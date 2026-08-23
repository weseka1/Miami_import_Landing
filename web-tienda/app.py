#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MIAMI_IMPORT — Tienda pública (FastAPI + Jinja2), independiente de Tiendanube.

Lee el catálogo de la base de datos PROPIA (la misma que administra panel-control)
y renderiza el theme portado a Jinja2, conservando el diseño Champagne Noir.

Uso:
    python app.py
Abrir: http://localhost:8001
"""
from __future__ import annotations

import re
import secrets
import time
import unicodedata
from decimal import ROUND_HALF_UP, Decimal
from pathlib import Path
from types import SimpleNamespace

import uvicorn
from fastapi import Cookie, Depends, FastAPI, HTTPException, Request
from fastapi.responses import HTMLResponse, PlainTextResponse, RedirectResponse, Response
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session

from auth_store import account_router, oauth_router
from cart import cart_router, cart_summary, get_or_create_cart, resolve_cart
from checkout import checkout_router, confirmar_pago_desde_stripe
from core import storage
from core.config import settings
from core.db import get_db, init_db
from core.home_config import get_home_config
from core.models import Category, Order, Product, User
from core.web_security import install_security
from deps import current_user
from mia import mia_router

# El panel administrativo, empaquetado como sub-app (web-tienda/panel/). Comparte
# el mismo core y la misma base de datos que la tienda.
from panel.app import app as panel_app
from panel.auth import ensure_admin as ensure_panel_admin

HERE = Path(__file__).resolve().parent

# Los docs de FastAPI enumeran todos los endpoints y esquemas: en producción es
# un mapa gratis para el atacante.
app = FastAPI(
    title="MIAMI_IMPORT Tienda", version="2.0",
    docs_url="/docs" if settings.DEV_MODE else None,
    redoc_url="/redoc" if settings.DEV_MODE else None,
    openapi_url="/openapi.json" if settings.DEV_MODE else None,
)

# Jinja busca en templates_jinja/ y también en snipplets/ (para incluir miami-styles.tpl)
templates = Jinja2Templates(directory=[str(HERE / "templates_jinja"), str(HERE / "snipplets")])
templates.env.globals["USD_RATE"] = settings.USD_TO_ARS_RATE
templates.env.globals["STORE_NAME"] = "MIAMI IMPORT"
# Píxel de Meta: gateado por env. Cuando exista el Business nuevo de Diego se
# setea META_PIXEL_ID en Render y la web empieza a juntar audiencias sola.
import os as _osenv  # noqa: E402
templates.env.globals["META_PIXEL_ID"] = (_osenv.environ.get("META_PIXEL_ID") or "").strip()


# --------------------------------------------------------------------------- #
# Helpers de presentación
# --------------------------------------------------------------------------- #
def _fmt_monto(value, simbolo: str) -> str:
    """Formatea un importe con separador de miles.

    Redondea (no trunca): con int(), $84.999,50 se exhibía "$ 84.999" y se
    cobraban $84.999,50 — mostrar menos de lo que se cobra es justo lo que
    sanciona la ley de defensa del consumidor.

    Pero por debajo de 10 se muestran los centavos: redondear a entero convertía
    US$ 0,07 en "US$ 0", que es directamente un precio equivocado.
    """
    if value is None:
        return ""
    d = Decimal(str(value))
    if abs(d) < 10:
        n = d.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        return f"{simbolo} {n:,.2f}".replace(",", "@").replace(".", ",").replace("@", ".")
    n = d.quantize(Decimal("1"), rounding=ROUND_HALF_UP)
    return f"{simbolo} {n:,.0f}".replace(",", ".")


def fmt_ars(value) -> str:
    return _fmt_monto(value, "$")


def fmt_usd(value) -> str:
    return _fmt_monto(value, "US$")


# Símbolo por moneda, para los productos que se cobran en otra distinta a la
# de la tienda. Sin esto un producto en dólares se mostraba con "$" y parecía
# 300 veces más barato de lo que se le va a cobrar.
_SIMBOLOS = {"ars": "$", "usd": "US$", "eur": "€", "brl": "R$", "clp": "$", "uyu": "$U"}


def fmt_moneda(value, currency: str | None = None) -> str:
    cur = (currency or settings.CHECKOUT_CURRENCY or "ars").strip().lower()
    return _fmt_monto(value, _SIMBOLOS.get(cur, cur.upper()))


templates.env.filters["ars"] = fmt_ars
templates.env.filters["usd"] = fmt_usd
templates.env.filters["money"] = fmt_moneda   # {{ importe | money(moneda) }}
# Filtro del theme original: 'images/x.webp' | static_url -> /static/images/x.webp
# Permite incluir los snipplets .tpl (miami-trilogy, etc.) casi sin tocarlos.
templates.env.filters["static_url"] = lambda p: f"/static/{p}"


def media_url(p: str | None) -> str:
    """URL de una imagen de la home, venga de donde venga.

    Las imágenes de fábrica son rutas del theme ('images/x.webp' o
    '/static/images/x.webp'); las que sube Diego desde el panel son URLs
    completas de Supabase. Este filtro acepta las tres formas para que la
    plantilla no tenga que saber cuál es cuál.
    """
    p = (p or "").strip()
    if not p:
        return "/static/images/empty-placeholder.png"
    if p.startswith(("http://", "https://", "/")):
        return p
    return f"/static/{p}"


templates.env.filters["media_url"] = media_url
templates.env.filters["has_custom_image"] = lambda p: False
# {{ url | thumb(640) }} -> foto redimensionada al vuelo (ver core/storage.py)
templates.env.filters["thumb"] = storage.thumb_url
templates.env.globals["store"] = {"products_url": "/productos"}


def _con_relaciones(db: Session):
    """Query de Product con variantes e imágenes cargadas de una.

    Las tarjetas del catálogo leen product.images y product.min_price/
    total_stock (que recorren las variantes). Sin esto era una consulta por
    producto por relación: cientos de viajes a la Postgres remota por página.
    """
    from sqlalchemy.orm import selectinload
    return (db.query(Product)
            .options(selectinload(Product.variants),
                     selectinload(Product.images)))


# --------------------------------------------------------------------------- #
# Caché en proceso de lo que se repite en CADA visita
# --------------------------------------------------------------------------- #
# La base está en São Paulo y el servidor en Oregon: cada consulta cuesta unos
# 180 ms de ida y vuelta. Estas dos (las marcas del footer y la configuración
# de la home) devuelven lo mismo para todos los visitantes y cambian solo
# cuando Diego edita algo, así que pedirlas en cada visita es regalar 360 ms.
#
# El panel corre en ESTE MISMO proceso (app.mount("/panel", panel_app)) y con
# un solo worker, así que al guardar desde el panel se limpia el caché y el
# cambio se ve al instante, sin esperar el TTL.
# ⚠️ Si algún día se levantan varios workers o el panel se separa a otro
# servicio, esa invalidación deja de alcanzar: ahí cada worker tendría su
# propia copia y habría que bajar el TTL o usar un caché compartido.
_CACHE_TTL = 60
_cache_navcat: dict = {"ts": 0.0, "data": None}
_cache_homecfg: dict = {"ts": 0.0, "data": None}


def limpiar_caches_web() -> None:
    """Tira el caché de la tienda. La llama el panel al guardar."""
    _cache_navcat.update(ts=0.0, data=None)
    _cache_homecfg.update(ts=0.0, data=None)
    _tipos_cache.update(ts=0.0, data=None)


def nav_categories(db: Session) -> list[SimpleNamespace]:
    """Marcas de primer nivel para el footer. Cacheadas.

    Se guardan como objetos PLANOS (name/handle), no filas del ORM: una fila
    cacheada queda atada a la sesión que la trajo, y al reusarla en el request
    siguiente —con esa sesión ya cerrada— SQLAlchemy intenta refrescarla y
    revienta con DetachedInstanceError. Con datos planos no hay sorpresa.
    """
    ahora = time.time()
    if _cache_navcat["data"] is not None and ahora - _cache_navcat["ts"] < _CACHE_TTL:
        return _cache_navcat["data"]
    data = [
        SimpleNamespace(name=c.name, handle=c.handle, id=c.id)
        for c in db.query(Category)
        .filter(Category.parent_id.is_(None))
        .order_by(Category.name)
        .all()
    ]
    _cache_navcat.update(ts=ahora, data=data)
    return data


def home_config_cacheada(db: Session) -> dict:
    """Configuración de la home (la que edita Diego). Cacheada."""
    ahora = time.time()
    if _cache_homecfg["data"] is not None and ahora - _cache_homecfg["ts"] < _CACHE_TTL:
        return _cache_homecfg["data"]
    data = get_home_config(db)
    _cache_homecfg.update(ts=ahora, data=data)
    return data


# --------------------------------------------------------------------------- #
# Menú de tienda: TIPOS de prenda → marcas (estructura invertida de la DB)
# --------------------------------------------------------------------------- #
_TIPOS_TTL = 60
_tipos_cache: dict = {"ts": 0.0, "data": None}


def _slug_tipo(nombre: str) -> str:
    """'Buzos' -> 'buzos' — minúsculas, sin acentos, espacios a guiones."""
    s = unicodedata.normalize("NFKD", (nombre or "").strip().lower())
    s = "".join(ch for ch in s if not unicodedata.combining(ch))
    return re.sub(r"[^a-z0-9]+", "-", s).strip("-")


def nav_tipos(db: Session) -> list[dict]:
    """Menú de tienda profesional: TIPO de prenda arriba, marcas debajo.

    En la DB los padres son MARCAS (Diesel, Amiri…) y las hijas TIPOS (Buzos,
    Remeras… con parent_id=marca). El menú se navega al revés: se agrupan las
    hijas por nombre normalizado (title case) y cada (tipo, marca) linkea a la
    categoría hija (/categoria/{handle}). Marcas alfabéticas; tipos con más
    marcas primero. Cache 60s en memoria, mismo criterio que Mia.
    """
    now = time.time()
    if _tipos_cache["data"] is not None and now - _tipos_cache["ts"] < _TIPOS_TTL:
        return _tipos_cache["data"]

    padres = {c.id: c for c in db.query(Category).filter(Category.parent_id.is_(None))}

    # Categorías que HOY tienen algo publicado. La migración dejó varias
    # vacías (cintos, remeras, pantalones1…) y el menú las mostraba igual:
    # el cliente clickeaba y caía en una página en blanco.
    from core.models import product_categories
    con_stock = {
        cid for (cid,) in db.query(product_categories.c.category_id)
        .join(Product, Product.id == product_categories.c.product_id)
        .filter(Product.published.is_(True))
        .distinct()
    }

    grupos: dict[str, list[dict]] = {}
    for hija in db.query(Category).filter(Category.parent_id.isnot(None)):
        marca = padres.get(hija.parent_id)
        nombre = (hija.name or "").strip().title()
        if not marca or not nombre or hija.id not in con_stock:
            continue
        grupos.setdefault(nombre, []).append({"marca": marca.name, "handle": hija.handle})

    data = [
        {"nombre": nombre, "slug": _slug_tipo(nombre),
         "marcas": sorted(marcas, key=lambda m: m["marca"].lower())}
        for nombre, marcas in sorted(grupos.items(), key=lambda kv: (-len(kv[1]), kv[0]))
    ]
    _tipos_cache.update(ts=now, data=data)
    return data


def base_context(request: Request, db: Session, **extra) -> dict:
    ctx = {
        "request": request,
        # Dominio real (no settings.STORE_BASE_URL, que en prod apunta al host
        # viejo de Render). Lo usan los links de WhatsApp de las fichas.
        "tienda_url": f"{request.url.scheme}://{request.url.netloc}".rstrip("/"),
        "nav_categories": nav_categories(db),
        "nav_tipos": nav_tipos(db),
        "usd_rate": settings.USD_TO_ARS_RATE,
        # Nonce de la CSP: cada <script> inline lo cita. Sin esto los scripts
        # de las plantillas no se ejecutan (script-src ya no lleva
        # 'unsafe-inline', que es lo que hacía inútil a la CSP frente a XSS).
        "csp_nonce": getattr(request.state, "csp_nonce", ""),
    }
    ctx.update(extra)
    return ctx


# --------------------------------------------------------------------------- #
# Startup
# --------------------------------------------------------------------------- #
# CSP de la TIENDA: permite scripts/estilos inline. El tema (portado de
# TiendaNube) tiene <script> y handlers on* inline por todos lados —el 3D, las
# animaciones, el carrito— y sin 'unsafe-inline' el navegador los bloquea.
# El riesgo de XSS acá está tapado en la capa correcta: el único campo con HTML
# enriquecido (product.description) se sanitiza en el backend, así que ni con
# inline permitido puede inyectarse un <script>. El PANEL sí queda con CSP
# estricta (no tiene inline y es la superficie sensible).
install_security(
    app,
    csp_extra={"script-src": "'unsafe-inline' https://bot-miami.onrender.com https://connect.facebook.net",
               "style-src": "'unsafe-inline'",
               "img-src": "https://miamiimport.com.ar https://www.facebook.com",
               "connect-src": "https://bot-miami.onrender.com https://miamiimport.com.ar https://www.facebook.com https://connect.facebook.net"},
    use_nonce=False,
    # El webhook NO se limita: Stripe entrega desde un pool chico de IPs y una
    # tanda normal de pedidos (cada uno dispara varios eventos) superaba los
    # 30/min y se comía 429. Reintenta, pero deja los pedidos en "confirmando"
    # varios minutos, que es justo lo que empuja al cliente a pagar dos veces.
    # La firma HMAC ya es la defensa real contra eventos falsos.
    sensitive_prefixes=("/api/account/login", "/api/account/register",
                        "/api/account/password", "/api/checkout"),
)

app.include_router(cart_router)
app.include_router(account_router)
app.include_router(oauth_router)
app.include_router(checkout_router)
app.include_router(mia_router)   # Mia, la asistente de la casa (POST /api/mia/chat)

from tryon import tryon_router  # noqa: E402  (probador virtual, gateado por FAL_KEY/GEMINI_API_KEY)
app.include_router(tryon_router)


@app.on_event("startup")
def _startup() -> None:
    init_db()
    # El sub-app del panel NO recibe eventos de lifespan al estar montado, así
    # que su bootstrap del admin (ADMIN_EMAIL/ADMIN_PASSWORD -> ensure_admin)
    # se ejecuta acá, desde el startup del proceso principal.
    ensure_panel_admin()


# --------------------------------------------------------------------------- #
# Rutas públicas
# --------------------------------------------------------------------------- #
@app.get("/health")
def health():
    return {"ok": True, "service": "web-tienda"}


@app.get("/diag", response_class=HTMLResponse)
def diag():
    """Página de diagnóstico del dispositivo (sobre todo la tablet del local).

    Usa JS a la vieja usanza (var, function, sin ?. ni ??) a propósito: si el
    navegador es viejo y no entiende la sintaxis moderna del panel, ESTA página
    igual corre y nos dice el ancho, el tipo de puntero y el navegador. Y el
    botón prueba que los toques se registran.
    """
    return HTMLResponse("""<!doctype html><html lang="es"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Diagnóstico</title>
<style>
  body{font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;background:#0a0a0a;color:#f5f3ee;
       margin:0;padding:24px;line-height:1.6}
  h1{color:#b99b63;font-size:22px}
  .fila{background:#141414;border:1px solid #2a2a2a;border-radius:10px;padding:14px 16px;margin:10px 0}
  .fila b{color:#b99b63;display:block;font-size:12px;letter-spacing:.1em;text-transform:uppercase}
  .fila span{font-size:16px;word-break:break-all}
  button{margin-top:20px;width:100%;min-height:64px;font-size:18px;font-weight:700;
         background:#b99b63;color:#0a0a0a;border:0;border-radius:12px}
  #res{margin-top:14px;font-size:18px;text-align:center;min-height:26px;color:#4ade80}
</style></head><body>
  <h1>Diagnóstico de la tablet</h1>
  <p>Sacale una captura a esta pantalla y mandámela. Después tocá el botón.</p>
  <div class="fila"><b>Ancho de pantalla (CSS px)</b><span id="w">-</span></div>
  <div class="fila"><b>Alto</b><span id="h">-</span></div>
  <div class="fila"><b>Pantalla táctil (pointer)</b><span id="p">-</span></div>
  <div class="fila"><b>Soporta sintaxis moderna</b><span id="mod">-</span></div>
  <div class="fila"><b>Navegador (user agent)</b><span id="ua">-</span></div>
  <button id="b" type="button">Tocá acá para probar</button>
  <div id="res"></div>
<script>
  function set(id, val){ document.getElementById(id).textContent = val; }
  set('w', window.innerWidth + ' px');
  set('h', window.innerHeight + ' px');
  var coarse = window.matchMedia && window.matchMedia('(pointer: coarse)').matches;
  set('p', coarse ? 'SÍ, es táctil (coarse)' : 'no detecta táctil (fine)');
  set('ua', navigator.userAgent);
  // ¿entiende ?. y ?? (lo que usa el panel)?
  var moderno = 'no';
  try { eval('var o={a:1}; o?.a; (null ?? 1);'); moderno = 'SÍ'; } catch(e){ moderno = 'NO — este es el problema'; }
  set('mod', moderno);
  var n = 0;
  document.getElementById('b').addEventListener('click', function(){
    n = n + 1;
    document.getElementById('res').textContent = 'Toque registrado ✓  (' + n + ')';
  });
</script>
</body></html>""")


@app.get("/", response_class=HTMLResponse)
def home(request: Request, db: Session = Depends(get_db)):
    from sqlalchemy import func
    from core.models import OrderItem, Variant

    # Cada sección se resuelve en DOS pasos: primero se piden solo los IDs
    # (consulta liviana) y al final se traen TODOS los productos juntos con
    # sus fotos y talles en una sola pasada. Antes cada sección hacía su
    # propia consulta + dos más para las relaciones: 9 viajes a São Paulo
    # (~180 ms cada uno) para mostrar 16 productos.
    def _base():
        return db.query(Product.id).filter(Product.published.is_(True))

    # MÁS VENDIDOS — curación manual desde el panel (mas_vendido=True). Si no
    # hay ninguno marcado, cae la lógica automática de siempre: unidades
    # vendidas reales (order_items) y, sin historial, los productos con más
    # talles cargados (proxy de "producto insignia"). Nunca queda vacía.
    ids_mv = [r[0] for r in _base().filter(Product.mas_vendido.is_(True))
              .order_by(Product.id.desc()).limit(8)]
    if not ids_mv:
        ventas = (
            db.query(OrderItem.product_id, func.sum(OrderItem.quantity).label("q"))
            .group_by(OrderItem.product_id).subquery()
        )
        ids_mv = [r[0] for r in _base().join(ventas, ventas.c.product_id == Product.id)
                  .order_by(ventas.c.q.desc()).limit(8)]
        if len(ids_mv) < 4:
            talles = (
                db.query(Variant.product_id, func.count(Variant.id).label("n"))
                .group_by(Variant.product_id).subquery()
            )
            ids_mv = [r[0] for r in _base().join(talles, talles.c.product_id == Product.id)
                      .order_by(talles.c.n.desc(), Product.id.desc()).limit(8)]

    # DESTACADOS — los que Diego marcó desde el panel (destacado=True). Si no
    # hay ninguno marcado, caen los más nuevos: la sección nunca queda vacía.
    ids_dest = [r[0] for r in _base().filter(Product.destacado.is_(True))
                .order_by(Product.id.desc()).limit(8)]
    if not ids_dest:
        ids_dest = [r[0] for r in _base().order_by(Product.id.desc()).limit(8)]

    # ÚLTIMOS EN STOCK — quedan pocas unidades (suma de stock ascendente, > 0).
    stock_sq = (
        db.query(Variant.product_id, func.sum(Variant.stock).label("s"))
        .group_by(Variant.product_id).subquery()
    )
    ids_ult = [r[0] for r in _base().join(stock_sq, stock_sq.c.product_id == Product.id)
               .filter(stock_sq.c.s > 0)
               .order_by(stock_sq.c.s.asc(), Product.id.desc()).limit(8)]

    # Una sola consulta (+2 de relaciones) para las tres secciones juntas, y
    # después se rearma cada lista respetando SU orden.
    necesarios = list({*ids_mv, *ids_dest, *ids_ult})
    porid = {p.id: p for p in _con_relaciones(db)
             .filter(Product.id.in_(necesarios)).all()} if necesarios else {}
    mas_vendidos = [porid[i] for i in ids_mv if i in porid]
    destacados = [porid[i] for i in ids_dest if i in porid]
    ultimos = [porid[i] for i in ids_ult if i in porid]

    # OJO con agregar variables acá: la base está en São Paulo y el servidor en
    # Oregon, así que CADA consulta cuesta ~180 ms de ida y vuelta. Se sacaron
    # `marcas` (nav_categories) y `sections` porque home.html no los usa: la
    # sección de marcas se arma con `home.marcas`, que sale de home_config.
    return templates.TemplateResponse(
        request, "home.html",
        base_context(request, db, destacados=destacados, mas_vendidos=mas_vendidos,
                     ultimos=ultimos,
                     # Todo lo editable de la home (lo carga Diego desde el
                     # panel). Sin nada guardado devuelve los valores de
                     # fábrica, que son los que estaban escritos a mano.
                     home=home_config_cacheada(db),
                     template_class="home"),
    )


@app.get("/p/{pid}", response_class=HTMLResponse)
@app.get("/p/{pid}/", response_class=HTMLResponse)
def product_por_id(pid: int, request: Request, db: Session = Depends(get_db)):
    """Link corto y estable de una pieza: /p/286

    Es el que viaja en los mensajes de WhatsApp. Ventajas sobre el handle:
      - corto y legible, con el MISMO número que ve Diego en el mensaje (#286),
        así identifica la pieza aunque el preview no cargue;
      - sobrevive a un cambio de nombre del producto;
      - una pieza YA VENDIDA (despublicada) sigue mostrando su ficha en vez de
        rebotar al catálogo — si no, el link viejo le mostraba a Diego una
        preview genérica de otra cosa.
    """
    prod = _con_relaciones(db).filter(Product.id == pid).one_or_none()
    if not prod:
        return RedirectResponse("/productos", status_code=302)
    if prod.published:
        return RedirectResponse(f"/productos/{prod.handle}/", status_code=302)
    return _ficha(prod, request, db, vendida=True)


def _ficha(prod: Product, request: Request, db: Session, vendida: bool = False):
    """Render de la ficha (la comparten /productos/{handle} y el link corto /p/{id})."""
    relacionados = (
        _con_relaciones(db)
        .filter(Product.brand == prod.brand, Product.id != prod.id,
                Product.published.is_(True))
        .limit(4)
        .all()
    )
    import os as _os
    tryon_enabled = (not vendida) and (
        bool((_os.environ.get("FAL_KEY") or _os.environ.get("GEMINI_API_KEY") or "").strip())
        or (settings.DEV_MODE and request.query_params.get("tryon_preview") == "1"))
    return templates.TemplateResponse(
        request, "product.html",
        base_context(request, db, product=prod, relacionados=relacionados,
                     tryon_enabled=tryon_enabled, vendida=vendida,
                     template_class="product"),
    )


@app.get("/productos/{handle}/", response_class=HTMLResponse)
@app.get("/productos/{handle}", response_class=HTMLResponse)
def product_detail(handle: str, request: Request, db: Session = Depends(get_db)):
    prod = _con_relaciones(db).filter(Product.handle == handle).one_or_none()
    if not prod or not prod.published:
        # Nunca mostrarle al cliente un JSON crudo: un producto que ya no está
        # (vendido/renombrado/link viejo) lo lleva al catálogo vivo.
        return RedirectResponse("/productos", status_code=302)
    return _ficha(prod, request, db)


@app.get("/productos", response_class=HTMLResponse)
def product_list(request: Request, db: Session = Depends(get_db)):
    productos = (
        _con_relaciones(db).filter(Product.published.is_(True))
        .order_by(Product.id.desc()).all()
    )
    return templates.TemplateResponse(
        request, "category.html",
        base_context(request, db, categoria=None, productos=productos,
                     catalog_title="Catálogo completo", template_class="category"),
    )


@app.get("/categoria/{handle}", response_class=HTMLResponse)
@app.get("/categorias/{handle}", response_class=HTMLResponse)
def category_page(handle: str, request: Request, db: Session = Depends(get_db)):
    cat = db.query(Category).filter(Category.handle == handle).one_or_none()
    if not cat:
        raise HTTPException(404, "Categoría no encontrada")
    # productos de la categoría y de sus subcategorías
    cat_ids = [cat.id] + [c.id for c in cat.subcategories]
    productos = (
        _con_relaciones(db)
        .filter(Product.published.is_(True))
        .filter(Product.categories.any(Category.id.in_(cat_ids)))
        .order_by(Product.id.desc())
        .all()
    )
    return templates.TemplateResponse(
        request, "category.html",
        base_context(request, db, categoria=cat, productos=productos,
                     template_class="category"),
    )


@app.get("/tipo/{nombre}", response_class=HTMLResponse)
def tipo_page(nombre: str, request: Request, db: Session = Depends(get_db)):
    """Listado por TIPO de prenda (Buzos, Remeras…) cruzando TODAS las marcas.

    Cada marca tiene su propia hija "Buzos": acá se juntan todas las hijas
    cuyo nombre matchea el slug y se listan sus productos con la misma
    template de listado que /productos.
    """
    objetivo = _slug_tipo(nombre)
    if not objetivo:
        raise HTTPException(404, "Tipo no encontrado")
    hijas = [c for c in db.query(Category).filter(Category.parent_id.isnot(None))
             if _slug_tipo(c.name) == objetivo]
    if not hijas:
        raise HTTPException(404, "Tipo no encontrado")
    productos = (
        _con_relaciones(db)
        .filter(Product.published.is_(True))
        .filter(Product.categories.any(Category.id.in_([c.id for c in hijas])))
        .order_by(Product.id.desc())
        .all()
    )
    titulo = (hijas[0].name or nombre).strip().title()
    return templates.TemplateResponse(
        request, "category.html",
        base_context(request, db, categoria=None, productos=productos,
                     catalog_title=titulo, template_class="category"),
    )


# El cliente busca como habla: "canguro" por buzo, "chancletas" por ojotas.
# Cada término se expande a sus sinónimos ANTES de ir a la base, así una sola
# palabra encuentra lo que está cargado con el otro nombre.
SINONIMOS_BUSQUEDA = {
    "buzo": ("hoodie", "canguro", "sudadera", "sweater", "sweatshirt"),
    "campera": ("jacket", "chaqueta", "abrigo", "rompeviento", "puffer"),
    "remera": ("camiseta", "tshirt", "t-shirt", "playera", "musculosa"),
    "gorra": ("cap", "visera", "gorro"),
    "ojotas": ("chancletas", "sandalias", "slides", "chinelas"),
    "pantalon": ("pantalón", "jogger", "jogging", "jean", "cargo"),
    "zapatillas": ("sneakers", "tenis", "championes", "calzado"),
    "conjunto": ("set", "equipo", "traje"),
    "riñonera": ("rinonera", "banano", "cangurera"),
}
# El diccionario se usa en los dos sentidos: quien escribe "canguro" también
# tiene que encontrar los buzos.
_SINONIMOS_INVERSO: dict[str, tuple[str, ...]] = {}
for _base, _alias in SINONIMOS_BUSQUEDA.items():
    for _a in _alias:
        _SINONIMOS_INVERSO.setdefault(_a, ())
        _SINONIMOS_INVERSO[_a] = _SINONIMOS_INVERSO[_a] + (_base,)


def _terminos_expandidos(q: str) -> list[str]:
    """Palabras de la consulta + sus sinónimos, en minúscula y sin duplicados."""
    palabras = [p for p in re.split(r"\s+", q.lower().strip()) if len(p) >= 2]
    out: list[str] = []
    for p in palabras[:6]:            # tope: una consulta larga no dispara 50 LIKE
        for t in (p, *SINONIMOS_BUSQUEDA.get(p, ()), *_SINONIMOS_INVERSO.get(p, ())):
            if t not in out:
                out.append(t)
    return out


@app.get("/buscar", response_class=HTMLResponse)
def search(request: Request, q: str = "", db: Session = Depends(get_db)):
    """Buscador de la tienda.

    SIN `q` NO es un error: es la pantalla del buscador (la lupa del mobile
    entra por acá). Antes caía en category.html y mostraba "No encontramos
    productos" sin un campo donde escribir — Diego no podía buscar nada.
    """
    productos = []
    terminos = _terminos_expandidos(q) if q.strip() else []
    if terminos:
        from sqlalchemy import func, or_
        cond = []
        for t in terminos:
            like = f"%{t}%"
            cond += [func.lower(Product.name).like(like),
                     func.lower(Product.brand).like(like),
                     func.lower(Product.description).like(like)]
        # _con_relaciones (no db.query pelado): las tarjetas leen la foto, el
        # precio y el stock de cada resultado, y sin precargar eso SQLAlchemy
        # pedía dos consultas MÁS por producto. Con la base en São Paulo
        # (~180 ms por viaje) una búsqueda de 51 resultados tardaba 23 s.
        productos = (
            _con_relaciones(db)
            .filter(Product.published.is_(True), Product.a_pedido.is_(False))
            .filter(or_(*cond))
            .order_by(Product.id.desc())
            .limit(120)
            .all()
        )
    return templates.TemplateResponse(
        request, "search.html",
        base_context(request, db, categoria=None, productos=productos,
                     search_query=q, template_class="search"),
    )


@app.get("/carrito", response_class=HTMLResponse)
def cart_page(request: Request, db: Session = Depends(get_db),
              user: User | None = Depends(current_user),
              mi_cart: str | None = Cookie(default=None)):
    cart = resolve_cart(db, None, user, mi_cart, create=False)
    return templates.TemplateResponse(
        request, "cart.html",
        base_context(request, db, cart=cart_summary(cart), template_class="cart"),
    )


@app.get("/checkout", response_class=HTMLResponse)
def checkout_page(request: Request, db: Session = Depends(get_db),
                  user: User | None = Depends(current_user),
                  mi_cart: str | None = Cookie(default=None)):
    # Misma resolución que usa create-intent: la pantalla tiene que mostrar
    # exactamente el carrito que se va a cobrar.
    cart = resolve_cart(db, None, user, mi_cart, create=False)
    summary = cart_summary(cart)
    return templates.TemplateResponse(
        request, "checkout.html",
        base_context(request, db, cart=summary, account=user,
                     stripe_enabled=bool(settings.STRIPE_PUBLISHABLE_KEY),
                     addresses=(user.addresses if user else []),
                     template_class="checkout"),
    )


@app.get("/pagar/{number}", response_class=HTMLResponse)
def pay_order_page(number: int, request: Request, t: str = "",
                   payment_intent: str = "", db: Session = Depends(get_db)):
    """Página de pago de un pedido puntual — la que abre el QR del mostrador.

    Se autoriza con el token opaco de la orden, igual que la confirmación:
    el número solo no alcanza. Siempre 404 (nunca 403) para no revelar qué
    números existen.
    """
    order = db.query(Order).filter(Order.number == number).one_or_none()
    if not order or not order.public_token or not t:
        raise HTTPException(404, "Pedido no encontrado")
    if not secrets.compare_digest(t, order.public_token):
        raise HTTPException(404, "Pedido no encontrado")

    # Al volver de Stripe se acredita en el momento, sin esperar al webhook.
    if order.payment_status != "paid" and payment_intent:
        if confirmar_pago_desde_stripe(db, order, payment_intent):
            db.refresh(order)

    return templates.TemplateResponse(
        request, "pagar_pedido.html",
        base_context(request, db, order=order, token=t,
                     stripe_enabled=bool(settings.STRIPE_PUBLISHABLE_KEY),
                     template_class="pay"),
    )


@app.get("/pedido/{number}", response_class=HTMLResponse)
def order_confirmation(number: int, request: Request, t: str = "",
                       payment_intent: str = "",
                       db: Session = Depends(get_db),
                       user: User | None = Depends(current_user)):
    """Confirmación de pedido.

    Los números son secuenciales, así que sin control de acceso se podía
    recorrer /pedido/1000..N y llevarse el registro completo de ventas. Se
    exige ser el dueño (sesión) o presentar el token opaco de la orden.
    Siempre 404 —nunca 403— para no confirmar qué números existen.
    """
    order = db.query(Order).filter(Order.number == number).one_or_none()
    if not order:
        raise HTTPException(404, "Pedido no encontrado")

    is_owner = bool(user and order.user_id and order.user_id == user.id)
    has_token = bool(t and order.public_token
                     and secrets.compare_digest(t, order.public_token))
    if not (is_owner or has_token):
        raise HTTPException(404, "Pedido no encontrado")

    # Red de seguridad del webhook: si el pedido sigue pendiente y el cliente
    # vuelve del pago, le preguntamos a Stripe cómo terminó en vez de esperar
    # un aviso que puede no llegar nunca. El parámetro de la URL es solo la
    # pista; la verdad la da la API de Stripe (ver confirmar_pago_desde_stripe).
    if order.payment_status != "paid" and payment_intent:
        if confirmar_pago_desde_stripe(db, order, payment_intent):
            db.refresh(order)

    return templates.TemplateResponse(
        request, "order_confirmation.html",
        base_context(request, db, order=order, template_class="order"),
    )


@app.get("/cuenta/ingresar", response_class=HTMLResponse)
def account_login_page(request: Request, db: Session = Depends(get_db),
                       user: User | None = Depends(current_user)):
    if user:
        return RedirectResponse("/cuenta", status_code=302)
    return templates.TemplateResponse(
        request, "account_login.html",
        base_context(request, db, google_enabled=bool(settings.GOOGLE_CLIENT_ID),
                     template_class="account-login"),
    )


@app.get("/cuenta/reset", response_class=HTMLResponse)
def account_reset_page(request: Request, token: str = "", db: Session = Depends(get_db)):
    return templates.TemplateResponse(
        request, "account_reset.html",
        base_context(request, db, reset_token=token, template_class="account-reset"),
    )


@app.get("/cuenta", response_class=HTMLResponse)
def account_page(request: Request, db: Session = Depends(get_db),
                 user: User | None = Depends(current_user)):
    if not user:
        return RedirectResponse("/cuenta/ingresar", status_code=302)
    # Las cuentas viejas quedaron con direcciones en blanco (la API las
    # aceptaba). No se puede despachar a ninguna: se limpian al entrar, asi el
    # cliente ve solo las suyas de verdad.
    from auth_store import limpiar_direcciones_vacias
    limpiar_direcciones_vacias(db, user)
    orders = (
        db.query(Order).filter(Order.user_id == user.id)
        .order_by(Order.created_at.desc()).all()
    )
    return templates.TemplateResponse(
        request, "account.html",
        base_context(request, db, account=user, orders=orders,
                     addresses=user.addresses, template_class="account"),
    )


@app.get("/robots.txt", response_class=PlainTextResponse)
def robots(request: Request):
    return (
        "User-agent: *\n"
        "Allow: /\n"
        "Disallow: /cuenta\n"
        "Disallow: /carrito\n"
        "Disallow: /checkout\n"
        "Disallow: /api/\n"
        f"Sitemap: {_base_publica(request)}/sitemap.xml\n"
    )


def _base_publica(request: Request) -> str:
    """Dominio real desde el que se está sirviendo la tienda.

    NO usar settings.STORE_BASE_URL: en producción quedó apuntando al host
    viejo de Render, y el sitemap publicaba las 261 fichas como
    miami-import-landing.onrender.com — todo el SEO se lo llevaba el dominio
    provisorio en vez de miamiimport.com.ar.
    """
    return f"{request.url.scheme}://{request.url.netloc}".rstrip("/")


@app.get("/sitemap.xml")
def sitemap(request: Request, db: Session = Depends(get_db)):
    base = _base_publica(request)
    urls = [f"{base}/", f"{base}/productos"]
    for c in db.query(Category).all():
        urls.append(f"{base}/categorias/{c.handle}")
    for p in db.query(Product).filter(Product.published.is_(True)).all():
        urls.append(f"{base}/productos/{p.handle}/")
    body = "".join(f"<url><loc>{u}</loc></url>" for u in urls)
    xml = ('<?xml version="1.0" encoding="UTF-8"?>'
           '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
           f"{body}</urlset>")
    return Response(content=xml, media_type="application/xml")


app.mount("/static", StaticFiles(directory=HERE / "static"), name="static")

# Panel administrativo montado DESPUÉS de las rutas de la tienda. Mismo proceso,
# mismo core, misma base de datos. La tienda queda en "/", el panel en "/panel".
app.mount("/panel", panel_app)


if __name__ == "__main__":
    print("\n 🛍  MIAMI_IMPORT — Tienda pública")
    print(f"    DB: {settings.DATABASE_URL}")
    print(" Abriendo en: http://localhost:8001\n")
    uvicorn.run("app:app", host="0.0.0.0", port=8001, reload=False, server_header=False)
