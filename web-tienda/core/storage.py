"""
Adapter de Supabase Storage para imágenes de productos.

Liviano: usa la API REST de Storage con `requests` (sin SDK pesado). Lee la
config del entorno (SUPABASE_URL / SUPABASE_SECRET_KEY / SUPABASE_BUCKET).

Si Supabase no está configurado, `is_enabled()` devuelve False y el código
llamador cae al guardado local (comportamiento de desarrollo).
"""
from __future__ import annotations

import requests

from .config import settings


def is_enabled() -> bool:
    return settings.storage_enabled


def _headers(content_type: str | None = None) -> dict:
    # Las claves nuevas (sb_secret_...) se autentican por el header `apikey`.
    # Mandamos también Authorization por compatibilidad con claves JWT legadas.
    key = settings.SUPABASE_SECRET_KEY
    h = {"apikey": key, "Authorization": f"Bearer {key}"}
    if content_type:
        h["Content-Type"] = content_type
    return h


def public_url(path: str) -> str:
    """URL pública (bucket público) para servir la imagen."""
    return f"{settings.SUPABASE_URL}/storage/v1/object/public/{settings.SUPABASE_BUCKET}/{path}"


_OBJECT_MARKER = "/storage/v1/object/public/"
_RENDER_MARKER = "/storage/v1/render/image/public/"


def thumb_url(url: str | None, width: int = 800, quality: int = 75) -> str | None:
    """URL redimensionada al vuelo (Supabase Image Transformations).

    Las fotos del panel entran crudas del celular (4-5 MB): servirlas directo
    deja las cards en negro / a medio pintar en el teléfono. El endpoint
    `render/image` devuelve la misma foto en el ancho pedido (~10x más
    liviana) y con la rotación EXIF ya aplicada.

    URLs que no son del Storage propio (CDN de Tiendanube, /static/...)
    vuelven tal cual.
    """
    if not url or _OBJECT_MARKER not in url or "?" in url:
        return url
    # OJO: con `width` solo, el transformador aplica `resize=cover` y mantiene el
    # alto original → recorta los costados y las fotos verticales salen como una
    # tira finita. `resize=contain` + una caja alta (tope 2500, el máximo del
    # transformador) devuelve la foto ENTERA proporcional al ancho pedido.
    alto = min(width * 2, 2500)
    return (url.replace(_OBJECT_MARKER, _RENDER_MARKER, 1)
            + f"?width={width}&height={alto}&resize=contain&quality={quality}")


def upload_bytes(content: bytes, path: str, content_type: str = "application/octet-stream") -> str:
    """Sube bytes al bucket en `path` (sobrescribe si existe). Devuelve la URL pública.
    Lanza RuntimeError si falla."""
    if not is_enabled():
        raise RuntimeError("Supabase Storage no está configurado")
    url = f"{settings.SUPABASE_URL}/storage/v1/object/{settings.SUPABASE_BUCKET}/{path}"
    headers = _headers(content_type)
    headers["x-upsert"] = "true"
    r = requests.post(url, headers=headers, data=content, timeout=60)
    if not r.ok:
        raise RuntimeError(f"Supabase upload {r.status_code}: {r.text[:200]}")
    return public_url(path)


def delete_path(path: str) -> bool:
    """Borra un objeto del bucket. No lanza: devuelve True/False."""
    if not is_enabled() or not path:
        return False
    url = f"{settings.SUPABASE_URL}/storage/v1/object/{settings.SUPABASE_BUCKET}/{path}"
    try:
        r = requests.delete(url, headers=_headers(), timeout=30)
        return r.ok
    except requests.RequestException:
        return False


def path_from_url(url: str | None) -> str | None:
    """Extrae el path dentro del bucket a partir de una URL pública de Supabase."""
    if not url:
        return None
    marker = f"/storage/v1/object/public/{settings.SUPABASE_BUCKET}/"
    if marker in url:
        return url.split(marker, 1)[1]
    return None
