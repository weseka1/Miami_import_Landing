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
      configurado en Stripe. Prometer cuotas que no se pueden cobrar es la
      misma trampa que el descuento que no se aplica.
   5. Modal propio, no `window.confirm` — el nativo bloquea el hilo (regla de
      la casa) y no se puede maquetar.
============================================================================ #}
{% set pr = promo() %}
{% set ruta = request.url.path %}
{% if pr.vigente and not (ruta.startswith('/carrito') or ruta.startswith('/checkout')
                          or ruta.startswith('/pagar') or ruta.startswith('/cuenta')) %}
<div class="mi-aviso" id="mi-aviso" role="dialog" aria-modal="true"
     aria-labelledby="mi-aviso-t" aria-describedby="mi-aviso-d" hidden>
  <div class="mi-aviso__fondo" data-cerrar></div>
  <div class="mi-aviso__caja" tabindex="-1">
    <button type="button" class="mi-aviso__x" data-cerrar aria-label="Cerrar el aviso">×</button>

    <p class="mi-aviso__eyebrow">Milano → Buenos Aires</p>
    <p class="mi-aviso__cifra" id="mi-aviso-t">{{ pr.porcentaje }}<span>%</span> OFF</p>
    <p class="mi-aviso__bajada" id="mi-aviso-d">{{ pr.bajada }}.</p>

    <div class="mi-aviso__pagos">
      <p class="mi-aviso__pagos-t">Cómo se paga</p>
      <ul>
        <li><strong>Tarjeta</strong><span>Crédito o débito, en la web</span></li>
        <li><strong>Transferencia</strong><span>Con descuento adicional</span></li>
        <li><strong>Efectivo</strong><span>En la entrega, CABA y GBA</span></li>
      </ul>
    </div>

    <a class="mi-aviso__cta" href="/productos" data-cerrar>Ver el catálogo →</a>
    <button type="button" class="mi-aviso__seguir" data-cerrar>Seguir mirando</button>
  </div>
</div>

<style>
  .mi-aviso{position:fixed;inset:0;z-index:1000;display:flex;align-items:center;
    justify-content:center;padding:20px}
  .mi-aviso[hidden]{display:none}
  .mi-aviso__fondo{position:absolute;inset:0;background:rgba(21,22,26,.42);
    -webkit-backdrop-filter:blur(6px);backdrop-filter:blur(6px);
    animation:mi-aviso-fondo .45s var(--mi-ease) both}
  .mi-aviso__caja:focus{outline:none}
  .mi-aviso__caja{position:relative;width:min(420px,100%);max-height:calc(100svh - 40px);
    overflow:auto;overscroll-behavior:contain;
    padding:34px 30px 26px;border-radius:28px;text-align:center;
    background:var(--mi-glass-strong);border:1px solid var(--mi-line);
    border-top-color:var(--mi-glass-line);
    -webkit-backdrop-filter:blur(var(--mi-blur)) saturate(170%);
    backdrop-filter:blur(var(--mi-blur)) saturate(170%);
    box-shadow:var(--mi-shadow-lift);
    animation:mi-aviso-caja .5s var(--mi-ease) both}
  @keyframes mi-aviso-fondo{from{opacity:0}to{opacity:1}}
  @keyframes mi-aviso-caja{from{opacity:0;transform:translateY(18px) scale(.97)}
                           to{opacity:1;transform:none}}

  .mi-aviso__x{position:absolute;top:12px;right:12px;width:36px;height:36px;
    border:0;border-radius:999px;background:none;color:var(--mi-ink-mute);
    font-size:22px;line-height:1;cursor:pointer}
  .mi-aviso__x:hover{background:var(--mi-bg-3);color:var(--mi-ink)}
  .mi-aviso__x:focus-visible{outline:2px solid var(--mi-accent);outline-offset:2px}

  .mi-aviso__eyebrow{margin:0 0 14px;font-size:10.5px;letter-spacing:.24em;
    text-transform:uppercase;color:var(--mi-ink-mute)}
  /* El número es el que tiene que leerse desde el otro lado de la habitación:
     ahí está lo "llamativo", en el tamaño, no en un color chillón. */
  .mi-aviso__cifra{margin:0;font-size:clamp(54px,15vw,76px);line-height:.9;
    font-weight:800;letter-spacing:-.045em;color:var(--mi-promo);
    font-variant-numeric:tabular-nums}
  .mi-aviso__cifra span{font-size:.5em;vertical-align:super;margin-left:2px}
  .mi-aviso__bajada{margin:12px 0 0;font-size:15px;line-height:1.55;
    color:var(--mi-ink);max-width:30ch;margin-inline:auto}

  .mi-aviso__pagos{margin:24px 0 22px;padding:18px 16px;border-radius:20px;
    background:var(--mi-bg-3);text-align:left}
  .mi-aviso__pagos-t{margin:0 0 12px;font-size:10.5px;letter-spacing:.2em;
    text-transform:uppercase;color:var(--mi-ink-mute)}
  .mi-aviso__pagos ul{list-style:none;margin:0;padding:0;display:grid;gap:9px}
  .mi-aviso__pagos li{display:flex;flex-direction:column;gap:1px;
    padding-left:14px;position:relative}
  /* Un punto, no un emoji: los emojis como íconos están vetados en la casa. */
  .mi-aviso__pagos li::before{content:"";position:absolute;left:0;top:7px;
    width:5px;height:5px;border-radius:999px;background:var(--mi-ink)}
  .mi-aviso__pagos strong{font-size:14px;font-weight:600;color:var(--mi-ink)}
  .mi-aviso__pagos span{font-size:12.5px;color:var(--mi-ink-soft)}

  .mi-aviso__cta{display:block;padding:15px 20px;border-radius:999px;
    background:var(--mi-accent);color:var(--mi-bg-2);
    font-size:13px;letter-spacing:.14em;text-transform:uppercase;font-weight:700;
    transition:transform .4s var(--mi-ease),box-shadow .4s var(--mi-ease)}
  .mi-aviso__cta:hover{transform:translateY(-2px);box-shadow:var(--mi-shadow-lift)}
  .mi-aviso__cta:focus-visible,.mi-aviso__seguir:focus-visible{
    outline:2px solid var(--mi-accent);outline-offset:3px}
  .mi-aviso__seguir{display:block;width:100%;margin-top:12px;padding:6px;
    border:0;background:none;cursor:pointer;
    font-size:12.5px;color:var(--mi-ink-mute);letter-spacing:.04em}
  .mi-aviso__seguir:hover{color:var(--mi-ink)}

  @supports not ((backdrop-filter:blur(1px)) or (-webkit-backdrop-filter:blur(1px))){
    .mi-aviso__caja{background:var(--mi-bg-2)}
    .mi-aviso__fondo{background:rgba(21,22,26,.6)}
  }
  @media (prefers-reduced-motion:reduce){
    .mi-aviso__fondo,.mi-aviso__caja{animation:none}
    .mi-aviso__cta{transition:none}
  }
  @media (max-width:420px){
    .mi-aviso{padding:14px}
    .mi-aviso__caja{padding:30px 22px 22px;border-radius:24px}
  }
</style>

<script nonce="{{ csp_nonce }}">
(function(){
  var aviso = document.getElementById('mi-aviso');
  if (!aviso) return;
  var LLAVE = 'mi_aviso_promo_{{ pr.porcentaje }}';
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
    // El foco va a la CAJA, no al boton: enfocar el CTA le dibuja el anillo
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

  // 1,2 s: que el hero termine de pintar antes de taparlo.
  setTimeout(abrir, 1200);
})();
</script>
{% endif %}
