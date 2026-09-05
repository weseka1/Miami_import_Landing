{# ============================================================
   MIAMI_IMPORT — DESIGN SYSTEM (tokens + base glass)
   iPhone / Richard Lens. Se carga ÚLTIMO en <head>: sus reglas
   ganan y unifican toda la web desde un solo lugar.
   Cambiás un token acá → cambia en TODA la web.
   ============================================================ #}
<style>
:root{
  /* ---- SUPERFICIES ----------------------------------------------------
     Blanco cálido, nunca #FFF puro (Estándar Web WESEKA). El papel es el
     fondo y la card es un punto MÁS clara, no más oscura: en un tema claro
     la jerarquía se construye con luz, exactamente al revés que en oscuro. */
  --mi-bg:#FBFBFA;        /* papel */
  --mi-bg-2:#FFFFFF;      /* card / superficie elevada */
  --mi-bg-3:#F1F1EF;      /* zona hundida: barras, footer, rellenos */

  /* ---- TINTA ---------------------------------------------------------- */
  --mi-ink:#15161A;                       /* gris muy oscuro, nunca #000 */
  --mi-ink-soft:rgba(21,22,26,.64);
  --mi-ink-mute:rgba(21,22,26,.44);

  /* ---- ACENTO ---------------------------------------------------------
     🔴 El acento ES la tinta. Monocromo real: la jerarquía la hacen el peso,
     el tamaño y el aire, no un color de marca. Así se leen caras las tiendas
     que son la vara (Off-White, SSENSE) y es lo contrario del negro+dorado,
     que se sacó justamente por leerse barato. */
  --mi-accent:#15161A;
  --mi-accent-2:#3A3C44;

  --mi-line:rgba(21,22,26,.09);
  --mi-line-2:rgba(21,22,26,.16);

  /* Radios — iPhone (generosos, nada de esquina viva) */
  --mi-r-xs:10px; --mi-r-sm:14px; --mi-r:20px; --mi-r-lg:28px; --mi-pill:999px;

  /* ---- LIQUID GLASS ---------------------------------------------------
     El vidrio de iOS no es "una capa translúcida": son TRES cosas juntas —
     blur alto, saturación por encima de 100% (lo de atrás se ve más vivo, no
     más gris) y un canto superior más claro que el resto, que es el reflejo.
     Si falta alguna, parece un div con opacity y se nota. */
  --mi-blur:28px;
  --mi-glass:rgba(255,255,255,.62);
  --mi-glass-strong:rgba(255,255,255,.82);
  --mi-glass-line:rgba(255,255,255,.9);

  /* Sombra en claro: difusa, baja y en DOS capas. Una sola sombra fuerte
     sobre blanco se ve sucia; dos suaves se ven profundas. */
  --mi-shadow:0 18px 44px rgba(21,22,26,.09), 0 2px 6px rgba(21,22,26,.04);
  --mi-shadow-lift:0 30px 64px rgba(21,22,26,.13), 0 3px 10px rgba(21,22,26,.05);

  --mi-ease:cubic-bezier(.16,1,.3,1);
}

/* Utilidad glass reusable (para cualquier superficie nueva) */
.u-glass{
  background:var(--mi-glass); border:1px solid var(--mi-line);
  border-top-color:var(--mi-glass-line);
  -webkit-backdrop-filter:blur(var(--mi-blur)) saturate(180%); backdrop-filter:blur(var(--mi-blur)) saturate(180%);
  border-radius:var(--mi-r); box-shadow:var(--mi-shadow);
}
/* Sin soporte de backdrop-filter (Firefox viejo, algunos WebView) el vidrio
   queda casi transparente y el texto de arriba se vuelve ilegible: se opaca. */
@supports not ((backdrop-filter:blur(1px)) or (-webkit-backdrop-filter:blur(1px))){
  .u-glass{ background:var(--mi-glass-strong); }
}

/* ---- Grid de productos BULLETPROOF (fix cards cortadas en mobile) ----
   `1fr` = minmax(auto,1fr): con contenido no comprimible (precios, nombres
   largos) el min-content de la card empujaba la grilla más allá del viewport
   y la columna derecha quedaba CORTADA en el celu. minmax(0,1fr) permite que
   la columna comprima siempre; min-width:0 en la card y su body hace lo mismo
   dentro del track. Cubre /, /productos, /categoria y relacionados (todos
   usan .mi-grid). */
.mi-grid{ grid-template-columns:repeat(4,minmax(0,1fr)); }
@media(max-width:900px){ .mi-grid{ grid-template-columns:repeat(2,minmax(0,1fr)); } }
.mi-card, .mi-card__body{ min-width:0; }
/* miami-import-custom.css (legacy, para su carrusel) fija .mi-card{width:clamp(220px,…)}:
   en la grilla eso desbordaba el track (220px > columna de ~150px en 390) y la
   columna derecha quedaba CORTADA. Dentro de .mi-grid la card es fluida. */
.mi-grid .mi-card{ width:auto; }
.mi-card__name, .mi-card__brand{ overflow-wrap:break-word; }
.miami-price-dual{ min-width:0; }
.miami-price-dual .miami-price-usd, .miami-price-dual .miami-price-ars,
.miami-price-dual .miami-price-ars-label{ white-space:normal; overflow-wrap:break-word; }

/* ---- De-cuadrar: cards con radio iPhone + hover fluido ---- */
.mi-card{
  border-radius:var(--mi-r) !important; border-color:var(--mi-line) !important;
  background:var(--mi-bg-2) !important;
  transition:transform .55s var(--mi-ease), border-color .55s var(--mi-ease), box-shadow .55s var(--mi-ease) !important;
}
.mi-card:hover{
  transform:translateY(-6px) !important; border-color:var(--mi-line-2) !important;
  box-shadow:var(--mi-shadow-lift) !important;
}
.mi-soldout{ border-radius:var(--mi-pill) !important; }

/* ---- Botones: pill liquid, consistentes en toda la web ---- */
.mi-btn, .miami-btn, .miami-lookbook__cta--glass{ border-radius:var(--mi-pill) !important; transition:.4s var(--mi-ease) !important; }
.miami-btn--ghost, .mi-btn--ghost{
  -webkit-backdrop-filter:blur(10px); backdrop-filter:blur(10px);
  background:var(--mi-glass) !important; border:1px solid var(--mi-line-2) !important;
}

/* ---- Header: glass fino + aire ---- */
.mi-header{
  background:rgba(251,251,250,.68) !important; border-bottom:1px solid var(--mi-line) !important;
  -webkit-backdrop-filter:blur(22px) saturate(140%); backdrop-filter:blur(22px) saturate(140%);
}
.mi-nav a{ transition:color .3s var(--mi-ease), border-color .3s var(--mi-ease) !important; }

/* ---- Superficies glass ya existentes: radio iPhone parejo ---- */
.miami-trilogy__glass, .miami-trilogy__nav, .miami-trilogy__gender,
.mi-cine__glass, .mi-search{ border-radius:var(--mi-r) !important; }
.mi-search{ border-radius:var(--mi-pill) !important; }

/* ---- Detalles iPhone ---- */
::selection{ background:rgba(21,22,26,.14); color:var(--mi-ink); }
html{ scroll-behavior:smooth; }
/* Precios y números con tabular-nums (Estándar Web WESEKA) */
.miami-price-ars, .miami-price-usd, .h-value__no, .mi-cine__glass-item em{ font-variant-numeric:tabular-nums; }
/* Grano sutil sobre todo — "materia" (opacity ~.035, sin capturar clicks) */
body::after{ content:""; position:fixed; inset:0; z-index:90; pointer-events:none;
  background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='2'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.5'/%3E%3C/svg%3E");
  opacity:.022; mix-blend-mode:soft-light; }
/* Red de seguridad responsive (Estándar): 0px overflow horizontal en cualquier ancho */
html, body{ overflow-x:clip; }

/* FIX CRÍTICO mobile — grid blowout por min-content: con `1fr` (=minmax(auto,1fr))
   la fila de precios/labels no comprime y el grid se derramaba a la derecha
   (cards cortadas en el celu, reporte de Juani en prod). minmax(0,1fr) obliga
   a las columnas a respetar el viewport SIEMPRE, pase lo que pase adentro. */
.mi-grid{ grid-template-columns:repeat(4,minmax(0,1fr)) !important; }
@media(max-width:900px){ .mi-grid{ grid-template-columns:repeat(2,minmax(0,1fr)) !important; gap:14px !important; } }
.mi-card{ min-width:0; }
.mi-card__name{ overflow-wrap:break-word; }
.miami-price-dual .miami-price-ars-label{ white-space:normal; }

/* ---- Carruseles arrastrables: que el browser nunca "agarre" links/imágenes ---- */
[data-miami-track] a, [data-miami-track] img{
  -webkit-user-drag:none; user-select:none;
}

/* ---- Unificar fondos duros legacy (#FBFBFA/#FBFBFA hardcodeados) a la paleta cálida ---- */
.miami-trilogy{ background:var(--mi-bg) !important; }
.miami-trilogy__atmosphere{
  background:
    radial-gradient(ellipse at 50% 50%, rgba(21,22,26,.10) 0%, transparent 50%),
    radial-gradient(ellipse at 25% 30%, rgba(21,22,26,.06) 0%, transparent 55%),
    linear-gradient(180deg, var(--mi-bg) 0%, var(--mi-bg-2) 50%, var(--mi-bg) 100%) !important;
}
/* Solo background-COLOR: el hero define su propia imagen de poster como
   fallback (iOS Low Power no arranca el video) y el shorthand acá la pisaba. */
.mi-hero{ background-color:var(--mi-bg) !important; }
.h-ticker, .mi-footer, .mi-header{ background-color:rgba(251,251,250,.9) !important; }
.mi-footer{ border-top-color:rgba(21,22,26,.16) !important; }

/* ---- Títulos de página: color propio, no heredado ----------------------
   `.mi-section-title` no declaraba `color` y venía heredando blanco de un
   contenedor de la era oscura: sobre papel quedaba invisible. Un título de
   sección tiene que decidir su color, no recibirlo por accidente. */
.mi-section-title, .page-header h1, .page-header h2{
  color:var(--mi-ink) !important; -webkit-text-fill-color:var(--mi-ink) !important;
}

/* ---- Buscador: vidrio, no una caja gris ---- */
/* 🔴 El input va TRANSPARENTE: el vidrio y el borde los pone el contenedor
   (.mi-search). Darle fondo y borde propios dibujaba una caja adentro de otra
   caja — el "recuadro tipo Win98" que reporto Juani. */
.mi-search input, .mi-search__input{
  background:transparent !important; border:0 !important; color:var(--mi-ink) !important;
}
input[type="search"]:not(.mi-search input){
  background:var(--mi-glass); color:var(--mi-ink); border:1px solid var(--mi-line);
}
.mi-search input::placeholder, input[type="search"]::placeholder{ color:var(--mi-ink-mute) !important; }
/* iOS zoomea el viewport si el input mide menos de 16px (Estándar WESEKA) */
@media(max-width:640px){ .mi-search input, input[type="search"]{ font-size:16px !important; } }

/* ---- Footer: los titulos venian en blanco desde el CSS compilado ----------
   La regla viva esta minificada dentro de style-critical.css y no se puede
   editar ahi (es build). El DS se carga ultimo justamente para esto. */
.mi-footer h1, .mi-footer h2, .mi-footer h3, .mi-footer h4{
  color:var(--mi-ink) !important; -webkit-text-fill-color:var(--mi-ink) !important;
}
.mi-footer a, .mi-footer p, .mi-footer li{ color:var(--mi-ink-soft) !important; }
.mi-footer a:hover{ color:var(--mi-ink) !important; }

/* ---- Menú lateral: vidrio de verdad ------------------------------------
   Tenía background transparent y backdrop-filter none, así que se veía
   blanco plano por el body de atrás. Un panel que se superpone al contenido
   es EL lugar donde el vidrio de iOS tiene sentido: dejás ver que hay algo
   debajo sin que compita con lo que estás leyendo. */
/* 🔴 `.mi-drawer` es un contenedor `position:fixed; inset:0` que ocupa TODA
   la pantalla: darle vidrio a él pintaba la web entera de blanco. El vidrio
   va en `.mi-drawer__sheet`, que es el panel que se desliza. */
.mi-drawer{ background:none !important; }
.mi-drawer__sheet{
  /* Tarjeta FLOTANTE, no un panel pegado al borde: separada de los bordes y
     con el radio grande de iOS. Es lo que hace que se lea como vidrio apoyado
     encima y no como media pantalla partida. */
  background:rgba(255,255,255,.52) !important;
  -webkit-backdrop-filter:blur(40px) saturate(200%); backdrop-filter:blur(40px) saturate(200%);
  border:1px solid rgba(255,255,255,.55) !important;
  border-radius:var(--mi-r-lg) !important;
  box-shadow:0 40px 90px rgba(21,22,26,.20), 0 4px 14px rgba(21,22,26,.06) !important;
  margin:12px !important; height:calc(100% - 24px) !important;
  max-height:calc(100svh - 24px) !important;
  /* 🔴 Acá decía `overflow:hidden` (para que el radio recortara el contenido)
     y eso MATABA el scroll interno del panel: con el menú abierto el dedo
     movía la web de atrás en vez de la lista. El radio igual recorta con
     overflow-y:auto. */
  overflow-y:auto !important; overscroll-behavior:contain !important;
  -webkit-overflow-scrolling:touch;
}
/* El canto de arriba, mas claro: es el reflejo. Sin esto el vidrio es plano. */
.mi-drawer__sheet::before{
  content:""; position:absolute; inset:0 0 auto 0; height:1px; pointer-events:none;
  background:linear-gradient(90deg, transparent, rgba(255,255,255,.95), transparent);
}
@supports not ((backdrop-filter:blur(1px)) or (-webkit-backdrop-filter:blur(1px))){
  .mi-drawer__sheet{ background:var(--mi-bg-2) !important; }
}
/* El velo de atrás: oscurece apenas el fondo para que el panel se despegue */
.mi-drawer-scrim, .mi-drawer__scrim, .mi-overlay{
  background:rgba(21,22,26,.18) !important;
  -webkit-backdrop-filter:blur(3px); backdrop-filter:blur(3px);
}

/* ---- Campos de formulario: vidrio, nunca caja hundida ---- */
input:not([type=checkbox]):not([type=radio]):not([type=submit]):not([type=button]),
select, textarea{
  background:var(--mi-glass) !important; color:var(--mi-ink) !important;
  border:1px solid var(--mi-line) !important; border-radius:var(--mi-r-sm);
  -webkit-backdrop-filter:blur(10px); backdrop-filter:blur(10px);
}
input:focus, select:focus, textarea:focus{
  outline:none; border-color:var(--mi-line-2) !important; background:var(--mi-bg-2) !important;
}
::placeholder{ color:var(--mi-ink-mute) !important; opacity:1; }
/* El buscador es la excepción: el vidrio lo pone la píldora que lo contiene,
   si además lo pone el input quedan dos cajas, una adentro de la otra. */
/* 🔴 La especificidad importa: la regla general de arriba es
   `input:not(...):not(...):not(...):not(...)` = (0,4,1), y le ganaba a
   `.mi-search input` = (0,1,1). Por eso el recuadro volvia a aparecer aunque
   la excepcion estuviera escrita despues. Se iguala la cuenta de :not(). */
.mi-search input:not([type=checkbox]):not([type=radio]):not([type=submit]):not([type=button]){
  background:transparent !important; border:0 !important; border-radius:0 !important;
  -webkit-backdrop-filter:none !important; backdrop-filter:none !important;
}
/* Chrome pinta el autocompletado de amarillo y se come el vidrio */
input:-webkit-autofill{ -webkit-text-fill-color:var(--mi-ink);
  -webkit-box-shadow:0 0 0 40px var(--mi-bg-2) inset; }
</style>