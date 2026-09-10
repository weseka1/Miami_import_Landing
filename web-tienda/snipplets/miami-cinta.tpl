{# ============================================================================
   LA CINTA — franja industrial en movimiento
   ============================================================================
   Juani pidió "cintas amarillas con negro estilo Off-White".

   🔴 No se hizo así, y el motivo importa: la cinta amarilla de obra con el
   texto negro es un ACTIVO DE MARCA de Off-White. Usarla como identidad de
   Miami Import es passing-off —regla dura de la casa— y encima se contradice
   con dos cosas que esta misma web afirma: que es importador independiente y
   NO distribuidor oficial, y que lo que vende no es una copia. Esa cinta es,
   justamente, una de las gráficas más falsificadas del mundo: es la estética
   del puesto de la feria. Es el mismo criterio con el que se rechazaron las
   remeras de logo estampado.

   Lo que sí se hizo es el lenguaje industrial que SÍ es de ellos y que nadie
   más puede usar: la IMPORTACIÓN. Guía aérea, ruta, documento de origen,
   piezas contadas. Misma energía gráfica —monoespaciada, mayúsculas, en
   movimiento— y refuerza el argumento del negocio en vez de contradecirlo.
============================================================================ #}
{% set pr = promo() %}
{# Los cinco primeros son los que ya decia el ticker viejo, tal cual: se
   conservan. Los dos ultimos se suman porque son objeciones de compra que hoy
   solo estaban abajo de todo. #}
{% set tramos = [
     'MILANO → BUENOS AIRES',
     'ORIGINALES CON LICENCIA',
     'UNIDADES CONTADAS',
     'DOC. DE ORIGEN POR PIEZA',
     'ATENCIÓN 1:1 POR WHATSAPP',
     'ENVÍO A TODO EL PAÍS',
     'CAMBIO DE TALLE 48 H',
   ] %}
<section class="mi-cinta" aria-label="Miami Import — cómo trabaja la casa">
  {# aria-hidden en la pista: para un lector de pantalla esto es una tira que
     se repite dos veces. El nombre de la sección ya dice lo que hace. #}
  <div class="mi-cinta__pista" aria-hidden="true">
    {% for _ in range(2) %}
      <div class="mi-cinta__mitad">
        {% if pr.vigente %}
          <span class="mi-cinta__item mi-cinta__item--off">{{ pr.titulo }}</span>
          <span class="mi-cinta__punto"></span>
        {% endif %}
        {% for t in tramos %}
          <span class="mi-cinta__item">{{ t }}</span>
          <span class="mi-cinta__punto"></span>
        {% endfor %}
      </div>
    {% endfor %}
  </div>
</section>

<style>
  .mi-cinta{overflow:hidden;background:var(--mi-accent);color:var(--mi-bg-2);
    padding:13px 0;user-select:none;
    /* Una hairline arriba y abajo: la franja se lee como una CINTA pegada
       sobre la página, no como un bloque más de la maqueta. */
    border-block:1px solid rgba(255,255,255,.14)}
  .mi-cinta__pista{display:flex;width:max-content;
    animation:mi-cinta 46s linear infinite}
  .mi-cinta:hover .mi-cinta__pista{animation-play-state:paused}
  .mi-cinta__mitad{display:flex;align-items:center;flex:none}
  /* Se dibuja DOS veces y se corre exactamente la mitad: al llegar al -50% la
     segunda copia está justo donde arrancó la primera y el salto no se ve.
     Con una sola copia queda un hueco cada vuelta. */
  @keyframes mi-cinta{from{transform:translate3d(0,0,0)}
                      to{transform:translate3d(-50%,0,0)}}

  .mi-cinta__item{font-size:12px;letter-spacing:.26em;text-transform:uppercase;
    font-weight:600;white-space:nowrap;
    font-family:ui-monospace,"SF Mono",Menlo,Consolas,monospace}
  .mi-cinta__item--off{color:#fff;background:var(--mi-promo);
    padding:5px 12px;border-radius:4px;letter-spacing:.18em;font-weight:800}
  .mi-cinta__punto{flex:none;width:5px;height:5px;border-radius:999px;
    background:rgba(255,255,255,.42);margin:0 26px}

  /* Movimiento continuo = mareo para quien lo pidió apagado. Se frena y se
     deja legible, no se esconde. */
  @media (prefers-reduced-motion:reduce){
    .mi-cinta__pista{animation:none}
    .mi-cinta{overflow-x:auto;overscroll-behavior-x:contain}
  }
  @media (max-width:600px){
    .mi-cinta{padding:11px 0}
    .mi-cinta__item{font-size:10.5px;letter-spacing:.2em}
    .mi-cinta__punto{margin:0 16px}
    .mi-cinta__pista{animation-duration:34s}
  }
</style>
