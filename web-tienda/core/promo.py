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

Hay un verificador que lo comprueba de punta a punta:

    python scripts/verificar_promo.py --url https://miamiimport.com.ar

Recorre una compra de verdad —ficha → carrito → checkout— y exige que las
cuatro pantallas digan el mismo número. Sale con código 1 si no cierra.

🔴 Corrélo DESPUÉS de tocar cualquier cosa que dibuje o cobre un precio, y
contra PRODUCCIÓN, no contra local. Este docstring prometía ese archivo desde
el 10-sep y el archivo no existía: en esos días `/checkout` estuvo rotulando
"Total" al subtotal SIN descuento y disparando el aviso "el precio se
actualizó, revisá antes de pagar" en el 100% de las compras. Se cobraba bien
—el PaymentIntent siempre salió de `order.total`— pero la última pantalla
antes de pagar decía otro número. Nadie lo vio porque un JS lo pisaba dos
líneas después. Una promesa de test sin test es peor que no tener test.
"""
from __future__ import annotations

from datetime import date, datetime, timezone
from decimal import ROUND_HALF_UP, Decimal

# --------------------------------------------------------------------------- #
# La promo. Esto es lo único que se toca para prenderla, apagarla o cambiarla.
# --------------------------------------------------------------------------- #
PROMO: dict = {
    "activa": True,
    # Entero, en por ciento. 20 = veinte por ciento de descuento.
    # 🔴 Subido de 15 a 20 el 10-sep por decisión de Diego. Este número es el
    # ÚNICO lugar donde vive el porcentaje: la cinta, el cartel, la barra, las
    # 229 tarjetas, el carrito, el checkout y el mail lo leen de acá. No lo
    # escribas en una plantilla ni para "probar".
    "porcentaje": 20,
    "titulo": "20% OFF",
    # La bajada dice POR QUÉ hay descuento, y eso no es adorno: un "20% OFF"
    # pelado y permanente se lee como que el precio de antes estaba inflado.
    # Con el motivo, el descuento tiene una causa verdadera, se entiende que es
    # una ventana, y encima refuerza lo único que esta tienda tiene y las demás
    # no: que Diego viaja y compra pieza por pieza.
    #
    # 🔴 Cambió el sentido el 10-sep, y el detalle importa: antes decía
    # "mientras Diego está de viaje" —la promo corría PORQUE estaba afuera—.
    # Diego pidió textual que sea "hasta que hagamos el próximo viaje": ahora
    # corre hasta que SALGAN. Son opuestos. Si alguien restaura el texto viejo
    # sin mirar, la web va a decir que Diego está en Milán cuando está acá.
    "bajada": "En toda la tienda, hasta nuestro próximo viaje a Milán",
    # Fecha de fin (AAAA-MM-DD) o None → la promo se apaga sola al pasar.
    #
    # 🔴 VA SIN FECHA, por decisión de Juani (10-sep) y ahora de Diego (11-sep,
    # al subir a 20): el final es "hasta que hagamos el próximo viaje", que es
    # un evento del negocio y no una fecha de calendario. Se advirtió el riesgo
    # y se confirmó, así que queda así.
    #
    # El riesgo, escrito para el que lo lea en dos meses: una promo prendida
    # demasiado tiempo deja de ser promo y pasa a ser el precio — y ahí el
    # "antes" tachado se vuelve un precio que ya nadie paga, que es
    # exactamente lo que se mira en un reclamo de Defensa del Consumidor. Con
    # el 20% el "antes" es un 25% más caro que el precio real, así que la
    # exposición subió, no bajó.
    #
    # Cómo se apaga cuando salgan de viaje: `activa: False` acá, o poner la
    # fecha del vuelo en este mismo campo y se apaga sola. Es UNA línea, y es
    # lo único que hay que acordarse de hacer.
    "hasta": None,

    # --- La foto del cartel ------------------------------------------------ #
    # Una POV real de adentro de una tienda de Milán. Es la prueba de lo que
    # dice el texto de al lado, y el activo que ninguna competencia tiene.
    "foto": "/static/images/promo-vitrina.webp",
    "foto_pie": "Milán · adentro de la tienda",
    # 🔴 La foto LINKEA al producto que se ve en ella, por pedido de Juani
    # (11-sep): "que se pueda entrar al producto mostrado". Si Diego cambia la
    # foto, hay que cambiar este handle también — si no, el cliente hace clic
    # en una zapatilla y le abre otra cosa, que es peor que no linkear nada.
    #
    # Si el producto se despublica, NO da 404: `product_detail` redirige al
    # catálogo (app.py:670, verificado en producción). O sea que el peor caso
    # es que el cliente caiga en /productos, no en un error — por eso el link
    # puede vivir acá sin una consulta a la base por request.
    # Dejarlo vacío ("") apaga el link y la foto vuelve a ser decorativa.
    "foto_link": "/productos/nike-nike-mind-001",
    "foto_producto": "Nike Mind 001",
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
        "foto": PROMO.get("foto") or "",
        "foto_pie": PROMO.get("foto_pie") or "",
        "foto_link": PROMO.get("foto_link") or "",
        "foto_producto": PROMO.get("foto_producto") or "",
    }
