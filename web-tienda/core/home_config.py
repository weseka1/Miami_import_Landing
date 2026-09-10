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
        # 🔴 VACIO A PROPOSITO. Aca vivian cinco camperas de la campana
        # "trilogy" escritas a mano. Diego dejo de venderlas y la vitrina las
        # siguio mostrando meses, porque no salian del catalogo: eran texto
        # fijo. Juani las reporto dos veces.
        #
        # Con la lista vacia, app.py arma la vitrina con productos REALES del
        # catalogo (los mismos `destacados` que ya se consultaron, sin costo
        # extra). Asi no puede volver a quedar desactualizada.
        # Si Diego carga piezas a mano desde el panel, esas ganan.
        "piezas": [],

        # --- Piezas FIJADAS: curaduria sin volver a la trampa de arriba -------
        # Aca no va la pieza escrita a mano: va el HANDLE del producto real.
        # app.py la busca en la base cada vez, y **la ignora sola** si dejo de
        # estar publicada o se quedo sin stock. Es la diferencia con el bloque
        # de arriba: una pieza fijada no puede quedar mostrandose meses despues
        # de que Diego dejo de venderla, porque no es texto — es una consulta.
        #
        # `genero` es opcional y sirve para decidir en que pestana aparece
        # (Hombre / Mujer). Sin el, se deduce del nombre, que es lo que hace
        # que un "Buzo Over" siempre caiga en Hombre. Ponerlo es una decision
        # de vidriera, no una afirmacion sobre la prenda.
        "fijadas": [
            # Pedido de Juani (8-sep): sacar el vestido Diesel de la pestana
            # Mujer y poner algo de Supreme. De las 3 piezas Supreme del
            # catalogo, esta es la UNICA con stock (M y L): el buzo negro
            # —el que mejor se ve— esta agotado en todos los talles.
            {"handle": "supreme-buzo-supreme-camuflado-over", "genero": "mujer"},
        ],
    },
    "marcas": {
        "activo": True,
        "eyebrow": "La casa",
        "titulo": "Marcas con licencia",
        "bajada": "Selección curada pieza por pieza. Cada casa, sus códigos.",
        # ------------------------------------------------------------------ #
        # 🖼️ Estas 8 imagenes son IMAGINERIA DE MARCA, no stock.
        #
        # Es importante tenerlo claro antes de tocarlas: ninguna de las 8 esta
        # en el catalogo de Diego (el bolso Balenciaga y la varsity Amiri
        # tampoco). La tarjeta dice "esta casa" y el link lleva al listado
        # real. Confundir las dos cosas lleva a elegir la pieza mas comun que
        # haya en stock, que es exactamente el error de las dos rondas
        # anteriores.
        #
        # Historial de rechazos, para no repetirlos:
        #   1er intento — DOS REMERAS NEGRAS LISAS (Diesel y Prada). Rebotadas
        #     las dos. Con razon: en una fila donde Palm Angels ya es un buzo
        #     negro y Amiri una campera negra, una remera lisa no se distingue
        #     de la de al lado.
        #   2do intento — campera de jean (Diesel) y bolso acolchado (Prada).
        #     Rechazadas por Diego: "estan quemadas por la pirateria". Son las
        #     dos graficas que mas se falsifican, o sea la estetica del puesto
        #     de feria — lo contrario de lo que esta tienda afirma.
        #   3ro (este, 10-sep) — pedido de Juani: "prendas mas exclusivas, mas
        #     caras" en Prada y Diesel, y sacar la gorra de Hugo Boss por algo
        #     "mas exotico de la marca". El criterio pasa a ser: la pieza
        #     ICONICA y cara de cada casa, la que nadie falsifica bien porque
        #     el valor esta en la herreria y el cuero, no en un estampado.
        #       · DIESEL    → bolso 1DR. Es LA pieza que volvio cara a Diesel.
        #       · PRADA     → Saffiano Brique. 🔴 Este modelo exacto lo eligio
        #         Diego: mando una foto del bolso en la oficina y pidio
        #         "conseguilo sin fondo, full pro". Esto es el packshot oficial
        #         del mismo modelo, que es la version limpia de esa foto.
        #       · HUGO BOSS → campera de cuero. La gorra que estaba era gris de
        #         lana con el logo bordado: la pieza mas barata de la casa en
        #         una fila donde todo lo demas es prenda.
        #
        # Las 3 salen de packshot oficial de la marca, recortadas con rembg
        # (isnet-general-use) sobre el original en resolucion completa. El
        # recorte se mira SIEMPRE compuesto sobre gris medio antes de subirlo:
        # sobre blanco no se ve ni la orla clara ni un hueco que quedo relleno
        # —al 1DR le habia quedado blanco el ojo del asa—.
        # ------------------------------------------------------------------ #
        "items": [
            {"nombre": "DIESEL", "link": "/categoria/diesel",
             "imagen": "/static/images/category-diesel-cut-v5.webp"},
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
             "imagen": "/static/images/category-hugo-boss-cut-v2.webp"},
            {"nombre": "PRADA", "link": "/categoria/prada",
             "imagen": "/static/images/category-prada-cut-v3.webp"},
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


def _invalidar_cache_web() -> None:
    """Avisa a la tienda que su caché quedó viejo.

    El panel corre en el mismo proceso que la tienda, así que al guardar acá
    se limpia el caché de allá y Diego ve el cambio al instante, sin esperar
    el TTL. El import va adentro para no crear un ciclo (app importa esto).
    """
    try:
        import app as _tienda
        _tienda.limpiar_caches_web()
    except Exception:  # noqa: BLE001 — que nunca rompa un guardado
        pass


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
    _invalidar_cache_web()
    return _merge(DEFAULTS, nuevo)


def reset_home_config(db: Session) -> dict:
    """Vuelve todo a los valores de fábrica (el botón de pánico del panel)."""
    fila = db.get(Setting, CLAVE)
    if fila:
        db.delete(fila)
        db.commit()
    _invalidar_cache_web()
    return copy.deepcopy(DEFAULTS)
