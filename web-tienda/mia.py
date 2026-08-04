# -*- coding: utf-8 -*-
"""
MIA — la asistente de la casa (MIAMI IMPORT).

POST /api/mia/chat  →  {reply: str, source: "claude" | "local"}

Regla de oro: Mia ES DE LA CASA. Habla como parte del equipo ("nosotros"),
jamás como bot genérico. Con ANTHROPIC_API_KEY responde Claude (Haiku) con el
catálogo REAL inyectado en el system prompt; sin key o ante cualquier error de
la API, contesta el motor local con los mismos datos — el chat nunca queda mudo.
"""
from __future__ import annotations

import json
import os
import re
import time
import unicodedata
from collections import defaultdict, deque
from pathlib import Path
from urllib.parse import quote

import requests
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session, selectinload

from core.db import get_db
from core.models import Product

HERE = Path(__file__).resolve().parent

mia_router = APIRouter(prefix="/api/mia", tags=["mia"])

# ---------------------------------------------------------------------------
# Constantes de la casa
# ---------------------------------------------------------------------------
WA_NUMERO = "5491162321391"          # Diego — atención 1:1
IG_HANDLE = "@miamimport_"
CLAUDE_MODEL = "claude-haiku-4-5-20251001"
CLAUDE_MAX_TOKENS = 400
CLAUDE_TIMEOUT = 25                  # seg; si tarda más, cae al motor local

# bot_config.json: la MISMA config que Diego edita en el panel (envíos/pagos/
# cambios). Se lee del archivo del panel — una sola fuente de verdad.
BOT_CONFIG_FILE = HERE / "panel" / "data" / "bot_config.json"

# Defaults sensatos si el panel todavía no cargó nada.
DEFAULT_SHIPPING = ("Hacemos entrega personal en CABA y GBA cercano, coordinamos "
                    "día y horario por WhatsApp. Al interior va por correo y llega "
                    "en 24-72hs hábiles.")
DEFAULT_PAYMENT = ("Aceptamos transferencia bancaria (con descuento), efectivo en "
                   "la entrega y tarjeta.")
DEFAULT_EXCHANGE = ("Tenés cambio de talle garantizado dentro de las 48hs hábiles "
                    "de recibida la pieza.")

# ---------------------------------------------------------------------------
# Rate limit simple por IP (en memoria; 1 instancia)
# ---------------------------------------------------------------------------
_RATE_LIMIT = 20        # requests
_RATE_WINDOW = 60       # por minuto
_hits: dict[str, deque] = defaultdict(deque)


def _rate_limited(ip: str) -> bool:
    now = time.time()
    q = _hits[ip]
    while q and now - q[0] > _RATE_WINDOW:
        q.popleft()
    if len(q) >= _RATE_LIMIT:
        return True
    q.append(now)
    return False


# ---------------------------------------------------------------------------
# Helpers de formato
# ---------------------------------------------------------------------------
def _ars(value) -> str:
    """$ 714.286 — entero con separador de miles (estilo de la web)."""
    try:
        n = int(round(float(value)))
    except (TypeError, ValueError):
        return ""
    return "$ " + f"{n:,}".replace(",", ".")


def _norm(s: str) -> str:
    """minúsculas + sin acentos, para matchear keywords."""
    s = unicodedata.normalize("NFD", s or "")
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return s.lower()


def _wa_link(texto: str) -> str:
    return f"https://wa.me/{WA_NUMERO}?text={quote(texto)}"


def _wa_producto(nombre: str) -> str:
    return _wa_link(f"Hola Diego, vengo de la web. Me interesa: {nombre}. ¿Lo tenés disponible?")


# ---------------------------------------------------------------------------
# Contexto vivo (catálogo real + config del panel), cacheado 60s
# ---------------------------------------------------------------------------
_cache: dict = {"ts": 0.0, "data": None}
_CACHE_TTL = 60


def _load_bot_config() -> dict:
    cfg = {}
    try:
        if BOT_CONFIG_FILE.exists():
            cfg = json.loads(BOT_CONFIG_FILE.read_text(encoding="utf-8"))
    except Exception:
        cfg = {}
    return {
        "shipping": (cfg.get("shipping_info") or "").strip() or DEFAULT_SHIPPING,
        "payment": (cfg.get("payment_info") or "").strip() or DEFAULT_PAYMENT,
        "exchange": (cfg.get("exchange_info") or "").strip() or DEFAULT_EXCHANGE,
    }


def _build_context(db: Session) -> dict:
    """Catálogo REAL desde la DB + bot_config. Se reconstruye cada 60s."""
    now = time.time()
    if _cache["data"] is not None and now - _cache["ts"] < _CACHE_TTL:
        return _cache["data"]

    prods = (
        db.query(Product)
        .options(selectinload(Product.variants))
        .filter(Product.published.is_(True))
        .all()
    )

    marcas: dict[str, dict] = {}
    productos: list[dict] = []
    for p in prods:
        brand = (p.brand or "Otras").strip()
        price = p.min_price
        talles = [v.value for v in p.variants
                  if (v.stock or 0) > 0 and v.visible and v.value]
        stock = p.total_stock

        m = marcas.setdefault(brand, {"n": 0, "min": None, "max": None})
        m["n"] += 1
        if price is not None:
            fp = float(price)
            m["min"] = fp if m["min"] is None else min(m["min"], fp)
            m["max"] = fp if m["max"] is None else max(m["max"], fp)

        productos.append({
            "name": p.name,
            "brand": brand,
            "handle": p.handle,
            "price": float(price) if price is not None else None,
            "talles": talles,
            "stock": stock,
        })

    # Priorizar con stock; dentro de cada grupo, lo más nuevo primero.
    productos.sort(key=lambda x: (0 if x["stock"] > 0 else 1, -x["stock"]))
    destacados = productos[:40]

    data = {"marcas": marcas, "productos": productos,
            "destacados": destacados, "config": _load_bot_config()}
    _cache["ts"] = now
    _cache["data"] = data
    return data


def _system_prompt(ctx: dict) -> str:
    cfg = ctx["config"]
    lineas_marcas = []
    for brand, m in sorted(ctx["marcas"].items(), key=lambda kv: -kv[1]["n"]):
        rango = ""
        if m["min"] is not None:
            rango = (f" · {_ars(m['min'])}" if m["min"] == m["max"]
                     else f" · {_ars(m['min'])} a {_ars(m['max'])}")
        lineas_marcas.append(f"- {brand}: {m['n']} modelos{rango}")

    lineas_prods = []
    for p in ctx["destacados"]:
        talles = ", ".join(p["talles"]) if p["talles"] else "consultar stock"
        precio = _ars(p["price"]) if p["price"] is not None else "consultar"
        lineas_prods.append(
            f"- {p['name']} | {p['brand']} | {precio} | talles: {talles} | /productos/{p['handle']}/")

    return f"""Sos Mia, del equipo de MIAMI IMPORT — tienda argentina de indumentaria de lujo importada CON LICENCIA (Milano → Buenos Aires). Hablás como parte de la casa: "nosotros", "tenemos", "te lo traemos". Nunca digas que sos una IA, un asistente virtual, un bot ni un modelo de lenguaje, y nunca menciones a Anthropic ni a Claude: si te preguntan quién sos, sos Mia, del equipo de Miami Import.

CÓMO HABLÁS:
- Criollo premium: tuteo argentino, frases cortas, con seguridad, sin chamuyo.
- Cero tics de IA: nada de "¡Claro que sí!", nada de emojis, nada de listas con viñetas salvo que te pidan comparar.
- Respondé corto: 2 a 5 oraciones.
- La casa es "original o nada": todo con licencia y comprobante de origen por pieza. Unidades contadas — cuando no está, no vuelve.

QUÉ HACÉS:
- Recomendá piezas CONCRETAS del catálogo de abajo, con precio y link en formato [Nombre de la pieza](/productos/handle/). Usá SOLO productos, precios y talles que figuren en el catálogo: nunca inventes stock, precios ni modelos.
- Si algo no está en el catálogo, ofrecé el pedido puntual a importación: 10 a 15 días desde Italia o Miami, lo gestiona Diego.
- Si hay intención de compra, consulta de talle o de stock, cerrá derivando a Diego por WhatsApp con un link así: [Escribile a Diego](https://wa.me/{WA_NUMERO}?text=TEXTO_URL_ENCODED) — el texto prellenado nombra la pieza puntual.
- Envíos, pagos y cambios: respondé SOLO con la info de la casa de abajo, sin inventar condiciones.
- Nuestro Instagram es {IG_HANDLE}.

INFO DE LA CASA (la verdad operativa, editada por Diego):
Envíos: {cfg['shipping']}
Pagos: {cfg['payment']}
Cambios: {cfg['exchange']}
Atención 1:1: Diego, WhatsApp +54 9 11 6232-1391.

MARCAS PUBLICADAS HOY:
{chr(10).join(lineas_marcas)}

CATÁLOGO DISPONIBLE HOY (nombre | marca | precio ARS | talles con stock | link):
{chr(10).join(lineas_prods)}"""


# ---------------------------------------------------------------------------
# Claude (HTTP puro con requests — sin SDK)
# ---------------------------------------------------------------------------
def _call_claude(system: str, msgs: list[dict]) -> str | None:
    key = os.environ.get("ANTHROPIC_API_KEY", "").strip()
    if not key:
        return None
    try:
        r = requests.post(
            "https://api.anthropic.com/v1/messages",
            headers={
                "x-api-key": key,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            },
            json={
                "model": CLAUDE_MODEL,
                "max_tokens": CLAUDE_MAX_TOKENS,
                "system": system,
                "messages": msgs,
            },
            timeout=CLAUDE_TIMEOUT,
        )
        if r.status_code != 200:
            return None
        data = r.json()
        if data.get("stop_reason") == "refusal":
            return None
        parts = [b.get("text", "") for b in data.get("content", [])
                 if b.get("type") == "text"]
        text = "\n".join(p for p in parts if p).strip()
        return text or None
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Motor local (fallback OBLIGATORIO — el chat nunca queda mudo)
# ---------------------------------------------------------------------------
_KW_ENVIO = ("envio", "envios", "envian", "enviar", "llega", "llegan", "demora",
             "correo", "mandan", "entrega", "entregan", "shipping", "interior")
_KW_PAGO = ("pago", "pagar", "pagos", "abonar", "transferencia", "tarjeta",
            "cuota", "cuotas", "efectivo", "mercado pago", "mercadopago")
_KW_CAMBIO = ("cambio", "cambiar", "cambios", "devolucion", "devolver",
              "garantia", "me queda")
_KW_PEDIDO = ("a pedido", "encargar", "encargo", "encargue", "importan",
              "importar", "traen", "conseguir", "conseguis", "consiguen",
              "pedido puntual")
_KW_SALUDO = ("hola", "buenas", "buen dia", "buenos dias", "buenas tardes",
              "buenas noches", "que tal", "como va", "como andas")

_STOPWORDS = {"que", "con", "para", "una", "uno", "unos", "unas", "los", "las",
              "del", "por", "tenes", "tienen", "hay", "algun", "alguna",
              "quiero", "busco", "necesito", "sale", "cuanto", "cuesta",
              "precio", "ver", "mostrame", "mostra", "pasame", "algo", "esta",
              "estan", "talle", "color", "negro", "negra", "blanco", "blanca"}


def _match_products(norm_msg: str, ctx: dict) -> list[dict]:
    """Matchea marcas/palabras del mensaje contra el catálogo real."""
    scored = []
    for p in ctx["productos"]:
        score = 0
        nb = _norm(p["brand"])
        # marca completa o cada palabra de la marca ("emporio armani" → "armani")
        if nb and nb in norm_msg:
            score += 4
        else:
            for w in nb.split():
                if len(w) > 3 and w in norm_msg:
                    score += 3
        for w in set(_norm(p["name"]).split()):
            if len(w) > 3 and w not in _STOPWORDS and w in norm_msg:
                score += 1
        if score > 0:
            scored.append((score, 0 if p["stock"] > 0 else 1, p))
    scored.sort(key=lambda t: (-t[0], t[1]))
    return [p for _, _, p in scored[:3]]


def _linea_producto(p: dict) -> str:
    precio = _ars(p["price"]) if p["price"] is not None else "consultar"
    talles = f" (talles {', '.join(p['talles'])})" if p["talles"] else ""
    return f"[{p['name']}](/productos/{p['handle']}/) a {precio}{talles}"


def _marcas_top(ctx: dict, n: int = 6) -> str:
    tops = sorted(ctx["marcas"].items(), key=lambda kv: -kv[1]["n"])[:n]
    return ", ".join(b for b, _ in tops)


def _fallback_reply(user_msg: str, ctx: dict) -> str:
    cfg = ctx["config"]
    m = _norm(user_msg)
    wa_general = _wa_link("Hola Diego, vengo de la web de Miami Import. Tengo una consulta.")

    def _cierre_wa(txt: str) -> str:
        return f"{txt} Cualquier detalle puntual lo cerrás directo con Diego: [Escribile por WhatsApp]({wa_general})."

    if any(k in m for k in _KW_ENVIO):
        return _cierre_wa(cfg["shipping"])
    if any(k in m for k in _KW_PAGO):
        return _cierre_wa(cfg["payment"])
    if any(k in m for k in _KW_CAMBIO):
        return _cierre_wa(cfg["exchange"])
    if any(k in m for k in _KW_PEDIDO):
        return _cierre_wa(
            "Trabajamos pedidos puntuales a importación: nos decís el modelo y "
            "lo traemos desde Italia o Miami en 10 a 15 días, siempre original "
            "con comprobante de origen.")

    matches = _match_products(m, ctx)
    if matches:
        if len(matches) == 1:
            p = matches[0]
            wa = _wa_producto(p["name"])
            return (f"Tenemos {_linea_producto(p)}. Original con comprobante de "
                    f"origen, unidades contadas. Si lo querés, te lo aparta "
                    f"Diego: [Escribile por WhatsApp]({wa}).")
        lineas = " · ".join(_linea_producto(p) for p in matches)
        wa = _wa_producto(matches[0]["name"])
        return (f"De eso tenemos: {lineas}. Todo original con licencia y "
                f"unidades contadas. Para reservar el tuyo, "
                f"[escribile a Diego por WhatsApp]({wa}).")

    if any(m.startswith(k) or m == k for k in _KW_SALUDO) and len(m) <= 25:
        return (f"Hola, soy Mia, del equipo de Miami Import. Trabajamos "
                f"{_marcas_top(ctx)} y más, todo original importado con "
                f"licencia. Contame qué marca o prenda buscás y te muestro "
                f"lo que hay.")

    return (f"Trabajamos {_marcas_top(ctx)}, entre otras casas — todo original "
            f"importado con licencia y unidades contadas. Contame qué buscás "
            f"(marca, prenda o talle) y te muestro opciones concretas. Si "
            f"preferís, hablás directo con Diego: "
            f"[WhatsApp]({wa_general}). También traemos piezas a pedido desde "
            f"Italia y Miami en 10 a 15 días.")


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------
@mia_router.post("/chat")
def mia_chat(body: dict, request: Request, db: Session = Depends(get_db)):
    ip = request.client.host if request.client else "?"
    if _rate_limited(ip):
        raise HTTPException(429, "Demasiados mensajes seguidos. Probá en un minuto.")

    raw = body.get("messages") if isinstance(body, dict) else None
    if not isinstance(raw, list):
        raise HTTPException(400, "messages debe ser una lista")

    # Sanitizar y truncar server-side: roles válidos, contenido acotado,
    # historial corto (máx 12 mensajes).
    msgs: list[dict] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        role = item.get("role")
        content = item.get("content")
        if role not in ("user", "assistant") or not isinstance(content, str):
            continue
        content = content.strip()[:1500]
        if content:
            msgs.append({"role": role, "content": content})
    msgs = msgs[-12:]
    while msgs and msgs[0]["role"] != "user":
        msgs.pop(0)
    if not msgs or msgs[-1]["role"] != "user":
        raise HTTPException(400, "falta el mensaje del cliente")

    ctx = _build_context(db)
    reply = _call_claude(_system_prompt(ctx), msgs)
    if reply:
        return {"reply": reply, "source": "claude"}

    return {"reply": _fallback_reply(msgs[-1]["content"], ctx), "source": "local"}
