{# MIAMI_IMPORT — Aviso de precios USD antes de entrar a la landing.
   Aparece UNA VEZ por sesion (sessionStorage). Si el user ya cerro el aviso
   no se vuelve a mostrar hasta cerrar el browser. #}
<div id="miami-price-notice" class="miami-price-notice" role="dialog" aria-modal="true" aria-labelledby="miami-price-notice-title">
  <div class="miami-price-notice__backdrop" data-miami-notice-close></div>
  <div class="miami-price-notice__card">
    <div class="miami-price-notice__seal">
      <img src="{{ 'images/miami-logo-v4.webp' | static_url }}" alt="" />
    </div>
    <div class="miami-price-notice__eyebrow">PRECIOS · USD</div>
    <h2 class="miami-price-notice__title" id="miami-price-notice-title">
      Los precios están expresados en <span class="miami-price-notice__usd">USD</span>
    </h2>
    <p class="miami-price-notice__body">
      Al finalizar tu compra, podés elegir abonar en <strong>pesos argentinos</strong>
      al dólar oficial seleccionando <strong>Mercado Pago</strong> como medio de pago.
    </p>
    <button type="button" class="miami-price-notice__btn" data-miami-notice-close>
      <span>ENTENDIDO</span>
      <span class="miami-price-notice__btn-arrow">→</span>
    </button>
  </div>
</div>

<style>
  .miami-price-notice {
    position: fixed; inset: 0; z-index: 99998;
    display: flex; align-items: center; justify-content: center;
    padding: 24px;
    opacity: 0;
    visibility: hidden;
    transition: opacity 0.5s cubic-bezier(0.22,0.61,0.36,1),
                visibility 0.5s cubic-bezier(0.22,0.61,0.36,1);
  }
  .miami-price-notice.is-visible {
    opacity: 1;
    visibility: visible;
  }
  .miami-price-notice__backdrop {
    position: absolute; inset: 0;
    background:
      radial-gradient(ellipse 60% 40% at 50% 50%, rgba(21,22,26,0.08) 0%, transparent 70%),
      rgba(0,0,0,0.78);
    -webkit-backdrop-filter: blur(8px) saturate(140%);
    backdrop-filter: blur(8px) saturate(140%);
    cursor: pointer;
  }
  .miami-price-notice__card {
    position: relative; z-index: 1;
    width: 100%; max-width: 460px;
    background:
      radial-gradient(ellipse 80% 40% at 50% 0%, rgba(21,22,26,0.12) 0%, transparent 60%),
      radial-gradient(circle at 50% 50%, rgba(21,22,26,0.06) 1px, transparent 1.6px) 0 0 / 28px 28px,
      #FBFBFA;
    border: 1px solid rgba(21,22,26,0.22);
    border-top: 1px solid rgba(21,22,26,0.5);
    padding: 38px 36px 28px;
    text-align: center;
    color: var(--mi-ink-soft);
    box-shadow:
      0 28px 80px rgba(0,0,0,0.7),
      0 0 0 1px rgba(21,22,26,0.08),
      0 0 60px rgba(21,22,26,0.08);
    transform: translateY(20px) scale(0.96);
    opacity: 0;
    transition: transform 0.7s cubic-bezier(0.22,0.61,0.36,1) 0.08s,
                opacity 0.7s cubic-bezier(0.22,0.61,0.36,1) 0.08s;
  }
  .miami-price-notice.is-visible .miami-price-notice__card {
    transform: translateY(0) scale(1);
    opacity: 1;
  }
  .miami-price-notice__seal {
    margin-bottom: 16px;
  }
  .miami-price-notice__seal img {
    width: auto; max-width: 92px; height: auto;
    display: inline-block;
    filter:
      drop-shadow(0 4px 12px rgba(0,0,0,0.5))
      drop-shadow(0 0 18px rgba(21,22,26,0.3));
  }
  .miami-price-notice__eyebrow {
    font-size: 10px;
    letter-spacing: 0.5em;
    text-transform: uppercase;
    color: #15161A;
    font-weight: 500;
    margin-bottom: 14px;
  }
  .miami-price-notice__title {
    font-size: clamp(18px, 4.2vw, 22px);
    font-weight: 500;
    letter-spacing: 0.02em;
    line-height: 1.3;
    margin: 0 0 18px;
    color: #fff;
  }
  .miami-price-notice__usd {
    color: #15161A;
    font-weight: 600;
    letter-spacing: 0.06em;
  }
  .miami-price-notice__body {
    font-size: 13px;
    line-height: 1.65;
    color: var(--mi-ink);
    margin: 0 0 26px;
  }
  .miami-price-notice__body strong {
    color: #fff;
    font-weight: 500;
  }
  .miami-price-notice__btn {
    display: inline-flex; align-items: center; justify-content: center;
    gap: 12px;
    padding: 14px 36px;
    background: rgba(20,18,15,0.5);
    border: 1px solid rgba(21,22,26,0.55);
    color: #15161A;
    font-family: inherit;
    font-size: 11px;
    letter-spacing: 0.4em;
    text-transform: uppercase;
    font-weight: 500;
    cursor: pointer;
    transition:
      background 0.35s cubic-bezier(0.22,0.61,0.36,1),
      color 0.35s cubic-bezier(0.22,0.61,0.36,1),
      border-color 0.35s cubic-bezier(0.22,0.61,0.36,1),
      box-shadow 0.35s cubic-bezier(0.22,0.61,0.36,1),
      transform 0.35s cubic-bezier(0.22,0.61,0.36,1);
    position: relative;
    overflow: hidden;
  }
  .miami-price-notice__btn::before {
    content: ""; position: absolute; inset: 0;
    background: linear-gradient(120deg, transparent 30%, rgba(21,22,26,0.25) 50%, transparent 70%);
    transform: translateX(-110%);
    transition: transform 0.7s cubic-bezier(0.22,0.61,0.36,1);
    pointer-events: none;
  }
  .miami-price-notice__btn:hover {
    background: #15161A;
    color: #FBFBFA;
    border-color: #15161A;
    box-shadow: 0 0 28px rgba(21,22,26,0.45);
    transform: translateY(-1px);
  }
  .miami-price-notice__btn:hover::before {
    transform: translateX(110%);
  }
  .miami-price-notice__btn-arrow {
    transition: transform 0.35s cubic-bezier(0.22,0.61,0.36,1);
  }
  .miami-price-notice__btn:hover .miami-price-notice__btn-arrow {
    transform: translateX(6px);
  }

  body.is-notice-open { overflow: hidden; }

  @media (max-width: 480px) {
    .miami-price-notice__card { padding: 30px 22px 22px; }
    .miami-price-notice__seal img { max-width: 78px; }
    .miami-price-notice__title { font-size: 18px; }
    .miami-price-notice__body  { font-size: 12.5px; }
    .miami-price-notice__btn   { padding: 13px 26px; font-size: 10px; letter-spacing: 0.32em; }
  }

  @media (prefers-reduced-motion: reduce) {
    .miami-price-notice,
    .miami-price-notice__card,
    .miami-price-notice__btn { transition: none !important; }
    .miami-price-notice__btn::before { display: none; }
  }
</style>

<script>
  (function () {
    var KEY = 'miami_price_notice_seen';
    var notice = document.getElementById('miami-price-notice');
    if (!notice) return;

    /* Si el user ya vio el aviso en esta sesion, no mostrarlo. */
    try {
      if (sessionStorage.getItem(KEY)) {
        if (notice.parentNode) notice.parentNode.removeChild(notice);
        return;
      }
    } catch (e) { /* sessionStorage puede no estar disponible (modo privado) */ }

    /* Mostrar despues de que el preloader se haya escondido (350ms da margen). */
    function show() {
      document.body.classList.add('is-notice-open');
      requestAnimationFrame(function () {
        notice.classList.add('is-visible');
      });
    }
    if (document.body.classList.contains('is-preloading')) {
      /* Esperar a que el preloader se vaya */
      var watcher = new MutationObserver(function () {
        if (!document.body.classList.contains('is-preloading')) {
          watcher.disconnect();
          setTimeout(show, 200);
        }
      });
      watcher.observe(document.body, { attributes: true, attributeFilter: ['class'] });
      /* Failsafe — siempre mostrar despues de 5s */
      setTimeout(function () {
        if (!notice.classList.contains('is-visible')) {
          watcher.disconnect();
          show();
        }
      }, 5000);
    } else {
      setTimeout(show, 200);
    }

    function close() {
      notice.classList.remove('is-visible');
      document.body.classList.remove('is-notice-open');
      try { sessionStorage.setItem(KEY, '1'); } catch (e) {}
      setTimeout(function () {
        if (notice.parentNode) notice.parentNode.removeChild(notice);
      }, 600);
    }

    notice.querySelectorAll('[data-miami-notice-close]').forEach(function (el) {
      el.addEventListener('click', function (e) {
        e.preventDefault();
        close();
      });
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && notice.classList.contains('is-visible')) close();
    });
  })();
</script>
