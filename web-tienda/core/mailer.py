"""Mails transaccionales de la tienda: confirmación al cliente y aviso a Diego.

Diego se enteraba de las ventas de casualidad (el pedido de Celeste quedó
"pendiente" un día entero sin que nadie lo viera). Esto manda:

  - PEDIDO NUEVO  → aviso a la tienda apenas alguien completa el checkout
                    (aunque el pago siga pendiente: ahí es cuando hay que
                    escribirle al cliente, no después)
  - PAGO ACREDITADO → confirmación linda al cliente + aviso a la tienda

Config por env (sin credenciales configuradas NO manda nada y NO rompe nada):
  SMTP_USER  → cuenta que envía (ej: miamiimport@gmail.com)
  SMTP_PASS  → app password de Gmail (Cuenta Google → Seguridad → Contraseñas
               de aplicaciones; requiere verificación en dos pasos activa)
  SMTP_HOST  → default smtp.gmail.com   ·  SMTP_PORT → default 587
  MAIL_TIENDA → a dónde llegan los avisos (default: SMTP_USER)

Todo se envía en un thread aparte y con try/except total: un SMTP caído
JAMÁS puede romper un checkout o un webhook de Stripe.
"""
from __future__ import annotations

import logging
import os
import smtplib
import threading
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

log = logging.getLogger("mailer")

_TIENDA_NOMBRE = "MIAMI IMPORT"
_TIENDA_URL = "https://miamiimport.com.ar"
_ORO = "#b99b63"
_NEGRO = "#0E0B08"


def _conf() -> dict | None:
    user = (os.environ.get("SMTP_USER") or "").strip()
    pw = (os.environ.get("SMTP_PASS") or "").strip()
    if not user or not pw:
        return None
    return {
        "host": (os.environ.get("SMTP_HOST") or "smtp.gmail.com").strip(),
        "port": int(os.environ.get("SMTP_PORT") or 587),
        "user": user,
        "pass": pw,
        "tienda": (os.environ.get("MAIL_TIENDA") or user).strip(),
    }


def habilitado() -> bool:
    return _conf() is not None


def _enviar(destino: str, asunto: str, html: str) -> None:
    """Envío real, siempre desde un thread y a prueba de todo."""
    def _worker() -> None:
        conf = _conf()
        if not conf or not destino:
            return
        try:
            msg = MIMEMultipart("alternative")
            msg["Subject"] = asunto
            msg["From"] = f"{_TIENDA_NOMBRE} <{conf['user']}>"
            msg["To"] = destino
            msg.attach(MIMEText(html, "html", "utf-8"))
            with smtplib.SMTP(conf["host"], conf["port"], timeout=30) as s:
                s.starttls()
                s.login(conf["user"], conf["pass"])
                s.sendmail(conf["user"], [destino], msg.as_string())
            log.info("mail '%s' -> %s", asunto, destino)
        except Exception:  # noqa: BLE001 — nunca propagar
            log.exception("no se pudo mandar '%s' a %s", asunto, destino)

    threading.Thread(target=_worker, daemon=True).start()


# --------------------------------------------------------------------------- #
# Armado de contenido
# --------------------------------------------------------------------------- #
def _pesos(monto) -> str:
    """$ 428.571 — el replace va SOLO sobre el número, no sobre nombres."""
    return "$ " + f"{float(monto or 0):,.0f}".replace(",", ".")


def _filas_items(order) -> str:
    filas = []
    for it in order.items:
        talle = f" · Talle {it.variant_value}" if it.variant_value else ""
        filas.append(
            f"<tr><td style='padding:10px 0;border-bottom:1px solid #eee'>"
            f"{it.product_name}{talle} × {it.quantity}</td>"
            f"<td style='padding:10px 0;border-bottom:1px solid #eee;"
            f"text-align:right;white-space:nowrap'>{_pesos(it.unit_price)}</td></tr>")
    return "".join(filas)


def _direccion(order) -> str:
    d = order.shipping_address or {}
    if d.get("canal") == "local":
        return "Retiro / venta en el local"
    partes = [f"{d.get('street', '')} {d.get('number', '')}".strip(),
              d.get("floor") or "", d.get("city") or "", d.get("province") or "",
              f"CP {d.get('zipcode')}" if d.get("zipcode") else ""]
    return " · ".join(p for p in partes if p) or "sin dirección cargada"


def _plantilla(titulo: str, cuerpo: str) -> str:
    return f"""
<div style="background:#f5f2ec;padding:28px 12px;font-family:Arial,Helvetica,sans-serif">
  <div style="max-width:560px;margin:0 auto;background:#ffffff;border-radius:14px;overflow:hidden">
    <div style="background:{_NEGRO};padding:22px 28px;text-align:center">
      <span style="color:{_ORO};font-size:18px;letter-spacing:.35em;font-weight:bold">MIAMI&nbsp;IMPORT</span>
    </div>
    <div style="padding:28px">
      <h1 style="margin:0 0 16px;font-size:20px;color:#1a1a1a">{titulo}</h1>
      {cuerpo}
    </div>
    <div style="padding:16px 28px;background:#faf8f4;text-align:center;font-size:12px;color:#999">
      {_TIENDA_NOMBRE} — Indumentaria original importada · <a href="{_TIENDA_URL}" style="color:{_ORO}">{_TIENDA_URL.replace('https://', '')}</a>
    </div>
  </div>
</div>"""


def _total(order) -> str:
    return _pesos(order.total)


# --------------------------------------------------------------------------- #
# Los tres avisos
# --------------------------------------------------------------------------- #
def avisar_pedido_nuevo(order) -> None:
    """A la tienda, apenas se crea el pedido (pago aún pendiente)."""
    conf = _conf()
    if not conf:
        return
    tel = order.contact_phone or (order.shipping_address or {}).get("phone") or "s/tel"
    cuerpo = f"""
      <p style="color:#444;line-height:1.6">Entró un pedido en la web y el pago está
      <strong>pendiente</strong>. Este es el momento de escribirle al cliente y cerrarlo.</p>
      <table style="width:100%;border-collapse:collapse;font-size:14px;color:#1a1a1a">{_filas_items(order)}</table>
      <p style="font-size:16px;margin:14px 0 4px"><strong>Total: {_total(order)}</strong></p>
      <p style="color:#444;font-size:14px;line-height:1.7;margin:14px 0 0">
        <strong>{order.contact_name or 'Sin nombre'}</strong><br/>
        {order.email or 'sin email'} · {tel}<br/>{_direccion(order)}</p>
      <p style="margin:22px 0 0"><a href="{_TIENDA_URL}/panel/#/panel/pedidos"
        style="background:{_ORO};color:#111;padding:12px 22px;border-radius:999px;
        text-decoration:none;font-weight:bold;font-size:13px">Ver en el panel</a></p>"""
    _enviar(conf["tienda"], f"🛍️ Pedido #{order.number} — {order.contact_name or 'cliente web'} (pago pendiente)",
            _plantilla(f"Pedido nuevo #{order.number}", cuerpo))


def avisar_pago_acreditado(order) -> None:
    """A la tienda, cuando el pago quedó acreditado: a despachar."""
    conf = _conf()
    if not conf:
        return
    tel = order.contact_phone or (order.shipping_address or {}).get("phone") or "s/tel"
    cuerpo = f"""
      <p style="color:#444;line-height:1.6">💰 <strong>Pago acreditado.</strong> El pedido queda listo para despachar.</p>
      <table style="width:100%;border-collapse:collapse;font-size:14px;color:#1a1a1a">{_filas_items(order)}</table>
      <p style="font-size:16px;margin:14px 0 4px"><strong>Total: {_total(order)}</strong></p>
      <p style="color:#444;font-size:14px;line-height:1.7;margin:14px 0 0">
        <strong>{order.contact_name or 'Sin nombre'}</strong><br/>
        {order.email or 'sin email'} · {tel}<br/>{_direccion(order)}</p>
      <p style="margin:22px 0 0"><a href="{_TIENDA_URL}/panel/#/panel/pedidos"
        style="background:{_ORO};color:#111;padding:12px 22px;border-radius:999px;
        text-decoration:none;font-weight:bold;font-size:13px">Ver en el panel</a></p>"""
    _enviar(conf["tienda"], f"💰 PAGADO — Pedido #{order.number} · {_total(order)}",
            _plantilla(f"Pedido #{order.number} pagado", cuerpo))


def confirmar_al_cliente(order) -> None:
    """Al cliente, cuando su pago quedó acreditado."""
    if not order.email:
        return
    nombre = (order.contact_name or "").split(" ")[0] or "Hola"
    cuerpo = f"""
      <p style="color:#444;line-height:1.7">¡{nombre}, gracias por tu compra!
      Tu pago quedó acreditado y ya estamos preparando tu pedido.</p>
      <table style="width:100%;border-collapse:collapse;font-size:14px;color:#1a1a1a">{_filas_items(order)}</table>
      <p style="font-size:16px;margin:14px 0 4px"><strong>Total: {_total(order)}</strong></p>
      <p style="color:#444;font-size:14px;line-height:1.7;margin:14px 0 0">
        <strong>Envío a:</strong><br/>{_direccion(order)}</p>
      <p style="color:#444;font-size:14px;line-height:1.7">Cualquier duda respondé este
      mail o escribinos por WhatsApp al <strong>11 6232-1391</strong>.</p>"""
    _enviar(order.email, f"Tu pedido #{order.number} está confirmado — {_TIENDA_NOMBRE}",
            _plantilla("¡Compra confirmada!", cuerpo))
