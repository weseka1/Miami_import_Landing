{# ============================================================
   MIAMI_IMPORT — DESIGN SYSTEM (tokens + base glass)
   iPhone / Richard Lens. Se carga ÚLTIMO en <head>: sus reglas
   ganan y unifican toda la web desde un solo lugar.
   Cambiás un token acá → cambia en TODA la web.
   ============================================================ #}
<style>
:root{
  /* Color — Champagne Noir CÁLIDO (Estándar Web WESEKA: fondos nunca puros) */
  --mi-bg:#0E0B08; --mi-bg-2:#17120E;
  --mi-ink:#F2EAD9; --mi-ink-soft:rgba(242,234,217,.60); --mi-ink-mute:rgba(242,234,217,.40);
  --mi-gold:#c6a768; --mi-gold-2:#e0c88f;
  /* Unifica los tokens legacy (miami-styles usa --miami-*): un solo fondo/tinta en TODA la web */
  --miami-dark:#0E0B08; --miami-text:#F2EAD9; --miami-gold:#c6a768;
  --mi-line:rgba(255,255,255,.08); --mi-line-2:rgba(255,255,255,.14);
  /* Radios — iPhone (generosos, nada de esquina viva) */
  --mi-r-xs:10px; --mi-r-sm:14px; --mi-r:20px; --mi-r-lg:28px; --mi-pill:999px;
  /* Glass */
  --mi-blur:16px;
  --mi-glass:rgba(255,255,255,.05); --mi-glass-strong:rgba(255,255,255,.09);
  --mi-shadow:0 24px 70px rgba(0,0,0,.5);
  --mi-ease:cubic-bezier(.16,1,.3,1);
}

/* Utilidad glass reusable (para cualquier superficie nueva) */
.u-glass{
  background:var(--mi-glass); border:1px solid var(--mi-line);
  border-top-color:rgba(185,155,99,.28);
  -webkit-backdrop-filter:blur(var(--mi-blur)) saturate(150%); backdrop-filter:blur(var(--mi-blur)) saturate(150%);
  border-radius:var(--mi-r); box-shadow:var(--mi-shadow);
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
  transform:translateY(-6px) !important; border-color:rgba(185,155,99,.42) !important;
  box-shadow:0 30px 64px rgba(0,0,0,.5) !important;
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
  background:rgba(6,6,6,.68) !important; border-bottom:1px solid var(--mi-line) !important;
  -webkit-backdrop-filter:blur(22px) saturate(140%); backdrop-filter:blur(22px) saturate(140%);
}
.mi-nav a{ transition:color .3s var(--mi-ease), border-color .3s var(--mi-ease) !important; }

/* ---- Superficies glass ya existentes: radio iPhone parejo ---- */
.miami-trilogy__glass, .miami-trilogy__nav, .miami-trilogy__gender,
.mi-cine__glass, .mi-search{ border-radius:var(--mi-r) !important; }
.mi-search{ border-radius:var(--mi-pill) !important; }

/* ---- Detalles iPhone ---- */
::selection{ background:rgba(198,167,104,.32); color:#0E0B08; }
html{ scroll-behavior:smooth; }
/* Precios y números con tabular-nums (Estándar Web WESEKA) */
.miami-price-ars, .miami-price-usd, .h-value__no, .mi-cine__glass-item em{ font-variant-numeric:tabular-nums; }
/* Grano sutil sobre todo — "materia" (opacity ~.035, sin capturar clicks) */
body::after{ content:""; position:fixed; inset:0; z-index:90; pointer-events:none;
  background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='2'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.5'/%3E%3C/svg%3E");
  opacity:.035; mix-blend-mode:overlay; }
/* Red de seguridad responsive (Estándar): 0px overflow horizontal en cualquier ancho */
html, body{ overflow-x:clip; }

/* ---- Carruseles arrastrables: que el browser nunca "agarre" links/imágenes ---- */
[data-miami-track] a, [data-miami-track] img{
  -webkit-user-drag:none; user-select:none;
}

/* ---- Unificar fondos duros legacy (#050505/#060606 hardcodeados) a la paleta cálida ---- */
.miami-trilogy{ background:var(--mi-bg) !important; }
.miami-trilogy__atmosphere{
  background:
    radial-gradient(ellipse at 50% 50%, rgba(198,167,104,.10) 0%, transparent 50%),
    radial-gradient(ellipse at 25% 30%, rgba(198,167,104,.06) 0%, transparent 55%),
    linear-gradient(180deg, var(--mi-bg) 0%, var(--mi-bg-2) 50%, var(--mi-bg) 100%) !important;
}
/* Solo background-COLOR: el hero define su propia imagen de poster como
   fallback (iOS Low Power no arranca el video) y el shorthand acá la pisaba. */
.mi-hero{ background-color:var(--mi-bg) !important; }
.h-ticker, .mi-footer, .mi-header{ background-color:rgba(14,11,8,.9) !important; }
.mi-footer{ border-top-color:rgba(198,167,104,.16) !important; }
</style>
