{# ============================================================
   MIAMI_IMPORT — INSTAGRAM (vara: Potente Propiedades)

   Reels REALES en tarjetas tipo teléfono, deslizables con flechas y con
   rotación automática. Embed oficial de Instagram por iframe: sin API, sin
   token que se venza, sin script de terceros que frene la página.

   Por qué acá: la cuenta tiene 65.597 seguidores y la web no los usaba. Y al
   revés — el que entra a la web y ve movimiento real entiende que hay alguien
   atrás. Es la misma prueba que las fotos de Milán, en otro formato.

   🔴 Los reels se cambian desde el panel (Mi web → Instagram). Sin nada
   cargado usa los últimos tres publicados, que están abajo como valor de
   fábrica. Un shortcode es lo que va después de /reel/ o /p/ en el link.
   ============================================================ #}
{% set _ig = home.instagram if home.instagram is defined else none %}
{% set _usuario = (_ig.usuario if _ig and _ig.usuario else 'miamimport_') %}
{% set _reels = (_ig['items'] if _ig and _ig['items'] else [
  {'code': 'DbBqSPspuOB', 'tipo': 'reel', 'pie': 'La oficina nueva, en el Hilton', 'video': true},
  {'code': 'DayZW8LiZU5', 'tipo': 'p',    'pie': 'Clientes con sus piezas'},
  {'code': 'DZ5-TAWkXY-', 'tipo': 'p',    'pie': 'Lo que llegó de Milán'}
]) %}

{% if _reels %}
<section class="mi-ig" aria-label="Miami Import en Instagram">
  <div class="mi-ig__wrap">

    <div class="mi-ig__head">
      <div>
        <p class="mi-ig__eyebrow">
          <svg viewBox="0 0 24 24" aria-hidden="true" class="mi-ig__glyph">
            <rect x="3" y="3" width="18" height="18" rx="5"/>
            <circle cx="12" cy="12" r="4"/><circle cx="17.5" cy="6.5" r="1.1" fill="currentColor" stroke="none"/>
          </svg>
          @{{ _usuario }}
        </p>
        <h2 class="mi-ig__title">Lo que llega, en video</h2>
        <p class="mi-ig__lead">Cada viaje, cada pieza que entra y los que ya se la están poniendo.</p>
      </div>
      <a class="mi-ig__follow" href="https://instagram.com/{{ _usuario }}" target="_blank" rel="noopener">
        Seguinos <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h13M13 6l6 6-6 6"/></svg>
      </a>
    </div>

    <div class="mi-ig__rail" data-ig-rail>
      <div class="mi-ig__track" data-ig-track>
        {% for r in _reels %}
        <article class="mi-ig__card">
          {# 🔴 SIN IFRAME. El embed de Instagram no carga si el visitante
             bloquea cookies de terceros o está en modo privado, y encima
             quedaba ENCIMA de la miniatura tapándole el click: la tarjeta se
             volvía un panel muerto. Ahora la tarjeta entera es el link, y el
             reel se reproduce con su propio video —guardado local, porque las
             URLs de Instagram vencen—. En el celular el link abre la app. #}
          <a class="mi-ig__phone" href="https://www.instagram.com/{{ r.tipo or 'p' }}/{{ r.code }}/"
             target="_blank" rel="noopener" aria-label="Ver en Instagram: {{ r.pie }}">
            {% if r.video %}
            <video class="mi-ig__media" muted loop playsinline preload="none"
                   poster="{{ ('images/ig/' ~ r.code ~ '.webp') | static_url }}" data-ig-video>
              <source src="{{ ('videos/ig/' ~ r.code ~ '.mp4') | static_url }}" type="video/mp4"/>
            </video>
            {% else %}
            <img class="mi-ig__media" src="{{ ('images/ig/' ~ r.code ~ '.webp') | static_url }}"
                 alt="{{ r.pie }}" loading="lazy"/>
            {% endif %}
            <span class="mi-ig__play" aria-hidden="true">
              <svg viewBox="0 0 24 24"><path d="M8 5.5v13l11-6.5z"/></svg>
            </span>
            <span class="mi-ig__ver">Ver en Instagram</span>
          </a>
          {% if r.pie %}<p class="mi-ig__pie">{{ r.pie }}</p>{% endif %}
        </article>
        {% endfor %}

        {# La última tarjeta no es un reel: es la invitación a seguir. Cierra
           el riel con una acción en vez de con un borde cortado. #}
        <article class="mi-ig__card mi-ig__card--cta">
          <a class="mi-ig__cta u-glass" href="https://instagram.com/{{ _usuario }}" target="_blank" rel="noopener">
            <svg viewBox="0 0 24 24" aria-hidden="true" class="mi-ig__glyph mi-ig__glyph--big">
              <rect x="3" y="3" width="18" height="18" rx="5"/>
              <circle cx="12" cy="12" r="4"/><circle cx="17.5" cy="6.5" r="1.1" fill="currentColor" stroke="none"/>
            </svg>
            <span class="mi-ig__cta-user">@{{ _usuario }}</span>
            <span class="mi-ig__cta-txt">Todo el catálogo se mueve primero acá.</span>
            <span class="mi-ig__cta-btn">Seguir en Instagram →</span>
          </a>
        </article>
      </div>

      <button type="button" class="mi-ig__arrow mi-ig__arrow--prev" data-ig-prev aria-label="Anterior">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15 5l-7 7 7 7"/></svg>
      </button>
      <button type="button" class="mi-ig__arrow mi-ig__arrow--next" data-ig-next aria-label="Siguiente">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 5l7 7-7 7"/></svg>
      </button>
    </div>
  </div>
</section>

<style>
  .mi-ig{ padding:clamp(38px,5vw,68px) 0; background:var(--mi-bg-3); }
  .mi-ig__wrap{ max-width:1280px; margin:0 auto; padding:0 clamp(20px,5vw,48px); }

  .mi-ig__head{ display:flex; align-items:flex-end; justify-content:space-between;
    gap:24px; flex-wrap:wrap; margin-bottom:clamp(20px,2.6vw,34px); }
  .mi-ig__eyebrow{ display:inline-flex; align-items:center; gap:8px; margin:0;
    font-size:11px; letter-spacing:.28em; text-transform:uppercase; font-weight:600; color:var(--mi-ink); }
  .mi-ig__glyph{ width:15px; height:15px; fill:none; stroke:currentColor; stroke-width:1.6; }
  .mi-ig__glyph--big{ width:26px; height:26px; }
  .mi-ig__title{ margin:12px 0 0; font-size:clamp(26px,4vw,48px); line-height:1.04;
    letter-spacing:-.024em; text-transform:uppercase; font-weight:600; color:var(--mi-ink); }
  .mi-ig__lead{ margin:10px 0 0; max-width:46ch; font-size:clamp(14px,1.15vw,16px);
    line-height:1.6; color:var(--mi-ink-soft); }
  .mi-ig__follow{ display:inline-flex; align-items:center; gap:9px; min-height:46px; padding:0 22px;
    border-radius:var(--mi-pill); background:var(--mi-accent); color:var(--mi-bg);
    font-size:11.5px; letter-spacing:.14em; text-transform:uppercase; font-weight:600; white-space:nowrap;
    transition:transform .35s var(--mi-ease), background .35s var(--mi-ease); }
  .mi-ig__follow:hover{ background:var(--mi-accent-2); transform:translateY(-2px); }
  .mi-ig__follow svg{ width:16px; height:16px; fill:none; stroke:currentColor; stroke-width:1.7; stroke-linecap:round; stroke-linejoin:round; }

  /* ---- el riel ---- */
  .mi-ig__rail{ position:relative; margin-right:calc(-1 * clamp(20px,5vw,48px)); }
  .mi-ig__track{
    display:flex; gap:clamp(14px,1.6vw,20px);
    overflow-x:auto; scroll-snap-type:x mandatory; -webkit-overflow-scrolling:touch;
    padding:4px clamp(20px,5vw,48px) 8px 0;
    -ms-overflow-style:none; scrollbar-width:none; cursor:grab;
  }
  .mi-ig__track::-webkit-scrollbar{ display:none; }
  .mi-ig__track.is-grabbing{ cursor:grabbing; scroll-snap-type:none; }
  @media (pointer:coarse){ .mi-ig__track{ scroll-snap-type:x proximity; cursor:default; } }

  .mi-ig__card{ flex:0 0 clamp(266px, 24vw, 316px); scroll-snap-align:start; margin:0; }

  /* La tarjeta "teléfono": el embed de Instagram trae su propio alto, así que
     se lo recorta a proporción fija y se lo empuja hacia arriba para tapar la
     barra de la cuenta, que repite lo que ya dice el encabezado. */
  .mi-ig__phone{
    display:block; position:relative; aspect-ratio:9/15; overflow:hidden;
    border-radius:26px; background:var(--mi-bg-2);
    border:1px solid var(--mi-line); box-shadow:var(--mi-shadow);
    transition:transform .5s var(--mi-ease), box-shadow .5s var(--mi-ease);
  }
  .mi-ig__card:hover .mi-ig__phone{ transform:translateY(-4px); box-shadow:var(--mi-shadow-lift); }
  .mi-ig__media{ position:absolute; inset:0; width:100%; height:100%; object-fit:cover; display:block; }
  .mi-ig__play{
    position:absolute; left:50%; top:50%; transform:translate(-50%,-50%);
    width:54px; height:54px; display:grid; place-items:center; border-radius:50%;
    background:var(--mi-glass-strong); border:1px solid var(--mi-line);
    -webkit-backdrop-filter:blur(var(--mi-blur)) saturate(180%); backdrop-filter:blur(var(--mi-blur)) saturate(180%);
    box-shadow:var(--mi-shadow); transition:transform .4s var(--mi-ease), opacity .4s var(--mi-ease);
  }
  .mi-ig__play svg{ width:22px; height:22px; fill:var(--mi-ink); margin-left:2px; }
  .mi-ig__card:hover .mi-ig__play{ transform:translate(-50%,-50%) scale(1.08); }
  /* Mientras el video corre, el play estorba: se va solo. */
  .mi-ig__phone.is-playing .mi-ig__play{ opacity:0; }
  .mi-ig__ver{
    position:absolute; left:12px; right:12px; bottom:12px; text-align:center;
    padding:9px 12px; border-radius:var(--mi-pill);
    background:var(--mi-glass-strong); border:1px solid var(--mi-line);
    -webkit-backdrop-filter:blur(var(--mi-blur)) saturate(180%); backdrop-filter:blur(var(--mi-blur)) saturate(180%);
    font-size:10.5px; letter-spacing:.16em; text-transform:uppercase; font-weight:600; color:var(--mi-ink);
  }
  .mi-ig__pie{ margin:11px 2px 0; font-size:12px; line-height:1.4; color:var(--mi-ink-soft); }

  /* ---- la tarjeta de cierre ---- */
  .mi-ig__card--cta .mi-ig__cta{
    display:flex; flex-direction:column; align-items:flex-start; justify-content:center; gap:9px;
    height:100%; aspect-ratio:9/15; padding:clamp(22px,2.4vw,30px);
    border-radius:26px; color:var(--mi-ink);
  }
  .mi-ig__cta-user{ font-size:15px; font-weight:700; letter-spacing:.06em; }
  .mi-ig__cta-txt{ font-size:13px; line-height:1.5; color:var(--mi-ink-soft); }
  .mi-ig__cta-btn{ margin-top:6px; font-size:11px; letter-spacing:.14em;
    text-transform:uppercase; font-weight:600; border-bottom:1px solid var(--mi-line-2); padding-bottom:3px; }

  /* ---- flechas ---- */
  .mi-ig__arrow{
    position:absolute; top:calc(50% - 22px); z-index:3;
    width:44px; height:44px; display:grid; place-items:center; cursor:pointer;
    border-radius:50%; border:1px solid var(--mi-line); color:var(--mi-ink);
    background:var(--mi-glass-strong);
    -webkit-backdrop-filter:blur(var(--mi-blur)) saturate(180%); backdrop-filter:blur(var(--mi-blur)) saturate(180%);
    box-shadow:var(--mi-shadow);
    transition:transform .3s var(--mi-ease), opacity .3s var(--mi-ease);
  }
  .mi-ig__arrow svg{ width:18px; height:18px; fill:none; stroke:currentColor; stroke-width:1.7; stroke-linecap:round; stroke-linejoin:round; }
  .mi-ig__arrow--prev{ left:-6px; }
  .mi-ig__arrow--next{ right:calc(clamp(20px,5vw,48px) - 6px); }
  .mi-ig__arrow:hover{ transform:scale(1.08); }
  .mi-ig__arrow:focus-visible{ outline:2px solid var(--mi-ink); outline-offset:3px; }
  .mi-ig__arrow[hidden]{ display:none; }
  @media (pointer:coarse){ .mi-ig__arrow{ display:none; } }   /* en el celu se desliza con el dedo */

  @media (max-width:640px){
    .mi-ig__card{ flex-basis:74vw; }
    .mi-ig__head{ align-items:flex-start; }
  }
  @media (prefers-reduced-motion:reduce){
    .mi-ig__phone, .mi-ig__arrow, .mi-ig__follow{ transition:none; }
  }
</style>

<script>
(function(){
  var rail = document.querySelector('[data-ig-rail]');
  var track = rail && rail.querySelector('[data-ig-track]');
  if (!rail || !track) return;

  var paso = function(){
    var c = track.querySelector('.mi-ig__card');
    return c ? c.getBoundingClientRect().width + 18 : 300;
  };
  var prev = rail.querySelector('[data-ig-prev]'), next = rail.querySelector('[data-ig-next]');
  function pintarFlechas(){
    if (!prev || !next) return;
    var fin = track.scrollLeft + track.clientWidth >= track.scrollWidth - 8;
    prev.hidden = track.scrollLeft < 8;
    next.hidden = fin;
  }
  if (prev) prev.addEventListener('click', function(){ track.scrollBy({left:-paso(), behavior:'smooth'}); });
  if (next) next.addEventListener('click', function(){ track.scrollBy({left: paso(), behavior:'smooth'}); });
  track.addEventListener('scroll', pintarFlechas, {passive:true});
  pintarFlechas();

  /* Rota solo, y se detiene cuando el visitante está mirando o tocando: nada
     peor que una vitrina que se mueve justo cuando la mirás. */
  var pausa = false, visible = false;
  rail.addEventListener('mouseenter', function(){ pausa = true; });
  rail.addEventListener('mouseleave', function(){ pausa = false; });
  rail.addEventListener('touchstart', function(){ pausa = true; }, {passive:true});
  if ('IntersectionObserver' in window){
    new IntersectionObserver(function(e){ visible = e[0].isIntersecting; }, {threshold:.3}).observe(rail);
  } else { visible = true; }
  if (!window.matchMedia('(prefers-reduced-motion: reduce)').matches){
    setInterval(function(){
      if (pausa || !visible || document.hidden) return;
      var fin = track.scrollLeft + track.clientWidth >= track.scrollWidth - 8;
      track.scrollTo({left: fin ? 0 : track.scrollLeft + paso(), behavior:'smooth'});
    }, 5200);
  }

  /* El video arranca solo cuando la tarjeta se ve, y se frena al salir: un
     video reproduciendose fuera de pantalla es bateria del visitante tirada. */
  var vids = rail.querySelectorAll('[data-ig-video]');
  if (vids.length && 'IntersectionObserver' in window){
    var ioV = new IntersectionObserver(function(es){
      es.forEach(function(e){
        var v = e.target;
        if (e.isIntersecting && !window.matchMedia('(prefers-reduced-motion: reduce)').matches){
          var pr = v.play();
          if (pr && pr.catch) pr.catch(function(){});   // iOS Bajo Consumo lo rechaza: no pasa nada
          v.closest('.mi-ig__phone').classList.add('is-playing');
        } else {
          v.pause(); v.closest('.mi-ig__phone').classList.remove('is-playing');
        }
      });
    }, {threshold:.55});
    vids.forEach(function(v){ ioV.observe(v); });
  }

  /* Se agarra y se tira, como el resto de la web. Los iframes se comen el
     mousedown, así que el arrastre se toma del riel y no de la tarjeta. */
  var x0 = null, sl0 = 0;
  track.addEventListener('pointerdown', function(e){
    if (e.pointerType === 'touch') return;          // en touch manda el scroll nativo
    x0 = e.clientX; sl0 = track.scrollLeft; track.classList.add('is-grabbing');
  });
  window.addEventListener('pointermove', function(e){
    if (x0 === null) return;
    track.scrollLeft = sl0 - (e.clientX - x0);
  });
  window.addEventListener('pointerup', function(){
    if (x0 === null) return;
    x0 = null; track.classList.remove('is-grabbing'); pintarFlechas();
  });
})();
</script>
{% endif %}
