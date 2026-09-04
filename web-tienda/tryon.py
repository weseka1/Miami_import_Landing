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
import hashlib
import os
import threading
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
# 120 y no 90: `mode='quality'` es mas lento que el 'balanced' que corria
# antes. Con 90 la generacion buena llegaba tarde y se caia al motor de
# respaldo, que es JUSTO el que no respeta el estampado — o sea que el
# timeout corto anulaba el arreglo.
_POLL_TIMEOUT = 120
_RATE_LIMIT = 5            # generaciones por IP por minuto (cada request cuesta)
_RATE_WINDOW = 60
_hits: dict[str, deque] = defaultdict(deque)

# 🔴 TOPE DIARIO. El freno por IP no alcanza: se esquiva con una cabecera
# `x-forwarded-for` inventada, y un dia viral (o un bot) se come el credito
# entero antes de que nadie lo mire. Esto es plata de Diego, no una cuota.
# Se toca con TRYON_TOPE_DIARIO en el entorno; 0 = apagado (no recomendado).
# 25/dia a USD 0,075 son USD 1,87 por dia: con la primera carga de USD 10 da
# para ~5 dias aunque el probador se llene de curiosos. El default es
# conservador a proposito — es mas facil subirlo despues de ver el uso real que
# explicarle a Diego que el credito se evaporo el primer dia.
_TOPE_DIA = int(os.environ.get("TRYON_TOPE_DIARIO") or 25)
_gastadas: dict[str, int] = {}

# 🔴 Lo que NO se prueba. El modelo pone ROPA sobre un cuerpo: una gorra, un
# morral o unas zapatillas salen como un mamarracho pegado al torso. Antes de
# encenderlo, en el catalogo habia 23 productos asi (10 gorras, 4 morrales,
# 3 ojotas, 2 zapatillas, 2 neceseres, 1 riñonera, 1 piluso). Mejor que el
# boton no aparezca a que aparezca y devuelva basura: el cliente no vuelve a
# apretarlo nunca mas.
_NO_SE_PRUEBA = {
    "gorras", "gorra", "pilusos", "piluso", "sombreros",
    "morrales", "morral", "neceseres", "neceser", "riñoneras", "rinoneras",
    "bolsos", "carteras", "mochilas",
    "ojotas", "zapatillas", "zapatos", "calzado", "sandalias",
    "relojes", "lentes", "perfumes", "medias", "cinturones", "accesorios",
}

# Segunda red, por el NOMBRE. La categoria sola no alcanza: "Nike Mind 001"
# (una zapatilla) y "Gorra jacquemus" se colaban porque nadie les puso
# categoria. Y Diego carga productos sin categoria todo el tiempo, asi que esto
# tiene que aguantar solo.
_PALABRAS_NO = (
    "gorra", "piluso", "sombrero", "vincha",
    "morral", "mochila", "bolso", "cartera", "riñonera", "rinonera", "neceser",
    "zapatilla", "ojota", "zapato", "sandalia", "bota",
    "reloj", "lente", "perfume", "cinturon", "cinturón", "media",
    # ropa interior y mallas: es una prenda, pero el probador toma la foto que
    # sube una persona y la devuelve en ropa interior. Para una tienda de una
    # persona eso es un problema sin ninguna venta del otro lado.
    "ropa interior", "lenceria", "lencería", "bikini", "malla", "boxer",
    "corpiño", "corpino", "bombacha",
)

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


def _ruta_recorte(url_original: str) -> str:
    """Ruta determinística del recorte en Storage. El nombre sale del hash de
    la URL original, así el mismo producto siempre cae en el mismo archivo y
    el recorte se paga UNA vez en la vida, no en cada prueba."""
    h = hashlib.sha1(url_original.encode("utf-8")).hexdigest()[:24]
    return f"products/_tryon/{h}.png"


def _prenda_aislada(url_original: str, data: bytes) -> str | None:
    """La prenda sola, sin el local de fondo. URL pública, o None si no se pudo.

    🔴 ESTE es el arreglo del "no me deja las remeras tal cual". Diego saca las
    fotos con el celular: la remera colgada de una percha o adentro de la
    valija, en ángulo, arrugada, agarrada con la mano y con OTRAS CUATRO
    prendas en el mismo cuadro. A FASHN le llegaba eso crudo y tenía que
    adivinar cuál de las prendas de la escena era la que hay que poner —
    por eso el estampado salía reinventado.

    `quitar_fondo()` (birefnet) ya resolvía exactamente esto para la vitrina
    de la home; el probador simplemente no lo usaba.

    El recorte se cachea en Storage por hash de la URL: se paga una vez en la
    vida del producto y todas las pruebas lo reusan. Si algo falla se devuelve
    None y se sigue con la foto original — el probador nunca se cae por esto,
    sólo vuelve a andar como antes.

    🔴 EL RECORTE NUNCA CORRE DENTRO DEL REQUEST. La primera version lo hacia
    y el cliente esperaba birefnet (hasta 90 s) MAS FASHN en quality (otros 90):
    dos minutos mirando "Generando tu look…" contra una UI que promete 20-60 s.
    Aca solo se MIRA el cache; si no esta, se devuelve None (se prueba con la
    foto original, como antes) y se deja el recorte andando en segundo plano
    para que la proxima persona ya lo encuentre hecho.

    Para que nadie pague esa primera vez esta `precalentar_recortes()`, que deja
    todo el catalogo recortado de antemano.
    """
    try:
        from core import storage
        from core.quitar_fondo import disponible as recorte_disponible
    except Exception:  # noqa: BLE001
        return None
    if not storage.is_enabled() or not recorte_disponible():
        return None

    ruta = _ruta_recorte(url_original)
    cacheada = storage.public_url(ruta)
    try:
        # Timeout corto A PROPOSITO: esto esta en el camino del cliente. Si el
        # storage no contesta en 5 s, se prueba con la foto original y listo.
        if requests.get(cacheada, timeout=5).status_code == 200:
            return cacheada
    except Exception:  # noqa: BLE001
        pass

    _recortar_en_segundo_plano(url_original, data, ruta)
    return None


_recortes_en_curso: set[str] = set()
_recortes_lock = threading.Lock()


def _recortar_en_segundo_plano(url_original: str, data: bytes, ruta: str) -> None:
    """Deja la prenda recortada para la PROXIMA prueba. No bloquea a nadie.

    El candado evita pagarle a birefnet dos veces por la misma prenda cuando
    entran dos personas juntas al mismo producto.
    """
    with _recortes_lock:
        if ruta in _recortes_en_curso:
            return
        _recortes_en_curso.add(ruta)

    def _worker() -> None:
        try:
            from core import storage
            from core.quitar_fondo import quitar_fondo
            png, motor = quitar_fondo(data)
            storage.upload_bytes(png, ruta, "image/png")
            print(f"[tryon] prenda recortada con {motor} -> {ruta}")
        except Exception as e:  # noqa: BLE001
            print(f"[tryon] no se pudo recortar ({type(e).__name__}: {e}); "
                  "se sigue usando la foto original")
        finally:
            with _recortes_lock:
                _recortes_en_curso.discard(ruta)

    threading.Thread(target=_worker, daemon=True).start()


def precalentar_recortes(db, limite: int = 0) -> dict:
    """Recorta de antemano la primera foto de cada prenda probable.

    Se corre una vez (y despues de cargar productos nuevos) para que ningun
    cliente sea el que estrena el recorte. Devuelve el conteo de lo que hizo.
    """
    from core import storage
    from core.quitar_fondo import disponible as recorte_disponible
    from core.quitar_fondo import quitar_fondo

    if not storage.is_enabled() or not recorte_disponible():
        return {"error": "falta storage o la key de recorte"}

    hechos = ya = fallos = saltados = 0
    for p in db.query(Product).filter(Product.published == True).all():  # noqa: E712
        if not p.images or not se_puede_probar(p):
            saltados += 1
            continue
        src = p.images[0].url
        if not src.startswith("http"):
            saltados += 1
            continue
        ruta = _ruta_recorte(src)
        try:
            if requests.get(storage.public_url(ruta), timeout=10).status_code == 200:
                ya += 1
                continue
            png, _ = quitar_fondo(requests.get(src, timeout=30).content)
            storage.upload_bytes(png, ruta, "image/png")
            hechos += 1
            print(f"[tryon] precalentado: {p.name}")
        except Exception as e:  # noqa: BLE001
            fallos += 1
            print(f"[tryon] precalentado FALLO en {p.name}: {type(e).__name__}")
        if limite and hechos >= limite:
            break
    return {"recortados": hechos, "ya_estaban": ya, "fallaron": fallos,
            "no_aplican": saltados}


def _garment(request: Request, product: Product) -> tuple[str, bool]:
    """(URL de la prenda a probar, si está aislada del fondo).

    El booleano no es cosmético: le dice a FASHN qué tipo de foto le estamos
    mandando (`garment_photo_type`). Declarar "flat-lay" sobre una foto con
    medio local adentro sería mentirle al modelo y empeora el resultado.
    """
    if not product.images:
        raise HTTPException(400, "Este producto todavía no tiene fotos.")
    src = product.images[0].url
    url = src if src.startswith("http") else str(request.base_url).rstrip("/") + src
    try:
        data = requests.get(url, timeout=20).content
    except Exception:
        raise HTTPException(502, "No pudimos leer la foto del producto.")

    recortada = _prenda_aislada(url, data)
    return (recortada, True) if recortada else (url, False)


def _nombres_categoria(product: Product) -> list[str]:
    return [(c.name or "").strip().lower() for c in (product.categories or [])]


def _parece_calzado(product: Product) -> bool:
    """Tercera red: el TALLE. "Nike Mind 001" es una zapatilla y ni la categoria
    ni el nombre lo dicen — pero su talle es "10US (43)". Un numero de 34 a 50,
    o un "US" adentro, es calzado y no una remera."""
    for v in (getattr(product, "variants", None) or []):
        t = (getattr(v, "value", "") or "").strip().lower()
        if not t:
            continue
        if "us" in t and any(c.isdigit() for c in t):
            return True
        n = "".join(c for c in t if c.isdigit())
        if n and t.replace(n, "").strip(" .()/-") == "" and 34 <= int(n[:2]) <= 50:
            return True
    return False


def se_puede_probar(product: Product) -> bool:
    """Si esta prenda tiene sentido en el probador.

    Una sola categoria de la lista negra alcanza para no ofrecerlo: un producto
    puede estar en "Gorras" y en "Diesel" a la vez, y el que manda es "Gorras".
    """
    if any(n in _NO_SE_PRUEBA for n in _nombres_categoria(product)):
        return False
    nombre = (getattr(product, "name", "") or "").strip().lower()
    if any(w in nombre for w in _PALABRAS_NO):
        return False
    return not _parece_calzado(product)


def _categoria(product: Product) -> str:
    for n in _nombres_categoria(product):
        cat = _CATEGORY_MAP.get(n)
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


def _generar_fashn(person_jpeg: bytes, garment_url: str, category: str, key: str,
                   aislada: bool = False) -> bytes:
    """FASHN v1.6 — el principal. Es el que respeta el texto de la prenda.

    Se mandaban 3 de los 10 parámetros: el resto quedaba en su default, y dos
    de esos defaults son justo los que gobiernan la fidelidad del estampado.
    Los nombres y valores salen del OpenAPI de fal, no de memoria:

      mode='quality'         el default es 'balanced'. La doc dice textual
                             "slower but produces higher quality". Miami vende
                             LOGO: un estampado aproximado es un cartel de
                             falsificación, así que acá se paga con segundos.
      garment_photo_type     el default 'auto' hace que el modelo adivine. Si
                             mandamos el recorte, ES una flat-lay y se lo
                             decimos; si no se pudo recortar, sigue 'auto'
                             porque la foto tiene medio local adentro.
    """
    return _fal_correr(_FAL_QUEUE, {
        "model_image": "data:image/jpeg;base64," + base64.b64encode(person_jpeg).decode(),
        "garment_image": garment_url,
        "category": category,
        "mode": "quality",
        "garment_photo_type": "flat-lay" if aislada else "auto",
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
    # el boton no aparece para estos, pero la API no puede confiar en eso
    if not se_puede_probar(product):
        raise HTTPException(400, "El probador es para prendas de vestir. "
                                 "Este producto no se puede probar.")

    person_jpeg = _leer_foto(raw)
    garment_url, aislada = _garment(request, product)

    def _tag(motor: str, e: Exception) -> str:
        st = getattr(getattr(e, "response", None), "status_code", "")
        return f"{motor}:{type(e).__name__}:{st}"

    img: bytes | None = None
    errores = []
    if _fal_key():
        try:
            img = _generar_fashn(person_jpeg, garment_url, _categoria(product),
                                 _fal_key(), aislada)
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
