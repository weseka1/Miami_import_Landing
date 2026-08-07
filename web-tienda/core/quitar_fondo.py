"""Quita el fondo de una foto para la vitrina de la home.

Diego saca las fotos en el local (percha, pared, piso de mármol) y la vitrina
necesita la prenda flotando sobre negro. Esto lo resuelve con la misma IA que
ya usa el probador virtual:

  FAL_KEY        → fal.ai birefnet (recorte dedicado, más fino y más barato)
  GEMINI_API_KEY → gemini-2.5-flash-image (OJO: NO tiene franja gratuita,
                   se cobra ~USD 0,039 por imagen procesada)

Cada recorte CUESTA PLATA. Como lo dispara Diego a mano desde el panel (unas
pocas fotos por mes), el gasto es de centavos; el volumen alto está en el
probador virtual, no acá.

Si ninguna key está cargada, `disponible()` devuelve False y el panel muestra
el modo manual (subir un PNG ya recortado). Nunca revienta la subida.
"""
from __future__ import annotations

import base64
import io
import os

import requests

_GEMINI_URL = ("https://generativelanguage.googleapis.com/v1beta/models/"
               "gemini-2.5-flash-image:generateContent")
_FAL_BIREFNET = "https://fal.run/fal-ai/birefnet/v2"
_TIMEOUT = 90
_LADO_MAX = 1400          # la vitrina no necesita más y acelera la subida

_PROMPT = (
    "Remove the background completely from this product photo. Keep ONLY the "
    "garment/product, perfectly cut out, including small details like straps, "
    "hoodie strings and hardware. Do not add shadows, reflections or any "
    "background. Do not alter the product's colors, texture or shape. "
    "Return the product centered on a fully TRANSPARENT background as PNG. "
    "Output ONLY the edited image."
)


def _gemini_key() -> str | None:
    return (os.environ.get("GEMINI_API_KEY") or "").strip() or None


def _fal_key() -> str | None:
    return (os.environ.get("FAL_KEY") or "").strip() or None


def disponible() -> bool:
    return bool(_gemini_key() or _fal_key())


def _preparar(data: bytes) -> bytes:
    """EXIF aplicado y lado máximo acotado, en PNG (conserva transparencia)."""
    try:
        from PIL import Image, ImageOps
        Image.MAX_IMAGE_PIXELS = 40_000_000
        img = Image.open(io.BytesIO(data))
        if (img.format or "").upper() == "MPO":   # fotos de iPhone
            img = img.convert("RGBA")
        img = ImageOps.exif_transpose(img)
        if max(img.size) > _LADO_MAX:
            img.thumbnail((_LADO_MAX, _LADO_MAX), Image.LANCZOS)
        buf = io.BytesIO()
        img.convert("RGBA").save(buf, format="PNG", optimize=True)
        return buf.getvalue()
    except Exception:  # noqa: BLE001 — si Pillow no puede, va el original
        return data


def _recorte_valido(png: bytes) -> bool:
    """¿De verdad quedó recortada? Verifica que haya transparencia real.

    Gemini a veces devuelve la foto con un fondo liso en vez de alfa; sin este
    control esa imagen entraría a la vitrina con un rectángulo de color y
    quedaría horrible sobre el fondo negro.
    """
    try:
        from PIL import Image
        img = Image.open(io.BytesIO(png))
        if img.mode != "RGBA":
            return False
        alpha = img.getchannel("A")
        minimo, maximo = alpha.getextrema()
        if minimo > 8:                    # nada transparente → no recortó
            return False
        # las 4 esquinas deberían estar vacías en un recorte bien hecho
        w, h = img.size
        esquinas = [alpha.getpixel(p) for p in
                    ((1, 1), (w - 2, 1), (1, h - 2), (w - 2, h - 2))]
        return sum(1 for e in esquinas if e < 32) >= 3
    except Exception:  # noqa: BLE001
        return False


def _por_gemini(data: bytes, key: str) -> bytes:
    body = {
        "contents": [{"parts": [
            {"text": _PROMPT},
            {"inline_data": {"mime_type": "image/png",
                             "data": base64.b64encode(data).decode()}},
        ]}],
        "generationConfig": {"responseModalities": ["TEXT", "IMAGE"]},
    }
    r = requests.post(f"{_GEMINI_URL}?key={key}", json=body, timeout=_TIMEOUT)
    if r.status_code != 200:
        raise RuntimeError(f"gemini HTTP {r.status_code}: {r.text[:200]}")
    for part in r.json()["candidates"][0]["content"]["parts"]:
        blob = part.get("inline_data") or part.get("inlineData")
        if blob and blob.get("data"):
            return base64.b64decode(blob["data"])
    raise RuntimeError("gemini no devolvió imagen")


def _por_fal(data: bytes, key: str) -> bytes:
    b64 = base64.b64encode(data).decode()
    r = requests.post(
        _FAL_BIREFNET,
        headers={"Authorization": f"Key {key}", "Content-Type": "application/json"},
        json={"image_url": f"data:image/png;base64,{b64}"},
        timeout=_TIMEOUT,
    )
    if r.status_code != 200:
        raise RuntimeError(f"fal HTTP {r.status_code}: {r.text[:200]}")
    url = (r.json().get("image") or {}).get("url")
    if not url:
        raise RuntimeError("fal no devolvió imagen")
    img = requests.get(url, timeout=_TIMEOUT)
    img.raise_for_status()
    return img.content


def quitar_fondo(data: bytes) -> tuple[bytes, str]:
    """Devuelve (png_recortado, motor). Lanza RuntimeError si ninguno pudo.

    fal/birefnet primero: es un modelo dedicado a recortar y sale más prolijo
    que un modelo generativo. Gemini queda de respaldo (y es gratis).
    """
    entrada = _preparar(data)
    errores = []

    for nombre, key, fn in (("fal", _fal_key(), _por_fal),
                            ("gemini", _gemini_key(), _por_gemini)):
        if not key:
            continue
        try:
            salida = fn(entrada, key)
            if not _recorte_valido(salida):
                # Reintento único: al modelo generativo a veces hay que
                # insistirle para que devuelva alfa de verdad.
                if nombre == "gemini":
                    salida = fn(entrada, key)
                if not _recorte_valido(salida):
                    raise RuntimeError("el resultado vino sin transparencia")
            return _preparar(salida), nombre
        except Exception as e:  # noqa: BLE001
            errores.append(f"{nombre}: {str(e)[:120]}")

    raise RuntimeError("; ".join(errores) or "no hay ninguna API de recorte configurada")
