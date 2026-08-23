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


# Lo que informa Stripe -> lo que Diego necesita leer. La pregunta textual
# fue: "¿seria porque intento pagar y no pudo o como es?".
_MOTIVOS = {
    "requires_payment_method": "no_intento",     # o intento y le rebotó: lo decide el error
    "requires_confirmation": "empezo_sin_confirmar",
    "requires_action": "espera_banco",
    "processing": "procesando",
    "canceled": "cancelado",
    "requires_capture": "autorizado_sin_cobrar",
}


# Los motivos de rechazo mas comunes, en castellano. Stripe los manda en
# ingles; el `decline_code` es estable y se traduce sin ambiguedad.
_RECHAZOS = {
    "insufficient_funds": "la tarjeta no tenía fondos",
    "generic_decline": "el banco la rechazó sin dar motivo",
    "do_not_honor": "el banco la rechazó (tiene que llamar al banco)",
    "card_declined": "el banco rechazó la tarjeta",
    "expired_card": "la tarjeta está vencida",
    "incorrect_cvc": "el código de seguridad estaba mal",
    "incorrect_number": "el número de tarjeta estaba mal",
    "invalid_expiry_year": "la fecha de vencimiento estaba mal",
    "invalid_expiry_month": "la fecha de vencimiento estaba mal",
    "processing_error": "hubo un error del procesador; puede reintentar",
    "lost_card": "la tarjeta figura como perdida",
    "stolen_card": "la tarjeta figura como robada",
    "call_issuer": "el banco pide que lo llame para autorizarla",
    "transaction_not_allowed": "el banco no permite este tipo de compra",
    "currency_not_supported": "la tarjeta no opera en esa moneda",
    "card_not_supported": "la tarjeta no sirve para compras por internet",
    "authentication_required": "el banco pidió una verificación que no completó",
}


def _texto_rechazo(pago) -> str:
    """El motivo del rechazo en castellano; si no lo conocemos, el de Stripe."""
    codigo = (getattr(pago, "error_code", None) or "").strip()
    if codigo in _RECHAZOS:
        return _RECHAZOS[codigo]
    # Los mensajes de Stripe ya vienen con punto final; se lo sacamos para que
    # la frase no termine en "..".
    return (pago.error_message or "").strip().rstrip(".")


def _motivo_humano(pago, orden_status: str | None = None) -> str | None:
    """Una frase que contesta '¿que paso con esta plata?'."""
    # Cobrado SIN mercaderia: es el unico caso donde la plata entro y NO hay
    # que despachar. Antes el early-return de 'paid' apagaba justo este aviso.
    if orden_status == "backorder":
        detalle = (pago.error_message or "").strip()
        return ("La plata entró pero NO quedaba mercadería para este pedido. "
                "NO despachar: conseguí la prenda o devolvele la plata."
                + (f" ({detalle})" if detalle else ""))
    if pago.status == "review":
        detalle = (pago.error_message or "").strip()
        return ("Stripe cobró un monto distinto al del pedido. La plata puede "
                "estar adentro: revisá en Stripe antes de despachar."
                + (f" {detalle}." if detalle else ""))
    if pago.status == "paid":
        return None

    # Reserva vencida: NO es una venta perdida, es una venta a rescatar.
    raw = pago.raw if isinstance(pago.raw, dict) else {}
    if raw.get("cancelado_por") == "reserva_vencida":
        base = (f"Pasaron {raw.get('minutos', 30)} minutos sin que pagara, así que la "
                "prenda volvió a estar a la venta. El pedido sigue acá: si lo "
                "contactás y quiere, tiene que hacer la compra de nuevo.")
        detalle = _texto_rechazo(pago)
        return f"{base} Antes de eso: {detalle}." if detalle else base

    estado = getattr(pago, "estado_stripe", None)
    if not estado:
        return None
    detalle = _texto_rechazo(pago)
    clave = _MOTIVOS.get(estado)
    if clave == "no_intento":
        if detalle:
            return f"Intentó pagar y no pudo: {detalle}."
        return ("Llegó hasta el checkout y no llegó a intentar el pago. "
                "Nunca se le cobró nada.")
    if clave == "espera_banco":
        return "Empezó a pagar y quedó esperando la confirmación del banco."
    if clave == "empezo_sin_confirmar":
        return "Empezó el pago y no lo confirmó."
    if clave == "procesando":
        return "El pago se está procesando. Esperá a que Stripe lo confirme."
    if clave == "cancelado":
        return "El pago se canceló. No se cobró nada."
    if clave == "autorizado_sin_cobrar":
        return "La tarjeta quedó autorizada pero el cobro no se completó."
    return f"Stripe informa: {estado}." + (f" {detalle}" if detalle else "")


_MEDIOS = {
    "card": "Tarjeta", "link": "Link de Stripe", "bank_transfer": "Transferencia",
    "customer_balance": "Saldo del cliente", "boleto": "Boleto",
}


def _pago_to_dict(o: Order) -> dict:
    """El rastro del cobro, para que Diego pueda PROBAR que entro la plata.

    Se prefiere el pago acreditado; si no hay, se muestra el ultimo intento
    (asi tambien se ve por que NO entro). Un pedido sin fila de pago devuelve
    {} y el panel simplemente no dibuja el bloque.
    """
    pagos = list(o.payments or [])
    if not pagos:
        return {}
    pago = next((x for x in reversed(pagos) if x.status in ("paid", "refunded")), pagos[-1])
    tarjeta = None
    if pago.card_brand and pago.card_last4:
        tarjeta = f"{pago.card_brand.upper()} ....{pago.card_last4}"
    elif getattr(pago, "metodo", None):
        # No todo cobro es con tarjeta. Mostrar el medio real es mejor que un
        # guion: le dice a Diego por donde entro la plata.
        tarjeta = _MEDIOS.get(pago.metodo, pago.metodo.replace("_", " ").title())
    return {
        "estado": pago.status,
        "intent_id": pago.stripe_payment_intent_id,
        "cobro_id": pago.stripe_charge_id,
        "recibo_url": pago.receipt_url,
        "tarjeta": tarjeta,
        "acreditado_en": pago.paid_at.isoformat() if pago.paid_at else None,
        "monto": _money(pago.amount),
        "moneda": pago.currency,
        "detalle": pago.error_message,
        # La frase que contesta "¿intento pagar y no pudo?" sin tecnicismos.
        "motivo": _motivo_humano(pago, o.status),
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
        # Rastro del cobro en Stripe: sin esto, "esta pagado" es solo nuestra
        # palabra y no hay con que responder un reclamo.
        "pago": _pago_to_dict(o),
        # Link para que el cliente termine de pagar ESTE pedido, sin rearmar el
        # carrito. Solo si todavia se puede cobrar: un pedido cancelado no se
        # paga (checkout.py lo corta), y ofrecer un link muerto es peor que no
        # dar ninguno. Es relativo: el front le antepone su propio dominio.
        "link_pago": (f"/pagar/{o.number}?t={o.public_token}"
                      if o.public_token
                      and o.payment_status in ("pending", "failed")
                      and o.status not in ("cancelled", "refunded")
                      else None),
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
