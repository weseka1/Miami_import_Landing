{# ============================================================
   MIAMI_IMPORT — HERO "EL VIAJE"

   Reemplaza al hero de video (Balenciaga, oscuro). Dos razones:
   1. Al pasar la web a clara, el texto blanco sobre el video quedó ilegible.
   2. El video era stock de marca. Las fotos de Diego en Milán son lo único
      que ningún competidor puede copiar — y son la prueba de que la prenda
      es original comprada en tienda oficial, que es LA objeción del rubro.

   La debilidad de esas fotos (celular, sin producción) se declara en el pie
   y así juega a favor: "FOTOS DEL VIAJE. SIN PRODUCCIÓN." Retocarlas seria
   perder exactamente lo que las hace creíbles.

   Textos editables desde el panel (Mi web → Portada); si están vacíos usa
   los de fábrica, que ya son los definitivos.
   ============================================================ #}
{% set _slides = [
  {'src': 'images/milano/montenapoleone.webp', 'small': 'images/milano/montenapoleone@800.webp',
   'lugar': 'Via Montenapoleone, Milán', 'pie': 'La cuadra de las boutiques.'},
  {'src': 'images/milano/offwhite.webp', 'small': 'images/milano/offwhite@800.webp',
   'lugar': 'Off-White, Milán', 'pie': 'Adentro de la tienda oficial.'},
  {'src': 'images/milano/duomo.webp', 'small': 'images/milano/duomo@800.webp',
   'lugar': 'Duomo, desde la Rinascente', 'pie': 'Donde arranca cada viaje.'},
  {'src': 'images/milano/galleria.webp', 'small': 'images/milano/galleria@800.webp',
   'lugar': 'Galleria Vittorio Emanuele II', 'pie': 'Cierra tarde. Nosotros también.'}
] %}

<section class="mh" id="mi-hero" aria-label="Miami Import — indumentaria original comprada en Milán">
  <div class="mh__wrap">

    {# ---------- COLUMNA FOTO ---------- #}
    <div class="mh__media">
      <div class="mh__stage" data-mh-stage>
        {% for s in _slides %}
        <figure class="mh__slide{% if loop.first %} is-on{% endif %}" data-mh-slide="{{ loop.index0 }}">
          <img src="{{ s.src | static_url }}"
               srcset="{{ s.small | static_url }} 800w, {{ s.src | static_url }} 960w"
               sizes="(max-width: 900px) 92vw, 46vw"
               alt="{{ s.lugar }}" width="960" height="1280"
               {% if loop.first %}fetchpriority="high"{% else %}loading="lazy"{% endif %}/>
          <figcaption class="mh__place u-glass">
            <span class="mh__place-pin" aria-hidden="true"></span>
            <span><b>{{ s.lugar }}</b>{{ s.pie }}</span>
          </figcaption>
        </figure>
        {% endfor %}

        {# Deslizable + flechas. Nunca selectores numéricos (regla de la casa). #}
        <div class="mh__arrows">
          <button type="button" class="mh__arrow" data-mh-prev aria-label="Foto anterior">
            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15 5l-7 7 7 7"/></svg>
          </button>
          <button type="button" class="mh__arrow" data-mh-next aria-label="Foto siguiente">
            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 5l7 7-7 7"/></svg>
          </button>
        </div>
      </div>

      <div class="mh__thumbs" role="tablist" aria-label="Fotos del viaje">
        {% for s in _slides %}
        <button type="button" class="mh__thumb{% if loop.first %} is-on{% endif %}"
                data-mh-thumb="{{ loop.index0 }}" role="tab"
                aria-selected="{{ 'true' if loop.first else 'false' }}"
                aria-label="{{ s.lugar }}">
          <img src="{{ s.small | static_url }}" alt="" width="800" height="1067" loading="lazy"/>
        </button>
        {% endfor %}
      </div>
      <p class="mh__note">Fotos del viaje. Sin producción.</p>
    </div>

    {# ---------- COLUMNA TEXTO ---------- #}
    <div class="mh__copy">
      <span class="mh__badge u-glass">
        <i aria-hidden="true"></i>{{ home.hero.eyebrow or 'Comprado en Milán, traído a mano' }}
      </span>

      <h1 class="mh__title">{{ home.hero.titulo or 'Cada pieza la compramos en Milán.' }}</h1>

      <p class="mh__lead">{{ home.hero.subtitulo or 'En la tienda oficial, una unidad por talle. Cuando no está, no vuelve.' }}</p>

      <div class="mh__cta">
        <a class="mh__btn mh__btn--solid" href="{{ home.hero.cta_link or store.products_url }}">
          {{ home.hero.cta_texto or 'Ver lo que llegó' }}
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h13M13 6l6 6-6 6"/></svg>
        </a>
        <a class="mh__btn mh__btn--glass u-glass" target="_blank" rel="noopener"
           href="{{ home.hero.cta2_link or ('https://wa.me/5491162321391?text=' ~ ('Hola, quiero encargar una pieza para el proximo viaje a Milan.' | urlencode)) }}">
          {{ home.hero.cta2_texto or 'Encargar del próximo viaje' }}
        </a>
      </div>

      <dl class="mh__facts">
        <div><dt>Viaja todos los meses</dt><dd>Compra en tienda oficial, en Milán.</dd></div>
        <div><dt>Una unidad por talle</dt><dd>Cuando no está, no vuelve.</dd></div>
        <div><dt>Probador virtual</dt><dd>Subís tu foto y la ves puesta.</dd></div>
      </dl>
    </div>

  </div>
</section>
<span id="mi-after-hero"></span>

<style>
  /* ====== HERO "EL VIAJE" — todo sobre los tokens del DS ====== */
  .mh{ background:var(--mi-bg); padding:clamp(18px,3vw,34px) 0 clamp(36px,6vw,64px); }
  .mh__wrap{
    max-width:1280px; margin:0 auto; padding:0 clamp(20px,5vw,48px);
    display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1fr);
    gap:clamp(28px,4vw,64px); align-items:center;
  }

  /* ---- Foto ---- */
  .mh__stage{
    position:relative; border-radius:var(--mi-r-lg); overflow:hidden;
    background:var(--mi-bg-3); box-shadow:var(--mi-shadow);
    aspect-ratio:3/4;                        /* la altura la fija la proporción, nunca el archivo */
  }
  .mh__slide{
    position:absolute; inset:0; margin:0; opacity:0; visibility:hidden;
    transition:opacity .7s var(--mi-ease);
  }
  .mh__slide.is-on{ opacity:1; visibility:visible; }
  .mh__slide img{ width:100%; height:100%; object-fit:cover; display:block; }

  .mh__place{
    position:absolute; top:14px; left:14px; right:auto; max-width:min(78%,320px);
    display:flex; align-items:center; gap:9px;
    padding:9px 14px; border-radius:var(--mi-pill);
    font-size:12.5px; line-height:1.35; color:var(--mi-ink);
  }
  .mh__place b{ display:block; font-weight:600; }
  .mh__place span span, .mh__place > span{ min-width:0; }
  .mh__place-pin{
    width:9px; height:9px; flex:none; border-radius:50%;
    border:2px solid var(--mi-ink); opacity:.55;
  }

  .mh__arrows{ position:absolute; right:14px; bottom:14px; display:flex; gap:8px; }
  .mh__arrow{
    width:44px; height:44px;            /* target táctil del Estándar */
    display:grid; place-items:center; cursor:pointer;
    border-radius:50%; border:1px solid var(--mi-line);
    background:var(--mi-glass-strong); color:var(--mi-ink);
    -webkit-backdrop-filter:blur(var(--mi-blur)) saturate(180%); backdrop-filter:blur(var(--mi-blur)) saturate(180%);
    transition:transform .35s var(--mi-ease), background .35s var(--mi-ease);
  }
  .mh__arrow svg{ width:19px; height:19px; fill:none; stroke:currentColor; stroke-width:1.6; stroke-linecap:round; stroke-linejoin:round; }
  .mh__arrow:hover{ transform:scale(1.07); background:var(--mi-bg-2); }
  .mh__arrow:focus-visible{ outline:2px solid var(--mi-ink); outline-offset:3px; }

  .mh__thumbs{ display:flex; gap:10px; margin-top:14px; }
  .mh__thumb{
    flex:1 1 0; min-width:0; padding:0; cursor:pointer; background:none;
    border:1px solid var(--mi-line); border-radius:var(--mi-r-sm); overflow:hidden;
    aspect-ratio:4/5; opacity:.5;
    transition:opacity .4s var(--mi-ease), border-color .4s var(--mi-ease), transform .4s var(--mi-ease);
  }
  .mh__thumb img{ width:100%; height:100%; object-fit:cover; display:block; }
  .mh__thumb:hover{ opacity:.85; transform:translateY(-2px); }
  .mh__thumb.is-on{ opacity:1; border-color:var(--mi-ink); }
  .mh__thumb:focus-visible{ outline:2px solid var(--mi-ink); outline-offset:2px; }

  .mh__note{
    margin:12px 0 0; font-size:10.5px; letter-spacing:.22em; text-transform:uppercase;
    color:var(--mi-ink-mute);
  }

  /* ---- Texto ---- */
  .mh__badge{
    display:inline-flex; align-items:center; gap:9px;
    padding:9px 16px; border-radius:var(--mi-pill);
    font-size:11px; letter-spacing:.18em; text-transform:uppercase; font-weight:600;
    color:var(--mi-ink);
  }
  .mh__badge i{ width:6px; height:6px; border-radius:50%; background:var(--mi-ink); flex:none; }

  .mh__title{
    margin:22px 0 0;
    font-size:clamp(38px,5.4vw,68px); line-height:1.02; letter-spacing:-.028em;
    font-weight:700; color:var(--mi-ink); text-wrap:balance;
  }
  .mh__lead{
    margin:18px 0 0; max-width:44ch;
    font-size:clamp(15px,1.25vw,17px); line-height:1.62; color:var(--mi-ink-soft);
  }

  .mh__cta{ display:flex; flex-wrap:wrap; gap:12px; margin-top:30px; }
  .mh__btn{
    display:inline-flex; align-items:center; justify-content:center; gap:10px;
    min-height:52px; padding:0 26px; border-radius:var(--mi-pill);
    font-size:12px; letter-spacing:.14em; text-transform:uppercase; font-weight:600;
    border:1px solid transparent; text-align:center;
    transition:transform .35s var(--mi-ease), background .35s var(--mi-ease), color .35s var(--mi-ease);
  }
  .mh__btn svg{ width:17px; height:17px; fill:none; stroke:currentColor; stroke-width:1.7; stroke-linecap:round; stroke-linejoin:round; }
  .mh__btn--solid{ background:var(--mi-accent); color:var(--mi-bg); }
  .mh__btn--solid:hover{ background:var(--mi-accent-2); transform:translateY(-2px); }
  .mh__btn--glass{ color:var(--mi-ink); border-color:var(--mi-line-2); }
  .mh__btn--glass:hover{ background:var(--mi-bg-2); transform:translateY(-2px); }
  .mh__btn:focus-visible{ outline:2px solid var(--mi-ink); outline-offset:3px; }

  .mh__facts{
    display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:clamp(14px,2vw,26px);
    margin:clamp(30px,4vw,44px) 0 0; padding-top:clamp(20px,2.6vw,28px);
    border-top:1px solid var(--mi-line);
  }
  .mh__facts dt{ font-size:13px; font-weight:600; color:var(--mi-ink); line-height:1.3; }
  .mh__facts dd{ margin:6px 0 0; font-size:12.5px; line-height:1.5; color:var(--mi-ink-soft); }

  /* ---- Mobile: la foto primero, el texto abajo ---- */
  @media (max-width:900px){
    .mh__wrap{ grid-template-columns:minmax(0,1fr); gap:26px; }
    .mh__facts{ grid-template-columns:minmax(0,1fr); gap:14px; }
    .mh__facts dd{ margin-top:3px; }
    .mh__btn{ flex:1 1 auto; }
  }
  @media (max-width:420px){
    .mh__place{ max-width:calc(100% - 28px); font-size:12px; }
  }

  /* ---- Entrada: el contenido arranca VISIBLE y sube apenas ----
     Nada parte de opacity:0 esperando un observer. Si el JS no corre o la
     pestaña estaba en segundo plano, la portada igual se lee — que es el
     modo en que este tipo de animación deja una web en blanco. */
  .mh__copy > *{ transform:translateY(10px); opacity:.001; }
  .mh.is-ready .mh__copy > *{ transform:none; opacity:1;
    transition:transform .8s var(--mi-ease), opacity .8s var(--mi-ease); }
  .mh.is-ready .mh__copy > *:nth-child(2){ transition-delay:.06s }
  .mh.is-ready .mh__copy > *:nth-child(3){ transition-delay:.12s }
  .mh.is-ready .mh__copy > *:nth-child(4){ transition-delay:.18s }
  .mh.is-ready .mh__copy > *:nth-child(5){ transition-delay:.24s }

  @media (prefers-reduced-motion:reduce){
    .mh__copy > *{ transform:none; opacity:1; }
    .mh__slide{ transition:none; }
    .mh__arrow, .mh__thumb, .mh__btn{ transition:none; }
  }
</style>

<script>
(function(){
  var hero = document.getElementById('mi-hero');
  if (!hero) return;

  /* La entrada se enciende en el frame siguiente, y ADEMÁS por setTimeout:
     si rAF nunca corre (pestaña de fondo, WebView), el contenido igual
     aparece. Sin este segundo camino, la portada puede quedar invisible. */
  var encender = function(){ hero.classList.add('is-ready'); };
  requestAnimationFrame(function(){ requestAnimationFrame(encender); });
  setTimeout(encender, 400);

  var slides = [].slice.call(hero.querySelectorAll('[data-mh-slide]'));
  var thumbs = [].slice.call(hero.querySelectorAll('[data-mh-thumb]'));
  if (slides.length < 2) return;
  var actual = 0, timer = null;

  function mostrar(i){
    actual = (i + slides.length) % slides.length;
    slides.forEach(function(s, n){ s.classList.toggle('is-on', n === actual); });
    thumbs.forEach(function(t, n){
      t.classList.toggle('is-on', n === actual);
      t.setAttribute('aria-selected', n === actual ? 'true' : 'false');
    });
  }
  function arrancar(){
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    detener(); timer = setInterval(function(){ mostrar(actual + 1); }, 5200);
  }
  function detener(){ if (timer) { clearInterval(timer); timer = null; } }
  function ir(i){ mostrar(i); arrancar(); }

  thumbs.forEach(function(t, n){ t.addEventListener('click', function(){ ir(n); }); });
  var prev = hero.querySelector('[data-mh-prev]'), next = hero.querySelector('[data-mh-next]');
  if (prev) prev.addEventListener('click', function(){ ir(actual - 1); });
  if (next) next.addEventListener('click', function(){ ir(actual + 1); });

  /* Se desliza con el dedo, como cualquier galería del teléfono. */
  var stage = hero.querySelector('[data-mh-stage]'), x0 = null;
  if (stage){
    stage.addEventListener('touchstart', function(e){ x0 = e.touches[0].clientX; detener(); }, {passive:true});
    stage.addEventListener('touchend', function(e){
      if (x0 === null) return;
      var dx = e.changedTouches[0].clientX - x0;
      if (Math.abs(dx) > 42) ir(actual + (dx < 0 ? 1 : -1)); else arrancar();
      x0 = null;
    }, {passive:true});
  }

  /* Fuera de pantalla no se gasta nada. */
  if ('IntersectionObserver' in window){
    new IntersectionObserver(function(es){
      es[0].isIntersecting ? arrancar() : detener();
    }, {threshold:.2}).observe(hero);
  } else { arrancar(); }

  document.addEventListener('visibilitychange', function(){
    document.hidden ? detener() : arrancar();
  });
})();
</script>
