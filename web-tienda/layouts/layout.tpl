<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:fb="http://www.facebook.com/2008/fbml" xmlns:og="http://opengraphprotocol.org/schema/" lang="{% for language in languages %}{% if language.active %}{{ language.lang }}{% endif %}{% endfor %}">
	<head>

		{{ component('head-tags') }}

		<link rel="preconnect" href="https://fonts.googleapis.com" />
		<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
		{# MIAMI_IMPORT — preconnect/dns-prefetch a CDNs para ganar 100-300ms #}
		<link rel="preconnect" href="https://cdn.jsdelivr.net" crossorigin />
		<link rel="preconnect" href="https://dcdn-us.mitiendanube.com" crossorigin />
		<link rel="dns-prefetch" href="https://bot-miami.onrender.com" />
		{# Preload del logo (visible en preloader + hero + sellos) — entra primero #}
		<link rel="preload" as="image" href="{{ 'images/miami-logo-v4.webp' | static_url }}" type="image/webp" fetchpriority="high" />

		{# MIAMI_IMPORT — Preloader inline (CSS en head, HTML/JS al inicio del body)
		   Critico que el CSS este en head para que el preloader se vea ANTES de que
		   cualquier otro estilo cargue. Sin esto el usuario ve un flash de contenido
		   sin estilizar. #}
		<style>
			#miami-preloader {
				position: fixed; inset: 0; z-index: 99999;
				background: #FBFBFA;
				display: flex; flex-direction: column;
				align-items: center; justify-content: center;
				opacity: 1; visibility: visible;
				transition: opacity 0.55s cubic-bezier(0.22,0.61,0.36,1),
				            visibility 0.55s cubic-bezier(0.22,0.61,0.36,1);
			}
			#miami-preloader.is-hidden {
				opacity: 0; visibility: hidden; pointer-events: none;
			}
			#miami-preloader::before {
				content: ""; position: absolute; inset: 0; z-index: 0;
				background:
					radial-gradient(ellipse 60% 40% at 50% 30%, rgba(21,22,26,0.18) 0%, transparent 60%),
					radial-gradient(circle at 50% 50%, rgba(21,22,26,0.06) 1px, transparent 1.8px) 0 0 / 30px 30px;
				pointer-events: none;
			}
			.miami-preloader__logo {
				position: relative; z-index: 1;
				width: 180px; max-width: 58vw;
				height: auto; display: block;
				filter:
					drop-shadow(0 4px 16px rgba(0,0,0,0.5))
					drop-shadow(0 0 22px rgba(21,22,26,0.3));
				animation: miami-preloader-pulse 1.8s ease-in-out infinite;
			}
			@keyframes miami-preloader-pulse {
				0%, 100% { opacity: 0.88; transform: scale(1); }
				50%      { opacity: 1;    transform: scale(1.04); }
			}
			.miami-preloader__bar {
				position: relative; z-index: 1;
				margin-top: 28px;
				width: 160px; height: 1px;
				background: rgba(255,255,255,0.08);
				overflow: hidden;
			}
			.miami-preloader__bar > i {
				position: absolute; top: 0; bottom: 0; left: 0; width: 50%;
				background: linear-gradient(90deg,
					transparent 0%,
					rgba(21,22,26,0.4) 30%,
					#d4bb88 50%,
					rgba(21,22,26,0.4) 70%,
					transparent 100%);
				animation: miami-preloader-bar 1.5s ease-in-out infinite;
			}
			@keyframes miami-preloader-bar {
				0%   { transform: translateX(-100%); }
				100% { transform: translateX(300%); }
			}
			body.is-preloading { overflow: hidden; }
			@media (prefers-reduced-motion: reduce) {
				.miami-preloader__logo { animation: none; }
				.miami-preloader__bar > i { animation: none; transform: translateX(100%); }
			}
		</style>
		
		{# Preload LCP home, category and product page elements #}

		{% snipplet 'preload-images.tpl' %}

		<link rel="preload" as="style" href="{{ [settings.font_headings, settings.font_rest] | google_fonts_url('400,700') }}" />
		<link rel="preload" href="{{ 'css/style-critical.scss' | static_url }}" as="style" />
		<link rel="preload" href="{{ 'css/style-utilities.scss' | static_url }}" as="style" />
		<link rel="preload" href="{{ 'js/external-no-dependencies.js.tpl' | static_url }}" as="script" />

		{#/*============================================================================
			#CSS and fonts
		==============================================================================*/#}

		<style>
			{# Font families #}

			{{ component(
				'fonts',{
					font_weights: '400,700',
					font_settings: 'settings.font_headings, settings.font_rest'
				})
			}}

			{# General CSS Tokens #}

			{% include "static/css/style-tokens.tpl" %}
		</style>

		{# Critical CSS #}

		{{ 'css/style-critical.scss' | static_url | static_inline }}
		{{ 'css/style-utilities.scss' | static_url | static_inline }}

		{# Load async styling not mandatory for first meaningfull paint #}

		<link rel="stylesheet" href="{{ 'css/style-async.scss' | static_url }}" media="print" onload="this.media='all'">

		{# Loads custom CSS added from Advanced Settings on the admin´s theme customization screen #}

		<style>
			{{ settings.css_code | raw }}
		</style>

		{# MIAMI_IMPORT — custom styles inline (no static_url) #}
		{% include "snipplets/miami-styles.tpl" %}

		{#/*============================================================================
			#Javascript: Needed before HTML loads
		==============================================================================*/#}

		{# Defines if async JS will be used by using script_tag(true) #}

		{% set async_js = true %}

		{# Defines the usage of jquery loaded below, if nojquery = true is deleted it will fallback to jquery 1.5 #}

		{% set nojquery = true %}

		{# Jquery async by adding script_tag(true) #}

		{% if load_jquery %}

			{{ '//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js' | script_tag(true) }}

		{% endif %}

		{# Loads private Tiendanube JS #}

		{% head_content %}

		{# Structured data to provide information for Google about the page content #}

		{{ component('structured-data-organization') }}
		{{ component('structured-data') }}

	</head>
	<body class="{% if customer %}customer-logged-in{% endif %} template-{{ template | replace('.', '-') }} is-preloading">

		{# MIAMI_IMPORT — Preloader: HTML inmediato al inicio del body para que aparezca antes que el resto #}
		<div id="miami-preloader" aria-hidden="true">
			<img class="miami-preloader__logo" src="{{ 'images/miami-logo-v4.webp' | static_url }}" alt="" fetchpriority="high" />
			<div class="miami-preloader__bar"><i></i></div>
		</div>
		<script>
			/* Hide preloader cuando window.load o failsafe 4500ms. Inline para ejecutarse
			   apenas el browser parsea el body, sin esperar otros scripts. */
			(function () {
				var p = document.getElementById('miami-preloader');
				if (!p) return;
				var hidden = false;
				function hide() {
					if (hidden) return;
					hidden = true;
					p.classList.add('is-hidden');
					document.body.classList.remove('is-preloading');
					setTimeout(function () {
						if (p.parentNode) p.parentNode.removeChild(p);
					}, 600);
				}
				if (document.readyState === 'complete') {
					setTimeout(hide, 100);
				} else {
					window.addEventListener('load', function () { setTimeout(hide, 150); });
				}
				setTimeout(hide, 4500); /* failsafe: no se queda colgado */
			})();
		</script>

		{{ component('nubesdk-slot', { type: "before_main_content" }) }}

		{# Theme icons #}

		{% include "snipplets/svg/icons.tpl" %}

		{# Back to admin bar #}

		{{back_to_admin}}

		{# Header #}

		{% snipplet "header/header.tpl" %}

		{# Page content #}

		{% template_content %}

		{# Quickshop modal #}

		{% snipplet "grid/quick-shop.tpl" %}

		{# WhatsApp chat button #}

		{% snipplet "whatsapp-chat.tpl" %}

		{# Footer #}

		{% snipplet "footer/footer.tpl" %}

		{% if cart.free_shipping.cart_has_free_shipping or cart.free_shipping.min_price_free_shipping.min_price %}

			{# Minimum used for free shipping progress messages. Located on header so it can be accesed everywhere with shipping calculator active or inactive #}

			<span class="js-ship-free-min hidden" data-pricemin="{{ cart.free_shipping.min_price_free_shipping.min_price_raw }}"></span>
			<span class="js-free-shipping-config hidden" data-config="{{ cart.free_shipping.allFreeConfigurations }}"></span>
			<span class="js-cart-subtotal hidden" data-priceraw="{{ cart.subtotal }}"></span>
			<span class="js-cart-discount hidden" data-priceraw="{{ cart.promotional_discount_amount }}"></span>
		{% endif %}

		{#/*============================================================================
			#Javascript: Needed after HTML loads
		==============================================================================*/#}

		{# Javascript used in the store #}

		{# Critical libraries #}

		{{ 'js/external-no-dependencies.js.tpl' | static_url | script_tag }}

		<script type="text/javascript">

			LS.ready.then(function(){

				{# Non critical libraries #}

				{% include "static/js/external.js.tpl" %}

				{# Specific store JS functions: product variants, cart, shipping, etc #}

				{% include "static/js/store.js.tpl" %}

			});

		</script>

		{# Google survey JS for Tiendanube Survey #}

		{{ component('google-survey') }}

		{# Store external codes added from admin #}

		{% if store.assorted_js %}
			<script>
				LS.ready.then(function() {
					var trackingCode = jQueryNuvem.parseHTML('{{ store.assorted_js| escape("js") }}', document, true);
					jQueryNuvem('body').append(trackingCode);
				});
			</script>
		{% endif %}

		{# MIAMI_IMPORT — Vanta.js (3D background del hero).
		   Vanta NET = red wireframe en 3D animada, color dorado sobre negro
		   matched con la paleta Champagne Noir. Requiere Three.js. Ambos
		   van con `defer` para no bloquear el FMP — el init del effecto se
		   reintenta hasta que VANTA este disponible (ver miami-scripts.tpl). #}
		<script src="https://cdn.jsdelivr.net/npm/three@0.134.0/build/three.min.js" defer></script>
		<script src="https://cdn.jsdelivr.net/npm/vanta@0.5.24/dist/vanta.net.min.js" defer></script>

		{# MIAMI_IMPORT — GSAP 3 + ScrollTrigger + Lenis (smooth scroll).
		   Stack cinematografico premium estandar industria:
		   - GSAP = engine de animacion (Apple, Tesla, Netflix)
		   - ScrollTrigger = scroll choreography (Bottega, Off-White, Saint Laurent)
		   - Lenis = smooth scroll con inercia (Awwwards SOTY 2023)
		   Los inits viven dentro de miami-trilogy.tpl y miami-scripts.tpl. #}
		<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/gsap.min.js" defer></script>
		<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/ScrollTrigger.min.js" defer></script>
		<script src="https://cdn.jsdelivr.net/npm/lenis@1.0.45/dist/lenis.min.js" defer></script>

		{# MIAMI_IMPORT — custom scripts inline (carrusel, modales, reveal, tilt 3D, hero parallax, vanta init) #}
		{% include "snipplets/miami-scripts.tpl" %}

		{# MIAMI_IMPORT — Dual price display: USD arriba + ARS abajo.
		   JS estatico (NO snippet) para que Twig no lo parsee. TC=1428.
		   Cambiar TC: editar static/js/miami-usd-display.js linea USD_RATE. #}
		<script src="{{ 'js/miami-usd-display.js' | static_url }}" defer></script>

		{# MIAMI_IMPORT — Widget de chat Mía (IA, bot embebido).
		   El script se sirve desde Bot-Miami (Render) y se auto-inicializa:
		   inyecta una burbuja flotante abajo-derecha + drawer con la
		   conversacion. El JS toma el origen desde la URL del propio
		   <script>, asi funciona tanto en miamiimport.com.ar como en el
		   subdominio de Tiendanube. #}
		<script src="https://bot-miami.onrender.com/static/widget.js" async></script>
	</body>
</html>
