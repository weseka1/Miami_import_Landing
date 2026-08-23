"""
Autenticación de clientes de la tienda.

- Registro / login con email + contraseña (bcrypt), sesión en cookie HttpOnly.
- Google OAuth (flujo de código de autorización).
- Recuperación de contraseña por token (link de vida corta, enviado por email).
- Al loguearse fusiona el carrito anónimo con el del usuario.
"""
from __future__ import annotations

import logging
import secrets
from datetime import datetime, timedelta, timezone

import requests
from email_validator import EmailNotValidError, validate_email
from fastapi import APIRouter, Cookie, Depends, HTTPException, Request, Response
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session

from cart import COOKIE_NAME as CART_COOKIE
from cart import merge_anonymous_cart_into_user
from core.config import settings
from core.db import get_db
from core.models import Address, AuditLog, Order, PasswordReset, User
from core.security import (
    generate_opaque_token, hash_password, hash_token,
    password_needs_rehash, verify_password,
)
from core.web_security import clear_failures, is_locked, record_failure
from deps import SESSION_COOKIE, current_user, require_user, set_session

log = logging.getLogger("auth_store")

account_router = APIRouter(prefix="/api/account", tags=["account"])
oauth_router = APIRouter(tags=["oauth"])

# La sesión vive en `deps` (la necesita también `cart`, que se importa acá).
# Se re-exportan para no romper los imports existentes.
_set_session = set_session
SESSION_MINUTES = settings.SESSION_MINUTES


# --------------------------------------------------------------------------- #
# Registro / login / logout
# --------------------------------------------------------------------------- #
@account_router.post("/register")
def register(body: dict, response: Response, request: Request,
             db: Session = Depends(get_db), mi_cart: str | None = Cookie(default=None)):
    try:
        email = validate_email(body.get("email", ""), check_deliverability=False).normalized.lower()
    except EmailNotValidError:
        raise HTTPException(400, "Email inválido")
    password = body.get("password") or ""
    if len(password) < 8:
        raise HTTPException(400, "La contraseña debe tener al menos 8 caracteres")

    # No revelar si el email ya está registrado: un 409 distinguible convierte
    # este endpoint en un oráculo para depurar listas de emails filtradas y
    # dirigir phishing. Se responde igual que en el alta exitosa.
    if db.query(User).filter(User.email == email).first():
        # Pagar el mismo costo de Argon2 que el alta real: si no, la rama del
        # email existente responde en ~2 ms y la nueva en ~100 ms, y esa
        # diferencia de tiempo reintroduce el oráculo de enumeración que la
        # respuesta uniforme buscaba cerrar.
        hash_password(password)
        db.add(AuditLog(action="register_existing_email", entity="user", entity_id=email,
                        ip=request.client.host if request.client else None))
        db.commit()
        return {"ok": True, "email": email, "name": None}

    user = User(email=email, password_hash=hash_password(password),
                full_name=(body.get("full_name") or "").strip()[:255] or None,
                phone=(body.get("phone") or "").strip()[:50] or None)
    db.add(user)
    db.commit()
    db.refresh(user)
    merge_anonymous_cart_into_user(db, user.id, mi_cart, response)
    _set_session(response, user)
    db.add(AuditLog(user_id=user.id, action="register", entity="user", entity_id=str(user.id),
                    ip=request.client.host if request.client else None))
    db.commit()
    return {"ok": True, "email": user.email, "name": user.full_name}


@account_router.post("/login")
def login(body: dict, response: Response, request: Request,
          db: Session = Depends(get_db), mi_cart: str | None = Cookie(default=None)):
    email = (body.get("email") or "").strip().lower()
    password = body.get("password") or ""
    ip = request.client.host if request.client else "?"
    lock_key = f"cust:{email}:{ip}"
    rem = is_locked(lock_key)
    if rem:
        raise HTTPException(429, f"Demasiados intentos. Reintentá en {rem // 60 + 1} min.")
    user = db.query(User).filter(User.email == email).one_or_none()
    if not user or not verify_password(password, user.password_hash):
        record_failure(lock_key)
        db.add(AuditLog(action="login_failed", entity="user", entity_id=email, ip=ip))
        db.commit()
        raise HTTPException(401, "Email o contraseña incorrectos")
    if not user.is_active:
        raise HTTPException(403, "Cuenta inactiva")
    clear_failures(lock_key)
    if password_needs_rehash(user.password_hash):
        user.password_hash = hash_password(password)
        db.commit()
    merge_anonymous_cart_into_user(db, user.id, mi_cart, response)
    _set_session(response, user)
    db.add(AuditLog(user_id=user.id, action="login", entity="user", entity_id=str(user.id),
                    ip=request.client.host if request.client else None))
    db.commit()
    return {"ok": True, "email": user.email, "name": user.full_name}


@account_router.post("/logout")
def logout(response: Response):
    response.delete_cookie(SESSION_COOKIE, path="/", domain=settings.COOKIE_DOMAIN)
    return {"ok": True}


@account_router.get("/me")
def me(user: User = Depends(require_user)):
    return {"id": user.id, "email": user.email, "name": user.full_name,
            "phone": user.phone, "google": bool(user.google_id)}


@account_router.put("/profile")
def update_profile(body: dict, user: User = Depends(require_user), db: Session = Depends(get_db)):
    if "full_name" in body:
        user.full_name = (body["full_name"] or "").strip() or None
    if "phone" in body:
        user.phone = (body["phone"] or "").strip() or None
    db.commit()
    return {"ok": True}


_ADDR_FIELDS = ("label", "full_name", "phone", "street", "number", "floor",
                "city", "province", "zipcode", "country")


def _addr_json(a: Address) -> dict:
    d = {f: getattr(a, f) for f in _ADDR_FIELDS}
    d.update({"id": a.id, "is_default": a.is_default})
    return d


@account_router.get("/addresses")
def list_addresses(user: User = Depends(require_user), db: Session = Depends(get_db)):
    return [_addr_json(a) for a in user.addresses]


# Sin estos campos la direccion no sirve para despachar nada. Aceptar una
# direccion vacia llenaba la cuenta de cajas en blanco (Diego junto 9).
_ADDR_MINIMOS = ("street", "number", "city", "province", "zipcode")


def _validar_direccion(body: dict) -> None:
    faltan = [f for f in _ADDR_MINIMOS if not (body.get(f) or "").strip()]
    if faltan:
        nombres = {"street": "calle", "number": "número", "city": "ciudad",
                   "province": "provincia", "zipcode": "código postal"}
        raise HTTPException(400, "Faltan datos de la dirección: "
                                 + ", ".join(nombres[f] for f in faltan))


@account_router.post("/addresses")
def create_address(body: dict, user: User = Depends(require_user), db: Session = Depends(get_db)):
    _validar_direccion(body)
    a = Address(user_id=user.id)
    for f in _ADDR_FIELDS:
        if f in body:
            setattr(a, f, (body[f] or "").strip() or None)
    a.country = a.country or "AR"
    if body.get("is_default") or not user.addresses:
        for other in user.addresses:
            other.is_default = False
        a.is_default = True
    db.add(a)
    db.commit()
    db.refresh(a)
    return _addr_json(a)


@account_router.put("/addresses/{aid}")
def update_address(aid: int, body: dict, user: User = Depends(require_user), db: Session = Depends(get_db)):
    _validar_direccion(body)
    a = db.get(Address, aid)
    if not a or a.user_id != user.id:
        raise HTTPException(404, "Dirección no encontrada")
    for f in _ADDR_FIELDS:
        if f in body:
            setattr(a, f, (body[f] or "").strip() or None)
    if body.get("is_default"):
        for other in user.addresses:
            other.is_default = (other.id == aid)
    db.commit()
    return _addr_json(a)


@account_router.delete("/addresses/{aid}")
def delete_address(aid: int, user: User = Depends(require_user), db: Session = Depends(get_db)):
    a = db.get(Address, aid)
    if not a or a.user_id != user.id:
        raise HTTPException(404, "Dirección no encontrada")
    db.delete(a)
    db.commit()
    return {"ok": True}


# --------------------------------------------------------------------------- #
# Recuperación de contraseña
# --------------------------------------------------------------------------- #
@account_router.post("/password/forgot")
def password_forgot(body: dict, db: Session = Depends(get_db)):
    email = (body.get("email") or "").strip().lower()
    user = db.query(User).filter(User.email == email).one_or_none()
    # Respondemos siempre OK (no revelar si el email existe).
    if not user:
        return {"ok": True}
    # Un reset nuevo invalida los anteriores: si no, cada pedido deja otro link
    # vivo y basta con que se filtre uno solo, de cualquier momento.
    (db.query(PasswordReset)
       .filter(PasswordReset.user_id == user.id, PasswordReset.used.is_(False))
       .update({"used": True}, synchronize_session=False))

    raw = generate_opaque_token()
    # Ventana corta y propia (antes reusaba refresh_expiry() = 30 DÍAS). Un link
    # de recuperación que sobrevive un mes en la casilla es una llave olvidada.
    expires = datetime.now(timezone.utc) + timedelta(minutes=settings.RESET_TOKEN_MINUTES)
    db.add(PasswordReset(user_id=user.id, token_hash=hash_token(raw), expires_at=expires))
    db.commit()
    link = f"{settings.STORE_BASE_URL}/cuenta/reset?token={raw}"
    # En producción esto se envía por email (SMTP). En dev se muestra por consola.
    # NUNCA se devuelve en el body: si DEV_MODE quedara mal seteado en un
    # deploy, cualquiera pediría el reset del admin y recibiría el token.
    log.info("[password-reset] link para %s: %s", email, link)
    return {"ok": True}


@account_router.post("/password/reset")
def password_reset(body: dict, db: Session = Depends(get_db)):
    raw = body.get("token") or ""
    password = body.get("password") or ""
    if len(password) < 8:
        raise HTTPException(400, "La contraseña debe tener al menos 8 caracteres")
    pr = db.query(PasswordReset).filter(PasswordReset.token_hash == hash_token(raw)).one_or_none()
    if not pr or pr.used or pr.expires_at < datetime.now(timezone.utc):
        raise HTTPException(400, "Token inválido o expirado")
    user = db.get(User, pr.user_id)
    if not user:
        raise HTTPException(400, "Token inválido o expirado")
    user.password_hash = hash_password(password)
    # Cerrar TODAS las sesiones vivas: si alguien había robado la cuenta, sin
    # esto conserva su cookie válida hasta que expire, aunque la víctima ya
    # haya cambiado la contraseña.
    user.token_version = (user.token_version or 0) + 1
    pr.used = True
    db.add(AuditLog(user_id=user.id, action="password_reset", entity="user",
                    entity_id=str(user.id)))
    db.commit()
    return {"ok": True}


# --------------------------------------------------------------------------- #
# Google OAuth
# --------------------------------------------------------------------------- #
GOOGLE_AUTH = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_TOKEN = "https://oauth2.googleapis.com/token"
GOOGLE_USERINFO = "https://openidconnect.googleapis.com/v1/userinfo"


def _google_redirect_uri() -> str:
    return f"{settings.STORE_BASE_URL}/auth/google/callback"


@oauth_router.get("/auth/google/login")
def google_login():
    if not settings.GOOGLE_CLIENT_ID:
        raise HTTPException(503, "Google OAuth no está configurado")
    state = secrets.token_urlsafe(16)
    from urllib.parse import urlencode
    params = {
        "client_id": settings.GOOGLE_CLIENT_ID,
        "redirect_uri": _google_redirect_uri(),
        "response_type": "code",
        "scope": "openid email profile",
        "state": state,
        "access_type": "online",
        "prompt": "select_account",
    }
    resp = RedirectResponse(f"{GOOGLE_AUTH}?{urlencode(params)}")
    resp.set_cookie("g_state", state, httponly=True, samesite="lax",
                    secure=settings.COOKIE_SECURE, max_age=600, path="/")
    return resp


@oauth_router.get("/auth/google/callback")
def google_callback(request: Request, code: str = "", state: str = "",
                    db: Session = Depends(get_db),
                    g_state: str | None = Cookie(default=None),
                    mi_cart: str | None = Cookie(default=None)):
    if not settings.GOOGLE_CLIENT_ID or not settings.GOOGLE_CLIENT_SECRET:
        raise HTTPException(503, "Google OAuth no está configurado")
    if not code or not state or state != g_state:
        raise HTTPException(400, "Estado OAuth inválido")
    tok = requests.post(GOOGLE_TOKEN, data={
        "code": code,
        "client_id": settings.GOOGLE_CLIENT_ID,
        "client_secret": settings.GOOGLE_CLIENT_SECRET,
        "redirect_uri": _google_redirect_uri(),
        "grant_type": "authorization_code",
    }, timeout=15)
    if not tok.ok:
        raise HTTPException(502, "No se pudo validar con Google")
    access = tok.json().get("access_token")
    info = requests.get(GOOGLE_USERINFO, headers={"Authorization": f"Bearer {access}"}, timeout=15).json()
    google_id = info.get("sub")
    email = (info.get("email") or "").lower()
    if not google_id or not email:
        raise HTTPException(502, "Google no devolvió email")

    email_verified = bool(info.get("email_verified"))

    user = db.query(User).filter(User.google_id == google_id).one_or_none()
    if not user:
        user = db.query(User).filter(User.email == email).one_or_none()
        if user:
            # Vincular una cuenta existente por email SOLO si Google confirma
            # que verificó ese email. Sin este chequeo, quien controle un
            # tenant de Workspace puede declarar el email de una víctima y
            # quedarse con su cuenta sin saber la contraseña.
            if not email_verified:
                raise HTTPException(403, "Google no verificó ese email")
            user.google_id = google_id
            user.email_verified = True
        else:
            if not email_verified:
                raise HTTPException(403, "Google no verificó ese email")
            user = User(email=email, google_id=google_id,
                        full_name=(info.get("name") or "")[:255] or None,
                        email_verified=True)
            db.add(user)
    if not user.is_active:
        raise HTTPException(403, "Cuenta inactiva")
    db.commit()
    db.refresh(user)
    merge_anonymous_cart_into_user(db, user.id, mi_cart)

    resp = RedirectResponse("/cuenta", status_code=302)
    _set_session(resp, user)
    resp.delete_cookie("g_state", path="/")
    db.add(AuditLog(user_id=user.id, action="login_google", entity="user", entity_id=str(user.id),
                    ip=request.client.host if request.client else None))
    db.commit()
    return resp
