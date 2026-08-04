#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Backup de fotos a una carpeta local (que después se sincroniza con
Google Drive vía "Drive for Desktop", o se sube manualmente).

Diseño:
    - Si LOCAL_BACKUP_PATH está seteado, guarda las fotos ahí (recomendado
      con un service account / Gmail personal porque los service accounts
      no tienen cuota de storage propio).
    - Si LOCAL_BACKUP_PATH está vacío, no hace nada y la app sigue
      funcionando normal contra Tiendanube.

Nombre de archivo (contiene toda la info para buscar desde Drive):

    {MARCA}__{producto-slug}__talles-{S-M-L}__{precio}{moneda}__TN-{id}__{pos}.jpg
"""
from __future__ import annotations

import os
import re
import shutil
import unicodedata
from pathlib import Path
from typing import Iterable, Optional

HERE = Path(__file__).resolve().parent

_backup_path: Optional[Path] = None
_initialized = False
_disabled_reason: Optional[str] = None


def _strip_accents(s: str) -> str:
    s = unicodedata.normalize("NFKD", s or "")
    return "".join(c for c in s if not unicodedata.combining(c))


def _slug(s: str, max_len: int = 40) -> str:
    s = _strip_accents(s).strip()
    s = re.sub(r"[^A-Za-z0-9]+", "-", s).strip("-")
    return s[:max_len].rstrip("-") or "x"


def _slug_upper(s: str, max_len: int = 20) -> str:
    return _slug(s, max_len).upper()


def _sanitize_for_windows(name: str) -> str:
    """Quita los caracteres prohibidos en nombres de archivo de Windows."""
    return re.sub(r'[<>:"/\\|?*\x00-\x1f]', "_", name)


def init() -> bool:
    """Inicializa la ruta de backup una sola vez.

    Devuelve True si el backup quedó activo, False si está desactivado."""
    global _backup_path, _initialized, _disabled_reason
    if _initialized:
        return _backup_path is not None

    _initialized = True
    raw = os.environ.get("LOCAL_BACKUP_PATH", "").strip()

    if not raw:
        _disabled_reason = "LOCAL_BACKUP_PATH vacío"
        return False

    try:
        path = Path(raw).expanduser()
        path.mkdir(parents=True, exist_ok=True)
        if not path.is_dir():
            _disabled_reason = f"{path} no es un directorio"
            return False
        _backup_path = path
        return True
    except Exception as e:
        _disabled_reason = f"Error creando {raw}: {e}"
        return False


def is_enabled() -> bool:
    if not _initialized:
        init()
    return _backup_path is not None


def status() -> dict:
    if not _initialized:
        init()
    return {
        "enabled": _backup_path is not None,
        "backup_path": str(_backup_path) if _backup_path else None,
        "reason": _disabled_reason,
    }


def build_filename(
    *,
    marca: str,
    producto: str,
    talles: Iterable[str],
    precio,
    moneda: str = "ARS",
    tn_id,
    position: int = 1,
    ext: str = "jpg",
) -> str:
    """Construye un nombre de archivo con toda la info del producto.

    Ejemplo:
        DIESEL__remera-regular-blanca__talles-S-M-L__45000ARS__TN-123456__01.jpg
    """
    marca_s = _slug_upper(marca, 20)
    prod_s = _slug(producto, 50)
    talles_list = [t for t in talles if t]
    talles_s = _slug("-".join(talles_list), 30) if talles_list else "unico"
    precio_num = re.sub(r"[^0-9.]", "", str(precio or 0)) or "0"
    if "." in precio_num:
        precio_num = precio_num.split(".")[0]
    moneda_s = (moneda or "ARS").upper()[:3]
    pos_s = f"{max(int(position or 1), 1):02d}"
    ext_s = (ext or "jpg").lstrip(".").lower()
    name = f"{marca_s}__{prod_s}__talles-{talles_s}__{precio_num}{moneda_s}__TN-{tn_id}__{pos_s}.{ext_s}"
    return _sanitize_for_windows(name)


def upload_bytes(content: bytes, filename: str, mime_type: str = "image/jpeg") -> Optional[dict]:
    """Guarda los bytes en la carpeta local con el nombre dado.

    Devuelve dict {path, name} si funcionó, None si está desactivado o
    hubo error (la app no debe fallar por esto).

    Parametro mime_type se acepta por compatibilidad pero se ignora
    (se guarda al disco tal cual)."""
    if not is_enabled():
        return None
    try:
        out = _backup_path / filename
        # Si ya existe con el mismo tamaño, saltear (idempotente)
        if out.exists() and out.stat().st_size == len(content):
            return {"path": str(out), "name": filename, "skipped": True}
        out.write_bytes(content)
        return {"path": str(out), "name": filename}
    except Exception as e:
        print(f"[backup] error guardando {filename}: {e}")
        return None


def existing_filenames() -> set:
    """Lista los nombres de archivo ya presentes en la carpeta de backup."""
    if not is_enabled():
        return set()
    try:
        return {p.name for p in _backup_path.iterdir() if p.is_file()}
    except Exception:
        return set()


def guess_mime_from_filename(filename: str) -> str:
    ext = filename.lower().rsplit(".", 1)[-1] if "." in filename else ""
    return {
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "webp": "image/webp",
        "gif": "image/gif",
        "heic": "image/heic",
    }.get(ext, "image/jpeg")


def guess_ext_from_filename(filename: str) -> str:
    base = filename.split("?")[0]
    if "." in base:
        return base.lower().rsplit(".", 1)[-1]
    return "jpg"
