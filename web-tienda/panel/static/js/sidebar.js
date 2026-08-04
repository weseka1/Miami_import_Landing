/* ==========================================================================
   Dock colapsable del sidebar (solo desktop) — enlatado WESEKA / estilo Potente.

   NO toca app.js: lo único que hace es poner/sacar la clase `sidebar-collapsed`
   (en <html> y <body>) y setear `title` en los ítems del menú. Todo lo visual
   vive en style.css, gateado a desktop (min-width:1101px + pointer fine), así
   el drawer de tablet/celular sigue exactamente igual.

   Se carga en <head> SIN defer: lee localStorage y marca <html> ANTES de que
   pinte el body → cero flash al entrar con el sidebar colapsado.
   ========================================================================== */
(function () {
  var KEY = "mi_panel_sidebar";

  /* 1. Estado persistido → clase en <html> antes del primer paint. */
  try {
    if (localStorage.getItem(KEY) === "collapsed") {
      document.documentElement.classList.add("sidebar-collapsed");
    }
  } catch (e) { /* localStorage bloqueado: arranca expandido y listo */ }

  function ready(fn) {
    if (document.readyState !== "loading") fn();
    else document.addEventListener("DOMContentLoaded", fn);
  }

  ready(function () {
    var html = document.documentElement;
    var body = document.body;

    /* La clase también en <body> (el CSS usa descendiente, funciona con ambas;
       body queda por contrato y por si algo externo la mira). */
    if (html.classList.contains("sidebar-collapsed")) {
      body.classList.add("sidebar-collapsed");
    }

    /* 2. Tooltips nativos para el modo riel (íconos sin texto). */
    var items = document.querySelectorAll(".nav-item");
    for (var i = 0; i < items.length; i++) {
      var txt = items[i].querySelector("span:not(.nav-icon)");
      if (txt && !items[i].title) items[i].title = txt.textContent.trim();
    }
    var logout = document.getElementById("btn-logout");
    if (logout && !logout.title) logout.title = "Cerrar sesión";

    /* 3. Toggle. Solo clases — nada de estilos inline. */
    var btn = document.getElementById("sidebar-toggle");
    if (!btn) return;

    function rotular(collapsed) {
      var t = collapsed ? "Expandir menú" : "Colapsar menú";
      btn.title = t;
      btn.setAttribute("aria-label", t);
      btn.setAttribute("aria-expanded", collapsed ? "false" : "true");
    }
    rotular(html.classList.contains("sidebar-collapsed"));

    btn.addEventListener("click", function () {
      var collapsed = html.classList.toggle("sidebar-collapsed");
      body.classList.toggle("sidebar-collapsed", collapsed);
      rotular(collapsed);
      try { localStorage.setItem(KEY, collapsed ? "collapsed" : "expanded"); } catch (e) {}
    });
  });
})();
