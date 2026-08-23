"""
Punto de venta (mostrador) — armar una venta desde la tablet y cobrarla.

Flujo:
  1. El vendedor arma el carrito en la tablet y pone el nombre del cliente.
  2. POST /api/pos/venta crea la orden, RESERVA el stock y devuelve un QR.
  3. El cliente escanea el QR con su celular y paga en la página de la tienda.
     El cobro entra por la MISMA cuenta de Stripe que las ventas online.
  4. La tablet consulta el estado hasta que el pago se acredita.

La venta queda como una orden más: aparece en Pedidos junto a las online, con
`canal="local"` para poder distinguirlas.

Decisiones (mismo criterio que el checkout público):
  - El precio SIEMPRE se toma de la base, nunca del request.
  - El stock se reserva al crear la venta, con lock de fila.
  - El pago lo confirma Stripe; el panel no puede marcar pagado a mano.
"""
from __future__ import annotations

import io
import logging
from decimal import Decimal, InvalidOperation

from fastapi import Request, APIRouter, Depends, HTTPException
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .auth import get_current_admin
from core.config import settings
from core.db import get_db
from core.models import AuditLog, Order, OrderItem, Product, Variant

log = logging.getLogger("pos")

router = APIRouter(prefix="/api/pos", tags=["punto-de-venta"],
                   dependencies=[Depends(get_current_admin)])

MAX_ITEMS = 60
MAX_QTY = 99


def _next_order_number(db: Session) -> int:
    last = db.query(Order).order_by(Order.number.desc()).first()
    return (last.number + 1) if last and last.number else 1000


def _qr_svg(url: str) -> str:
    """QR del link de pago, generado en el servidor (sin depender de un CDN)."""
    try:
        import qrcode
        import qrcode.image.svg as svg
        buf = io.BytesIO()
        qrcode.make(url, image_factory=svg.SvgPathImage).save(buf)
        return buf.getvalue().decode("utf-8")
    except Exception:  # noqa: BLE001  (sin QR queda el link igual)
        log.exception("No se pudo generar el QR")
        return ""


def _base_publica(request) -> str:
    """El dominio con el que entro la peticion, no el de la variable.

    Mismo criterio que el sitemap (app.py): en produccion STORE_BASE_URL quedo
    apuntando a miami-import-landing.onrender.com, y ese no es un dominio para
    mostrarle a un cliente que escanea el QR.
    """
    try:
        proto = request.headers.get("x-forwarded-proto") or request.url.scheme
        host = request.headers.get("x-forwarded-host") or request.headers.get("host")
        if host:
            return f"{proto}://{host}".rstrip("/")
    except Exception:  # noqa: BLE001
        pass
    return settings.STORE_BASE_URL.rstrip("/")


@router.get("/buscar")
def buscar_productos(q: str = "", db: Session = Depends(get_db)):
    """Busca productos para agregar a la venta. Devuelve solo lo vendible.

    Carga anticipada de variantes e imágenes (selectinload): sin esto era N+1
    —una consulta por producto para las variantes y otra para las imágenes—, y
    contra la Postgres remota eso son cientos de viajes de ida y vuelta. Así son
    3 consultas en total, sin importar cuántos productos vuelvan.
    """
    from sqlalchemy import func
    from sqlalchemy.orm import selectinload

    query = (db.query(Product)
             .options(selectinload(Product.variants),
                      selectinload(Product.images))
             .filter(Product.published.is_(True))
             .order_by(Product.name))
    termino = (q or "").strip().lower()
    if termino:
        like = f"%{termino}%"
        query = query.filter(func.lower(Product.name).like(like)
                             | func.lower(func.coalesce(Product.brand, "")).like(like)
                             | func.lower(func.coalesce(Product.handle, "")).like(like))

    salida = []
    for p in query.limit(60).all():
        variantes = [{
            "variant_id": v.id,
            "talle": v.value or "Único",
            "sku": v.sku,
            "precio": f"{v.price:.2f}" if v.price else None,
            "stock": v.stock or 0,
        } for v in p.variants if v.visible and (v.stock or 0) > 0 and v.price and v.price > 0]
        if not variantes:
            continue          # sin stock o sin precio: no se puede vender
        imgs = p.images
        salida.append({
            "product_id": p.id,
            "nombre": p.name,
            "marca": p.brand or "",
            "imagen": imgs[0].url if imgs else None,
            "variantes": variantes,
        })
    return {"productos": salida}


@router.post("/venta")
def crear_venta(body: dict, request: Request, db: Session = Depends(get_db),
                admin=Depends(get_current_admin)):
    """Crea la venta de mostrador y devuelve el QR para que el cliente pague."""
    items = body.get("items") or []
    if not items:
        raise HTTPException(400, "La venta está vacía")
    if len(items) > MAX_ITEMS:
        raise HTTPException(400, f"Máximo {MAX_ITEMS} ítems por venta")

    cliente = str(body.get("cliente") or "").strip()[:120]
    if not cliente:
        raise HTTPException(400, "Falta el nombre del cliente")
    telefono = str(body.get("telefono") or "").strip()[:40]
    email = str(body.get("email") or "").strip().lower()[:255]
    nota = str(body.get("nota") or "").strip()[:500]

    # --- Separar ítems del catálogo de los sueltos ----------------------------
    # Los "sueltos" son cosas que no están cargadas (un accesorio, un arreglo,
    # algo de última hora). No tienen stock que reservar y el precio lo pone el
    # vendedor: es el ÚNICO caso donde el importe viene del request, y por eso
    # se valida con rango y queda registrado en la auditoría.
    pedido: dict[int, int] = {}
    sueltos: list[tuple[str, Decimal, int]] = []
    for it in items:
        try:
            qty = int(it.get("cantidad", 1))
        except (TypeError, ValueError):
            raise HTTPException(400, "Cantidad inválida")
        if qty < 1 or qty > MAX_QTY:
            raise HTTPException(400, f"Cantidad inválida (1 a {MAX_QTY})")

        if it.get("libre"):
            nombre = str(it.get("nombre") or "").strip()[:200]
            if not nombre:
                raise HTTPException(400, "El ítem suelto necesita una descripción")
            try:
                precio = Decimal(str(it.get("precio")))
            except (InvalidOperation, TypeError, ValueError):
                raise HTTPException(400, f"Precio inválido en «{nombre}»")
            if not precio.is_finite() or precio <= 0 or precio > Decimal("100000000"):
                raise HTTPException(400, f"Precio fuera de rango en «{nombre}»")
            sueltos.append((nombre, precio.quantize(Decimal("0.01")), qty))
            continue

        try:
            vid = int(it.get("variant_id"))
        except (TypeError, ValueError):
            raise HTTPException(400, "Ítem inválido")
        pedido[vid] = pedido.get(vid, 0) + qty   # mismo talle dos veces = suma

    if not pedido and not sueltos:
        raise HTTPException(400, "La venta está vacía")

    subtotal = Decimal("0")
    snapshot = []
    monedas: set[str] = set()
    for vid in sorted(pedido):                    # orden fijo: evita deadlocks
        qty = pedido[vid]
        v = db.get(Variant, vid, with_for_update=True)
        if not v or not v.visible:
            db.rollback()
            raise HTTPException(404, "Un producto de la venta ya no está disponible")
        nombre = v.product.name if v.product else "un producto"
        if not v.product or not v.product.published:
            db.rollback()
            raise HTTPException(409, f"{nombre} ya no está publicado")
        if qty > (v.stock or 0):
            db.rollback()
            raise HTTPException(409, f"Sin stock suficiente de {nombre} "
                                     f"(quedan {v.stock or 0})")
        if not v.price or v.price <= 0:
            db.rollback()
            raise HTTPException(409, f"{nombre} no tiene precio válido")
        monedas.add((v.currency or settings.CHECKOUT_CURRENCY).strip().lower())
        linea = v.price * qty
        subtotal += linea
        snapshot.append((v, qty, v.price, linea))

    # Los sueltos van en la moneda de la tienda (no tienen variante que la fije).
    for nombre, precio, qty in sueltos:
        subtotal += precio * qty
    if sueltos:
        monedas.add(settings.CHECKOUT_CURRENCY.strip().lower())

    if len(monedas) > 1:
        db.rollback()
        raise HTTPException(409, "La venta mezcla productos en distintas monedas")
    moneda = monedas.pop() if monedas else settings.CHECKOUT_CURRENCY

    # --- Crear la orden -------------------------------------------------------
    orden = Order(
        number=_next_order_number(db), email=email or None,
        contact_name=cliente, contact_phone=telefono or None,
        status="pending", payment_status="pending",
        currency=moneda.upper()[:3],
        subtotal=subtotal, shipping_cost=Decimal("0"), discount=Decimal("0"),
        total=subtotal, stock_reserved=True,
        notes=(f"Venta en local. {nota}".strip() if nota else "Venta en local"),
        shipping_address={"canal": "local", "vendedor": admin.email},
    )
    for v, qty, precio, linea in snapshot:
        v.stock = (v.stock or 0) - qty            # reserva
        orden.items.append(OrderItem(
            variant_id=v.id, product_id=v.product_id,
            product_name=v.product.name if v.product else "",
            variant_value=v.value, sku=v.sku,
            unit_price=precio, quantity=qty, subtotal=linea))
    # Ítems sueltos: sin variante ni producto, así que no descuentan stock.
    for nombre, precio, qty in sueltos:
        orden.items.append(OrderItem(
            variant_id=None, product_id=None,
            product_name=nombre, variant_value=None, sku=None,
            unit_price=precio, quantity=qty, subtotal=precio * qty))
    db.add(orden)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(503, "No se pudo generar la venta. Probá de nuevo.")
    db.refresh(orden)

    db.add(AuditLog(user_id=admin.id, action="pos_venta_creada",
                    entity="order", entity_id=str(orden.id)))
    if sueltos:
        # Rastro de quién puso qué precio a mano: es el único importe que no
        # sale del catálogo, así que tiene que quedar auditado.
        db.add(AuditLog(
            user_id=admin.id, action="pos_items_sueltos",
            entity="order", entity_id=str(orden.id),
            detail={"items": [{"nombre": n, "precio": str(pr), "cantidad": q}
                              for n, pr, q in sueltos]}))
    db.commit()

    # El dominio sale de la peticion, no de la variable: en produccion
    # STORE_BASE_URL apunta a miami-import-landing.onrender.com (verificado
    # 23-ago) y ese no es un dominio para mostrarle a un cliente en un QR.
    base = _base_publica(request)
    url_pago = f"{base}/pagar/{orden.number}?t={orden.public_token}"
    return {
        "ok": True,
        "order_id": orden.id,
        "numero": orden.number,
        "total": f"{subtotal:.2f}",
        "moneda": moneda,
        "url_pago": url_pago,
        "qr_svg": _qr_svg(url_pago),
    }


@router.get("/venta/{oid}/estado")
def estado_venta(oid: int, db: Session = Depends(get_db)):
    """Estado del cobro, para que la tablet sepa cuándo se acreditó."""
    o = db.get(Order, oid)
    if not o:
        raise HTTPException(404, "Venta no encontrada")
    return {
        "numero": o.number,
        "pagado": o.payment_status == "paid",
        "estado_pago": o.payment_status,
        "estado": o.status,
        "total": f"{o.total:.2f}",
    }


@router.post("/venta/{oid}/cancelar")
def cancelar_venta(oid: int, db: Session = Depends(get_db),
                   admin=Depends(get_current_admin)):
    """Cancela una venta sin pagar y devuelve el stock reservado."""
    o = db.get(Order, oid)
    if not o:
        raise HTTPException(404, "Venta no encontrada")
    if o.payment_status == "paid":
        raise HTTPException(409, "La venta ya está pagada: usá el reembolso")

    if o.stock_reserved:
        for it in o.items:
            v = db.get(Variant, it.variant_id, with_for_update=True) if it.variant_id else None
            if v:
                v.stock = (v.stock or 0) + it.quantity
        o.stock_reserved = False
    o.status = "cancelled"
    o.payment_status = "cancelled"
    db.add(AuditLog(user_id=admin.id, action="pos_venta_cancelada",
                    entity="order", entity_id=str(o.id)))
    db.commit()
    return {"ok": True}
