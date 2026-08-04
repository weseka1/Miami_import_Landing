#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Migrador de catálogo Tiendanube -> base de datos propia.

Fuentes:
  --backup RUTA.json   Lee un export estático de productos (recomendado, sin rate limits).
  --live               Descarga TODO en vivo desde la API de Tiendanube (usa el token del .env).

Por defecto intenta el backup conocido y, si no existe, cae a --live.

Uso:
    python migrate_from_tiendanube.py                 # auto
    python migrate_from_tiendanube.py --backup ruta.json
    python migrate_from_tiendanube.py --live
    python migrate_from_tiendanube.py --skip-images   # no descarga fotos (usa URLs del CDN)

Es idempotente: re-correrlo actualiza por tn_id en vez de duplicar.
"""
from __future__ import annotations

import argparse
import sys
from decimal import Decimal, InvalidOperation
from pathlib import Path

# Usar el almacén de certificados del SO (arregla SSL en Windows al bajar del CDN).
try:
    import truststore
    truststore.inject_into_ssl()
except Exception:  # noqa: BLE001
    pass

from core import storage
from core.config import settings
from core.db import SessionLocal, init_db
from core.models import Category, Product, ProductImage, Variant
from core.sanitize import clean_description

HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent
STORE_STATIC = PROJECT_ROOT / "web-tienda" / "static"
IMAGES_DIR = STORE_STATIC / "products"

# Backup conocido (fuera de las carpetas de trabajo, solo lectura)
DEFAULT_BACKUP = (
    PROJECT_ROOT.parent
    / "Stock mIAmimport_-20260422T165214Z-3-001"
    / "Stock mIAmimport_"
    / "backup_productos_20260529_172844.json"
)


# --------------------------------------------------------------------------- #
# Utilidades
# --------------------------------------------------------------------------- #
def load_json_repairing_encoding(path: Path):
    """Carga JSON arreglando el mojibake del backup (latin-1/cp1252 vs utf-8)."""
    import json

    raw = path.read_bytes()
    for enc in ("utf-8", "cp1252", "latin-1"):
        try:
            text = raw.decode(enc)
        except UnicodeDecodeError:
            continue
        if "�" in text:  # carácter de reemplazo => encoding equivocado
            continue
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            continue
    # Último recurso: utf-8 tolerante
    return json.loads(raw.decode("utf-8", errors="replace"))


def es(value):
    """Extrae el texto es de los campos i18n de Tiendanube ({'es': '...'} o str)."""
    if isinstance(value, dict):
        return value.get("es") or next(iter(value.values()), None)
    return value


def to_decimal(v):
    if v in (None, ""):
        return None
    try:
        return Decimal(str(v))
    except (InvalidOperation, ValueError):
        return None


def fetch_live_products() -> list[dict]:
    """Trae TODOS los productos paginando la API de Tiendanube."""
    import requests

    if not settings.TIENDANUBE_STORE_ID or not settings.TIENDANUBE_ACCESS_TOKEN:
        sys.exit("ERROR: faltan TIENDANUBE_STORE_ID / TIENDANUBE_ACCESS_TOKEN en .env para --live")
    base = f"https://api.tiendanube.com/v1/{settings.TIENDANUBE_STORE_ID}"
    headers = {
        "Authentication": f"bearer {settings.TIENDANUBE_ACCESS_TOKEN}",
        "User-Agent": settings.TIENDANUBE_USER_AGENT,
        "Content-Type": "application/json",
    }
    out: list[dict] = []
    page = 1
    while True:
        r = requests.get(f"{base}/products?per_page=200&page={page}", headers=headers, timeout=60)
        if not r.ok:
            print(f"  aviso: página {page} respondió {r.status_code}; corto.")
            break
        chunk = r.json()
        if not chunk:
            break
        out.extend(chunk)
        if len(chunk) < 200:
            break
        page += 1
    return out


def download_image(url: str, dest: Path) -> bool:
    import requests

    try:
        r = requests.get(url, timeout=60)
        if not r.ok:
            return False
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(r.content)
        return True
    except Exception as e:  # noqa: BLE001
        print(f"    error bajando {url}: {e}")
        return False


# --------------------------------------------------------------------------- #
# Migración
# --------------------------------------------------------------------------- #
def upsert_categories(db, products: list[dict]) -> dict[int, Category]:
    """Recolecta todas las categorías de todos los productos y las upsertea.
    Devuelve mapa tn_id -> Category. Resuelve parent en segunda pasada."""
    raw: dict[int, dict] = {}
    for p in products:
        for c in p.get("categories") or []:
            cid = c.get("id")
            if cid is not None:
                raw[cid] = c

    by_tn: dict[int, Category] = {}
    for tn_id, c in raw.items():
        cat = db.query(Category).filter_by(tn_id=tn_id).one_or_none()
        if not cat:
            cat = Category(tn_id=tn_id)
            db.add(cat)
        cat.name = es(c.get("name")) or f"cat-{tn_id}"
        cat.handle = es(c.get("handle")) or f"cat-{tn_id}"
        cat.description = es(c.get("description"))
        cat.seo_title = es(c.get("seo_title"))
        cat.seo_description = es(c.get("seo_description"))
        by_tn[tn_id] = cat
    db.flush()

    # Segunda pasada: parents
    for tn_id, c in raw.items():
        parent_tn = c.get("parent")
        if parent_tn and parent_tn in by_tn:
            by_tn[tn_id].parent_id = by_tn[parent_tn].id
    db.flush()
    return by_tn


def upsert_product(db, p: dict, cat_map: dict[int, Category], download_images: bool) -> Product:
    tn_id = p.get("id")
    prod = db.query(Product).filter_by(tn_id=tn_id).one_or_none()
    if not prod:
        prod = Product(tn_id=tn_id)
        db.add(prod)

    prod.name = es(p.get("name")) or f"producto-{tn_id}"
    prod.handle = es(p.get("handle")) or f"producto-{tn_id}"
    # La descripción de TN es HTML y se renderiza con `| safe` en la tienda:
    # se sanitiza con allow-list para no persistir <script> ejecutable en el
    # dominio donde vive el checkout de Stripe.
    prod.description = clean_description(es(p.get("description")))
    prod.brand = p.get("brand")
    prod.published = bool(p.get("published", True))
    prod.free_shipping = bool(p.get("free_shipping", False))
    prod.video_url = p.get("video_url")
    prod.seo_title = es(p.get("seo_title"))
    prod.seo_description = es(p.get("seo_description"))
    prod.canonical_url = p.get("canonical_url")
    prod.tags = p.get("tags") or []

    # Categorías
    prod.categories = [cat_map[c["id"]] for c in (p.get("categories") or [])
                       if c.get("id") in cat_map]
    db.flush()

    # Variantes (upsert por tn_id; eliminar las que ya no estén)
    incoming_ids = set()
    for i, v in enumerate(p.get("variants") or [], 1):
        v_tn = v.get("id")
        incoming_ids.add(v_tn)
        var = db.query(Variant).filter_by(tn_id=v_tn).one_or_none() if v_tn else None
        if not var:
            var = Variant(tn_id=v_tn, product_id=prod.id)
            db.add(var)
        var.product_id = prod.id
        var.sku = v.get("sku")
        var.price = to_decimal(v.get("price"))
        var.compare_at_price = to_decimal(v.get("compare_at_price"))
        var.promotional_price = to_decimal(v.get("promotional_price"))
        var.stock = int(v.get("stock") or 0)
        vals = v.get("values") or []
        var.value = es(vals[0]) if vals else None
        var.position = v.get("position") or i
        var.weight = to_decimal(v.get("weight"))
        var.visible = bool(v.get("visible", True))
        if settings.USD_TO_ARS_RATE and var.price:
            var.usd_price = (var.price / Decimal(str(settings.USD_TO_ARS_RATE))).quantize(Decimal("0.01"))
    for stale in [v for v in prod.variants if v.tn_id not in incoming_ids]:
        db.delete(stale)
    db.flush()

    # Imágenes (upsert por tn_id)
    incoming_img = set()
    for i, img in enumerate(p.get("images") or [], 1):
        img_tn = img.get("id")
        incoming_img.add(img_tn)
        src = img.get("src")
        if not src:
            continue
        pi = db.query(ProductImage).filter_by(tn_id=img_tn).one_or_none() if img_tn else None
        if not pi:
            pi = ProductImage(tn_id=img_tn, product_id=prod.id)
            db.add(pi)
        pi.product_id = prod.id
        pi.src = src
        pi.position = img.get("position") or i
        alt = img.get("alt")
        pi.alt = (alt[0] if isinstance(alt, list) and alt else (alt or None)) or prod.name
        pi.width = img.get("width")
        pi.height = img.get("height")
        if download_images:
            ext = Path(src.split("?")[0]).suffix or ".jpg"
            rel = f"products/{prod.handle}/{pi.position}{ext}"
            if storage.is_enabled():
                # Bajar del CDN de TN y subir a Supabase Storage.
                try:
                    import requests as _rq
                    resp = _rq.get(src, timeout=60)
                    if resp.ok:
                        ct = resp.headers.get("content-type", "image/jpeg")
                        pi.src = storage.upload_bytes(resp.content, rel, ct)
                        pi.local_path = None
                except Exception as e:  # noqa: BLE001
                    print(f"    no se pudo subir a Supabase {src}: {e}")
            else:
                dest = STORE_STATIC / rel
                if dest.exists() or download_image(src, dest):
                    pi.local_path = f"/static/{rel}"
    for stale in [im for im in prod.images if im.tn_id not in incoming_img]:
        db.delete(stale)
    db.flush()
    return prod


def main():
    ap = argparse.ArgumentParser(description="Migrar catálogo Tiendanube -> DB propia")
    ap.add_argument("--backup", type=str, help="ruta a un JSON export de productos")
    ap.add_argument("--live", action="store_true", help="descargar en vivo desde la API de TN")
    ap.add_argument("--skip-images", action="store_true", help="no descargar fotos (usa URLs del CDN)")
    args = ap.parse_args()

    print("Inicializando base de datos…")
    print(f"  DB: {settings.DATABASE_URL}")
    init_db()

    # Elegir fuente
    if args.live:
        print("Descargando productos en vivo desde Tiendanube…")
        products = fetch_live_products()
    else:
        backup_path = Path(args.backup) if args.backup else DEFAULT_BACKUP
        if backup_path.exists():
            print(f"Leyendo backup: {backup_path}")
            data = load_json_repairing_encoding(backup_path)
            products = data if isinstance(data, list) else data.get("products", [])
        else:
            print(f"No se encontró backup ({backup_path}); intento --live…")
            products = fetch_live_products()

    print(f"Productos a migrar: {len(products)}")
    download = not args.skip_images
    if download:
        print(f"Las imágenes se descargarán a: {IMAGES_DIR}")

    db = SessionLocal()
    try:
        cat_map = upsert_categories(db, products)
        print(f"Categorías upserteadas: {len(cat_map)}")
        n = 0
        for p in products:
            prod = upsert_product(db, p, cat_map, download)
            n += 1
            if n % 10 == 0:
                db.commit()
                print(f"  {n}/{len(products)} productos…")
        db.commit()
        # Resumen
        total_var = db.query(Variant).count()
        total_img = db.query(ProductImage).count()
        total_stock = sum(v.stock for v in db.query(Variant).all())
        print("\n=== MIGRACIÓN COMPLETA ===")
        print(f"  Productos : {db.query(Product).count()}")
        print(f"  Categorías: {db.query(Category).count()}")
        print(f"  Variantes : {total_var}")
        print(f"  Imágenes  : {total_img}")
        print(f"  Stock total (unidades): {total_stock}")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
