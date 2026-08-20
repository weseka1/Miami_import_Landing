"""
Checkout con Stripe (Payment Intents) — única pasarela.

Flujo:
  1. POST /api/checkout/create-intent: valida carrito + stock, RESERVA el stock,
     crea Order (pending) + OrderItems (snapshot de precios), crea el
     PaymentIntent y devuelve client_secret.
  2. El front monta el Payment Element con client_secret y confirma el pago.
  3. POST /api/stripe/webhook: Stripe confirma. Al cobrar
     (payment_intent.succeeded) verificamos monto y moneda contra lo que
     esperábamos, marcamos la orden pagada y vaciamos el carrito. Si el pago
     falla o se cancela, devolvemos el stock reservado.

Decisiones de seguridad (no cambiar sin entender el porqué):
  - El monto SIEMPRE se recalcula server-side desde Variant.price. Nada del
    request influye en lo que se cobra.
  - El stock se reserva al crear el intent, con SELECT ... FOR UPDATE. Validar
    sin reservar permite vender la misma unidad dos veces.
  - La firma del webhook es OBLIGATORIA siempre. No hay modo "sin firma": era
    un camino a marcar pedidos como pagados sin pagar.
  - La autoridad para resolver la orden es la fila Payment (la escribimos
    nosotros), NO el metadata del evento (viaja en el objeto de Stripe).
  - Idempotencia real por event.id en la tabla webhook_events.

Las claves viven SOLO en backend (settings). Si no están configuradas, los
endpoints responden 503 sin romper la tienda.
"""
from __future__ import annotations

import logging
import secrets
from datetime import datetime, timedelta, timezone
from decimal import Decimal

import stripe
from email_validator import EmailNotValidError, validate_email
from fastapi import APIRouter, Cookie, Depends, HTTPException, Request
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from auth_store import current_user
from cart import get_or_create_cart, resolve_cart
from core import mailer
from core.config import settings
from core.db import get_db
from core.models import (
    AuditLog, Cart, CartItem, Order, OrderItem, Payment, User, Variant, WebhookEvent,
)

log = logging.getLogger("checkout")


def _sd(obj) -> dict:
    """Objeto de Stripe -> dict plano.

    A partir de stripe-python 8 los recursos (PaymentIntent, Event...) dejaron
    de soportar `.get()` y tiran AttributeError. Ese error rompía el webhook y
    la reconciliación: un pago cobrado de verdad NUNCA se acreditaba y el
    pedido quedaba "sin pagar" para siempre. Todo lo que vuelve de Stripe pasa
    por acá antes de leerse.
    """
    if obj is None:
        return {}
    if isinstance(obj, dict):
        return obj
    for metodo in ("to_dict_recursive", "to_dict"):
        fn = getattr(obj, metodo, None)
        if callable(fn):
            try:
                return fn()
            except Exception:  # noqa: BLE001
                pass
    try:
        return dict(obj)
    except Exception:  # noqa: BLE001
        return {}

checkout_router = APIRouter(tags=["checkout"])

# Campos de envío aceptados y su largo máximo. Todo lo que no esté acá se
# descarta: el shipping_address va a JSON y de ahí al panel, así que un campo
# libre sin límite es superficie de XSS y de basura en la base.
_SHIPPING_FIELDS = {
    "full_name": 120, "phone": 40, "street": 160, "number": 20, "floor": 40,
    "city": 80, "province": 80, "zipcode": 20, "country": 60,
}


def _sellar_cobro(payment, intent: dict) -> None:
    """Deja en la fila del pago el rastro VERIFICABLE del cobro.

    `status='paid'` es una palabra nuestra. Lo que prueba que la plata entro es
    lo que devuelve Stripe: el id del cobro, el recibo que Stripe hospeda (link
    publico que el cliente y el banco pueden abrir) y con que tarjeta se pago.
    Sin esto, ante un "¿me cobraste?" no hay con que contestar.

    Nunca levanta: si Stripe no contesta, el pago se acredita igual. Quedarse
    sin el rastro es molesto; no acreditar una venta ya cobrada es grave.
    """
    try:
        cargo = None
        cargo_id = intent.get("latest_charge")
        if isinstance(cargo_id, dict):          # vino expandido
            cargo = _sd(cargo_id)
            cargo_id = cargo.get("id")
        if not cargo_id:                        # API vieja: charges.data[0]
            datos = (_sd(intent.get("charges")).get("data") or [])
            if datos:
                cargo = _sd(datos[0])
                cargo_id = cargo.get("id")
        if cargo_id and cargo is None:
            cargo = _sd(stripe.Charge.retrieve(cargo_id))

        payment.stripe_charge_id = cargo_id
        if cargo:
            payment.receipt_url = cargo.get("receipt_url")
            detalles = _sd(cargo.get("payment_method_details"))
            payment.metodo = ((detalles.get("type") or "")[:40]) or None
            tarjeta = _sd(detalles.get("card"))
            payment.card_brand = ((tarjeta.get("brand") or "")[:30]) or None
            payment.card_last4 = ((tarjeta.get("last4") or "")[:4]) or None
            creado = cargo.get("created")
            if creado:
                payment.paid_at = datetime.fromtimestamp(int(creado), tz=timezone.utc)
    except Exception:  # noqa: BLE001
        log.exception("No se pudo sellar el rastro del cobro (intent %s)",
                      intent.get("id") if isinstance(intent, dict) else "?")
    if not payment.paid_at:
        payment.paid_at = datetime.now(timezone.utc)


def _stripe_ready() -> bool:
    if not settings.STRIPE_SECRET_KEY:
        return False
    stripe.api_key = settings.STRIPE_SECRET_KEY
    return True


def _clean_shipping(body: dict) -> dict:
    """Recorta y limita los campos de envío; descarta cualquier clave extra."""
    out: dict[str, str] = {}
    for field, maxlen in _SHIPPING_FIELDS.items():
        raw = body.get(field)
        if raw is None:
            continue
        value = str(raw).strip()[:maxlen]
        if value:
            out[field] = value
    return out


def _next_order_number(db: Session) -> int:
    last = db.query(Order).order_by(Order.number.desc()).first()
    return (last.number + 1) if last and last.number else 1000


def _release_stock(db: Session, order: Order) -> None:
    """Devuelve al stock lo reservado por una orden. Idempotente vía el flag."""
    if not order.stock_reserved:
        return
    for it in order.items:
        if not it.variant_id:
            continue
        v = db.get(Variant, it.variant_id, with_for_update=True)
        if v:
            v.stock = (v.stock or 0) + it.quantity
    order.stock_reserved = False


def _try_reserve(db: Session, order: Order) -> list[str]:
    """Intenta (re)tomar el stock de una orden. Devuelve lo que NO alcanzó.

    Se usa cuando llega un pago acreditado sobre una orden cuya reserva ya se
    había soltado. Si falta aunque sea una unidad, no se descuenta NADA y se
    devuelve la lista de faltantes para que el operador lo resuelva a mano.
    """
    faltantes: list[str] = []
    tomados: list[tuple[Variant, int]] = []
    for it in sorted(order.items, key=lambda x: x.variant_id or 0):
        if not it.variant_id:
            continue
        v = db.get(Variant, it.variant_id, with_for_update=True)
        if not v or it.quantity > (v.stock or 0):
            faltantes.append(it.product_name or f"variante {it.variant_id}")
            continue
        tomados.append((v, it.quantity))

    if faltantes:
        return faltantes           # todo o nada: no se descuenta parcial
    for v, qty in tomados:
        v.stock = (v.stock or 0) - qty
    order.stock_reserved = True
    return []


# Minutos tras los cuales una orden pending con stock reservado se considera
# abandonada. Stripe NO cancela solo los PaymentIntents, así que sin este
# barrido la reserva quedaría para siempre y agotaría el inventario.
_RESERVATION_TTL_MIN = 30


def _reap_abandoned_reservations(db: Session) -> None:
    """Libera el stock de órdenes pending abandonadas (checkout no confirmado).

    Corre de forma oportunista al inicio de cada create-intent. Barato: filtra
    por índice sobre created_at + estado. Cancela el PaymentIntent en Stripe
    (idempotente) para que no pueda cobrarse después de liberada la reserva.
    """
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=_RESERVATION_TTL_MIN)
    stale = (db.query(Order)
             .filter(Order.stock_reserved.is_(True),
                     Order.payment_status == "pending",
                     Order.created_at < cutoff)
             .limit(50)
             .all())
    for order in stale:
        try:
            pay = order.payments[0] if order.payments else None
            if pay and pay.stripe_payment_intent_id:
                # cancel() dispara payment_intent.canceled; si ya no es
                # cancelable (p.ej. ya se cobró) Stripe lanza y NO liberamos.
                stripe.PaymentIntent.cancel(pay.stripe_payment_intent_id)
                pay.status = "cancelled"
            _release_stock(db, order)
            order.status = "cancelled"
            order.payment_status = "cancelled"
            db.commit()
        except stripe.StripeError:
            # El intent no era cancelable (posible cobro en curso): dejar la
            # orden como está; el webhook resolverá el estado real.
            db.rollback()
        except Exception:  # noqa: BLE001
            db.rollback()
            log.exception("Fallo liberando reserva de la orden %s", order.id)


@checkout_router.post("/api/checkout/create-intent")
def create_intent(body: dict, request: Request, db: Session = Depends(get_db),
                  user: User | None = Depends(current_user),
                  mi_cart: str | None = Cookie(default=None)):
    if not _stripe_ready():
        raise HTTPException(503, "Stripe no está configurado todavía")

    # Liberar reservas de checkouts abandonados antes de tomar stock nuevo.
    _reap_abandoned_reservations(db)
    return _create_intent_once(body, request, db, user, mi_cart)


def _create_intent_once(body: dict, request: Request, db: Session,
                        user: User | None, mi_cart: str | None):

    # Misma resolución que usa el resto de la tienda: si el usuario logueado ve
    # un carrito, es el que se le cobra. Antes /carrito leía por cookie y el
    # checkout priorizaba el del usuario, así que se cobraba otro carrito.
    cart = resolve_cart(db, None, user, mi_cart, create=False)
    if not cart or not cart.items:
        raise HTTPException(400, "El carrito está vacío")

    # --- Reusar la orden pendiente de este mismo carrito ---------------------
    # Sin esto, cada click en "Continuar al pago" creaba una orden NUEVA y
    # reservaba stock de nuevo: el cliente se autobloqueaba ("sin stock" sobre
    # su propia reserva), podía terminar pagando dos veces, y cualquiera podía
    # agotar el catálogo entero repitiendo la llamada.
    vigente = (db.query(Order)
               .filter(Order.cart_id == cart.id,
                       Order.payment_status == "pending",
                       Order.stock_reserved.is_(True),
                       Order.created_at >= datetime.now(timezone.utc)
                       - timedelta(minutes=_RESERVATION_TTL_MIN))
               .order_by(Order.id.desc())
               .first())
    if vigente:
        pay = vigente.payments[0] if vigente.payments else None
        if pay and pay.stripe_payment_intent_id:
            try:
                intent = stripe.PaymentIntent.retrieve(pay.stripe_payment_intent_id)
                if _sd(intent).get("status") in ("requires_payment_method",
                                            "requires_confirmation",
                                            "requires_action"):
                    return {
                        "client_secret": intent.client_secret,
                        "publishable_key": settings.STRIPE_PUBLISHABLE_KEY,
                        "order_number": vigente.number,
                        "order_token": vigente.public_token,
                        "amount": f"{vigente.total:.2f}",
                        "reused": True,
                    }
            except stripe.StripeError:
                pass  # no se pudo recuperar: seguimos y creamos uno nuevo

    raw_email = (body.get("email") or (user.email if user else "") or "").strip()
    if user:
        # Para usuarios logueados manda la sesión, no el body: si no, uno puede
        # asociar el mail de otro a su orden y desviar el recibo de Stripe.
        raw_email = user.email
    try:
        email = validate_email(raw_email, check_deliverability=False).normalized.lower()
    except EmailNotValidError:
        raise HTTPException(400, "Email inválido")

    shipping = _clean_shipping(body)

    # --- Validar y RESERVAR stock con lock de fila ---------------------------
    # with_for_update serializa a los compradores concurrentes de la misma
    # variante. En SQLite local es no-op (no hay lock de fila); el deploy real
    # es Postgres, donde sí aplica.
    subtotal = Decimal("0")
    snapshot = []
    monedas: set[str] = set()
    for it in sorted(cart.items, key=lambda x: x.variant_id or 0):  # orden fijo: evita deadlocks
        v = db.get(Variant, it.variant_id, with_for_update=True) if it.variant_id else None
        if not v or it.quantity > (v.stock or 0):
            db.rollback()
            name = v.product.name if v and v.product else "un producto"
            raise HTTPException(409, f"Sin stock suficiente de {name}")
        name = v.product.name if v.product else "un producto"
        # El carrito puede tener semanas (la cookie dura 30 días): revalidar que
        # el producto siga a la venta, no solo que tenga stock.
        if not v.visible or not v.product or not v.product.published:
            db.rollback()
            raise HTTPException(409, f"{name} ya no está disponible")
        price = v.price
        # Un precio nulo o 0 en un carrito mixto regalaba ese ítem: el total
        # seguía siendo > 0 por los demás, así que pasaba el control de abajo.
        if price is None or price <= 0 or not price.is_finite():
            db.rollback()
            log.error("Variante %s con precio inválido (%s): no se puede vender", v.id, price)
            raise HTTPException(409, f"{name} no tiene precio válido")
        monedas.add((v.currency or settings.CHECKOUT_CURRENCY).strip().lower())
        line = price * it.quantity
        subtotal += line
        snapshot.append((v, it.quantity, price, line))

    # Un PaymentIntent cobra en UNA sola moneda. Si el carrito mezcla, no se
    # puede cobrar de una: mejor avisarlo que cobrar cualquier cosa.
    if len(monedas) > 1:
        db.rollback()
        raise HTTPException(
            409, "No se pueden comprar juntos productos en distintas monedas. "
                 "Dejá uno solo en el carrito y hacé la compra por separado.")

    total = subtotal  # MVP: sin costo de envío (se suma al confirmar logística)
    if total <= 0:
        db.rollback()
        raise HTTPException(400, "El total del pedido es inválido")

    currency = monedas.pop() if monedas else settings.CHECKOUT_CURRENCY
    minor = settings.minor_units(currency)

    # --- Crear la orden y descontar la reserva -------------------------------
    order = Order(
        number=_next_order_number(db), user_id=user.id if user else None,
        cart_id=cart.id, email=email,
        contact_name=shipping.get("full_name"), contact_phone=shipping.get("phone"),
        status="pending", payment_status="pending", currency=currency.upper()[:3],
        subtotal=subtotal, shipping_cost=Decimal("0"), discount=Decimal("0"), total=total,
        shipping_address=shipping, stock_reserved=True,
    )
    # Se usa la relación (no order_id=...) porque el id todavía no existe: lo
    # asigna SQLAlchemy al hacer flush.
    for v, qty, price, line in snapshot:
        v.stock = (v.stock or 0) - qty  # reserva efectiva
        order.items.append(OrderItem(
            variant_id=v.id, product_id=v.product_id,
            product_name=v.product.name if v.product else "",
            variant_value=v.value, sku=v.sku, unit_price=price,
            quantity=qty, subtotal=line))
    db.add(order)

    # Order.number es único y sale de max+1: dos create-intent concurrentes
    # pueden sacar el mismo. El retry se acota SOLO a este commit —no envuelve
    # la llamada a Stripe— para no crear un segundo PaymentIntent ni reservar
    # stock dos veces si un IntegrityError apareciera más adelante.
    for attempt in range(5):
        try:
            db.commit()
            break
        except IntegrityError:
            db.rollback()
            if attempt == 4:
                log.error("No se pudo asignar número de orden tras 5 intentos")
                raise HTTPException(503, "No pudimos generar el pedido. Probá de nuevo.")
            # Rehacer la reserva (el rollback la deshizo) con un número nuevo.
            for it in cart.items:
                v = db.get(Variant, it.variant_id, with_for_update=True) if it.variant_id else None
                if not v or it.quantity > (v.stock or 0):
                    raise HTTPException(409, "Sin stock suficiente")
                v.stock = (v.stock or 0) - it.quantity
            order.number = _next_order_number(db)
            db.add(order)
    db.refresh(order)

    # --- Recién ahora hablamos con Stripe ------------------------------------
    # Si esto falla, compensamos: devolvemos el stock y cancelamos la orden.
    try:
        intent = stripe.PaymentIntent.create(
            amount=int((total * minor).to_integral_value()),
            currency=currency,
            receipt_email=email,
            metadata={"order_id": order.id, "order_number": order.number},
            automatic_payment_methods={"enabled": True},
            idempotency_key=f"order-{order.id}-{order.public_token[:16]}",
        )
    except stripe.StripeError as exc:
        log.exception("Stripe rechazó la creación del PaymentIntent (orden %s)", order.id)
        _release_stock(db, order)
        order.status = "cancelled"
        order.payment_status = "failed"
        db.commit()
        raise HTTPException(502, "No pudimos iniciar el pago. Probá de nuevo en un momento.") from exc

    db.add(Payment(order_id=order.id, provider="stripe",
                   stripe_payment_intent_id=intent.id, amount=total,
                   currency=currency.upper()[:3], status="pending"))
    db.add(AuditLog(user_id=user.id if user else None, action="checkout_intent",
                    entity="order", entity_id=str(order.id),
                    ip=request.client.host if request.client else None))
    db.commit()

    # Aviso a la tienda YA, con el pago todavía pendiente: el pedido de Celeste
    # (#1016) estuvo un día entero invisible porque nadie se enteraba de los
    # checkouts sin pagar — y ese es justo el momento de escribirle al cliente.
    mailer.avisar_pedido_nuevo(order)

    return {
        "client_secret": intent.client_secret,
        "publishable_key": settings.STRIPE_PUBLISHABLE_KEY,
        "order_number": order.number,
        "order_token": order.public_token,
        "amount": f"{total:.2f}",
    }


@checkout_router.post("/api/checkout/pagar-pedido")
def pagar_pedido(body: dict, db: Session = Depends(get_db)):
    """Genera el pago de una orden YA creada (ventas de mostrador vía QR).

    A diferencia de create-intent, acá no hay carrito: la orden ya existe con
    su detalle y su stock reservado. El acceso se autoriza con el token opaco
    de la orden, igual que la página de confirmación.

    El monto se toma de la ORDEN, nunca del request.
    """
    if not _stripe_ready():
        raise HTTPException(503, "Stripe no está configurado todavía")

    try:
        numero = int(body.get("numero"))
    except (TypeError, ValueError):
        raise HTTPException(400, "Pedido inválido")
    token = str(body.get("token") or "")

    order = db.query(Order).filter(Order.number == numero).one_or_none()
    if not order or not order.public_token or not token:
        raise HTTPException(404, "Pedido no encontrado")
    if not secrets.compare_digest(token, order.public_token):
        raise HTTPException(404, "Pedido no encontrado")
    if order.payment_status == "paid":
        return {"ya_pagado": True, "order_number": order.number}
    if order.status == "cancelled":
        raise HTTPException(409, "Este pedido fue cancelado")
    if not order.total or order.total <= 0:
        raise HTTPException(400, "El total del pedido es inválido")

    moneda = (order.currency or settings.CHECKOUT_CURRENCY).lower()
    minor = settings.minor_units(moneda)

    # Si ya hay un intent vivo para esta orden, se reusa: crear uno nuevo en
    # cada escaneo del QR dejaría pagos huérfanos en Stripe.
    pago = (db.query(Payment)
            .filter(Payment.order_id == order.id,
                    Payment.stripe_payment_intent_id.isnot(None))
            .order_by(Payment.id.desc()).first())
    if pago:
        try:
            intent = stripe.PaymentIntent.retrieve(pago.stripe_payment_intent_id)
            estado = _sd(intent).get("status")
            # Ya cobrado: NO generar otro intent (sería un segundo cobro por la
            # misma compra). Se acredita la orden y se avisa que está pagada.
            if estado in ("succeeded", "processing"):
                confirmar_pago_desde_stripe(db, order, pago.stripe_payment_intent_id)
                return {"ya_pagado": True, "order_number": order.number}
            if estado in ("requires_payment_method", "requires_confirmation",
                          "requires_action"):
                return {
                    "client_secret": intent.client_secret,
                    "publishable_key": settings.STRIPE_PUBLISHABLE_KEY,
                    "order_number": order.number,
                    "amount": f"{order.total:.2f}",
                }
        except stripe.StripeError:
            pass

    try:
        intent = stripe.PaymentIntent.create(
            amount=int((order.total * minor).to_integral_value()),
            currency=moneda,
            receipt_email=order.email or None,
            metadata={"order_id": order.id, "order_number": order.number,
                      "canal": "local"},
            automatic_payment_methods={"enabled": True},
            idempotency_key=f"orden-{order.id}-{order.public_token[:16]}",
        )
    except stripe.StripeError as exc:
        log.exception("Stripe rechazó el pago de la orden %s", order.id)
        raise HTTPException(502, "No pudimos iniciar el pago. Probá de nuevo.") from exc

    db.add(Payment(order_id=order.id, provider="stripe",
                   stripe_payment_intent_id=intent.id, amount=order.total,
                   currency=(order.currency or moneda.upper())[:3], status="pending"))
    db.commit()
    return {
        "client_secret": intent.client_secret,
        "publishable_key": settings.STRIPE_PUBLISHABLE_KEY,
        "order_number": order.number,
        "amount": f"{order.total:.2f}",
    }


def confirmar_pago_desde_stripe(db: Session, order: Order, pi_id: str) -> bool:
    """Acredita una orden consultando el PaymentIntent DIRECTO a Stripe.

    Es la red de seguridad del webhook: si el aviso de Stripe no llega (webhook
    mal configurado, caído o demorado), el pedido quedaría en `pending` con la
    plata cobrada. Cuando el cliente vuelve del pago, Stripe agrega
    ?payment_intent=... a la URL de retorno, y con eso preguntamos el estado
    real a la API.

    NO se confía en los parámetros de la URL (el cliente los controla): sirven
    solo como pista para ir a preguntarle a Stripe. Se verifica que el intent
    sea el de ESTA orden, que esté efectivamente pagado, y que el monto y la
    moneda coincidan con lo que esperábamos.

    Devuelve True si dejó la orden pagada.
    """
    if not order or order.payment_status == "paid" or not pi_id:
        return False
    if not _stripe_ready():
        return False

    payment = (db.query(Payment)
               .filter(Payment.order_id == order.id,
                       Payment.stripe_payment_intent_id == pi_id)
               .order_by(Payment.id.desc())
               .first())
    if not payment:
        log.warning("Intent %s no pertenece a la orden %s", pi_id, order.id)
        return False

    try:
        intent = stripe.PaymentIntent.retrieve(pi_id)
    except stripe.StripeError:
        log.exception("No se pudo consultar el PaymentIntent %s", pi_id)
        return False

    intent = _sd(intent)
    if intent.get("status") != "succeeded":
        return False

    minor = settings.minor_units(payment.currency)
    pagado = Decimal(intent.get("amount_received") or intent.get("amount") or 0) / minor
    moneda = (intent.get("currency") or "").upper()[:3]
    if pagado != payment.amount or moneda != (payment.currency or "").upper()[:3]:
        log.error("Monto/moneda no coinciden al confirmar la orden %s: %s %s vs %s %s",
                  order.id, pagado, moneda, payment.amount, payment.currency)
        payment.status = "review"
        db.add(AuditLog(user_id=order.user_id, action="payment_amount_mismatch",
                        entity="order", entity_id=str(order.id)))
        db.commit()
        return False

    # Si la reserva se soltó (pago demorado, barrido), re-tomar antes de dar la
    # orden por despachable.
    if not order.stock_reserved:
        faltantes = _try_reserve(db, order)
        if faltantes:
            order.payment_status = "paid"
            order.status = "backorder"
            payment.status = "paid"
            payment.error_message = "Pago acreditado sin stock: " + ", ".join(faltantes)
            _sellar_cobro(payment, intent)
            db.add(AuditLog(user_id=order.user_id, action="paid_without_stock",
                            entity="order", entity_id=str(order.id)))
            db.commit()
            return True

    order.payment_status = "paid"
    order.status = "processing"
    payment.status = "paid"
    payment.raw = {"confirmado_por": "retorno_del_cliente", "intent": pi_id}
    _sellar_cobro(payment, intent)
    if order.cart_id:
        db.query(CartItem).filter(CartItem.cart_id == order.cart_id).delete(
            synchronize_session=False)
    db.add(AuditLog(user_id=order.user_id, action="payment_succeeded_por_retorno",
                    entity="order", entity_id=str(order.id)))
    db.commit()
    mailer.confirmar_al_cliente(order)
    mailer.avisar_pago_acreditado(order)
    log.info("Orden %s acreditada por consulta directa a Stripe", order.id)
    return True


@checkout_router.post("/api/stripe/webhook")
async def stripe_webhook(request: Request, db: Session = Depends(get_db)):
    if not _stripe_ready():
        raise HTTPException(503, "Stripe no está configurado")
    if not settings.STRIPE_WEBHOOK_SECRET:
        # Sin secret no hay forma de distinguir a Stripe de un atacante. No se
        # procesa nada, ni siquiera en desarrollo: para pruebas locales, el
        # Stripe CLI entrega su propio whsec_.
        log.error("Webhook recibido pero STRIPE_WEBHOOK_SECRET no está configurado")
        raise HTTPException(503, "Webhook no configurado")

    payload = await request.body()
    sig = request.headers.get("stripe-signature", "")
    try:
        event = stripe.Webhook.construct_event(payload, sig, settings.STRIPE_WEBHOOK_SECRET)
    except Exception as exc:  # noqa: BLE001  (firma inválida / payload manipulado)
        log.warning("Firma de webhook inválida: %s", exc)
        raise HTTPException(400, "Firma inválida")  # sin filtrar el detalle

    event = _sd(event)
    event_id = event.get("id") or ""
    etype = event.get("type") or ""
    obj = (event.get("data") or {}).get("object") or {}
    pi_id = obj.get("id")

    # --- Idempotencia ATÓMICA -------------------------------------------------
    # El WebhookEvent NO se commitea por separado: se agrega a la sesión y viaja
    # en el MISMO commit que el efecto (marcar pagado, liberar stock, etc.). Si
    # el procesamiento falla, el event_id no queda persistido y Stripe reintenta
    # de verdad. Si el mismo evento llega dos veces en paralelo, la PK única
    # hace que uno de los dos commits explote con IntegrityError → rollback de
    # TODO su trabajo, sin doble efecto. Marcar procesado antes de aplicar
    # perdía el pago si el paso siguiente fallaba.
    if event_id and db.get(WebhookEvent, event_id) is not None:
        return {"received": True, "duplicate": True}
    if event_id:
        db.add(WebhookEvent(event_id=event_id, event_type=etype))

    def _commit() -> bool:
        """Cierra la transacción. False si el evento resultó duplicado (otra
        entrega concurrente ganó la carrera de la PK)."""
        try:
            db.commit()
            return True
        except IntegrityError:
            db.rollback()
            return False

    # --- La fila Payment es la autoridad, no el metadata del evento ----------
    payment = (db.query(Payment)
               .filter(Payment.stripe_payment_intent_id == pi_id)
               .one_or_none()) if pi_id else None
    order = payment.order if payment else None

    if not payment:
        # No hay fila Payment: casi siempre es un PaymentIntent que no es
        # nuestro. PERO existe una ventana mínima —el proceso muere entre crear
        # el intent y guardar el Payment— en la que el cliente sí pudo pagar una
        # orden nuestra. Recuperamos por metadata.order_id, y creamos la fila
        # que faltaba, SIEMPRE verificando monto/moneda después (más abajo), así
        # que aunque el metadata fuera manipulable no se despacha de más.
        meta_oid = (obj.get("metadata") or {}).get("order_id")
        if meta_oid:
            try:
                order = db.get(Order, int(meta_oid))
            except (TypeError, ValueError):
                order = None
        if order and pi_id:
            payment = Payment(order_id=order.id, provider="stripe",
                              stripe_payment_intent_id=pi_id,
                              amount=order.total, currency=order.currency,
                              status="pending")
            db.add(payment)
        if not payment:
            log.info("Webhook %s para PaymentIntent desconocido %s", etype, pi_id)
            _commit()  # persistir el WebhookEvent: no hay nada que reintentar
            return {"received": True, "ignored": "payment_intent desconocido"}

    if not order:
        _commit()
        return {"received": True, "ignored": "orden inexistente"}

    if etype == "payment_intent.succeeded":
        # Verificar que lo cobrado sea lo que esperábamos, en la moneda correcta.
        minor = settings.minor_units(payment.currency)
        paid = Decimal(obj.get("amount_received") or obj.get("amount") or 0) / minor
        paid_cur = (obj.get("currency") or "").upper()[:3]
        if paid != payment.amount or paid_cur != (payment.currency or "").upper()[:3]:
            log.error("Monto/moneda no coinciden en orden %s: cobrado %s %s, esperado %s %s",
                      order.id, paid, paid_cur, payment.amount, payment.currency)
            db.add(AuditLog(user_id=order.user_id, action="payment_amount_mismatch",
                            entity="order", entity_id=str(order.id)))
            payment.status = "review"
            payment.error_message = (f"Cobrado {paid} {paid_cur}, "
                                     f"esperado {payment.amount} {payment.currency}")
            if not _commit():
                return {"received": True, "duplicate": True}
            return {"received": True, "review": True}  # NO despachar

        if order.payment_status != "paid":
            # Normalmente el stock ya está reservado desde el create-intent. Pero
            # si la reserva se soltó (pago rechazado y reintentado con otra
            # tarjeta, o expiración por el barrido), hay que RE-TOMARLA antes de
            # dar la orden por despachable: si no, se cobra mercadería que ya se
            # le vendió a otro.
            if not order.stock_reserved:
                faltantes = _try_reserve(db, order)
                if faltantes:
                    log.error("Orden %s pagada SIN stock disponible: %s",
                              order.id, ", ".join(faltantes))
                    order.payment_status = "paid"
                    order.status = "backorder"     # cobrado, NO despachar
                    payment.status = "paid"
                    payment.error_message = ("Pago acreditado sin stock: "
                                             + ", ".join(faltantes))
                    _sellar_cobro(payment, obj)
                    db.add(AuditLog(user_id=order.user_id, action="paid_without_stock",
                                    entity="order", entity_id=str(order.id)))
                    if not _commit():
                        return {"received": True, "duplicate": True}
                    return {"received": True, "backorder": True}

            order.payment_status = "paid"
            order.status = "processing"
            payment.status = "paid"
            payment.raw = {"event": etype, "event_id": event_id}
            _sellar_cobro(payment, obj)
            # Vaciar exactamente el carrito que originó la orden (también el de
            # invitados, que antes quedaba lleno y llevaba a pagar dos veces).
            if order.cart_id:
                db.query(CartItem).filter(CartItem.cart_id == order.cart_id).delete(
                    synchronize_session=False)
            db.add(AuditLog(user_id=order.user_id, action="payment_succeeded",
                            entity="order", entity_id=str(order.id)))
            if not _commit():
                return {"received": True, "duplicate": True}
            # Solo después del commit exitoso (si fue duplicado, el otro camino
            # ya mandó los mails): confirmación al cliente + aviso a la tienda.
            mailer.confirmar_al_cliente(order)
            mailer.avisar_pago_acreditado(order)
        else:
            _commit()  # ya estaba pagada; solo persistir el WebhookEvent

    elif etype in ("payment_intent.payment_failed", "payment_intent.canceled"):
        # Nunca degradar un pago ya acreditado: Stripe no garantiza el orden de
        # entrega y reintenta hasta 3 días. Un `failed` viejo llegando después
        # de un `succeeded` dejaba la orden como fallida con la plata cobrada.
        if order.payment_status == "paid":
            log.info("Ignorando %s sobre orden %s ya pagada", etype, order.id)
            _commit()
            return {"received": True, "ignored": "orden ya pagada"}
        payment.status = "failed"
        payment.error_message = (obj.get("last_payment_error") or {}).get("message")
        order.payment_status = "failed"
        # OJO: en Stripe un `payment_failed` NO es terminal — el mismo
        # PaymentIntent vuelve a `requires_payment_method` y el cliente reintenta
        # con otra tarjeta. Por eso acá NO se libera el stock: si se liberaba, el
        # reintento exitoso cobraba mercadería ya vendida a otro. La reserva se
        # suelta solo en `canceled` o cuando la vence el barrido.
        if etype == "payment_intent.canceled":
            order.status = "cancelled"
            _release_stock(db, order)
        db.add(AuditLog(user_id=order.user_id, action="payment_failed",
                        entity="order", entity_id=str(order.id)))
        if not _commit():
            return {"received": True, "duplicate": True}

    else:
        _commit()  # evento de otro tipo: persistir el WebhookEvent y listo

    return {"received": True}
