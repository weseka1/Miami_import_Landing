"""Configuración editable de la home de la tienda.

Todo lo que Diego puede cambiar desde el panel (hero, vitrina, marcas,
valores, cierre) vive acá como un JSON en la tabla `settings`, bajo la clave
`home_config`. No hace falta migración: `Setting` ya es key/value JSON.

Regla de oro: **si no hay nada guardado, la web se ve exactamente igual que
hoy**. Los DEFAULTS de este módulo son una copia fiel de lo que estaba
hardcodeado en las plantillas, así que la home nunca queda vacía ni rota,
ni siquiera si alguien borra la fila de la base.
"""
from __future__ import annotations

import copy
from typing import Any

from sqlalchemy.orm import Session

from .models import Setting

CLAVE = "home_config"

# --------------------------------------------------------------------------- #
# Valores por defecto = lo que hoy está escrito a mano en las plantillas.
# --------------------------------------------------------------------------- #
DEFAULTS: dict[str, Any] = {
    "hero": {
        "activo": True,
        "eyebrow": "MILANO → BUENOS AIRES · MARCAS CON LICENCIA",
        "titulo": "Originales importados con licencia de origen.",
        "subtitulo": "Piezas contadas — cuando no está, no vuelve.",
        "cta_texto": "Ver catálogo",
        "cta_link": "/productos",
        "cta2_texto": "Pedido puntual",
        "cta2_link": "",          # vacío → se arma el WhatsApp de la tienda
        "video": "",              # vacío → /static/videos/hero-miami.mp4
    },
    "vitrina": {
        "activo": True,
        "eyebrow": "La casa",
        "titulo": "Piezas de archivo",
        # Copia FIEL de lo que estaba en la plantilla (incluido el género, que
        # es lo que filtra el switch HOMBRE / MUJER de la vitrina).
        "piezas": [
            {"nombre": "MARRÓN", "genero": "hombre",
             "imagen": "/static/images/trilogy-marron-v6.webp",
             "ref": "REF / 01 · HOMBRE", "colorway": "TIERRA NEGRA",
             "talles": "S — 2XL", "peso": "980 g", "link": "/tipo/camperas",
             "descripcion": "Tierra negra. La pieza se reescribe en tono cálido, con patches que viran al dorado. Streetwear con vocabulario de archivo."},
            {"nombre": "MULTICOLOR", "genero": "hombre",
             "imagen": "/static/images/trilogy-multicolor-v6.webp",
             "ref": "REF / 02 · HOMBRE", "colorway": "MULTICOLOR ARCHIVE",
             "talles": "S — 2XL", "peso": "980 g", "link": "",
             "descripcion": "Pieza de archivo racing. Patches saturados, composición tipográfica intensa. Rojo motor, blanco crudo y negro tinta en convivencia."},
            {"nombre": "BLANCO", "genero": "mujer",
             "imagen": "/static/images/trilogy-blanco-v6.webp",
             "ref": "REF / 01 · MUJER", "colorway": "CRUDO MARFIL",
             "talles": "S — 2XL", "peso": "980 g", "link": "/tipo/camperas",
             "descripcion": "Crudo. Sin maquillaje. Patches bordados sobre nylon italiano, hilos plateados, costura visible. Una declaración de pureza."},
            {"nombre": "NEGRO", "genero": "mujer",
             "imagen": "/static/images/trilogy-negro-v6.webp",
             "ref": "REF / 02 · MUJER", "colorway": "NEGRO TINTA",
             "talles": "S — 2XL", "peso": "980 g", "link": "/tipo/camperas",
             "descripcion": "Negro tinta. El bordado se vuelve tonal, el peso visual se concentra. Una lectura más íntima, casi monástica."},
            {"nombre": "NEGRA PARCHES", "genero": "hombre",
             "imagen": "/static/images/trilogy-negra-parches-v6.webp",
             "ref": "REF / 03 · HOMBRE", "colorway": "NEGRO PARCHES",
             "talles": "S — 2XL", "peso": "980 g", "link": "/tipo/camperas",
             "descripcion": "Negra estructura. Patches metálicos sobre nylon italiano, costura visible y peso editorial. Streetwear con presencia de archivo."},
        ],
    },
    "marcas": {
        "activo": True,
        "eyebrow": "La casa",
        "titulo": "Marcas con licencia",
        "bajada": "Selección curada pieza por pieza. Cada casa, sus códigos.",
        "items": [
            {"nombre": "DIESEL", "link": "/categoria/diesel",
             "imagen": "/static/images/category-diesel-cut-v2.webp"},
            {"nombre": "BALENCIAGA", "link": "/categoria/balenciaga",
             "imagen": "/static/images/category-balenciaga-cut.webp"},
            {"nombre": "OFF-WHITE", "link": "/categoria/off-white",
             "imagen": "/static/images/category-off-white-cut.webp"},
            {"nombre": "AMIRI", "link": "/categoria/amiri",
             "imagen": "/static/images/category-amiri-cut.webp"},
            {"nombre": "PALM ANGELS", "link": "/categoria/palm-angels",
             "imagen": "/static/images/category-palm-angels-cut.webp"},
            {"nombre": "BALMAIN", "link": "/categoria/balmain",
             "imagen": "/static/images/category-balmain-cut.webp"},
            {"nombre": "HUGO BOSS", "link": "/categoria/hugo-boss",
             "imagen": "/static/images/category-hugo-boss-cut.webp"},
            {"nombre": "CALVIN KLEIN", "link": "/categoria/calvin-klein",
             "imagen": "/static/images/category-calvin-klein-cut.webp"},
        ],
    },
    "secciones": {
        "mas_vendidos_eyebrow": "Lo que más vuela",
        "mas_vendidos_titulo": "Más vendidos",
        "destacados_eyebrow": "Selección de la casa",
        "destacados_titulo": "Destacados",
        "ultimos_eyebrow": "Se agotan",
        "ultimos_titulo": "Últimos en stock",
    },
    "valores": {
        "activo": True,
        "items": [
            {"num": "01", "titulo": "Doc. de origen",
             "texto": "Comprobante de autenticidad con cada pieza."},
            {"num": "02", "titulo": "Edición chica",
             "texto": "Pocas unidades. Reposición sólo por pedido."},
            {"num": "03", "titulo": "Atención 1:1",
             "texto": "WhatsApp directo, sin formularios ni esperas."},
            {"num": "04", "titulo": "Ruta verificada",
             "texto": "Italia · Miami → Buenos Aires, trazable."},
        ],
    },
    "cierre": {
        "activo": True,
        "titulo": "¿Buscás una pieza puntual?",
        "texto": "Escribinos y te confirmamos disponibilidad, talle y precio en minutos.",
        "cta_texto": "Abrir WhatsApp →",
        "wa_mensaje": "Hola, quiero consultar por una pieza.",
    },
}


def _merge(base: dict, encima: dict) -> dict:
    """Mezcla profunda: lo guardado pisa al default, campo por campo.

    Así, si mañana se agrega una clave nueva a DEFAULTS, las configuraciones
    ya guardadas la heredan en vez de quedar sin ese dato (que en la plantilla
    se vería como un hueco).
    """
    out = copy.deepcopy(base)
    for k, v in (encima or {}).items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = _merge(out[k], v)
        else:
            out[k] = v
    return out


def get_home_config(db: Session) -> dict:
    """Config completa para las plantillas (siempre con todas las claves)."""
    fila = db.get(Setting, CLAVE)
    guardado = fila.value if fila and isinstance(fila.value, dict) else {}
    return _merge(DEFAULTS, guardado)


def save_home_config(db: Session, parcial: dict) -> dict:
    """Guarda SOLO los bloques que vienen en `parcial` (merge, no reemplazo).

    El panel manda un bloque por vez; reemplazar el JSON entero borraría los
    otros bloques si el front mandara de menos.
    """
    fila = db.get(Setting, CLAVE)
    actual = fila.value if fila and isinstance(fila.value, dict) else {}
    nuevo = _merge(actual, parcial or {})
    if not fila:
        fila = Setting(key=CLAVE)
        db.add(fila)
    fila.value = nuevo
    db.commit()
    return _merge(DEFAULTS, nuevo)


def reset_home_config(db: Session) -> dict:
    """Vuelve todo a los valores de fábrica (el botón de pánico del panel)."""
    fila = db.get(Setting, CLAVE)
    if fila:
        db.delete(fila)
        db.commit()
    return copy.deepcopy(DEFAULTS)
