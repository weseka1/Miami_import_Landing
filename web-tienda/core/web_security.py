"""
Blindaje web compartido: cabeceras de seguridad + rate limiting básico.

Pensado para producción pero sin dependencias externas (Redis, slowapi):
el rate limiter es en memoria por proceso — suficiente para 1 instancia en
Render. Si se escala a varias instancias, migrar a Redis.
"""
from __future__ import annotations

import secrets
import time
from collections import defaultdict, deque

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from .config import settings

# --------------------------------------------------------------------------- #
# Bloqueo de cuenta tras intentos fallidos (anti brute-force / credential stuffing)
# En memoria por proceso; para multi-instancia migrar a Redis.
# --------------------------------------------------------------------------- #
_LOCKOUT_THRESHOLD = 5          # intentos fallidos
_LOCKOUT_WINDOW = 15 * 60       # se cuentan dentro de 15 min
_LOCKOUT_TIME = 15 * 60         # bloqueo de 15 min
_failed: dict[str, deque] = defaultdict(deque)
_locked_until: dict[str, float] = {}


def is_locked(key: str) -> int:
    """Devuelve segundos restantes de bloqueo, o 0 si no está bloqueado."""
    until = _locked_until.get(key, 0)
    rem = int(until - time.time())
    return rem if rem > 0 else 0


def record_failure(key: str) -> None:
    now = time.time()
    q = _failed[key]
    q.append(now)
    while q and now - q[0] > _LOCKOUT_WINDOW:
        q.popleft()
    if len(q) >= _LOCKOUT_THRESHOLD:
        _locked_until[key] = now + _LOCKOUT_TIME
        q.clear()


# Contador por CUENTA (sin IP). No bloquea: solo frena. Un bloqueo duro por
# cuenta deja que cualquiera que sepa el email del admin lo eche del panel para
# siempre, fallando el login 5 veces cada 15 minutos.
_SOFT_THRESHOLD = 5
_SOFT_MAX_DELAY = 8.0     # segundos
_soft_failures: dict[str, deque] = defaultdict(deque)


def record_soft_failure(key: str) -> None:
    now = time.time()
    q = _soft_failures[key]
    q.append(now)
    while q and now - q[0] > _LOCKOUT_WINDOW:
        q.popleft()


def soft_delay(key: str) -> float:
    """Segundos a esperar antes de procesar el intento (backoff exponencial).

    Hace inviable la fuerza bruta distribuida sin dejar a nadie afuera: el
    dueño con la contraseña correcta entra igual, solo espera unos segundos.
    """
    q = _soft_failures.get(key)
    if not q:
        return 0.0
    now = time.time()
    while q and now - q[0] > _LOCKOUT_WINDOW:
        q.popleft()
    extra = len(q) - _SOFT_THRESHOLD
    if extra < 0:
        return 0.0
    return min(_SOFT_MAX_DELAY, 0.5 * (2 ** min(extra, 5)))


def clear_failures(key: str) -> None:
    _failed.pop(key, None)
    _locked_until.pop(key, None)
    _soft_failures.pop(key, None)

# Hosts permitidos por la tienda (CDNs de animación, Stripe, fuentes, imágenes TN, bot).
#
# script-src NO lleva 'unsafe-inline': con esa directiva la CSP deja de servir
# como defensa contra XSS (un `<img onerror=...>` inyectado ejecuta igual).
# En su lugar cada respuesta HTML trae un nonce y los <script> inline lo citan.
_DEFAULT_CSP = {
    "default-src": "'self'",
    "script-src": "'self' https://cdn.jsdelivr.net https://js.stripe.com https://ajax.googleapis.com",
    # style-src sí lo conserva: los estilos inline del theme son numerosos y el
    # riesgo de una inyección de CSS es órdenes de magnitud menor.
    "style-src": "'self' 'unsafe-inline' https://fonts.googleapis.com",
    "img-src": "'self' data: https:",
    "font-src": "'self' https://fonts.gstatic.com data:",
    "connect-src": "'self' https://api.stripe.com",
    "frame-src": "'self' https://js.stripe.com https://hooks.stripe.com",
    "frame-ancestors": "'self'",
    "base-uri": "'self'",
    "form-action": "'self'",
    "object-src": "'none'",
}


def _csp_string(extra: dict | None = None, nonce: str | None = None) -> str:
    policy = dict(_DEFAULT_CSP)
    if extra:
        for k, v in extra.items():
            policy[k] = f"{policy.get(k, '')} {v}".strip()
    if nonce:
        policy["script-src"] = f"{policy['script-src']} 'nonce-{nonce}'"
    return "; ".join(f"{k} {v}" for k, v in policy.items())


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, csp_extra: dict | None = None, use_nonce: bool = False):
        super().__init__(app)
        self._csp_extra = csp_extra
        self._use_nonce = use_nonce
        self._static_csp = None if use_nonce else _csp_string(csp_extra)

    async def dispatch(self, request: Request, call_next):
        nonce = None
        if self._use_nonce:
            # Un nonce por respuesta; las plantillas lo leen de request.state.
            nonce = secrets.token_urlsafe(16)
            request.state.csp_nonce = nonce
        resp: Response = await call_next(request)
        # Variable local, NO atributo de instancia: el middleware es único y
        # compartido por todas las requests concurrentes.
        csp = self._static_csp or _csp_string(self._csp_extra, nonce)
        resp.headers.setdefault("X-Content-Type-Options", "nosniff")
        # Coherente con frame-ancestors de la CSP (los navegadores modernos
        # priorizan la CSP; tener DENY acá y 'self' allá era contradictorio).
        resp.headers.setdefault("X-Frame-Options", "SAMEORIGIN")
        resp.headers.setdefault("Referrer-Policy", "strict-origin-when-cross-origin")
        resp.headers.setdefault("Permissions-Policy",
                                "geolocation=(), microphone=(), camera=(), payment=(self)")
        resp.headers.setdefault("Content-Security-Policy", csp)
        resp.headers.setdefault("Cross-Origin-Opener-Policy", "same-origin")
        resp.headers.setdefault("Cross-Origin-Resource-Policy", "same-site")
        # No filtrar la tecnología del stack.
        for h in ("Server", "X-Powered-By"):
            if h in resp.headers:
                del resp.headers[h]
        # Nunca cachear respuestas sensibles (API, auth, cuenta, checkout).
        p = request.url.path
        if p.startswith(("/api/", "/auth/", "/cuenta", "/checkout")):
            resp.headers["Cache-Control"] = "no-store"
        elif "text/html" in resp.headers.get("content-type", ""):
            # Las páginas de catálogo muestran stock y precios que cambian desde
            # el panel. Sin cabecera, el navegador y el proxy aplican caché
            # heurística y siguen mostrando la versión vieja: se cambiaba el
            # stock y la tienda no se enteraba. `no-cache` obliga a revalidar
            # en cada visita (permite 304, así que no encarece la carga).
            resp.headers.setdefault("Cache-Control", "no-cache, must-revalidate")
        # HSTS depende solo de no estar en desarrollo: atarlo también a
        # COOKIE_SECURE hacía que un error de config quitara las dos defensas
        # a la vez (cookies sin Secure Y sin forzar HTTPS).
        if not settings.DEV_MODE:
            resp.headers.setdefault(
                "Strict-Transport-Security",
                "max-age=63072000; includeSubDomains; preload")
        return resp


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Limita ráfagas en endpoints sensibles (login, registro, checkout, etc.)."""

    def __init__(self, app, limit: int = 30, window: int = 60,
                 sensitive_prefixes: tuple[str, ...] = ()):
        super().__init__(app)
        self.limit = limit
        self.window = window
        self.sensitive = sensitive_prefixes
        self._hits: dict[str, deque] = defaultdict(deque)

    async def dispatch(self, request: Request, call_next):
        path = request.url.path
        if request.method == "POST" and any(path.startswith(p) for p in self.sensitive):
            ip = request.client.host if request.client else "?"
            key = f"{ip}:{path}"
            now = time.time()
            q = self._hits[key]
            while q and now - q[0] > self.window:
                q.popleft()
            if len(q) >= self.limit:
                return JSONResponse({"detail": "Demasiados intentos. Probá en un minuto."},
                                    status_code=429)
            q.append(now)
        return await call_next(request)


def install_security(app, *, csp_extra: dict | None = None,
                     rate_limit: int = 30, rate_window: int = 60,
                     use_nonce: bool = False,
                     sensitive_prefixes: tuple[str, ...] = ()) -> None:
    app.add_middleware(SecurityHeadersMiddleware, csp_extra=csp_extra,
                       use_nonce=use_nonce)
    if sensitive_prefixes:
        app.add_middleware(RateLimitMiddleware, limit=rate_limit, window=rate_window,
                           sensitive_prefixes=sensitive_prefixes)
