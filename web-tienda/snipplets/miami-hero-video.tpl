{# ============================================================
   MIAMI_IMPORT — HERO VIDEO (restrained, video-led · vara bombo)
   - El video de moda manda (full-bleed). Branding sobrio encima.
   - Sin grano/grilla/marquee: menos es más.
   ============================================================ #}
<section class="mi-hero" id="mi-hero" aria-label="Miami Import — indumentaria original importada">
  <video class="mi-hero__video" autoplay muted loop playsinline preload="metadata"
         poster="{{ 'videos/hero-miami-poster.jpg' | static_url }}">
    <source src="{{ 'videos/hero-miami.mp4' | static_url }}" type="video/mp4"/>
  </video>
  <div class="mi-hero__scrim" aria-hidden="true"></div>

  <div class="mi-hero__top">
    <span class="mi-hero__eyebrow"><i></i>MILANO&nbsp;→&nbsp;BUENOS AIRES · MARCAS CON LICENCIA</span>
  </div>

  <div class="mi-hero__content">
    {# El branding "MIAMI IMPORT" ya va quemado en el video (estilo Balenciaga),
       así que el overlay no repite el logo — un solo mark, minimalista. #}
    <p class="mi-hero__tag">
      Originales importados con licencia de origen.<br/>
      <span class="mi-hero__tag-strong">Piezas contadas — cuando no está, no vuelve.</span>
    </p>
    <div class="mi-hero__cta">
      <a href="{{ store.products_url }}" class="mi-hero__btn mi-hero__btn--gold miami-magnetic">Ver catálogo <span aria-hidden="true">→</span></a>
      <a href="https://wa.me/5491162321391?text=Hola%2C%20quiero%20abrir%20un%20pedido%20puntual." target="_blank" rel="noopener" class="mi-hero__btn mi-hero__btn--ghost miami-magnetic">Pedido puntual</a>
    </div>
  </div>

  <a href="#mi-after-hero" class="mi-hero__scroll" aria-label="Bajar"><span></span></a>
</section>
<span id="mi-after-hero"></span>

<style>
  .mi-hero{
    --gold: var(--miami-gold, #b99b63);
    position:relative; min-height:100svh; height:100svh;
    /* El poster de FONDO, no solo en <video poster>: en iOS con Low Power el
       video ni arranca y el hero quedaba un bloque negro vacío. Así SIEMPRE
       pinta imagen (el DS solo pisa el background-color). */
    background:#0E0B08 url('{{ "videos/hero-miami-poster.jpg" | static_url }}') center/cover no-repeat;
    overflow:hidden;
    display:flex; align-items:flex-end;
    isolation:isolate;
  }
  .mi-hero__video{
    position:absolute; inset:0; width:100%; height:100%;
    object-fit:cover; object-position:center; z-index:0;
  }
  /* Scrim: oscurece abajo/izquierda para que el branding SIEMPRE se lea,
     deja respirar el video arriba/derecha. */
  .mi-hero__scrim{
    position:absolute; inset:0; z-index:1;
    background:
      linear-gradient(90deg, rgba(5,5,5,.85) 0%, rgba(5,5,5,.45) 42%, transparent 72%),
      linear-gradient(0deg,  rgba(5,5,5,.92) 0%, rgba(5,5,5,.30) 42%, transparent 78%);
  }

  .mi-hero__top{
    position:absolute; top:clamp(22px,4vh,40px); left:clamp(22px,5vw,72px); z-index:3;
  }
  .mi-hero__eyebrow{
    display:inline-flex; align-items:center; gap:14px;
    font-size:clamp(9px,.95vw,11px); letter-spacing:.4em; text-transform:uppercase;
    color:var(--gold); font-weight:600;
  }
  .mi-hero__eyebrow i{ width:clamp(24px,4vw,52px); height:1px; background:var(--gold); display:inline-block; }

  .mi-hero__content{
    position:relative; z-index:3;
    padding:clamp(28px,5vw,72px) clamp(22px,5vw,72px) clamp(64px,9vh,96px);
    max-width:min(720px,90vw);
  }
  .mi-hero__logo{
    height:clamp(72px,11vh,140px); width:auto; margin:0 0 clamp(20px,3vh,30px);
    filter:drop-shadow(0 8px 30px rgba(0,0,0,.6));
  }
  .mi-hero__tag{
    margin:0 0 clamp(28px,4vh,40px); max-width:40ch;
    font-size:clamp(15px,1.4vw,20px); line-height:1.6; letter-spacing:.01em;
    color:rgba(245,243,238,.82);
  }
  .mi-hero__tag-strong{ color:#fff; }

  .mi-hero__cta{ display:flex; flex-wrap:wrap; gap:14px; }
  .mi-hero__btn{
    display:inline-flex; align-items:center; gap:10px;
    padding:16px 30px; border-radius:999px;               /* iPhone / liquid: pill */
    font-size:12px; letter-spacing:.14em; text-transform:uppercase; font-weight:600;
    border:1px solid transparent; transition:.4s cubic-bezier(.22,.61,.36,1); will-change:transform;
  }
  .mi-hero__btn--gold{ background:var(--gold); color:#0b0b0b; box-shadow:0 10px 34px rgba(185,155,99,.28); }
  .mi-hero__btn--gold:hover{ background:#d4bb88; }
  .mi-hero__btn--ghost{
    color:#fff; border-color:rgba(255,255,255,.35);
    -webkit-backdrop-filter:blur(10px); backdrop-filter:blur(10px);
    background:rgba(255,255,255,.06);
  }
  .mi-hero__btn--ghost:hover{ border-color:var(--gold); color:var(--gold); }

  /* Scroll cue ELIMINADO a pedido de Juani (cargaba el hero y se pisaba con los CTAs) */
  .mi-hero__scroll{ display:none !important; }
  .mi-hero__scroll{
    position:absolute; left:50%; bottom:18px; transform:translateX(-50%); z-index:3;
    width:22px; height:36px; border:1px solid rgba(245,243,238,.3); border-radius:12px;
  }
  .mi-hero__scroll span{ position:absolute; left:50%; top:7px; width:2px; height:7px; background:var(--gold);
    transform:translateX(-50%); border-radius:2px; animation:mi-hero-scroll 1.8s ease-in-out infinite; }
  @keyframes mi-hero-scroll{ 0%,100%{opacity:0;transform:translate(-50%,0)} 40%{opacity:1} 70%{opacity:0;transform:translate(-50%,12px)} }

  /* Entrada sutil (FOUC-safe) */
  .mi-hero.mi-anim .mi-hero__content > *{ opacity:0; transform:translateY(22px); }
  .mi-hero.mi-anim.is-in .mi-hero__content > *{
    opacity:1; transform:none;
    transition:opacity .9s cubic-bezier(.16,1,.3,1), transform .9s cubic-bezier(.16,1,.3,1);
  }
  .mi-hero.mi-anim.is-in .mi-hero__logo{ transition-delay:.05s; }
  .mi-hero.mi-anim.is-in .mi-hero__tag{ transition-delay:.15s; }
  .mi-hero.mi-anim.is-in .mi-hero__cta{ transition-delay:.25s; }

  @media(max-width:640px){
    /* 92svh: el tagline + CTAs entran en el viewport inicial (no un mar de
       negro) y asoma el ticker, que invita a scrollear. */
    .mi-hero{ min-height:92svh; height:92svh; }
    .mi-hero__scrim{ background:linear-gradient(0deg, rgba(5,5,5,.92) 0%, rgba(5,5,5,.28) 55%, transparent 88%); }
    .mi-hero__content{ max-width:100%; padding-bottom:clamp(48px,7vh,72px); }
    .mi-hero__btn{ flex:1 1 auto; justify-content:center; }
    /* En celu el wordmark quemado del video YA lleva la marca: el eyebrow HTML
       encima era doble branding pisándose. Fuera. */
    .mi-hero__top{ display:none; }
  }
  @media(prefers-reduced-motion:reduce){
    .mi-hero__scroll span{ animation:none !important; }
    .mi-hero.mi-anim .mi-hero__content > *{ opacity:1 !important; transform:none !important; }
  }
</style>

<script>
(function(){
  var el=document.getElementById('mi-hero'); if(!el) return;
  el.classList.add('mi-anim');
  requestAnimationFrame(function(){ requestAnimationFrame(function(){ el.classList.add('is-in'); }); });
  // Algunos browsers bloquean autoplay hasta interacción: reintento play mudo.
  var v=el.querySelector('.mi-hero__video');
  if(v){ v.muted=true; var p=v.play&&v.play(); if(p&&p.catch){ p.catch(function(){}); } }
})();
</script>
