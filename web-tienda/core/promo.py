"""La promoción de la tienda — UNA sola fuente de verdad para el descuento.

🔴 Por qué existe este módulo y no un `-15%` escrito en cada plantilla:

El precio se dibuja en TRES lugares (la tarjeta del catálogo, la ficha, el
carrito) y se COBRA en un cuarto (`checkout.py`, que arma el PaymentIntent de
Stripe). Si el descuento se escribe en las plantillas, la web anuncia un 15%
y Stripe cobra el precio entero — el cliente ve una cosa y le llega otra al
resumen de la tarjeta. Eso no es un bug de diseño: es un problema de defensa
del consumidor y un contracargo asegurado.

Todo el mundo pregunta acá. `aplicar()` es la única función que sabe restar.

⚠️ Y el error simétrico, que es peor: aplicarlo DOS veces. Pasa si se descuenta
el precio unitario Y además se le resta el porcentaje al subtotal. Por eso el
contrato es explícito:

    · `aplicar(precio)`  → el precio que se cobra por unidad.
    · El descuento se resta UNA vez, al armar cada línea.
    · `Order.subtotal` guarda el total SIN descuento y `Order.discount` el
      ahorro, para que el comprobante pueda mostrar "antes / ahorro / ahora".
      `total = subtotal - discount`, y eso es lo que va a Stripe.

Hay un test que lo verifica de punta a punta: `scripts/verificar_promo.py`
compara lo que dice la ficha, lo que dice el carrito y lo que se le manda a
Stripe. Si los tres no coinciden, falla.
"""
from __future__ import annotations

from datetime import date, datetime, timezone
from decimal import ROUND_HALF_UP, Decimal

# --------------------------------------------------------------------------- #
# La promo. Esto es lo único que se toca para prenderla, apagarla o cambiarla.
# --------------------------------------------------------------------------- #
PROMO: dict = {
    "activa": True,
    # Entero, en por ciento. 15 = quince por ciento de descuento.
    "porcentaje": 15,
    "titulo": "15% OFF",
    # La bajada dice POR QUÉ hay descuento, y eso no es adorno: un "15% OFF"
    # pelado y permanente se lee como que el precio de antes estaba inflado.
    # Con el motivo —Diego está de viaje comprando— el descuento tiene una
    # causa verdadera, se entiende que es una ventana, y encima refuerza lo
    # único que esta tienda tiene y las demás no: que él viaja y compra.
    "bajada": "En toda la tienda, mientras Diego está de viaje",
    # Fecha de fin (AAAA-MM-DD) o None → la promo se apaga sola al pasar.
    #
    # 🔴 HOY VA SIN FECHA, por decisión de Juani (10-sep): "descuento en TODO,
    # hasta que Diego vuelve de viaje… indefinido". Se le advirtió el riesgo y
    # lo confirmó, así que queda así.
    # El riesgo, escrito para el que lo lea en dos meses: una promo prendida
    # demasiado tiempo deja de ser promo y pasa a ser el precio — y ahí el
    # "antes" tachado se vuelve un precio que ya nadie paga, que es
    # exactamente lo que se mira en un reclamo de Defensa del Consumidor.
    # Cuando Diego vuelva: `activa: False`, o poner acá la fecha.
    "hasta": None,
}


def _hoy() -> date:
    return datetime.now(timezone.utc).date()


def vigente() -> bool:
    """¿Hay promo corriendo ahora?"""
    if not PROMO.get("activa"):
        return False
    if int(PROMO.get("porcentaje") or 0) <= 0:
        return False
    hasta = PROMO.get("hasta")
    if hasta:
        try:
            if _hoy() > date.fromisoformat(str(hasta)):
                return False
        except ValueError:
            # Fecha mal escrita: se prefiere NO cobrar de menos por un typo.
            return False
    return True


def porcentaje() -> int:
    """El porcentaje vigente, o 0 si no hay promo."""
    return int(PROMO.get("porcentaje") or 0) if vigente() else 0


def aplicar(precio) -> Decimal | None:
    """El precio que se COBRA. Es la única función que resta.

    Redondea a 2 decimales con ROUND_HALF_UP, igual que el resto de la casa:
    truncar hacia abajo hace que la suma de las líneas no dé el total y el
    control de `payment_amount_mismatch` salte por un centavo.
    """
    if precio is None:
        return None
    p = Decimal(str(precio))
    if not vigente():
        return p
    neto = p * (Decimal(100) - Decimal(porcentaje())) / Decimal(100)
    return neto.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def ahorro(precio) -> Decimal:
    """Cuánto se ahorra en esa pieza. 0 si no hay promo."""
    if precio is None or not vigente():
        return Decimal("0")
    return Decimal(str(precio)) - (aplicar(precio) or Decimal("0"))


def datos() -> dict:
    """Lo que necesitan las plantillas. Se expone como global de Jinja."""
    return {
        "vigente": vigente(),
        "porcentaje": porcentaje(),
        "titulo": PROMO.get("titulo") or f"{porcentaje()}% OFF",
        "bajada": PROMO.get("bajada") or "",
        "hasta": PROMO.get("hasta"),
    }
