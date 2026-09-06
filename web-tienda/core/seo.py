"""SEO, datos estructurados y contenido de marca de Miami Import.

Por qué un módulo de Python y no un `.tpl`:

1. **El JSON-LD se arma con `json.dumps`, no con Jinja.** Un `{{ }}` suelto
   dentro de un `<script type="application/ld+json">` con una comilla o un
   `</script>` en el nombre de un producto rompe el bloque entero — y rompe
   *en silencio*: la página se ve perfecta y Google no lee nada. Serializando
   desde Python el escapado lo hace la librería.
2. **Un solo lugar donde vive lo que la casa afirma.** El texto de cada marca,
   la ruta de compra, la política de cambio y quién es Diego Radio se escriben
   una vez acá y los usan la ficha, el listado, la página "Nosotros", el
   `llms.txt` y el sitemap. Antes de esto, cada plantilla afirmaba lo suyo.

🔴 Regla que no se toca: **Miami Import no es distribuidor oficial de ninguna
de estas marcas.** Es un importador independiente que compra en tienda. Todo el
texto de acá lo dice así. Escribir "distribuidor autorizado" o "representante
oficial" es publicidad engañosa y, con marcas de lujo, un problema legal real.
"""
from __future__ import annotations

import json
from decimal import Decimal
from typing import Any, Iterable

# --------------------------------------------------------------------------- #
# 1) La casa — datos verificados contra el código que ya está en producción
#    (mia.py: WhatsApp e Instagram; home_config.py: la ruta y los valores).
#    Nada de acá está inventado. Si algo no está escrito en el sistema, no se
#    afirma: es preferible una ficha más corta que un dato que Diego no dijo.
# --------------------------------------------------------------------------- #
NEGOCIO: dict[str, Any] = {
    "nombre": "Miami Import",
    "fundador": "Diego Radio",
    "instagram": "https://www.instagram.com/miamimport_/",
    "instagram_handle": "@miamimport_",
    "whatsapp": "5491162321391",
    "pais": "AR",
    "idioma": "es-AR",
    # La ruta tal cual la afirma la home ("Ruta verificada · Italia · Miami →
    # Buenos Aires, trazable"). No se agranda ni se achica acá.
    "ruta": "Italia · Miami → Buenos Aires",
    "envios": ("Entrega personal en CABA y GBA cercano, coordinada por WhatsApp. "
               "Al interior del país, por correo: 24 a 72 horas hábiles."),
    "pagos": ("Transferencia bancaria con descuento, efectivo en la entrega y "
              "tarjeta de crédito o débito directamente en la web."),
    "cambios": "Cambio de talle dentro de las 48 horas hábiles de recibida la pieza.",
    "encargos": ("Si la pieza que busca no está en el catálogo, se encarga: Diego "
                 "la busca en el viaje siguiente y confirma precio antes de comprarla."),
}

DESCRIPCION_CORTA = (
    "Indumentaria original de marcas europeas y americanas, comprada en tienda "
    "en Italia y traída a la Argentina. Catálogo chico, piezas contadas y "
    "atención directa por WhatsApp."
)

DESCRIPCION_LARGA = (
    "Miami Import es el proyecto de Diego Radio: viaja a Italia todos los meses, "
    "compra las piezas él mismo en tienda y las trae a Buenos Aires. No es una "
    "tienda de reventa mayorista ni un distribuidor oficial de las marcas que "
    "vende: es un importador independiente con un catálogo chico que rota rápido. "
    "Cada pieza viaja con su comprobante de origen, se puede pagar con tarjeta en "
    "la web y hay cambio de talle dentro de las 48 horas hábiles."
)


# --------------------------------------------------------------------------- #
# 2) Contenido por marca
#
#    Cada entrada tiene: título y meta para el buscador, dos párrafos de texto
#    real para la página, y una ficha corta con los datos de la casa.
#
#    Los párrafos NO son la misma plantilla rellenada 17 veces. Una página de
#    marca que dice lo mismo que las otras cambiando el nombre es exactamente
#    lo que Google llama "doorway page" y lo que un lector reconoce como texto
#    de IA. Cada una entra por un ángulo distinto.
#
#    Sobre los datos de las casas: sólo van los que no cambian (año, ciudad,
#    fundador, la prenda que las hizo conocidas). A propósito NO se nombra al
#    director creativo de ninguna: rotan cada dos o tres años y dejarían la
#    página desactualizada sin que nadie se entere.
# --------------------------------------------------------------------------- #
MARCAS: dict[str, dict[str, Any]] = {
    "balenciaga": {
        "nombre": "Balenciaga",
        "titulo": "Balenciaga original en Argentina",
        "meta": ("Balenciaga original en Argentina: buzos, remeras y zapatillas "
                 "compradas en tienda en Italia. Envío a todo el país, pago con "
                 "tarjeta y cambio de talle."),
        "fundada": "1917, San Sebastián. Casa en París desde 1937",
        "origen": "Francia",
        "conocida": "Siluetas oversize, la Triple S y el logo tipográfico",
        "parrafos": [
            "Cristóbal Balenciaga abrió su taller en San Sebastián en 1917 y "
            "mudó la casa a París en 1937. Hoy Balenciaga es una de las firmas "
            "que más cambió la forma de vestir de la última década: la silueta "
            "amplia, los hombros caídos y la zapatilla voluminosa que el resto "
            "del mercado terminó copiando salieron de acá.",
            "Lo que llega a Miami Import es la línea de todos los días —buzos, "
            "remeras, camperas y zapatillas—, comprada en tienda en Italia y "
            "traída pieza por pieza. Son unidades contadas: cuando un talle se "
            "va, no se repone salvo por encargo. Si busca algo puntual, "
            "escríbanos por WhatsApp con el modelo y el talle y se lo buscamos "
            "en el viaje siguiente.",
        ],
    },
    "off-white": {
        "nombre": "Off-White",
        "titulo": "Off-White original en Argentina",
        "meta": ("Off-White original en Argentina: remeras, buzos y accesorios "
                 "traídos de Italia. Comprá con tarjeta, envío a todo el país."),
        "fundada": "2012, Milán. Fundada por Virgil Abloh",
        "origen": "Italia",
        "conocida": "Las rayas diagonales, las comillas y las flechas",
        "parrafos": [
            "Virgil Abloh fundó Off-White en Milán en 2012 y le dio a la moda de "
            "lujo un vocabulario que hasta entonces era de la calle: las rayas "
            "diagonales del piso de una obra, la cinta industrial amarilla, las "
            "comillas alrededor de una palabra cualquiera. Es la marca que puso "
            "el streetwear adentro de las vidrieras de la via Montenapoleone.",
            "En el catálogo entran sobre todo remeras y buzos, que es donde el "
            "código gráfico de la casa se lee de una. Se compran en tienda en "
            "Italia y viajan con su comprobante de origen. Antes de comprar "
            "puede probarse la pieza en la web con el probador virtual, que le "
            "muestra cómo le queda con una foto suya.",
        ],
    },
    "hugo-boss": {
        "nombre": "Hugo Boss",
        "titulo": "Hugo Boss original en Argentina",
        "meta": ("Hugo Boss original en Argentina: remeras, buzos y camisas "
                 "importadas. Envío a todo el país y cambio de talle asegurado."),
        "fundada": "1924, Metzingen (Alemania)",
        "origen": "Alemania",
        "conocida": "Sastrería y prendas de logo limpio",
        "parrafos": [
            "Hugo Boss nació en Metzingen, en el sur de Alemania, en 1924. Es la "
            "casa alemana de sastrería más conocida del mundo y desde hace años "
            "convive en dos líneas: BOSS, la formal y de corte clásico, y HUGO, "
            "más joven y más cerca del logo.",
            "Es la marca que más se pide para vestir de civil sin disfrazarse: "
            "una remera o un buzo con el logo chico, en negro o en blanco, que "
            "entra en cualquier lado. Todo lo que ve publicado está físicamente "
            "en Buenos Aires y sale con envío en el día siguiente hábil.",
        ],
    },
    "emporio-armani": {
        "nombre": "Emporio Armani",
        "titulo": "Emporio Armani original en Argentina",
        "meta": ("Emporio Armani original en Argentina, comprado en tienda en "
                 "Italia. Remeras, buzos y camperas con envío a todo el país."),
        "fundada": "1981, Milán. Línea de Giorgio Armani",
        "origen": "Italia",
        "conocida": "El águila del logo y el corte italiano",
        "parrafos": [
            "Giorgio Armani lanzó Emporio Armani en Milán en 1981 como la línea "
            "de todos los días de la casa: el mismo corte italiano y la misma "
            "sobriedad, en prendas para usar y no para guardar. El águila del "
            "escudo es de las pocas insignias de lujo que se reconocen de lejos "
            "sin que la marca esté escrita.",
            "Es la casa italiana con más presencia en el catálogo, porque es la "
            "que mejor se consigue en el circuito de tiendas que Diego recorre "
            "cada mes en Milán. Si busca un talle que no aparece publicado, "
            "escríbanos: hay reposición por encargo con confirmación de precio "
            "antes de comprar.",
        ],
    },
    "diesel": {
        "nombre": "Diesel",
        "titulo": "Diesel original en Argentina",
        "meta": ("Diesel original en Argentina: remeras, buzos, camperas y jeans "
                 "traídos de Italia. Pago con tarjeta y envío a todo el país."),
        "fundada": "1978, Molvena (Italia). Fundada por Renzo Rosso",
        "origen": "Italia",
        "conocida": "El denim tratado y el logo grande",
        "parrafos": [
            "Renzo Rosso fundó Diesel en 1978 en Molvena, en el Véneto, y se "
            "hizo un lugar haciendo con el denim lo que nadie hacía: lavarlo, "
            "romperlo, gastarlo a propósito. De ahí salió una estética que hoy "
            "vuelve cada temporada y que la marca terminó llevando también a "
            "remeras, buzos y camperas.",
            "Es la marca con más piezas y más talles del catálogo, y por lejos "
            "la que más rota. Conviene mirar el listado seguido: lo que entra "
            "un lunes puede no estar el viernes, y la reposición es sólo por "
            "pedido.",
        ],
    },
    "palm-angels": {
        "nombre": "Palm Angels",
        "titulo": "Palm Angels original en Argentina",
        "meta": ("Palm Angels original en Argentina: buzos, remeras y conjuntos "
                 "importados de Italia. Envío a todo el país."),
        "fundada": "2015, Milán. Fundada por Francesco Ragazzi",
        "origen": "Italia",
        "conocida": "El skate de Los Ángeles contado desde Milán",
        "parrafos": [
            "Palm Angels empezó en 2015 como un libro de fotos: Francesco "
            "Ragazzi retrató durante años a los skaters de Los Ángeles y "
            "terminó convirtiendo esas imágenes en una marca italiana. Esa "
            "mezcla —el skate californiano hecho en Italia— es toda su "
            "identidad, y se nota en el tiro de los pantalones y en los "
            "conjuntos de jogging.",
            "En Miami Import entran sobre todo buzos y conjuntos. Son de las "
            "piezas más buscadas del catálogo y las que menos duran, así que "
            "conviene consultar por talle antes de que se agote.",
        ],
    },
    "amiri": {
        "nombre": "Amiri",
        "titulo": "Amiri original en Argentina",
        "meta": ("Amiri original en Argentina, traído de Italia. Piezas contadas, "
                 "envío a todo el país y cambio de talle."),
        "fundada": "2014, Los Ángeles. Fundada por Mike Amiri",
        "origen": "Estados Unidos",
        "conocida": "El denim roto a mano y el acabado artesanal",
        "parrafos": [
            "Mike Amiri arrancó cosiendo prendas a mano para músicos de Los "
            "Ángeles y en 2014 le puso nombre de marca. Es de las casas nuevas "
            "más caras del mercado por una razón concreta: el trabajo sobre el "
            "denim —los rotos, los parches, las costuras— se hace pieza por "
            "pieza y no sale de una máquina.",
            "Por precio y por disponibilidad, Amiri llega en cantidades muy "
            "chicas: casi siempre son una o dos unidades por modelo. Si le "
            "interesa una pieza, consúltela el mismo día.",
        ],
    },
    "balmain": {
        "nombre": "Balmain",
        "titulo": "Balmain original en Argentina",
        "meta": ("Balmain original en Argentina: remeras y buzos comprados en "
                 "tienda en Italia. Pago con tarjeta y envío a todo el país."),
        "fundada": "1945, París. Fundada por Pierre Balmain",
        "origen": "Francia",
        "conocida": "Los botones dorados y la estructura de los hombros",
        "parrafos": [
            "Pierre Balmain abrió su casa en París en 1945, en plena "
            "reconstrucción, y definió una silueta que la firma no soltó nunca: "
            "hombros marcados, cintura ajustada y una idea de vestir que tiene "
            "más de militar que de romántico.",
            "Lo que llega acá es la línea de logo —remeras y buzos con el "
            "monograma de la casa—, en tiradas cortas. Es de las marcas donde "
            "más conviene el encargo: si sabe el modelo exacto, se busca en el "
            "viaje siguiente.",
        ],
    },
    "calvin-klein": {
        "nombre": "Calvin Klein",
        "titulo": "Calvin Klein original en Argentina",
        "meta": ("Calvin Klein original en Argentina: remeras, buzos y ropa "
                 "interior importada. Envío a todo el país."),
        "fundada": "1968, Nueva York",
        "origen": "Estados Unidos",
        "conocida": "El logo de la cintura y el minimalismo americano",
        "parrafos": [
            "Calvin Klein se fundó en Nueva York en 1968 y es probablemente la "
            "marca que mejor entendió que un logo puede ser una prenda entera. "
            "El elástico de la cintura con el nombre escrito es uno de los "
            "objetos de diseño más reproducidos del siglo pasado.",
            "Es la entrada más accesible del catálogo y la que se lleva la "
            "gente que compra por primera vez. Prendas simples, en negro, "
            "blanco y gris, que no pasan de moda ni se discuten.",
        ],
    },
    "supreme": {
        "nombre": "Supreme",
        "titulo": "Supreme original en Argentina",
        "meta": ("Supreme original en Argentina, traído del exterior. Piezas "
                 "contadas, envío a todo el país y atención por WhatsApp."),
        "fundada": "1994, Nueva York",
        "origen": "Estados Unidos",
        "conocida": "El box logo y las entregas semanales agotadas",
        "parrafos": [
            "Supreme abrió en 1994 como un local de skate en el Soho y terminó "
            "inventando la lógica que hoy usa toda la industria: entregas "
            "chicas, un día fijo por semana, y todo agotado en minutos. El "
            "recuadro rojo con el nombre en blanco es de las tres o cuatro "
            "imágenes más reconocibles de la ropa contemporánea.",
            "Es la marca más difícil de conseguir de todo el catálogo, "
            "justamente porque nunca hay stock corriente: lo que entra, entra "
            "de a una pieza. Si ve algo publicado, está.",
        ],
    },
    "prada": {
        "nombre": "Prada",
        "titulo": "Prada original en Argentina",
        "meta": ("Prada original en Argentina, comprado en tienda en Italia. "
                 "Piezas contadas, envío a todo el país."),
        "fundada": "1913, Milán. Fundada por Mario Prada",
        "origen": "Italia",
        "conocida": "El nylon Re-Nylon y el triángulo de metal",
        "parrafos": [
            "Prada abrió en 1913 en la Galleria Vittorio Emanuele II de Milán "
            "vendiendo baúles y artículos de cuero. Su giro más importante no "
            "fue una prenda sino un material: el nylon técnico, que la casa "
            "convirtió en objeto de lujo cuando nadie lo tomaba en serio.",
            "Llega en cantidades muy chicas y casi siempre por encargo. Si "
            "busca una pieza puntual de Prada, lo más rápido es escribirle a "
            "Diego con la referencia antes del viaje.",
        ],
    },
    "givenchy": {
        "nombre": "Givenchy",
        "titulo": "Givenchy original en Argentina",
        "meta": ("Givenchy original en Argentina, traído de Italia. Piezas "
                 "contadas con envío a todo el país."),
        "fundada": "1952, París. Fundada por Hubert de Givenchy",
        "origen": "Francia",
        "conocida": "La 4G y el corte limpio de la casa",
        "parrafos": [
            "Hubert de Givenchy abrió su casa en París en 1952 con una idea "
            "poco común para la época: separar la línea de alta costura de una "
            "línea lista para usar. Esa segunda decisión es la que hoy hace que "
            "una remera de la casa siga teniendo el corte de un traje.",
            "En el catálogo aparece de a poco y siempre en unidades sueltas. "
            "Consulte disponibilidad por WhatsApp antes de decidir el talle.",
        ],
    },
    "louis-vuitton": {
        "nombre": "Louis Vuitton",
        "titulo": "Louis Vuitton original en Argentina",
        "meta": ("Louis Vuitton original en Argentina, traído del exterior. "
                 "Piezas contadas y atención directa por WhatsApp."),
        "fundada": "1854, París",
        "origen": "Francia",
        "conocida": "El monograma y la marroquinería de viaje",
        "parrafos": [
            "Louis Vuitton empezó en 1854 haciendo baúles de viaje planos —una "
            "idea nueva entonces, porque permitían apilarlos— y el monograma "
            "apareció recién en 1896, como defensa contra las copias. Es, en "
            "los hechos, el primer logotipo antifalsificación de la historia de "
            "la moda.",
            "Es la casa más pedida y la más difícil de traer. Trabaja "
            "exclusivamente por encargo con seña: se confirma la pieza, el "
            "precio y la fecha del viaje antes de que usted ponga un peso.",
        ],
    },
    "michael-kors": {
        "nombre": "Michael Kors",
        "titulo": "Michael Kors original en Argentina",
        "meta": ("Michael Kors original en Argentina: carteras y accesorios "
                 "importados. Envío a todo el país y pago con tarjeta."),
        "fundada": "1981, Nueva York",
        "origen": "Estados Unidos",
        "conocida": "La marroquinería y el lujo americano de uso diario",
        "parrafos": [
            "Michael Kors fundó su marca en Nueva York en 1981 apuntando a algo "
            "que en ese momento casi no existía: lujo americano para usar todos "
            "los días, sin la solemnidad de las casas europeas. Las carteras son "
            "su producto insignia y lo que sostiene la marca hasta hoy.",
            "Es lo que más se regala del catálogo. Si es para una fecha, "
            "avísenos con tiempo y coordinamos la entrega para el día.",
        ],
    },
    "casablanca": {
        "nombre": "Casablanca",
        "titulo": "Casablanca original en Argentina",
        "meta": ("Casablanca original en Argentina, traído de Italia. Piezas "
                 "contadas con envío a todo el país."),
        "fundada": "2018, París. Fundada por Charaf Tajer",
        "origen": "Francia",
        "conocida": "Los estampados de club y la seda",
        "parrafos": [
            "Casablanca es de las casas más nuevas del catálogo: Charaf Tajer "
            "la fundó en París en 2018 con una idea muy definida —el imaginario "
            "de los clubes de tenis y las Rivieras de los años setenta, en seda "
            "y en colores que ninguna otra marca se anima a usar.",
            "Entra en tiradas cortas y se agota rápido, sobre todo en verano. "
            "Si busca un modelo específico, el encargo es el camino.",
        ],
    },
    "loewe": {
        "nombre": "Loewe",
        "titulo": "Loewe original en Argentina",
        "meta": ("Loewe original en Argentina, traído de Europa. Piezas "
                 "contadas y atención directa por WhatsApp."),
        "fundada": "1846, Madrid",
        "origen": "España",
        "conocida": "El cuero y el anagrama de las cuatro L",
        "parrafos": [
            "Loewe se fundó en Madrid en 1846 como un taller de cuero, lo que "
            "la convierte en la casa más antigua de todo el catálogo. Es "
            "también la única española, y la marroquinería sigue siendo el "
            "corazón de la marca casi dos siglos después.",
            "Llega de a una pieza y casi siempre por pedido. Consulte "
            "disponibilidad antes de reservar.",
        ],
    },
    # Emestudios no es una casa histórica y no hay datos públicos que se puedan
    # afirmar. Antes que inventarle una fundación y una ciudad —que es
    # exactamente el error que se comete cuando se rellena una plantilla— la
    # ficha va vacía y el texto habla sólo de lo que sí sabemos: cómo llega.
    "emestudios": {
        "nombre": "Emestudios",
        "titulo": "Emestudios en Miami Import",
        "meta": ("Emestudios en Miami Import: piezas importadas con envío a "
                 "todo el país y cambio de talle."),
        "parrafos": [
            "Emestudios entra en el catálogo por la misma vía que el resto: "
            "compra en tienda, viaje y comprobante de origen. Es de las líneas "
            "con mejor relación entre precio y calidad de tela de todo el "
            "listado.",
            "Se puede pagar con tarjeta en la web y hay cambio de talle dentro "
            "de las 48 horas hábiles de recibida la pieza.",
        ],
    },
}


def marca_de(handle: str | None) -> dict[str, Any] | None:
    """Contenido de marca para un handle de categoría (`off-white`, `diesel`…)."""
    if not handle:
        return None
    return MARCAS.get(handle.strip().lower())


# --------------------------------------------------------------------------- #
# 3) Preguntas frecuentes
#
#    Sirven a dos públicos a la vez y por eso están acá y no sueltas en una
#    plantilla: son las que un comprador escribe en Google ("¿es original?",
#    "¿mandan al interior?") y son, textualmente, lo que un asistente de IA lee
#    para contestar cuando alguien le pregunta por Miami Import.
#
#    Las respuestas salen de mia.py y home_config.py — la misma información que
#    da el bot en el chat. Si mañana cambia la política de envíos hay que
#    tocar los dos lugares; están enlazados por este comentario a propósito.
# --------------------------------------------------------------------------- #
FAQ: list[tuple[str, str]] = [
    ("¿La ropa de Miami Import es original?",
     "Sí. Cada pieza se compra en tienda en el exterior y viaja con su "
     "comprobante de origen. Miami Import es un importador independiente: "
     "no es distribuidor oficial ni representante de las marcas que vende."),
    ("¿De dónde traen la ropa?",
     f"De Italia. Diego Radio viaja todos los meses, compra él mismo en tienda "
     f"y la mercadería entra por la ruta {NEGOCIO['ruta']}."),
    ("¿Hacen envíos a todo el país?",
     NEGOCIO["envios"]),
    ("¿Se puede pagar con tarjeta de crédito?",
     NEGOCIO["pagos"]),
    ("¿Y si no me queda el talle?",
     NEGOCIO["cambios"]),
    ("¿Hacen pedidos de una pieza que no está en el catálogo?",
     NEGOCIO["encargos"]),
    ("¿Puedo ver cómo me queda antes de comprar?",
     "Sí. La web tiene un probador virtual: sube una foto suya y la prenda se "
     "renderiza encima para ver cómo le queda antes de decidir el talle."),
    ("¿Dónde queda Miami Import?",
     "No hay local a la calle. La venta es online y la entrega es personal en "
     "CABA y Gran Buenos Aires, coordinada por WhatsApp, o por correo al resto "
     "del país."),
]


# --------------------------------------------------------------------------- #
# 4) JSON-LD
# --------------------------------------------------------------------------- #
def _limpio(d: dict[str, Any]) -> dict[str, Any]:
    """Saca las claves vacías.

    Un `"price": null` en un Offer no es "no sé el precio": Google lo lee como
    dato inválido e invalida el bloque completo. Se omite la clave y listo.
    """
    return {k: v for k, v in d.items() if v not in (None, "", [], {})}


def grafo_sitio(base: str) -> list[dict[str, Any]]:
    """Organization + WebSite + Person, con `@id` estables.

    Los `@id` (`#tienda`, `#sitio`, `#diego`) son lo que permite que la ficha
    de un producto diga "el vendedor es *ese* de allá" en vez de repetir los
    datos de la tienda en cada página. Sin ellos Google ve una organización
    nueva por página y no consolida nada.
    """
    org = _limpio({
        "@type": "OnlineStore",
        "@id": f"{base}/#tienda",
        "name": NEGOCIO["nombre"],
        "url": f"{base}/",
        "logo": f"{base}/static/images/miami-logo-v4.webp",
        "image": f"{base}/static/images/miami-logo-v4.webp",
        "description": DESCRIPCION_CORTA,
        "founder": {"@id": f"{base}/#diego"},
        "sameAs": [NEGOCIO["instagram"]],
        "areaServed": {"@type": "Country", "name": "Argentina"},
        "currenciesAccepted": "ARS",
        "paymentAccepted": "Tarjeta de crédito, tarjeta de débito, transferencia bancaria, efectivo",
        "contactPoint": [{
            "@type": "ContactPoint",
            "contactType": "customer service",
            "telephone": f"+{NEGOCIO['whatsapp']}",
            "availableLanguage": ["Spanish"],
            "areaServed": "AR",
        }],
    })

    persona = _limpio({
        "@type": "Person",
        "@id": f"{base}/#diego",
        "name": NEGOCIO["fundador"],
        "jobTitle": "Fundador de Miami Import",
        "description": (
            "Diego Radio es el fundador de Miami Import. Viaja a Italia todos "
            "los meses para comprar en tienda la indumentaria original que "
            "después vende en la Argentina, y atiende personalmente a cada "
            "cliente por WhatsApp."),
        "worksFor": {"@id": f"{base}/#tienda"},
        "url": f"{base}/nosotros",
        "sameAs": [NEGOCIO["instagram"]],
        "knowsAbout": [
            "Indumentaria de lujo importada",
            "Compra en tienda en Italia",
            "Importación de indumentaria a la Argentina",
        ],
    })

    sitio = _limpio({
        "@type": "WebSite",
        "@id": f"{base}/#sitio",
        "url": f"{base}/",
        "name": NEGOCIO["nombre"],
        "inLanguage": NEGOCIO["idioma"],
        "publisher": {"@id": f"{base}/#tienda"},
        # Caja de búsqueda en el resultado de Google: lleva directo al buscador
        # de la tienda en vez de a la home.
        "potentialAction": {
            "@type": "SearchAction",
            "target": {"@type": "EntryPoint",
                       "urlTemplate": f"{base}/buscar?q={{search_term_string}}"},
            "query-input": "required name=search_term_string",
        },
    })
    return [org, persona, sitio]


def migas(base: str, tramos: Iterable[tuple[str, str | None]]) -> dict[str, Any]:
    """BreadcrumbList. `tramos` = [(nombre, url_relativa_o_None), …].

    El último tramo va sin URL a propósito: es la página en la que se está.
    """
    items = []
    for i, (nombre, ruta) in enumerate(tramos, start=1):
        it: dict[str, Any] = {"@type": "ListItem", "position": i, "name": nombre}
        if ruta:
            it["item"] = f"{base}{ruta}"
        items.append(it)
    return {"@type": "BreadcrumbList", "itemListElement": items}


def _precio(valor: Decimal | float | None) -> str | None:
    """Precio como string con dos decimales, que es como lo quiere schema.org."""
    if valor is None:
        return None
    return f"{Decimal(str(valor)):.2f}"


def jsonld_producto(prod, base: str, imagenes: list[str]) -> dict[str, Any]:
    """Product + Offer de una ficha.

    Sin `aggregateRating` ni `review`: no hay reseñas reales cargadas y
    inventarlas es, además de mentira, una violación de las políticas de datos
    estructurados que puede costar todas las fichas del sitio.
    """
    precio = _precio(prod.min_price)
    sku = next((v.sku for v in prod.variants if v.sku), None)
    talles = [v.value for v in prod.variants if v.value and (v.stock or 0) > 0]

    oferta = _limpio({
        "@type": "Offer",
        "url": f"{base}/productos/{prod.handle}/",
        "priceCurrency": "ARS",
        "price": precio,
        "availability": ("https://schema.org/InStock" if prod.total_stock > 0
                         else "https://schema.org/OutOfStock"),
        "itemCondition": "https://schema.org/NewCondition",
        "seller": {"@id": f"{base}/#tienda"},
    }) if precio else None

    return _limpio({
        "@context": "https://schema.org",
        "@type": "Product",
        "@id": f"{base}/productos/{prod.handle}/#producto",
        "name": prod.name,
        "sku": sku or f"MI-{prod.id}",
        "url": f"{base}/productos/{prod.handle}/",
        "image": imagenes,
        "description": (prod.seo_description or
                        f"{prod.name} original de {prod.brand or NEGOCIO['nombre']}, "
                        f"importado y disponible en la Argentina."),
        "brand": {"@type": "Brand", "name": prod.brand} if prod.brand else None,
        "category": ", ".join(c.name for c in prod.categories if c.name) or None,
        "size": talles or None,
        "offers": oferta,
    })


def jsonld_listado(base: str, titulo: str, ruta: str, productos, descripcion: str = "",
                   tope: int = 30) -> dict[str, Any]:
    """CollectionPage + ItemList de un listado (marca, tipo o catálogo).

    Tope de 30: la lista es una señal de qué hay en la página, no un volcado
    del catálogo. Mandar 237 items infla el HTML sin que Google use ninguno.
    """
    items = [{"@type": "ListItem", "position": i,
              "url": f"{base}/productos/{p.handle}/", "name": p.name}
             for i, p in enumerate(productos[:tope], start=1)]
    return _limpio({
        "@context": "https://schema.org",
        "@type": "CollectionPage",
        "@id": f"{base}{ruta}#coleccion",
        "name": titulo,
        "url": f"{base}{ruta}",
        "description": descripcion or None,
        "isPartOf": {"@id": f"{base}/#sitio"},
        "mainEntity": {"@type": "ItemList",
                       "numberOfItems": len(productos),
                       "itemListElement": items},
    })


def jsonld_faq(preguntas: list[tuple[str, str]]) -> dict[str, Any]:
    return {
        "@context": "https://schema.org",
        "@type": "FAQPage",
        "mainEntity": [
            {"@type": "Question", "name": p,
             "acceptedAnswer": {"@type": "Answer", "text": r}}
            for p, r in preguntas
        ],
    }


def serializar(piezas: Iterable[dict[str, Any]] | None) -> str:
    """Todas las piezas de una página en UN solo `<script type="ld+json">`.

    Van juntas bajo `@graph` a propósito, no en cinco bloques sueltos: así los
    `@id` se resuelven entre sí (la oferta de un producto puede decir "el
    vendedor es #tienda" y Google sabe de quién habla) y queda un solo
    `@context` en vez de uno por bloque.

    🔴 El reemplazo de `<` no es decoración. Si el nombre de un producto trajera
    `</script>`, el navegador cerraría el bloque ahí y el resto del JSON se
    dibujaría como texto suelto en el medio de la página. `\\u003C` es la forma
    canónica de evitarlo y cualquier parser de JSON lo lee igual.
    """
    grafo = [dict(p) for p in (piezas or []) if p]
    if not grafo:
        return ""
    for p in grafo:                       # el @context va una sola vez, arriba
        p.pop("@context", None)
    dato = {"@context": "https://schema.org", "@graph": grafo}
    return (json.dumps(dato, ensure_ascii=False, separators=(",", ":"))
            .replace("<", "\\u003C"))


# --------------------------------------------------------------------------- #
# 5) llms.txt — la ficha que leen los asistentes de IA
#
#    No es un estándar cerrado todavía, pero ChatGPT, Claude y Perplexity ya lo
#    buscan y es texto plano: cuesta cero y evita que una IA describa el negocio
#    a partir de lo que adivina del HTML.
# --------------------------------------------------------------------------- #
def llms_txt(base: str) -> str:
    marcas = ", ".join(m["nombre"] for m in MARCAS.values())
    faq = "\n".join(f"### {p}\n{r}\n" for p, r in FAQ)
    return f"""# Miami Import

> {DESCRIPCION_CORTA}

## Quién es
{DESCRIPCION_LARGA}

- **Fundador:** {NEGOCIO['fundador']}
- **Instagram:** {NEGOCIO['instagram_handle']} ({NEGOCIO['instagram']})
- **WhatsApp:** +{NEGOCIO['whatsapp']}
- **Ruta de importación:** {NEGOCIO['ruta']}
- **Opera en:** Argentina (venta online, sin local a la calle)

## Marcas del catálogo
{marcas}

Miami Import **no es distribuidor oficial** de estas marcas. Compra las piezas
en tienda en el exterior y las importa de forma independiente.

## Cómo comprar
1. Elegir la pieza en {base}/productos
2. Probarla con el probador virtual (opcional)
3. Pagar con tarjeta en la web, o coordinar transferencia o efectivo por WhatsApp

## Preguntas frecuentes
{faq}
## Páginas
- [Catálogo completo]({base}/productos)
- [Quiénes somos]({base}/nosotros)
- [Buscador]({base}/buscar)
"""
