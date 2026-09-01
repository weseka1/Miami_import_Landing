"""
PROBADOR VIRTUAL — el cliente se ve la prenda puesta.

Motor DOBLE, gateado por env (sin key: el botón ni aparece, nada roto):
- FAL_KEY   → FASHN v1.6 (USD 0,075/imagen, 864x1296). Es el principal, y se
              eligió por una razón concreta: es el único que renderiza bien el
              TEXTO y el estampado de la prenda. Miami vende logo (Off-White,
              Palm Angels, Diesel) y un probador que escribe "Palm Angeis" es
              peor que no tener probador: parece falsificación.
- FAL_KEY   → image-apps-v2 (USD 0,040/imagen, 4K) como respaldo del anterior.
              MISMA key, misma cuenta: fal sirve los dos.

🪦 Gemini 2.5 Flash Image quedó AFUERA: Google lo retira el 2-oct-2026. El
   reemplazo (gemini-3-pro-image) sale ~USD 0,13/imagen, o sea mas caro que
   FASHN y peor con el texto de la prenda.
🪦 MuAPI no sirve para esto: tiene Seedance, Kling y Veo, pero NINGUN modelo de
   try-on. Su "virtual try-on" es un generador de imagen generico.

Cada prueba cuesta plata de verdad, asi que hay DOS frenos: por IP y por dia.

La foto del cliente NO se persiste: viaja al motor y el resultado se guarda
como archivo temporal same-origin (se limpia a la hora).
"""
from __future__ import annotations

import base64
import io
import os
import time
import uuid
from collections import defaultdict, deque
from pathlib import Path

import requests
from fastapi import APIRouter, Depends, File, Form, HTTPException, Request, UploadFile
from sqlalchemy.orm import Session

from core.db import get_db
from core.models import Product

tryon_router = APIRouter()

_FAL_QUEUE = "https://queue.fal.run/fal-ai/fashn/tryon/v1.6"
_FAL_BARATO = "https://queue.fal.run/fal-ai/image-apps-v2/virtual-try-on"
_TMP_DIR = Path(__file__).resolve().parent / "static" / "tryon"
_TMP_TTL = 3600
_MAX_UPLOAD = 8 * 1024 * 1024
_POLL_TIMEOUT = 90
_RATE_LIMIT = 5            # generaciones por IP por minuto (cada request cuesta)
_RATE_WINDOW = 60
_hits: dict[str, deque] = defaultdict(deque)

# 🔴 TOPE DIARIO. El freno por IP no alcanza: se esquiva con una cabecera
# `x-forwarded-for` inventada, y un dia viral (o un bot) se come el credito
# entero antes de que nadie lo mire. Esto es plata de Diego, no una cuota.
# Se toca con TRYON_TOPE_DIARIO en el entorno; 0 = apagado (no recomendado).
_TOPE_DIA = int(os.environ.get("TRYON_TOPE_DIARIO") or 120)
_gastadas: dict[str, int] = {}

_CATEGORY_MAP = {
    "remeras": "tops", "buzos": "tops", "camperas": "tops", "chaquetas": "tops",
    "camisas": "tops", "tops": "tops", "abrigos": "tops",
    "pantalones": "bottoms", "shorts": "bottoms", "bermudas": "bottoms",
    "vestidos": "one-pieces", "enteritos": "one-pieces",
}



def _fal_key() -> str | None:
    return (os.environ.get("FAL_KEY") or "").strip() or None


def _rate_ok(ip: str) -> bool:
    now = time.time()
    q = _hits[ip]
    while q and now - q[0] > _RATE_WINDOW:
        q.popleft()
    if len(q) >= _RATE_LIMIT:
        return False
    q.append(now)
    return True


def _hoy() -> str:
    return time.strftime("%Y-%m-%d")


def _cupo_dia_ok() -> bool:
    """Freno duro del dia. Se cuenta la generacion que SALIO, no el intento:
    si el motor falla no se le cobra a nadie y no se descuenta."""
    if _TOPE_DIA <= 0:
        return True
    d = _hoy()
    for k in list(_gastadas):
        if k != d:
            _gastadas.pop(k, None)
    return _gastadas.get(d, 0) < _TOPE_DIA


def _sumar_gasto() -> None:
    d = _hoy()
    _gastadas[d] = _gastadas.get(d, 0) + 1


def _limpiar_viejos() -> None:
    try:
        now = time.time()
        for f in _TMP_DIR.glob("*.jpg"):
            if now - f.stat().st_mtime > _TMP_TTL:
                f.unlink(missing_ok=True)
    except OSError:
        pass


def _leer_foto(raw: bytes) -> bytes:
    """Valida por contenido, corrige rotación EXIF y comprime a JPEG liviano.
    Gotcha: las fotos de iPhone llegan como 'MPO' para Pillow → se tratan como JPEG."""
    from PIL import Image, ImageOps

    try:
        img = Image.open(io.BytesIO(raw))
        if img.format not in ("JPEG", "PNG", "WEBP", "MPO"):
            raise ValueError(img.format)
        img = ImageOps.exif_transpose(img)
        img = img.convert("RGB")
    except Exception:
        raise HTTPException(400, "No pudimos leer la foto. Probá con una JPG o PNG.")

    img.thumbnail((1024, 1536))
    buf = io.BytesIO()
    img.save(buf, "JPEG", quality=88)
    return buf.getvalue()


def _garment(request: Request, product: Product) -> tuple[str, bytes]:
    """(URL pública, bytes) de la primera foto del producto."""
    if not product.images:
        raise HTTPException(400, "Este producto todavía no tiene fotos.")
    src = product.images[0].url
    url = src if src.startswith("http") else str(request.base_url).rstrip("/") + src
    try:
        data = requests.get(url, timeout=20).content
    except Exception:
        raise HTTPException(502, "No pudimos leer la foto del producto.")
    return url, data


def _categoria(product: Product) -> str:
    for c in (product.categories or []):
        cat = _CATEGORY_MAP.get((c.name or "").strip().lower())
        if cat:
            return cat
    return "auto"


# --------------------------------------------------------------------------- #
# Motores
# --------------------------------------------------------------------------- #
def _fal_correr(cola: str, payload: dict, key: str) -> bytes:
    """Encola en fal, espera y devuelve la imagen. Sirve para los dos modelos:
    la cola de fal se maneja igual, solo cambia la URL y el payload."""
    headers = {"Authorization": f"Key {key}", "Content-Type": "application/json"}
    r = requests.post(cola, json=payload, headers=headers, timeout=30)
    r.raise_for_status()
    job = r.json()
    status_url = job.get("status_url") or f"{cola}/requests/{job['request_id']}/status"
    result_url = job.get("response_url") or f"{cola}/requests/{job['request_id']}"

    deadline = time.time() + _POLL_TIMEOUT
    while time.time() < deadline:
        time.sleep(2.5)
        try:
            st = requests.get(status_url, headers=headers, timeout=15).json()
        except Exception:
            continue
        if st.get("status") == "COMPLETED":
            res = requests.get(result_url, headers=headers, timeout=20).json()
            return requests.get(res["images"][0]["url"], timeout=30).content
        if st.get("status") in ("FAILED", "ERROR"):
            raise RuntimeError("fal failed")
    raise TimeoutError("fal timeout")


def _generar_fashn(person_jpeg: bytes, garment_url: str, category: str, key: str) -> bytes:
    """FASHN v1.6 — el principal. Es el que respeta el texto de la prenda."""
    return _fal_correr(_FAL_QUEUE, {
        "model_image": "data:image/jpeg;base64," + base64.b64encode(person_jpeg).decode(),
        "garment_image": garment_url,
        "category": category,
    }, key)


def _generar_barato(person_jpeg: bytes, garment_url: str, category: str, key: str) -> bytes:
    """image-apps-v2 — respaldo, la MISMA cuenta de fal. Sale la mitad y saca 4K,
    pero es menos fiel con el estampado: solo entra si FASHN falló."""
    return _fal_correr(_FAL_BARATO, {
        "person_image_url": "data:image/jpeg;base64," + base64.b64encode(person_jpeg).decode(),
        "garment_image_url": garment_url,
        "clothing_type": {"tops": "upper", "bottoms": "lower",
                          "one-pieces": "dress"}.get(category, "upper"),
    }, key)


# --------------------------------------------------------------------------- #
# Endpoints
# --------------------------------------------------------------------------- #
@tryon_router.get("/api/tryon/status")
def tryon_status():
    return {"available": bool(_fal_key())}


@tryon_router.post("/api/tryon")
async def tryon(
    request: Request,
    person: UploadFile = File(...),
    product_id: int = Form(...),
    db: Session = Depends(get_db),
):
    if not _fal_key():
        return {"available": False, "error": "El probador no está habilitado todavía."}

    # el tope del día va ANTES que el de IP: es el que cuida la plata
    if not _cupo_dia_ok():
        raise HTTPException(503, "El probador llegó al tope de pruebas de hoy. "
                                 "Volvé mañana y lo probás.")

    ip = (request.headers.get("x-forwarded-for") or (request.client.host if request.client else "?")).split(",")[0].strip()
    if not _rate_ok(ip):
        raise HTTPException(429, "Muchas pruebas seguidas. Esperá un minuto y probá de nuevo.")

    raw = await person.read()
    if len(raw) > _MAX_UPLOAD:
        raise HTTPException(400, "La foto pesa más de 8MB. Sacale una captura o achicala.")

    product = db.get(Product, product_id)
    if not product or not product.published:
        raise HTTPException(404, "Producto no encontrado.")

    person_jpeg = _leer_foto(raw)
    garment_url, _ = _garment(request, product)

    def _tag(motor: str, e: Exception) -> str:
        st = getattr(getattr(e, "response", None), "status_code", "")
        return f"{motor}:{type(e).__name__}:{st}"

    img: bytes | None = None
    errores = []
    if _fal_key():
        try:
            img = _generar_fashn(person_jpeg, garment_url, _categoria(product), _fal_key())
        except Exception as e:  # noqa: BLE001
            errores.append(_tag("fashn", e))
    if img is None:
        # respaldo en la MISMA cuenta de fal: la mitad de precio, 4K, menos fiel
        # con el estampado. Solo se usa si FASHN falló.
        try:
            img = _generar_barato(person_jpeg, garment_url, _categoria(product), _fal_key())
        except Exception as e:  # noqa: BLE001
            errores.append(_tag("barato", e))

    if img is None:
        print(f"[tryon] fallo ({', '.join(errores)})")
        # 429 = cuota del motor agotada — no es culpa de la foto del cliente.
        if any(":429" in e for e in errores):
            raise HTTPException(503, "El probador está a tope en este momento. "
                                     "Probá de nuevo en unos minutos.")
        raise HTTPException(502, "No pudimos generar la prueba con esa foto. "
                                 "Probá con una foto de frente, cuerpo visible y buena luz.")

    _sumar_gasto()
    _TMP_DIR.mkdir(parents=True, exist_ok=True)
    _limpiar_viejos()
    name = f"{uuid.uuid4().hex}.jpg"
    (_TMP_DIR / name).write_bytes(img)
    return {"ok": True, "image_url": f"/static/tryon/{name}"}
