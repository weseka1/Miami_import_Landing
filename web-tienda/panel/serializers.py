"""
Serializadores DB -> forma compatible con Tiendanube.

El frontend del panel (y el theme original) consumen la estructura de la API de
Tiendanube (name.es, variants[].values[].es, images[].src, handle.es...). Para
no reescribir el frontend, exponemos los datos de NUESTRA base con esa misma
forma. Así el panel sigue funcionando casi sin tocar el JS.
"""
from __future__ import annotations

from core.models import Order, Product, Reserva, Variant


def _money(d) -> str | None:
    return f"{d:.2f}" if d is not None else None


def variant_to_tn(v: Variant) -> dict:
    return {
        "id": v.id,
        "product_id": v.product_id,
        "position": v.position,
        "price": _money(v.price),
        "compare_at_price": _money(v.compare_at_price),
        "promotional_price": _money(v.promotional_price),
        "usd_price": _money(v.usd_price),
        "stock": v.stock,
        "sku": v.sku,
        "values": [{"es": v.value}] if v.value else [],
        "visible": v.visible,
    }


def image_to_tn(img) -> dict:
    return {
        "id": img.id,
        "product_id": img.product_id,
        "src": img.url,          # local si se descargó, si no CDN
        "position": img.position,
        "alt": [img.alt] if img.alt else [],
        "width": img.width,
        "height": img.height,
    }


def category_to_tn(c) -> dict:
    return {
        "id": c.id,
        "name": {"es": c.name},
        "handle": {"es": c.handle},
        "parent": c.parent_id,
    }


def product_to_tn(p: Product, *, full: bool = True) -> dict:
    data = {
        "id": p.id,
        "name": {"es": p.name},
        "handle": {"es": p.handle},
        "brand": p.brand,
        "published": p.published,
        "a_pedido": bool(p.a_pedido),
        "destacado": bool(getattr(p, "destacado", False)),
        "mas_vendido": bool(getattr(p, "mas_vendido", False)),
        "free_shipping": p.free_shipping,
        "variants": [variant_to_tn(v) for v in p.variants],
        "images": [image_to_tn(i) for i in p.images],
        "categories": [category_to_tn(c) for c in p.categories],
    }
    if full:
        data.update({
            "description": {"es": p.description or ""},
            "seo_title": {"es": p.seo_title or ""},
            "seo_description": {"es": p.seo_description or ""},
            "canonical_url": p.canonical_url,
            "video_url": p.video_url,
            "tags": p.tags or [],
            "created_at": p.created_at.isoformat() if p.created_at else None,
            "updated_at": p.updated_at.isoformat() if p.updated_at else None,
        })
    return data


def reserva_to_dict(r: Reserva) -> dict:
    return {
        "id": r.id,
        "product_id": r.product_id,
        "variant_id": r.variant_id,
        "product_name": r.product_name,
        "talle": r.talle,
        "customer_name": r.customer_name,
        "customer_phone": r.customer_phone,
        "notes": r.notes,
        "status": r.status,
        "created_at": r.created_at.isoformat() if r.created_at else None,
    }


def order_to_tn(o: Order) -> dict:
    return {
        "id": o.id,
        "number": o.number,
        "created_at": o.created_at.isoformat() if o.created_at else None,
        "status": o.status,
        "payment_status": o.payment_status,
        "total": _money(o.total),
        "currency": o.currency,
        "contact_name": o.contact_name,
        "contact_email": o.email,
        "contact_phone": o.contact_phone,
        # Sin esto el operador no tiene a dónde mandar el pedido: el checkout
        # pide calle/ciudad/CP pero nada los exponía. El front ya los esperaba.
        "shipping_address": o.shipping_address or {},
        "products": [
            {
                "product_id": it.product_id,
                "variant_id": it.variant_id,
                "name": it.product_name,
                # El talle IBA escondido dentro del SKU (…OVER NEGR-L) y Diego
                # tenía que adivinarlo. Es EL dato para despachar ropa.
                "talle": it.variant_value,
                "sku": it.sku,
                "quantity": it.quantity,
                "price": _money(it.unit_price),
            }
            for it in o.items
        ],
    }
