{#
  VITRINA — placa de vidrio
  ===========================================================================
  Reemplaza a miami-trilogy.tpl. Mismo contrato de datos (home.vitrina.piezas:
  nombre / genero / imagen / ref / colorway / talles / link / descripcion), así
  que Diego la sigue editando desde Mi web sin cambiar nada.

  POR QUÉ ESTÁ ARMADA ASÍ (dos versiones rebotaron antes):
   · La prenda NO se recorta. Las fotos de Diego son de celular adentro de los
     locales de Miami, con la mano y el perchero: cualquier recorte automático
     deja púas y agujeros ("parece que lo cortó un nene con una tijera").
     🔴 Y el fondo TAMPOCO se apaga — Juani, 28-ago: "no me borres los fondos,
     que las fotos queden naturales / originales". La foto entra tal cual, sólo
     encuadrada a 4:5. Que se vea el local es parte de que vienen de Miami.
   · Como el material fotográfico no aguanta un hero a pantalla completa, manda
     la TIPOGRAFÍA y la foto es la prueba, no la estrella.
   · El vidrio es vidrio de verdad: la chapa de datos se apoya SOBRE la foto,
     así el blur tiene algo que refractar. Un panel translúcido sobre un fondo
     liso es un rectángulo gris y se nota. Con fotos naturales atrás (a veces
     un piso claro), la chapa lleva más cuerpo para que el texto se lea.
   · El switch Hombre/Mujer es un segmented control de iOS: hairline + un
     indicador que se desliza. Nada de pastillas con gradiente.
   · El carrusel se agarra y se tira (regla de la casa), y además tiene flechas.
     Si un género tiene una sola pieza, las flechas se esconden.
   · Los géneros salen del DOM: si Diego cambia las piezas, sigue funcionando.
#}
{% set piezas = home.vitrina.piezas %}
{% if piezas %}
<section class="mi-vt" id="mi-vt" data-genero="hombre" aria-label="Piezas de archivo">

  <div class="mi-vt__amb" aria-hidden="true"></div>
  <div class="mi-vt__grano" aria-hidden="true"></div>

  <div class="mi-vt__wrap">

    {# OJO: acá NO va <header>. miami-styles.tpl (herencia de la migración de
       Tiendanube) tiene `body header { background:...!important }` para la barra
       de arriba, y le pega a CUALQUIER <header> de la página: dejaba un
       rectángulo punteado con borde detrás del título. #}
    <div class="mi-vt__head">
      <p class="mi-vt__eyebrow">{{ home.vitrina.eyebrow or 'La casa' }}</p>
      <h2 class="mi-vt__title">{{ home.vitrina.titulo or 'Piezas de archivo' }}</h2>

      <div class="mi-vt__seg" role="tablist" aria-label="Género">
        <span class="mi-vt__seg-ind" aria-hidden="true"></span>
        <button type="button" class="mi-vt__seg-btn is-on" data-g="hombre"
                role="tab" aria-selected="true">Hombre</button>
        <button type="button" class="mi-vt__seg-btn" data-g="mujer"
                role="tab" aria-selected="false">Mujer</button>
      </div>
    </div>

    <div class="mi-vt__body">

      {# ---------- la placa: la foto adentro del vidrio ---------- #}
      <div class="mi-vt__placa" id="mi-vt-placa">
        <span class="mi-vt__spec" aria-hidden="true"></span>
        {% for p in piezas %}
        <figure class="mi-vt__foto{{ ' is-on' if loop.first }}" data-i="{{ loop.index0 }}"
                data-g="{{ p.genero or 'hombre' }}">
          {# la primera se pide ya: es la que se ve al llegar, y con lazy la
             placa quedaba vacia varios segundos en el telefono #}
          <img class="mi-vt__img" src="{{ p.imagen | media_url }}"
               alt="{{ p.nombre }}" draggable="false"
               {% if loop.first %}fetchpriority="high"{% else %}loading="lazy"{% endif %}/>
          {% if p.colorway or p.talles %}
          <figcaption class="mi-vt__chapa">
            {% if p.colorway %}<span>{{ p.colorway }}</span>{% endif %}
            {% if p.colorway and p.talles %}<i aria-hidden="true"></i>{% endif %}
            {% if p.talles %}<span>{{ p.talles }}</span>{% endif %}
          </figcaption>
          {% endif %}
        </figure>
        {% endfor %}
      </div>

      {# ---------- la ficha: acá manda el texto ---------- #}
      <div class="mi-vt__fichas">
        {% for p in piezas %}
        <article class="mi-vt__ficha{{ ' is-on' if loop.first }}" data-i="{{ loop.index0 }}"
                 data-g="{{ p.genero or 'hombre' }}">
          {% if p.ref %}<p class="mi-vt__ref">{{ p.ref }}</p>{% endif %}
          <h3 class="mi-vt__nombre">{{ p.nombre }}</h3>
          {% if p.descripcion %}
          <p class="mi-vt__desc">{{ p.descripcion }}</p>
          {% endif %}
          {% if p.link %}
          <a class="mi-vt__cta" href="{{ p.link }}">
            Ver la pieza <span aria-hidden="true">&#8594;</span>
          </a>
          {% endif %}
        </article>
        {% endfor %}

        <div class="mi-vt__nav">
          <button type="button" class="mi-vt__flecha" data-paso="-1"
                  aria-label="Pieza anterior">
            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15 5l-7 7 7 7"/></svg>
          </button>
          <span class="mi-vt__cuenta" aria-live="polite"><b>01</b>&#8202;/&#8202;<i>01</i></span>
          <button type="button" class="mi-vt__flecha" data-paso="1"
                  aria-label="Pieza siguiente">
            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 5l7 7-7 7"/></svg>
          </button>
        </div>
      </div>

    </div>
  </div>
</section>

<style>
/* ===== VITRINA ============================================================ */
.mi-vt{
  --tinta:#F3EFE7;
  --champ:#C6A970;                 /* el único acento */
  --carbon:#0B0908;                /* nunca #000: near-black cálido */
  --hair:rgba(243,239,231,.13);
  position:relative; isolation:isolate; overflow:clip;
  background:var(--carbon); color:var(--tinta);
  padding:clamp(52px,7vw,92px) 0 clamp(46px,6vw,78px);
}
/* luz ambiental: UNA fuente cálida, no un gradiente decorativo */
.mi-vt__amb{
  position:absolute; inset:-25% -10% auto -20%; height:130%; z-index:0;
  pointer-events:none;
  background:radial-gradient(56% 50% at 28% 24%,
             rgba(198,169,112,.15) 0%, rgba(198,169,112,.045) 44%, transparent 72%);
}
/* grano: materia, es lo que separa "oscuro" de "barato" */
.mi-vt__grano{
  position:absolute; inset:0; z-index:1; pointer-events:none;
  opacity:.05; mix-blend-mode:overlay;
  background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='140' height='140'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.82' numOctaves='3'/%3E%3C/filter%3E%3Crect width='140' height='140' filter='url(%23n)'/%3E%3C/svg%3E");
}
.mi-vt__wrap{
  position:relative; z-index:2;
  width:min(1160px, calc(100% - clamp(28px,6vw,72px)));
  margin-inline:auto;
}

/* ---------------------------------------------------------------- cabecera */
.mi-vt__head{ text-align:center; margin-bottom:clamp(28px,4vw,44px); }
.mi-vt__eyebrow{
  margin:0 0 10px; font-size:11px; letter-spacing:.42em; text-transform:uppercase;
  color:var(--champ);
}
.mi-vt__title{
  margin:0 0 clamp(20px,3vw,30px); font-weight:300; line-height:.96;
  font-size:clamp(28px,5.2vw,54px);
  letter-spacing:-.035em;              /* tracking negativo en display */
}

/* ------------------------------------------------ segmented control (iOS) */
.mi-vt__seg{
  position:relative; display:inline-flex; padding:4px; border-radius:999px;
  border:1px solid var(--hair); background:rgba(243,239,231,.045);
  -webkit-backdrop-filter:blur(14px); backdrop-filter:blur(14px);
}
.mi-vt__seg-ind{
  position:absolute; top:4px; bottom:4px; left:4px; width:calc(50% - 4px);
  border-radius:999px; background:rgba(243,239,231,.10);
  border:1px solid rgba(243,239,231,.16);
  box-shadow:inset 0 1px 0 rgba(255,255,255,.20);
  transition:transform .42s cubic-bezier(.22,1,.36,1), width .3s ease;
}
.mi-vt__seg-btn{
  position:relative; z-index:1; min-height:44px; padding:0 clamp(20px,3.4vw,34px);
  border:0; background:none; cursor:pointer; font:inherit; font-size:12px;
  letter-spacing:.2em; text-transform:uppercase;
  color:rgba(243,239,231,.5); transition:color .3s ease;
}
.mi-vt__seg-btn.is-on{ color:var(--tinta); }
.mi-vt__seg-btn[hidden]{ display:none; }

/* ------------------------------------------------------------------ cuerpo */
.mi-vt__body{
  display:grid; align-items:center;
  gap:clamp(26px,4vw,60px);
  grid-template-columns:minmax(0,.82fr) minmax(0,1fr);
}

/* ------------------------------------------- la placa de vidrio con la foto */
.mi-vt__placa{
  /* 3:4 — es el formato en el que Diego manda las fotos (960x1280). La placa
     se adapta a la foto, no al reves: asi entran ENTERAS y no se recorta nada. */
  position:relative; width:100%; max-width:404px; aspect-ratio:3/4;
  margin-inline:auto; border-radius:26px; overflow:hidden;
  background:#0E0C0B; border:1px solid var(--hair);
  box-shadow:0 44px 96px -34px rgba(0,0,0,.92),
             inset 0 1px 0 rgba(255,255,255,.10);
  cursor:grab; touch-action:pan-y;
}
.mi-vt__placa.is-drag{ cursor:grabbing; }
/* especular: la luz sigue al puntero. Sin esto, "vidrio" es un rectángulo */
.mi-vt__spec{
  position:absolute; inset:0; z-index:3; pointer-events:none; opacity:0;
  transition:opacity .4s ease; mix-blend-mode:screen;
  background:radial-gradient(210px 210px at var(--mx,50%) var(--my,0%),
             rgba(255,255,255,.15), transparent 68%);
}
.mi-vt__placa:hover .mi-vt__spec{ opacity:1; }

.mi-vt__foto{
  position:absolute; inset:0; margin:0; opacity:0; visibility:hidden;
  transform:scale(1.045);
  transition:opacity .6s ease, transform .8s cubic-bezier(.22,1,.36,1);
}
.mi-vt__foto.is-on{ opacity:1; visibility:visible; transform:none; }
.mi-vt__img{
  width:100%; height:100%; object-fit:cover; display:block;
  -webkit-user-drag:none; user-select:none;
}
/* la chapita de vidrio APOYADA sobre la foto: acá el blur sí refracta algo */
.mi-vt__chapa{
  position:absolute; left:14px; right:14px; bottom:14px; z-index:2;
  display:flex; align-items:center; justify-content:center; gap:12px;
  min-height:42px; padding:0 16px; border-radius:14px;
  font-size:11px; letter-spacing:.2em; text-transform:uppercase;
  color:#F3EFE7; background:rgba(12,10,9,.56);
  /* las fotos de local traen pisos claros detras: sin esto el texto de la
     chapa queda al limite de contraste justo donde dice el talle */
  text-shadow:0 1px 3px rgba(0,0,0,.65);
  -webkit-backdrop-filter:blur(20px) saturate(170%);
  backdrop-filter:blur(20px) saturate(170%);
  border:1px solid rgba(243,239,231,.16);
  box-shadow:inset 0 1px 0 rgba(255,255,255,.22),
             inset 0 -1px 0 rgba(0,0,0,.32);
}
.mi-vt__chapa i{ width:3px; height:3px; border-radius:50%; background:var(--champ); flex:none; }

/* ------------------------------------------------------------------ ficha */
.mi-vt__fichas{ position:relative; min-width:0; }
.mi-vt__ficha{
  position:absolute; inset:0 0 auto 0; opacity:0; visibility:hidden;
  transform:translateY(14px);
  transition:opacity .5s ease, transform .6s cubic-bezier(.22,1,.36,1);
}
.mi-vt__ficha.is-on{ position:relative; opacity:1; visibility:visible; transform:none; }
.mi-vt__ref{
  margin:0 0 12px; font-size:11px; letter-spacing:.3em; text-transform:uppercase;
  color:var(--champ);
}
.mi-vt__nombre{
  margin:0 0 16px; font-weight:300; line-height:.98; text-transform:uppercase;
  font-size:clamp(30px,5.6vw,64px); letter-spacing:-.04em;
}
.mi-vt__desc{
  margin:0 0 26px; max-width:44ch; line-height:1.7;
  font-size:clamp(14px,1.1vw,16px); color:rgba(243,239,231,.6);
}
.mi-vt__cta{
  display:inline-flex; align-items:center; gap:10px; min-height:46px;
  padding:0 26px; border-radius:999px; text-decoration:none;
  font-size:12px; letter-spacing:.18em; text-transform:uppercase;
  color:var(--carbon); background:var(--champ);
  transition:transform .3s cubic-bezier(.22,1,.36,1), box-shadow .3s ease;
}
.mi-vt__cta:hover{ transform:translateY(-2px); box-shadow:0 14px 28px -12px rgba(198,169,112,.6); }
.mi-vt__cta span{ transition:transform .3s cubic-bezier(.22,1,.36,1); }
.mi-vt__cta:hover span{ transform:translateX(4px); }

/* ------------------------------------------------------------- navegación */
.mi-vt__nav{ display:flex; align-items:center; gap:14px; margin-top:clamp(24px,3.2vw,36px); }
.mi-vt__nav[hidden]{ display:none; }
.mi-vt__flecha{
  width:46px; height:46px; border-radius:50%; cursor:pointer; flex:none;
  border:1px solid var(--hair); background:rgba(243,239,231,.04);
  -webkit-backdrop-filter:blur(14px); backdrop-filter:blur(14px);
  color:var(--tinta); display:grid; place-items:center;
  transition:background .3s ease, border-color .3s ease, transform .2s ease;
}
.mi-vt__flecha svg{ width:18px; height:18px; fill:none; stroke:currentColor;
  stroke-width:1.4; stroke-linecap:round; stroke-linejoin:round; }
.mi-vt__flecha:hover{ background:rgba(243,239,231,.10); border-color:rgba(243,239,231,.28); }
.mi-vt__flecha:active{ transform:scale(.94); }
.mi-vt__cuenta{
  font-size:11px; letter-spacing:.24em; color:rgba(243,239,231,.45);
  font-variant-numeric:tabular-nums;
}
.mi-vt__cuenta b{ color:var(--tinta); font-weight:400; }
.mi-vt__cuenta i{ font-style:normal; }

/* ------------------------------------------------------------------ mobile */
@media (max-width:860px){
  .mi-vt__body{ grid-template-columns:1fr; gap:26px; }
  .mi-vt__placa{ max-width:min(330px,78vw); }
  .mi-vt__fichas{ text-align:center; }
  .mi-vt__desc{ margin-inline:auto; }
  /* el globo de MIA vive fijo abajo a la derecha y le pisaba la flecha:
     en el teléfono la navegación sube, entre la placa y el texto. */
  .mi-vt__fichas{ display:flex; flex-direction:column; }
  .mi-vt__nav{ order:-1; justify-content:center; margin:2px 0 20px; }
  .mi-vt{ padding-bottom:clamp(64px,14vw,92px); }
}
@media (prefers-reduced-motion:reduce){
  .mi-vt *{ transition:none !important; animation:none !important; }
}
</style>

<script>
(function(){
  var sec = document.getElementById('mi-vt');
  if (!sec) return;
  var placa  = document.getElementById('mi-vt-placa');
  var fotos  = [].slice.call(sec.querySelectorAll('.mi-vt__foto'));
  var fichas = [].slice.call(sec.querySelectorAll('.mi-vt__ficha'));
  var botones= [].slice.call(sec.querySelectorAll('.mi-vt__seg-btn'));
  var nav    = sec.querySelector('.mi-vt__nav');
  var cuenta = sec.querySelector('.mi-vt__cuenta');
  var ind    = sec.querySelector('.mi-vt__seg-ind');
  if (!fotos.length) return;

  // los géneros salen del DOM: si Diego cambia las piezas, esto sigue andando
  var hay = {};
  fotos.forEach(function(f){ hay[f.dataset.g || 'hombre'] = true; });
  botones.forEach(function(b){ if (!hay[b.dataset.g]) b.hidden = true; });

  var genero = hay.hombre ? 'hombre' : Object.keys(hay)[0];
  var indice = 0;

  function delGenero(){
    var r = [];
    fotos.forEach(function(f, i){
      if ((f.dataset.g || 'hombre') === genero) r.push(i);
    });
    return r;
  }

  function pintar(){
    var lista = delGenero();
    if (!lista.length) return;
    if (indice >= lista.length) indice = 0;
    if (indice < 0) indice = lista.length - 1;
    var actual = lista[indice];

    fotos.forEach(function(f, i){ f.classList.toggle('is-on', i === actual); });
    fichas.forEach(function(f, i){ f.classList.toggle('is-on', i === actual); });

    sec.dataset.genero = genero;
    var visibles = botones.filter(function(b){ return !b.hidden; });
    var pos = 0;
    visibles.forEach(function(b, i){
      var on = b.dataset.g === genero;
      if (on) pos = i;
      b.classList.toggle('is-on', on);
      b.setAttribute('aria-selected', on ? 'true' : 'false');
    });
    if (ind) {
      ind.style.width = 'calc(' + (100 / Math.max(1, visibles.length)) + '% - 4px)';
      ind.style.transform = 'translateX(' + (pos * 100) + '%)';
      ind.hidden = visibles.length < 2;
    }
    // una sola pieza no necesita flechas
    if (nav) nav.hidden = lista.length < 2;
    if (cuenta) {
      cuenta.querySelector('b').textContent = ('0' + (indice + 1)).slice(-2);
      cuenta.querySelector('i').textContent = ('0' + lista.length).slice(-2);
    }
  }

  botones.forEach(function(b){
    b.addEventListener('click', function(){
      if (b.dataset.g === genero) return;
      genero = b.dataset.g; indice = 0; pintar();
    });
  });

  [].slice.call(sec.querySelectorAll('.mi-vt__flecha')).forEach(function(b){
    b.addEventListener('click', function(){
      indice += parseInt(b.dataset.paso, 10); pintar();
    });
  });

  if (placa) {
    placa.addEventListener('pointermove', function(e){
      var r = placa.getBoundingClientRect();
      placa.style.setProperty('--mx', ((e.clientX - r.left) / r.width * 100) + '%');
      placa.style.setProperty('--my', ((e.clientY - r.top) / r.height * 100) + '%');
    });

    // agarrar y tirar: la regla de la casa para todo carrusel. El estado vive
    // en estas variables, no en el estado de un framework que remonte el
    // listener en cada frame y se coma el último evento.
    var x0 = 0, movido = false, agarrado = false;
    placa.addEventListener('pointerdown', function(e){
      agarrado = true; movido = false; x0 = e.clientX;
      placa.classList.add('is-drag');
    });
    placa.addEventListener('pointermove', function(e){
      if (agarrado && Math.abs(e.clientX - x0) > 8) movido = true;
    });
    function soltar(e){
      if (!agarrado) return;
      agarrado = false; placa.classList.remove('is-drag');
      var d = (e && e.clientX ? e.clientX : x0) - x0;
      if (Math.abs(d) > 48) { indice += (d < 0 ? 1 : -1); pintar(); }
    }
    placa.addEventListener('pointerup', soltar);
    placa.addEventListener('pointercancel', soltar);
    placa.addEventListener('pointerleave', soltar);
    placa.addEventListener('click', function(e){ if (movido) e.preventDefault(); }, true);
  }

  pintar();
})();
</script>
{% endif %}
