{# ============================================================
   MIAMI_IMPORT — TRILOGIA · CARRUSEL CINEMATOGRAFICO
   ============================================================
   - 4 chaquetas:
       0 = MARRON   (hombre)
       1 = MULTICOLOR (hombre)
       2 = BLANCO   (mujer)
       3 = NEGRO    (mujer)
   - Switch HOMBRE / MUJER arriba: filtra las 2 visibles
   - Navegacion: dots 01/02, flechas ← →, teclado izq/der, swipe touch
   - Auto-loop entre las 2 del genero activo, pausa al hover/manual
   ============================================================ #}

<section class="miami-trilogy" id="miami-trilogy" data-gender="hombre">

  <div class="miami-trilogy__atmosphere"></div>

  {# Switch HOMBRE / MUJER arriba centrado #}
  <div class="miami-trilogy__gender" role="tablist" aria-label="Genero">
    <button class="miami-trilogy__gender-btn is-active" data-gender="hombre" role="tab" aria-selected="true">HOMBRE</button>
    <span class="miami-trilogy__gender-sep">/</span>
    <button class="miami-trilogy__gender-btn" data-gender="mujer" role="tab" aria-selected="false">MUJER</button>
  </div>

  {# Stage del carrusel: 4 jackets. La activa (is-center) es clickeable y va al producto. #}
  <div class="miami-trilogy__stage" aria-label="Carrusel de chaquetas">
    <a href="https://miamiimport.com.ar/productos/diesel-chaqueta-diesel-marron-parches/"
       class="miami-trilogy__jacket is-center" data-jacket="0" data-gender="hombre"
       aria-label="Ver Chaqueta Diesel Marrón Parches">
      <img class="miami-trilogy__img" src="{{ 'images/trilogy-marron-v6.webp' | static_url }}" alt="Diesel Varsity Marron" loading="lazy"/>
    </a>
    {# Multicolor aun no esta subido al catalogo — sin link por ahora #}
    <div class="miami-trilogy__jacket is-next" data-jacket="1" data-gender="hombre">
      <img class="miami-trilogy__img" src="{{ 'images/trilogy-multicolor-v6.webp' | static_url }}" alt="Diesel Varsity Multicolor" loading="lazy"/>
    </div>
    <a href="https://miamiimport.com.ar/productos/diesel-chaqueta-diesel-dama-blanca-con-strass/"
       class="miami-trilogy__jacket" data-jacket="2" data-gender="mujer"
       aria-label="Ver Chaqueta Diesel Blanca con Strass">
      <img class="miami-trilogy__img" src="{{ 'images/trilogy-blanco-v6.webp' | static_url }}" alt="Diesel Varsity Blanco" loading="lazy"/>
    </a>
    <a href="https://miamiimport.com.ar/productos/diesel-chaqueta-diesel-negra-con-strass/"
       class="miami-trilogy__jacket" data-jacket="3" data-gender="mujer"
       aria-label="Ver Chaqueta Diesel Negra con Strass">
      <img class="miami-trilogy__img" src="{{ 'images/trilogy-negro-v6.webp' | static_url }}" alt="Diesel Varsity Negro" loading="lazy"/>
    </a>
    <a href="https://miamiimport.com.ar/productos/diesel-chaqueta-diesel-negra-parches/"
       class="miami-trilogy__jacket" data-jacket="4" data-gender="hombre"
       aria-label="Ver Chaqueta Diesel Negra Parches">
      <img class="miami-trilogy__img" src="{{ 'images/trilogy-negra-parches-v6.webp' | static_url }}" alt="Diesel Negra Parches" loading="lazy"/>
    </a>
  </div>

  {# 4 Overlays editoriales — solo el del jacket activo (y del genero activo) se ve #}
  <div class="miami-trilogy__ch is-active" data-chapter="0" data-gender="hombre">
    <h3 class="miami-trilogy__name">MARRÓN</h3>
    <div class="miami-trilogy__glass">
      <div class="miami-trilogy__glass-label">REF / 01 · HOMBRE</div>
      <p>Tierra negra. La pieza se reescribe en tono cálido, con patches
         que viran al dorado. Streetwear con vocabulario de archivo.</p>
      <div class="miami-trilogy__glass-meta">
        <div>COLORWAY · <strong>TIERRA NEGRA</strong></div>
        <div>TALLES · <strong>S — 2XL</strong></div>
        <div>PESO · <strong>980 g</strong></div>
      </div>
    </div>
  </div>
  <div class="miami-trilogy__ch" data-chapter="1" data-gender="hombre">
    <h3 class="miami-trilogy__name">MULTICOLOR</h3>
    <div class="miami-trilogy__glass">
      <div class="miami-trilogy__glass-label">REF / 02 · HOMBRE</div>
      <p>Pieza de archivo racing. Patches saturados, composición tipográfica
         intensa. Rojo motor, blanco crudo y negro tinta en convivencia.</p>
      <div class="miami-trilogy__glass-meta">
        <div>COLORWAY · <strong>MULTICOLOR ARCHIVE</strong></div>
        <div>TALLES · <strong>S — 2XL</strong></div>
        <div>PESO · <strong>980 g</strong></div>
      </div>
    </div>
  </div>
  <div class="miami-trilogy__ch" data-chapter="2" data-gender="mujer">
    <h3 class="miami-trilogy__name">BLANCO</h3>
    <div class="miami-trilogy__glass">
      <div class="miami-trilogy__glass-label">REF / 01 · MUJER</div>
      <p>Crudo. Sin maquillaje. Patches bordados sobre nylon italiano,
         hilos plateados, costura visible. Una declaración de pureza.</p>
      <div class="miami-trilogy__glass-meta">
        <div>COLORWAY · <strong>CRUDO MARFIL</strong></div>
        <div>TALLES · <strong>S — 2XL</strong></div>
        <div>PESO · <strong>980 g</strong></div>
      </div>
    </div>
  </div>
  <div class="miami-trilogy__ch" data-chapter="3" data-gender="mujer">
    <h3 class="miami-trilogy__name">NEGRO</h3>
    <div class="miami-trilogy__glass">
      <div class="miami-trilogy__glass-label">REF / 02 · MUJER</div>
      <p>Negro tinta. El bordado se vuelve tonal, el peso visual se
         concentra. Una lectura más íntima, casi monástica.</p>
      <div class="miami-trilogy__glass-meta">
        <div>COLORWAY · <strong>NEGRO TINTA</strong></div>
        <div>TALLES · <strong>S — 2XL</strong></div>
        <div>PESO · <strong>980 g</strong></div>
      </div>
    </div>
  </div>
  <div class="miami-trilogy__ch" data-chapter="4" data-gender="hombre">
    <h3 class="miami-trilogy__name miami-trilogy__name--compact">NEGRA PARCHES</h3>
    <div class="miami-trilogy__glass">
      <div class="miami-trilogy__glass-label">REF / 03 · HOMBRE</div>
      <p>Negra estructura. Patches metálicos sobre nylon italiano, costura
         visible y peso editorial. Streetwear con presencia de archivo.</p>
      <div class="miami-trilogy__glass-meta">
        <div>COLORWAY · <strong>NEGRO PARCHES</strong></div>
        <div>TALLES · <strong>S — 2XL</strong></div>
        <div>PESO · <strong>980 g</strong></div>
      </div>
    </div>
  </div>

  {# Nav abajo: 2 dots (mujer) o 3 dots (hombre) — JS oculta los que sobran segun genero #}
  <nav class="miami-trilogy__nav" aria-label="Capítulos">
    <button class="miami-trilogy__nav-arrow" data-arrow="prev" aria-label="Anterior">←</button>
    <button data-go="0" class="is-active" aria-label="Modelo 1"></button>
    <button data-go="1" aria-label="Modelo 2"></button>
    <button data-go="2" aria-label="Modelo 3"></button>
    <button class="miami-trilogy__nav-arrow" data-arrow="next" aria-label="Siguiente">→</button>
  </nav>
</section>

<style>
.miami-trilogy {
  position: relative;
  background: #050505;
  color: #fff;
  height: 100vh; min-height: 720px;
  overflow: hidden;
  isolation: isolate;
  touch-action: pan-y;
}

/* Atmosfera CSS-only */
.miami-trilogy__atmosphere {
  position: absolute; inset: 0; z-index: 0;
  background:
    radial-gradient(ellipse at 50% 50%, rgba(185,155,99,0.10) 0%, transparent 50%),
    radial-gradient(ellipse at 25% 30%, rgba(185,155,99,0.06) 0%, transparent 55%),
    radial-gradient(ellipse at 75% 70%, rgba(185,155,99,0.05) 0%, transparent 60%),
    linear-gradient(180deg, #050505 0%, #0c0c0c 50%, #050505 100%);
}
.miami-trilogy__atmosphere::before {
  content: ""; position: absolute; inset: 0;
  background-image:
    repeating-linear-gradient(0deg,  rgba(255,255,255,0.013) 0 1px, transparent 1px 88px),
    repeating-linear-gradient(90deg, rgba(255,255,255,0.013) 0 1px, transparent 1px 88px);
}
.miami-trilogy__atmosphere::after {
  content: ""; position: absolute; inset: 0;
  background: radial-gradient(ellipse at center, transparent 40%, rgba(0,0,0,0.7) 100%);
}

/* ========== SWITCH HOMBRE / MUJER ========== */
.miami-trilogy__gender {
  position: absolute;
  top: clamp(20px, 4vh, 36px);
  left: 50%; transform: translateX(-50%);
  z-index: 13;
  display: inline-flex; align-items: center; gap: 14px;
  background: rgba(10,10,10,0.5);
  backdrop-filter: blur(14px) saturate(140%);
  -webkit-backdrop-filter: blur(14px) saturate(140%);
  border: 1px solid rgba(255,255,255,0.06);
  border-top: 1px solid rgba(185,155,99,0.35);
  padding: 8px 18px;
}
.miami-trilogy__gender-btn {
  background: transparent;
  border: none;
  font-family: inherit;
  font-size: 11px; letter-spacing: 0.45em; text-transform: uppercase;
  color: rgba(255,255,255,0.45); font-weight: 500;
  cursor: pointer;
  padding: 6px 14px;
  transition: color 0.3s var(--miami-ease, ease);
}
.miami-trilogy__gender-btn:hover { color: rgba(255,255,255,0.85); }
.miami-trilogy__gender-btn.is-active {
  color: #b99b63;
}
.miami-trilogy__gender-sep {
  color: rgba(255,255,255,0.25);
  font-size: 13px; font-weight: 300;
}

/* ========== STAGE: el carrusel ========== */
.miami-trilogy__stage {
  position: absolute; inset: 0; z-index: 4;
  display: flex; align-items: center; justify-content: center;
  pointer-events: none;
}

/* Deslizable con el mouse (se suma al swipe touch que ya existía) */
.miami-trilogy { cursor: grab; }
.miami-trilogy.is-dragging { cursor: grabbing; }
.miami-trilogy__glass { cursor: auto; }

.miami-trilogy__jacket {
  position: absolute; top: 50%; left: 50%;
  width: clamp(280px, 32vw, 540px);
  height: 78vh; max-height: 720px;
  opacity: 0;
  pointer-events: none;
  transition:
    transform 0.95s cubic-bezier(0.22, 0.61, 0.36, 1),
    opacity 0.85s cubic-bezier(0.22, 0.61, 0.36, 1),
    filter 0.95s cubic-bezier(0.22, 0.61, 0.36, 1);
  will-change: transform, opacity, filter;
  transform: translate(-50%, -50%) scale(0.5);
}

/* CENTRO — protagonista (clickeable cuando es un <a>) */
.miami-trilogy__jacket.is-center {
  opacity: 1; z-index: 5;
  transform: translate(
    calc(-50% + var(--mx, 0px)),
    calc(-50% + var(--my, 0px))
  ) scale(1);
  pointer-events: auto;
  text-decoration: none;
}
a.miami-trilogy__jacket {
  display: block;
  text-decoration: none;
  color: inherit;
}
a.miami-trilogy__jacket.is-center { cursor: pointer; }
a.miami-trilogy__jacket.is-center:hover .miami-trilogy__img {
  filter: brightness(1.05);
}
.miami-trilogy__jacket.is-center .miami-trilogy__img {
  animation: miami-trilogy-rim 2.8s ease-in-out infinite;
}
@keyframes miami-trilogy-rim {
  0%, 100% {
    filter:
      drop-shadow(0 36px 60px rgba(0,0,0,0.75))
      drop-shadow(0 0 3px rgba(255,215,150,0.95))
      drop-shadow(0 0 8px rgba(212,187,136,0.85))
      drop-shadow(0 0 16px rgba(185,155,99,0.7))
      drop-shadow(0 0 32px rgba(185,155,99,0.5))
      drop-shadow(0 0 60px rgba(185,155,99,0.35));
  }
  50% {
    filter:
      drop-shadow(0 36px 60px rgba(0,0,0,0.75))
      drop-shadow(0 0 5px rgba(255,230,176,1))
      drop-shadow(0 0 14px rgba(212,187,136,1))
      drop-shadow(0 0 26px rgba(185,155,99,0.95))
      drop-shadow(0 0 50px rgba(185,155,99,0.75))
      drop-shadow(0 0 100px rgba(185,155,99,0.45));
  }
}
.miami-trilogy__jacket.is-center::before {
  content: ""; position: absolute; inset: 5% 5%; z-index: -1;
  background: radial-gradient(ellipse at center,
    rgba(185,155,99,0.22) 0%,
    rgba(185,155,99,0.08) 35%,
    transparent 65%);
  filter: blur(20px);
  animation: miami-trilogy-aura 4s ease-in-out infinite;
  pointer-events: none;
}
@keyframes miami-trilogy-aura {
  0%, 100% { opacity: 0.7; transform: scale(1); }
  50%      { opacity: 1.0; transform: scale(1.08); }
}

/* LATERAL IZQUIERDA */
.miami-trilogy__jacket.is-prev {
  opacity: 0.32; z-index: 2;
  transform: translate(-160%, -50%) scale(0.55);
}
.miami-trilogy__jacket.is-prev .miami-trilogy__img {
  filter: drop-shadow(0 18px 40px rgba(0,0,0,0.6))
          blur(1.5px) grayscale(0.5) brightness(0.7);
}

/* LATERAL DERECHA */
.miami-trilogy__jacket.is-next {
  opacity: 0.32; z-index: 2;
  transform: translate(60%, -50%) scale(0.55);
}
.miami-trilogy__jacket.is-next .miami-trilogy__img {
  filter: drop-shadow(0 18px 40px rgba(0,0,0,0.6))
          blur(1.5px) grayscale(0.5) brightness(0.7);
}

.miami-trilogy__img {
  width: 100%; height: 100%; object-fit: contain;
  animation: miami-trilogy-float 6.5s ease-in-out infinite;
  transition: filter 0.95s cubic-bezier(0.22, 0.61, 0.36, 1);
  -webkit-user-drag: none; user-select: none;   /* que el browser no "agarre" la imagen */
}
@keyframes miami-trilogy-float {
  0%, 100% { transform: translate3d(0,0,0) rotate(0deg); }
  25%      { transform: translate3d(0,-10px,0) rotate(-0.6deg); }
  50%      { transform: translate3d(0,-16px,0) rotate(0deg); }
  75%      { transform: translate3d(0,-8px,0) rotate(0.6deg); }
}

/* ========== Overlays editoriales por chapter ========== */
.miami-trilogy__ch {
  position: absolute; inset: 0; z-index: 10;
  pointer-events: none;
  opacity: 0; transform: translateY(20px);
  transition: opacity 0.7s cubic-bezier(0.16,1,0.3,1),
              transform 0.7s cubic-bezier(0.16,1,0.3,1);
}
.miami-trilogy__ch.is-active { opacity: 1; transform: translateY(0); }

.miami-trilogy__eyebrow {
  position: absolute;
  top: clamp(78px, 12vh, 130px);
  left: clamp(24px, 5vw, 64px);
  font-size: 11px; letter-spacing: 0.55em; text-transform: uppercase;
  color: #b99b63; font-weight: 500;
  display: inline-flex; align-items: center; gap: 16px;
}
.miami-trilogy__eyebrow::before {
  content: ""; width: 48px; height: 1px; background: #b99b63;
}

.miami-trilogy__name {
  position: absolute;
  bottom: clamp(120px, 18vh, 180px);
  left: clamp(24px, 5vw, 64px);
  /* Antes 11vw/200px: monstruoso y chocaba con la ficha. Más contenido = más offwhite. */
  font-size: clamp(48px, 8vw, 140px);
  font-weight: 500; line-height: 0.95;
  letter-spacing: 0.04em; text-transform: uppercase;
  /* Reserva SIEMPRE la zona de la ficha glass (su ancho + su margen derecho) */
  max-width: calc(100% - clamp(280px, 28vw, 380px) - clamp(48px, 10vw, 128px) - clamp(24px, 5vw, 64px));
  overflow-wrap: break-word;
  text-shadow: 0 4px 24px rgba(0,0,0,0.7);
  mix-blend-mode: difference;
  margin: 0;
}

/* Anchos intermedios (ventana achicada / tablet apaisada): el hueco entre
   nombre y ficha se achica — bajamos tipografía y compactamos la ficha para
   que NUNCA se pisen. */
@media (min-width: 768px) and (max-width: 1280px) {
  .miami-trilogy__name { font-size: clamp(34px, 5.5vw, 80px); bottom: clamp(140px, 22vh, 200px); }
  .miami-trilogy__name--compact { font-size: clamp(28px, 4.2vw, 60px); }
  .miami-trilogy__glass { width: clamp(250px, 32vw, 330px); padding: 18px 20px; }
  .miami-trilogy__glass p { font-size: 12px; margin-bottom: 12px; }
}
/* Nombres de dos palabras (ej: "NEGRA PARCHES") en el tamaño de una palabra
   partían en dos renglones y se montaban gigantes sobre la campera. Se achica
   y se fuerza a UNA línea para que quede alineado abajo como los demás. */
.miami-trilogy__name--compact {
  font-size: clamp(38px, 5.5vw, 96px);
  /* puede partir en dos líneas: con la tipo contenida queda bien y nunca desborda */
}

.miami-trilogy__glass {
  position: absolute;
  bottom: clamp(40px, 8vh, 80px);
  right: clamp(24px, 5vw, 64px);
  width: clamp(280px, 28vw, 380px);
  background: rgba(10,10,10,0.5);
  backdrop-filter: blur(22px) saturate(160%);
  -webkit-backdrop-filter: blur(22px) saturate(160%);
  border: 1px solid rgba(255,255,255,0.06);
  border-top: 1px solid rgba(185,155,99,0.45);
  padding: 24px 26px;
  box-shadow: 0 24px 80px rgba(0,0,0,0.6);
  pointer-events: auto;
}
.miami-trilogy__glass-label {
  font-size: 10px; letter-spacing: 0.5em; text-transform: uppercase;
  color: #b99b63; margin-bottom: 14px; font-weight: 500;
}
.miami-trilogy__glass p {
  font-size: 13px; line-height: 1.7; letter-spacing: 0.02em;
  color: rgba(255,255,255,0.85); margin: 0 0 18px;
}
.miami-trilogy__glass-meta {
  display: flex; flex-direction: column; gap: 6px;
  font-size: 10px; letter-spacing: 0.4em; text-transform: uppercase;
  color: rgba(255,255,255,0.5);
}
.miami-trilogy__glass-meta strong {
  color: #fff; font-weight: 500; letter-spacing: 0.18em;
}

/* ========== Nav abajo ========== */
.miami-trilogy__nav {
  position: absolute;
  bottom: clamp(28px, 4vh, 48px);
  left: 50%; transform: translateX(-50%);
  z-index: 12;
  display: flex; align-items: center; gap: 14px;
  background: rgba(10,10,10,0.55);
  backdrop-filter: blur(14px) saturate(140%);
  -webkit-backdrop-filter: blur(14px) saturate(140%);
  border: 1px solid rgba(255,255,255,0.06);
  padding: 10px 18px;
  pointer-events: auto;
}
.miami-trilogy__nav button {
  background: transparent;
  border: 1px solid rgba(255,255,255,0.2);
  padding: 8px 14px;
  font-family: inherit;
  font-size: 10px; letter-spacing: 0.35em; text-transform: uppercase;
  color: rgba(255,255,255,0.55); font-weight: 500;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.22,0.61,0.36,1);
}
.miami-trilogy__nav button:hover {
  color: #b99b63; border-color: #b99b63;
}
.miami-trilogy__nav button.is-active {
  color: #0f0f0f; background: #b99b63; border-color: #b99b63;
  box-shadow: 0 6px 20px rgba(185,155,99,0.35);
}
.miami-trilogy__nav-arrow {
  border: none !important; padding: 4px 8px !important;
  font-size: 16px !important; color: rgba(255,255,255,0.5) !important;
  letter-spacing: 0 !important;
}
.miami-trilogy__nav-arrow:hover { color: #b99b63 !important; }
.miami-trilogy__nav-arrow:disabled {
  opacity: 0.3 !important; cursor: not-allowed !important;
}
/* Dots simples (chau numeros 01/02/03): puntos, como se navega en cualquier lado */
.miami-trilogy__nav [data-go] {
  width: 10px; height: 10px; padding: 0; border-radius: 50%;
  border: 1px solid rgba(255,255,255,0.35); background: transparent;
  box-shadow: none;
}
.miami-trilogy__nav [data-go]:hover { border-color: #b99b63; }
.miami-trilogy__nav [data-go].is-active {
  background: #b99b63; border-color: #b99b63;
}

/* ========== Responsive mobile ========== */
@media (max-width: 767px) {
  .miami-trilogy {
    height: auto;
    min-height: 100vh;
    padding-bottom: 64px;
  }
  .miami-trilogy__gender { top: 14px; padding: 6px 12px; }
  .miami-trilogy__gender-btn { font-size: 10px; letter-spacing: 0.35em; padding: 4px 10px; }

  /* === PERFORMANCE FIXES MOBILE ===
     El trilogy era pesado por:
     1) 5-6 drop-shadows apiladas en la jacket central (cada una = render-pass GPU)
     2) Float animation infinita
     3) Aura pulsante con blur
     4) Backdrop-filter del glass + nav

     En mobile bajamos a 2 drop-shadows compactas, sacamos blur del aura,
     simplificamos backdrop-filter. La estetica se mantiene visible (sigue
     habiendo halo dorado) pero el GPU respira. */
  .miami-trilogy__jacket.is-center .miami-trilogy__img {
    animation: miami-trilogy-rim-mobile 3.6s ease-in-out infinite !important;
  }
  @keyframes miami-trilogy-rim-mobile {
    0%, 100% {
      filter:
        drop-shadow(0 18px 28px rgba(0,0,0,0.65))
        drop-shadow(0 0 20px rgba(185,155,99,0.55));
    }
    50% {
      filter:
        drop-shadow(0 18px 28px rgba(0,0,0,0.65))
        drop-shadow(0 0 32px rgba(185,155,99,0.75));
    }
  }
  /* Float: lo dejamos pero mas suave (menos repintados) */
  .miami-trilogy__img {
    animation-duration: 9s !important;
  }
  /* Aura sin blur en mobile (blur=20px era el mas pesado) */
  .miami-trilogy__jacket.is-center::before {
    filter: none !important;
    background: radial-gradient(ellipse at center,
      rgba(185,155,99,0.16) 0%, transparent 60%) !important;
    animation: none !important;
  }
  /* Glass del meta-card sin backdrop-filter en mobile (caro) */
  .miami-trilogy__glass,
  .miami-trilogy__nav,
  .miami-trilogy__gender {
    backdrop-filter: none !important;
    -webkit-backdrop-filter: none !important;
    background: rgba(0,0,0,0.65) !important;
  }
  /* Atmosphere grid: simplificamos para no pintar grid completo en mobile */
  .miami-trilogy__atmosphere::before {
    background-image: none !important;
  }

  .miami-trilogy__jacket.is-prev,
  .miami-trilogy__jacket.is-next {
    opacity: 0 !important;
    pointer-events: none;
  }
  .miami-trilogy__jacket {
    width: 78vw;
    height: 55vh;
    max-height: 480px;
    top: 42%;
  }

  .miami-trilogy__eyebrow {
    top: 88px; left: 50%; transform: translateX(-50%);
    font-size: 9px; letter-spacing: 0.45em;
    text-align: center;
    width: max-content; max-width: 80vw;
  }
  .miami-trilogy__eyebrow::before { display: none; }

  .miami-trilogy__name {
    bottom: auto; top: calc(42% + 27vh + 16px);
    left: 50%; transform: translateX(-50%);
    font-size: clamp(40px, 13vw, 72px);
    text-align: center;
    margin: 0; width: 100%;
    mix-blend-mode: normal;
    text-shadow: 0 4px 24px rgba(0,0,0,0.8);
  }
  /* En celular se centra: dejamos que las dos palabras bajen a dos renglones
     (sin nowrap, que se saldría de pantalla) y un poco más chico. */
  .miami-trilogy__name--compact {
    font-size: clamp(34px, 10vw, 56px);
    white-space: normal;
    line-height: 1;
  }

  .miami-trilogy__glass {
    bottom: 88px;
    right: 50%; transform: translateX(50%);
    width: calc(100vw - 40px);
    max-width: 360px;
    padding: 12px 16px;
    /* Sin filtros distorsionadores: transparente liso, sin blur ni saturate */
    background: rgba(0,0,0,0.32);
    backdrop-filter: none !important;
    -webkit-backdrop-filter: none !important;
    border: 1px solid rgba(255,255,255,0.05);
    border-top: 1px solid rgba(185,155,99,0.3);
    box-shadow: none;
  }
  .miami-trilogy__glass-label {
    font-size: 8px; letter-spacing: 0.4em;
    margin-bottom: 8px;
  }
  .miami-trilogy__glass p {
    font-size: 10px;
    line-height: 1.5;
    margin: 0 0 10px;
    color: rgba(255,255,255,0.78);
  }
  .miami-trilogy__glass-meta {
    font-size: 8px;
    letter-spacing: 0.28em;
    gap: 3px;
  }

  .miami-trilogy__nav {
    bottom: 16px;
    gap: 10px; padding: 8px 14px;
  }
  .miami-trilogy__nav button {
    padding: 6px 10px;
    font-size: 9px; letter-spacing: 0.25em;
  }
  .miami-trilogy__nav-arrow {
    font-size: 14px !important;
    padding: 2px 6px !important;
  }
}

@media (prefers-reduced-motion: reduce) {
  .miami-trilogy__img,
  .miami-trilogy__jacket.is-center::before {
    animation: none !important;
  }
  .miami-trilogy__jacket {
    transition: none !important;
  }
}

/* PAUSA TOTAL cuando la seccion no esta en viewport — el JS agrega esta clase
   via IntersectionObserver. Mata TODAS las animaciones para liberar GPU. */
.miami-trilogy.is-paused .miami-trilogy__img,
.miami-trilogy.is-paused .miami-trilogy__jacket.is-center::before,
.miami-trilogy.is-paused </style>

<script>
(function () {
  'use strict';

  if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  var section = document.getElementById('miami-trilogy');
  if (!section) return;

  /* Mapeo: cada genero tiene 2 jackets, los data-jacket globales son 0-3 */
  var GENDER_JACKETS = {
    hombre: [0, 1, 4],   // Marron, Multicolor, Negra Parches
    mujer:  [2, 3]       // Blanco, Negro
  };

  var gender = 'hombre';
  var active = 0;  /* indice DENTRO del genero actual (0 o 1) */

  function getVisibleIndices() {
    return GENDER_JACKETS[gender];
  }

  /* ===== Update DOM: muestra solo los del genero activo segun active idx ===== */
  function render() {
    var visible = getVisibleIndices();
    var TOTAL = visible.length;
    var centerGlobal = visible[active];
    var nextGlobal = visible[(active + 1) % TOTAL];
    var prevGlobal = visible[(active - 1 + TOTAL) % TOTAL];

    section.querySelectorAll('.miami-trilogy__jacket').forEach(function (el) {
      var idx = parseInt(el.dataset.jacket, 10);
      el.classList.remove('is-center', 'is-prev', 'is-next');
      if (el.dataset.gender !== gender) {
        return; /* queda oculta (opacity 0 por defecto) */
      }
      if (idx === centerGlobal) el.classList.add('is-center');
      else if (TOTAL > 1 && idx === nextGlobal && idx !== centerGlobal) el.classList.add('is-next');
      else if (TOTAL > 2 && idx === prevGlobal) el.classList.add('is-prev');
    });

    /* Overlays: solo el del centerGlobal activo */
    section.querySelectorAll('.miami-trilogy__ch').forEach(function (el) {
      var chIdx = parseInt(el.dataset.chapter, 10);
      el.classList.toggle('is-active', chIdx === centerGlobal);
    });

    /* Nav dots: mostrar solo los necesarios (segun TOTAL del genero activo) */
    section.querySelectorAll('.miami-trilogy__nav [data-go]').forEach(function (el, i) {
      el.classList.toggle('is-active', i === active);
      el.style.display = (i < TOTAL) ? '' : 'none';
    });

    /* HUD */
    var counter = section.querySelector('[data-counter]');
    if (counter) counter.textContent = String(active + 1).padStart(2, '0');
    var totalEl = section.querySelector('[data-total]');
    if (totalEl) totalEl.textContent = String(TOTAL).padStart(2, '0');
    var bar = section.querySelector('[data-bar]');
    if (bar) bar.style.transform = 'scaleX(' + ((active + 1) / TOTAL) + ')';

    /* Arrows enable/disable solo si hay 1 jacket; con 2 nunca se deshabilitan */
    var prevA = section.querySelector('[data-arrow="prev"]');
    var nextA = section.querySelector('[data-arrow="next"]');
    if (prevA) prevA.disabled = (TOTAL <= 1);
    if (nextA) nextA.disabled = (TOTAL <= 1);
  }

  function switchChapter(newIdx) {
    var TOTAL = getVisibleIndices().length;
    if (TOTAL === 0) return;
    newIdx = ((newIdx % TOTAL) + TOTAL) % TOTAL;
    if (newIdx === active) return;
    active = newIdx;
    render();
  }

  function switchGender(newGender) {
    if (newGender === gender) return;
    if (!GENDER_JACKETS[newGender]) return;
    gender = newGender;
    active = 0;
    section.setAttribute('data-gender', gender);
    /* Actualiza visual del switch */
    section.querySelectorAll('.miami-trilogy__gender-btn').forEach(function (btn) {
      var isActive = btn.dataset.gender === gender;
      btn.classList.toggle('is-active', isActive);
      btn.setAttribute('aria-selected', String(isActive));
    });
    render();
  }

  /* ===== Click handlers nav ===== */
  section.querySelectorAll('.miami-trilogy__nav [data-go]').forEach(function (btn, i) {
    btn.addEventListener('click', function () { switchChapter(i); });
  });
  var prevA = section.querySelector('[data-arrow="prev"]');
  var nextA = section.querySelector('[data-arrow="next"]');
  if (prevA) prevA.addEventListener('click', function () { switchChapter(active - 1); });
  if (nextA) nextA.addEventListener('click', function () { switchChapter(active + 1); });

  /* ===== Switch HOMBRE / MUJER ===== */
  section.querySelectorAll('.miami-trilogy__gender-btn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      switchGender(btn.dataset.gender);
      pauseForManual();
    });
  });

  /* ===== Keyboard nav ===== */
  document.addEventListener('keydown', function (e) {
    var rect = section.getBoundingClientRect();
    if (rect.bottom < 0 || rect.top > window.innerHeight) return;
    if (e.key === 'ArrowRight') { switchChapter(active + 1); pauseForManual(); }
    if (e.key === 'ArrowLeft')  { switchChapter(active - 1); pauseForManual(); }
  });

  /* ===== Touch swipe en mobile ===== */
  var touchStartX = null, touchStartY = null;
  var SWIPE_THRESHOLD = 50; /* px minimos para contar como swipe */
  section.addEventListener('touchstart', function (e) {
    if (e.touches.length !== 1) return;
    touchStartX = e.touches[0].clientX;
    touchStartY = e.touches[0].clientY;
  }, { passive: true });
  section.addEventListener('touchend', function (e) {
    if (touchStartX === null) return;
    var t = e.changedTouches[0];
    var dx = t.clientX - touchStartX;
    var dy = t.clientY - touchStartY;
    /* Solo si fue mas horizontal que vertical (evita confusion con scroll) */
    if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > SWIPE_THRESHOLD) {
      if (dx < 0) switchChapter(active + 1);  /* swipe izq → siguiente */
      else        switchChapter(active - 1);  /* swipe der → anterior */
      pauseForManual();
    }
    touchStartX = null;
    touchStartY = null;
  }, { passive: true });

  /* ===== Mouse drag / swipe (desktop) =====
     El swipe touch ya existía; faltaba poder arrastrar con el mouse. Un drag
     horizontal pasado el umbral cambia de campera, igual que el swipe. Si hubo
     drag, se cancela el click para no navegar al producto sin querer. */
  var mDownX = null, mDownY = null, mDragged = false;
  var MOUSE_SWIPE_THRESHOLD = 60;
  /* CLAVE: la campera central es <a><img> — el drag&drop nativo del browser
     secuestraba el gesto (por eso el swipe con mouse "no andaba"). Se anula. */
  section.addEventListener('dragstart', function (e) { e.preventDefault(); });
  section.addEventListener('mousedown', function (e) {
    if (e.button !== 0) return;
    /* No interceptar los controles (dots, flechas, switch, ficha) */
    if (e.target.closest('.miami-trilogy__nav, .miami-trilogy__gender, .miami-trilogy__glass')) return;
    e.preventDefault();   /* mata la selección de texto y el drag nativo */
    mDownX = e.clientX; mDownY = e.clientY; mDragged = false;
  });
  window.addEventListener('mousemove', function (e) {
    if (mDownX === null) return;
    if (!mDragged && Math.abs(e.clientX - mDownX) > 8) {
      mDragged = true;
      section.classList.add('is-dragging');
    }
  });
  window.addEventListener('mouseup', function (e) {
    if (mDownX === null) return;
    var dx = e.clientX - mDownX, dy = e.clientY - mDownY;
    section.classList.remove('is-dragging');
    if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > MOUSE_SWIPE_THRESHOLD) {
      if (dx < 0) switchChapter(active + 1);
      else        switchChapter(active - 1);
      pauseForManual();
    }
    mDownX = null; mDownY = null;
  });
  /* Si arrastró sobre la campera central (que es un <a>), no navegar al producto */
  section.querySelectorAll('.miami-trilogy__jacket').forEach(function (j) {
    j.addEventListener('click', function (e) {
      if (mDragged) { e.preventDefault(); e.stopPropagation(); mDragged = false; }
    }, true);
  });

  /* ===== Mouse parallax (solo la central, solo desktop con mouse real) =====
     En mobile/tablet con touch NO arrancamos el loop. Si lo arrancaramos,
     requestAnimationFrame corre 60 veces por segundo en idle, comiendo CPU
     y haciendo que el scroll se trabe. */
  var canHover = window.matchMedia && window.matchMedia('(hover: hover)').matches;
  var hasMouse = window.matchMedia && window.matchMedia('(pointer: fine)').matches;

  if (canHover && hasMouse) {
    var tmx = 0, tmy = 0, mx = 0, my = 0;
    var rafId = null, inView = true;

    section.addEventListener('mousemove', function (e) {
      var r = section.getBoundingClientRect();
      tmx = (((e.clientX - r.left) / r.width) - 0.5) * 30;
      tmy = (((e.clientY - r.top) / r.height) - 0.5) * 20;
      if (!rafId) rafId = requestAnimationFrame(loop);
    });
    section.addEventListener('mouseleave', function () {
      tmx = 0; tmy = 0;
      if (!rafId) rafId = requestAnimationFrame(loop);
    });

    /* Pausamos el loop cuando la seccion sale del viewport */
    if ('IntersectionObserver' in window) {
      var io = new IntersectionObserver(function (entries) {
        inView = entries[0].isIntersecting;
        if (!inView && rafId) { cancelAnimationFrame(rafId); rafId = null; }
      }, { threshold: 0.05 });
      io.observe(section);
    }

    function loop() {
      rafId = null;
      if (!inView) return;
      mx += (tmx - mx) * 0.08;
      my += (tmy - my) * 0.08;
      section.querySelectorAll('.miami-trilogy__jacket').forEach(function (el) {
        el.style.setProperty('--mx', mx.toFixed(2) + 'px');
        el.style.setProperty('--my', my.toFixed(2) + 'px');
      });
      /* Solo seguir el loop si todavia hay distancia para recorrer */
      if (Math.abs(tmx - mx) > 0.05 || Math.abs(tmy - my) > 0.05) {
        rafId = requestAnimationFrame(loop);
      }
    }
  }

  /* ============ AUTO-LOOP ============ */
  var AUTO_INTERVAL = 5000;
  var MANUAL_PAUSE = 15000;
  var autoTimer = null;
  var resumeTimer = null;

  function autoNext() { switchChapter(active + 1); }
  function startAutoLoop() {
    /* DESACTIVADO a pedido de Juani: la seccion NUNCA se mueve sola.
       (antes rotaba cada 5s y ademas revivia a los 15s tras interaccion) */
  }
  function stopAutoLoop() {
    if (autoTimer) { clearInterval(autoTimer); autoTimer = null; }
  }
  function pauseForManual() {
    stopAutoLoop();
    if (resumeTimer) clearTimeout(resumeTimer);
    resumeTimer = setTimeout(function () {
      resumeTimer = null;
      startAutoLoop();
    }, MANUAL_PAUSE);
  }

  /* Inicializa render desde estado inicial */
  render();
  /* auto-loop DESACTIVADO: solo se mueve cuando el usuario lo pide */

  /* ===== Pausa total cuando la seccion sale del viewport =====
     Mata todas las animaciones CSS del trilogy (rim glow, float, aura)
     y el auto-loop cuando estamos scrolleando lejos. Apenas vuelve a
     entrar, retoma. Esto es lo que da el "feel" de scroll fluido. */
  if ('IntersectionObserver' in window) {
    var visibilityIO = new IntersectionObserver(function (entries) {
      var isVisible = entries[0].isIntersecting;
      section.classList.toggle('is-paused', !isVisible);
      if (isVisible) {
      } else {
        stopAutoLoop();
      }
    }, { threshold: 0.1 });
    visibilityIO.observe(section);
  }
})();
</script>
