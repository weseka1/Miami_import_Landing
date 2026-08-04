{# ============================================================
   MIAMI_IMPORT — Custom styles (inline)
   Incluido desde layouts/layout.tpl en <head>.
   No depende de static_url (que falla con .css planos).
   ============================================================ #}
<style>
/* DUAL PRICE DISPLAY — USD arriba + ARS abajo (aplicado via JS) */
.miami-price-dual {
  display: block !important;
  line-height: 1.25;
}
.miami-price-dual .miami-price-usd {
  display: block;
  font-size: clamp(20px, 3vw, 28px);
  font-weight: 600;
  color: var(--miami-gold, #b99b63);
  letter-spacing: 0.04em;
  text-transform: uppercase;
  margin-bottom: 4px;
  font-variant-numeric: tabular-nums;
}
.miami-price-dual .miami-price-ars-label {
  display: block;
  font-size: 10px;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  color: rgba(255,255,255,0.5);
  margin-top: 2px;
}
.miami-price-dual .miami-price-ars {
  display: block;
  font-size: 13px;
  font-weight: 500;
  color: rgba(255,255,255,0.78);
  font-variant-numeric: tabular-nums;
}
/* Mas chico en cards del catalogo */
.miami-products-grid .miami-price-dual .miami-price-usd,
.item-product .miami-price-dual .miami-price-usd,
.js-item-product .miami-price-dual .miami-price-usd {
  font-size: clamp(16px, 2.4vw, 20px);
}
.miami-products-grid .miami-price-dual .miami-price-ars,
.item-product .miami-price-dual .miami-price-ars,
.js-item-product .miami-price-dual .miami-price-ars {
  font-size: 11px;
}
/* Mas grande en detalle de producto */
body.template-product .miami-price-dual .miami-price-usd {
  font-size: clamp(28px, 4vw, 42px);
  margin-bottom: 6px;
}
body.template-product .miami-price-dual .miami-price-ars {
  font-size: 14px;
}
body.template-product .miami-price-dual .miami-price-ars-label {
  font-size: 10px;
  margin-top: 6px;
}
</style>
<style>
:root {
  --miami-bg: #ffffff;
  --miami-bg-soft: #f6f3ee;
  --miami-text: #111111;
  --miami-muted: #6f6f6f;
  --miami-border: #e8e2d8;
  --miami-gold: #b99b63;
  --miami-dark: #0f0f0f;
  --miami-radius: 18px;
  --miami-shadow: 0 18px 45px rgba(0,0,0,.08);
  --miami-track: 0.18em;
  --miami-track-wide: 0.45em;
  --miami-ease: cubic-bezier(0.22, 0.61, 0.36, 1);
  /* === Aliases --mi-* (compat con bloque CATALOGO/PRODUCT) === */
  --mi-ink: var(--miami-text);
  --mi-paper: var(--miami-bg);
  --mi-mist: var(--miami-bg-soft);
  --mi-stone: var(--miami-muted);
  --mi-rule: var(--miami-border);
  --mi-accent: var(--miami-text);
  --mi-track: var(--miami-track);
  --mi-track-wide: var(--miami-track-wide);
  --mi-track-xwide: 0.55em;
  --mi-ease: var(--miami-ease);
  --mi-overlay: rgba(10, 10, 10, 0.78);

}

/* === Tipografía global (sin pisar mucho el theme) === */
body { font-family: 'Helvetica Neue', Helvetica, Inter, Arial, sans-serif; -webkit-font-smoothing: antialiased; color: var(--miami-text); }
h1, h2, h3, h4, h5, h6, .h1, .h2, .h3, .h4, .h5, .h6 {
  font-family: 'Helvetica Neue', Helvetica, Inter, Arial, sans-serif;
  font-weight: 500;
}

/* === HERO MIAMI (top de la home) === */
.miami-hero {
  position: relative; min-height: 84vh;
  display: flex; align-items: center; justify-content: center;
  overflow: hidden; background: var(--miami-dark); color: #fff;
  isolation: isolate; margin: 0;
}
.miami-hero::before {
  content: ""; position: absolute; inset: 0; z-index: 0; pointer-events: none;
  background:
    radial-gradient(ellipse at 25% 15%, rgba(255,255,255,0.14), transparent 55%),
    radial-gradient(ellipse at 78% 85%, rgba(255,255,255,0.08), transparent 60%),
    radial-gradient(ellipse at 50% 50%, rgba(255,255,255,0.04), transparent 70%),
    linear-gradient(180deg, #060606 0%, #131313 45%, #1a1a1a 75%, #0a0a0a 100%);
}
/* (Aros 3D removidos — la lluvia de marcas es la única atmósfera del hero) */

/* === Lluvia de marcas en el hero === */
.miami-hero__rain {
  position: absolute; inset: 0; z-index: 0;
  overflow: hidden; pointer-events: none;
}
.miami-rain-word {
  position: absolute; top: -8%;
  font-family: 'Helvetica Neue', Helvetica, Inter, Arial, sans-serif;
  font-weight: 200;
  letter-spacing: 0.45em;
  text-transform: uppercase;
  color: rgba(255,255,255,0.16);
  white-space: nowrap;
  font-size: clamp(10px, 1.05vw, 14px);
  left: var(--rx, 50%);
  animation: miami-rain-fall var(--rd, 22s) linear var(--rdy, 0s) infinite;
}
.miami-rain-word--bold {
  font-size: clamp(13px, 1.6vw, 22px);
  font-weight: 300;
  color: rgba(255,255,255,0.22);
  letter-spacing: 0.32em;
}
.miami-rain-word--ghost {
  font-size: clamp(9px, 0.9vw, 12px);
  color: rgba(255,255,255,0.09);
  letter-spacing: 0.58em;
}
@media (max-width: 768px) {
  .miami-rain-word { display: none; }
  .miami-rain-word--bold,
  .miami-rain-word--ghost { display: inline-block; opacity: 0.6; }
}
@keyframes miami-rain-fall {
  0%   { transform: translateY(-10vh); opacity: 0; }
  8%   { opacity: 1; }
  92%  { opacity: 1; }
  100% { transform: translateY(120vh); opacity: 0; }
}
.miami-hero__inner {
  max-width: 1100px; width: 100%;
  padding: 96px 24px 80px; text-align: center; position: relative; z-index: 2;
}
.miami-hero__brand {
  font-size: 13px; letter-spacing: 0.55em; text-transform: uppercase;
  font-weight: 500; color: #fff; opacity: 0.92;
  margin-bottom: 72px; padding-left: 0.55em; /* compensa letter-spacing del último char */
  display: inline-flex; align-items: center; gap: 16px;
}
.miami-hero__brand::before, .miami-hero__brand::after {
  content: ""; display: block; width: 36px; height: 1px; background: #fff; opacity: 0.5;
}
.miami-hero__title {
  font-size: clamp(40px, 8.4vw, 124px);
  line-height: 1.06;
  letter-spacing: 0.04em;
  font-weight: 500;
  margin: 0 auto 36px;
  color: #fff;
  text-transform: uppercase;
  max-width: 1100px;
}
.miami-hero__title br + .miami-stroke {
  display: inline-block;
  margin-top: 0.08em; /* aire extra entre la línea con stroke y la primera */
}
.miami-hero__title .miami-stroke {
  -webkit-text-stroke: 1.4px #fff;
  -webkit-text-fill-color: transparent;
  color: transparent;
  letter-spacing: 0.06em; /* las letras outlined ganan respiro */
}
.miami-hero__sub {
  font-size: 11px; letter-spacing: 0.42em; text-transform: uppercase;
  color: #fff; opacity: 0.7; margin: 0 auto 44px; max-width: 480px; line-height: 1.7;
  font-weight: 400;
}
.miami-hero__actions {
  display: flex; gap: 12px; justify-content: center; flex-wrap: wrap;
  margin-bottom: 56px;
}
@media (max-width: 640px) {
  .miami-hero__brand { margin-bottom: 48px; font-size: 11px; letter-spacing: 0.4em; }
  .miami-hero__brand::before, .miami-hero__brand::after { width: 22px; }
  .miami-hero__title { font-size: clamp(36px, 12.5vw, 72px); line-height: 1.04; letter-spacing: 0.03em; }
  .miami-hero__title .miami-stroke { -webkit-text-stroke: 1px #fff; letter-spacing: 0.04em; }
  .miami-hero__sub { font-size: 10px; letter-spacing: 0.36em; margin-bottom: 36px; }
  .miami-hero__actions { margin-bottom: 40px; gap: 8px; }
}
.miami-btn {
  display: inline-flex; align-items: center; justify-content: center; gap: 10px;
  padding: 18px 32px; font-size: 11px; letter-spacing: 0.18em;
  text-transform: uppercase; font-weight: 500; text-decoration: none;
  border: 1px solid currentColor; transition: all 0.3s var(--miami-ease);
  cursor: pointer; background: transparent; line-height: 1;
}
.miami-btn--primary {
  background: #fff; color: var(--miami-dark); border-color: #fff;
}
.miami-btn--primary:hover { background: transparent; color: #fff; }
.miami-btn--ghost { color: #fff; }
.miami-btn--ghost:hover { background: #fff; color: var(--miami-dark); }
.miami-btn--xl { padding: 22px 40px; font-size: 12px; }
.miami-hero__chips {
  display: inline-flex; gap: 14px; flex-wrap: wrap; justify-content: center;
  font-size: 9px; letter-spacing: 0.4em; text-transform: uppercase;
  color: #fff; opacity: 0.5;
  align-items: center;
}
.miami-hero__chips .miami-hero__chip-dot {
  display: inline-block; width: 4px; height: 4px;
  border-radius: 50%; background: #fff; opacity: 0.55;
}
@media (max-width: 640px) {
  .miami-hero__chips { gap: 10px; font-size: 8px; letter-spacing: 0.32em; }
}

/* === Ticker editorial === */
.miami-ticker {
  background: var(--miami-dark); color: #fff;
  border-top: 1px solid rgba(255,255,255,0.1);
  border-bottom: 1px solid rgba(255,255,255,0.1);
  overflow: hidden; padding: 14px 0;
}
.miami-ticker__track {
  display: flex; gap: 56px; animation: miami-tick 36s linear infinite;
  white-space: nowrap; font-size: 11px; letter-spacing: 0.4em;
  text-transform: uppercase;
}
.miami-ticker__track > span { flex-shrink: 0; opacity: 0.85; }
@keyframes miami-tick {
  0% { transform: translateX(0); } 100% { transform: translateX(-50%); }
}

/* === Trust strip === */
.miami-trust {
  background: var(--miami-bg-soft); padding: 32px 16px;
  border-top: 1px solid var(--miami-border);
  border-bottom: 1px solid var(--miami-border);
}
.miami-trust__grid {
  max-width: 1180px; margin: 0 auto; display: grid;
  grid-template-columns: repeat(4, 1fr); gap: 16px;
}
@media (max-width: 768px) {
  .miami-trust__grid { grid-template-columns: repeat(2, 1fr); }
}
.miami-trust__item {
  text-align: center; padding: 12px; font-size: 11px;
  letter-spacing: 0.28em; text-transform: uppercase; color: var(--miami-text);
}
.miami-trust__item strong {
  display: block; font-weight: 500; font-size: 13px; letter-spacing: 0.2em;
  margin-bottom: 6px;
}
.miami-trust__item span {
  display: block; color: var(--miami-muted); letter-spacing: 0.18em;
  font-size: 10px; line-height: 1.6;
}

/* === Sección genérica === */
.miami-section { padding: 80px 24px; background: var(--miami-bg); border-top: 1px solid var(--miami-border); }
.miami-section--dark { background: var(--miami-dark); color: #fff; border-top: none; }
.miami-section--soft { background: var(--miami-bg-soft); }
.miami-section__head {
  max-width: 1100px; margin: 0 auto 56px;
  display: flex; flex-direction: column; align-items: center;
  text-align: center; gap: 12px;
}
.miami-eyebrow {
  font-size: 10px; letter-spacing: 0.5em; text-transform: uppercase;
  color: var(--miami-muted); margin-bottom: 12px;
}
.miami-section--dark .miami-eyebrow { color: rgba(255,255,255,0.55); }
.miami-section__title {
  font-size: clamp(26px, 4vw, 44px); letter-spacing: 0.18em;
  margin: 0; font-weight: 500; text-transform: uppercase; color: inherit;
}
.miami-section__sub {
  font-size: 13px; letter-spacing: 0.4em; text-transform: uppercase;
  color: var(--miami-muted); margin: 4px 0 0;
}
.miami-section--dark .miami-section__sub { color: rgba(255,255,255,0.6); }
.miami-section__link {
  font-size: 11px; letter-spacing: 0.2em; text-transform: uppercase;
  color: inherit; text-decoration: none; border-bottom: 1px solid currentColor;
  padding-bottom: 4px; transition: opacity 0.3s var(--miami-ease);
  margin-top: 12px; align-self: center;
}
.miami-section__link:hover { opacity: 0.6; }

/* === Status quote pantalla completa === */
.miami-status {
  background: var(--miami-dark); color: #fff;
  padding: 120px 24px; text-align: center;
}
.miami-status__quote {
  max-width: 880px; margin: 0 auto 24px;
  font-size: clamp(28px, 4.5vw, 56px); line-height: 1.18;
  font-weight: 500; letter-spacing: 0.01em; color: #fff;
}
.miami-status__foot {
  font-size: 11px; letter-spacing: 0.5em; text-transform: uppercase;
  opacity: 0.55; color: #fff;
}

/* === Marquee marcas === */
.miami-marquee {
  background: #fff; border-top: 1px solid var(--miami-border);
  border-bottom: 1px solid var(--miami-border);
  overflow: hidden; padding: 28px 0;
}
.miami-marquee__track {
  display: flex; gap: 48px; animation: miami-marq 48s linear infinite;
  white-space: nowrap; font-size: clamp(18px, 2.4vw, 34px);
  font-weight: 500; letter-spacing: 0.4em; text-transform: uppercase;
  color: var(--miami-dark);
}
.miami-marquee__track > span { flex-shrink: 0; }
.miami-marquee__track > span.miami-dot {
  width: 6px; height: 6px; border-radius: 50%;
  background: var(--miami-dark); align-self: center; display: inline-block;
}
@keyframes miami-marq {
  0% { transform: translateX(0); } 100% { transform: translateX(-50%); }
}

/* === Editorial split (foto + quote en 2 columnas) === */
.miami-split {
  display: grid; grid-template-columns: 1fr 1fr;
  min-height: 560px; background: #fff;
  border-top: 1px solid var(--miami-border);
  border-bottom: 1px solid var(--miami-border);
}
@media (max-width: 900px) { .miami-split { grid-template-columns: 1fr; } }
.miami-split__media {
  position: relative; background: var(--miami-dark); color: #fff;
  padding: 56px 48px; min-height: 480px;
  display: flex; flex-direction: column; justify-content: space-between;
  overflow: hidden;
}
.miami-split__media::before {
  content: ""; position: absolute; inset: 0;
  background:
    radial-gradient(ellipse at 20% 30%, rgba(255,255,255,0.10), transparent 55%),
    radial-gradient(ellipse at 80% 80%, rgba(255,255,255,0.05), transparent 60%);
  pointer-events: none;
}
.miami-split__media::after {
  content: ""; position: absolute; inset: 0; pointer-events: none;
  background-image:
    repeating-linear-gradient(0deg,  rgba(255,255,255,0.022) 0 1px, transparent 1px 80px),
    repeating-linear-gradient(90deg, rgba(255,255,255,0.022) 0 1px, transparent 1px 80px);
}
.miami-split__media--alt { background: var(--miami-bg-soft); color: var(--miami-dark); }
.miami-split__media--alt::before {
  background:
    radial-gradient(ellipse at 20% 30%, rgba(0,0,0,0.05), transparent 55%),
    radial-gradient(ellipse at 80% 80%, rgba(0,0,0,0.03), transparent 60%);
}
.miami-split__media--alt::after {
  background-image:
    repeating-linear-gradient(0deg,  rgba(0,0,0,0.022) 0 1px, transparent 1px 80px),
    repeating-linear-gradient(90deg, rgba(0,0,0,0.022) 0 1px, transparent 1px 80px);
}
.miami-split__media--photo {
  text-decoration: none; background: var(--miami-dark);
  display: block; padding: 0; min-height: 480px;
}
.miami-split__media--photo::before, .miami-split__media--photo::after { display: none; }
.miami-split__img {
  position: absolute; inset: 0; width: 100%; height: 100%;
  object-fit: cover; display: block; z-index: 0;
  transition: transform 0.7s var(--miami-ease);
  filter: brightness(0.85) saturate(0.95);
}
.miami-split__media--photo:hover .miami-split__img { transform: scale(1.04); }
.miami-split__media-overlay {
  position: absolute; inset: 0; z-index: 2;
  display: flex; flex-direction: column; justify-content: space-between;
  align-items: center; text-align: center;
  padding: 56px 48px;
  background:
    linear-gradient(180deg, rgba(0,0,0,0.55) 0%, rgba(0,0,0,0.15) 35%, rgba(0,0,0,0.15) 65%, rgba(0,0,0,0.65) 100%);
  color: #fff;
}
.miami-split__media-overlay .miami-split__media-tag,
.miami-split__media-overlay .miami-split__media-brand,
.miami-split__media-overlay .miami-split__media-foot { color: #fff; }
@media (max-width: 768px) {
  .miami-split__media-overlay { padding: 48px 28px; }
}
.miami-split__media-tag {
  position: relative; z-index: 1;
  font-size: 10px; letter-spacing: 0.5em; text-transform: uppercase; opacity: 0.55;
}
.miami-split__media-brand {
  position: relative; z-index: 1;
  font-size: clamp(56px, 9vw, 128px); font-weight: 500;
  letter-spacing: 0.04em; text-transform: uppercase; line-height: 0.95;
  margin: auto 0;
}
.miami-split__media-foot {
  position: relative; z-index: 1;
  font-size: 10px; letter-spacing: 0.5em; text-transform: uppercase; opacity: 0.55;
}
.miami-split__content {
  padding: 64px 48px; display: flex; flex-direction: column; justify-content: center;
  align-items: center; text-align: center;
  background: #fff;
}
.miami-split--reverse .miami-split__content { order: 1; }
.miami-split--reverse .miami-split__media   { order: 2; }
@media (max-width: 900px) {
  .miami-split--reverse .miami-split__content { order: 2; }
  .miami-split--reverse .miami-split__media   { order: 1; }
}
.miami-split__quote {
  font-size: clamp(28px, 4.4vw, 56px);
  font-weight: 500; letter-spacing: 0.01em;
  text-transform: none; line-height: 1.1;
  margin: 16px 0 24px; color: var(--miami-dark);
}
.miami-split__copy {
  font-size: 15px; line-height: 1.8; color: var(--miami-muted);
  margin: 0 auto 32px; max-width: 520px;
}
.miami-split__actions { margin-top: 8px; display: flex; justify-content: center; }
@media (max-width: 768px) {
  .miami-split__media { padding: 48px 28px; min-height: 360px; }
  .miami-split__content { padding: 48px 28px; }
}

/* === Lookbook (2 tiles con foto + overlay) === */
.miami-lookbook {
  display: grid; grid-template-columns: 1fr 1fr; gap: 2px;
  background: var(--miami-border);
  border-bottom: 1px solid var(--miami-border);
}
@media (max-width: 768px) { .miami-lookbook { grid-template-columns: 1fr; } }
.miami-lookbook__tile {
  position: relative; min-height: 480px;
  display: block; text-decoration: none; overflow: hidden;
  background: var(--miami-dark);
}
.miami-lookbook__img {
  position: absolute; inset: 0; width: 100%; height: 100%;
  object-fit: cover; display: block; z-index: 0;
  transition: transform 0.7s var(--miami-ease);
  filter: brightness(0.78) saturate(0.95);
}
.miami-lookbook__tile:hover .miami-lookbook__img {
  transform: scale(1.05); filter: brightness(0.85) saturate(1);
}
.miami-lookbook__overlay {
  position: absolute; inset: 0; z-index: 1;
  display: flex; flex-direction: column; justify-content: space-between;
  align-items: center; text-align: center;
  padding: 48px;
  color: #fff;
  background:
    linear-gradient(180deg, rgba(0,0,0,0.45) 0%, rgba(0,0,0,0.15) 40%, rgba(0,0,0,0.7) 100%);
}
@media (max-width: 768px) { .miami-lookbook__overlay { padding: 40px 28px; } }
.miami-lookbook__no {
  font-size: 10px; letter-spacing: 0.5em; text-transform: uppercase; opacity: 0.7;
  color: #fff;
}
.miami-lookbook__title {
  font-size: clamp(30px, 5vw, 60px); font-weight: 500;
  letter-spacing: 0.04em; text-transform: uppercase; line-height: 0.96;
  margin: auto 0 16px; color: #fff;
}
.miami-lookbook__sub {
  font-size: 12px; letter-spacing: 0.3em; text-transform: uppercase;
  opacity: 0.85; margin-bottom: 28px; color: #fff;
}
.miami-lookbook__cta {
  font-size: 11px; letter-spacing: 0.4em; text-transform: uppercase; font-weight: 500;
  display: inline-block; padding-bottom: 6px;
  border-bottom: 1px solid currentColor; align-self: center;
  transition: padding 0.4s var(--miami-ease);
  color: #fff;
}
.miami-lookbook__tile:hover .miami-lookbook__cta { padding-right: 12px; }
/* FIX reflow: el padding del hover empujaba "EXPLORAR CAPÍTULO" a 2 renglones.
   Se fija a UNA línea (base y hover) para que el hover solo desplace/ilumine. */
.miami-lookbook__cta,
.miami-lookbook__cta--glass,
.miami-lookbook__cta--glass > span { white-space: nowrap; }

/* === Products grid (cuando sections.primary tiene items) === */
.miami-products-grid {
  max-width: 1280px; margin: 0 auto;
  display: grid; grid-template-columns: repeat(4, 1fr); gap: 24px;
}
@media (max-width: 1024px) { .miami-products-grid { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 768px)  { .miami-products-grid { grid-template-columns: repeat(2, 1fr); } }

/* === Brand grid (categorías destacadas) === */
.miami-brand-grid {
  max-width: 1280px; margin: 0 auto;
  display: grid; grid-template-columns: repeat(4, 1fr); gap: 2px;
  background: var(--miami-border);
  border: 1px solid var(--miami-border);
}
@media (max-width: 1024px) { .miami-brand-grid { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 640px)  { .miami-brand-grid { grid-template-columns: repeat(2, 1fr); } }

.miami-brand-tile {
  position: relative;
  aspect-ratio: 4 / 5;
  display: flex; flex-direction: column;
  align-items: center; justify-content: space-between;
  text-align: center;
  padding: 24px;
  text-decoration: none;
  color: #fff;
  background: var(--miami-dark);
  overflow: hidden;
}
.miami-brand-tile__img {
  position: absolute; inset: 0; width: 100%; height: 100%;
  object-fit: cover; display: block; z-index: 0;
  transition: transform 0.7s var(--miami-ease), filter 0.7s var(--miami-ease);
  filter: brightness(0.55) saturate(0.85) grayscale(0.15);
}
.miami-brand-tile:hover .miami-brand-tile__img {
  transform: scale(1.05);
  filter: brightness(0.75) saturate(1) grayscale(0);
}
.miami-brand-tile__overlay {
  position: absolute; inset: 0; z-index: 1;
  background:
    linear-gradient(180deg, rgba(0,0,0,0.5) 0%, rgba(0,0,0,0.15) 40%, rgba(0,0,0,0.65) 100%);
  pointer-events: none;
}
.miami-brand-tile--empty {
  background:
    radial-gradient(ellipse at 50% 100%, rgba(255,255,255,0.06), transparent 60%),
    linear-gradient(180deg, #0a0a0a 0%, #1a1a1a 100%);
}
.miami-brand-tile--empty::before {
  content: ""; position: absolute; inset: 0; pointer-events: none;
  background-image:
    repeating-linear-gradient(0deg, rgba(255,255,255,0.018) 0 1px, transparent 1px 60px),
    repeating-linear-gradient(90deg, rgba(255,255,255,0.018) 0 1px, transparent 1px 60px);
}
.miami-brand-tile::after {
  content: ""; position: absolute; left: 50%; bottom: 60px;
  width: 24px; height: 1px; transform: translateX(-50%);
  background: #fff; opacity: 0.4; z-index: 2;
  transition: width 0.4s var(--miami-ease), opacity 0.4s var(--miami-ease);
}
.miami-brand-tile:hover::after { width: 56px; opacity: 0.7; }
.miami-brand-tile:hover {
  background: var(--miami-dark);
  color: #fff;
}
.miami-brand-tile:hover::before { opacity: 0; }
.miami-brand-tile:hover::after  { opacity: 0.4; }
.miami-brand-tile__no {
  position: relative; z-index: 2;
  font-size: 11px; letter-spacing: 0.5em; text-transform: uppercase;
  opacity: 0.7; font-weight: 500; color: #fff;
}
.miami-brand-tile__name {
  position: relative; z-index: 2;
  font-size: clamp(20px, 2.6vw, 32px); font-weight: 500;
  letter-spacing: 0.16em; text-transform: uppercase;
  line-height: 1.05;
  margin-top: auto; margin-bottom: 12px;
  word-break: break-word;
  color: #fff;
}
.miami-brand-tile__cta {
  position: relative; z-index: 2;
  font-size: 10px; letter-spacing: 0.4em; text-transform: uppercase;
  opacity: 0.7; transform: translateY(0); transition: all 0.4s var(--miami-ease);
  color: #fff;
}
.miami-brand-tile:hover .miami-brand-tile__cta { opacity: 1; transform: translateY(-2px); }

/* === Bloque editorial centrado === */
.miami-editorial {
  max-width: 880px; margin: 0 auto; text-align: center; padding: 0 16px;
}
.miami-editorial h2 {
  font-size: clamp(26px, 3.6vw, 40px); text-transform: none;
  letter-spacing: 0.01em; line-height: 1.25; font-weight: 500;
  margin: 0 0 20px;
}
.miami-editorial p {
  font-size: 14px; letter-spacing: 0.02em; color: var(--miami-muted);
  margin: 0 auto; line-height: 1.8; max-width: 640px;
}

/* === CTA final === */
.miami-cta {
  background: var(--miami-bg-soft); padding: 112px 24px; text-align: center;
  border-top: 1px solid var(--miami-border);
}
.miami-cta__title {
  font-size: clamp(34px, 5.6vw, 72px); font-weight: 500;
  letter-spacing: 0.18em; text-transform: uppercase;
  margin: 0 0 16px; color: var(--miami-dark);
}
.miami-cta__sub {
  font-size: 13px; letter-spacing: 0.4em; text-transform: uppercase;
  color: var(--miami-muted); margin: 0 0 40px;
}

/* === Footer extra (bloque institucional) === */
.miami-footer-extra {
  padding: 56px 24px 28px; background: var(--miami-dark); color: #fff;
}
.miami-footer-extra__grid {
  max-width: 1180px; margin: 0 auto; display: grid;
  gap: 48px; grid-template-columns: 1fr 1fr 1fr;
  text-align: center;
}
.miami-footer-extra__grid > * {
  display: flex; flex-direction: column; align-items: center;
}
@media (max-width: 780px) {
  .miami-footer-extra__grid { grid-template-columns: 1fr; gap: 40px; }
}
.miami-footer-extra .miami-eyebrow { color: rgba(255,255,255,0.6); margin-bottom: 16px; }
.miami-footer-extra p { font-size: 13px; line-height: 1.8; margin: 0 auto 14px; opacity: 0.85; color: #fff; max-width: 360px; }
.miami-footer-extra ul { list-style: none; padding: 0; margin: 0; font-size: 13px; line-height: 2.2; text-align: center; }
.miami-footer-extra a { color: inherit; text-decoration: none; opacity: 0.85; transition: opacity 0.3s var(--miami-ease); }
.miami-footer-extra a:hover { opacity: 1; }
.miami-footer-extra__tag {
  font-size: 11px; letter-spacing: 0.4em; text-transform: uppercase;
  opacity: 0.55; margin: 0;
}
.miami-footer-extra__bottom {
  margin-top: 48px; padding-top: 24px;
  border-top: 1px solid rgba(255,255,255,0.1);
  text-align: center; font-size: 10px; letter-spacing: 0.4em;
  text-transform: uppercase; opacity: 0.5;
}
.miami-social-btn {
  display: inline-flex; width: 38px; height: 38px;
  align-items: center; justify-content: center;
  border: 1px solid rgba(255,255,255,0.5); border-radius: 50%;
  text-decoration: none; color: inherit; opacity: 0.85;
  transition: all 0.3s var(--miami-ease);
}
.miami-social-btn:hover { opacity: 1; background: #fff; color: var(--miami-dark); border-color: #fff; }
.miami-social-btn + .miami-social-btn { margin-left: 8px; }

/* === Modales legales === */
.miami-modal {
  position: fixed; inset: 0; z-index: 9999;
  display: flex; align-items: flex-start; justify-content: center;
  padding: 24px 12px; overflow-y: auto;
  animation: miami-fade 0.3s var(--miami-ease);
}
.miami-modal[hidden] { display: none; }
@keyframes miami-fade { from { opacity: 0; } to { opacity: 1; } }
.miami-modal__backdrop {
  position: fixed; inset: 0; background: rgba(10,10,10,0.78);
  -webkit-backdrop-filter: blur(8px); backdrop-filter: blur(8px);
}
.miami-modal__card {
  position: relative; max-width: 720px; width: 100%;
  background: #fff; color: var(--miami-dark);
  padding: 48px 36px 40px; margin: 32px auto;
  font-family: 'Helvetica Neue', Helvetica, Inter, Arial, sans-serif;
  line-height: 1.65; animation: miami-rise 0.4s var(--miami-ease);
  border-radius: 4px;
}
@keyframes miami-rise {
  from { transform: translateY(20px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}
@media (max-width: 640px) {
  .miami-modal__card { padding: 36px 20px; margin: 16px auto; }
}
.miami-modal__close {
  position: absolute; top: 14px; right: 14px;
  background: none; border: none; font-size: 28px; line-height: 1;
  color: var(--miami-dark); cursor: pointer;
  width: 36px; height: 36px;
  display: flex; align-items: center; justify-content: center;
}
.miami-modal__eyebrow {
  font-size: 10px; letter-spacing: 0.5em; text-transform: uppercase;
  color: var(--miami-muted); margin-bottom: 8px; text-align: center;
}
.miami-modal__title {
  font-weight: 500; letter-spacing: 0.18em; font-size: 24px;
  text-transform: uppercase; margin: 0 0 28px; text-align: center;
  color: var(--miami-dark);
}
.miami-modal__body { font-size: 15px; color: var(--miami-dark); }
.miami-modal__body h3 {
  font-weight: 500; letter-spacing: 0.18em; font-size: 12px;
  text-transform: uppercase; margin: 28px 0 10px;
  border-top: 1px solid var(--miami-border); padding-top: 20px;
}
.miami-modal__body p { margin: 0 0 12px; font-size: 15px; }
.miami-modal__body ul, .miami-modal__body ol { padding-left: 18px; margin: 0 0 12px; }
.miami-modal__body li { margin-bottom: 6px; font-size: 15px; }
.miami-modal__body strong { font-weight: 500; }
.miami-modal__body table { width: 100%; border-collapse: collapse; margin: 10px 0; font-size: 14px; }
.miami-modal__body th, .miami-modal__body td { padding: 8px 4px; text-align: left; border-bottom: 1px solid var(--miami-border); }
.miami-modal__body th { font-weight: 500; font-size: 11px; letter-spacing: 0.18em; text-transform: uppercase; color: var(--miami-muted); }
.miami-modal__body a { color: var(--miami-dark); text-decoration: underline; }
body.miami-modal-open { overflow: hidden; }

/* === Reveal on scroll === */
[data-miami-reveal] {
  opacity: 0; transform: translateY(20px);
  transition: opacity 0.9s var(--miami-ease), transform 0.9s var(--miami-ease);
}
[data-miami-reveal].is-revealed { opacity: 1; transform: translateY(0); }

/* === Botones nativos del theme: les damos look Nike === */
.btn-primary, .btn.btn-primary, input[type=submit].btn-primary,
.section-featured-products-home .btn,
.cart-button-container .btn {
  border-radius: 0 !important;
  letter-spacing: 0.18em !important;
  text-transform: uppercase !important;
  font-weight: 500 !important;
  background: var(--miami-dark) !important;
  border-color: var(--miami-dark) !important;
}

/* === Responsive ajustes === */
@media (max-width: 768px) {
  .miami-section { padding: 64px 18px; }
  .miami-status { padding: 80px 18px; }
  .miami-cta { padding: 80px 18px; }
  .miami-hero__inner { padding: 64px 16px 48px; }
  .miami-section__head { flex-direction: column; align-items: flex-start; gap: 8px; }
  .miami-footer-extra { padding: 48px 18px 24px; }
}

/* === Anti scroll horizontal === */
html, body { overflow-x: hidden; }

/* ===========================================================
   CATALOGO + PRODUCT DETAIL — overrides para que matcheen
   la estetica del home (negro / uppercase / tracking)
   =========================================================== */

/* --- Container general del catalogo --- */
.category-body { background: var(--mi-paper); padding-bottom: 64px; }
.category-body .container { max-width: 1280px; }

/* --- Header de categoria (h1 + count + sort) --- */
.category-body h1,
.category-body .h4 {
  font-family: 'Helvetica Neue', Helvetica, Inter, Arial, sans-serif !important;
  font-size: clamp(28px, 4vw, 48px) !important;
  letter-spacing: var(--mi-track) !important;
  text-transform: uppercase !important;
  font-weight: 500 !important;
  color: var(--mi-ink) !important;
  margin-bottom: 8px !important;
}

/* --- Breadcrumbs eyebrow style --- */
.category-body .breadcrumb,
.product-info .breadcrumb {
  font-size: 10px !important;
  letter-spacing: var(--mi-track-xwide) !important;
  text-transform: uppercase !important;
  color: var(--mi-stone) !important;
  margin-bottom: 14px !important;
  background: transparent !important;
  padding: 0 !important;
}
.category-body .breadcrumb a,
.product-info .breadcrumb a { color: var(--mi-stone) !important; text-decoration: none; }
.category-body .breadcrumb a:hover,
.product-info .breadcrumb a:hover { color: var(--mi-ink) !important; }

/* --- Sort by --- */
.category-body .form-select,
.category-body select.form-select-small {
  font-family: 'Helvetica Neue', Helvetica, Inter, Arial, sans-serif !important;
  font-size: 11px !important;
  letter-spacing: var(--mi-track) !important;
  text-transform: uppercase !important;
  border: 1px solid var(--mi-rule) !important;
  border-radius: 0 !important;
  background-color: #fff !important;
  color: var(--mi-ink) !important;
  padding: 12px 36px 12px 16px !important;
  font-weight: 500 !important;
}

/* --- Filtros sidebar --- */
.filters-controls,
.filters-list,
.filters-modal {
  font-family: 'Helvetica Neue', Helvetica, Inter, Arial, sans-serif !important;
}
.filters-controls .form-label,
.filters-controls h2,
.filters-controls h3,
.filters-controls .filter-title {
  font-size: 11px !important;
  letter-spacing: var(--mi-track-wide) !important;
  text-transform: uppercase !important;
  font-weight: 500 !important;
  color: var(--mi-ink) !important;
  margin-bottom: 14px !important;
  padding-bottom: 10px;
  border-bottom: 1px solid var(--mi-rule);
}
.filters-controls .form-check,
.filters-controls .filter-option {
  font-size: 12px !important;
  letter-spacing: 0.04em;
  color: var(--mi-ink);
  padding: 6px 0;
}
.filters-controls .form-check-input,
.filters-controls input[type="checkbox"] {
  border-radius: 0 !important;
  border-color: var(--mi-stone) !important;
  margin-right: 10px;
}
.filters-controls .form-check-input:checked {
  background-color: var(--mi-ink) !important;
  border-color: var(--mi-ink) !important;
}
.filters-controls a { color: var(--mi-ink) !important; }
.filters-controls a:hover { opacity: 0.6; }

/* --- Grid de productos --- */
.products-list .product-item,
.product-item {
  background: transparent !important;
  border: none !important;
  border-radius: 0 !important;
  box-shadow: none !important;
}
.product-item .product-item-image-container,
.product-item .item-image,
.product-item-link img {
  border-radius: 0 !important;
}
.product-item .product-item-image-container,
.product-item .placeholder {
  background: var(--mi-mist) !important;
  aspect-ratio: 1 / 1;
  overflow: hidden;
}
.product-item .product-item-image-container img {
  transition: transform 0.7s var(--mi-ease);
}
.product-item:hover .product-item-image-container img {
  transform: scale(1.04);
}
.product-item .item-name,
.product-item .product-item-name,
.product-item h3 {
  font-family: 'Helvetica Neue', Helvetica, Inter, Arial, sans-serif !important;
  font-size: 13px !important;
  font-weight: 500 !important;
  letter-spacing: 0.02em !important;
  text-transform: none !important;
  line-height: 1.4 !important;
  color: var(--mi-ink) !important;
  margin: 14px 0 6px !important;
}
.product-item .item-price,
.product-item .product-item-price,
.product-item .price {
  font-size: 13px !important;
  letter-spacing: 0.04em !important;
  color: var(--mi-ink) !important;
  font-weight: 400 !important;
}
.product-item .price-compare,
.product-item .item-price-compare {
  font-size: 11px !important;
  color: var(--mi-stone) !important;
  text-decoration: line-through;
}
.product-item .product-item-discount,
.product-item .label-accent {
  font-size: 10px !important;
  letter-spacing: var(--mi-track) !important;
  text-transform: uppercase !important;
  background: var(--mi-ink) !important;
  color: #fff !important;
  border-radius: 0 !important;
  padding: 5px 10px !important;
  font-weight: 500 !important;
}

/* --- Pagination --- */
.pagination .page-item .page-link,
.pagination a {
  font-size: 11px !important;
  letter-spacing: var(--mi-track) !important;
  text-transform: uppercase !important;
  border-radius: 0 !important;
  border-color: var(--mi-rule) !important;
  color: var(--mi-ink) !important;
  background: #fff !important;
}
.pagination .page-item.active .page-link {
  background: var(--mi-ink) !important;
  border-color: var(--mi-ink) !important;
  color: #fff !important;
}

/* ===========================================================
   PRODUCT DETAIL
   =========================================================== */
#single-product .container { max-width: 1280px; }
#single-product .product-columns {
  display: grid;
  grid-template-columns: 1.1fr 1fr;
  gap: 56px;
  align-items: start;
}
@media (max-width: 768px) {
  #single-product .product-columns { grid-template-columns: 1fr; gap: 24px; }
}

/* Imagen principal */
.product-images,
.product-image-container {
  background: var(--mi-mist);
  border-radius: 0 !important;
}
.product-images img,
.product-image-container img { border-radius: 0 !important; }
.product-image-thumbs .product-image-thumb { border-radius: 0 !important; }

/* Nombre del producto */
.product-info .product-name,
.product-info h1 {
  font-family: 'Helvetica Neue', Helvetica, Inter, Arial, sans-serif !important;
  font-size: clamp(22px, 3vw, 34px) !important;
  font-weight: 500 !important;
  letter-spacing: var(--mi-track) !important;
  text-transform: uppercase !important;
  color: var(--mi-ink) !important;
  line-height: 1.15 !important;
  margin-bottom: 12px !important;
}

/* Precio */
.product-info .product-price,
.product-info .price,
.product-info .js-product-price {
  font-size: clamp(20px, 2.5vw, 28px) !important;
  font-weight: 400 !important;
  letter-spacing: 0.04em !important;
  color: var(--mi-ink) !important;
  margin: 6px 0 24px !important;
}
.product-info .price-compare {
  font-size: 14px !important;
  color: var(--mi-stone) !important;
  text-decoration: line-through;
  margin-right: 10px;
}

/* SKU / metadata */
.product-info .product-sku,
.product-info .product-extra,
.product-info .font-small {
  font-size: 10px !important;
  letter-spacing: var(--mi-track-wide) !important;
  text-transform: uppercase !important;
  color: var(--mi-stone) !important;
}

/* Variantes (talles / colores) - chips cuadrados */
.product-info .product-variants,
.product-info .product-form-variants {
  margin: 28px 0 24px;
}
.product-info .form-label,
.product-info .product-form-variants label {
  font-size: 10px !important;
  letter-spacing: var(--mi-track-xwide) !important;
  text-transform: uppercase !important;
  color: var(--mi-stone) !important;
  font-weight: 500 !important;
  margin-bottom: 12px !important;
  display: block;
}
.product-info select.form-select,
.product-info .form-select {
  font-family: 'Helvetica Neue', Helvetica, Inter, Arial, sans-serif !important;
  font-size: 12px !important;
  letter-spacing: var(--mi-track) !important;
  text-transform: uppercase !important;
  border: 1px solid var(--mi-ink) !important;
  border-radius: 0 !important;
  background-color: #fff !important;
  color: var(--mi-ink) !important;
  padding: 14px 40px 14px 16px !important;
  font-weight: 500 !important;
  width: 100%;
  appearance: none;
  background-image: linear-gradient(45deg, transparent 50%, var(--mi-ink) 50%), linear-gradient(135deg, var(--mi-ink) 50%, transparent 50%);
  background-position: calc(100% - 18px) 50%, calc(100% - 12px) 50%;
  background-size: 6px 6px;
  background-repeat: no-repeat;
}

/* --- Selector de cantidad --- ULTRA centrado */
.product-info .form-quantity-container,
.cart-button-container {
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: 16px;
  margin-top: 16px;
}
.product-info .grid.grid-auto-1 {
  display: grid !important;
  grid-template-columns: 140px 1fr !important;
  gap: 16px !important;
  align-items: stretch !important;
}
@media (max-width: 480px) {
  .product-info .grid.grid-auto-1 {
    grid-template-columns: 1fr !important;
  }
}
.form-quantity {
  display: grid !important;
  grid-template-columns: 44px 1fr 44px !important;
  align-items: center !important;
  border: 1px solid var(--mi-ink);
  height: 50px;
}
.form-quantity-icon,
.js-quantity-down,
.js-quantity-up {
  background: transparent !important;
  color: var(--mi-ink) !important;
  border: none !important;
  width: 100% !important;
  height: 100% !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  cursor: pointer;
  padding: 0 !important;
  border-radius: 0 !important;
}
.form-quantity-icon:hover { background: var(--mi-ink) !important; color: #fff !important; }
.form-quantity-icon svg { width: 14px; height: 14px; }
.form-quantity .js-quantity-input,
.form-quantity input[type="number"] {
  border: none !important;
  border-left: 1px solid var(--mi-rule) !important;
  border-right: 1px solid var(--mi-rule) !important;
  height: 100% !important;
  text-align: center !important;
  font-family: 'Helvetica Neue', Helvetica, Inter, Arial, sans-serif !important;
  font-size: 14px !important;
  font-weight: 500 !important;
  letter-spacing: 0.04em;
  color: var(--mi-ink) !important;
  background: #fff !important;
  border-radius: 0 !important;
  padding: 0 !important;
  -moz-appearance: textfield;
}
.form-quantity input[type="number"]::-webkit-outer-spin-button,
.form-quantity input[type="number"]::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

/* MIAMI_IMPORT: ocultar el placeholder de loading del addtocart (era el "2do boton") — super aggressive */
.cart-button-container .js-addtocart-placeholder,
body.template-product .js-addtocart-placeholder,
div.js-addtocart-placeholder,
.js-addtocart.js-addtocart-placeholder {
  display: none !important;
  visibility: hidden !important;
  width: 0 !important;
  height: 0 !important;
  opacity: 0 !important;
  position: absolute !important;
  pointer-events: none !important;
  overflow: hidden !important;
}

/* --- CTA Add-to-cart --- */
.product-info .btn.js-addtocart,
.product-info input.js-addtocart,
.cart-button-container .btn-primary:not(.js-addtocart-placeholder) {
  font-family: 'Helvetica Neue', Helvetica, Inter, Arial, sans-serif !important;
  font-size: 12px !important;
  letter-spacing: var(--mi-track-wide) !important;
  text-transform: uppercase !important;
  font-weight: 500 !important;
  border-radius: 0 !important;
  border: 1px solid var(--mi-ink) !important;
  background: var(--mi-ink) !important;
  color: #fff !important;
  height: 50px !important;
  padding: 0 32px !important;
  width: 100% !important;
  display: inline-flex !important;
  align-items: center !important;
  justify-content: center !important;
  transition: background 0.3s var(--mi-ease), color 0.3s var(--mi-ease) !important;
}
.product-info .btn.js-addtocart:hover,
.product-info input.js-addtocart:hover,
.cart-button-container .btn-primary:hover {
  background: #fff !important;
  color: var(--mi-ink) !important;
}
.product-info .btn.js-addtocart.nostock,
.product-info input.js-addtocart.nostock {
  background: var(--mi-stone) !important;
  border-color: var(--mi-stone) !important;
  cursor: not-allowed;
}

/* CTA WhatsApp para "Pedir a importacion" en product detail */
.product-info .btn-whatsapp,
.product-info .product-whatsapp,
.product-info a.whatsapp-cta {
  background: transparent !important;
  color: var(--mi-ink) !important;
  border: 1px solid var(--mi-ink) !important;
  margin-top: 12px !important;
}
.product-info .btn-whatsapp:hover,
.product-info .product-whatsapp:hover,
.product-info a.whatsapp-cta:hover {
  background: var(--mi-ink) !important;
  color: #fff !important;
}

/* Descripcion */
.product-description,
.product-info .product-description {
  font-size: 14px !important;
  line-height: 1.8 !important;
  color: var(--mi-ink) !important;
  margin-top: 32px !important;
  padding-top: 32px !important;
  border-top: 1px solid var(--mi-rule);
}
.product-description h2 {
  font-size: 11px !important;
  letter-spacing: var(--mi-track-wide) !important;
  text-transform: uppercase !important;
  font-weight: 500 !important;
  margin-bottom: 16px !important;
  color: var(--mi-stone) !important;
}

/* Stock indicator */
.product-info .text-stock,
.product-info .js-product-stock {
  font-size: 10px !important;
  letter-spacing: var(--mi-track-wide) !important;
  text-transform: uppercase !important;
  color: var(--mi-accent) !important;
}

/* Related products section */
.related-products,
.cart-related-products {
  border-top: 1px solid var(--mi-rule);
  padding-top: 64px;
  margin-top: 64px;
}
.related-products h2,
.cart-related-products h2 {
  font-size: clamp(20px, 2.2vw, 28px) !important;
  letter-spacing: var(--mi-track) !important;
  text-transform: uppercase !important;
  font-weight: 500 !important;
  text-align: center;
  margin-bottom: 32px !important;
}

/* ===========================================================
   CART (carrito)
   =========================================================== */
.cart-page,
.cart-body {
  padding: 32px 0 64px;
}
.cart-page h1,
.cart-body h1 {
  font-size: clamp(24px, 3vw, 36px) !important;
  letter-spacing: var(--mi-track) !important;
  text-transform: uppercase !important;
  font-weight: 500 !important;
  margin-bottom: 24px !important;
}
.cart-item,
.cart-row {
  border-bottom: 1px solid var(--mi-rule);
  padding: 20px 0;
}
.cart-item .cart-item-image,
.cart-row img {
  border-radius: 0 !important;
}
.cart-item .item-name,
.cart-row .product-name {
  font-size: 13px !important;
  font-weight: 500 !important;
  letter-spacing: 0.02em !important;
  color: var(--mi-ink) !important;
  text-transform: none !important;
}
.cart-item .price,
.cart-row .item-price {
  font-size: 13px !important;
  font-weight: 500 !important;
  letter-spacing: 0.04em !important;
  color: var(--mi-ink) !important;
}
.cart-summary,
.cart-totals {
  border: 1px solid var(--mi-rule);
  padding: 24px;
}
.cart-summary .total,
.cart-totals .grand-total {
  font-size: 14px !important;
  letter-spacing: var(--mi-track) !important;
  text-transform: uppercase !important;
  font-weight: 500 !important;
  border-top: 1px solid var(--mi-rule);
  padding-top: 16px;
  margin-top: 16px;
}

/* ===========================================================
   SEARCH page
   =========================================================== */
.search-results h1 {
  font-size: clamp(24px, 3vw, 36px) !important;
  letter-spacing: var(--mi-track) !important;
  text-transform: uppercase !important;
  font-weight: 500 !important;
}

/* ===========================================================
   404 / EMPTY states
   =========================================================== */
.not-found,
.empty-state {
  text-align: center;
  padding: 96px 32px;
}
.not-found h1,
.empty-state h1 {
  font-size: clamp(32px, 5vw, 64px) !important;
  letter-spacing: var(--mi-track) !important;
  text-transform: uppercase !important;
  font-weight: 500 !important;
}

/* ===========================================================
   FORMS (contact, login, etc.)
   =========================================================== */
.form-control,
input[type="text"],
input[type="email"],
input[type="tel"],
input[type="password"],
textarea {
  border: 1px solid var(--mi-rule) !important;
  border-radius: 0 !important;
  font-family: 'Helvetica Neue', Helvetica, Inter, Arial, sans-serif !important;
  font-size: 14px !important;
  padding: 12px 16px !important;
  background: #fff !important;
  color: var(--mi-ink) !important;
  transition: border-color 0.2s var(--mi-ease);
}
.form-control:focus,
input:focus,
textarea:focus {
  border-color: var(--mi-ink) !important;
  outline: none !important;
  box-shadow: none !important;
}

/* ===========================================================
   HEADER cart count badge
   =========================================================== */
.cart-count,
.cart-badge,
.js-cart-count {
  background: var(--mi-ink) !important;
  color: #fff !important;
  font-size: 10px !important;
  letter-spacing: 0.04em !important;
  border-radius: 0 !important;
  padding: 2px 6px !important;
  font-weight: 500 !important;
}

/* =============================================================
   CHAMPAGNE NOIR — Overrides de paleta dorada + 3D CSS
   ============================================================= */

:root {
  --miami-gold:       #b99b63;   /* champagne — acento principal */
  --miami-gold-soft:  #d4bb88;   /* champagne claro para glow/hover */
  --miami-gold-deep:  #8e7547;   /* champagne profundo para borders */
  --mi-gold:          var(--miami-gold);
  --mi-gold-soft:     var(--miami-gold-soft);
  --mi-gold-deep:     var(--miami-gold-deep);
  --miami-tilt-max:   8deg;
  --miami-tilt-perspective: 900px;
}

/* --- Hero: stroke text "LLEGÓ UNA VEZ" en gold --- */
.miami-hero__title .miami-stroke {
  -webkit-text-stroke-color: var(--miami-gold) !important;
}

/* --- Hero brand "MIAMI_IMPORT" — barritas en gold sutil --- */
.miami-hero__brand::before,
.miami-hero__brand::after {
  background: var(--miami-gold) !important;
  opacity: 0.75 !important;
}

/* --- Hero chips dots en gold --- */
.miami-hero__chips .miami-hero__chip-dot {
  background: var(--miami-gold) !important;
  opacity: 0.85 !important;
}

/* --- Trust strip: <strong> en gold-deep para acento --- */
.miami-trust__item strong {
  color: var(--miami-gold-deep);
}

/* --- DOSSIER eyebrow en gold --- */
.miami-eyebrow,
.miami-modal__eyebrow {
  color: var(--miami-gold);
}
.miami-section--dark .miami-eyebrow,
.miami-footer-extra .miami-eyebrow {
  color: var(--miami-gold-soft);
}

/* --- Brand tile: numero (01..12) en gold + linea inferior en gold --- */
.miami-brand-tile__no {
  color: var(--miami-gold) !important;
  opacity: 0.95 !important;
}
.miami-brand-tile::after {
  background: var(--miami-gold) !important;
  opacity: 0.7 !important;
}
.miami-brand-tile:hover::after {
  opacity: 1 !important;
  width: 64px !important;
}

/* --- Lookbook number en gold --- */
.miami-lookbook__no {
  color: var(--miami-gold);
  opacity: 0.95;
}

/* --- Marquee dots en gold --- */
.miami-marquee__track > span.miami-dot {
  background: var(--miami-gold) !important;
}

/* --- Status quote: foot label en gold --- */
.miami-status__foot {
  color: var(--miami-gold);
  opacity: 0.95;
}

/* --- CTA final WhatsApp: dorado sobre negro (acento fuerte) --- */
.miami-cta .miami-btn--primary,
.miami-cta a.miami-btn--xl {
  background: var(--miami-gold) !important;
  border-color: var(--miami-gold) !important;
  color: #0f0f0f !important;
  box-shadow: 0 6px 24px rgba(185, 155, 99, 0.28);
}
.miami-cta .miami-btn--primary:hover,
.miami-cta a.miami-btn--xl:hover {
  background: transparent !important;
  color: var(--miami-gold) !important;
  border-color: var(--miami-gold) !important;
  box-shadow: 0 10px 36px rgba(185, 155, 99, 0.18);
}

/* --- Hero primary CTA: lift con sombra dorada --- */
.miami-hero__actions .miami-btn--primary {
  transition: all 0.35s var(--miami-ease), box-shadow 0.35s var(--miami-ease) !important;
}
.miami-hero__actions .miami-btn--primary:hover {
  box-shadow: 0 12px 36px rgba(185, 155, 99, 0.35);
  transform: translateY(-2px);
}
.miami-hero__actions .miami-btn--ghost {
  transition: all 0.35s var(--miami-ease), box-shadow 0.35s var(--miami-ease) !important;
}
.miami-hero__actions .miami-btn--ghost:hover {
  box-shadow: 0 12px 36px rgba(255, 255, 255, 0.18);
  transform: translateY(-2px);
}

/* --- Section link underline en gold al hover --- */
.miami-section__link {
  transition: color 0.3s var(--miami-ease), border-color 0.3s var(--miami-ease), opacity 0.3s var(--miami-ease);
}
.miami-section__link:hover {
  color: var(--miami-gold);
  border-bottom-color: var(--miami-gold);
  opacity: 1;
}

/* --- Modal title: subrayado dorado sutil --- */
.miami-modal__title {
  border-bottom: 1px solid var(--miami-gold);
  padding-bottom: 18px;
}

/* =============================================================
   3D CSS — Tilt cards, lookbook parallax, depth premium
   ============================================================= */

/* Brand tiles — perspective 3D que reacciona al mouse (via JS --tx/--ty) */
.miami-brand-tile {
  perspective: var(--miami-tilt-perspective);
  transform-style: preserve-3d;
  transition: transform 0.45s var(--miami-ease), box-shadow 0.45s var(--miami-ease);
  will-change: transform;
}
.miami-brand-tile[data-miami-tilt]:hover {
  transform:
    rotateX(calc(var(--ty, 0deg) * -1))
    rotateY(var(--tx, 0deg))
    translateZ(0);
  box-shadow:
    0 24px 50px rgba(0, 0, 0, 0.35),
    0 0 0 1px rgba(185, 155, 99, 0.35) inset;
}
.miami-brand-tile[data-miami-tilt] .miami-brand-tile__img {
  transition: transform 0.6s var(--miami-ease), filter 0.6s var(--miami-ease);
}
.miami-brand-tile[data-miami-tilt]:hover .miami-brand-tile__img {
  transform: scale(1.08) translateZ(20px);
}
.miami-brand-tile[data-miami-tilt] .miami-brand-tile__name,
.miami-brand-tile[data-miami-tilt] .miami-brand-tile__no,
.miami-brand-tile[data-miami-tilt] .miami-brand-tile__cta {
  transition: transform 0.45s var(--miami-ease);
}
.miami-brand-tile[data-miami-tilt]:hover .miami-brand-tile__name {
  transform: translateZ(28px);
}
.miami-brand-tile[data-miami-tilt]:hover .miami-brand-tile__no {
  transform: translateZ(18px);
}
.miami-brand-tile[data-miami-tilt]:hover .miami-brand-tile__cta {
  transform: translateZ(36px);
}

/* Lookbook tiles — lift 3D mas sutil + sombra dorada */
.miami-lookbook__tile {
  perspective: 1200px;
  transition: transform 0.5s var(--miami-ease), box-shadow 0.5s var(--miami-ease);
  will-change: transform;
}
.miami-lookbook__tile[data-miami-tilt]:hover {
  transform:
    rotateX(calc(var(--ty, 0deg) * -0.6))
    rotateY(calc(var(--tx, 0deg) * 0.6))
    translateY(-6px);
  box-shadow:
    0 28px 60px rgba(0, 0, 0, 0.38),
    0 0 0 1px rgba(185, 155, 99, 0.28);
}

/* Split media photo (dossier 01, 02) — depth sutil al hover */
.miami-split__media--photo {
  perspective: 1400px;
  transition: transform 0.6s var(--miami-ease);
  will-change: transform;
}
.miami-split__media--photo[data-miami-tilt]:hover {
  transform:
    rotateX(calc(var(--ty, 0deg) * -0.4))
    rotateY(calc(var(--tx, 0deg) * 0.4));
}

/* Reveal-on-scroll: entran con leve rotacion 3D (sensacion "flip suave") */
[data-miami-reveal] {
  transform-origin: center bottom;
  transform: translateY(28px) rotateX(6deg);
  transition: opacity 0.95s var(--miami-ease), transform 0.95s var(--miami-ease);
}
[data-miami-reveal].is-revealed {
  transform: translateY(0) rotateX(0);
}

/* Hero parallax layers — JS escribe --hero-mx/--hero-my (range -1..1) */
.miami-hero__rain {
  transform: translate3d(
    calc(var(--hero-mx, 0) * 18px),
    calc(var(--hero-my, 0) * 12px),
    0
  );
  transition: transform 0.2s linear;
  will-change: transform;
  /* Cuando Vanta esta activo (canvas inyectado adentro), bajamos opacidad
     de la lluvia para que no compita con la red 3D */
  opacity: 0.55;
}
.miami-hero__inner {
  transform: translate3d(
    calc(var(--hero-mx, 0) * -8px),
    calc(var(--hero-my, 0) * -6px),
    0
  );
  transition: transform 0.25s linear;
  will-change: transform;
}

/* === VANTA.NET layering ===
   Vanta inyecta un <canvas> directo dentro de .miami-hero. El canvas tiene
   que quedar al fondo (z-0), el gradiente original baja a z-(-1) y la
   lluvia + contenido por arriba. Sin esto el canvas tapa todo o queda
   tapado. */
.miami-hero {
  position: relative !important;
  isolation: isolate;
}
.miami-hero > canvas {
  position: absolute !important;
  top: 0 !important; left: 0 !important;
  width: 100% !important; height: 100% !important;
  z-index: 0 !important;
  pointer-events: auto;
}
.miami-hero::before {
  z-index: -1 !important;
  opacity: 0.55;
}
.miami-hero::after,
.miami-hero__rain {
  z-index: 1 !important;
}
.miami-hero__inner {
  z-index: 5 !important;
  position: relative;
}

/* =============================================================
   CUSTOM CURSOR (dot + ring magnetic)
   Solo se monta en devices con hover (desktop). Touch no.
   ============================================================= */
.miami-cursor {
  position: fixed; top: 0; left: 0;
  pointer-events: none;
  z-index: 999999;
  mix-blend-mode: difference;
  will-change: transform, width, height;
  opacity: 0;
  transition: opacity 0.25s ease;
}
.miami-cursor--dot {
  width: 6px; height: 6px;
  margin: -3px 0 0 -3px;
  background: #fff;
  border-radius: 50%;
  transition: opacity 0.2s ease, background 0.2s ease, transform 0.12s linear;
}
.miami-cursor--dot.is-hover {
  background: #b99b63;
}
.miami-cursor--ring {
  width: 38px; height: 38px;
  margin: -19px 0 0 -19px;
  border: 1px solid rgba(255,255,255,0.5);
  border-radius: 50%;
  transition: width 0.3s cubic-bezier(0.22, 0.61, 0.36, 1),
              height 0.3s cubic-bezier(0.22, 0.61, 0.36, 1),
              margin 0.3s cubic-bezier(0.22, 0.61, 0.36, 1),
              border-color 0.3s ease,
              opacity 0.25s ease,
              transform 0.18s linear;
}
.miami-cursor--ring.is-hover {
  width: 64px; height: 64px;
  margin: -32px 0 0 -32px;
  border-color: #b99b63;
  border-width: 1.5px;
}
/* Cuando hay custom cursor, ocultamos el nativo para sensacion premium */
@media (hover: hover) {
  body:has(.miami-cursor) { cursor: none; }
  body:has(.miami-cursor) a,
  body:has(.miami-cursor) button,
  body:has(.miami-cursor) [data-cursor-hover],
  body:has(.miami-cursor) .miami-magnetic { cursor: none; }
}
@media (prefers-reduced-motion: reduce) {
  .miami-cursor { display: none !important; }
}

/* =============================================================
   GLASSMORPHISM utility
   ============================================================= */
.miami-glass {
  background: rgba(15, 15, 15, 0.55);
  backdrop-filter: blur(16px) saturate(140%);
  -webkit-backdrop-filter: blur(16px) saturate(140%);
  border: 1px solid rgba(255,255,255,0.06);
  border-left: 1px solid rgba(185,155,99,0.45);
}

/* =============================================================
   MAGNETIC element base — el JS escribe transform inline
   ============================================================= */
.miami-magnetic {
  transition: transform 0.45s cubic-bezier(0.22, 0.61, 0.36, 1);
  will-change: transform;
}

/* Respeta usuarios con animaciones reducidas — desactiva tilt y parallax */
@media (prefers-reduced-motion: reduce) {
  .miami-brand-tile[data-miami-tilt]:hover,
  .miami-lookbook__tile[data-miami-tilt]:hover,
  .miami-split__media--photo[data-miami-tilt]:hover {
    transform: none !important;
  }
  .miami-brand-tile[data-miami-tilt]:hover .miami-brand-tile__img,
  .miami-brand-tile[data-miami-tilt]:hover .miami-brand-tile__name,
  .miami-brand-tile[data-miami-tilt]:hover .miami-brand-tile__no,
  .miami-brand-tile[data-miami-tilt]:hover .miami-brand-tile__cta {
    transform: none !important;
  }
  .miami-hero__rain,
  .miami-hero__inner {
    transform: none !important;
  }
  [data-miami-reveal] { transform: translateY(28px) !important; }
  [data-miami-reveal].is-revealed { transform: translateY(0) !important; }
}

/* === SPLIT MEDIA CLEAN — foto a fondo, sin overlay ni filtros === */
.miami-split__media--clean {
  padding: 0 !important;
  background: #000;
  overflow: hidden;
}
.miami-split__media--clean .miami-split__img {
  filter: none;
  inset: 0;
  width: 100%; height: 100%;
  object-fit: cover;
}
.miami-split__media--clean::before,
.miami-split__media--clean::after { display: none !important; }

/* ==========================================================================
   DARK PALETTE GLOBAL — TODO el sitio en negro con texturas sutiles
   ==========================================================================
   Estrategia:
   - Pasamos a negro toda seccion que estaba blanca/crema
   - Cada tipo de seccion lleva una textura distinta (dots, grid, halo)
   - El texto se ajusta a blanco/gris/dorado
   - Las paginas de Tiendanube (category, search, product) heredan el look
   ========================================================================== */

/* --- Body base + halo dorado ambiental — TODAS las paginas --- */
body,
body.template-home,
body.template-category,
body.template-search,
body.template-product,
body.template-cart,
body.template-page,
body.template-blog,
body.template-blog-post,
body.template-contact,
body.template-account,
body.template-404,
body.template-password {
  background:
    radial-gradient(circle at 50% 50%, rgba(185,155,99,0.06) 1px, transparent 1.8px) 0 0 / 30px 30px,
    radial-gradient(circle at 50% 50%, rgba(255,255,255,0.018) 1px, transparent 1.5px) 14px 14px / 30px 30px,
    radial-gradient(ellipse 90% 50% at 50% 0%, rgba(185,155,99,0.05), transparent 60%),
    #050505 !important;
  background-attachment: fixed;
  color: #f0eeea;
}

/* --- 1) SECTION base (era miami-bg blanco) — dots dorados visibles --- */
.miami-section:not(.miami-section--brands-float):not(.miami-section--products-dark):not(.miami-section--dark):not(.miami-section--soft) {
  background:
    radial-gradient(circle at 50% 50%, rgba(185,155,99,0.08) 1px, transparent 2px) 0 0 / 26px 26px,
    radial-gradient(circle at 50% 50%, rgba(255,255,255,0.022) 1px, transparent 1.5px) 13px 13px / 26px 26px,
    radial-gradient(ellipse 90% 50% at 50% 0%, rgba(185,155,99,0.07), transparent 60%),
    #0a0a0a !important;
  color: #f0eeea !important;
  border-top: 1px solid rgba(185,155,99,0.1) !important;
}
.miami-section:not(.miami-section--brands-float):not(.miami-section--products-dark):not(.miami-section--dark):not(.miami-section--soft) .miami-section__title { color: #fff !important; }
.miami-section:not(.miami-section--brands-float):not(.miami-section--products-dark):not(.miami-section--dark):not(.miami-section--soft) .miami-section__sub { color: rgba(255,255,255,0.6) !important; }
.miami-section:not(.miami-section--brands-float):not(.miami-section--products-dark):not(.miami-section--dark):not(.miami-section--soft) .miami-section__link { color: #fff !important; }
.miami-section:not(.miami-section--brands-float):not(.miami-section--products-dark):not(.miami-section--dark):not(.miami-section--soft) .miami-eyebrow { color: var(--miami-gold) !important; }

/* --- 2) SECTION--soft (era cream) — grid muy sutil + halo --- */
.miami-section--soft {
  background:
    repeating-linear-gradient(0deg,  rgba(255,255,255,0.02) 0 1px, transparent 1px 80px),
    repeating-linear-gradient(90deg, rgba(255,255,255,0.02) 0 1px, transparent 1px 80px),
    radial-gradient(ellipse 70% 40% at 30% 20%, rgba(185,155,99,0.06), transparent 65%),
    #080808 !important;
  color: #f0eeea !important;
}

/* --- 3) STATUS quote (era oscuro pero plano) — agregamos halo cromatico --- */
.miami-status {
  background:
    radial-gradient(ellipse 60% 50% at 50% 50%, rgba(185,155,99,0.06), transparent 70%),
    radial-gradient(circle at 50% 50%, rgba(185,155,99,0.025) 1px, transparent 1.5px) 0 0 / 36px 36px,
    #0a0a0a !important;
}

/* --- 4) CTA section ("Buscas un modelo que no esta?") --- */
.miami-cta {
  background:
    radial-gradient(ellipse 80% 50% at 50% 50%, rgba(185,155,99,0.08), transparent 60%),
    radial-gradient(circle at 50% 50%, rgba(185,155,99,0.04) 1px, transparent 1.8px) 0 0 / 32px 32px,
    #060606 !important;
  color: #fff !important;
  border-top: 1px solid rgba(185,155,99,0.15);
  border-bottom: 1px solid rgba(185,155,99,0.15);
}
.miami-cta .miami-cta__title { color: #fff !important; }
.miami-cta .miami-cta__sub { color: rgba(255,255,255,0.72) !important; }

/* --- 5) EDITORIAL centered (DOSSIER 03 procedencia) --- */
.miami-editorial,
.miami-section--soft .miami-editorial {
  color: #f0eeea;
}
.miami-editorial h2 { color: #fff !important; }
.miami-editorial p { color: rgba(255,255,255,0.72) !important; }

/* --- 6) SPLIT default bg (cuando no es --dark) --- */
.miami-split:not(.miami-split--dark) {
  background:
    radial-gradient(ellipse 70% 40% at 30% 0%, rgba(185,155,99,0.05), transparent 60%),
    #0a0a0a !important;
}
.miami-split:not(.miami-split--dark) .miami-split__content {
  background: transparent !important;
  color: #f0eeea !important;
}
.miami-split:not(.miami-split--dark) .miami-split__quote { color: #fff !important; }
.miami-split:not(.miami-split--dark) .miami-split__copy { color: rgba(255,255,255,0.72) !important; }
.miami-split:not(.miami-split--dark) .miami-split__content .miami-btn {
  border-color: var(--miami-gold) !important;
  color: var(--miami-gold) !important;
}
.miami-split:not(.miami-split--dark) .miami-split__content .miami-btn:hover {
  background: var(--miami-gold) !important;
  color: #000 !important;
}

/* --- 6.5) LOOKBOOK section background + márgenes — negro con grid sutil --- */
.miami-lookbook {
  background:
    repeating-linear-gradient(0deg,  rgba(185,155,99,0.025) 0 1px, transparent 1px 70px),
    repeating-linear-gradient(90deg, rgba(185,155,99,0.025) 0 1px, transparent 1px 70px),
    radial-gradient(ellipse 90% 50% at 50% 50%, rgba(185,155,99,0.05), transparent 65%),
    #050505 !important;
  border-top: 1px solid rgba(185,155,99,0.1) !important;
  border-bottom: 1px solid rgba(185,155,99,0.1) !important;
}

/* --- 7) PAGINAS DE TIENDANUBE (category, search, product) — fondo negro + dots --- */
body.template-category,
body.template-search,
body.template-product {
  background:
    radial-gradient(circle at 50% 50%, rgba(185,155,99,0.03) 1px, transparent 1.5px) 0 0 / 30px 30px,
    radial-gradient(ellipse 90% 40% at 50% 0%, rgba(185,155,99,0.05), transparent 60%),
    #060606 !important;
}
body.template-category main,
body.template-search main,
body.template-product main,
body.template-category .container,
body.template-search .container,
body.template-product .container {
  background: transparent !important;
}
/* Texto base sobre fondo oscuro */
body.template-category, body.template-search, body.template-product {
  color: #e8e6e1;
}
body.template-category h1, body.template-search h1, body.template-product h1,
body.template-category h2, body.template-search h2, body.template-product h2,
body.template-category h3, body.template-search h3, body.template-product h3 {
  color: #fff !important;
}
/* Cards de productos en la grilla de categoria/search */
body.template-category .item-product,
body.template-search .item-product,
body.template-category .js-item-product,
body.template-search .js-item-product {
  background: rgba(20,18,15,0.55);
  border: 1px solid rgba(185,155,99,0.08);
  padding: 14px 14px 18px;
  transition:
    border-color 0.4s var(--miami-ease),
    box-shadow 0.4s var(--miami-ease),
    transform 0.4s var(--miami-ease);
}
body.template-category .item-product:hover,
body.template-search .item-product:hover,
body.template-category .js-item-product:hover,
body.template-search .js-item-product:hover {
  border-color: rgba(185,155,99,0.5);
  box-shadow:
    0 0 0 1px rgba(185,155,99,0.2),
    0 0 24px rgba(185,155,99,0.22),
    0 12px 28px rgba(0,0,0,0.5);
  transform: translateY(-2px);
}
/* Nombres / precios */
body.template-category .item-name,
body.template-category .js-item-name,
body.template-search .item-name,
body.template-search .js-item-name,
body.template-product .item-name {
  color: #fff !important;
}
body.template-category .item-price,
body.template-category .js-price-display,
body.template-search .item-price,
body.template-search .js-price-display,
body.template-product .item-price,
body.template-product .js-price-display,
body.template-category .price,
body.template-search .price,
body.template-product .price {
  color: var(--miami-gold) !important;
}
body.template-category .price-compare,
body.template-search .price-compare,
body.template-product .price-compare {
  color: rgba(255,255,255,0.4) !important;
}
/* Slot imagen del item — fondo oscuro para que no quede franja blanca */
body.template-category .item-image,
body.template-search .item-image,
body.template-product .item-image,
body.template-category .item-image-wrapper,
body.template-search .item-image-wrapper {
  background: #0a0a0a !important;
}
/* Sidebar / filtros */
body.template-category aside,
body.template-category .filters,
body.template-category .filter-group {
  background: transparent !important;
  color: #e8e6e1 !important;
}
body.template-category aside h3,
body.template-category aside h4,
body.template-category aside h5,
body.template-category .filter-name,
body.template-category .filters .text-uppercase {
  color: #fff !important;
}
body.template-category .form-check-label,
body.template-category aside label,
body.template-category aside .text-muted {
  color: rgba(255,255,255,0.7) !important;
}
/* Inputs / selects sobre fondo oscuro */
body.template-category input[type="text"],
body.template-category input[type="search"],
body.template-category select,
body.template-search input[type="text"],
body.template-product input[type="text"],
body.template-product select {
  background: rgba(20,18,15,0.55) !important;
  border: 1px solid rgba(185,155,99,0.18) !important;
  color: #fff !important;
}
body.template-category input::placeholder,
body.template-search input::placeholder { color: rgba(255,255,255,0.4); }
/* Pagination dark */
body.template-category .pagination .page-link,
body.template-search .pagination .page-link {
  background: rgba(20,18,15,0.55) !important;
  border-color: rgba(185,155,99,0.18) !important;
  color: #fff !important;
}
body.template-category .pagination .page-item.active .page-link {
  background: var(--miami-gold) !important;
  border-color: var(--miami-gold) !important;
  color: #000 !important;
}
/* Breadcrumbs */
body.template-category .breadcrumb,
body.template-search .breadcrumb,
body.template-product .breadcrumb {
  background: transparent !important;
  color: rgba(255,255,255,0.6);
}
body.template-category .breadcrumb a,
body.template-search .breadcrumb a,
body.template-product .breadcrumb a {
  color: rgba(255,255,255,0.7) !important;
}
/* Product detail dark */
body.template-product .product-info,
body.template-product .product-info-wrapper,
body.template-product .product-detail {
  background: transparent !important;
  color: #e8e6e1 !important;
}
body.template-product .product-info .product-name,
body.template-product .product-info h1 {
  color: #fff !important;
}
body.template-product .form-quantity input[type="number"] {
  background: rgba(20,18,15,0.55) !important;
  color: #fff !important;
  border-color: rgba(185,155,99,0.25) !important;
}
body.template-product .product-info .btn.js-addtocart,
body.template-product .product-info input.js-addtocart {
  background: var(--miami-gold) !important;
  color: #000 !important;
  border-color: var(--miami-gold) !important;
}
body.template-product .product-info .btn.js-addtocart:hover {
  background: #fff !important;
  color: #000 !important;
  border-color: #fff !important;
}

/* ==========================================================================
   NUKE WHITE — todo lo blanco que quede en pages de catalogo/search/producto
   se pasa a transparente o a oscuro con dots de fondo.
   ========================================================================== */
body.template-category,
body.template-search,
body.template-product {
  background:
    radial-gradient(circle at 50% 50%, rgba(185,155,99,0.08) 1px, transparent 2px) 0 0 / 30px 30px,
    radial-gradient(circle at 50% 50%, rgba(255,255,255,0.02) 1px, transparent 1.5px) 14px 14px / 30px 30px,
    radial-gradient(ellipse 90% 50% at 50% 0%, rgba(185,155,99,0.06), transparent 60%),
    #060606 !important;
  background-attachment: fixed !important;
}

/* Containers / wrappers main / sections: TODOS transparentes */
body.template-category .container,
body.template-search .container,
body.template-product .container,
body.template-category section,
body.template-search section,
body.template-product section,
body.template-category main,
body.template-search main,
body.template-product main,
body.template-category .category-body,
body.template-search .category-body,
body.template-product .product-columns,
body.template-product #single-product,
body.template-category .row,
body.template-search .row,
body.template-product .row,
body.template-category .col,
body.template-search .col,
body.template-product .col,
body.template-category [class*="col-"],
body.template-search [class*="col-"],
body.template-product [class*="col-"] {
  background: transparent !important;
}

/* Cualquier clase bg-white o bg-light de bootstrap */
body.template-category .bg-white,
body.template-search .bg-white,
body.template-product .bg-white,
body.template-category .bg-light,
body.template-search .bg-light,
body.template-product .bg-light {
  background: transparent !important;
}

/* SELECTS de "Ordenar por" — fondo oscuro con borde dorado */
body.template-category select,
body.template-search select,
body.template-product select,
body.template-category .form-select,
body.template-search .form-select,
body.template-product .form-select,
body.template-category .form-select-small,
body.template-search .form-select-small,
body.template-product .form-select-small {
  background-color: rgba(20,18,15,0.65) !important;
  border-color: rgba(185,155,99,0.25) !important;
  color: #fff !important;
}
body.template-category select option,
body.template-search select option,
body.template-product select option {
  background: #0a0a0a;
  color: #fff;
}

/* Filtros sidebar (filter-name, form-check, etc) */
body.template-category .filter-name,
body.template-category .filter-group,
body.template-category .filter-group-title {
  color: #fff !important;
}
body.template-category .form-check-label,
body.template-category aside label {
  color: rgba(255,255,255,0.8) !important;
}

/* "Selección actual de..." (category.description) en blanco suave */
body.template-category .font-small,
body.template-search .font-small,
body.template-category p,
body.template-search p {
  color: rgba(255,255,255,0.7) !important;
}

/* Barra mobile FILTRAR / ORDENAR — fondo dark con borde dorado fino */
body.template-category .category-controls,
body.template-search .category-controls,
body.template-category .js-category-controls,
body.template-search .js-category-controls {
  background: rgba(15,15,15,0.7) !important;
  border-top: 1px solid rgba(185,155,99,0.18) !important;
  border-bottom: 1px solid rgba(185,155,99,0.18) !important;
}
body.template-category .category-controls button,
body.template-search .category-controls button,
body.template-category .js-category-controls button,
body.template-search .js-category-controls button {
  background: transparent !important;
  color: #fff !important;
  border-color: rgba(185,155,99,0.18) !important;
}
body.template-category .category-controls .right-line,
body.template-search .category-controls .right-line {
  border-right: 1px solid rgba(185,155,99,0.18) !important;
}
body.template-category .category-controls .font-weight-bold,
body.template-search .category-controls .font-weight-bold,
body.template-category .category-controls .font-smallest,
body.template-search .category-controls .font-smallest {
  color: rgba(185,155,99,0.85) !important;
}
body.template-category .top-line,
body.template-category .bottom-line,
body.template-search .top-line,
body.template-search .bottom-line {
  border-color: rgba(185,155,99,0.18) !important;
}

/* H1 del nombre de la categoria — solo el nombre en gris claro, prolijo */
body.template-category .miami-category-title,
body.template-search .miami-category-title {
  color: rgba(255,255,255,0.55) !important;
  font-size: clamp(28px, 4vw, 42px) !important;
  font-weight: 400 !important;
  letter-spacing: 0.18em !important;
  text-transform: uppercase !important;
  text-align: left;
  margin: 8px 0 28px !important;
}
/* ==========================================================================
   PRODUCT DETAIL — Layout compacto, prolijo, todo mas chico
   ========================================================================== */

/* Titulo del producto: tamano razonable, wrap natural */
body.template-product h1,
body.template-product .product-name,
body.template-product .h1 {
  color: #fff !important;
  word-break: normal !important;
  overflow-wrap: normal !important;
  font-size: clamp(18px, 4vw, 28px) !important;
  font-weight: 500 !important;
  letter-spacing: 0.02em !important;
  line-height: 1.25 !important;
  text-transform: none !important;
  margin: 8px 0 16px !important;
  text-align: left !important;
}

/* Padding general del wrapper del producto: mas compacto en mobile */
body.template-product #single-product .container {
  padding-top: 12px !important;
  padding-bottom: 24px !important;
}
body.template-product .product-columns {
  margin-bottom: 24px !important;
}
body.template-product .product-info {
  padding: 0 !important;
}
body.template-product .product-info > div,
body.template-product .product-info .pt-md-3 {
  padding-top: 0 !important;
}

/* Reducir margins de bloques internos del form (texto info, labels, etc) */
body.template-product .product-info .mb-3,
body.template-product .product-info .mb-4,
body.template-product .product-info .my-3,
body.template-product .product-info .my-4,
body.template-product .product-info .mt-3,
body.template-product .product-info .mt-4 {
  margin-bottom: 12px !important;
  margin-top: 0 !important;
}
body.template-product .product-info .pb-3,
body.template-product .product-info .pb-4 {
  padding-bottom: 8px !important;
}

/* Precio: tamano razonable */
body.template-product .price,
body.template-product .js-price-display,
body.template-product .product-price {
  font-size: clamp(20px, 4.5vw, 26px) !important;
  color: var(--miami-gold) !important;
  margin: 4px 0 12px !important;
  font-weight: 500 !important;
}

/* "No te lo pierdas..." label */
body.template-product .label-accent,
body.template-product .text-accent {
  font-size: 11px !important;
  margin: 6px 0 !important;
}

/* GoCuotas / cuotas / info financiera — compactar */
body.template-product [class*="gocuotas"],
body.template-product [class*="installments"],
body.template-product .custom-installments {
  font-size: 11px !important;
  margin: 4px 0 10px !important;
}

/* Talles: label + variants */
body.template-product .form-label,
body.template-product .variant-name {
  font-size: 11px !important;
  letter-spacing: 0.2em !important;
  text-transform: uppercase !important;
  color: rgba(255,255,255,0.7) !important;
  margin-bottom: 6px !important;
}
body.template-product .js-product-variants,
body.template-product .variant-options {
  margin-bottom: 14px !important;
}
body.template-product .form-variant,
body.template-product .js-variation-option,
body.template-product .variant-button {
  background: rgba(20,18,15,0.55) !important;
  border: 1px solid rgba(185,155,99,0.25) !important;
  color: #fff !important;
  padding: 8px 14px !important;
  font-size: 12px !important;
  letter-spacing: 0.1em !important;
}
body.template-product .form-variant:hover,
body.template-product .variant-button:hover {
  border-color: var(--miami-gold) !important;
}
body.template-product .form-variant.is-active,
body.template-product .js-variation-option.is-active,
body.template-product .form-variant.active {
  background: var(--miami-gold) !important;
  color: #000 !important;
  border-color: var(--miami-gold) !important;
}

/* Quantity input */
body.template-product .form-quantity {
  margin: 8px 0 14px !important;
}
body.template-product .form-quantity input[type="number"] {
  background: rgba(20,18,15,0.55) !important;
  color: #fff !important;
  border-color: rgba(185,155,99,0.25) !important;
  padding: 8px 12px !important;
  font-size: 13px !important;
  width: 60px !important;
}

/* Agregar al carrito: boton compacto pero claro */
body.template-product .btn.js-addtocart,
body.template-product input.js-addtocart {
  background: var(--miami-gold) !important;
  color: #0a0a0a !important;
  border: 1px solid var(--miami-gold) !important;
  padding: 12px 18px !important;
  font-size: 12px !important;
  letter-spacing: 0.25em !important;
  text-transform: uppercase !important;
  font-weight: 500 !important;
  margin: 8px 0 16px !important;
  width: 100%;
  transition: all 0.3s ease;
}
body.template-product .btn.js-addtocart:hover,
body.template-product input.js-addtocart:hover {
  background: #fff !important;
  color: #000 !important;
  border-color: #fff !important;
}

/* Banners "Compra protegida" / "Cambios y devoluciones" — solo ajusto tipografia
   y colores, NO toco el layout del grid base (eso lo rompia palabra por linea) */
body.template-product .icon-text .font-weight-bold {
  color: #fff !important;
  font-size: 13px !important;
  margin-bottom: 4px !important;
  text-transform: none !important;
}
body.template-product .icon-text {
  color: rgba(255,255,255,0.7) !important;
  font-size: 12px !important;
  line-height: 1.5 !important;
}

/* Descripcion del producto: compacta + mas cerca del bloque de arriba */
body.template-product .product-description,
body.template-product .description-content {
  margin-top: 16px !important;
  padding-top: 16px !important;
  border-top: 1px solid rgba(185,155,99,0.18);
  font-size: 13px !important;
  line-height: 1.6 !important;
  color: rgba(255,255,255,0.75) !important;
}
body.template-product .product-description h2,
body.template-product .product-description h3,
body.template-product .description-content h2,
body.template-product .description-content h3 {
  font-size: 12px !important;
  letter-spacing: 0.3em !important;
  text-transform: uppercase !important;
  color: var(--miami-gold) !important;
  margin-bottom: 10px !important;
  margin-top: 0 !important;
}

/* Productos similares — titulo y grid compacto */
body.template-product .product-related h2,
body.template-product .product-related h3 {
  font-size: 14px !important;
  letter-spacing: 0.3em !important;
  text-transform: uppercase !important;
  color: var(--miami-gold) !important;
  margin: 20px 0 16px !important;
}

@media (min-width: 768px) {
  body.template-product h1,
  body.template-product .product-name {
    font-size: clamp(22px, 2.4vw, 32px) !important;
  }
}

/* ==========================================================================
   PRODUCT LAYOUT 2 COLUMNAS — descripcion pegada a la imagen en desktop
   ========================================================================== */

/* Mobile: stack natural — imagen, descripcion, info */
body.template-product .miami-product-cols {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
body.template-product .miami-product-cols__left,
body.template-product .miami-product-cols__right {
  width: 100%;
}
body.template-product .miami-product-desc-inline {
  margin-top: 8px;
}

/* Desktop: 2 columnas — IZQ imagen+desc, DER info */
@media (min-width: 768px) {
  body.template-product .miami-product-cols {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
    gap: 40px;
    align-items: start;
  }
  body.template-product .miami-product-cols__left,
  body.template-product .miami-product-cols__right {
    width: 100%;
    min-width: 0;
  }
  body.template-product .miami-product-desc-inline {
    margin-top: 28px;
    padding-top: 24px;
    border-top: 1px solid rgba(185,155,99,0.18);
  }
}

/* ==========================================================================
   HEADER — todo negro con dots, paleta unificada
   ========================================================================== */
header,
.header,
.header-wrapper,
.header-main,
.header-top,
.header-bottom,
.navbar,
.site-header,
body > header,
body header {
  background:
    radial-gradient(circle at 50% 50%, rgba(185,155,99,0.08) 1px, transparent 2px) 0 0 / 30px 30px,
    radial-gradient(ellipse 90% 50% at 50% 100%, rgba(185,155,99,0.04), transparent 60%),
    #050505 !important;
  border-bottom: 1px solid rgba(185,155,99,0.18) !important;
  color: #fff !important;
}
header > *,
.header > *,
.navbar > *,
body header > div,
body header > nav {
  background: transparent !important;
}
/* Logo / Tiendanube branded title */
header a.logo,
header .logo,
header .site-title,
header .navbar-brand,
header h1,
header h2 {
  color: #fff !important;
}
/* Search bar */
header input[type="text"],
header input[type="search"],
header .form-control,
header .search-input,
header form input,
.header input[type="text"],
.header input[type="search"] {
  background: rgba(20,18,15,0.55) !important;
  border: 1px solid rgba(185,155,99,0.22) !important;
  color: #fff !important;
}
header input::placeholder,
.header input::placeholder {
  color: rgba(255,255,255,0.45) !important;
}
header button.search-btn,
header .search-btn,
header [class*="search-submit"],
header form button {
  background: rgba(185,155,99,0.18) !important;
  border-color: rgba(185,155,99,0.35) !important;
  color: var(--miami-gold) !important;
}
header button.search-btn:hover,
header .search-btn:hover {
  background: var(--miami-gold) !important;
  color: #000 !important;
}
/* Links de navegacion */
header a,
.header a,
header nav a,
.navbar a {
  color: rgba(255,255,255,0.85) !important;
}
header a:hover,
.header a:hover {
  color: var(--miami-gold) !important;
}
/* "Entra / Registrate", "Carrito" etc */
header .account-link,
header .cart-link,
header [class*="cart"],
header [class*="account"],
header [class*="login"] {
  color: rgba(255,255,255,0.85) !important;
}
header [class*="cart"] svg,
header [class*="account"] svg {
  fill: rgba(255,255,255,0.85) !important;
  color: rgba(255,255,255,0.85) !important;
}
/* Iconos circular bg que aparecen en "Entra" y "Carrito" */
header .rounded-circle,
header .icon-circle,
header [class*="icon-bg"] {
  background: rgba(20,18,15,0.55) !important;
  border: 1px solid rgba(185,155,99,0.2) !important;
  color: var(--miami-gold) !important;
}
header .rounded-circle svg,
header .icon-circle svg {
  fill: var(--miami-gold) !important;
  color: var(--miami-gold) !important;
}
/* Cantidad/precio del carrito */
header .cart-count,
header .cart-total,
header [class*="cart-quantity"] {
  color: rgba(255,255,255,0.7) !important;
}
/* Navigation menu items: CATEGORIAS, INICIO, PRODUCTOS, CONTACTO */
header nav,
header .navigation,
.navbar-nav,
.nav-menu,
[class*="navigation-list"],
[class*="navigation-categories"] {
  background: transparent !important;
}
header nav a,
header .nav-link,
header .navigation a,
.navbar-nav a,
header [class*="navigation"] a {
  color: rgba(255,255,255,0.78) !important;
}
header nav a:hover,
header .nav-link:hover,
header .navigation a:hover {
  color: var(--miami-gold) !important;
}
/* Dropdown de categorias (cuando se abre) */
.navigation-categories-desktop,
.dropdown-menu,
[class*="dropdown-menu"] {
  background: rgba(10,10,10,0.95) !important;
  border: 1px solid rgba(185,155,99,0.2) !important;
  color: #fff !important;
}
.dropdown-menu a,
[class*="dropdown"] a {
  color: rgba(255,255,255,0.8) !important;
}
.dropdown-menu a:hover {
  color: var(--miami-gold) !important;
  background: rgba(185,155,99,0.08) !important;
}
/* Header advertising bar (si esta activa) */
.header-advertising,
[class*="header-advertising"],
[class*="advertising"] {
  background: rgba(15,15,15,0.85) !important;
  color: rgba(255,255,255,0.85) !important;
  border-bottom: 1px solid rgba(185,155,99,0.15) !important;
}

/* ==========================================================================
   CART (carrito) — dark + gold completo, todo legible
   ========================================================================== */
body.template-cart {
  background:
    radial-gradient(circle at 50% 50%, rgba(185,155,99,0.08) 1px, transparent 2px) 0 0 / 30px 30px,
    radial-gradient(circle at 50% 50%, rgba(255,255,255,0.02) 1px, transparent 1.5px) 14px 14px / 30px 30px,
    radial-gradient(ellipse 90% 50% at 50% 0%, rgba(185,155,99,0.06), transparent 60%),
    #060606 !important;
  background-attachment: fixed !important;
  color: #f0eeea !important;
}
body.template-cart .container,
body.template-cart section,
body.template-cart main,
body.template-cart #shoppingCartPage,
body.template-cart .cart-page-content,
body.template-cart .cart-page-products,
body.template-cart .cart-page-summary,
body.template-cart .cart-page-fulfillment,
body.template-cart .js-ajax-cart-list,
body.template-cart .cart-page-table-header,
body.template-cart .row,
body.template-cart [class*="col-"],
body.template-cart .bg-white,
body.template-cart .bg-light {
  background: transparent !important;
}

/* Titulo "Carrito de compras" */
body.template-cart h1,
body.template-cart h2,
body.template-cart h3,
body.template-cart .page-header,
body.template-cart .h1 {
  color: #fff !important;
}

/* Cart items — cada producto en lista */
body.template-cart .cart-item,
body.template-cart .cart-row,
body.template-cart [class*="cart-item-ajax"],
body.template-cart .js-cart-item {
  background: rgba(15,15,15,0.55) !important;
  border-bottom: 1px solid rgba(185,155,99,0.15) !important;
  padding: 16px 12px !important;
  margin-bottom: 8px !important;
  border-radius: 2px;
}

/* Nombre de producto en el cart */
body.template-cart .item-name,
body.template-cart .cart-item .item-name,
body.template-cart .cart-row .product-name,
body.template-cart .product-name,
body.template-cart .js-cart-item-name,
body.template-cart .cart-item a,
body.template-cart a.product-name {
  color: #fff !important;
  font-size: 13px !important;
  font-weight: 500 !important;
  line-height: 1.4 !important;
  text-decoration: none !important;
}
body.template-cart .item-variation,
body.template-cart .cart-item-variant,
body.template-cart .js-cart-item-variant,
body.template-cart .variant-name {
  color: rgba(255,255,255,0.6) !important;
  font-size: 11px !important;
}

/* Precios en el cart */
body.template-cart .item-price,
body.template-cart .cart-item .price,
body.template-cart .cart-row .item-price,
body.template-cart .js-cart-item-price,
body.template-cart .js-price-display,
body.template-cart .price,
body.template-cart .product-price,
body.template-cart .js-item-price {
  color: var(--miami-gold) !important;
  font-size: 14px !important;
  font-weight: 500 !important;
}
body.template-cart .price-compare,
body.template-cart .js-compare-price {
  color: rgba(255,255,255,0.4) !important;
  text-decoration: line-through;
}

/* Cantidad: input + botones */
body.template-cart .form-quantity input,
body.template-cart input[type="number"],
body.template-cart input.js-cart-item-quantity,
body.template-cart .quantity-input {
  background: rgba(20,18,15,0.65) !important;
  border: 1px solid rgba(185,155,99,0.3) !important;
  color: #fff !important;
  padding: 8px !important;
  font-size: 13px !important;
}
body.template-cart .form-quantity-icon,
body.template-cart .js-cart-item-quantity-action,
body.template-cart button.quantity-minus,
body.template-cart button.quantity-plus {
  background: rgba(20,18,15,0.65) !important;
  border-color: rgba(185,155,99,0.3) !important;
  color: var(--miami-gold) !important;
}

/* Boton eliminar item */
body.template-cart .js-cart-item-remove,
body.template-cart .cart-item-remove,
body.template-cart [class*="remove"] {
  color: rgba(255,255,255,0.6) !important;
}
body.template-cart .js-cart-item-remove:hover {
  color: var(--miami-gold) !important;
}

/* Tabla header de cart (Productos / Cantidad / Precio / Subtotal en desktop) */
body.template-cart .cart-page-table-header {
  color: rgba(255,255,255,0.55) !important;
  border-bottom: 1px solid rgba(185,155,99,0.18) !important;
  font-size: 11px !important;
  letter-spacing: 0.18em !important;
  text-transform: uppercase !important;
}

/* Cart summary (totales) */
body.template-cart .cart-summary,
body.template-cart .cart-totals,
body.template-cart .cart-page-summary,
body.template-cart .js-cart-summary {
  background: rgba(15,15,15,0.6) !important;
  border: 1px solid rgba(185,155,99,0.2) !important;
  padding: 24px !important;
  margin-top: 16px;
}
body.template-cart .cart-summary *,
body.template-cart .cart-totals * {
  color: #f0eeea !important;
}
body.template-cart .cart-summary .total,
body.template-cart .cart-summary .subtotal,
body.template-cart .cart-totals .total,
body.template-cart .js-cart-total {
  color: var(--miami-gold) !important;
  font-weight: 500 !important;
}

/* Boton "INICIAR COMPRA" — el del checkout */
body.template-cart .btn-primary,
body.template-cart .cart-button-container .btn,
body.template-cart .cart-button-container .btn-primary,
body.template-cart .js-cart-submit,
body.template-cart button[type="submit"],
body.template-cart .checkout-button {
  background: var(--miami-gold) !important;
  color: #050505 !important;
  border: 1px solid var(--miami-gold) !important;
  font-weight: 600 !important;
  letter-spacing: 0.25em !important;
  text-transform: uppercase !important;
  padding: 16px 28px !important;
  font-size: 13px !important;
  width: 100% !important;
  margin: 16px 0 !important;
  transition: all 0.3s ease;
}
body.template-cart .btn-primary:hover,
body.template-cart .cart-button-container .btn:hover,
body.template-cart button[type="submit"]:hover {
  background: #fff !important;
  color: #000 !important;
  border-color: #fff !important;
}

/* Shipping calculator / cupon code area */
body.template-cart .shipping-calculator-container,
body.template-cart .cart-fulfillment,
body.template-cart .cart-page-fulfillment,
body.template-cart .js-cart-fulfillment {
  background: rgba(15,15,15,0.45) !important;
  border: 1px solid rgba(185,155,99,0.15) !important;
  padding: 20px !important;
  margin-bottom: 16px;
}
body.template-cart .shipping-calculator-container label,
body.template-cart .cart-fulfillment label {
  color: rgba(255,255,255,0.85) !important;
  font-size: 12px !important;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}
body.template-cart .shipping-calculator-container input,
body.template-cart .cart-fulfillment input {
  background: rgba(20,18,15,0.65) !important;
  border: 1px solid rgba(185,155,99,0.3) !important;
  color: #fff !important;
}
body.template-cart .shipping-calculator-container select,
body.template-cart .cart-fulfillment select {
  background: rgba(20,18,15,0.65) !important;
  border: 1px solid rgba(185,155,99,0.3) !important;
  color: #fff !important;
}

/* GoCuotas widget / payment badges */
body.template-cart [class*="gocuotas"],
body.template-cart [class*="installments"],
body.template-cart .payment-method-icon {
  margin: 10px 0 !important;
  opacity: 0.9;
}

/* Carrito vacio */
body.template-cart .alert,
body.template-cart .alert-info {
  background: rgba(20,18,15,0.65) !important;
  border: 1px solid rgba(185,155,99,0.25) !important;
  color: rgba(255,255,255,0.85) !important;
  padding: 32px 24px !important;
}

/* Imagenes de productos en cart: bg oscuro */
body.template-cart .cart-item-image,
body.template-cart .item-image,
body.template-cart .cart-row img {
  background: transparent !important;
  border-radius: 2px;
}

/* Continuar comprando link */
body.template-cart .continue-shopping,
body.template-cart .back-to-shop,
body.template-cart [class*="continue"] {
  color: rgba(255,255,255,0.7) !important;
  font-size: 11px !important;
  letter-spacing: 0.2em !important;
  text-transform: uppercase !important;
}

/* Mobile: ajustes para que cada item se vea como card stacked */
@media (max-width: 768px) {
  body.template-cart .cart-item,
  body.template-cart .cart-row {
    display: grid !important;
    grid-template-columns: 80px 1fr !important;
    gap: 12px !important;
    align-items: start;
  }
  body.template-cart .cart-item-image,
  body.template-cart .cart-row img {
    max-width: 80px !important;
    height: auto !important;
  }
  body.template-cart .item-info,
  body.template-cart .cart-item-info {
    display: flex !important;
    flex-direction: column !important;
    gap: 6px !important;
  }
}

/* ==========================================================================
   CART MODAL (#modal-cart) — el drawer del carrito en CUALQUIER pagina
   ========================================================================== */
#modal-cart,
#modal-cart .modal-content,
#modal-cart .modal-body,
#modal-cart .modal-dialog,
#modal-cart .modal-header,
#modal-cart .modal-footer {
  background: #0a0a0a !important;
  color: #f0eeea !important;
  border-color: rgba(185,155,99,0.2) !important;
}
#modal-cart .modal-content {
  background:
    radial-gradient(circle at 50% 50%, rgba(185,155,99,0.06) 1px, transparent 1.8px) 0 0 / 30px 30px,
    #0a0a0a !important;
  border-left: 1px solid rgba(185,155,99,0.25) !important;
}

/* Header del modal con titulo "Carrito de compras" + boton X */
#modal-cart .modal-header,
#modal-cart .modal-header h1,
#modal-cart .modal-header h2,
#modal-cart .modal-header .modal-title {
  color: #fff !important;
  font-size: 14px !important;
  letter-spacing: 0.18em !important;
  text-transform: uppercase !important;
  font-weight: 500 !important;
  border-bottom: 1px solid rgba(185,155,99,0.18) !important;
  padding: 18px 20px !important;
}
#modal-cart .close,
#modal-cart [data-dismiss="modal"] {
  color: rgba(255,255,255,0.8) !important;
  opacity: 1 !important;
  font-size: 24px;
}
#modal-cart .close:hover {
  color: var(--miami-gold) !important;
}

/* Items del cart en modal */
#modal-cart .cart-item,
#modal-cart .js-cart-item,
#modal-cart .cart-row {
  background: transparent !important;
  border-bottom: 1px solid rgba(185,155,99,0.15) !important;
  padding: 16px 0 !important;
}
#modal-cart .item-name,
#modal-cart .cart-item .item-name,
#modal-cart .product-name,
#modal-cart .js-cart-item-name,
#modal-cart a.product-name {
  color: #fff !important;
  font-size: 13px !important;
  font-weight: 500 !important;
  text-decoration: none !important;
  line-height: 1.4 !important;
}
#modal-cart .item-variation,
#modal-cart .cart-item-variant,
#modal-cart .variant-name,
#modal-cart .js-cart-item-variant {
  color: rgba(255,255,255,0.55) !important;
  font-size: 11px !important;
}

/* Precios en el modal */
#modal-cart .item-price,
#modal-cart .cart-item .price,
#modal-cart .price,
#modal-cart .js-cart-item-price,
#modal-cart .js-price-display,
#modal-cart .js-item-price {
  color: var(--miami-gold) !important;
  font-size: 14px !important;
  font-weight: 500 !important;
}

/* Subtotal / Total en el modal */
#modal-cart .cart-summary,
#modal-cart .cart-totals,
#modal-cart .subtotal-line,
#modal-cart .total-line {
  background: transparent !important;
  border: none !important;
  padding: 8px 0 !important;
}
#modal-cart .cart-summary *,
#modal-cart .cart-totals * {
  color: #f0eeea !important;
}
#modal-cart .js-cart-total,
#modal-cart .total,
#modal-cart [class*="total-amount"] {
  color: var(--miami-gold) !important;
  font-weight: 600 !important;
}
#modal-cart .subtotal-label,
#modal-cart .total-label {
  color: rgba(255,255,255,0.7) !important;
  font-size: 13px !important;
  letter-spacing: 0.08em !important;
}

/* Quantity input/buttons en modal */
#modal-cart input[type="number"],
#modal-cart .form-quantity input,
#modal-cart input.js-cart-item-quantity,
#modal-cart .quantity-input {
  background: rgba(20,18,15,0.65) !important;
  border: 1px solid rgba(185,155,99,0.3) !important;
  color: #fff !important;
}
#modal-cart .form-quantity-icon,
#modal-cart button.quantity-minus,
#modal-cart button.quantity-plus,
#modal-cart .js-cart-item-quantity-action {
  background: transparent !important;
  border: 1px solid rgba(185,155,99,0.3) !important;
  color: var(--miami-gold) !important;
}

/* Eliminar */
#modal-cart .js-cart-item-remove,
#modal-cart .cart-item-remove,
#modal-cart [class*="remove"],
#modal-cart a[class*="eliminar"] {
  color: rgba(255,255,255,0.7) !important;
  font-size: 12px !important;
  letter-spacing: 0.1em !important;
  text-decoration: none !important;
}
#modal-cart .js-cart-item-remove:hover {
  color: var(--miami-gold) !important;
}

/* Boton INICIAR COMPRA en modal — gold completo */
#modal-cart .btn-primary,
#modal-cart .cart-button-container .btn,
#modal-cart .cart-button-container .btn-primary,
#modal-cart .js-cart-submit,
#modal-cart button[type="submit"],
#modal-cart .checkout-button,
#modal-cart a.btn-primary {
  background: var(--miami-gold) !important;
  color: #050505 !important;
  border: 1px solid var(--miami-gold) !important;
  font-weight: 600 !important;
  letter-spacing: 0.25em !important;
  text-transform: uppercase !important;
  padding: 16px 24px !important;
  font-size: 13px !important;
  width: 100% !important;
  margin: 12px 0 !important;
  transition: all 0.3s ease;
  display: block;
  text-align: center;
  text-decoration: none !important;
}
#modal-cart .btn-primary:hover,
#modal-cart button[type="submit"]:hover {
  background: #fff !important;
  color: #000 !important;
  border-color: #fff !important;
}

/* "Ver mas productos" link */
#modal-cart .btn-link,
#modal-cart a.btn-link {
  color: rgba(255,255,255,0.75) !important;
  font-size: 11px !important;
  letter-spacing: 0.2em !important;
  text-transform: uppercase !important;
  text-decoration: underline;
}
#modal-cart a.btn-link:hover {
  color: var(--miami-gold) !important;
}

/* GoCuotas / cuotas badge en modal */
#modal-cart [class*="gocuotas"],
#modal-cart [class*="installments"] {
  background: transparent !important;
  color: rgba(255,255,255,0.75) !important;
  padding: 12px 0 !important;
}

/* Bordes y separadores horizontales en modal */
#modal-cart hr,
#modal-cart .divider,
#modal-cart .border-top,
#modal-cart .border-bottom {
  border-color: rgba(185,155,99,0.18) !important;
}

/* Backdrop del modal mas oscuro */
.modal-backdrop {
  background: rgba(0,0,0,0.85) !important;
}

/* Imagenes de items en modal: contenedor transparente */
#modal-cart .cart-item-image,
#modal-cart .item-image,
#modal-cart .cart-row img {
  background: transparent !important;
}

/* ==========================================================================
   FOOTER — todo negro con dots dorados, igual que el resto del sitio
   ========================================================================== */
footer,
.footer,
.footer-main,
.footer-bottom,
.footer-extra,
.miami-footer-extra,
body footer,
body .footer {
  background:
    radial-gradient(circle at 50% 50%, rgba(185,155,99,0.08) 1px, transparent 2px) 0 0 / 30px 30px,
    radial-gradient(circle at 50% 50%, rgba(255,255,255,0.02) 1px, transparent 1.5px) 14px 14px / 30px 30px,
    radial-gradient(ellipse 90% 40% at 50% 0%, rgba(185,155,99,0.05), transparent 60%),
    #050505 !important;
  color: #f0eeea !important;
  border-top: 1px solid rgba(185,155,99,0.18) !important;
}
footer > *,
.footer > *,
.miami-footer-extra > * {
  background: transparent !important;
}
footer a,
.footer a,
.miami-footer-extra a {
  color: rgba(255,255,255,0.85) !important;
}
footer a:hover,
.footer a:hover,
.miami-footer-extra a:hover {
  color: var(--miami-gold) !important;
}
footer input,
footer textarea,
footer select,
.footer input,
.footer textarea,
.footer select {
  background: rgba(20,18,15,0.55) !important;
  border-color: rgba(185,155,99,0.25) !important;
  color: #fff !important;
}
footer h1, footer h2, footer h3, footer h4, footer h5, footer h6,
.footer h1, .footer h2, .footer h3, .footer h4, .footer h5, .footer h6 {
  color: #fff !important;
}

/* ==========================================================================
   PRODUCT SLIDER MULTI-IMAGEN — fondo siempre negro en slider + thumbs
   ========================================================================== */
body.template-product .product-images-slider,
body.template-product .product-images-thumbs,
body.template-product .js-swiper-product,
body.template-product .js-swiper-product-thumbs,
body.template-product .swiper-container,
body.template-product .swiper-wrapper,
body.template-product .swiper-slide,
body.template-product .slider-slide,
body.template-product .js-product-slide,
body.template-product .js-product-slide-link,
body.template-product .product-thumb-container,
body.template-product .product-slider-image,
body.template-product .swiper-button-prev,
body.template-product .swiper-button-next,
body.template-product .swiper-fractions,
body.template-product .swiper-pagination {
  background: transparent !important;
}

/* Wrapper general del area de imagenes del producto en negro */
body.template-product .product-images {
  background: transparent !important;
}

/* Las flechas y paginacion del swiper en blanco para verlas sobre negro */
body.template-product .swiper-button-prev,
body.template-product .swiper-button-next {
  color: rgba(255,255,255,0.85) !important;
}
body.template-product .swiper-button-prev:hover,
body.template-product .swiper-button-next:hover {
  color: var(--miami-gold) !important;
}
body.template-product .swiper-fractions {
  color: rgba(255,255,255,0.75) !important;
}

/* Thumbs: borde sutil dorado al activo */
body.template-product .product-thumb-container {
  border: 1px solid rgba(185,155,99,0.12);
  transition: border-color 0.3s ease;
}
body.template-product .product-thumb-container:hover {
  border-color: rgba(185,155,99,0.5);
}
body.template-product .product-thumb-container.swiper-slide-thumb-active,
body.template-product .product-thumb-container.is-active {
  border-color: var(--miami-gold) !important;
}

/* ==========================================================================
   PAGE HEADER (CATEGORY / PRODUCT / SEARCH) — logo dorado + halo + texturas
   ========================================================================== */
.miami-page-header {
  position: relative;
  width: 100%;
  padding: 56px 24px 32px;
  text-align: center;
  background:
    radial-gradient(ellipse 50% 100% at 50% 0%, rgba(185,155,99,0.18) 0%, transparent 65%),
    radial-gradient(circle at 50% 50%, rgba(185,155,99,0.06) 1px, transparent 1.8px) 0 0 / 30px 30px,
    #060606;
  border-bottom: 1px solid rgba(185,155,99,0.18);
  z-index: 1;
}
.miami-page-header::before {
  content: ""; position: absolute; inset: 0; z-index: 0;
  background:
    radial-gradient(ellipse 80% 60% at 50% 100%, rgba(0,0,0,0.55) 0%, transparent 70%);
  pointer-events: none;
}
.miami-page-header__logo {
  position: relative; z-index: 1;
  display: inline-block;
  width: auto;
  max-width: 180px;
  height: auto;
  filter:
    drop-shadow(0 6px 18px rgba(0,0,0,0.55))
    drop-shadow(0 0 28px rgba(185,155,99,0.28));
  animation: miami-page-logo-breathe 6s ease-in-out infinite;
}
@keyframes miami-page-logo-breathe {
  0%, 100% {
    filter:
      drop-shadow(0 6px 18px rgba(0,0,0,0.55))
      drop-shadow(0 0 28px rgba(185,155,99,0.22));
  }
  50% {
    filter:
      drop-shadow(0 8px 22px rgba(0,0,0,0.6))
      drop-shadow(0 0 38px rgba(185,155,99,0.4));
  }
}
@media (max-width: 768px) {
  .miami-page-header {
    padding: 36px 16px 22px;
  }
  .miami-page-header__logo { max-width: 130px; }
}
@media (prefers-reduced-motion: reduce) {
  .miami-page-header__logo { animation: none; }
}

/* ==========================================================================
   CATEGORY / SEARCH — Cards con halo dorado, imagen 100% estatica
   Mismo patron que .miami-section--products-dark, pero aplicado al grid de
   category/search. NO toca individual product detail.
   ========================================================================== */
body.template-category .item-product,
body.template-search .item-product,
body.template-category .js-item-product,
body.template-search .js-item-product {
  background: rgba(15,15,15,0.65) !important;
  border: 1px solid rgba(185,155,99,0.1) !important;
  padding: 14px 14px 18px !important;
  transition:
    border-color 0.45s var(--miami-ease, ease),
    box-shadow 0.45s var(--miami-ease, ease) !important;
}
body.template-category .item-product:hover,
body.template-search .item-product:hover,
body.template-category .js-item-product:hover,
body.template-search .js-item-product:hover {
  border-color: var(--miami-gold) !important;
  box-shadow:
    0 0 0 2px var(--miami-gold),
    0 0 32px rgba(185,155,99,0.45),
    0 0 64px rgba(185,155,99,0.2) !important;
}

/* IMAGEN 100% ESTATICA en catalogo — preserva translateX(-50%) original
   y descarta el scale(1.04) del theme base que rompia el centrado. */
body.template-category .product-item:hover .product-item-image-container img,
body.template-search .product-item:hover .product-item-image-container img,
body.template-category .item-product:hover .product-item-image-container img,
body.template-search .item-product:hover .product-item-image-container img {
  transform: translateX(-50%) !important;
  transition: none !important;
}

/* Quitar outline default del browser al focus en links de catalogo */
body.template-category .item-product a:focus,
body.template-search .item-product a:focus,
body.template-category a:focus,
body.template-search a:focus {
  outline: none !important;
}

/* === LOOKBOOK CINEMATIC — Ken Burns + grain + vignette + glassmorphism === */
.miami-lookbook__tile--cinematic {
  min-height: 560px;
  isolation: isolate;
  background: #050505;
}
.miami-lookbook__tile--cinematic .miami-lookbook__media {
  position: absolute; inset: 0; z-index: 0;
  overflow: hidden;
}
.miami-lookbook__tile--cinematic .miami-lookbook__img {
  position: absolute; inset: -6%;
  width: 112%; height: 112%;
  object-fit: cover;
  filter: brightness(0.78) saturate(0.92) contrast(1.05);
  transition: filter 1.2s var(--miami-ease);
  transform-origin: 45% 55%;
  animation: miami-kenburns 28s ease-in-out infinite alternate;
  will-change: transform, filter;
}
@keyframes miami-kenburns {
  0% {
    transform: scale(1.04) translate(0, 0);
  }
  50% {
    transform: scale(1.10) translate(-1.2%, -1%);
  }
  100% {
    transform: scale(1.07) translate(0.8%, 0.6%);
  }
}
.miami-lookbook__tile--cinematic:hover .miami-lookbook__img {
  filter: brightness(0.84) saturate(0.98) contrast(1.05);
  transform: scale(1.12);
}

/* Capa de halo cálido (sol dorado filtrandose desde la izquierda) */
.miami-lookbook__haze {
  position: absolute; inset: 0; z-index: 1;
  pointer-events: none;
  background:
    radial-gradient(ellipse 60% 40% at 18% 30%, rgba(232,189,116,0.18) 0%, transparent 55%),
    radial-gradient(ellipse 50% 45% at 80% 70%, rgba(40,30,18,0.35) 0%, transparent 65%);
  mix-blend-mode: screen;
  opacity: 0.85;
  animation: miami-haze-breathe 14s ease-in-out infinite alternate;
}
@keyframes miami-haze-breathe {
  0%   { opacity: 0.7; transform: translateX(0); }
  100% { opacity: 0.95; transform: translateX(1%); }
}

/* Film grain animado (SVG noise como bg, scroll continuo casi imperceptible) */
.miami-lookbook__grain {
  position: absolute; inset: -10%; z-index: 2;
  pointer-events: none;
  opacity: 0.18;
  mix-blend-mode: overlay;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='220' height='220'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='0.92' numOctaves='2' stitchTiles='stitch'/><feColorMatrix values='0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.55 0'/></filter><rect width='100%25' height='100%25' filter='url(%23n)'/></svg>");
  background-size: 220px 220px;
  animation: miami-grain-shift 1.6s steps(4) infinite;
}
@keyframes miami-grain-shift {
  0%   { transform: translate(0, 0); }
  25%  { transform: translate(-3%, 2%); }
  50%  { transform: translate(2%, -3%); }
  75%  { transform: translate(-2%, -2%); }
  100% { transform: translate(0, 0); }
}

/* Vignette premium — bordes oscuros con falloff suave */
.miami-lookbook__vignette {
  position: absolute; inset: 0; z-index: 3;
  pointer-events: none;
  background:
    radial-gradient(ellipse at center, transparent 38%, rgba(0,0,0,0.55) 100%),
    linear-gradient(180deg, rgba(0,0,0,0.35) 0%, transparent 30%, transparent 65%, rgba(0,0,0,0.78) 100%);
}

/* Overlay del contenido (textos) — z-index sobre los efectos */
.miami-lookbook__tile--cinematic .miami-lookbook__overlay {
  z-index: 4;
}

/* Reveal staggered cinematográfico — entran desde abajo con fade */
.miami-lookbook__tile--cinematic [data-cinematic-reveal] {
  opacity: 0;
  transform: translateY(18px);
  transition:
    opacity 1.1s cubic-bezier(0.22, 0.61, 0.36, 1),
    transform 1.1s cubic-bezier(0.22, 0.61, 0.36, 1);
}
.miami-lookbook__tile--cinematic.is-revealed [data-cinematic-reveal] {
  opacity: 1;
  transform: translateY(0);
}
.miami-lookbook__tile--cinematic.is-revealed [data-cinematic-reveal]:nth-child(1) { transition-delay: 0.1s; }
.miami-lookbook__tile--cinematic.is-revealed [data-cinematic-reveal]:nth-child(2) { transition-delay: 0.28s; }
.miami-lookbook__tile--cinematic.is-revealed [data-cinematic-reveal]:nth-child(3) { transition-delay: 0.48s; }
.miami-lookbook__tile--cinematic.is-revealed [data-cinematic-reveal]:nth-child(4) { transition-delay: 0.72s; }

/* Tipografía mejorada del cinematic tile */
.miami-lookbook__tile--cinematic .miami-lookbook__no {
  letter-spacing: 0.6em;
  color: rgba(232,189,116,0.85);
  text-shadow: 0 2px 12px rgba(0,0,0,0.6);
  font-weight: 400;
}
.miami-lookbook__tile--cinematic .miami-lookbook__title {
  font-weight: 300;
  letter-spacing: 0.08em;
  text-shadow:
    0 4px 24px rgba(0,0,0,0.75),
    0 1px 0 rgba(0,0,0,0.4);
}
.miami-lookbook__tile--cinematic .miami-lookbook__sub {
  opacity: 0.78;
  letter-spacing: 0.42em;
  text-shadow: 0 2px 10px rgba(0,0,0,0.55);
}

/* Glassmorphism CTA — vidrio translúcido con borde dorado */
.miami-lookbook__cta--glass {
  display: inline-flex !important;
  align-items: center;
  gap: 14px;
  padding: 16px 32px;
  background: rgba(20,18,16,0.42);
  backdrop-filter: blur(12px) saturate(1.1);
  -webkit-backdrop-filter: blur(12px) saturate(1.1);
  border: 1px solid rgba(232,189,116,0.35);
  color: rgba(255,255,255,0.95) !important;
  letter-spacing: 0.4em;
  font-size: 11px;
  font-weight: 500;
  position: relative;
  overflow: hidden;
  transition:
    border-color 0.6s var(--miami-ease),
    background 0.6s var(--miami-ease),
    transform 0.6s var(--miami-ease),
    box-shadow 0.6s var(--miami-ease);
}
.miami-lookbook__cta--glass::before {
  content: ""; position: absolute; inset: 0;
  background: linear-gradient(120deg, transparent 30%, rgba(232,189,116,0.22) 50%, transparent 70%);
  transform: translateX(-110%);
  transition: transform 0.9s cubic-bezier(0.22, 0.61, 0.36, 1);
  pointer-events: none;
}
.miami-lookbook__cta--glass .miami-lookbook__cta-arrow {
  transition: transform 0.5s var(--miami-ease);
  display: inline-block;
}
.miami-lookbook__tile--cinematic:hover .miami-lookbook__cta--glass {
  background: rgba(30,26,20,0.55);
  border-color: rgba(232,189,116,0.7);
  box-shadow:
    0 0 0 1px rgba(232,189,116,0.25),
    0 0 28px rgba(232,189,116,0.22),
    0 12px 30px rgba(0,0,0,0.45);
  transform: translateY(-2px);
}
.miami-lookbook__tile--cinematic:hover .miami-lookbook__cta--glass::before {
  transform: translateX(110%);
}
.miami-lookbook__tile--cinematic:hover .miami-lookbook__cta-arrow {
  transform: translateX(6px);
}

/* Mobile: bajar densidad del grain + simplificar haze */
@media (max-width: 768px) {
  .miami-lookbook__tile--cinematic { min-height: 500px; }
  .miami-lookbook__grain { opacity: 0.12; animation-duration: 2.4s; }
  .miami-lookbook__haze { opacity: 0.65; }
}

/* Reduced motion: cortamos Ken Burns y grain */
@media (prefers-reduced-motion: reduce) {
  .miami-lookbook__tile--cinematic .miami-lookbook__img { animation: none; transform: scale(1.04); }
  .miami-lookbook__grain { animation: none; }
  .miami-lookbook__haze { animation: none; }
  .miami-lookbook__tile--cinematic [data-cinematic-reveal] { transition: none; opacity: 1; transform: none; }
}

/* === SPLIT SEAL — logo dorado dentro del panel content del split === */
.miami-split__seal {
  max-width: 110px;
  width: 100%;
  height: auto;
  margin: 0 auto 22px;
  display: block;
  flex-shrink: 0;
}
@media (max-width: 900px) {
  .miami-split__seal { max-width: 90px; margin-bottom: 18px; }
}

/* === SPLIT DARK — paleta negra/dorada en split de dossier === */
.miami-split--dark {
  background: #000 !important;
  border-top: 1px solid rgba(185,155,99,0.12);
  border-bottom: 1px solid rgba(185,155,99,0.12);
}
.miami-split--dark .miami-split__media--clean {
  background: #000;
}
.miami-split__content--dark {
  background: #000 !important;
  color: #fff;
  padding: 80px 48px !important;
}
.miami-split__content--dark .miami-eyebrow {
  color: var(--miami-gold) !important;
}
.miami-split__content--dark .miami-split__quote {
  color: #fff;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}
.miami-split__content--dark .miami-split__copy {
  color: rgba(255,255,255,0.72) !important;
}
@media (max-width: 900px) {
  .miami-split__content--dark { padding: 56px 28px !important; }
}

/* === SECTION SEAL — logo dorado al costado izquierdo del texto === */
.miami-section__seal {
  display: block;
  width: auto;
  max-width: 180px;
  height: auto;
  flex-shrink: 0;
  opacity: 0.95;
  filter:
    drop-shadow(0 6px 16px rgba(0,0,0,0.5))
    drop-shadow(0 0 22px rgba(185,155,99,0.22));
}
.miami-section__head--seal {
  flex-direction: row !important;
  align-items: center;
  justify-content: center;
  gap: 36px;
  text-align: left;
  flex-wrap: wrap;
}
.miami-section__head--seal .miami-section__head-text {
  text-align: left;
}
.miami-section__head--seal .miami-section__link {
  margin-top: 0;
  align-self: center;
  margin-left: 18px;
}
@media (max-width: 768px) {
  .miami-section__head--seal {
    gap: 20px;
    justify-content: flex-start;
  }
  .miami-section__seal { max-width: 130px; }
  .miami-section__head--seal .miami-section__head-text { flex: 1; min-width: 0; }
  .miami-section__head--seal .miami-section__link {
    flex-basis: 100%;
    margin-left: 0;
    margin-top: 12px;
    text-align: center;
  }
}

/* === PRODUCTOS DESTACADOS DARK — paleta unificada negro + aura dorada === */
.miami-section--products-dark {
  background:
    radial-gradient(circle at 50% 50%, rgba(185,155,99,0.075) 1px, transparent 2px) 0 0 / 32px 32px,
    radial-gradient(circle at 50% 50%, rgba(255,255,255,0.02) 1px, transparent 1.5px) 16px 16px / 32px 32px,
    radial-gradient(ellipse 85% 50% at 50% 100%, rgba(185,155,99,0.06), transparent 65%),
    #050505 !important;
  color: #fff;
  border-top: 1px solid rgba(185,155,99,0.12);
}
.miami-section--products-dark .miami-section__title,
.miami-section--products-dark .miami-section__sub,
.miami-section--products-dark .miami-section__link {
  color: #fff;
}
.miami-section--products-dark .miami-eyebrow {
  color: var(--miami-gold);
}
.miami-section--products-dark .miami-section__sub {
  color: rgba(255,255,255,0.6);
}

/* Cards: fondo oscuro + borde sutil dorado, aura al hover */
.miami-section--products-dark .miami-products-grid > .js-item-product,
.miami-section--products-dark .miami-products-grid > .item-product,
.miami-section--products-dark .miami-products-grid > .js-product-container {
  background: #0a0a0a;
  border: 1px solid rgba(185,155,99,0.08);
  padding: 14px 14px 18px;
  border-radius: 2px;
  position: relative;
  transition:
    border-color 0.45s var(--miami-ease),
    box-shadow 0.45s var(--miami-ease),
    transform 0.45s var(--miami-ease);
}
/* IMAGEN ESTATICA — fix preciso del bug del hover en cards.
   Causa raiz: la clase .img-absolute-centered solo aplica
       transform: translateX(-50%);
   (centrado horizontal). Cuando el theme aplica
       .product-item:hover img { transform: scale(1.04); }
   REEMPLAZA el translateX(-50%) y la imagen se desplaza 50% a la derecha
   (queda con su esquina izq en left:50% sin compensar).

   Fix: en products-dark, sobreescribimos el transform del hover para
   preservar el translateX(-50%) original y descartar el scale. La imagen
   queda 100% quieta. */
.miami-section--products-dark .miami-products-grid .product-item:hover .product-item-image-container img,
.miami-section--products-dark .miami-products-grid .item-product:hover .product-item-image-container img,
.miami-section--products-dark .miami-products-grid .js-item-product:hover .product-item-image-container img {
  transform: translateX(-50%) !important;
  transition: none !important;
}

/* Info section abajo del card (donde van nombre/precio): forzamos bg oscuro
   para que no quede la franja blanca default de Tiendanube. */
.miami-section--products-dark .miami-products-grid .item-product-info,
.miami-section--products-dark .miami-products-grid .product-item-info,
.miami-section--products-dark .miami-products-grid .item-info,
.miami-section--products-dark .miami-products-grid .information,
.miami-section--products-dark .miami-products-grid .item-product > div,
.miami-section--products-dark .miami-products-grid .js-item-product > div {
  background: transparent !important;
}

/* HOVER / TAP en mobile: aura dorada alrededor del card.
   No tocamos la imagen, solo el card. */
.miami-section--products-dark .miami-products-grid > .js-item-product:hover,
.miami-section--products-dark .miami-products-grid > .item-product:hover,
.miami-section--products-dark .miami-products-grid > .js-product-container:hover {
  border-color: var(--miami-gold) !important;
  box-shadow:
    0 0 0 2px var(--miami-gold),
    0 0 32px rgba(185,155,99,0.45),
    0 0 64px rgba(185,155,99,0.2) !important;
}
/* Sin outline default del browser en los <a> al focus */
.miami-section--products-dark .miami-products-grid a:focus,
.miami-section--products-dark .miami-products-grid a:active {
  outline: none !important;
}

/* Tipografía interna sobre fondo oscuro */
.miami-section--products-dark .item-name,
.miami-section--products-dark .js-item-name,
.miami-section--products-dark .item-product-name,
.miami-section--products-dark a.item-link {
  color: #fff !important;
}
.miami-section--products-dark .item-price,
.miami-section--products-dark .js-price-display,
.miami-section--products-dark .js-item-price,
.miami-section--products-dark .price {
  color: var(--miami-gold) !important;
}
.miami-section--products-dark .price-compare,
.miami-section--products-dark .js-compare-price {
  color: rgba(255,255,255,0.4) !important;
}
.miami-section--products-dark .custom-installments,
.miami-section--products-dark .product-item-installments {
  color: rgba(255,255,255,0.55) !important;
}
.miami-section--products-dark .item-product-name a {
  color: inherit !important;
}

/* Fondo del slot de imagen del producto: que no quede una franja blanca
   detras del PNG/JPG si la imagen no llena el contenedor */
.miami-section--products-dark .item-image,
.miami-section--products-dark .js-item-image,
.miami-section--products-dark .item-image-wrapper {
  background: #0a0a0a !important;
}

/* === TRUST STRIP DARK — paleta unificada negro + dorado === */
.miami-trust {
  background: #000 !important;
  border-top: 1px solid rgba(185,155,99,0.15) !important;
  border-bottom: 1px solid rgba(185,155,99,0.15) !important;
  padding: 44px 16px !important;
  position: relative;
}
.miami-trust::before,
.miami-trust::after {
  content: ""; position: absolute; left: 0; right: 0; height: 80px;
  pointer-events: none; z-index: 0;
}
.miami-trust::before {
  top: 0;
  background: linear-gradient(180deg, #000 0%, transparent 100%);
}
.miami-trust::after {
  bottom: 0;
  background: linear-gradient(0deg, #000 0%, transparent 100%);
}
.miami-trust__grid {
  position: relative; z-index: 1;
}
.miami-trust__item {
  color: rgba(255,255,255,0.85) !important;
}
.miami-trust__item strong {
  color: var(--miami-gold) !important;
}
.miami-trust__item span {
  color: rgba(255,255,255,0.55) !important;
}

/* === HERO BANNER — foto full-bleed con texto overlay sobre la derecha === */
.miami-hero-banner {
  position: relative;
  width: 100%;
  background: #000;
  overflow: hidden;
  min-height: 540px;
  aspect-ratio: 21 / 9;
  max-height: 80vh;
  display: block;
}
.miami-hero-banner__img {
  position: absolute; inset: 0;
  width: 100%; height: 100%;
  object-fit: cover;
  z-index: 0;
  display: block;
}
.miami-hero-banner__overlay {
  position: absolute; inset: 0; z-index: 1;
  pointer-events: none;
  background:
    linear-gradient(90deg, transparent 0%, transparent 45%, rgba(0,0,0,0.55) 75%, rgba(0,0,0,0.78) 100%);
}
.miami-hero-banner__content {
  position: absolute;
  top: 50%; right: 6%;
  transform: translateY(-50%);
  z-index: 2;
  max-width: 460px;
  color: #fff;
  text-align: left;
}
.miami-hero-banner__content .miami-eyebrow {
  color: var(--miami-gold);
  margin-bottom: 18px;
  display: block;
}
.miami-hero-banner__title {
  font-size: clamp(28px, 3.4vw, 48px);
  font-weight: 500;
  letter-spacing: 0.02em;
  line-height: 1.08;
  margin: 0 0 22px;
  color: #fff;
}
.miami-hero-banner__copy {
  font-size: 15px;
  line-height: 1.75;
  color: rgba(255,255,255,0.78);
  margin: 0 0 32px;
}
.miami-btn--gold {
  display: inline-block;
  border: 1px solid var(--miami-gold);
  color: var(--miami-gold);
  padding: 16px 36px;
  font-size: 11px;
  letter-spacing: 0.35em;
  text-transform: uppercase;
  text-decoration: none;
  transition: all 0.3s var(--miami-ease);
}
.miami-btn--gold:hover {
  background: var(--miami-gold);
  color: #000;
}
@media (max-width: 768px) {
  .miami-hero-banner {
    aspect-ratio: 4 / 5;
    min-height: 460px;
    max-height: 85vh;
  }
  .miami-hero-banner__img {
    object-position: 30% center; /* anchor al buzo (lado izq de la foto) */
  }
  .miami-hero-banner__overlay {
    background:
      linear-gradient(180deg, transparent 0%, transparent 50%, rgba(0,0,0,0.6) 72%, rgba(0,0,0,0.94) 100%);
  }
  .miami-hero-banner__content {
    top: auto; bottom: 4%;
    right: 5%; left: 5%;
    transform: none;
    max-width: 100%;
    text-align: left;
  }
  .miami-hero-banner__content .miami-eyebrow {
    font-size: 9px;
    letter-spacing: 0.4em;
    margin-bottom: 10px;
  }
  .miami-hero-banner__title {
    font-size: clamp(20px, 5.5vw, 28px);
    margin-bottom: 12px;
    line-height: 1.05;
  }
  .miami-hero-banner__copy {
    font-size: 12px;
    line-height: 1.55;
    margin-bottom: 18px;
  }
  .miami-btn--gold {
    padding: 13px 24px;
    font-size: 9px;
    letter-spacing: 0.28em;
  }
}

/* === HERO LOGO — escudo dorado MIAMI IMPORT con protagonismo === */
.miami-hero__logo-wrap {
  display: flex;
  justify-content: center;
  align-items: center;
  margin-bottom: 36px;
  position: relative;
}
.miami-hero__logo-wrap::before {
  content: "";
  position: absolute;
  width: 70%;
  max-width: 560px;
  aspect-ratio: 2 / 1;
  background: radial-gradient(ellipse at center, rgba(185,155,99,0.22) 0%, rgba(185,155,99,0.06) 40%, transparent 70%);
  pointer-events: none;
  z-index: 0;
  filter: blur(6px);
}
.miami-hero__logo {
  position: relative;
  z-index: 1;
  width: 100%;
  max-width: 520px;
  height: auto;
  display: block;
  filter:
    drop-shadow(0 12px 28px rgba(0,0,0,0.55))
    drop-shadow(0 0 24px rgba(185,155,99,0.18));
  animation: miami-logo-breathe 6s ease-in-out infinite;
}
@keyframes miami-logo-breathe {
  0%, 100% {
    filter:
      drop-shadow(0 12px 28px rgba(0,0,0,0.55))
      drop-shadow(0 0 24px rgba(185,155,99,0.18));
  }
  50% {
    filter:
      drop-shadow(0 14px 32px rgba(0,0,0,0.6))
      drop-shadow(0 0 38px rgba(185,155,99,0.32));
  }
}
.miami-hero__title--with-logo {
  font-size: clamp(28px, 5.8vw, 78px) !important;
  margin-top: 8px;
}
@media (max-width: 720px) {
  .miami-hero { align-items: flex-start !important; }
  .miami-hero__inner { padding-top: 56px !important; }
  .miami-hero__logo {
    max-width: 280px;
  }
  .miami-hero__logo-wrap {
    margin-bottom: 24px;
  }
  .miami-hero__title--with-logo {
    font-size: clamp(26px, 8.4vw, 52px) !important;
  }
}
@media (prefers-reduced-motion: reduce) {
  .miami-hero__logo { animation: none; }
}

/* === BRAND GRID FLOAT — imagenes sin fondo sobre negro + aura dorada === */
.miami-section--brands-float {
  background:
    radial-gradient(circle at 50% 50%, rgba(185,155,99,0.06) 1px, transparent 1.8px) 0 0 / 36px 36px,
    radial-gradient(ellipse 80% 50% at 50% 0%, rgba(185,155,99,0.05), transparent 60%),
    #060606 !important;
  color: #fff;
  border-top: 1px solid rgba(255,255,255,0.06);
}
.miami-section--brands-float .miami-section__title,
.miami-section--brands-float .miami-section__sub,
.miami-section--brands-float .miami-section__link {
  color: #fff;
}
.miami-section--brands-float .miami-eyebrow {
  color: rgba(255,255,255,0.55);
}
.miami-brand-grid--float {
  background: #000;
  gap: 1px;
}
.miami-brand-tile--float {
  background:
    radial-gradient(ellipse at 50% 50%, rgba(185,155,99,0.04) 0%, transparent 60%),
    #000;
  overflow: hidden;
  transition: background 0.6s var(--miami-ease);
}
.miami-brand-tile--float::before {
  content: ""; position: absolute; inset: 0; pointer-events: none; z-index: 0;
  background-image:
    repeating-linear-gradient(0deg, rgba(255,255,255,0.018) 0 1px, transparent 1px 64px),
    repeating-linear-gradient(90deg, rgba(255,255,255,0.018) 0 1px, transparent 1px 64px);
  opacity: 0.6;
  transition: opacity 0.6s var(--miami-ease);
}
.miami-brand-tile--float .miami-brand-tile__img {
  position: absolute;
  top: 8%; left: 8%;
  width: 84%; height: 68%;
  object-fit: contain;
  margin: 0;
  z-index: 1;
  filter: drop-shadow(0 18px 28px rgba(0,0,0,0.55));
  transition:
    transform 0.7s var(--miami-ease),
    filter 0.7s var(--miami-ease);
}
.miami-brand-tile--float:hover .miami-brand-tile__img {
  transform: scale(1.07) translateY(-4px);
  filter:
    drop-shadow(0 0 22px rgba(185,155,99,0.55))
    drop-shadow(0 0 48px rgba(185,155,99,0.35))
    drop-shadow(0 22px 32px rgba(0,0,0,0.6));
}
.miami-brand-tile--float:hover {
  background:
    radial-gradient(ellipse at 50% 45%, rgba(185,155,99,0.18) 0%, rgba(185,155,99,0.04) 38%, transparent 70%),
    #050505;
}
.miami-brand-tile--float:hover::before { opacity: 0.25; }
.miami-brand-tile--float .miami-brand-tile__name,
.miami-brand-tile--float .miami-brand-tile__no,
.miami-brand-tile--float .miami-brand-tile__cta {
  position: relative; z-index: 3;
}
.miami-brand-tile--float .miami-brand-tile__name {
  text-shadow: 0 2px 12px rgba(0,0,0,0.85);
}
@media (max-width: 640px) {
  .miami-brand-tile--float .miami-brand-tile__img {
    top: 7%; left: 6%;
    width: 88%; height: 66%;
  }
}

</style>
