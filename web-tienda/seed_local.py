"""Seed de la DB LOCAL (sandbox) con el catálogo real desde el backup JSON.
NO toca producción — sólo la SQLite local para poder ver productos en el preview."""
import json, pathlib
from decimal import Decimal, InvalidOperation

from core.db import SessionLocal, init_db
from core.config import settings
from core import models as m

# CANDADO DE SEGURIDAD: este seeder BORRA y recarga el catálogo, así que sólo
# puede correr contra una SQLite LOCAL. Si DATABASE_URL apunta a Postgres
# (producción), aborta sin tocar nada.
if not settings.DATABASE_URL.startswith("sqlite"):
    raise SystemExit(
        "ABORT: el seeder SOLO corre contra SQLite local. "
        f"DATABASE_URL={settings.DATABASE_URL[:20]}... no es local — no lo toco."
    )

CAT_JSON = pathlib.Path(__file__).resolve().parent.parent / "catalogo" / "catalogo_tiendanube_completo.json"


def es(v):
    if isinstance(v, dict):
        return v.get("es") or next(iter(v.values()), None)
    return v


def dec(x):
    try:
        return Decimal(str(x)) if x not in (None, "", "null") else None
    except (InvalidOperation, TypeError):
        return None


def uniq(handle, used, fallback):
    h = (handle or fallback) or "item"
    if h in used:
        h = f"{h}-{fallback}"
    used.add(h)
    return h


def main():
    init_db()
    db = SessionLocal()
    try:
        # limpiar catálogo local (es sandbox)
        db.query(m.Variant).delete()
        db.query(m.ProductImage).delete()
        db.execute(m.product_categories.delete())
        db.query(m.Product).delete()
        db.query(m.Category).delete()
        db.commit()

        data = json.loads(CAT_JSON.read_text(encoding="utf-8"))

        # categorías (dos pasadas para el parent)
        raw = {}
        for p in data:
            for c in (p.get("categories") or []):
                raw[c["id"]] = c
        cat_by_tn, used_ch = {}, set()
        for tn, c in raw.items():
            cat = m.Category(tn_id=tn, name=es(c["name"]) or str(tn),
                             handle=uniq(es(c.get("handle")), used_ch, str(tn)),
                             description=es(c.get("description")))
            db.add(cat); cat_by_tn[tn] = cat
        db.flush()
        for tn, c in raw.items():
            par = c.get("parent")
            if par and par in cat_by_tn:
                cat_by_tn[tn].parent_id = cat_by_tn[par].id
        db.flush()

        # productos
        n, used_ph = 0, set()
        for p in data:
            try:
                prod = m.Product(
                    tn_id=p.get("id"),
                    name=es(p.get("name")) or "Producto",
                    handle=uniq(es(p.get("handle")), used_ph, f"prod-{p.get('id')}"),
                    description=es(p.get("description")),
                    brand=p.get("brand"),
                    published=bool(p.get("published", True)),
                )
                for c in (p.get("categories") or []):
                    cat = cat_by_tn.get(c["id"])
                    if cat:
                        prod.categories.append(cat)
                for i, v in enumerate(p.get("variants") or [], start=1):
                    vals = v.get("values") or []
                    prod.variants.append(m.Variant(
                        tn_id=v.get("id"), sku=v.get("sku"),
                        price=dec(v.get("price")),
                        compare_at_price=dec(v.get("compare_at_price")),
                        stock=int(v.get("stock") or 0),
                        value=(es(vals[0]) if vals else None),
                        position=v.get("position") or i,
                    ))
                for j, im in enumerate(p.get("images") or [], start=1):
                    prod.images.append(m.ProductImage(
                        tn_id=im.get("id"), src=im.get("src") or "",
                        position=im.get("position") or j,
                        width=im.get("width"), height=im.get("height"),
                    ))
                db.add(prod); n += 1
            except Exception as e:  # noqa: BLE001
                print("skip", p.get("id"), e)
        db.commit()
        print(f"SEED OK: {n} productos, {len(cat_by_tn)} categorias")
    finally:
        db.close()


if __name__ == "__main__":
    main()
