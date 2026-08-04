"""
Sanitización de HTML enriquecido (descripciones de producto).

La tienda renderiza `product.description` con `| safe`, así que lo que se
guarda en la base tiene que ser HTML ya seguro. Las descripciones de
TiendaNube traen formato legítimo (<p>, <strong>, listas), por eso no alcanza
con escapar todo: se filtra con una allow-list de etiquetas y atributos.

Si `bleach` no está instalado, el fallback ESCAPA todo (seguro, aunque se
pierda el formato) en vez de dejar pasar HTML crudo.
"""
from __future__ import annotations

import html

try:
    import bleach

    _HAVE_BLEACH = True
except ImportError:  # pragma: no cover
    _HAVE_BLEACH = False

# Etiquetas de formato inofensivas. Sin <script>, <style>, <iframe>, <a>
# (href javascript:), ni handlers on*.
_ALLOWED_TAGS = [
    "p", "br", "strong", "b", "em", "i", "u", "ul", "ol", "li",
    "span", "h2", "h3", "h4", "blockquote", "hr",
]
_ALLOWED_ATTRS: dict[str, list[str]] = {}


def clean_description(raw: str | None) -> str | None:
    """Devuelve HTML seguro para renderizar con `| safe`, o None si vacío."""
    if not raw:
        return raw
    if _HAVE_BLEACH:
        return bleach.clean(raw, tags=_ALLOWED_TAGS, attributes=_ALLOWED_ATTRS,
                            strip=True)
    # Sin bleach: escapar todo. Se pierde el formato pero nunca ejecuta.
    return html.escape(raw)
