{# ============================================================
   MIAMI_IMPORT — MASTHEAD + DOSSIER DE ORIGEN
   Reemplaza a miami-hero-video.tpl.

   LA DECISIÓN: no hay foto atrás del texto. Ninguna.
   El hero es tipografía sobre papel. Las cuatro fotos de Milán bajan
   a una tira numerada, con epígrafe abajo (nunca encima), donde una
   foto de celular se lee como PRUEBA y no como campaña fallida.

   Por qué, en una línea: si no hay imagen atrás del texto, no existe
   el estado en que el texto es invisible. El bug del hero blanco no se
   arregla con un scrim más oscuro, se arregla sacando el texto de
   encima de la imagen.
   ============================================================ #}

<section class="mh" id="mi-hero" aria-labelledby="mh-claim">

  {# ---- fila 1: el claim + la ficha técnica ---- #}
  <div class="mh__row mh__row--top">
    <div class="mh__claim" id="mh-claim">
      {% if home.hero.eyebrow %}
      <p class="mh__eyebrow"><i aria-hidden="true"></i>{{ home.hero.eyebrow }}</p>
      {% endif %}
      {# El claim es identidad tipográfica, no contenido editable: va fijo
         para que el panel no pueda romper la composición con una frase
         larga. Lo que Diego edita (titulo/subtitulo) entra abajo. #}
      <h1 class="mh__display">
        <span class="mh__line mh__line--a">Una sola</span>
        <span class="mh__line mh__line--b">de cada</span>
        <span class="mh__line mh__line--c">prenda</span>
      </h1>
    </div>

    <dl class="mh__spec">
      <div class="mh__spec-row"><dt>Origen</dt><dd>Milán, Italia</dd></div>
      <div class="mh__spec-row"><dt>Compra</dt><dd>En tienda oficial, en persona</dd></div>
      <div class="mh__spec-row"><dt>Stock</dt><dd>Un talle por prenda</dd></div>
      <div class="mh__spec-row"><dt>Probador</dt><dd>Con una foto, en la web</dd></div>
    </dl>
  </div>

  {# ---- la línea que cruza el claim, a sangre completa ---- #}
  <div class="mh__rule" aria-hidden="true"></div>

  {# ---- fila 2: cierre del claim + lo editable + acciones ---- #}
  <div class="mh__row mh__row--bottom">
    <div class="mh__close">
      <div class="mh__cta">
        <a class="mh__btn mh__btn--solid"
           href="{{ home.hero.cta_link or store.products_url }}">
          {{ home.hero.cta_texto or 'Ver el catálogo' }}<span aria-hidden="true">→</span>
        </a>
        {% if home.hero.cta2_texto %}
        <a class="mh__btn mh__btn--ghost" target="_blank" rel="noopener"
           href="{{ home.hero.cta2_link or ('https://wa.me/5491162321391?text=' ~ ('Hola, quiero consultar por una pieza.' | urlencode)) }}">
          {{ home.hero.cta2_texto }}
        </a>
        {% endif %}
      </div>
    </div>

    <div class="mh__lead">
      {% if home.hero.titulo %}<p class="mh__lead-1">{{ home.hero.titulo }}</p>{% endif %}
      {% if home.hero.subtitulo %}<p class="mh__lead-2">{{ home.hero.subtitulo }}</p>{% endif %}
    </div>
  </div>
</section>

{# ============================================================
   DOSSIER — las cuatro fotos, en orden de viaje.
   Deslizable + flechas (nunca selector numérico). Epígrafe DEBAJO.
   ============================================================ #}
<section class="mh-doss" aria-labelledby="mh-doss-t">
  <div class="mh-doss__head">
    <p class="mh__eyebrow"><i aria-hidden="true"></i>El viaje</p>
    <h2 class="mh-doss__t" id="mh-doss-t">Las fotos son de Diego.</h2>
    <p class="mh-doss__d">No salieron de un banco de imágenes. Son del viaje
      en el que se compró la ropa que está en esta página.</p>
    <div class="mh-doss__nav">
      <button type="button" class="mh-doss__arrow" data-mh-prev aria-label="Foto anterior">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15 5 8 12l7 7"/></svg>
      </button>
      <button type="button" class="mh-doss__arrow" data-mh-next aria-label="Foto siguiente">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="m9 5 7 7-7 7"/></svg>
      </button>
    </div>
  </div>

  <div class="mh-doss__strip">
    <ul class="mh-doss__track" data-mh-track>
      {% for f in [
        {'src':'montenapoleone', 'n':'01', 't':'Via Montenapoleone', 'd':'La cuadra. Etro, Gucci, y lo que hay en la vidriera esa semana.'},
        {'src':'offwhite',       'n':'02', 't':'Boutique Off-White',  'd':'Adentro del local. Acá se compra la pieza, con ticket.'},
        {'src':'duomo',          'n':'03', 't':'Terraza de la Rinascente', 'd':'El Duomo desde arriba, entre una compra y la otra.'},
        {'src':'galleria',       'n':'04', 't':'Galleria Vittorio Emanuele II', 'd':'De noche, saliendo. Milán cierra tarde.'}
      ] %}
      <li class="mh-doss__item">
        <figure class="mh-doss__fig">
          <div class="mh-doss__media">
            <img src="{{ ('images/milano/' ~ f.src ~ '.webp') | static_url }}"
                 srcset="{{ ('images/milano/' ~ f.src ~ '@800.webp') | static_url }} 800w,
                         {{ ('images/milano/' ~ f.src ~ '.webp') | static_url }} 1600w"
                 sizes="(max-width:700px) 78vw, 30vw"
                 alt="{{ f.t }}, Milán" loading="lazy" decoding="async"/>
          </div>
          <figcaption class="mh-doss__cap">
            <span class="mh-doss__n">{{ f.n }}</span>
            <span class="mh-doss__ct">{{ f.t }}</span>
            <span class="mh-doss__cd">{{ f.d }}</span>
          </figcaption>
        </figure>
      </li>
      {% endfor %}
    </ul>
  </div>
</section>
<span id="mi-after-hero"></span>

<style>
/* ==========================================================================
   MASTHEAD — todo sobre tokens del DS (miami-ds.tpl). Cero color nuevo.
   ========================================================================== */
.mh{
  --mh-pad: clamp(20px, 5vw, 72px);
  --mh-max: 1440px;
  background: var(--mi-bg);
  /* Grid de sangre completa: la regla ocupa [full], el contenido [content].
     Todo queda contenido por el grid → 0px de overflow horizontal por
     construcción, sin usar 100vw (que incluye la scrollbar y desborda). */
  display: grid;
  grid-template-columns:
    [full-start] minmax(var(--mh-pad), 1fr)
    [content-start] minmax(0, var(--mh-max)) [content-end]
    minmax(var(--mh-pad), 1fr) [full-end];
  align-content: center;
  min-height: 62svh;                 /* svh, nunca vh: Safari mobile miente  */
  padding: clamp(28px, 6svh, 64px) 0 clamp(24px, 4svh, 44px);
  overflow: clip;
}
.mh__row{
  grid-column: content;
  display: grid;
  grid-template-columns: minmax(0, 1.55fr) minmax(0, .82fr);
  gap: clamp(20px, 4vw, 64px);
}
.mh__row--top{ align-items: start; }
.mh__row--bottom{ align-items: start; padding-top: clamp(18px, 2.6svh, 32px); }

/* ---- eyebrow ---- */
.mh__eyebrow{
  margin: 0 0 clamp(16px, 2.4svh, 26px);
  display: flex; align-items: center; gap: 14px;
  font-size: clamp(9.5px, .8vw, 11px); font-weight: 600;
  letter-spacing: .38em; text-transform: uppercase;
  color: var(--mi-ink-soft);
}
.mh__eyebrow i{
  width: clamp(22px, 4vw, 54px); height: 1px; flex: none;
  background: var(--mi-ink-mute);
}

/* ---- EL CLAIM: escalera tipográfica asimétrica ----
   Tres líneas, tres posiciones, DOS tamaños. La línea del medio es chica
   y está corrida a la derecha: es lo que rompe el bloque centrado que
   arma cualquier plantilla. */
.mh__display{
  margin: 0;
  font-weight: 700;
  text-transform: uppercase;
  color: var(--mi-ink);
  line-height: .82;
  letter-spacing: -.055em;   /* muy ceñido: las formas casi se tocan */
  /* el claim NUNCA parte: si una fuente del sistema mide más ancho que
     Arial, se achica sola en vez de romper la composición en dos renglones */
  overflow-wrap: normal; hyphens: none;
  display: flex; flex-direction: column;
}
.mh__line{ display: block; }
.mh__line--a,
.mh__line--c{ font-size: clamp(44px, 10.1vw, 164px); }
.mh__line--b{
  font-size: clamp(19px, 3.6vw, 54px);
  letter-spacing: -.02em;
  align-self: flex-start;
  /* el corrimiento: arranca donde termina, ópticamente, la "U" de arriba */
  margin-left: clamp(44px, 10.4vw, 158px);
  margin-top: clamp(3px, .7vw, 10px);
  /* en gris se leia "deshabilitado". En monocromo la jerarquia la hacen el
     tamano y la posicion, no un gris mas claro: va tinta plena. */
  color: var(--mi-ink);
}
.mh__line--c{ margin-top: clamp(4px, 1vw, 14px); }

/* ---- ficha técnica: registro documento ---- */
.mh__spec{
  /* alineada con la altura de mayuscula del claim, no con su base: si se
     cuelga abajo, el cuadrante superior derecho queda vacio. */
  margin: clamp(34px, 5svh, 62px) 0 0; align-self: start;
  border-top: 1px solid var(--mi-line-2);
}
.mh__spec-row{
  display: grid; grid-template-columns: minmax(84px, 34%) minmax(0, 1fr);
  gap: 14px; align-items: baseline;
  padding: clamp(9px, 1.3svh, 13px) 0;
  border-bottom: 1px solid var(--mi-line);
}
.mh__spec dt{
  font-size: 9.5px; font-weight: 600; letter-spacing: .26em;
  text-transform: uppercase; color: var(--mi-ink-soft);
  /* .44 daba 2,85:1 sobre papel (medido): a 9,5px se lava. .64 = 5,4:1 */
}
.mh__spec dd{
  margin: 0; font-size: clamp(12.5px, 1.05vw, 14px); line-height: 1.4;
  color: var(--mi-ink); font-variant-numeric: tabular-nums;
}

/* ---- la regla que cruza el claim, a sangre ---- */
.mh__rule{
  grid-column: full;
  height: 1px; background: var(--mi-ink);
  opacity: .22;
  margin: clamp(10px, 1.6svh, 20px) 0 0;
}

/* ---- cierre + acciones ---- */
.mh__cta{ display: flex; flex-wrap: wrap; gap: 10px; }
.mh__btn{
  display: inline-flex; align-items: center; justify-content: center; gap: 10px;
  min-height: 48px;                       /* target táctil ≥ 44px */
  padding: 14px 26px; border-radius: var(--mi-pill);
  font-size: 12px; font-weight: 600; letter-spacing: .14em;
  text-transform: uppercase; white-space: nowrap;
  border: 1px solid transparent;
  transition: background-color .4s var(--mi-ease), color .4s var(--mi-ease),
              border-color .4s var(--mi-ease), transform .4s var(--mi-ease);
}
.mh__btn--solid{
  background: var(--mi-ink); color: var(--mi-bg);
  box-shadow: var(--mi-shadow);
}
.mh__btn--solid:hover{ background: var(--mi-accent-2); transform: translateY(-2px); }
.mh__btn--solid span{ transition: transform .4s var(--mi-ease); }
.mh__btn--solid:hover span{ transform: translateX(4px); }
.mh__btn--ghost{
  color: var(--mi-ink); border-color: var(--mi-line-2);
  background: var(--mi-glass);
  -webkit-backdrop-filter: blur(var(--mi-blur)) saturate(180%);
          backdrop-filter: blur(var(--mi-blur)) saturate(180%);
}
.mh__btn--ghost:hover{ border-color: var(--mi-ink); transform: translateY(-2px); }
@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))){
  .mh__btn--ghost{ background: var(--mi-glass-strong); }
}

/* ---- lo editable desde el panel ---- */
.mh__lead{ padding-top: clamp(2px, .6svh, 8px); }
.mh__lead-1{
  margin: 0; max-width: 34ch; text-wrap: balance;
  font-size: clamp(15px, 1.35vw, 19px); line-height: 1.45;
  letter-spacing: -.01em; color: var(--mi-ink);
}
.mh__lead-2{
  margin: 10px 0 0; max-width: 34ch;
  font-size: clamp(13px, 1.05vw, 14.5px); line-height: 1.55;
  color: var(--mi-ink-soft);
}

/* ==========================================================================
   DOSSIER
   ========================================================================== */
.mh-doss{
  --mh-pad: clamp(20px, 5vw, 72px);
  background: var(--mi-bg);
  padding: clamp(48px, 8svh, 96px) 0 clamp(40px, 7svh, 88px);
  overflow: clip;
}
.mh-doss__head{
  max-width: 1440px; margin: 0 auto;
  padding: 0 var(--mh-pad) clamp(26px, 4svh, 44px);
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  grid-template-areas: "eye  nav" "tit nav" "des nav";
  align-items: end; column-gap: 24px;
}
.mh-doss__head .mh__eyebrow{ grid-area: eye; margin-bottom: 14px; }
.mh-doss__t{
  grid-area: tit; margin: 0;
  font-size: clamp(26px, 4vw, 52px); line-height: 1.02;
  letter-spacing: -.035em; text-transform: uppercase; font-weight: 700;
  color: var(--mi-ink);
}
.mh-doss__d{
  grid-area: des; margin: 12px 0 0; max-width: 46ch;
  font-size: clamp(13px, 1.1vw, 15px); line-height: 1.6; color: var(--mi-ink-soft);
}
.mh-doss__nav{ grid-area: nav; display: flex; gap: 8px; align-self: end; }
.mh-doss__arrow{
  width: 46px; height: 46px; flex: none;    /* ≥44px */
  display: grid; place-items: center;
  border-radius: var(--mi-pill); cursor: pointer;
  border: 1px solid var(--mi-line-2); color: var(--mi-ink);
  background: var(--mi-glass);
  -webkit-backdrop-filter: blur(var(--mi-blur)) saturate(180%);
          backdrop-filter: blur(var(--mi-blur)) saturate(180%);
  transition: border-color .35s var(--mi-ease), background-color .35s var(--mi-ease),
              opacity .35s var(--mi-ease);
}
.mh-doss__arrow svg{ width: 19px; height: 19px; fill: none; stroke: currentColor;
  stroke-width: 1.6; stroke-linecap: round; stroke-linejoin: round; }
.mh-doss__arrow:hover{ border-color: var(--mi-ink); }
.mh-doss__arrow[disabled]{ opacity: .3; cursor: default; }
/* si las 4 fotos entran en pantalla no hay nada que deslizar: las flechas
   no se quedan de adorno apagado, se van (lo pone el JS). */
.mh-doss__nav[hidden]{ display: none; }
@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))){
  .mh-doss__arrow{ background: var(--mi-glass-strong); }
}

/* la tira: full-bleed por padding en el track, nunca por 100vw */
.mh-doss__strip{ overflow: hidden; }
.mh-doss__track{
  list-style: none; margin: 0;
  padding: 0 var(--mh-pad) 6px;
  display: flex; gap: clamp(12px, 1.6vw, 22px);
  overflow-x: auto; overscroll-behavior-x: contain;
  scroll-snap-type: x mandatory; -webkit-overflow-scrolling: touch;
  scroll-padding-left: var(--mh-pad);
  scrollbar-width: none; -ms-overflow-style: none; cursor: grab;
}
.mh-doss__track::-webkit-scrollbar{ display: none; }
.mh-doss__track.is-grabbing{ cursor: grabbing; scroll-snap-type: none; }
@media (pointer: coarse){
  /* mandatory frena el impulso nativo en iOS: se siente trabado */
  .mh-doss__track{ scroll-snap-type: x proximity; cursor: default; }
}
.mh-doss__item{
  flex: 0 0 clamp(230px, 28vw, 380px);
  scroll-snap-align: start; min-width: 0;
}
@media (max-width: 700px){ .mh-doss__item{ flex-basis: 78vw; } }

.mh-doss__fig{ margin: 0; }
.mh-doss__media{
  aspect-ratio: 3 / 4;                     /* las 4 fotos son verticales 3:4 */
  overflow: hidden; border-radius: var(--mi-r);
  background: var(--mi-bg-3);              /* si la foto no cargó: bloque gris, nunca un hueco */
  border: 1px solid var(--mi-line);
}
.mh-doss__media img{
  width: 100%; height: 100%; object-fit: cover; display: block;
  transition: transform .8s var(--mi-ease);
}
.mh-doss__item:hover .mh-doss__media img{ transform: scale(1.035); }

/* epígrafe SIEMPRE debajo, sobre papel: contraste garantizado en todos los estados */
.mh-doss__cap{
  display: grid; grid-template-columns: auto minmax(0, 1fr);
  column-gap: 12px; row-gap: 4px; padding: 14px 2px 0;
  border-top: 1px solid var(--mi-line); margin-top: 14px;
}
.mh-doss__n{
  grid-row: 1 / span 2;
  font-size: 10px; font-weight: 600; letter-spacing: .18em;
  color: var(--mi-ink-soft); font-variant-numeric: tabular-nums;
  padding-top: 2px;
}
.mh-doss__ct{
  font-size: clamp(12px, 1vw, 13.5px); font-weight: 600;
  letter-spacing: .1em; text-transform: uppercase; color: var(--mi-ink);
}
.mh-doss__cd{
  font-size: clamp(12px, 1vw, 13px); line-height: 1.5; color: var(--mi-ink-soft);
}

/* ==========================================================================
   Entrada. Regla de la casa: NADA parkeado en opacity:0 esperando un
   observer. El estado inicial lo pone el JS (.is-anim) y hay timeout que
   fuerza el final pase lo que pase. Sin JS, todo se ve.
   ========================================================================== */
.mh.is-anim .mh__eyebrow,
.mh.is-anim .mh__line,
.mh.is-anim .mh__spec-row,
.mh.is-anim .mh__cta,
.mh.is-anim .mh__lead > *{
  opacity: 0; transform: translateY(16px);
}
.mh.is-anim.is-in .mh__eyebrow,
.mh.is-anim.is-in .mh__line,
.mh.is-anim.is-in .mh__spec-row,
.mh.is-anim.is-in .mh__cta,
.mh.is-anim.is-in .mh__lead > *{
  opacity: 1; transform: none;
  transition: opacity .8s var(--mi-ease), transform .8s var(--mi-ease);
}
.mh.is-anim.is-in .mh__line--a{ transition-delay: .04s; }
.mh.is-anim.is-in .mh__line--b{ transition-delay: .10s; }
.mh.is-anim.is-in .mh__line--c{ transition-delay: .16s; }
.mh.is-anim.is-in .mh__spec-row:nth-child(1){ transition-delay: .14s; }
.mh.is-anim.is-in .mh__spec-row:nth-child(2){ transition-delay: .19s; }
.mh.is-anim.is-in .mh__spec-row:nth-child(3){ transition-delay: .24s; }
.mh.is-anim.is-in .mh__spec-row:nth-child(4){ transition-delay: .29s; }
.mh.is-anim.is-in .mh__cta{ transition-delay: .26s; }
.mh.is-anim.is-in .mh__lead > *{ transition-delay: .30s; }

/* ==========================================================================
   MOBILE
   ========================================================================== */
@media (max-width: 860px){
  .mh{ min-height: auto; padding-top: clamp(24px, 4svh, 40px); }
  .mh__row--top,
  .mh__row--bottom{ grid-template-columns: minmax(0, 1fr); gap: 22px; }
  .mh__row--bottom{ padding-top: 20px; }
  .mh__spec{ border-top: 0; padding-bottom: 0; }
  /* en celu la ficha va al final: primero el claim, después la acción */
  .mh__row--top{ display: block; }
  .mh__spec{ margin-top: 26px; border-top: 1px solid var(--mi-line-2); }
  .mh__spec-row{ grid-template-columns: minmax(72px, 30%) minmax(0, 1fr); }
  .mh__btn{ flex: 1 1 auto; }
  .mh-doss__head{
    grid-template-columns: minmax(0, 1fr);
    grid-template-areas: "eye" "tit" "des" "nav";
  }
  .mh-doss__nav{ margin-top: 22px; justify-self: start; }
}
@media (max-width: 860px){
  /* en celu la columna es el ancho entero: el claim puede crecer */
  .mh__line--a, .mh__line--c{ font-size: min(14.2vw, 92px); }
  .mh__line--b{ font-size: min(5.6vw, 34px); margin-left: min(13.6vw, 88px); }
}

@media (prefers-reduced-motion: reduce){
  .mh.is-anim .mh__eyebrow,
  .mh.is-anim .mh__line,
  .mh.is-anim .mh__spec-row,
  .mh.is-anim .mh__cta,
  .mh.is-anim .mh__lead > *{
    opacity: 1 !important; transform: none !important; transition: none !important;
  }
  .mh__btn, .mh-doss__media img, .mh-doss__arrow{ transition: none !important; }
  .mh-doss__item:hover .mh-doss__media img{ transform: none; }
  .mh-doss__track{ scroll-behavior: auto; }
}
</style>

<script>
(function () {
  'use strict';

  /* ---- entrada del masthead ------------------------------------------
     El CSS no esconde nada por su cuenta: la clase .is-anim la pone este
     script. Si el script no corre, el hero se ve igual, completo. */
  var mh = document.getElementById('mi-hero');
  if (mh) {
    var quieto = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (!quieto) {
      mh.classList.add('is-anim');
      var entrar = function () { mh.classList.add('is-in'); };
      requestAnimationFrame(function () { requestAnimationFrame(entrar); });
      /* Red de seguridad: si el doble rAF no corre (pestaña de fondo,
         WebView raro), a los 700 ms se fuerza el estado final igual. */
      setTimeout(entrar, 700);
    }
  }

  /* ---- tira del dossier: deslizable + arrastre + flechas -------------- */
  var track = document.querySelector('[data-mh-track]');
  if (!track) return;
  var prev = document.querySelector('[data-mh-prev]');
  var next = document.querySelector('[data-mh-next]');

  function paso() {
    var item = track.querySelector('.mh-doss__item');
    if (!item) return track.clientWidth * 0.8;
    var gap = parseFloat(getComputedStyle(track).columnGap || '0') || 0;
    return item.getBoundingClientRect().width + gap;
  }
  function ir(dir) {
    track.scrollBy({ left: dir * paso(), behavior: 'smooth' });
  }
  if (prev) prev.addEventListener('click', function () { ir(-1); });
  if (next) next.addEventListener('click', function () { ir(1); });

  var nav = document.querySelector('.mh-doss__nav');
  function estado() {
    var max = track.scrollWidth - track.clientWidth;
    /* en desktop ancho las 4 entran: sin recorrido, las flechas se ocultan */
    if (nav) nav.hidden = max <= 2;
    if (prev) prev.disabled = track.scrollLeft <= 2;
    if (next) next.disabled = track.scrollLeft >= max - 2;
  }
  track.addEventListener('scroll', estado, { passive: true });
  window.addEventListener('resize', estado);
  estado();

  /* Arrastre con el mouse (Estándar WESEKA: se desliza con el mouse, no
     solo con la rueda). El listener va en el track, no en window. */
  var abajo = false, x0 = 0, s0 = 0, movio = 0;
  track.addEventListener('pointerdown', function (e) {
    if (e.pointerType === 'touch') return;      /* touch lo maneja el browser */
    abajo = true; movio = 0;
    x0 = e.clientX; s0 = track.scrollLeft;
    track.classList.add('is-grabbing');
  });
  track.addEventListener('pointermove', function (e) {
    if (!abajo) return;
    var d = e.clientX - x0;
    movio = Math.max(movio, Math.abs(d));
    track.scrollLeft = s0 - d;
    if (movio > 4) e.preventDefault();
  });
  function soltar() {
    if (!abajo) return;
    abajo = false;
    track.classList.remove('is-grabbing');
    estado();
  }
  track.addEventListener('pointerup', soltar);
  track.addEventListener('pointercancel', soltar);
  track.addEventListener('pointerleave', soltar);
  /* si se arrastró, el click que sigue no debe abrir nada */
  track.addEventListener('click', function (e) {
    if (movio > 4) { e.preventDefault(); e.stopPropagation(); }
  }, true);
})();
</script>
