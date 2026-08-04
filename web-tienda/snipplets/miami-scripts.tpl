{# MIAMI_IMPORT — custom scripts (inline) #}
<script>
(function () {
  'use strict';

  /* ---- Modales legales ---- */
  document.addEventListener('click', function (e) {
    var opener = e.target.closest('[data-miami-open]');
    if (opener) {
      e.preventDefault();
      var id = opener.getAttribute('data-miami-open');
      var modal = document.getElementById(id);
      if (modal) { modal.hidden = false; document.body.classList.add('miami-modal-open'); }
      return;
    }
    if (e.target.matches('[data-miami-close]')) {
      var modal2 = e.target.closest('.miami-modal');
      if (modal2) modal2.hidden = true;
      if (!document.querySelector('.miami-modal:not([hidden])')) {
        document.body.classList.remove('miami-modal-open');
      }
    }
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
      document.querySelectorAll('.miami-modal:not([hidden])').forEach(function (m) { m.hidden = true; });
      document.body.classList.remove('miami-modal-open');
    }
  });

  /* ---- Reveal on scroll ---- */
  function initReveal() {
    var els = document.querySelectorAll('[data-miami-reveal]');
    if (!els.length) return;
    if (!('IntersectionObserver' in window)) {
      els.forEach(function (el) { el.classList.add('is-revealed'); });
      return;
    }
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) { entry.target.classList.add('is-revealed'); io.unobserve(entry.target); }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
    els.forEach(function (el) { io.observe(el); });
  }

  /* ---- Marquee infinite ---- */
  function initMarquees() {
    document.querySelectorAll('[data-miami-marquee]').forEach(function (track) {
      if (track.dataset.miamiMarqueeReady) return;
      track.innerHTML = track.innerHTML + track.innerHTML;
      track.dataset.miamiMarqueeReady = '1';
    });
  }

  /* ---- Drag carousel (futuro) ---- */
  function initCarousels() {
    document.querySelectorAll('[data-miami-carousel]').forEach(function (carousel) {
      var track = carousel.querySelector('[data-miami-track]');
      if (!track || track.dataset.miamiReady) return;
      track.dataset.miamiReady = '1';
      /* Las cards son <a><img>: el drag&drop nativo del browser se robaba el
         gesto y solo se podia arrastrar desde el fondo. Se anula acá. */
      track.addEventListener('dragstart', function (e) { e.preventDefault(); });
      var isDown=false,startX=0,startScroll=0,lastX=0,lastT=0,velocity=0,hasMoved=false;
      function down(e){isDown=true;hasMoved=false;startX=(e.touches?e.touches[0].pageX:e.pageX);startScroll=track.scrollLeft;lastX=startX;lastT=Date.now();velocity=0;}
      function move(e){if(!isDown)return;var x=(e.touches?e.touches[0].pageX:e.pageX);var dx=x-startX;if(Math.abs(dx)>6){if(!hasMoved){hasMoved=true;track.classList.add('is-grabbing');}if(!e.touches)e.preventDefault();track.scrollLeft=startScroll-dx*1.4;var n=Date.now();var dt=n-lastT||16;velocity=(x-lastX)/dt;lastX=x;lastT=n;}}
      function up(){if(!isDown)return;isDown=false;if(!hasMoved){track.classList.remove('is-grabbing');return;}var v=-velocity*16,f=0;function step(){if(Math.abs(v)<0.4||f++>90){track.classList.remove('is-grabbing');return;}track.scrollLeft+=v;v*=0.93;requestAnimationFrame(step);}requestAnimationFrame(step);}
      track.addEventListener('mousedown',down);
      window.addEventListener('mousemove',move);
      window.addEventListener('mouseup',up);
      track.addEventListener('click',function(e){if(hasMoved){e.preventDefault();e.stopPropagation();hasMoved=false;}},true);
      track.addEventListener('touchstart',down,{passive:true});
      track.addEventListener('touchmove',move,{passive:true});
      track.addEventListener('touchend',up);
      track.addEventListener('touchcancel',up);
    });
  }

  /* ---- Tilt 3D (Champagne Noir) ---- */
  /* Gateado: solo si el device tiene hover real (descarta tablets/mobile que
     emulan hover y disparan tilts pegajosos) y si el usuario no pidio
     reduced-motion. La intensidad maxima sale del CSS var --miami-tilt-max
     (default 8deg). */
  function initTilt3D() {
    if (!window.matchMedia) return;
    var canHover = window.matchMedia('(hover: hover)').matches;
    var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (!canHover || reduceMotion) return;

    var rootStyle = getComputedStyle(document.documentElement);
    var maxDeg = parseFloat(rootStyle.getPropertyValue('--miami-tilt-max')) || 8;

    var selectors = [
      '.miami-brand-tile',
      '.miami-lookbook__tile',
      '.miami-split__media--photo'
    ];
    document.querySelectorAll(selectors.join(',')).forEach(function (el) {
      if (el.dataset.miamiTilt) return;
      el.dataset.miamiTilt = '1';

      el.addEventListener('mousemove', function (e) {
        var rect = el.getBoundingClientRect();
        var x = (e.clientX - rect.left) / rect.width;   // 0..1
        var y = (e.clientY - rect.top) / rect.height;   // 0..1
        var ty = (y - 0.5) * maxDeg * 2;
        var tx = (x - 0.5) * maxDeg * 2;
        el.style.setProperty('--tx', tx.toFixed(2) + 'deg');
        el.style.setProperty('--ty', ty.toFixed(2) + 'deg');
      });
      el.addEventListener('mouseleave', function () {
        el.style.setProperty('--tx', '0deg');
        el.style.setProperty('--ty', '0deg');
      });
    });
  }

  /* ---- Hero parallax (mouse) ---- */
  /* Mueve la lluvia de marcas y el bloque del titulo en direcciones
     opuestas al mover el mouse sobre el hero. Crea sensacion de profundidad
     sin tocar la accesibilidad. */
  function initHeroParallax() {
    if (!window.matchMedia) return;
    var canHover = window.matchMedia('(hover: hover)').matches;
    var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (!canHover || reduceMotion) return;

    var hero = document.querySelector('.miami-hero');
    if (!hero || hero.dataset.miamiParallax) return;
    hero.dataset.miamiParallax = '1';

    hero.addEventListener('mousemove', function (e) {
      var rect = hero.getBoundingClientRect();
      var mx = ((e.clientX - rect.left) / rect.width) * 2 - 1;   // -1..1
      var my = ((e.clientY - rect.top) / rect.height) * 2 - 1;   // -1..1
      hero.style.setProperty('--hero-mx', mx.toFixed(3));
      hero.style.setProperty('--hero-my', my.toFixed(3));
    });
    hero.addEventListener('mouseleave', function () {
      hero.style.setProperty('--hero-mx', '0');
      hero.style.setProperty('--hero-my', '0');
    });
  }

  /* ---- Vanta.NET — fondo 3D animado en el hero ---- */
  /* Red wireframe dorada sobre negro. Vanta + Three se cargan con `defer`
     desde CDN (jsdelivr), asi que cuando este boot() corre puede que aun
     no esten disponibles. Reintentamos cada 200ms hasta 10s.
     Skipeamos en mobile (perf) y si pidio reduced-motion. */
  function initVanta() {
    if (!document.querySelector('.miami-hero')) return;
    if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

    var isMobile = window.innerWidth < 768;

    /* Skip Vanta en devices low-end para no trabar la pagina:
       - hardwareConcurrency < 4 (CPUs viejas/baratas)
       - deviceMemory < 4 GB (RAM baja, mayormente celus viejos)
       - Save-Data on (usuario pidio ahorrar datos)
       El sitio sigue viendose 100% igual, solo sin red wireframe atras. */
    var lowEnd = false;
    if (typeof navigator !== 'undefined') {
      if (typeof navigator.hardwareConcurrency === 'number' && navigator.hardwareConcurrency > 0 && navigator.hardwareConcurrency < 4) lowEnd = true;
      if (typeof navigator.deviceMemory === 'number' && navigator.deviceMemory > 0 && navigator.deviceMemory < 4) lowEnd = true;
      if (navigator.connection && navigator.connection.saveData) lowEnd = true;
    }
    if (lowEnd) return;

    var tries = 0;
    function tryInit() {
      if (window.VANTA && window.VANTA.NET && window.THREE) {
        if (window._miamiVanta) {
          try { window._miamiVanta.destroy(); } catch (e) {}
        }
        window._miamiVanta = window.VANTA.NET({
          el: '.miami-hero',
          mouseControls: !isMobile,
          touchControls: false,
          gyroControls: false,
          minHeight: 400.0,
          minWidth: 200.0,
          scale: 1.0,
          scaleMobile: 1.0,
          color: 0xb99b63,        // champagne gold
          backgroundColor: 0x0a0a0a,
          // Desktop: red densa (la que te gusta). Mobile: menos puntos y
          // mas spacing para que en pantalla angosta no se vea tupido.
          points: isMobile ? 8.0 : 12.0,
          maxDistance: isMobile ? 20.0 : 24.0,
          spacing: isMobile ? 26.0 : 18.0,
          showDots: true
        });
        return;
      }
      if (tries++ < 50) setTimeout(tryInit, 200);
    }
    tryInit();
  }

  /* ---- Lenis smooth scroll (inercia premium tipo Awwwards) ---- */
  /* Lenis se carga via defer en layout.tpl. Si llego aca, lo inicializamos.
     ScrollTrigger.update() se hookea para que el pin/scrub del trilogy
     siga al smooth scroll y no al native scroll. */
  function initLenis() {
    if (!window.Lenis) {
      if ((initLenis.tries = (initLenis.tries || 0) + 1) < 50) {
        setTimeout(initLenis, 200);
      }
      return;
    }
    if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    if (window._miamiLenis) return; // ya inicializado

    var lenis = new window.Lenis({
      duration: 1.15,
      easing: function (t) { return Math.min(1, 1.001 - Math.pow(2, -10 * t)); },
      smoothWheel: true,
      smoothTouch: false,    // touch nativo: mejor UX en mobile
      lerp: 0.08,
    });
    window._miamiLenis = lenis;

    function raf(time) {
      lenis.raf(time);
      requestAnimationFrame(raf);
    }
    requestAnimationFrame(raf);

    // Hook con ScrollTrigger si esta disponible (el pin de trilogy depende
    // de que ST sepa cuando el scroll cambia)
    if (window.gsap && window.ScrollTrigger) {
      lenis.on('scroll', window.ScrollTrigger.update);
      window.gsap.ticker.add(function (time) { lenis.raf(time * 1000); });
      window.gsap.ticker.lagSmoothing(0);
    }
  }

  /* ---- Custom cursor (dot + ring + magnetic detection) ---- */
  /* Skipea touch devices (sin (hover: hover) no tiene sentido). El ring
     sigue con delay para sensacion premium. Cuando esta sobre algo
     interactivo (.miami-magnetic, a, button, [data-cursor-hover]) el ring
     se agranda y el dot se invierte a dorado. */
  function initCursor() {
    if (!window.matchMedia || !window.matchMedia('(hover: hover)').matches) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    if (document.querySelector('.miami-cursor')) return; // ya esta

    var dot = document.createElement('div');
    dot.className = 'miami-cursor miami-cursor--dot';
    var ring = document.createElement('div');
    ring.className = 'miami-cursor miami-cursor--ring';
    document.body.appendChild(dot);
    document.body.appendChild(ring);

    var tx = 0, ty = 0, rx = 0, ry = 0;
    var dx = 0, dy = 0;

    document.addEventListener('mousemove', function (e) {
      tx = e.clientX; ty = e.clientY;
      dot.style.opacity = '1';
      ring.style.opacity = '1';
    }, { passive: true });

    document.addEventListener('mouseleave', function () {
      dot.style.opacity = '0';
      ring.style.opacity = '0';
    });

    // Loop: dot inmediato, ring con delay
    function loop() {
      dx += (tx - dx) * 0.4;
      dy += (ty - dy) * 0.4;
      rx += (tx - rx) * 0.16;
      ry += (ty - ry) * 0.16;
      dot.style.transform = 'translate3d(' + dx + 'px,' + dy + 'px, 0)';
      ring.style.transform = 'translate3d(' + rx + 'px,' + ry + 'px, 0)';
      requestAnimationFrame(loop);
    }
    loop();

    // Hover effects sobre interactivos
    var hoverSel = 'a, button, [data-cursor-hover], .miami-magnetic';
    document.addEventListener('mouseover', function (e) {
      if (e.target.closest(hoverSel)) {
        ring.classList.add('is-hover');
        dot.classList.add('is-hover');
      }
    });
    document.addEventListener('mouseout', function (e) {
      if (e.target.closest(hoverSel)) {
        ring.classList.remove('is-hover');
        dot.classList.remove('is-hover');
      }
    });
  }

  /* ---- Magnetic buttons (elementos con .miami-magnetic o data-magnetic) ---- */
  /* El boton se traduce hacia el cursor un 30% de la distancia dentro de
     su bounding box. Reset suave en mouseleave. Funciona en cualquier
     elemento marcado. */
  function initMagnetic() {
    if (!window.matchMedia || !window.matchMedia('(hover: hover)').matches) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

    var els = document.querySelectorAll('.miami-magnetic, [data-magnetic]');
    if (!els.length) return;

    els.forEach(function (el) {
      if (el.dataset.miamiMagneticReady) return;
      el.dataset.miamiMagneticReady = '1';
      var strength = parseFloat(el.dataset.magneticStrength || '0.35');
      var rect = null;

      function enter() { rect = el.getBoundingClientRect(); }
      function move(e) {
        if (!rect) rect = el.getBoundingClientRect();
        var cx = rect.left + rect.width / 2;
        var cy = rect.top + rect.height / 2;
        var dx = (e.clientX - cx) * strength;
        var dy = (e.clientY - cy) * strength;
        el.style.transform = 'translate3d(' + dx + 'px,' + dy + 'px,0)';
      }
      function leave() {
        rect = null;
        el.style.transform = '';
      }

      el.addEventListener('mouseenter', enter);
      el.addEventListener('mousemove', move);
      el.addEventListener('mouseleave', leave);
    });
  }

  /* ---- Cinematic tile (Lenguaje de calle) — reveal + mouse parallax inercia ---- */
  function initCinematicTile() {
    var tiles = document.querySelectorAll('[data-miami-cinematic]');
    if (!tiles.length) return;
    var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    // Reveal del texto via IntersectionObserver
    if ('IntersectionObserver' in window) {
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) {
            e.target.classList.add('is-revealed');
            io.unobserve(e.target);
          }
        });
      }, { threshold: 0.25 });
      tiles.forEach(function (t) { io.observe(t); });
    } else {
      tiles.forEach(function (t) { t.classList.add('is-revealed'); });
    }

    if (reduceMotion) return;
    var canHover = window.matchMedia && window.matchMedia('(hover: hover)').matches;
    if (!canHover) return;

    tiles.forEach(function (tile) {
      var img = tile.querySelector('.miami-lookbook__img');
      var haze = tile.querySelector('.miami-lookbook__haze');
      if (!img) return;
      var targetX = 0, targetY = 0, curX = 0, curY = 0;
      var rafId = null;
      function loop() {
        curX += (targetX - curX) * 0.08;
        curY += (targetY - curY) * 0.08;
        // Parallax sutil — la animacion Ken Burns sigue, esto se suma como translate adicional
        var px = curX * 1.2; // px max ~12px
        var py = curY * 0.9; // px max ~9px
        img.style.transform = 'translate3d(' + px + 'px, ' + py + 'px, 0)';
        if (haze) haze.style.transform = 'translate3d(' + (curX * 2) + 'px, ' + (curY * 1.5) + 'px, 0)';
        if (Math.abs(targetX - curX) > 0.05 || Math.abs(targetY - curY) > 0.05) {
          rafId = requestAnimationFrame(loop);
        } else {
          rafId = null;
        }
      }
      tile.addEventListener('mousemove', function (e) {
        var rect = tile.getBoundingClientRect();
        targetX = -(((e.clientX - rect.left) / rect.width) * 2 - 1) * 10;
        targetY = -(((e.clientY - rect.top) / rect.height) * 2 - 1) * 8;
        if (!rafId) rafId = requestAnimationFrame(loop);
      });
      tile.addEventListener('mouseleave', function () {
        targetX = 0; targetY = 0;
        if (!rafId) rafId = requestAnimationFrame(loop);
      });
    });
  }

  function boot() {
    initReveal();
    initMarquees();
    initCarousels();
    initTilt3D();
    initHeroParallax();
    /* initVanta() + initLenis() removidos: el hero viejo (Vanta 3D) ya no existe
       y el smooth-scroll de Lenis trababa la ruedita. Scroll NATIVO, fluido.
       initCursor() también fuera (cursor custom = tell de IA). */
    initMagnetic();
    initCinematicTile();
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
</script>
