"""
PROBADOR VIRTUAL — el cliente se ve la prenda puesta.

Motor DOBLE, gateado por env (sin key: el botón ni aparece, nada roto):
- FAL_KEY        → FASHN v1.6 vía fal.ai (~USD 0,08/imagen, máxima fidelidad)
- GEMINI_API_KEY → Gemini 2.5 Flash Image / nano-banana (franja GRATUITA de Google)
Si están las dos, FASHN manda y Gemini queda de respaldo.

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
_GEMINI_URL = ("https://generativelanguage.googleapis.com/v1beta/models/"
               "gemini-2.5-flash-image:generateContent")
_TMP_DIR = Path(__file__).resolve().parent / "static" / "tryon"
_TMP_TTL = 3600
_MAX_UPLOAD = 8 * 1024 * 1024
_POLL_TIMEOUT = 90
_RATE_LIMIT = 5            # generaciones por IP por minuto (cada request cuesta)
_RATE_WINDOW = 60
_hits: dict[str, deque] = defaultdict(deque)

_CATEGORY_MAP = {
    "remeras": "tops", "buzos": "tops", "camperas": "tops", "chaquetas": "tops",
    "camisas": "tops", "tops": "tops", "abrigos": "tops",
    "pantalones": "bottoms", "shorts": "bottoms", "bermudas": "bottoms",
    "vestidos": "one-pieces", "enteritos": "one-pieces",
}

_GEMINI_PROMPT = (
    "Virtual try-on: dress the person from the FIRST image in the garment shown "
    "in the SECOND image. Keep the person's face, pose, body and background "
    "exactly as they are. Fit the garment naturally with realistic drape, "
    "lighting and shadows. Photorealistic result. Output ONLY the edited image."
)


def _fal_key() -> str | None:
    return (os.environ.get("FAL_KEY") or "").strip() or None


def _gemini_key() -> str | None:
    return (os.environ.get("GEMINI_API_KEY") or "").strip() or None


def _rate_ok(ip: str) -> bool:
    now = time.time()
    q = _hits[ip]
    while q and now - q[0] > _RATE_WINDOW:
        q.popleft()
    if len(q) >= _RATE_LIMIT:
        return False
    q.append(now)
    return True


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
def _generar_fashn(person_jpeg: bytes, garment_url: str, category: str, key: str) -> bytes:
    headers = {"Authorization": f"Key {key}", "Content-Type": "application/json"}
    payload = {
        "model_image": "data:image/jpeg;base64," + base64.b64encode(person_jpeg).decode(),
        "garment_image": garment_url,
        "category": category,
    }
    r = requests.post(_FAL_QUEUE, json=payload, headers=headers, timeout=30)
    r.raise_for_status()
    job = r.json()
    status_url = job.get("status_url") or f"{_FAL_QUEUE}/requests/{job['request_id']}/status"
    result_url = job.get("response_url") or f"{_FAL_QUEUE}/requests/{job['request_id']}"

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
            raise RuntimeError("fashn failed")
    raise TimeoutError("fashn timeout")


def _generar_gemini(person_jpeg: bytes, garment_jpeg: bytes, key: str) -> bytes:
    body = {
        "contents": [{
            "parts": [
                {"text": _GEMINI_PROMPT},
                {"inline_data": {"mime_type": "image/jpeg",
                                 "data": base64.b64encode(person_jpeg).decode()}},
                {"inline_data": {"mime_type": "image/jpeg",
                                 "data": base64.b64encode(garment_jpeg).decode()}},
            ],
        }],
        # Sin esto Gemini puede responder SOLO texto y no hay imagen que parsear.
        "generationConfig": {"responseModalities": ["TEXT", "IMAGE"]},
    }
    r = requests.post(f"{_GEMINI_URL}?key={key}", json=body, timeout=_POLL_TIMEOUT)
    if r.status_code != 200:
        print(f"[tryon] gemini HTTP {r.status_code}: {r.text[:400]}")
    r.raise_for_status()
    data = r.json()
    for part in data["candidates"][0]["content"]["parts"]:
        blob = part.get("inline_data") or part.get("inlineData")
        if blob and blob.get("data"):
            return base64.b64decode(blob["data"])
    raise RuntimeError("gemini sin imagen en la respuesta")


# --------------------------------------------------------------------------- #
# Endpoints
# --------------------------------------------------------------------------- #
@tryon_router.get("/api/tryon/status")
def tryon_status():
    return {"available": bool(_fal_key() or _gemini_key())}


@tryon_router.post("/api/tryon")
async def tryon(
    request: Request,
    person: UploadFile = File(...),
    product_id: int = Form(...),
    db: Session = Depends(get_db),
):
    if not (_fal_key() or _gemini_key()):
        return {"available": False, "error": "El probador no está habilitado todavía."}

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
    garment_url, garment_jpeg = _garment(request, product)

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
    if img is None and _gemini_key():
        try:
            img = _generar_gemini(person_jpeg, garment_jpeg, _gemini_key())
        except Exception as e:  # noqa: BLE001
            errores.append(_tag("gemini", e))

    if img is None:
        print(f"[tryon] fallo ({', '.join(errores)})")
        # 429 = cuota del motor agotada — no es culpa de la foto del cliente.
        if any(":429" in e for e in errores):
            raise HTTPException(503, "El probador está a tope en este momento. "
                                     "Probá de nuevo en unos minutos.")
        raise HTTPException(502, "No pudimos generar la prueba con esa foto. "
                                 "Probá con una foto de frente, cuerpo visible y buena luz.")

    _TMP_DIR.mkdir(parents=True, exist_ok=True)
    _limpiar_viejos()
    name = f"{uuid.uuid4().hex}.jpg"
    (_TMP_DIR / name).write_bytes(img)
    return {"ok": True, "image_url": f"/static/tryon/{name}"}
