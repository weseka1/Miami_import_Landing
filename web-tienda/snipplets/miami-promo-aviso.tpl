{# ============================================================================
   AVISO DE PROMO — el cartel que salta al entrar
   ============================================================================
   Reglas que se respetaron y por qué, para que nadie las deshaga sin saber:

   1. 🔴 NO aparece en /carrito, /checkout, /pagar ni /cuenta. Un cartel encima
      de alguien que está por pagar es la forma más cara de perder una venta:
      ya lo convenciste, no lo interrumpas.
   2. Se muestra UNA vez cada 3 días (localStorage), no en cada visita. Un
      popup que salta siempre se cierra sin leer y entrena a ignorarlo.
   3. Espera 1,2 s. Si aparece encima de la primera pintura, empeora el LCP y
      tapa el hero justo cuando está cargando.
   4. Los medios de pago son los que la tienda cobra DE VERDAD: tarjeta,
      transferencia y efectivo. 🔴 NO dice cuotas: `installments` no está
      configurado en Stripe, y 🔴 ya NO dice "transferencia con descuento
      adicional": ese segundo descuento se prometía sin número en cuatro
      lugares distintos y nadie definió si se suma al de la promo. Un
      descuento sin número apilado sobre otro es la misma trampa que el
      descuento que no se aplica.
   5. Modal propio, no `window.confirm` — el nativo bloquea el hilo (regla de
      la casa) y no se puede maquetar.

   ── EL REDISEÑO (11-sep) ────────────────────────────────────────────────────
   Antes era una caja de vidrio centrada de 420 px: seis bloques apilados del
   mismo peso, con un recuadro gris de viñetas en el medio. O sea, el lenguaje
   visual de un aviso de cookies. Juani: "que sea más llamativo, no tan
   básico, que realmente sea profesional".

   Lo que lo cambia no es el color: es la FOTO y la ESCALA.
   · Dos columnas. A la izquierda una foto real de adentro de una tienda de
     Milán, a sangre. Es el activo que ninguna competencia tiene —onekickz,
     la referencia que puso Diego, hace exactamente esto pero con una foto de
     su local de Buenos Aires— y es la prueba de lo que el texto afirma.
   · La cifra pasa de 76 px a ~120 px. "Llamativo" se gana con tamaño y
     contraste, no subiendo la saturación.

   ── EL MOVIMIENTO ───────────────────────────────────────────────────────────
   Juani preguntó si podía tener "algún efecto súper exclusivo extra". Sí, y
   el criterio es uno: lo caro se siente cuando las cosas entran ORDENADAS y
   se ASIENTAN, no cuando parpadean. Todo lo de acá es una sola vez —nada en
   loop, porque el loop es justamente lo que abarata—:

     1. La caja no hace fade: entra desenfocada y se ENFOCA (blur 14→0 con
        scale .94→1). Es el gesto de un objeto que se acerca, no de una capa
        que aparece.
     2. La foto arranca en scale 1.14 y se asienta en 1 durante 1,6 s, como
        una cámara que se estabiliza. Sigue moviéndose un rato después de que
        el resto ya paró: eso es lo que da la sensación de peso.
     3. 🔴 LA CIFRA LLEGA A LOS OJOS. Pedido textual de Juani (11-sep): "que
        salga agrandándose pasando de desenfoque a enfoque de una forma
        sutil, que básicamente llegue a nuestros ojos". Arranca al 68% y con
        15 px de blur —como algo que todavía está lejos— y se asienta nítida
        en 1,25 s.
        La primera versión revelaba los dígitos de a uno por clip-path y se
        cambió: con cada dígito entrando por su cuenta el ojo los lee como
        piezas sueltas y se pierde lo que se buscaba, que es UNA cosa
        viniendo hacia vos. Lo sutil está en la desaceleración del easing,
        no en cuánto viaja.
     4. El resto entra escalonado detrás (eyebrow → bajada → pagos → CTA).

   Todo esto se apaga entero con `prefers-reduced-motion`, y el cartel queda
   perfectamente legible sin una sola animación.

   ── LA FOTO ES UN LINK ──────────────────────────────────────────────────────
   "Que se pueda entrar al producto mostrado" (Juani, 11-sep). La foto lleva
   a la ficha del producto que se ve en ella, con una pastilla arriba a la
   derecha que lo nombra: si es clicable tiene que PARECER clicable, no ser
   un misterio que se descubre pasando el mouse. El handle vive en
   `core/promo.py` junto a la foto, para que no se separen.
============================================================================ #}
{% set pr = promo() %}
{% set ruta = request.url.path %}
{% if pr.vigente and not (ruta.startswith('/carrito') or ruta.startswith('/checkout')
                          or ruta.startswith('/pagar') or ruta.startswith('/cuenta')) %}
<div class="mi-aviso" id="mi-aviso" role="dialog" aria-modal="true"
     aria-labelledby="mi-aviso-t" aria-describedby="mi-aviso-d" hidden>
  <div class="mi-aviso__fondo" data-cerrar></div>

  <div class="mi-aviso__caja" tabindex="-1">
    <button type="button" class="mi-aviso__x" data-cerrar aria-label="Cerrar el aviso">&times;</button>

    {# La foto LLEVA AL PRODUCTO que se ve en ella (pedido de Juani, 11-sep).
       Cuando hay link deja de ser decorativa: ahí el alt sí tiene que decir
       a dónde va, porque es el texto del enlace. Sin link vuelve a ser una
       figure muda con alt vacío, para que el lector de pantalla no repita lo
       que ya dice el texto de al lado.
       `loading=lazy` + prioridad baja: el cartel recién aparece a los 1,2 s,
       no tiene que pelear con el hero por el ancho de banda. #}
    {% set _foto %}
      <img src="{{ pr.foto | media_url }}"
           alt="{% if pr.foto_link %}Ver {{ pr.foto_producto or 'el producto de la foto' }}{% endif %}"
           loading="lazy" fetchpriority="low" decoding="async" width="900" height="1200"/>
      {# El pie se parte para poder acortarlo en el celu: ahí la foto es
         full-width y no entran la credencial larga Y el nombre del producto
         en la misma fila. Queda "Milán" y se esconde el resto. #}
      {% set _pie = (pr.foto_pie or '').split(' · ') %}
      <span class="mi-aviso__pie">{{ _pie[0] }}{% if _pie|length > 1
        %}<span class="mi-aviso__pie-larga"> · {{ _pie[1:]|join(' · ') }}</span>{% endif %}</span>
      {% if pr.foto_link %}<span class="mi-aviso__vermas">{{ pr.foto_producto or 'Ver la pieza' }} <b aria-hidden="true">→</b></span>{% endif %}
    {% endset %}
    {% if pr.foto %}
      {% if pr.foto_link %}
        <a class="mi-aviso__foto mi-aviso__foto--link" href="{{ pr.foto_link }}" data-cerrar-navega>{{ _foto }}</a>
      {% else %}
        <figure class="mi-aviso__foto">{{ _foto }}</figure>
      {% endif %}
    {% endif %}

    <div class="mi-aviso__cuerpo">
      <p class="mi-aviso__eyebrow mi-aviso__e1">Milano <span aria-hidden="true">→</span> Buenos Aires</p>

      {# El número completo va en aria-label: un lector de pantalla tiene que
         oír "20% OFF", no "2, 0, %". #}
      <p class="mi-aviso__cifra" id="mi-aviso-t"
         aria-label="{{ pr.porcentaje }}% OFF">
        <span aria-hidden="true">{{ pr.porcentaje }}<i>%</i></span>
        <em aria-hidden="true">OFF</em>
      </p>

      <p class="mi-aviso__bajada mi-aviso__e3" id="mi-aviso-d">{{ pr.bajada }}.</p>

      <ul class="mi-aviso__pagos mi-aviso__e4">
        <li>Tarjeta</li>
        <li>Transferencia</li>
        <li>Efectivo</li>
      </ul>

      <a class="mi-aviso__cta mi-aviso__e5" href="/productos" data-cerrar>Ver el catálogo <span aria-hidden="true">→</span></a>
      <button type="button" class="mi-aviso__seguir mi-aviso__e5" data-cerrar>Seguir mirando</button>
    </div>
  </div>
</div>

<style>
  .mi-aviso{position:fixed;inset:0;z-index:1000;display:flex;align-items:center;
    justify-content:center;padding:20px}
  .mi-aviso[hidden]{display:none}
  .mi-aviso__fondo{position:absolute;inset:0;background:rgba(21,22,26,.52);
    -webkit-backdrop-filter:blur(7px);backdrop-filter:blur(7px);
    animation:mi-av-fondo .5s var(--mi-ease) both}

  /* Caja SÓLIDA, no vidrio: el vidrio sobre una foto ensucia los dos. */
  .mi-aviso__caja{position:relative;display:grid;grid-template-columns:44% 56%;
    width:min(940px,100%);max-height:calc(100svh - 40px);overflow:hidden;
    border-radius:26px;background:var(--mi-bg-2);border:1px solid var(--mi-line);
    box-shadow:0 40px 90px rgba(0,0,0,.28);
    animation:mi-av-caja .75s cubic-bezier(.16,1,.3,1) both}
  .mi-aviso__caja:focus{outline:none}

  @keyframes mi-av-fondo{from{opacity:0}to{opacity:1}}
  /* Entra DESENFOCADA y se enfoca. No es un fade. */
  @keyframes mi-av-caja{
    from{opacity:0;transform:translateY(26px) scale(.94);filter:blur(14px)}
    to{opacity:1;transform:none;filter:blur(0)}}

  /* ---- la foto ---- */
  .mi-aviso__foto{position:relative;margin:0;overflow:hidden;display:block;
    background:var(--mi-bg-3)}
  .mi-aviso__foto img{width:100%;height:100%;object-fit:cover;display:block;
    /* 50% vertical = el producto queda centrado en el recorte. La zapatilla
       de esta foto va del 40% al 62% de la altura; medido, no estimado. Si
       se cambia la foto hay que volver a mirar dónde cae la pieza. */
    object-position:50% 50%;transform-origin:50% 45%;
    /* 1,6 s: sigue asentándose cuando el texto ya paró. Ahí está el peso. */
    animation:mi-av-foto 1.6s cubic-bezier(.22,1,.28,1) both}
  @keyframes mi-av-foto{from{transform:scale(1.14)}to{transform:scale(1)}}

  .mi-aviso__pie{position:absolute;left:14px;bottom:14px;
    padding:7px 12px;border-radius:999px;font-size:10.5px;letter-spacing:.14em;
    text-transform:uppercase;color:#fff;background:rgba(21,22,26,.62);
    -webkit-backdrop-filter:blur(8px);backdrop-filter:blur(8px);
    animation:mi-av-sube .7s cubic-bezier(.16,1,.3,1) .75s both}

  /* Cuando la foto es un link tiene que PARECER un link: afordancia visible,
     no un misterio que el usuario descubre pasando el mouse. */
  .mi-aviso__foto--link{cursor:pointer}
  .mi-aviso__vermas{position:absolute;right:14px;top:14px;max-width:calc(100% - 28px);
    display:inline-flex;align-items:center;gap:7px;
    padding:8px 14px;border-radius:999px;font-size:11px;letter-spacing:.1em;
    text-transform:uppercase;font-weight:600;color:var(--mi-ink);
    background:rgba(255,255,255,.93);
    -webkit-backdrop-filter:blur(8px);backdrop-filter:blur(8px);
    box-shadow:0 3px 14px rgba(0,0,0,.16);
    white-space:nowrap;overflow:hidden;text-overflow:ellipsis;
    transition:transform .4s var(--mi-ease);
    animation:mi-av-sube .7s cubic-bezier(.16,1,.3,1) .85s both}
  .mi-aviso__vermas b{font-weight:700;transition:transform .4s var(--mi-ease)}
  .mi-aviso__foto--link:hover .mi-aviso__vermas b{transform:translateX(3px)}
  .mi-aviso__foto--link:hover img{transform:scale(1.04);transition:transform .7s var(--mi-ease)}
  .mi-aviso__foto--link:focus-visible{outline:2px solid var(--mi-accent);outline-offset:-4px}

  /* ---- el cuerpo ---- */
  .mi-aviso__cuerpo{padding:40px 38px 30px;display:flex;flex-direction:column;
    justify-content:center;min-width:0}
  .mi-aviso__e1,.mi-aviso__e3,.mi-aviso__e4,.mi-aviso__e5{
    animation:mi-av-sube .72s cubic-bezier(.16,1,.3,1) both}
  .mi-aviso__e1{animation-delay:.16s}
  .mi-aviso__e3{animation-delay:.46s}
  .mi-aviso__e4{animation-delay:.54s}
  .mi-aviso__e5{animation-delay:.62s}
  @keyframes mi-av-sube{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:none}}

  .mi-aviso__eyebrow{margin:0 0 16px;font-size:10.5px;letter-spacing:.24em;
    text-transform:uppercase;color:var(--mi-ink-mute)}

  /* La cifra es lo que se lee desde el otro lado de la habitación.
     ── EL GESTO (pedido de Juani, 11-sep) ─────────────────────────────────
     "que salga agrandándose pasando de desenfoque a enfoque de una forma
     sutil, que básicamente LLEGUE A NUESTROS OJOS".
     Es el número entero el que se acerca, no los dígitos de a uno: si cada
     dígito entra por su cuenta, el ojo los lee como piezas sueltas y se
     pierde el efecto de una sola cosa que viene hacia vos. Arranca chico y
     desenfocado —como algo que todavía está lejos— y el easing desacelera
     al final para que se ASIENTE en vez de frenar de golpe. Ahí está lo
     sutil: en la desaceleración, no en la distancia recorrida. */
  .mi-aviso__cifra{margin:0;line-height:.86;font-weight:800;
    letter-spacing:-.05em;color:var(--mi-promo);
    font-size:clamp(66px,9vw,120px);font-variant-numeric:tabular-nums;
    display:flex;align-items:baseline;gap:.1em;flex-wrap:wrap;
    transform-origin:50% 50%;
    /* will-change: el blur animado sin capa propia parpadea en Safari iOS. */
    will-change:transform,filter;
    animation:mi-av-llega 1.25s cubic-bezier(.2,.75,.2,1) .3s both}
  .mi-aviso__cifra span{display:inline-flex;align-items:baseline}
  .mi-aviso__cifra i{font-style:normal;font-size:.46em;margin-left:.04em}
  .mi-aviso__cifra em{font-style:normal;font-size:.62em;letter-spacing:-.03em;
    margin-left:.12em;color:var(--mi-ink)}
  @keyframes mi-av-llega{
    from{opacity:0;transform:scale(.68);filter:blur(15px)}
    55%{opacity:1}
    to{opacity:1;transform:scale(1);filter:blur(0)}}

  .mi-aviso__bajada{margin:16px 0 0;font-size:15.5px;line-height:1.55;
    color:var(--mi-ink-soft);max-width:34ch}

  /* Tira horizontal con separadores, no una caja de viñetas. */
  .mi-aviso__pagos{list-style:none;display:flex;flex-wrap:wrap;align-items:center;
    gap:8px 14px;margin:22px 0 26px;padding:16px 0 0;
    border-top:1px solid var(--mi-line)}
  .mi-aviso__pagos li{font-size:12px;letter-spacing:.12em;text-transform:uppercase;
    color:var(--mi-ink-mute);display:flex;align-items:center;gap:14px}
  .mi-aviso__pagos li+li::before{content:"";width:3px;height:3px;border-radius:999px;
    background:var(--mi-line);flex:none;margin-left:-8px}

  .mi-aviso__cta{display:inline-flex;align-items:center;justify-content:center;
    gap:8px;padding:16px 26px;border-radius:999px;
    background:var(--mi-accent);color:var(--mi-bg-2);
    font-size:13px;letter-spacing:.14em;text-transform:uppercase;font-weight:700;
    transition:transform .45s var(--mi-ease),box-shadow .45s var(--mi-ease)}
  .mi-aviso__cta:hover{transform:translateY(-2px);box-shadow:var(--mi-shadow-lift)}
  .mi-aviso__cta:focus-visible,.mi-aviso__seguir:focus-visible{
    outline:2px solid var(--mi-accent);outline-offset:3px}
  .mi-aviso__seguir{display:block;width:100%;margin-top:12px;padding:8px;
    border:0;background:none;cursor:pointer;
    font-size:12.5px;color:var(--mi-ink-mute);letter-spacing:.04em}
  .mi-aviso__seguir:hover{color:var(--mi-ink)}

  .mi-aviso__x{position:absolute;top:12px;right:12px;z-index:2;width:38px;height:38px;
    border:0;border-radius:999px;background:var(--mi-bg-2);color:var(--mi-ink-mute);
    font-size:22px;line-height:1;cursor:pointer;
    box-shadow:0 2px 10px rgba(0,0,0,.12)}
  .mi-aviso__x:hover{color:var(--mi-ink)}
  .mi-aviso__x:focus-visible{outline:2px solid var(--mi-accent);outline-offset:2px}

  /* ---- mobile: una columna, la foto pasa a franja ---- */
  @media (max-width:760px){
    .mi-aviso{padding:14px}
    .mi-aviso__caja{grid-template-columns:1fr;width:min(440px,100%);
      overflow-y:auto;overscroll-behavior:contain}
    /* 190 px, no 132. Con la franja corta el producto entraba justo al filo
       —la zapatilla de esta foto va del 40% al 62% de la altura y quedaba
       cortada arriba—. Con 190 px se ve la pieza entera y le queda aire
       arriba y abajo, que es lo que Juani pidió: "que se vea bien centrado
       el producto desde el celu". Sigue sin empujar el CTA fuera de
       pantalla: medido a 390 y a 375 px. */
    .mi-aviso__foto{height:190px}
    .mi-aviso__foto img{object-position:50% 50%;transform-origin:50% 50%}
    /* 🔴 En el celu la foto es full-width y el botón de cerrar le queda
       ENCIMA: con la pastilla arriba a la derecha, la X tapaba el nombre del
       producto y se leía "NIKE MIND 00". Baja a la fila de abajo, del lado
       opuesto al pie, y el pie se acorta a "Milán" para que entren los dos. */
    .mi-aviso__vermas{top:auto;bottom:12px;right:12px;max-width:56%;
      font-size:10.5px;padding:7px 12px}
    .mi-aviso__pie{left:12px;bottom:12px;max-width:40%}
    .mi-aviso__pie-larga{display:none}
    .mi-aviso__cuerpo{padding:24px 22px 20px}
    .mi-aviso__cifra{font-size:clamp(58px,17vw,78px)}
    .mi-aviso__bajada{font-size:14.5px;margin-top:12px}
    .mi-aviso__pagos{margin:16px 0 18px;padding-top:13px}
  }

  /* Movimiento apagado: se ve TODO, sin una sola animación.
     🔴 La cifra necesita `filter:none` ADEMÁS de `animation:none`: sin eso
     se queda con el blur del fotograma inicial y el número aparece
     ilegible justo para quien pidió menos movimiento. */
  @media (prefers-reduced-motion:reduce){
    .mi-aviso__fondo,.mi-aviso__caja,.mi-aviso__foto img,.mi-aviso__pie,
    .mi-aviso__vermas,.mi-aviso__cifra,.mi-aviso__e1,.mi-aviso__e3,
    .mi-aviso__e4,.mi-aviso__e5{animation:none}
    .mi-aviso__cifra{filter:none;transform:none;opacity:1}
    .mi-aviso__cta,.mi-aviso__foto--link img,.mi-aviso__vermas b{transition:none}
  }
</style>

<script nonce="{{ csp_nonce }}">
(function(){
  var aviso = document.getElementById('mi-aviso');
  if (!aviso) return;
  // La llave lleva el porcentaje Y la versión del diseño: al cambiar
  // cualquiera de los dos, el que ya lo había cerrado vuelve a verlo. Es lo
  // que se quiere cuando cambia la OFERTA; sin esto, el que cerró el cartel
  // del 15% nunca se entera de que ahora es 20%.
  var LLAVE = 'mi_aviso_promo_{{ pr.porcentaje }}_v2';
  var DIAS  = 3;

  // localStorage puede tirar excepción (modo privado viejo, cookies de sitio
  // bloqueadas). Si falla, el aviso se muestra igual: es preferible mostrarlo
  // de más que romper la home entera por un try/catch que falta.
  function visto(){
    try { var t = localStorage.getItem(LLAVE);
          return t && (Date.now() - parseInt(t,10)) < DIAS*864e5; }
    catch(e){ return false; }
  }
  function marcar(){ try { localStorage.setItem(LLAVE, String(Date.now())); } catch(e){} }

  var previo = null;
  function cerrar(){
    aviso.hidden = true;
    document.removeEventListener('keydown', porTecla);
    marcar();
    if (previo && previo.focus) previo.focus();   // el foco vuelve de donde salió
  }
  function porTecla(e){
    if (e.key === 'Escape') { cerrar(); return; }
    if (e.key !== 'Tab') return;
    // El tabulador no se escapa del cartel mientras está abierto.
    var f = aviso.querySelectorAll('a[href],button:not([disabled])');
    if (!f.length) return;
    var pri = f[0], ult = f[f.length-1];
    if (e.shiftKey && document.activeElement === pri){ e.preventDefault(); ult.focus(); }
    else if (!e.shiftKey && document.activeElement === ult){ e.preventDefault(); pri.focus(); }
  }
  function abrir(){
    if (visto()) return;
    previo = document.activeElement;
    aviso.hidden = false;
    document.addEventListener('keydown', porTecla);
    // El foco va a la CAJA, no al botón: enfocar el CTA le dibuja el anillo
    // encima y se ve como un borde doble, igual que si estuviera roto. La caja
    // tiene tabindex="-1" para poder recibirlo sin entrar en el tabulado.
    var caja = aviso.querySelector('.mi-aviso__caja');
    if (caja) caja.focus({preventScroll:true});
  }

  aviso.querySelectorAll('[data-cerrar]').forEach(function(b){
    b.addEventListener('click', function(ev){
      // El CTA es un link: se marca como visto pero se deja navegar.
      if (b.classList.contains('mi-aviso__cta')) { marcar(); return; }
      ev.preventDefault(); cerrar();
    });
  });

  // La foto lleva al producto que se ve en ella. Se marca como visto y se
  // deja navegar: NO se llama a cerrar(), porque cerrar() devuelve el foco
  // al elemento previo y eso pelea con la navegación que ya arrancó.
  aviso.querySelectorAll('[data-cerrar-navega]').forEach(function(a){
    a.addEventListener('click', function(){ marcar(); });
  });

  // 1,2 s: que el hero termine de pintar antes de taparlo.
  setTimeout(abrir, 1200);
})();
</script>
{% endif %}
