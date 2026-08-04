"""
Autenticación del panel administrativo (JWT en cookie HttpOnly).

- Login con email + contraseña contra la tabla users (is_admin=True).
- El token va en cookie HttpOnly/SameSite; nunca expuesto al JS.
- `ensure_admin()` crea el admin inicial al arrancar (ADMIN_EMAIL/ADMIN_PASSWORD).
- `get_current_admin` protege los endpoints del panel.
"""
from __future__ import annotations

import time

import pyotp
from fastapi import APIRouter, Cookie, Depends, HTTPException, Request, Response
from sqlalchemy.orm import Session

from core.config import settings
from core.db import SessionLocal, get_db
from core.models import AuditLog, User
from core.security import (
    create_access_token, decode_token, hash_password, password_needs_rehash,
    verify_password,
)
from core.web_security import (
    clear_failures, is_locked, record_failure, record_soft_failure, soft_delay,
)

COOKIE_NAME = "mi_admin"
ADMIN_TOKEN_MINUTES = 720  # 12 h de sesión de admin

auth_router = APIRouter(prefix="/api/auth", tags=["auth"])


# --------------------------------------------------------------------------- #
# Dependencia: admin actual
# --------------------------------------------------------------------------- #
def _admin_from_token(db: Session, token: str | None) -> User | None:
    """Resuelve el admin de un token, con TODAS las verificaciones.

    El claim `adm` es obligatorio: sin ese chequeo, un token de cliente de la
    tienda (que también es `type=access`) servía como sesión de admin, y como
    la tienda no tiene MFA, eso saltaba el TOTP por completo.
    """
    payload = decode_token(token) if token else None
    if not payload or payload.get("type") != "access":
        return None
    if payload.get("adm") is not True:
        return None  # token de la tienda, no del panel
    if not payload.get("sub"):
        return None
    try:
        user = db.get(User, int(payload["sub"]))
    except (TypeError, ValueError):
        return None
    if not user or not user.is_admin or not user.is_active:
        return None
    if int(payload.get("tv", -1)) != int(user.token_version or 0):
        return None  # sesión invalidada
    # MFA obligatorio para el panel: un admin sin TOTP configurado solo puede
    # llegar a los endpoints de setup (ver _MFA_SETUP_PATHS en la dependencia).
    return user


def get_current_admin(
    request: Request,
    db: Session = Depends(get_db),
    mi_admin: str | None = Cookie(default=None),
) -> User:
    token = mi_admin
    if not token:
        # fallback: Authorization: Bearer xxx (útil para tests/curl)
        auth = request.headers.get("Authorization", "")
        if auth.lower().startswith("bearer "):
            token = auth[7:]
    user = _admin_from_token(db, token)
    if not user:
        raise HTTPException(401, "No autenticado")
    # Con REQUIRE_MFA activo, una sesión sin segundo factor solo sirve para
    # configurarlo. Con REQUIRE_MFA apagado se entra solo con contraseña (pero
    # a quien YA tenga TOTP se le sigue pidiendo en el login).
    if (settings.REQUIRE_MFA and not user.totp_enabled
            and request.url.path not in _MFA_SETUP_PATHS):
        raise HTTPException(403, "Configurá el segundo factor (MFA) para continuar")
    return user


# Rutas alcanzables por un admin que todavía no habilitó MFA.
_MFA_SETUP_PATHS = {
    "/api/auth/me", "/api/auth/logout",
    "/api/auth/totp/setup", "/api/auth/totp/enable",
}


def is_admin_request(request: Request) -> bool:
    """Versión sin dependencias de FastAPI, para las rutas HTML del panel."""
    db = SessionLocal()
    try:
        return _admin_from_token(db, request.cookies.get(COOKIE_NAME)) is not None
    finally:
        db.close()


# --------------------------------------------------------------------------- #
# Endpoints
# --------------------------------------------------------------------------- #
@auth_router.post("/login")
def login(body: dict, response: Response, request: Request, db: Session = Depends(get_db)):
    email = (body.get("email") or "").strip().lower()
    password = body.get("password") or ""
    ip = request.client.host if request.client else "?"
    # Dos contadores: por IP+cuenta y por CUENTA sola. Solo con el primero,
    # rotando proxies cada IP arranca en cero y la cuenta nunca se bloquea.
    lock_key = f"admin:{email}:{ip}"
    account_key = f"admin-account:{email}"

    rem = is_locked(lock_key)
    if rem:
        raise HTTPException(429, f"Demasiados intentos. Reintentá en {rem // 60 + 1} min.")
    # Por cuenta se aplica un RETARDO, no un bloqueo: bloquear por email dejaba
    # que cualquiera que lo conozca eche al dueño del panel indefinidamente.
    espera = soft_delay(account_key)
    if espera:
        time.sleep(espera)

    user = db.query(User).filter(User.email == email).one_or_none()
    if not user or not user.is_admin or not verify_password(password, user.password_hash):
        record_failure(lock_key)
        record_soft_failure(account_key)
        db.add(AuditLog(action="admin_login_failed", entity="user", entity_id=email, ip=ip))
        db.commit()
        raise HTTPException(401, "Email o contraseña incorrectos")
    if not user.is_active:
        raise HTTPException(403, "Usuario inactivo")

    # MFA/TOTP obligatorio si está habilitado.
    if user.totp_enabled:
        code = (body.get("totp_code") or "").strip()
        if not code:
            return {"ok": False, "mfa_required": True}
        if not pyotp.TOTP(user.totp_secret).verify(code, valid_window=1):
            record_failure(lock_key)
            record_soft_failure(account_key)  # el MFA también cuenta por cuenta
            db.add(AuditLog(user_id=user.id, action="admin_mfa_failed", entity="user",
                            entity_id=str(user.id), ip=ip))
            db.commit()
            raise HTTPException(401, "Código MFA inválido")

    # Login OK: limpiar AMBOS contadores (si no, el de cuenta se queda pegado y
    # un admin legítimo sigue viendo 429 hasta que expire la ventana).
    clear_failures(lock_key)
    clear_failures(account_key)
    if password_needs_rehash(user.password_hash):
        user.password_hash = hash_password(password)

    token = create_access_token(
        user.id,
        {"adm": True, "tv": user.token_version or 0},
        minutes=ADMIN_TOKEN_MINUTES,
    )
    response.set_cookie(
        key=COOKIE_NAME, value=token, httponly=True, samesite="strict",
        secure=settings.COOKIE_SECURE, max_age=ADMIN_TOKEN_MINUTES * 60,
        domain=settings.COOKIE_DOMAIN, path="/",
    )
    db.add(AuditLog(user_id=user.id, action="admin_login", entity="user", entity_id=str(user.id), ip=ip))
    db.commit()
    return {"ok": True, "email": user.email, "name": user.full_name,
            "mfa_enabled": user.totp_enabled, "mfa_setup_required": not user.totp_enabled}


@auth_router.post("/logout")
def logout(response: Response):
    response.delete_cookie(COOKIE_NAME, path="/", domain=settings.COOKIE_DOMAIN)
    return {"ok": True}


@auth_router.get("/me")
def me(admin: User = Depends(get_current_admin)):
    return {"id": admin.id, "email": admin.email, "name": admin.full_name,
            "is_admin": admin.is_admin, "role": admin.role, "mfa_enabled": admin.totp_enabled}


# --------------------------------------------------------------------------- #
# MFA / TOTP (Google Authenticator, Authy, 1Password, etc.)
# --------------------------------------------------------------------------- #
@auth_router.post("/totp/setup")
def totp_setup(admin: User = Depends(get_current_admin), db: Session = Depends(get_db)):
    """Genera (o reusa) el secreto TOTP y devuelve la URI para el QR.
    No queda habilitado hasta confirmar un código con /totp/enable."""
    if not admin.totp_secret or admin.totp_enabled is False:
        admin.totp_secret = pyotp.random_base32()
        db.commit()
    uri = pyotp.TOTP(admin.totp_secret).provisioning_uri(
        name=admin.email, issuer_name="MIAMI IMPORT Panel")

    # QR generado en el server (SVG). Así no hace falta ninguna librería del
    # navegador ni un CDN, que además la CSP del panel no permitiría.
    qr_svg = ""
    try:
        import io as _io

        import qrcode
        import qrcode.image.svg as _svg
        buf = _io.BytesIO()
        qrcode.make(uri, image_factory=_svg.SvgPathImage).save(buf)
        qr_svg = buf.getvalue().decode("utf-8")
    except Exception:  # noqa: BLE001  (sin QR se puede cargar la clave a mano)
        pass

    return {"secret": admin.totp_secret, "otpauth_uri": uri, "qr_svg": qr_svg}


@auth_router.post("/totp/enable")
def totp_enable(body: dict, request: Request, admin: User = Depends(get_current_admin),
                db: Session = Depends(get_db)):
    code = (body.get("totp_code") or "").strip()
    if not admin.totp_secret or not pyotp.TOTP(admin.totp_secret).verify(code, valid_window=1):
        raise HTTPException(400, "Código inválido")
    admin.totp_enabled = True
    db.add(AuditLog(user_id=admin.id, action="mfa_enabled", entity="user", entity_id=str(admin.id),
                    ip=request.client.host if request.client else None))
    db.commit()
    return {"ok": True}


@auth_router.post("/totp/disable")
def totp_disable(body: dict, request: Request, admin: User = Depends(get_current_admin),
                 db: Session = Depends(get_db)):
    # Para desactivar exigimos un código válido (evita que un secuestro de sesión lo apague).
    code = (body.get("totp_code") or "").strip()
    if admin.totp_enabled and not pyotp.TOTP(admin.totp_secret or "").verify(code, valid_window=1):
        raise HTTPException(400, "Código inválido")
    admin.totp_enabled = False
    admin.totp_secret = None
    db.add(AuditLog(user_id=admin.id, action="mfa_disabled", entity="user", entity_id=str(admin.id),
                    ip=request.client.host if request.client else None))
    db.commit()
    return {"ok": True}


# --------------------------------------------------------------------------- #
# Bootstrap del admin inicial
# --------------------------------------------------------------------------- #
def ensure_admin() -> None:
    """Crea/actualiza el admin inicial si ADMIN_EMAIL/ADMIN_PASSWORD están seteados.
    Si no hay password configurada y no existe ningún admin, avisa por consola."""
    db = SessionLocal()
    try:
        any_admin = db.query(User).filter(User.is_admin.is_(True)).first()
        if settings.ADMIN_EMAIL and settings.ADMIN_PASSWORD:
            email = settings.ADMIN_EMAIL.strip().lower()
            user = db.query(User).filter(User.email == email).one_or_none()
            if not user:
                user = User(email=email, is_admin=True, email_verified=True)
                db.add(user)
            user.is_admin = True
            user.is_active = True
            user.role = "owner"
            user.password_hash = hash_password(settings.ADMIN_PASSWORD)
            user.full_name = user.full_name or "Administrador"
            db.commit()
            print(f"[auth] admin asegurado: {email}")
        elif not any_admin:
            print("[auth] [!] No hay admin y no se configuró ADMIN_PASSWORD. "
                  "Seteá ADMIN_EMAIL/ADMIN_PASSWORD en .env para crear uno.")
    finally:
        db.close()
