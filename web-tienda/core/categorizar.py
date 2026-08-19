"""Categorización automática de productos — la herencia de Tiendanube.

Problema que resuelve (medido el 19-ago-2026): de 248 productos publicados,
**113 (45%) no aparecían en el menú de la tienda** porque nadie les asignaba
categoría al cargarlos. Marcas enteras invisibles: Emestudios (20 productos),
Karl Lagerfeld (13), Casa Blanca (7). El cliente solo llegaba a ellas por el
buscador o de casualidad desde la home.

Además la misma marca venía escrita de varias formas ("Off white", "Off White",
"Off-White"), así que el catálogo de una marca aparecía partido en pedazos.

Cómo funciona el menú de la tienda (ver nav_tipos en app.py):
    Categoría PADRE  = marca   (Diesel, Off-White…)
    Categoría HIJA   = tipo    (Buzos, Remeras… con parent_id = la marca)
El menú agrupa las hijas por nombre y muestra TIPO -> marcas.

Este módulo: normaliza la marca, deduce el tipo de prenda desde el nombre, y
crea/engancha las categorías que hagan falta.
"""
from __future__ import annotations

import re
import unicodedata

from sqlalchemy.orm import Session

from .models import Category, Product


def _clave(texto: str) -> str:
    """Minúsculas, sin acentos ni separadores: Off-White == off white."""
    t = unicodedata.normalize("NFKD", texto or "")
    t = "".join(c for c in t if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]", "", t.lower())


# Forma canónica de cada marca. La clave es el nombre normalizado; se listan
# las variantes que trajo la migración y los errores de tipeo vistos en la base.
MARCAS_CANONICAS = {
    "diesel": "Diesel", "diesle": "Diesel",
    "offwhite": "Off-White", "offwhitte": "Off-White", "offwithe": "Off-White",
    "emporioarmani": "Emporio Armani", "emporioarmanu": "Emporio Armani",
    "armaniexchange": "Armani Exchange",
    "hugoboss": "Hugo Boss", "boss": "Hugo Boss",
    "palmangels": "Palm Angels",
    "karllagerfeld": "Karl Lagerfeld",
    "emestudios": "Emestudios", "emstudios": "Emestudios",
    "casablanca": "Casablanca",
    "balenciaga": "Balenciaga", "balmain": "Balmain", "amiri": "Amiri",
    "supreme": "Supreme", "prada": "Prada", "givenchy": "Givenchy",
    "louisvuitton": "Louis Vuitton", "michaelkors": "Michael Kors",
    "calvinklein": "Calvin Klein", "dsquared2": "Dsquared2", "dsquared": "Dsquared2",
    "jacquemus": "Jacquemus", "jaquemus": "Jacquemus", "loewe": "Loewe",
    "moncler": "Moncler", "lacoste": "Lacoste", "nike": "Nike",
    "adidas": "Adidas", "stoneisland": "Stone Island", "burberry": "Burberry",
    "tommyhilfiger": "Tommy Hilfiger", "ralphlauren": "Ralph Lauren",
    "northface": "The North Face", "thenorthface": "The North Face",
}


def marca_canonica(brand: str | None) -> str | None:
    """Devuelve la forma única de la marca (Off white -> Off-White).

    Una marca desconocida se respeta: solo se le limpian los espacios y se le
    da formato de título si venía toda en minúscula o toda en mayúscula.
    """
    if not brand or not brand.strip():
        return None
    limpio = re.sub(r"\s+", " ", brand.strip())
    canon = MARCAS_CANONICAS.get(_clave(limpio))
    if canon:
        return canon
    if limpio.islower() or limpio.isupper():
        return limpio.title()
    return limpio


# Tipo de prenda por palabra clave. El ORDEN IMPORTA: gana la primera que
# aparezca, así que las más específicas van arriba (una "campera de jean" es
# campera, no pantalón).
TIPOS = [
    ("Ropa interior", ("ropa interior", "boxer", "calzoncillo")),
    ("Conjuntos", ("conjunto", "traje deportivo")),
    ("Camperas", ("campera", "chaqueta", "rompeviento", "rompevientos",
                  "puffer", "abrigo", "parka", "camperon")),
    ("Buzos", ("buzo", "hoodie", "canguro", "sudadera", "sweater", "sweatshirt", "sweter", "sueter", "pulover")),
    ("Remeras", ("remera", "camiseta", "t-shirt", "tshirt", "musculosa", "playera")),
    ("Camisas", ("camisa",)),
    ("Pantalones", ("pantalon", "jogger", "jogging", "jean", "cargo", "babucha")),
    ("Shorts", ("short", "bermuda", "malla", "traje de baño")),
    ("Vestidos", ("vestido",)),
    ("Tops", ("top ", "crop", "corpiño")),
    ("Faldas", ("falda", "pollera")),
    ("Gorras", ("gorra", "visera")),
    ("Pilusos", ("piluso", "bucket", "sombrero")),
    ("Gorros", ("gorro", "beanie")),
    ("Ojotas", ("ojota", "chancleta", "sandalia", "slide")),
    ("Zapatillas", ("zapatilla", "sneaker", "botin", "calzado")),
    ("Morrales", ("morral", "mochila", "bolso", "cartera")),
    ("Riñoneras", ("riñonera", "rinonera", "banano")),
    ("Neceseres", ("neceser",)),
    ("Cintos", ("cinto", "cinturon")),
    ("Medias", ("medias",)),
    ("Lentes", ("lente", "anteojo", "gafas")),
    ("Relojes", ("reloj",)),
    ("Perfumes", ("perfume", "fragancia")),
]


def _sin_acentos(texto: str) -> str:
    t = unicodedata.normalize("NFKD", (texto or "").lower())
    return "".join(c for c in t if not unicodedata.combining(c))


def tipo_de_prenda(nombre: str | None) -> str | None:
    """Deduce el tipo desde el nombre del producto. None si no se reconoce."""
    if not nombre:
        return None
    n = _sin_acentos(nombre)
    for tipo, claves in TIPOS:
        if any(_sin_acentos(k) in n for k in claves):
            return tipo
    return None


def _slug(texto: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", _sin_acentos(texto)).strip("-") or "categoria"


def _handle_libre(db: Session, base: str) -> str:
    """Handle único para una categoría nueva (buzos, buzos1, buzos2…)."""
    handle, i = base, 0
    while db.query(Category).filter(Category.handle == handle).first():
        i += 1
        handle = f"{base}{i}"
    return handle


def asegurar_categoria(db: Session, marca: str, tipo: str) -> Category:
    """Devuelve (creando si hace falta) la categoría hija tipo-bajo-marca.

    Busca la marca comparando por nombre NORMALIZADO, así no se duplica el
    padre por una diferencia de mayúsculas o de guiones.
    """
    padres = db.query(Category).filter(Category.parent_id.is_(None)).all()
    padre = next((c for c in padres if _clave(c.name or "") == _clave(marca)), None)
    if not padre:
        padre = Category(name=marca, handle=_handle_libre(db, _slug(marca)))
        db.add(padre)
        db.flush()

    hijas = db.query(Category).filter(Category.parent_id == padre.id).all()
    hija = next((c for c in hijas if _clave(c.name or "") == _clave(tipo)), None)
    if not hija:
        hija = Category(name=tipo, handle=_handle_libre(db, _slug(tipo)),
                        parent_id=padre.id)
        db.add(hija)
        db.flush()
    return hija


def categorizar_producto(db: Session, producto: Product, forzar: bool = False) -> dict:
    """Normaliza la marca y asigna categoría al producto. NO hace commit.

    Con `forzar=False` respeta las categorías que ya tenga (solo completa lo
    que falta). Devuelve un dict con lo que cambió, para poder informarlo.
    """
    cambios: dict[str, str] = {}

    canon = marca_canonica(producto.brand)
    if canon and canon != (producto.brand or ""):
        cambios["marca"] = f"{producto.brand} -> {canon}"
        producto.brand = canon

    if producto.categories and not forzar:
        return cambios

    tipo = tipo_de_prenda(producto.name)
    if not producto.brand or not tipo:
        falta = []
        if not producto.brand:
            falta.append("marca")
        if not tipo:
            falta.append("tipo reconocible en el nombre")
        cambios["sin_categoria"] = "falta " + " y ".join(falta)
        return cambios

    cat = asegurar_categoria(db, producto.brand, tipo)
    if cat not in producto.categories:
        producto.categories = [cat]
        cambios["categoria"] = f"{tipo} / {producto.brand}"
    return cambios
