"""
Carrito persistente de la tienda.

- Carrito anónimo identificado por cookie `mi_cart` (token opaco) -> fila Cart.
- Al loguearse, el carrito anónimo se fusiona con el del usuario (ver auth/merge).
- Valida stock en el backend (nada de confiar en el front).
- Devuelve siempre un resumen JSON consistente para que el front re-renderice.
"""
from __future__ import annotations

import secrets
from decimal import Decimal

from fastapi import APIRouter, Cookie, Depends, HTTPException, Response
from sqlalchemy.orm import Session

from core.config import settings
from core.db import get_db
from core.models import Cart, CartItem, User, Variant
from core import promo
from deps import current_user

COOKIE_NAME = "mi_cart"
CART_COOKIE_MAX_AGE = 60 * 60 * 24 * 30  # 30 días (era 90: cuanto más largo,
                                         # más chance de que el precio cambie)
cart_router = APIRouter(prefix="/api/cart", tags=["cart"])


def _set_cart_cookie(response: Response | None, token: str) -> None:
    if response is None:
        return
    response.set_cookie(
        COOKIE_NAME, token, httponly=True, samesite="lax",
        secure=settings.COOKIE_SECURE, max_age=CART_COOKIE_MAX_AGE,
        domain=settings.COOKIE_DOMAIN, path="/",
    )


# --------------------------------------------------------------------------- #
# Resolución del carrito
# --------------------------------------------------------------------------- #
def get_or_create_cart(db: Session, response: Response | None,
                       token: str | None, create: bool = True) -> Cart | None:
    cart = None
    if token:
        cart = db.query(Cart).filter(Cart.token == token).one_or_none()
    if cart or not create:
        return cart
    new_token = secrets.token_urlsafe(24)
    cart = Cart(token=new_token, currency="ARS")
    db.add(cart)
    db.flush()
    _set_cart_cookie(response, new_token)
    return cart


def resolve_cart(db: Session, response: Response | None, user: User | None,
                 token: str | None, create: bool = True) -> Cart | None:
    """Única fuente de verdad de "cuál es el carrito de este visitante".

    TODOS los endpoints (ver, agregar, modificar, pagar) tienen que usar esta
    función. Antes el checkout priorizaba el carrito del usuario mientras que
    /carrito leía por cookie, así que se podía mostrar un carrito y cobrar otro.

    Si el usuario está logueado manda su carrito, y se re-sincroniza la cookie
    para que las lecturas por token siguientes caigan en el mismo lugar.
    """
    if user:
        cart = db.query(Cart).filter(Cart.user_id == user.id).order_by(Cart.id).first()
        if cart:
            if token != cart.token:
                _set_cart_cookie(response, cart.token)
            return cart
        # Sin carrito propio todavía: adoptamos el de la cookie, si hay.
        anon = get_or_create_cart(db, response, token, create=create)
        if anon and anon.user_id is None:
            anon.user_id = user.id
            db.commit()
        return anon
    return get_or_create_cart(db, response, token, create=create)


def cart_summary(cart: Cart | None) -> dict:
    """Resumen del carrito con el precio VIGENTE, no el congelado al agregar.

    `CartItem.unit_price` es el precio del momento en que se agregó. El cobro
    usa `Variant.price` actual, así que mostrar el snapshot hacía que la
    pantalla dijera un total y Stripe cobrara otro. Se muestra el precio vivo
    y se marca `price_changed` para que el front pueda avisarlo.
    """
    if not cart:
        return {"items": [], "count": 0, "subtotal": "0.00", "subtotal_raw": 0.0,
                "descuento": "0.00", "descuento_raw": 0.0, "porcentaje_promo": 0,
                "total": "0.00", "total_raw": 0.0,
                "price_changed": False}
    items = []
    subtotal = Decimal("0")
    count = 0
    any_changed = False
    for it in cart.items:
        v = it.variant
        if not v:
            continue
        price = v.price or Decimal("0")
        was = it.unit_price or Decimal("0")
        changed = was != price
        any_changed = any_changed or changed
        line = price * it.quantity
        subtotal += line
        count += it.quantity
        prod = v.product
        img = prod.images[0].url if (prod and prod.images) else "/static/images/empty-placeholder.png"
        items.append({
            "variant_id": v.id,
            "currency": (v.currency or settings.CHECKOUT_CURRENCY).lower(),
            "product_id": prod.id if prod else None,
            "handle": prod.handle if prod else None,
            "product_name": prod.name if prod else "",
            "brand": prod.brand if prod else "",
            "value": v.value,
            "sku": v.sku,
            "quantity": it.quantity,
            "stock": v.stock,
            "unit_price": f"{price:.2f}",
            "previous_price": f"{was:.2f}" if changed else None,
            "price_changed": changed,
            "line_total": f"{line:.2f}",
            "image": img,
        })
    # Moneda del carrito. Si hay mezcla, el checkout la rechaza (un cobro no
    # puede tener dos monedas); acá se informa para poder avisarlo antes.
    monedas = {i["currency"] for i in items}
    # 🔴 El descuento se calcula ACA y en checkout.py, y los dos preguntan a
    # core/promo.py. Nunca se resta un porcentaje "a mano" sobre el subtotal:
    # ese es el camino a cobrar dos veces el descuento.
    descuento = sum((promo.ahorro(i["unit_price"]) * i["quantity"] for i in items),
                    Decimal("0"))
    total = subtotal - descuento
    return {
        "items": items,
        "count": count,
        "currency": (monedas.pop() if len(monedas) == 1 else None),
        "mixed_currency": len(monedas) > 1,
        "subtotal": f"{subtotal:.2f}",
        "subtotal_raw": float(subtotal),
        "descuento": f"{descuento:.2f}",
        "descuento_raw": float(descuento),
        "porcentaje_promo": promo.porcentaje(),
        "total": f"{total:.2f}",
        "total_raw": float(total),
        "price_changed": any_changed,
    }


# --------------------------------------------------------------------------- #
# Endpoints
# --------------------------------------------------------------------------- #
def merge_anonymous_cart_into_user(db: Session, user_id: int, anon_token: str | None,
                                   response: Response | None = None) -> None:
    """Al loguearse: fusiona el carrito anónimo (cookie) con el del usuario.
    Suma cantidades (capadas al stock) y deja un único carrito por usuario."""
    user_cart = db.query(Cart).filter(Cart.user_id == user_id).order_by(Cart.id).first()
    anon_cart = (
        db.query(Cart).filter(Cart.token == anon_token).one_or_none() if anon_token else None
    )
    if anon_cart and anon_cart.user_id and anon_cart.user_id != user_id:
        anon_cart = None  # el carrito de la cookie ya es de otro usuario; no tocar

    if not user_cart:
        # El usuario no tenía carrito: adoptamos el anónimo (si hay) o creamos uno.
        if anon_cart:
            anon_cart.user_id = user_id
            db.commit()
        return

    if not anon_cart or anon_cart.id == user_cart.id:
        _set_cart_cookie(response, user_cart.token)  # la cookie debe seguir al carrito real
        return

    for it in list(anon_cart.items):
        existing = db.query(CartItem).filter_by(cart_id=user_cart.id, variant_id=it.variant_id).one_or_none()
        stock = (it.variant.stock or 0) if it.variant else 0
        cap = min(stock, 999)  # mismo tope duro que add/update
        if existing:
            existing.quantity = min(existing.quantity + it.quantity, cap)
        else:
            db.add(CartItem(cart_id=user_cart.id, variant_id=it.variant_id,
                            quantity=min(it.quantity, cap), unit_price=it.unit_price))
    db.delete(anon_cart)
    db.commit()
    # La cookie apuntaba al carrito que acabamos de borrar. Si no se
    # re-sincroniza, el próximo "agregar" crea un tercer carrito huérfano y el
    # cliente termina viendo uno y pagando otro.
    if response is not None:
        _set_cart_cookie(response, user_cart.token)


def _parse_variant_id(body: dict) -> int:
    try:
        return int(body.get("variant_id"))
    except (TypeError, ValueError):
        raise HTTPException(400, "variant_id inválido")


def _parse_quantity(body: dict, default: int = 1) -> int:
    try:
        qty = int(body.get("quantity", default))
    except (TypeError, ValueError):
        raise HTTPException(400, "Cantidad inválida")
    # Tope duro: sin esto, un pedido de 10^9 unidades desborda el monto que se
    # le manda a Stripe y genera órdenes absurdas.
    return max(-1, min(qty, 999))


@cart_router.get("")
def get_cart(db: Session = Depends(get_db), response: Response = None,
             user: User | None = Depends(current_user),
             mi_cart: str | None = Cookie(default=None)):
    cart = resolve_cart(db, response, user, mi_cart, create=False)
    return cart_summary(cart)


@cart_router.post("/add")
def add_to_cart(body: dict, response: Response, db: Session = Depends(get_db),
                user: User | None = Depends(current_user),
                mi_cart: str | None = Cookie(default=None)):
    variant_id = _parse_variant_id(body)
    qty = max(1, _parse_quantity(body))
    v = db.get(Variant, variant_id)
    if not v or not v.visible:
        raise HTTPException(404, "Variante no encontrada")
    if (v.stock or 0) <= 0:
        raise HTTPException(409, "Sin stock disponible")

    cart = resolve_cart(db, response, user, mi_cart)
    item = db.query(CartItem).filter_by(cart_id=cart.id, variant_id=v.id).one_or_none()
    current = item.quantity if item else 0
    new_qty = min(current + qty, v.stock)  # nunca por encima del stock
    if item:
        item.quantity = new_qty
        item.unit_price = v.price or Decimal("0")
    else:
        db.add(CartItem(cart_id=cart.id, variant_id=v.id, quantity=new_qty,
                        unit_price=v.price or Decimal("0")))
    db.commit()
    db.refresh(cart)
    return cart_summary(cart)


@cart_router.post("/update")
def update_cart(body: dict, response: Response = None, db: Session = Depends(get_db),
                user: User | None = Depends(current_user),
                mi_cart: str | None = Cookie(default=None)):
    cart = resolve_cart(db, response, user, mi_cart, create=False)
    if not cart:
        raise HTTPException(404, "Carrito vacío")
    variant_id = _parse_variant_id(body)
    qty = _parse_quantity(body)
    item = db.query(CartItem).filter_by(cart_id=cart.id, variant_id=variant_id).one_or_none()
    if not item:
        raise HTTPException(404, "Ítem no está en el carrito")
    if qty <= 0:
        db.delete(item)
    else:
        item.quantity = min(qty, (item.variant.stock or 0) if item.variant else 0)
    db.commit()
    db.refresh(cart)
    return cart_summary(cart)


@cart_router.post("/remove")
def remove_from_cart(body: dict, response: Response = None, db: Session = Depends(get_db),
                     user: User | None = Depends(current_user),
                     mi_cart: str | None = Cookie(default=None)):
    cart = resolve_cart(db, response, user, mi_cart, create=False)
    if not cart:
        return cart_summary(None)
    variant_id = _parse_variant_id(body)
    item = db.query(CartItem).filter_by(cart_id=cart.id, variant_id=variant_id).one_or_none()
    if item:
        db.delete(item)
        db.commit()
        db.refresh(cart)
    return cart_summary(cart)
