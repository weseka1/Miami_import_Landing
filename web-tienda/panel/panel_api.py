"""
API del panel administrativo, respaldada por la base de datos PROPIA.

Reemplaza al viejo proxy contra Tiendanube. Mantiene los mismos paths y la misma
forma de respuesta (ver serializers.py) para que el frontend siga funcionando.
"""
from __future__ import annotations

import html
import io
import logging
import re
import secrets
import unicodedata
from datetime import datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import List, Optional

import requests
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import StreamingResponse
from sqlalchemy import case, func
from sqlalchemy.orm import Session

from .auth import get_current_admin
from core import storage
from core.config import settings
from core.db import get_db
from core.models import (
    Category, Order, Product, ProductImage, Reserva, Variant, Setting,
    RESERVA_STATUSES,
)
from core.sanitize import clean_description
from .serializers import order_to_tn, product_to_tn, reserva_to_dict

log = logging.getLogger("panel_api")

# Todo el panel exige sesión de admin.
router = APIRouter(prefix="/api", tags=["panel"], dependencies=[Depends(get_current_admin)])

# static de la TIENDA (web-tienda/static): ahí viven las fotos locales que se
# sirven como /static/products/... — el path viejo duplicaba "web-tienda" (de
# cuando el panel era un paquete hermano) y el guardado local daba 500.
STORE_STATIC = Path(__file__).resolve().parent.parent / "static"


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
def _strip_accents(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFKD", s) if not unicodedata.combining(c))



def _rotar_bytes(content: bytes, grados: int) -> bytes:
    """Rota una imagen en memoria. Si algo falla devuelve la original.

    `expand=True` para que no recorte al girar 90/270. El signo es negativo
    porque Pillow rota antihorario y en la interfaz el botón gira horario.
    """
    grados = grados % 360
    if not grados:
        return content
    try:
        from PIL import Image
        Image.MAX_IMAGE_PIXELS = 40_000_000     # anti bomba de descompresión
        src = Image.open(io.BytesIO(content))
        fmt = (src.format or "JPEG").upper()
        if fmt not in ("JPEG", "PNG", "WEBP"):
            fmt = "JPEG"
        out = src.rotate(-grados, expand=True)
        if fmt == "JPEG" and out.mode in ("RGBA", "P"):
            out = out.convert("RGB")
        buf = io.BytesIO()
        out.save(buf, format=fmt, quality=90)
        return buf.getvalue()
    except Exception:  # noqa: BLE001
        log.exception("No se pudo rotar la imagen; se guarda sin girar")
        return content


def _precio_valido(raw) -> Decimal:
    """Convierte a Decimal validando. Sin esto, "NaN", "Infinity", negativos y
    "1e999" entraban a la base y de ahí al monto que se le cobra al cliente."""
    try:
        d = Decimal(str(raw))
    except (InvalidOperation, TypeError, ValueError):
        raise HTTPException(400, "Precio inválido")
    if not d.is_finite() or d <= 0 or d > Decimal("100000000"):
        raise HTTPException(400, "Precio fuera de rango")
    return d.quantize(Decimal("0.01"))

def slugify(text: str, max_len: int = 80) -> str:
    t = _strip_accents(text or "").lower()
    t = re.sub(r"[^a-z0-9]+", "-", t).strip("-")
    return t[:max_len].rstrip("-") or "producto"


def unique_handle(db: Session, base: str) -> str:
    handle = base
    i = 1
    while db.query(Product).filter_by(handle=handle).first():
        i += 1
        handle = f"{base}-{i}"
    return handle


ALLOWED_IMAGE_EXT = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".avif"}
ALLOWED_IMAGE_MIME = {"image/jpeg", "image/png", "image/webp", "image/gif", "image/avif"}
MAX_IMAGE_BYTES = 8 * 1024 * 1024  # 8 MB
# Firmas (magic numbers) para confirmar que el archivo ES una imagen real.
_IMAGE_MAGIC = (b"\xff\xd8\xff", b"\x89PNG\r\n\x1a\n", b"GIF87a", b"GIF89a", b"RIFF")


def validate_image(filename: str, content_type: str, content: bytes) -> str:
    """Valida una imagen subida y devuelve un nombre de archivo SEGURO y aleatorio.
    Rechaza por tamaño, extensión, MIME y firma binaria. Renombrado aleatorio
    evita path traversal y colisiones."""
    if len(content) > MAX_IMAGE_BYTES:
        raise HTTPException(413, "Imagen demasiado grande (máx 8 MB)")
    if len(content) < 64:
        raise HTTPException(400, "Archivo vacío o corrupto")
    ext = Path(filename or "").suffix.lower()
    if ext not in ALLOWED_IMAGE_EXT:
        raise HTTPException(415, f"Extensión no permitida: {ext or '(ninguna)'}")
    if content_type and content_type.lower() not in ALLOWED_IMAGE_MIME:
        raise HTTPException(415, f"Tipo no permitido: {content_type}")
    if not any(content.startswith(sig) for sig in _IMAGE_MAGIC):
        raise HTTPException(415, "El contenido no es una imagen válida")
    return f"{secrets.token_hex(16)}{ext if ext != '.jpeg' else '.jpg'}"


MAX_IMAGE_SIDE = 1600      # px: alcanza para zoom en detalle; una foto de celular trae 4000+
JPEG_WEB_QUALITY = 82


def comprimir_imagen(content: bytes) -> bytes:
    """Recomprime una foto a tamaño web ANTES de guardarla.

    Las fotos salen del celular en 4-5 MB / 4000px: servidas así, las cards de
    la tienda quedan negras o pintadas a medias en el teléfono. Acá se aplica
    la rotación EXIF, se limita el lado mayor a MAX_IMAGE_SIDE y se guarda en
    calidad web. GIF/AVIF (o cualquier cosa que Pillow no abra) vuelven tal
    cual: mejor foto pesada que upload roto.
    """
    try:
        from PIL import Image, ImageOps
    except ImportError:
        return content
    try:
        Image.MAX_IMAGE_PIXELS = 40_000_000  # anti bomba de descompresión
        img = Image.open(io.BytesIO(content))
        fmt = (img.format or "").upper()
        if fmt == "MPO":
            fmt = "JPEG"   # foto de iPhone: JPEG multi-frame, el primer frame es la foto
        if fmt not in ("JPEG", "PNG", "WEBP"):
            return content
        img = ImageOps.exif_transpose(img)
        if max(img.size) > MAX_IMAGE_SIDE:
            img.thumbnail((MAX_IMAGE_SIDE, MAX_IMAGE_SIDE), Image.LANCZOS)
        if fmt == "JPEG" and img.mode not in ("RGB", "L"):
            img = img.convert("RGB")
        buf = io.BytesIO()
        if fmt == "PNG":
            img.save(buf, format="PNG", optimize=True)
        else:
            img.save(buf, format=fmt, quality=JPEG_WEB_QUALITY, optimize=True)
        out = buf.getvalue()
        # Si no achicó (foto ya optimizada), se queda la original.
        return out if len(out) < len(content) else content
    except Exception:  # noqa: BLE001 — nunca romper la subida por la compresión
        log.exception("comprimir_imagen falló; se sube la original")
        return content


def store_image_bytes(content: bytes, content_type: str, handle: str, safe_name: str) -> tuple[str, str | None]:
    """Guarda la imagen en Supabase Storage (si está configurado) o en disco local.
    Devuelve (src, local_path). En Supabase, src = URL pública y local_path = None."""
    content = comprimir_imagen(content)
    rel = f"products/{handle}/{safe_name}"
    if storage.is_enabled():
        url = storage.upload_bytes(content, rel, content_type or "image/jpeg")
        return url, None
    dest = STORE_STATIC / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(content)
    return f"/static/{rel}", f"/static/{rel}"


def _productos_completos(db: Session):
    """Query de Product con variantes, imágenes y categorías cargadas de una.

    El serializer toca esas tres relaciones por producto. Sin carga anticipada,
    /products/all (que devuelve TODO el catálogo) hacía ~3 consultas por
    producto: cientos de viajes a la Postgres remota. Con esto son 4 en total.
    """
    from sqlalchemy.orm import selectinload
    return (db.query(Product)
            .options(selectinload(Product.variants),
                     selectinload(Product.images),
                     selectinload(Product.categories)))


def current_usd_rate(db: Session) -> float:
    s = db.get(Setting, "usd_rate")
    if s and s.value and s.value.get("rate"):
        try:
            return float(s.value["rate"])
        except (TypeError, ValueError):
            pass
    return settings.USD_TO_ARS_RATE


# --------------------------------------------------------------------------- #
# Productos
# --------------------------------------------------------------------------- #
@router.get("/store")
def store_info(db: Session = Depends(get_db)):
    """Datos de la tienda para el frontend del panel.

    El panel viejo tenía la URL de Tiendanube hardcodeada; ahora sale de la
    config para que los links apunten a NUESTRA tienda.
    """
    base = settings.STORE_BASE_URL.rstrip("/")
    return {
        "name": "MIAMI IMPORT",
        "url": base,
        "product_url_base": f"{base}/productos/",
        "usd_rate": current_usd_rate(db),
    }


# Los productos "a pedido" no son stock real: se listan aparte, así que el
# catálogo normal del panel los excluye. `is_(False)` cubre también las filas
# viejas donde la columna quedó en NULL antes de existir el flag.
def _no_a_pedido(query):
    return query.filter((Product.a_pedido.is_(False)) | (Product.a_pedido.is_(None)))


@router.get("/products")
def list_products(q: Optional[str] = None, page: int = 1, per_page: int = 200,
                  db: Session = Depends(get_db)):
    query = _no_a_pedido(_productos_completos(db))
    if q:
        like = f"%{q.lower()}%"
        query = query.filter(func.lower(Product.name).like(like) | func.lower(Product.brand).like(like))
    items = query.order_by(Product.id.desc()).offset((page - 1) * per_page).limit(per_page).all()
    return [product_to_tn(p) for p in items]


@router.get("/products/all")
def list_all_products(db: Session = Depends(get_db)):
    q = _no_a_pedido(_productos_completos(db)).order_by(Product.id.desc())
    return [product_to_tn(p) for p in q.all()]


@router.get("/products/a_pedido")
def list_a_pedido(db: Session = Depends(get_db)):
    q = (_productos_completos(db)
         .filter(Product.a_pedido.is_(True))
         .order_by(Product.id.desc()))
    return [product_to_tn(p) for p in q.all()]


@router.get("/products/{pid}")
def get_product(pid: int, db: Session = Depends(get_db)):
    p = db.get(Product, pid)
    if not p:
        raise HTTPException(404, "Producto no encontrado")
    return product_to_tn(p)


@router.put("/products/{pid}")
def update_product(pid: int, body: dict, db: Session = Depends(get_db)):
    """Actualiza datos del producto (nombre, marca, descripción, publicado)."""
    p = db.get(Product, pid)
    if not p:
        raise HTTPException(404, "Producto no encontrado")

    if body.get("name") is not None:
        nombre = str(body["name"]).strip()[:500]
        if not nombre:
            raise HTTPException(400, "El nombre no puede quedar vacío")
        p.name = nombre
    if "brand" in body:
        p.brand = str(body.get("brand") or "").strip()[:255] or None
    if "description" in body:
        # Se renderiza con `| safe` en la tienda: sanitizar siempre.
        p.description = clean_description(str(body.get("description") or ""))
    if "published" in body:
        p.published = bool(body["published"])
    if "destacado" in body:
        p.destacado = bool(body["destacado"])
    if "mas_vendido" in body:
        p.mas_vendido = bool(body["mas_vendido"])

    db.commit()
    db.refresh(p)
    return product_to_tn(p)


@router.post("/products/{pid}/variants")
def add_variant(pid: int, body: dict, db: Session = Depends(get_db)):
    """Agrega un talle nuevo a un producto existente.

    Se crea con stock 0 por defecto: solo deja la opción disponible, sin tocar
    las variantes que el producto ya tiene cargadas.
    """
    p = db.get(Product, pid)
    if not p:
        raise HTTPException(404, "Producto no encontrado")

    talle = str(body.get("talle") or body.get("value") or "").strip().upper()[:255]
    if not talle:
        raise HTTPException(400, "Falta el talle")
    if any((v.value or "").strip().upper() == talle for v in p.variants):
        raise HTTPException(409, f"El talle {talle} ya existe en este producto")

    try:
        stock = max(0, int(body.get("stock", 0) or 0))
    except (TypeError, ValueError):
        raise HTTPException(400, "Stock inválido")

    # Precio: el del body, o el de la primera variante existente.
    price = None
    if body.get("price") not in (None, ""):
        price = _precio_valido(body["price"])
    base = p.variants[0] if p.variants else None
    if price is None:
        price = base.price if base else Decimal("0")

    v = Variant(
        product_id=p.id, value=talle, stock=stock, price=price,
        usd_price=(base.usd_price if base else None),
        compare_at_price=(base.compare_at_price if base else None),
        position=(max((x.position or 0) for x in p.variants) + 1) if p.variants else 1,
        visible=True,
    )
    db.add(v)
    db.commit()
    db.refresh(p)
    return product_to_tn(p)


@router.delete("/variants/{pid}/{vid}")
def delete_variant(pid: int, vid: int, db: Session = Depends(get_db)):
    """Quita un talle del producto.

    No se borra si es el único que queda (un producto sin variantes no se puede
    comprar ni mostrar precio) ni si está comprometido en un pedido pendiente
    de pago, porque ahí hay stock reservado que quedaría sin dueño.
    """
    from core.models import Order, OrderItem

    v = db.get(Variant, vid)
    if not v or v.product_id != pid:
        raise HTTPException(404, "Talle no encontrado")

    p = db.get(Product, pid)
    if p and len(p.variants) <= 1:
        raise HTTPException(409, "Es el único talle del producto: no se puede quitar")

    reservado = (db.query(OrderItem)
                 .join(Order, Order.id == OrderItem.order_id)
                 .filter(OrderItem.variant_id == vid,
                         Order.payment_status == "pending",
                         Order.stock_reserved.is_(True))
                 .first())
    if reservado:
        raise HTTPException(409, "Hay un pedido pendiente con este talle. "
                                 "Resolvelo antes de quitarlo.")

    db.delete(v)
    db.commit()
    db.refresh(p)
    return product_to_tn(p)


@router.put("/products/{pid}/images/orden")
def reorder_images(pid: int, body: dict, db: Session = Depends(get_db)):
    """Reordena la galería del producto.

    `ids` viene con el orden nuevo, de la portada a la última. La primera es la
    que se ve en el listado de la tienda y como foto principal del producto.
    Se exige la lista COMPLETA para no dejar posiciones repetidas: la relación
    ordena por `position` y con empates el orden que ve el cliente es al azar.
    """
    p = db.get(Product, pid)
    if not p:
        raise HTTPException(404, "Producto no encontrado")

    ids = body.get("ids")
    if not isinstance(ids, list) or not ids:
        raise HTTPException(400, "Falta el orden de las fotos")
    try:
        ids = [int(i) for i in ids]
    except (TypeError, ValueError):
        raise HTTPException(400, "Orden inválido")

    actuales = {im.id: im for im in p.images}
    if set(ids) != set(actuales) or len(ids) != len(actuales):
        raise HTTPException(400, "El orden no coincide con las fotos del producto")

    for pos, iid in enumerate(ids, 1):
        actuales[iid].position = pos
    db.commit()
    db.refresh(p)
    return product_to_tn(p)


@router.delete("/products/{pid}/images/{image_id}")
def delete_product_image(pid: int, image_id: int, db: Session = Depends(get_db)):
    """Borra una foto del producto.

    Se renumeran las posiciones de las que quedan (1..N) para no dejar huecos
    ni empates: con posiciones repetidas el orden en la tienda sale al azar.
    Si se borra la portada, la que quedó primera pasa a ser la principal.
    El archivo del bucket se elimina DESPUÉS del commit, y si falla no se
    aborta: peor caso queda un archivo huérfano, no una foto fantasma.
    """
    p = db.get(Product, pid)
    img = db.get(ProductImage, image_id)
    if not p or not img or img.product_id != pid:
        raise HTTPException(404, "Imagen no encontrada")

    old_path = storage.path_from_url(img.src)
    db.delete(img)
    db.flush()
    db.refresh(p)
    for pos, im in enumerate(sorted(p.images, key=lambda x: x.position or 0), 1):
        im.position = pos
    db.commit()

    if old_path:
        try:
            storage.delete_path(old_path)
        except Exception:  # noqa: BLE001
            pass
    db.refresh(p)
    return product_to_tn(p)


@router.post("/products/{pid}/images/{image_id}/rotate")
def rotate_product_image(pid: int, image_id: int, body: dict, db: Session = Depends(get_db)):
    """Rota una imagen ya subida y la reemplaza en el mismo lugar.

    A diferencia del panel viejo (que tenía que borrar y resubir a Tiendanube),
    acá se reescribe el archivo en nuestro bucket y se conserva la posición.
    """
    p = db.get(Product, pid)
    img = db.get(ProductImage, image_id)
    if not p or not img or img.product_id != pid:
        raise HTTPException(404, "Imagen no encontrada")
    try:
        degrees = int(body.get("degrees", 0) or 0) % 360
    except (TypeError, ValueError):
        degrees = 0
    if degrees == 0:
        return {"ok": True, "unchanged": True}
    if not storage.is_enabled():
        raise HTTPException(503, "Storage no configurado")

    try:
        from PIL import Image
    except ImportError:
        raise HTTPException(503, "Falta Pillow para rotar imágenes")

    # Se lee de `src`, NO de la property `url`: `url` devuelve local_path si
    # existe (las fotos migradas de TN tienen "/static/..." ahí, que no es
    # descargable) y además es de solo lectura, así que no se le puede asignar.
    origen = img.src or ""
    bucket = (settings.SUPABASE_URL or "").rstrip("/")
    if not (bucket and origen.startswith(bucket)):
        # Allow-list del origen: evita convertir esto en un SSRF si alguna vez
        # se permite cargar imágenes por URL arbitraria.
        raise HTTPException(400, "Solo se pueden rotar imágenes de nuestro bucket")

    try:
        resp = requests.get(origen, timeout=30, allow_redirects=False)
        resp.raise_for_status()
        if len(resp.content) > MAX_IMAGE_BYTES:
            raise HTTPException(413, "La imagen es demasiado grande")
        Image.MAX_IMAGE_PIXELS = 40_000_000  # anti bomba de descompresión
        src = Image.open(io.BytesIO(resp.content))
        fmt = (src.format or "JPEG").upper()
        if fmt not in ("JPEG", "PNG", "WEBP"):
            fmt = "JPEG"
        # expand=True para que no recorte al rotar 90/270.
        out = src.rotate(-degrees, expand=True)
        if fmt == "JPEG" and out.mode in ("RGBA", "P"):
            out = out.convert("RGB")
        buf = io.BytesIO()
        out.save(buf, format=fmt, quality=90)
        data = comprimir_imagen(buf.getvalue())
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(502, f"No se pudo procesar la imagen: {exc}")

    ext = {"JPEG": "jpg", "PNG": "png", "WEBP": "webp"}[fmt]
    rel = f"products/{slugify(p.name or 'producto')}/{secrets.token_hex(16)}.{ext}"
    try:
        new_url = storage.upload_bytes(
            data, rel, f"image/{'jpeg' if ext == 'jpg' else ext}")
    except RuntimeError as exc:
        raise HTTPException(502, f"No se pudo guardar la imagen rotada: {exc}")

    old_path = storage.path_from_url(img.src)
    img.src = new_url          # `url` es property de solo lectura
    img.local_path = None      # la copia local vieja ya no aplica
    db.commit()
    if old_path:
        try:
            storage.delete_path(old_path)  # recién ahora, con la nueva ya guardada
        except Exception:  # noqa: BLE001
            pass
    return {"ok": True, "src": new_url}


@router.delete("/products/{pid}")
def delete_product(pid: int, db: Session = Depends(get_db)):
    p = db.get(Product, pid)
    if not p:
        raise HTTPException(404, "Producto no encontrado")
    # Borrar también las imágenes del bucket de Supabase (si aplica).
    if storage.is_enabled():
        for img in p.images:
            path = storage.path_from_url(img.src)
            if path:
                storage.delete_path(path)
    db.delete(p)
    db.commit()
    return {"ok": True}


@router.put("/variants/{pid}/{vid}/stock")
def update_variant_stock(pid: int, vid: int, body: dict, db: Session = Depends(get_db)):
    v = db.get(Variant, vid)
    if not v or v.product_id != pid:
        raise HTTPException(404, "Variante no encontrada")
    try:
        nuevo = int(body.get("stock", 0))
    except (TypeError, ValueError):
        raise HTTPException(400, "Stock inválido")
    if nuevo < 0:
        raise HTTPException(400, "El stock no puede ser negativo")
    v.stock = nuevo
    db.commit()
    return {"ok": True, "stock": v.stock}


@router.put("/variants/{pid}/{vid}")
def update_variant(pid: int, vid: int, body: dict, db: Session = Depends(get_db)):
    v = db.get(Variant, vid)
    if not v or v.product_id != pid:
        raise HTTPException(404, "Variante no encontrada")
    try:
        if "stock" in body:
            stock = int(body["stock"])
            if stock < 0:
                raise HTTPException(400, "El stock no puede ser negativo")
            v.stock = stock
        if "price" in body:
            v.price = _precio_valido(body["price"])
        if "sku" in body:
            v.sku = (str(body["sku"]) or "")[:120] or None
        if "promotional_price" in body and body["promotional_price"] not in (None, ""):
            v.promotional_price = _precio_valido(body["promotional_price"])
    except (TypeError, ValueError):
        raise HTTPException(400, "Valor inválido")
    db.commit()
    return {"ok": True}


@router.post("/products")
async def create_product(
    name: str = Form(...),
    brand: str = Form(...),
    description: str = Form(""),
    # Precio opcional: en los productos "a pedido" el precio puede no saberse
    # todavía. En el catálogo normal sigue siendo obligatorio (se valida abajo).
    price: str = Form(""),
    talles: str = Form(""),
    stock_por_talle: int = Form(1),
    publicado: bool = Form(True),
    # Producto "a pedido": no es stock real ni se publica en la tienda. Queda en
    # la pestaña aparte del panel para tomar reservas.
    a_pedido: bool = Form(False),
    images: List[UploadFile] = File([]),
    convertir_a_ars: bool = Form(False),
    # Grados de giro por imagen, en el mismo orden que `images` ("0,90,0").
    # El formulario ya lo mandaba, pero el backend no lo recibía: la foto que
    # se veía derecha en la vista previa se subía igual de dada vuelta.
    rotations: str = Form(""),
    db: Session = Depends(get_db),
):
    talles_list = [t.strip().upper() for t in re.split(r"[,;]", talles) if t.strip()]
    base_handle = slugify(f"{brand}-{name}")
    handle = unique_handle(db, base_handle)
    sku_base = re.sub(r"[^A-Z0-9]", "", _strip_accents(f"{brand}{name}").upper())[:30] or "PROD"

    # Un producto "a pedido" nunca se publica en la tienda (no es stock real) y
    # su stock arranca en 0.
    if a_pedido:
        publicado = False
        stock_por_talle = 0

    rate = Decimal(str(current_usd_rate(db)))
    if not price.strip():
        if not a_pedido:
            raise HTTPException(400, "Falta el precio")
        precio_ars = None    # a pedido sin precio definido todavía
        usd_val = None
    else:
        precio_num = _precio_valido(price)
        if convertir_a_ars:
            usd_val = precio_num
            precio_ars = (precio_num * rate).quantize(Decimal("0.01"))
        else:
            precio_ars = precio_num.quantize(Decimal("0.01"))
            usd_val = (precio_ars / rate).quantize(Decimal("0.01")) if rate else None

    # La descripción se renderiza con `| safe` en la tienda, así que el HTML
    # que se guarda tiene que ser SOLO el que armamos acá: los valores del
    # formulario van escapados. Sin esto, un `<script>` guardado desde el panel
    # queda persistente en el dominio donde vive el checkout de Stripe.
    desc = f"<p>{html.escape(name)}</p>"
    if brand:
        desc += f"<p>Marca: {html.escape(brand)}</p>"
    desc += (f"<p>{html.escape(description)}</p>" if description
             else "<p>Producto original importado.</p>")

    prod = Product(name=name, handle=handle, description=desc, brand=brand,
                   published=publicado, a_pedido=a_pedido)
    db.add(prod)
    db.flush()

    talles_iter = talles_list or [None]
    for i, t in enumerate(talles_iter, 1):
        db.add(Variant(
            product_id=prod.id, price=precio_ars, usd_price=usd_val, stock=stock_por_talle,
            sku=f"{sku_base}-{slugify(t).upper()}" if t else sku_base, value=t, position=i,
        ))
    db.flush()

    imgs_ok = 0
    giros = [int(g) % 360 if g.strip().lstrip("-").isdigit() else 0
             for g in (rotations or "").split(",")]
    for i, upfile in enumerate(images, 1):
        content = await upfile.read()
        safe_name = validate_image(upfile.filename or "", upfile.content_type or "", content)
        # Aplicar el giro que el usuario le dio en la vista previa ANTES de
        # guardar: si no, la foto se sube tal como salió de la cámara.
        giro = giros[i - 1] if i - 1 < len(giros) else 0
        if giro:
            content = _rotar_bytes(content, giro)
        src, local_path = store_image_bytes(content, upfile.content_type or "", handle, safe_name)
        db.add(ProductImage(product_id=prod.id, src=src, local_path=local_path,
                            position=i, alt=name))
        imgs_ok += 1
    db.commit()

    return {
        "ok": True,
        "product_id": prod.id,
        "a_pedido": a_pedido,
        # Los "a pedido" no viven en la tienda: no tiene sentido un link público.
        "url": None if a_pedido else f"{settings.STORE_BASE_URL}/productos/{handle}/",
        "imagenes_subidas": imgs_ok,
        "variantes_creadas": len(talles_iter),
    }


@router.post("/products/{pid}/images")
async def upload_image(pid: int, file: UploadFile = File(...),
                       position: Optional[int] = Form(None),
                       db: Session = Depends(get_db)):
    p = db.get(Product, pid)
    if not p:
        raise HTTPException(404, "Producto no encontrado")
    content = await file.read()
    safe_name = validate_image(file.filename or "", file.content_type or "", content)
    src, local_path = store_image_bytes(content, file.content_type or "", p.handle, safe_name)
    # Sin posición explícita, la foto va al final de la galería. Antes entraban
    # todas con 99: al subir varias de una quedaban empatadas y el orden que
    # veía el cliente en la tienda salía al azar.
    if position is None:
        position = (max((im.position or 0) for im in p.images) + 1) if p.images else 1
    db.add(ProductImage(product_id=p.id, src=src, local_path=local_path,
                        position=position, alt=p.name))
    db.commit()
    return {"ok": True, "src": src}


# --------------------------------------------------------------------------- #
# Pedidos / estadísticas
# --------------------------------------------------------------------------- #
@router.get("/orders/{oid}")
def get_order(oid: int, db: Session = Depends(get_db)):
    o = db.get(Order, oid)
    if not o:
        raise HTTPException(404, "Pedido no encontrado")
    return order_to_tn(o)


@router.post("/orders/{oid}/status")
def set_order_status(oid: int, body: dict, db: Session = Depends(get_db)):
    from core.models import ORDER_STATUSES
    o = db.get(Order, oid)
    if not o:
        raise HTTPException(404, "Pedido no encontrado")
    new = body.get("status")
    if new not in ORDER_STATUSES:
        raise HTTPException(400, f"Estado inválido. Opciones: {', '.join(ORDER_STATUSES)}")
    # "refunded" solo puede salir del endpoint de reembolso, que sí le pide la
    # plata a Stripe. Marcarlo a mano dejaba al cliente sin su devolución y con
    # el pedido figurando como reembolsado (contracargo asegurado a los 60 días).
    if new == "refunded":
        raise HTTPException(409, "Usá el botón de reembolso: marcarlo a mano no "
                                 "devuelve el dinero en Stripe")
    o.status = new
    db.commit()
    return {"ok": True, "status": o.status}


@router.post("/orders/reconciliar")
def reconciliar_pagos(db: Session = Depends(get_db)):
    """Revisa los pedidos pendientes contra Stripe y acredita los ya cobrados.

    Existe porque el webhook puede no llegar (mal configurado, caído o
    demorado) y en ese caso el pedido queda "pendiente" con la plata cobrada.
    Acá se pregunta el estado real de cada PaymentIntent y se corrige.

    Es seguro de correr las veces que haga falta: solo toca pedidos que Stripe
    confirma como pagados y cuyo monto y moneda coinciden con lo esperado.
    """
    if not settings.STRIPE_SECRET_KEY:
        raise HTTPException(503, "Stripe no está configurado")
    import stripe
    stripe.api_key = settings.STRIPE_SECRET_KEY

    from core.models import AuditLog, CartItem, Payment

    pendientes = (db.query(Order)
                  .filter(Order.payment_status == "pending")
                  .order_by(Order.id.desc()).limit(200).all())

    acreditados, sin_pagar, revisar, errores = [], [], [], []
    minor = settings.currency_minor_units

    for o in pendientes:
        pago = (db.query(Payment)
                .filter(Payment.order_id == o.id,
                        Payment.stripe_payment_intent_id.isnot(None))
                .order_by(Payment.id.desc()).first())
        if not pago:
            continue
        try:
            intent = stripe.PaymentIntent.retrieve(pago.stripe_payment_intent_id)
        except Exception as e:  # noqa: BLE001
            errores.append({"pedido": o.number, "error": str(e)[:120]})
            continue

        if intent.get("status") != "succeeded":
            sin_pagar.append({"pedido": o.number, "estado_stripe": intent.get("status")})
            continue

        cobrado = Decimal(intent.get("amount_received") or intent.get("amount") or 0) / minor
        moneda = (intent.get("currency") or "").upper()[:3]
        if cobrado != pago.amount or moneda != (pago.currency or "").upper()[:3]:
            pago.status = "review"
            revisar.append({"pedido": o.number, "cobrado": f"{cobrado} {moneda}",
                            "esperado": f"{pago.amount} {pago.currency}"})
            continue

        o.payment_status = "paid"
        o.status = "processing"
        pago.status = "paid"
        pago.raw = {"confirmado_por": "reconciliacion_manual"}
        if o.cart_id:
            db.query(CartItem).filter(CartItem.cart_id == o.cart_id).delete(
                synchronize_session=False)
        db.add(AuditLog(user_id=o.user_id, action="payment_reconciled",
                        entity="order", entity_id=str(o.id)))
        acreditados.append({"pedido": o.number, "monto": f"{cobrado} {moneda}"})

    db.commit()
    return {
        "ok": True,
        "revisados": len(pendientes),
        "acreditados": acreditados,
        "sin_pagar": sin_pagar,
        "para_revisar": revisar,
        "errores": errores,
    }


@router.post("/orders/{oid}/refund")
def refund_order(oid: int, db: Session = Depends(get_db)):
    """Reembolsa el pago de Stripe asociado a la orden y marca el pedido."""
    o = db.get(Order, oid)
    if not o:
        raise HTTPException(404, "Pedido no encontrado")
    # Validar el ESTADO antes que la config: reembolsar algo no cobrado es un
    # error de operación, no de configuración, y el mensaje tiene que decirlo.
    # Sin este control se llamaba a Stripe sobre órdenes pendientes o ya
    # reembolsadas y el error crudo de Stripe volvía al cliente.
    if o.payment_status == "refunded":
        return {"ok": True, "already": True, "status": "refunded"}
    if o.payment_status != "paid":
        raise HTTPException(409, f"La orden no está pagada (estado: {o.payment_status})")
    if not settings.STRIPE_SECRET_KEY:
        raise HTTPException(503, "Stripe no está configurado")

    from core.models import AuditLog, Payment
    payment = (
        db.query(Payment).filter(Payment.order_id == o.id,
                                 Payment.stripe_payment_intent_id.isnot(None))
        .order_by(Payment.id.desc()).first()
    )
    if not payment or not payment.stripe_payment_intent_id:
        raise HTTPException(400, "No hay pago de Stripe para reembolsar")
    import stripe
    stripe.api_key = settings.STRIPE_SECRET_KEY
    try:
        refund = stripe.Refund.create(
            payment_intent=payment.stripe_payment_intent_id,
            # Doble click = un solo reembolso, no dos.
            idempotency_key=f"refund-order-{o.id}",
        )
    except stripe.StripeError as e:
        log.exception("Stripe rechazó el reembolso de la orden %s", o.id)
        raise HTTPException(502, "No se pudo reembolsar. Revisá el panel de Stripe.") from e

    payment.status = "refunded"
    o.payment_status = "refunded"
    o.status = "refunded"
    # Reponer stock una sola vez. Dejar stock_reserved en True hacía que un
    # `canceled` tardío volviera a sumar las mismas unidades (stock fantasma).
    if o.stock_reserved:
        for it in o.items:
            v = db.get(Variant, it.variant_id, with_for_update=True) if it.variant_id else None
            if v:
                v.stock = (v.stock or 0) + it.quantity
        o.stock_reserved = False
    db.add(AuditLog(action="order_refunded", entity="order", entity_id=str(o.id)))
    db.commit()
    return {"ok": True, "refund_id": refund.id, "status": "refunded"}


@router.get("/orders")
def list_orders(per_page: int = 50, page: int = 1, status: Optional[str] = None,
                db: Session = Depends(get_db)):
    query = db.query(Order)
    if status:
        query = query.filter(Order.payment_status == status)
    items = query.order_by(Order.created_at.desc()).offset((page - 1) * per_page).limit(per_page).all()
    return [order_to_tn(o) for o in items]


@router.get("/stats")
def stats(db: Session = Depends(get_db)):
    productos = _productos_completos(db).all()
    total_productos = len(productos)
    total_publicados = sum(1 for p in productos if p.published)
    total_variantes = db.query(Variant).count()
    total_stock = db.query(func.coalesce(func.sum(Variant.stock), 0)).scalar() or 0
    productos_sin_stock = sum(1 for p in productos if p.total_stock == 0)

    pedidos = db.query(Order).all()
    total_pedidos = len(pedidos)
    total_facturado = float(sum((o.total or 0) for o in pedidos))
    pedidos_pagados = sum(1 for o in pedidos if o.payment_status == "paid")
    pedidos_pendientes = sum(1 for o in pedidos if o.payment_status == "pending")

    contar = {}
    for o in pedidos:
        for it in o.items:
            if it.product_id:
                contar[it.product_id] = contar.get(it.product_id, 0) + it.quantity
    top = sorted(contar.items(), key=lambda x: -x[1])[:10]
    name_by_id = {p.id: p.name for p in productos}
    top_named = [{"product_id": pid, "name": name_by_id.get(pid, "?"), "vendidos": q} for pid, q in top]

    stock_bajo = [
        {"id": p.id, "name": p.name, "brand": p.brand, "stock": p.total_stock}
        for p in productos if p.total_stock <= 1
    ][:20]

    return {
        "productos": {
            "total": total_productos, "publicados": total_publicados,
            "sin_stock": productos_sin_stock, "variantes": total_variantes,
            "stock_total": int(total_stock),
        },
        "pedidos": {
            "total": total_pedidos, "pagados": pedidos_pagados, "pendientes": pedidos_pendientes,
            "facturado_total": total_facturado,
            "ticket_promedio": (total_facturado / total_pedidos) if total_pedidos else 0,
        },
        "top_vendidos": top_named,
        "stock_bajo": stock_bajo,
    }


# --------------------------------------------------------------------------- #
# Precios USD (ahora 100% sobre la DB propia)
# --------------------------------------------------------------------------- #
@router.get("/usd_prices")
def usd_prices_get(db: Session = Depends(get_db)):
    prices = {}
    for p in _productos_completos(db).all():
        v = p.variants[0] if p.variants else None
        if v and v.usd_price is not None:
            prices[str(p.id)] = float(v.usd_price)
    return {"prices": prices, "rate": current_usd_rate(db)}


@router.post("/usd_prices")
def usd_prices_save(body: dict, db: Session = Depends(get_db)):
    # La cotización se guarda ACÁ, en la tabla settings, que es de donde la lee
    # current_usd_rate(). El botón "Guardar cotización" la mandaba a
    # /api/bot_config (un JSON suelto del bot) y el recálculo nunca la veía:
    # guardabas 1500 y seguía multiplicando por 1410.
    if body.get("rate") is not None:
        try:
            rate = Decimal(str(body["rate"]))
        except (InvalidOperation, TypeError, ValueError):
            raise HTTPException(400, "Cotización inválida")
        if not rate.is_finite() or rate <= 0 or rate > Decimal("1000000"):
            raise HTTPException(400, "Cotización fuera de rango")
        s = db.get(Setting, "usd_rate")
        if not s:
            s = Setting(key="usd_rate")
            db.add(s)
        s.value = {"rate": float(rate)}

    prices = body.get("prices") or {}
    saved = 0
    for pid, usd in prices.items():
        try:
            usd_d = Decimal(str(usd))
        except Exception:
            continue
        p = db.get(Product, int(pid))
        if not p:
            continue
        for v in p.variants:
            v.usd_price = usd_d
        saved += 1
    db.commit()
    return {"ok": True, "saved_count": saved, "rate": current_usd_rate(db)}


@router.post("/usd_prices/from_current")
def usd_prices_seed(db: Session = Depends(get_db)):
    rate = Decimal(str(current_usd_rate(db)))
    if rate <= 0:
        raise HTTPException(400, "USD rate inválido")
    count = 0
    for p in _productos_completos(db).all():
        for v in p.variants:
            if v.price:
                v.usd_price = (v.price / rate).quantize(Decimal("0.01"))
        count += 1
    db.commit()
    return {"ok": True, "count": count, "rate": float(rate)}


@router.post("/usd_prices/sync_to_tiendanube")
def usd_prices_sync(db: Session = Depends(get_db)):
    """Recalcula ARS = USD × rate en TODAS las variantes (ya no toca Tiendanube,
    actualiza nuestra propia base — el nombre se mantiene por compatibilidad del frontend)."""
    rate = Decimal(str(current_usd_rate(db)))
    updated_products = updated_variants = 0
    for p in _productos_completos(db).all():
        touched = False
        for v in p.variants:
            if v.usd_price is not None:
                v.price = (v.usd_price * rate).quantize(Decimal("0.01"))
                updated_variants += 1
                touched = True
        if touched:
            updated_products += 1
    db.commit()
    return {"ok": True, "updated_products": updated_products,
            "updated_variants": updated_variants, "rate": float(rate)}


# --------------------------------------------------------------------------- #
# Export Excel (desde la DB)
# --------------------------------------------------------------------------- #
@router.get("/export/excel")
def export_excel(db: Session = Depends(get_db)):
    from openpyxl import Workbook
    from openpyxl.styles import Font, PatternFill

    productos = _productos_completos(db).order_by(Product.id.desc()).all()
    pedidos = db.query(Order).order_by(Order.created_at.desc()).limit(1000).all()

    wb = Workbook()
    ws = wb.active
    ws.title = "productos"
    ws.append(["id", "nombre", "marca", "publicado", "url", "stock_total",
               "variantes", "precio_min", "categorías"])
    for p in productos:
        cats = " | ".join(c.name for c in p.categories)
        ws.append([p.id, p.name, p.brand, p.published,
                   f"{settings.STORE_BASE_URL}/productos/{p.handle}/",
                   p.total_stock, len(p.variants),
                   float(p.min_price) if p.min_price else 0, cats])

    wsv = wb.create_sheet("variantes")
    wsv.append(["product_id", "product_name", "variant_id", "sku", "talle", "precio", "stock"])
    for p in productos:
        for v in p.variants:
            wsv.append([p.id, p.name, v.id, v.sku, v.value,
                        float(v.price) if v.price else 0, v.stock])

    wsp = wb.create_sheet("pedidos")
    wsp.append(["id", "numero", "fecha", "estado", "pago", "total", "moneda",
                "cliente", "email", "telefono", "productos"])
    for o in pedidos:
        prods = " | ".join(f"{it.product_name} x{it.quantity}" for it in o.items)
        wsp.append([o.id, o.number, o.created_at.isoformat() if o.created_at else "",
                    o.status, o.payment_status, float(o.total or 0), o.currency,
                    o.contact_name, o.email, o.contact_phone, prods])

    for sh in (ws, wsv, wsp):
        for cell in sh[1]:
            cell.font = Font(bold=True, color="FFFFFF")
            cell.fill = PatternFill(start_color="111111", end_color="111111", fill_type="solid")
        sh.freeze_panes = "A2"

    buf = io.BytesIO()
    wb.save(buf)
    buf.seek(0)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    return StreamingResponse(
        buf,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename=miami_import_export_{stamp}.xlsx"},
    )


# --------------------------------------------------------------------------- #
# Reservas de productos "a pedido"
# --------------------------------------------------------------------------- #
@router.get("/reservas")
def list_reservas(db: Session = Depends(get_db)):
    """Todas las reservas, las pendientes primero y dentro de cada grupo las
    más nuevas arriba."""
    orden = case((Reserva.status == "pendiente", 0),
                 (Reserva.status == "avisado", 1),
                 (Reserva.status == "entregado", 2),
                 else_=3)
    reservas = (db.query(Reserva)
                .order_by(orden, Reserva.created_at.desc())
                .all())
    return [reserva_to_dict(r) for r in reservas]


@router.post("/reservas")
def create_reserva(body: dict, db: Session = Depends(get_db)):
    """Registra que un cliente quiere un producto (y opcionalmente un talle).

    El producto tiene que ser uno "a pedido". Se guardan copias del nombre y el
    talle para que la reserva se lea aunque el producto se borre después.
    """
    nombre = str(body.get("customer_name") or "").strip()[:255]
    if not nombre:
        raise HTTPException(400, "Falta el nombre del cliente")

    pid = body.get("product_id")
    prod = db.get(Product, int(pid)) if pid not in (None, "") else None
    if not prod:
        raise HTTPException(404, "Producto no encontrado")
    if not prod.a_pedido:
        raise HTTPException(400, "Solo se reservan productos de la pestaña 'A pedido'")

    talle = None
    variant_id = body.get("variant_id")
    if variant_id not in (None, ""):
        v = db.get(Variant, int(variant_id))
        if not v or v.product_id != prod.id:
            raise HTTPException(400, "El talle no es de este producto")
        variant_id = v.id
        talle = v.value
    else:
        variant_id = None

    r = Reserva(
        product_id=prod.id,
        variant_id=variant_id,
        product_name=prod.name,
        talle=talle,
        customer_name=nombre,
        customer_phone=(str(body.get("customer_phone") or "").strip()[:50] or None),
        notes=(str(body.get("notes") or "").strip()[:1000] or None),
        status="pendiente",
    )
    db.add(r)
    db.commit()
    db.refresh(r)
    return reserva_to_dict(r)


@router.post("/reservas/{rid}/status")
def set_reserva_status(rid: int, body: dict, db: Session = Depends(get_db)):
    r = db.get(Reserva, rid)
    if not r:
        raise HTTPException(404, "Reserva no encontrada")
    nuevo = str(body.get("status") or "").strip().lower()
    if nuevo not in RESERVA_STATUSES:
        raise HTTPException(400, f"Estado inválido: {nuevo or '(vacío)'}")
    r.status = nuevo
    db.commit()
    return reserva_to_dict(r)


@router.delete("/reservas/{rid}")
def delete_reserva(rid: int, db: Session = Depends(get_db)):
    r = db.get(Reserva, rid)
    if not r:
        raise HTTPException(404, "Reserva no encontrada")
    db.delete(r)
    db.commit()
    return {"ok": True}
