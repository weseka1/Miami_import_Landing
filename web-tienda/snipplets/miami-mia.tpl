{# ============================================================
   MIA — chat de la casa (widget flotante, todas las páginas)
   FAB glass champagne abajo-derecha → panel de chat.
   Mobile: bottom-sheet full-width (h:100dvh). Desktop: card 380px.
   Estándar WESEKA: input 16px, overscroll-contain, scroll-lock,
   radios iPhone, backdrop blur, z-index 80 (bajo el grano 90).
   ============================================================ #}
<style>
  /* Contenedor NEUTRO (static, sin z-index): si fuera fixed+z-index crearía un
     stacking context que capa a los hijos por debajo del header sticky (200). */
  #mia-root{font-family:'Helvetica Neue',Helvetica,Inter,Arial,sans-serif}
  /* ---- FAB ---- */
  .mia-fab{position:fixed;bottom:22px;right:22px;z-index:80;display:flex;align-items:center;gap:10px;
    padding:12px 20px 12px 14px;border:1px solid rgba(198,167,104,.4);border-radius:999px;cursor:pointer;
    background:rgba(23,18,14,.72);color:#F2EAD9;
    -webkit-backdrop-filter:blur(16px) saturate(150%);backdrop-filter:blur(16px) saturate(150%);
    box-shadow:0 14px 40px rgba(0,0,0,.45);
    transition:transform .35s cubic-bezier(.16,1,.3,1),border-color .35s,background .35s}
  .mia-fab:hover{transform:translateY(-3px);border-color:rgba(224,200,143,.75);background:rgba(23,18,14,.9)}
  .mia-fab svg{width:20px;height:20px;flex:none}
  .mia-fab span{font-size:13px;letter-spacing:.14em;text-transform:uppercase;color:#e0c88f;font-weight:600}
  /* ---- Panel ---- */
  .mia-panel{position:fixed;z-index:80;display:none;flex-direction:column;overflow:hidden;
    background:rgba(14,11,8,.92);border:1px solid rgba(198,167,104,.28);
    -webkit-backdrop-filter:blur(22px) saturate(150%);backdrop-filter:blur(22px) saturate(150%);
    box-shadow:0 30px 80px rgba(0,0,0,.6)}
  .mia-panel.is-open{display:flex}
  @media(min-width:641px){
    .mia-panel{right:22px;bottom:22px;width:380px;height:min(600px,calc(100dvh - 44px));border-radius:28px}
  }
  @media(max-width:640px){
    /* BOTTOM-SHEET amoldable (no full-screen: se comía la página y "tosqueaba").
       dvh sigue al teclado en iOS/Android → el input nunca queda tapado.
       z-index 220: el header sticky del sitio usa 200 y tapaba el chat. */
    .mia-panel{left:0;right:0;bottom:0;width:100%;
      height:min(78dvh, 640px);
      border-radius:24px 24px 0 0;
      border-left:0;border-right:0;border-bottom:0;z-index:220;
      background:rgba(14,11,8,.97);
      box-shadow:0 -24px 70px rgba(0,0,0,.55);
      padding-bottom:env(safe-area-inset-bottom)}
    .mia-head{padding-top:14px}
  }
  /* ---- Header ---- */
  .mia-head{display:flex;align-items:center;gap:12px;padding:16px 18px;flex:none;
    border-bottom:1px solid rgba(198,167,104,.2);background:rgba(23,18,14,.6)}
  .mia-head__avatar{width:38px;height:38px;flex:none;border-radius:50%;display:flex;align-items:center;justify-content:center;
    background-color:#c6a768 !important;background-image:linear-gradient(135deg,#c6a768,#8a6f3e) !important;
    color:#0E0B08 !important;font-weight:700;font-size:15px;letter-spacing:.04em}
  .mia-head__meta{flex:1;min-width:0}
  .mia-head__name{font-size:14px;font-weight:700;color:#F2EAD9;letter-spacing:.04em}
  .mia-head__status{display:flex;align-items:center;gap:6px;font-size:11px;color:rgba(242,234,217,.55);margin-top:2px}
  .mia-head__dot{width:7px;height:7px;border-radius:50%;background:#4ade80;box-shadow:0 0 6px rgba(74,222,128,.8);flex:none}
  .mia-close{background:none;border:0;cursor:pointer;color:rgba(242,234,217,.6);padding:8px;border-radius:12px;display:flex}
  .mia-close:hover{color:#e0c88f;background:rgba(255,255,255,.06)}
  .mia-close svg{width:18px;height:18px}
  /* ---- Mensajes ---- */
  .mia-body{flex:1;overflow-y:auto;overscroll-behavior:contain;padding:18px 16px;display:flex;flex-direction:column;gap:10px;
    -webkit-overflow-scrolling:touch}
  .mia-msg{max-width:85%;padding:11px 15px;font-size:14px;line-height:1.55;word-wrap:break-word;overflow-wrap:break-word;white-space:pre-line}
  .mia-msg--bot{align-self:flex-start;background:rgba(255,255,255,.07);color:#F2EAD9;
    border:1px solid rgba(255,255,255,.08);border-radius:4px 18px 18px 18px}
  .mia-msg--user{align-self:flex-end;background:linear-gradient(135deg,#c6a768,#b3924f);color:#17120E;
    border-radius:18px 4px 18px 18px;font-weight:500}
  .mia-msg a{color:#e0c88f;text-decoration:underline;text-underline-offset:2px}
  .mia-msg--user a{color:#17120E}
  .mia-typing{display:flex;gap:5px;align-items:center;padding:14px 16px}
  .mia-typing i{width:6px;height:6px;border-radius:50%;background:rgba(224,200,143,.8);animation:miaBlink 1.2s infinite}
  .mia-typing i:nth-child(2){animation-delay:.2s}
  .mia-typing i:nth-child(3){animation-delay:.4s}
  @keyframes miaBlink{0%,80%,100%{opacity:.25;transform:translateY(0)}40%{opacity:1;transform:translateY(-3px)}}
  /* ---- Input ---- */
  .mia-foot{flex:none;display:flex;gap:10px;padding:12px 14px calc(12px + env(safe-area-inset-bottom));
    border-top:1px solid rgba(198,167,104,.2);background:rgba(23,18,14,.6)}
  /* El theme pisa input[type=text] con !important (fondo blanco, radius 0,
     14px): se blinda con ID + !important. 16px = sin zoom en iOS (Estándar). */
  #mia-panel .mia-input{flex:1;min-width:0;background:rgba(255,255,255,.06) !important;
    border:1px solid rgba(255,255,255,.12) !important;border-radius:999px !important;
    padding:12px 18px !important;color:#F2EAD9 !important;outline:none;
    font-size:16px !important;font-family:inherit !important;-webkit-appearance:none;appearance:none}
  #mia-panel .mia-input::placeholder{color:rgba(242,234,217,.4)}
  #mia-panel .mia-input:focus{border-color:rgba(198,167,104,.55) !important;box-shadow:none !important}
  .mia-send{flex:none;width:46px;height:46px;border-radius:50%;border:0;cursor:pointer;display:flex;align-items:center;justify-content:center;
    background:linear-gradient(135deg,#c6a768,#b3924f);color:#0E0B08;transition:transform .25s cubic-bezier(.16,1,.3,1)}
  .mia-send:hover{transform:scale(1.06)}
  .mia-send:disabled{opacity:.45;cursor:default;transform:none}
  .mia-send svg{width:18px;height:18px}
  html.mia-lock,html.mia-lock body{overflow:hidden !important}
  @media (prefers-reduced-motion:reduce){
    .mia-fab,.mia-send,.mia-close{transition:none}
    .mia-typing i{animation:none;opacity:.7}
  }
</style>

<div id="mia-root">
  <button class="mia-fab" id="mia-fab" type="button" aria-label="Abrir chat con Mia" aria-haspopup="dialog">
    <svg viewBox="0 0 24 24" fill="none" stroke="#e0c88f" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M21 11.5a8.4 8.4 0 0 1-8.5 8.3 8.9 8.9 0 0 1-3.2-.6L3 21l1.9-5.2a8 8 0 0 1-1.4-4.3A8.4 8.4 0 0 1 12 3.2a8.4 8.4 0 0 1 9 8.3z"/>
    </svg>
    <span>Mia</span>
  </button>

  <section class="mia-panel" id="mia-panel" role="dialog" aria-modal="false" aria-label="Chat con Mia de Miami Import">
    <header class="mia-head">
      <div class="mia-head__avatar">M</div>
      <div class="mia-head__meta">
        <div class="mia-head__name">Mia — Miami Import</div>
        <div class="mia-head__status"><span class="mia-head__dot" aria-hidden="true"></span>en línea</div>
      </div>
      <button class="mia-close" id="mia-close" type="button" aria-label="Cerrar chat">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
          <path d="M6 6l12 12M18 6L6 18"/>
        </svg>
      </button>
    </header>
    <div class="mia-body" id="mia-body" aria-live="polite"></div>
    <form class="mia-foot" id="mia-form" autocomplete="off">
      <input class="mia-input" id="mia-input" type="text" maxlength="600"
             placeholder="Escribile a Mia…" aria-label="Tu mensaje para Mia"/>
      <button class="mia-send" id="mia-send" type="submit" aria-label="Enviar mensaje">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M22 2 11 13M22 2l-7 20-4-9-9-4 20-7z"/>
        </svg>
      </button>
    </form>
  </section>
</div>

<script>
(function () {
  var KEY = 'mia_chat_v1';
  var WA_FALLBACK = 'https://wa.me/5491162321391?text=' +
    encodeURIComponent('Hola Diego, vengo de la web de Miami Import. Tengo una consulta.');
  var BIENVENIDA = 'Hola, soy Mia. ¿Buscás algo puntual o te muestro lo nuevo?';

  var fab = document.getElementById('mia-fab');
  var panel = document.getElementById('mia-panel');
  var body = document.getElementById('mia-body');
  var form = document.getElementById('mia-form');
  var input = document.getElementById('mia-input');
  var sendBtn = document.getElementById('mia-send');
  if (!fab || !panel || !body || !form || !input || !sendBtn) return;

  var pending = false;

  function loadHist() {
    try {
      var h = JSON.parse(sessionStorage.getItem(KEY) || '[]');
      return Array.isArray(h) ? h : [];
    } catch (e) { return []; }
  }
  function saveHist(h) {
    try { sessionStorage.setItem(KEY, JSON.stringify(h.slice(-24))); } catch (e) {}
  }

  /* Render seguro: texto como nodos, links [texto](url) y URLs sueltas como <a>.
     Solo se aceptan URLs relativas (/...) o https://. WhatsApp abre en _blank. */
  function appendLinkified(el, text) {
    var re = /\[([^\]]{1,120})\]\((\/[^)\s]*|https:\/\/[^)\s]+)\)|(https:\/\/[^\s)]+)/g;
    var last = 0, m;
    while ((m = re.exec(text)) !== null) {
      if (m.index > last) el.appendChild(document.createTextNode(text.slice(last, m.index)));
      var label = m[1] || m[3];
      var url = m[2] || m[3];
      var a = document.createElement('a');
      a.href = url;
      a.textContent = label;
      if (url.indexOf('https://') === 0) { a.target = '_blank'; a.rel = 'noopener'; }
      el.appendChild(a);
      last = re.lastIndex;
    }
    if (last < text.length) el.appendChild(document.createTextNode(text.slice(last)));
  }

  function bubble(role, text) {
    var div = document.createElement('div');
    div.className = 'mia-msg ' + (role === 'user' ? 'mia-msg--user' : 'mia-msg--bot');
    appendLinkified(div, text);
    body.appendChild(div);
    body.scrollTop = body.scrollHeight;
    return div;
  }

  function typingOn() {
    var t = document.createElement('div');
    t.className = 'mia-msg mia-msg--bot mia-typing';
    t.id = 'mia-typing';
    t.innerHTML = '<i></i><i></i><i></i>';
    body.appendChild(t);
    body.scrollTop = body.scrollHeight;
  }
  function typingOff() {
    var t = document.getElementById('mia-typing');
    if (t) t.remove();
  }

  function renderAll() {
    body.textContent = '';
    bubble('assistant', BIENVENIDA);
    loadHist().forEach(function (msg) { bubble(msg.role, msg.content); });
  }

  var isMobile = function () { return window.matchMedia('(max-width:640px)').matches; };

  function openPanel() {
    panel.classList.add('is-open');
    fab.style.display = 'none';
    if (isMobile()) document.documentElement.classList.add('mia-lock');
    renderAll();
    if (!isMobile()) input.focus();
  }
  function closePanel() {
    panel.classList.remove('is-open');
    fab.style.display = '';
    document.documentElement.classList.remove('mia-lock');
  }

  fab.addEventListener('click', openPanel);
  document.getElementById('mia-close').addEventListener('click', closePanel);
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && panel.classList.contains('is-open')) closePanel();
  });

  form.addEventListener('submit', function (e) {
    e.preventDefault();
    if (pending) return;
    var text = (input.value || '').trim();
    if (!text) return;
    input.value = '';

    var hist = loadHist();
    hist.push({ role: 'user', content: text });
    saveHist(hist);
    bubble('user', text);

    pending = true;
    sendBtn.disabled = true;
    typingOn();

    fetch('/api/mia/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ messages: hist.slice(-12) })
    })
      .then(function (r) {
        if (!r.ok) throw new Error('http ' + r.status);
        return r.json();
      })
      .then(function (data) {
        var reply = (data && data.reply) ? String(data.reply) : '';
        if (!reply) throw new Error('vacio');
        hist.push({ role: 'assistant', content: reply });
        saveHist(hist);
        typingOff();
        bubble('assistant', reply);
      })
      .catch(function () {
        var msg = 'Se me cortó un segundo la conexión. Escribinos directo y te ' +
          'contestamos al toque: [WhatsApp de Diego](' + WA_FALLBACK + ').';
        hist.push({ role: 'assistant', content: msg });
        saveHist(hist);
        typingOff();
        bubble('assistant', msg);
      })
      .then(function () {
        pending = false;
        sendBtn.disabled = false;
        if (!isMobile()) input.focus();
      });
  });

  /* Hook de verificación (mismo patrón que ?debugw=1): abre el chat al cargar. */
  if (location.search.indexOf('miaopen') !== -1) openPanel();
})();
</script>
