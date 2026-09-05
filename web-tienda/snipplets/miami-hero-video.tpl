{# ============================================================
   MIAMI_IMPORT — HERO "EL VIAJE" (tira arrastrable, full-bleed)

   Por qué así:
   · Las fotos de Diego en Milán son lo único que ningún competidor puede
     copiar, y son la prueba de que la prenda es original comprada en tienda
     oficial — LA objeción del rubro. Por eso mandan ellas, a sangre.
   · Se ARRASTRA: con el dedo en el celular y con el mouse en la compu, como
     una galería del teléfono. Nunca selectores numéricos (regla de la casa).
   · El texto vive en una placa de vidrio CLARO encima de la foto: así se lee
     sobre cualquiera de las cuatro (hay claras y oscuras) sin depender de la
     suerte, que es exactamente el bug que rompió el hero anterior.
   · Altura contenida con svh: la barra de Safari mobile miente con vh, y una
     foto 3/4 a 800px de ancho mide 1000px de alto y empuja todo fuera de
     pantalla — que es como este hero "desaparecía" en anchos intermedios.

   Textos editables desde el panel (Mi web → Portada).
   ============================================================ #}
{% set _slides = [
  {'src': 'images/milano/montenapoleone.webp', 'small': 'images/milano/montenapoleone@800.webp',
   'lugar': 'Via Montenapoleone', 'pie': 'La cuadra de las boutiques.'},
  {'src': 'images/milano/offwhite.webp', 'small': 'images/milano/offwhite@800.webp',
   'lugar': 'Off-White, Milán', 'pie': 'Adentro de la tienda oficial.'},
  {'src': 'images/milano/duomo.webp', 'small': 'images/milano/duomo@800.webp',
   'lugar': 'Duomo di Milano', 'pie': 'Donde arranca cada viaje.'},
  {'src': 'images/milano/galleria.webp', 'small': 'images/milano/galleria@800.webp',
   'lugar': 'Galleria Vittorio Emanuele II', 'pie': 'Cierra tarde. Nosotros también.'}
] %}

<section class="mh" id="mi-hero" aria-label="Miami Import — comprado en Milán, traído a mano">

  {# ---------- el video de la marca, de fondo ----------
     Va DETRAS de todo y con un velo claro encima: da movimiento y contraste
     para que las fotos del viaje floten en vidrio, sin pelearle la lectura al
     mensaje. El poster tambien va como background del contenedor: en iOS con
     Bajo Consumo el video no arranca y sin eso quedaba un bloque vacio. #}
  <div class="mh__bg" aria-hidden="true">
    <video class="mh__video" autoplay muted loop playsinline preload="metadata"
           poster="{{ 'videos/hero-miami-poster.jpg' | static_url }}">
      <source src="{{ home.hero.video | media_url if home.hero.video else ('videos/hero-miami.mp4' | static_url) }}" type="video/mp4"/>
    </video>
    <div class="mh__veil"></div>
  </div>

  <div class="mh__wrap">
  {# ---------- la foto, entera, en marco vertical ---------- #}
  <div class="mh__rail" data-mh-rail>
    <div class="mh__track" data-mh-track>
      {% for s in _slides %}
      <figure class="mh__cell" data-mh-cell="{{ loop.index0 }}">
        <img src="{{ s.src | static_url }}"
             srcset="{{ s.small | static_url }} 800w, {{ s.src | static_url }} 960w"
             sizes="(max-width: 900px) 100vw, 62vw"
             alt="{{ s.lugar }}, Milán" width="960" height="1280"
             draggable="false"
             {% if loop.first %}fetchpriority="high"{% else %}loading="lazy"{% endif %}/>
        <figcaption class="mh__place">
          <span class="mh__pin" aria-hidden="true"></span>
          <b>{{ s.lugar }}</b><span>{{ s.pie }}</span>
        </figcaption>
      </figure>
      {% endfor %}
    </div>

    {# ---------- controles, en la base de la foto ---------- #}
    <div class="mh__ctrl">
      <button type="button" class="mh__arrow" data-mh-prev aria-label="Foto anterior">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15 5l-7 7 7 7"/></svg>
      </button>
      <div class="mh__bars" role="tablist" aria-label="Fotos del viaje">
        {% for s in _slides %}
        <button type="button" class="mh__bar{% if loop.first %} is-on{% endif %}" data-mh-go="{{ loop.index0 }}"
                role="tab" aria-selected="{{ 'true' if loop.first else 'false' }}" aria-label="{{ s.lugar }}"><i></i></button>
        {% endfor %}
      </div>
      <button type="button" class="mh__arrow" data-mh-next aria-label="Foto siguiente">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 5l7 7-7 7"/></svg>
      </button>
    </div>
  </div>

    {# ---------- el mensaje, al lado de la foto ---------- #}
    <div class="mh__panel">
      <span class="mh__badge">
        <i aria-hidden="true"></i>{{ home.hero.eyebrow or 'Comprado en Milán, traído a mano' }}
      </span>
      <h1 class="mh__title">{{ home.hero.titulo or 'Cada pieza la compramos en Milán.' }}</h1>
      <p class="mh__lead">{{ home.hero.subtitulo or 'En la tienda oficial, una unidad por talle. Cuando no está, no vuelve.' }}</p>
      <div class="mh__cta">
        <a class="mh__btn mh__btn--solid" href="{{ home.hero.cta_link or store.products_url }}">
          {{ home.hero.cta_texto or 'Ver lo que llegó' }}
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h13M13 6l6 6-6 6"/></svg>
        </a>
        <a class="mh__btn mh__btn--ghost" target="_blank" rel="noopener"
           href="{{ home.hero.cta2_link or ('https://wa.me/5491162321391?text=' ~ ('Hola, quiero encargar una pieza para el proximo viaje a Milan.' | urlencode)) }}">
          {{ home.hero.cta2_texto or 'Encargar del próximo viaje' }}
        </a>
      </div>

      {# Las otras fotos del viaje. Llenan el aire que dejaba el mensaje y
         dan a entender de una que hay más de una foto para ver. #}
      <div class="mh__thumbs">
        {% for s in _slides %}
        <button type="button" class="mh__thumb{% if loop.first %} is-on{% endif %}"
                data-mh-go="{{ loop.index0 }}" aria-label="Ver {{ s.lugar }}">
          <img src="{{ s.small | static_url }}" alt="" loading="lazy" draggable="false"/>
          <span>{{ s.lugar }}</span>
        </button>
        {% endfor %}
      </div>
    </div>

  </div>

  {# ---------- la línea de abajo: por qué comprar acá ---------- #}
  <dl class="mh__facts">
    <div><dt>Viaja todos los meses</dt><dd>Compra en tienda oficial, en Milán.</dd></div>
    <div><dt>Una unidad por talle</dt><dd>Cuando no está, no vuelve.</dd></div>
    <div><dt>Probador virtual</dt><dd>Subís tu foto y la ves puesta.</dd></div>
    <div><dt>Fotos del viaje</dt><dd>Sin producción. Las saca él.</dd></div>
  </dl>
</section>
<span id="mi-after-hero"></span>

<style>
  /* ====== HERO — tira arrastrable + placa de vidrio ====== */
  .mh{
    position:relative; isolation:isolate;
    background:var(--mi-bg) url('{{ "videos/hero-miami-poster.jpg" | static_url }}') center/cover no-repeat;
    padding:clamp(14px,2vw,30px) 0 clamp(24px,3vw,44px);
  }
  .mh__bg{ position:absolute; inset:0; z-index:-1; overflow:hidden; }
  .mh__video{ width:100%; height:100%; object-fit:cover; display:block; }
  /* El velo: sin esto el mensaje compite con el video y no se lee ninguno de
     los dos. Con esto el video queda como atmosfera y el vidrio se despega. */
  .mh__veil{
    position:absolute; inset:0;
    /* Menos blanco y MUCHO mas desenfoque: el video se nota como un flujo de
       color en movimiento, no como una foto tapada por una sabana. El mensaje
       no depende de este velo para leerse —vive en su propia placa de vidrio—
       asi que se puede bajar sin arriesgar el contraste. */
    background:linear-gradient(180deg, rgba(251,251,250,.52) 0%, rgba(251,251,250,.38) 45%,
                                       rgba(251,251,250,.62) 100%);
    -webkit-backdrop-filter:blur(22px) saturate(135%); backdrop-filter:blur(22px) saturate(135%);
  }
  /* El video, un poco mas grande que su caja: al desenfocar, los bordes se
     lavan y se veria un halo claro en el perimetro. */
  .mh__video{ transform:scale(1.06); }
  @media (prefers-reduced-motion:reduce){ .mh__video{ display:none; } }

  /* ---- EL MARCO ES VERTICAL, COMO LA FOTO ------------------------------
     🔴 Las fotos de Milán son verticales (3:4). Metidas en una franja
     apaisada hay que recortarles arriba y abajo — por eso el Duomo aparecía
     cortado. Acá el marco tiene LA MISMA proporción que la foto, así entra
     entera y no se recorta nada. En PC la foto va a un lado y el mensaje al
     otro; en el celular, la foto arriba y el mensaje abajo. */
  .mh__wrap{
    max-width:1280px; margin:0 auto; padding:0 clamp(20px,5vw,48px);
    display:grid; grid-template-columns:auto minmax(0,1fr);
    gap:clamp(26px,4vw,56px); align-items:center;
  }
  .mh__rail{
    position:relative; overflow:hidden; border-radius:var(--mi-r-lg);
    /* La altura manda y el ancho sale de la proporción de la foto: así el
       marco nunca pide más foto de la que hay. */
    height:clamp(380px, 62svh, 700px); aspect-ratio:3/4;
    background:var(--mi-bg-3); box-shadow:var(--mi-shadow);
    cursor:grab; touch-action:pan-y;
    user-select:none; -webkit-user-select:none;
  }
  .mh__rail.is-drag{ cursor:grabbing; }

  .mh__track{ display:flex; height:100%; will-change:transform;
    transition:transform .72s var(--mi-ease); }
  .mh__rail.is-drag .mh__track{ transition:none; }
  .mh__cell{ flex:0 0 100%; height:100%; margin:0; position:relative; }
  .mh__cell img{
    width:100%; height:100%; object-fit:cover; object-position:center;
    display:block; pointer-events:none;
  }
  /* Sólo un velo abajo, para que la chapa del lugar se lea. El mensaje ya no
     va encima de la foto, así que no hace falta lavarla entera. */
  .mh__cell::after{
    content:""; position:absolute; inset:auto 0 0 0; height:34%; pointer-events:none;
    background:linear-gradient(180deg, rgba(251,251,250,0), rgba(251,251,250,.55));
  }

  .mh__place{
    position:absolute; right:16px; top:16px; z-index:2;
    display:flex; align-items:baseline; gap:8px; flex-wrap:wrap;
    max-width:min(64%,340px); padding:8px 14px; border-radius:var(--mi-pill);
    background:var(--mi-glass-strong); border:1px solid var(--mi-line);
    -webkit-backdrop-filter:blur(18px) saturate(180%); backdrop-filter:blur(18px) saturate(180%);
    font-size:12px; color:var(--mi-ink-soft);
  }
  .mh__place b{ font-weight:600; color:var(--mi-ink); }
  .mh__pin{ width:7px; height:7px; border-radius:50%; background:var(--mi-ink); opacity:.5; flex:none; align-self:center; }

  /* ---- la placa del mensaje ---- */
  .mh__panel{
    min-width:0; padding:clamp(24px,2.6vw,34px); border-radius:var(--mi-r-lg);
    background:var(--mi-glass); border:1px solid var(--mi-line);
    border-top-color:var(--mi-glass-line);
    -webkit-backdrop-filter:blur(var(--mi-blur)) saturate(180%); backdrop-filter:blur(var(--mi-blur)) saturate(180%);
    box-shadow:var(--mi-shadow);
  }
  @supports not ((backdrop-filter:blur(1px)) or (-webkit-backdrop-filter:blur(1px))){
    .mh__panel{ background:var(--mi-glass-strong); }
  }

  .mh__badge{
    display:inline-flex; align-items:center; gap:8px;
    font-size:10.5px; letter-spacing:.2em; text-transform:uppercase; font-weight:600; color:var(--mi-ink);
  }
  .mh__badge i{ width:6px; height:6px; border-radius:50%; background:var(--mi-ink); flex:none; }
  .mh__title{
    margin:16px 0 0; font-size:clamp(30px,4vw,54px); line-height:1.03;
    letter-spacing:-.028em; font-weight:700; color:var(--mi-ink); text-wrap:balance;
  }
  .mh__lead{ margin:14px 0 0; font-size:clamp(14px,1.15vw,16px); line-height:1.6; color:var(--mi-ink-soft); }
  .mh__cta{ display:flex; flex-wrap:wrap; gap:10px; margin-top:24px; }
  .mh__btn{
    display:inline-flex; align-items:center; justify-content:center; gap:9px;
    min-height:50px; padding:0 24px; border-radius:var(--mi-pill);
    font-size:11.5px; letter-spacing:.14em; text-transform:uppercase; font-weight:600;
    border:1px solid transparent;
    transition:transform .35s var(--mi-ease), background .35s var(--mi-ease);
  }
  .mh__btn svg{ width:16px; height:16px; fill:none; stroke:currentColor; stroke-width:1.7; stroke-linecap:round; stroke-linejoin:round; }
  .mh__btn--solid{ background:var(--mi-accent); color:var(--mi-bg); }
  .mh__btn--solid:hover{ background:var(--mi-accent-2); transform:translateY(-2px); }
  .mh__btn--ghost{ color:var(--mi-ink); border-color:var(--mi-line-2); background:var(--mi-bg-2); }
  .mh__btn--ghost:hover{ transform:translateY(-2px); }
  .mh__btn:focus-visible{ outline:2px solid var(--mi-ink); outline-offset:3px; }

  /* ---- controles: barras que se llenan, no números ---- */
  .mh__ctrl{
    position:absolute; z-index:3; left:14px; right:14px; bottom:14px;
    display:flex; align-items:center; justify-content:space-between; gap:10px;
  }
  .mh__arrow{
    width:44px; height:44px; display:grid; place-items:center; cursor:pointer;
    border-radius:50%; border:1px solid var(--mi-line); color:var(--mi-ink);
    background:var(--mi-glass-strong);
    -webkit-backdrop-filter:blur(18px) saturate(180%); backdrop-filter:blur(18px) saturate(180%);
    transition:transform .3s var(--mi-ease), background .3s var(--mi-ease);
  }
  .mh__arrow svg{ width:18px; height:18px; fill:none; stroke:currentColor; stroke-width:1.7; stroke-linecap:round; stroke-linejoin:round; }
  .mh__arrow:hover{ transform:scale(1.08); background:var(--mi-bg-2); }
  .mh__arrow:focus-visible{ outline:2px solid var(--mi-ink); outline-offset:3px; }

  .mh__bars{ display:flex; gap:6px; align-items:center; }
  .mh__bar{
    width:30px; height:34px; padding:0; border:0; background:none; cursor:pointer;
    display:grid; place-items:center;
  }
  .mh__bar i{
    display:block; width:100%; height:3px; border-radius:2px;
    background:rgba(21,22,26,.22); overflow:hidden; position:relative;
  }
  .mh__bar i::after{
    content:""; position:absolute; inset:0; width:0; background:var(--mi-ink);
    transition:width .4s var(--mi-ease);
  }
  .mh__bar.is-on i::after{ width:100%; }
  .mh__bar:focus-visible{ outline:2px solid var(--mi-ink); outline-offset:2px; border-radius:4px; }

  /* ---- la línea de abajo ---- */
  .mh__thumbs{
    display:grid; grid-template-columns:repeat(4,minmax(0,1fr));
    gap:10px; margin-top:clamp(26px,3vw,38px);
    padding-top:clamp(20px,2.4vw,28px); border-top:1px solid var(--mi-line);
  }
  .mh__thumb{
    display:block; padding:0; border:0; background:none; cursor:pointer;
    text-align:left; min-width:0;
  }
  .mh__thumb img{
    width:100%; aspect-ratio:4/5; object-fit:cover; display:block;
    border-radius:var(--mi-r-sm); border:1px solid var(--mi-line);
    opacity:.55; transition:opacity .4s var(--mi-ease), transform .4s var(--mi-ease);
  }
  .mh__thumb span{
    display:block; margin-top:7px; font-size:10px; letter-spacing:.1em;
    text-transform:uppercase; color:var(--mi-ink-mute);
    overflow:hidden; text-overflow:ellipsis; white-space:nowrap;
  }
  .mh__thumb:hover img{ opacity:.85; transform:translateY(-3px); }
  .mh__thumb.is-on img{ opacity:1; border-color:var(--mi-ink); }
  .mh__thumb.is-on span{ color:var(--mi-ink); }
  @media (max-width:900px){ .mh__thumbs{ display:none; } }

  .mh__facts{
    position:relative; max-width:1280px; margin:clamp(22px,3vw,34px) auto 0; padding:0 clamp(20px,5vw,48px);
    display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:clamp(14px,2vw,28px);
  }
  .mh__facts dt{ font-size:12.5px; font-weight:600; color:var(--mi-ink); line-height:1.3; }
  .mh__facts dd{ margin:5px 0 0; font-size:12px; line-height:1.5; color:var(--mi-ink-soft); }

  @media (max-width:900px){
    .mh__wrap{ grid-template-columns:minmax(0,1fr); gap:18px; }
    /* En una columna la foto cede: 5/6 es mas bajo que 4/5 y deja el mensaje
       y los botones dentro de la primera pantalla, que es lo que importa. */
    .mh__rail{ height:auto; width:100%; aspect-ratio:5/6; max-height:52svh; }
    .mh__panel{ padding:18px; }
    .mh__title{ font-size:clamp(26px,7vw,38px); }
    .mh__place{ max-width:calc(100% - 32px); }
    .mh__btn{ flex:1 1 auto; }
    .mh__facts{ grid-template-columns:repeat(2,minmax(0,1fr)); }
  }
  /* Celular chico: la pantalla es la mitad de alta que en la compu y el
     header ya se come 180px. La foto cede lo necesario para que el boton
     de comprar entre SIN scrollear — que es todo el punto de un hero. */
  @media (max-width:560px){
    .mh__rail{ max-height:40svh; }
    .mh__panel{ padding:16px; }
    .mh__title{ font-size:clamp(24px,6.6vw,32px); }
    .mh__lead{ font-size:14px; margin-top:10px; }
    .mh__cta{ margin-top:16px; gap:8px; }
    .mh__btn{ min-height:46px; font-size:11px; }
  }
  @media (max-width:420px){
    .mh__facts{ grid-template-columns:minmax(0,1fr); }
  }

  /* Entrada: arranca casi visible y sube. Nunca en opacity:0 esperando un
     observer — si no dispara, la portada queda en blanco para siempre. */
  .mh__panel > *{ transform:translateY(9px); opacity:.001; }
  .mh.is-ready .mh__panel > *{ transform:none; opacity:1;
    transition:transform .75s var(--mi-ease), opacity .75s var(--mi-ease); }
  .mh.is-ready .mh__panel > *:nth-child(2){ transition-delay:.07s }
  .mh.is-ready .mh__panel > *:nth-child(3){ transition-delay:.14s }
  .mh.is-ready .mh__panel > *:nth-child(4){ transition-delay:.21s }

  @media (prefers-reduced-motion:reduce){
    .mh__panel > *{ transform:none; opacity:1; }
    .mh__track, .mh__arrow, .mh__btn, .mh__bar i::after{ transition:none; }
  }
</style>

<script>
(function(){
  var hero = document.getElementById('mi-hero');
  if (!hero) return;

  var encender = function(){ hero.classList.add('is-ready'); };
  requestAnimationFrame(function(){ requestAnimationFrame(encender); });
  setTimeout(encender, 400);            // segundo camino: si rAF no corre, igual aparece

  var rail  = hero.querySelector('[data-mh-rail]');
  var track = hero.querySelector('[data-mh-track]');
  var cells = [].slice.call(hero.querySelectorAll('[data-mh-cell]'));
  var bars  = [].slice.call(hero.querySelectorAll('.mh__bar[data-mh-go]'));
  var minis = [].slice.call(hero.querySelectorAll('.mh__thumb[data-mh-go]'));
  if (!rail || !track || cells.length < 2) return;

  var i = 0, timer = null, lento = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function pintar(){
    track.style.transform = 'translate3d(' + (-i * 100) + '%,0,0)';
    bars.forEach(function(b, n){
      b.classList.toggle('is-on', n === i);
      b.setAttribute('aria-selected', n === i ? 'true' : 'false');
    });
    minis.forEach(function(m, n){ m.classList.toggle('is-on', n === i); });
  }
  function ir(n){ i = (n + cells.length) % cells.length; pintar(); reloj(); }
  function reloj(){ parar(); if (!lento) timer = setInterval(function(){ ir(i + 1); }, 5600); }
  function parar(){ if (timer) { clearInterval(timer); timer = null; } }

  bars.forEach(function(b, n){ b.addEventListener('click', function(){ ir(n); }); });
  minis.forEach(function(m, n){ m.addEventListener('click', function(){ ir(n); }); });
  var prev = hero.querySelector('[data-mh-prev]'), next = hero.querySelector('[data-mh-next]');
  if (prev) prev.addEventListener('click', function(){ ir(i - 1); });
  if (next) next.addEventListener('click', function(){ ir(i + 1); });

  /* ---- Se agarra y se tira: mouse y dedo, con el MISMO código ----
     Pointer Events unifica los dos. El umbral es proporcional al ancho para
     que en el celular no haga falta arrastrar media pantalla. */
  var x0 = 0, dx = 0, arrastrando = false;

  function empezar(e){
    if (e.button !== undefined && e.button !== 0) return;   // sólo botón izquierdo
    arrastrando = true; x0 = e.clientX; dx = 0;
    rail.classList.add('is-drag'); parar();
    if (rail.setPointerCapture && e.pointerId !== undefined) {
      try { rail.setPointerCapture(e.pointerId); } catch (err) {}
    }
  }
  function mover(e){
    if (!arrastrando) return;
    dx = e.clientX - x0;
    track.style.transform = 'translate3d(calc(' + (-i * 100) + '% + ' + dx + 'px),0,0)';
  }
  function soltar(){
    if (!arrastrando) return;
    arrastrando = false; rail.classList.remove('is-drag');
    var umbral = Math.max(48, rail.offsetWidth * 0.14);
    if (Math.abs(dx) > umbral) ir(i + (dx < 0 ? 1 : -1));
    else { pintar(); reloj(); }
    dx = 0;
  }

  if (window.PointerEvent){
    rail.addEventListener('pointerdown', empezar);
    rail.addEventListener('pointermove', mover);
    rail.addEventListener('pointerup', soltar);
    rail.addEventListener('pointercancel', soltar);
    rail.addEventListener('pointerleave', soltar);
  } else {
    rail.addEventListener('mousedown', empezar);
    window.addEventListener('mousemove', mover);
    window.addEventListener('mouseup', soltar);
    rail.addEventListener('touchstart', function(e){ empezar(e.touches[0]); }, {passive:true});
    rail.addEventListener('touchmove',  function(e){ mover(e.touches[0]); }, {passive:true});
    rail.addEventListener('touchend', soltar);
  }
  /* Arrastrar no tiene que "abrir" el link que hay debajo del dedo. */
  rail.addEventListener('click', function(e){
    if (Math.abs(dx) > 6) { e.preventDefault(); e.stopPropagation(); }
  }, true);
  rail.addEventListener('dragstart', function(e){ e.preventDefault(); });

  /* Teclado */
  rail.setAttribute('tabindex', '0');
  rail.addEventListener('keydown', function(e){
    if (e.key === 'ArrowLeft')  { e.preventDefault(); ir(i - 1); }
    if (e.key === 'ArrowRight') { e.preventDefault(); ir(i + 1); }
  });

  /* Fuera de pantalla o pestaña oculta: no se gasta nada */
  if ('IntersectionObserver' in window){
    new IntersectionObserver(function(es){ es[0].isIntersecting ? reloj() : parar(); },
                             {threshold:.15}).observe(hero);
  } else { reloj(); }
  document.addEventListener('visibilitychange', function(){ document.hidden ? parar() : reloj(); });

  pintar(); reloj();
})();
</script>
