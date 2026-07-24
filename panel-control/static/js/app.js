// MIAMI_IMPORT — Stock Manager · Frontend

const API = '';  // mismo dominio
let PRODUCTS_CACHE = [];

// Datos de la tienda (URL propia). Se cargan al arrancar desde /api/store para
// no hardcodear el dominio en el frontend.
let STORE = { url: '', product_url_base: '/productos/' };

// Set estándar de talles ofrecidos en el modal (respeta convención de la tienda)
const STANDARD_SIZES = ['XXS', 'XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL'];

// ============ Helpers ============
const $ = sel => document.querySelector(sel);
const $$ = sel => document.querySelectorAll(sel);

function toast(msg, type = '') {
  const t = $('#toast');
  t.textContent = msg;
  t.className = 'toast ' + type;
  setTimeout(() => t.classList.add('hidden'), 3500);
  setTimeout(() => t.className = 'toast hidden', 3500);
}

function fmtMoney(n) {
  if (n === null || n === undefined) return '—';
  return '$ ' + Number(n).toLocaleString('es-AR', { minimumFractionDigits: 0, maximumFractionDigits: 0 });
}

function fmtNum(n) {
  return Number(n).toLocaleString('es-AR');
}

// REGLA: todo valor que venga de la API y se inserte con innerHTML va con
// esc(). Los pedidos los crea cualquiera desde el checkout público (nombre,
// email), así que sin esto un `<img onerror=...>` en el nombre del comprador
// ejecuta JS con la sesión del admin.
//
// Se define ACÁ arriba a propósito: es de las primeras cosas que corren y la
// usa todo el panel. Estaba más abajo, junto a una sección que se eliminó, y
// se fue con ella: `const esc = escapeHtml` lanzaba ReferenceError y mataba el
// script entero (no andaba ni el menú ni las pestañas).
function escapeHtml(s) {
  // String(s ?? '') — NO `s || ''`: con un número, array o booleano el `||` los
  // dejaba pasar tal cual y `.replace` no existe -> TypeError que abortaba el
  // render entero. Y con `||` el 0 se convertía en '' (stock 0 salía vacío).
  return String(s ?? '')
    .replace(/&/g, '&amp;').replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
    .replace(/</g, '&lt;').replace(/>/g, '&gt;');
}
const esc = escapeHtml;

let MFA_ABIERTO = false;

async function api(path, opts = {}) {
  const r = await fetch(API + path, opts);

  if (r.status === 401) {
    window.location.href = '/login';       // sesion vencida
    throw new Error('Sesion expirada');
  }
  if (r.status === 403) {
    // 403 NO es sesion vencida: la sesion es valida pero falta activar el
    // segundo factor. Mandarlo a /login dejaba al admin en un bucle sin salida
    // (entra, todo da 403, vuelve al login) sin manera de configurarlo.
    const cuerpo = await r.clone().json().catch(() => ({}));
    if (/MFA|segundo factor/i.test(cuerpo.detail || '')) {
      abrirSetupMfa();
      throw new Error('Falta activar el segundo factor');
    }
    window.location.href = '/login';
    throw new Error('Sin permisos');
  }
  if (!r.ok) {
    const t = await r.text();
    throw new Error(t || r.statusText);
  }
  if (r.headers.get('content-type')?.includes('application/json')) {
    return r.json();
  }
  return r;
}

// ============ Tabs / routing por hash ============
// Cada pestaña tiene su propia URL (#dashboard, #venta, etc.) para
// poder entrar directo, compartir el link y usar atrás/adelante del navegador.
const VALID_TABS = [
  'dashboard', 'productos', 'alta', 'venta', 'pedidos',
  'estadisticas', 'precios-usd', 'whatsapp', 'acciones',
];
const TAB_LOADERS = {
  dashboard: loadDashboard,
  productos: () => { if (PRODUCTS_CACHE.length === 0) loadProducts(); },
  venta: () => posBuscar($('#pos-buscar')?.value || ''),
  pedidos: loadOrders,
  estadisticas: loadStatsDetail,
  'precios-usd': loadUsdPrices,
  whatsapp: loadWaTemplates,
};

function currentTabFromHash() {
  const t = (location.hash || '').replace(/^#/, '').trim();
  return VALID_TABS.includes(t) ? t : 'dashboard';
}

function activateTab(tab) {
  if (!VALID_TABS.includes(tab)) tab = 'dashboard';
  $$('.nav-item').forEach(b => b.classList.toggle('active', b.dataset.tab === tab));
  $$('.tab').forEach(s => s.classList.toggle('active', s.dataset.tab === tab));
  closeSidebar();            // en tablet: cerrar el cajón al navegar
  window.scrollTo(0, 0);
  // La carga de datos va al final y protegida: si un endpoint falla, la
  // pestaña igual queda abierta en vez de dejar la navegación a medias.
  try {
    const loader = TAB_LOADERS[tab];
    if (loader) loader();
  } catch (e) {
    toast('No se pudo cargar esta sección: ' + e.message, 'error');
  }
}

// Navegación por cambio de hash (back/forward del navegador, entrada directa)
window.addEventListener('hashchange', () => activateTab(currentTabFromHash()));

// Y ADEMÁS por click directo en cada ítem del menú. No alcanza con depender del
// hashchange: si el hash ya es el mismo el evento no dispara, y algunos
// navegadores de tablet lo entregan tarde o no lo entregan. Con esto, tocar una
// pestaña siempre navega.
document.addEventListener('click', ev => {
  const item = ev.target.closest('.nav-item[href^="#"]');
  if (!item) return;
  ev.preventDefault();
  const tab = item.getAttribute('href').slice(1);
  if (location.hash !== '#' + tab) {
    history.pushState(null, '', '#' + tab);   // deja andando atrás/adelante
  }
  activateTab(tab);
});
window.addEventListener('popstate', () => activateTab(currentTabFromHash()));

// ============ Menú lateral en celular (drawer) ============
function openSidebar() { document.body.classList.add('nav-open'); }
function closeSidebar() { document.body.classList.remove('nav-open'); }
function toggleSidebar() { document.body.classList.toggle('nav-open'); }

$('#mobile-menu-btn')?.addEventListener('click', toggleSidebar);
$('#sidebar-overlay')?.addEventListener('click', closeSidebar);
// Al tocar cualquier ítem del menú, cerrar el cajón (aunque sea la tab activa)
$$('.nav-item').forEach(a => a.addEventListener('click', closeSidebar));

// ============ Dashboard ============
async function loadDashboard() {
  try {
    const s = await api('/api/stats');

    $('#kpi-publicados').textContent = fmtNum(s.productos.publicados);
    $('#kpi-publicados-sub').textContent = `de ${s.productos.total} totales`;
    $('#kpi-stock').textContent = fmtNum(s.productos.stock_total);
    $('#kpi-stock-sub').textContent = `en ${s.productos.variantes} variantes`;
    $('#kpi-sin-stock').textContent = fmtNum(s.productos.sin_stock);
    $('#kpi-facturado').textContent = fmtMoney(s.pedidos.facturado_total);
    $('#kpi-facturado-sub').textContent = `${s.pedidos.total} pedidos · ticket ${fmtMoney(s.pedidos.ticket_promedio)}`;

    // Top vendidos
    const topEl = $('#list-top-vendidos');
    if (s.top_vendidos && s.top_vendidos.length) {
      topEl.innerHTML = s.top_vendidos.map((t, i) => `
        <li>
          <span><b>${i + 1}.</b> ${esc(t.name || '—')}</span>
          <span class="qty">${t.vendidos} ${t.vendidos === 1 ? 'unidad' : 'unidades'}</span>
        </li>
      `).join('');
    } else {
      topEl.innerHTML = '<li class="loading-row">Sin ventas registradas todavía.</li>';
    }

    // Stock bajo
    const stockEl = $('#list-stock-bajo');
    if (s.stock_bajo && s.stock_bajo.length) {
      stockEl.innerHTML = s.stock_bajo.slice(0, 12).map(p => `
        <li>
          <span>${esc(p.name || '—')} <small style="color:var(--ink-mute)">· ${esc(p.brand || '')}</small></span>
          <span class="alert">${p.stock} unid.</span>
        </li>
      `).join('');
    } else {
      stockEl.innerHTML = '<li class="loading-row">¡Todo con stock OK!</li>';
    }
  } catch (e) {
    toast('Error cargando estadísticas: ' + e.message, 'error');
  }
}

$('#btn-refresh-stats').addEventListener('click', loadDashboard);

// ============ Productos ============
async function loadProducts() {
  const grid = $('#products-grid');
  grid.innerHTML = '<div class="loading">Cargando productos…</div>';
  try {
    const prods = await api('/api/products/all');
    PRODUCTS_CACHE = prods;
    renderProducts(prods);
  } catch (e) {
    grid.innerHTML = '<div class="loading">Error: ' + esc(e.message) + '</div>';
  }
}

function renderProducts(prods) {
  const grid = $('#products-grid');
  if (!prods.length) {
    grid.innerHTML = '<div class="loading">No se encontraron productos.</div>';
    return;
  }
  grid.innerHTML = prods.map(p => {
    const nm = (p.name && p.name.es) || p.name || '—';
    const brand = p.brand || '';
    const img = p.images && p.images[0] ? p.images[0].src : '';
    const stock = (p.variants || []).reduce((a, v) => a + (parseInt(v.stock) || 0), 0);
    const minPrice = Math.min(...(p.variants || []).map(v => parseFloat(v.price) || Infinity));
    let stockClass = '';
    if (stock === 0) stockClass = 'empty';
    else if (stock <= 2) stockClass = 'low';
    return `
      <div class="product-card" data-product-id="${Number(p.id)}">
        <div class="img">
          ${img ? `<img src="${esc(img)}" alt="${esc(nm)}" loading="lazy">` : '<div class="no-img">Sin imagen</div>'}
        </div>
        <div class="meta">
          <div class="brand">${esc(brand)}</div>
          <div class="name">${esc(nm)}</div>
          <div class="footline">
            <span class="price">${minPrice !== Infinity ? fmtMoney(minPrice) : '—'}</span>
            <span class="stock-pill ${stockClass}">${stock} ud.</span>
          </div>
        </div>
      </div>
    `;
  }).join('');

  // Además de la delegación en document, se ata el clic DIRECTO a cada tarjeta.
  // Un listener directo sobre el elemento dispara el toque en cualquier tablet
  // (iOS incluido), donde la delegación sobre un <div> puede no hacerlo.
  grid.querySelectorAll('.product-card').forEach(card => {
    card.addEventListener('click', () => openProduct(Number(card.dataset.productId)));
  });
}

$('#search').addEventListener('input', e => {
  const q = e.target.value.trim().toLowerCase();
  if (!q) return renderProducts(PRODUCTS_CACHE);
  const filt = PRODUCTS_CACHE.filter(p => {
    const nm = ((p.name && p.name.es) || p.name || '').toLowerCase();
    const brand = (p.brand || '').toLowerCase();
    return nm.includes(q) || brand.includes(q);
  });
  renderProducts(filt);
});

// ============ Modal producto ============
async function openProduct(pid) {
  $('#modal').classList.remove('hidden');
  $('#modal-body').innerHTML = '<div class="loading">Cargando…</div>';
  try {
    const p = await api(`/api/products/${pid}`);
    renderProductModal(p);
  } catch (e) {
    $('#modal-body').innerHTML = 'Error: ' + esc(e.message);
  }
}

function renderProductModal(p) {
  const nm = (p.name && p.name.es) || p.name || '—';
  const img = p.images && p.images[0] ? p.images[0].src : '';
  const handle = (p.handle && p.handle.es) || p.handle || '';
  // Apunta a NUESTRA tienda (antes estaba la URL de Tiendanube hardcodeada).
  const url = `${STORE.product_url_base || '/productos/'}${handle}/`;

  const variants = (p.variants || []).map(v => {
    const vals = v.values || [];
    const talle = vals[0]?.es || vals[0]?.value || 'Único';
    return `
      <div class="modal-row" data-vid="${Number(v.id)}">
        <span class="talle">${esc(talle)}</span>
        <span class="sku">${esc(v.sku || '')}</span>
        <span style="flex:1"></span>
        <button class="btn-stock" data-adjust="-1" data-pid="${Number(p.id)}" data-vid="${Number(v.id)}">−</button>
        <input class="stock-input" type="number" min="0" value="${Number(v.stock) || 0}" data-stock-input/>
        <button class="btn-stock" data-adjust="1" data-pid="${Number(p.id)}" data-vid="${Number(v.id)}">+</button>
        <span style="font-weight:600; min-width:80px; text-align:right">${fmtMoney(v.price)}</span>
        <button class="btn-stock" data-del-variant="${Number(v.id)}" data-pid="${Number(p.id)}"
                title="Quitar este talle" style="color:#ff7a7a">✕</button>
      </div>
    `;
  }).join('');

  // Agregar talles: disponible SIEMPRE, en todos los productos. Antes esta
  // sección solo aparecía si el producto traía el atributo "Talle", así que a
  // la mayoría del catálogo no se le podía sumar ninguno. Además de los atajos
  // con los talles comunes hay un campo libre: cualquier talle vale (números
  // como 38/42, "ÚNICO", "44 EU", lo que se use).
  const present = new Set((p.variants || []).map(v => {
    const vals = v.values || [];
    return ((vals[0]?.es || vals[0]?.value || '') + '').trim().toUpperCase();
  }));
  const chips = STANDARD_SIZES.map(sz => {
    if (present.has(sz)) {
      return `<span class="size-chip present" title="Ya cargado">${esc(sz)}</span>`;
    }
    return `<button class="size-chip add" data-add-variant="${Number(p.id)}" data-size="${esc(sz)}" title="Agregar talle ${esc(sz)} (stock 0)">+ ${esc(sz)}</button>`;
  }).join('');
  const addSizesHtml = `
    <h2 style="margin-top:24px; font-size:14px; letter-spacing:.08em; text-transform:uppercase; color:var(--ink-mute)">Agregar talle</h2>
    <p style="color:var(--ink-mute); font-size:12px; margin:4px 0 12px">Tocá uno de los rápidos o escribí el que quieras. Se agrega con stock 0 y después le cargás las unidades.</p>
    <div class="size-chips">${chips}</div>
    <div class="size-custom">
      <input id="modal-new-size" class="size-custom-input" type="text" maxlength="20"
             autocomplete="off" placeholder="Otro talle: 38, 42, ÚNICO…"
             data-new-size-for="${Number(p.id)}" />
      <button class="btn-ghost" type="button" data-add-custom-size="${Number(p.id)}">Agregar talle</button>
    </div>
  `;

  // Galería de fotos. Cada una se puede girar (preview + "Actualizar") y
  // reordenar: la PRIMERA es la portada, la que ve el cliente en el listado.
  const imgs = p.images || [];
  const imagesHtml = imgs.length
    ? `<div class="modal-photos">${imgs.map((im, i) => `
        <div class="modal-photo${i === 0 ? ' is-cover' : ''}" data-img-id="${Number(im.id)}" data-rot="0">
          <img src="${esc(im.src)}" alt="">
          <span class="modal-photo-pos">${i === 0 ? '★ Principal' : i + 1 + '°'}</span>
          <div class="modal-photo-tools">
            <button class="modal-photo-del" type="button" data-del-img="${Number(im.id)}"
                    data-pid="${Number(p.id)}" title="Eliminar foto">✕</button>
            <button class="modal-photo-rotate" type="button" data-rotate-preview="${Number(im.id)}" title="Girar 90°">↻</button>
            <button class="modal-photo-move" type="button" data-move-img="${Number(im.id)}"
                    data-pid="${Number(p.id)}" data-dir="-1" title="Mover antes"
                    ${i === 0 ? 'disabled' : ''}>◀</button>
            <button class="modal-photo-move" type="button" data-move-img="${Number(im.id)}"
                    data-pid="${Number(p.id)}" data-dir="1" title="Mover después"
                    ${i === imgs.length - 1 ? 'disabled' : ''}>▶</button>
          </div>
          ${i === 0 ? '' : `<button class="modal-photo-cover" type="button"
                    data-make-cover="${Number(im.id)}" data-pid="${Number(p.id)}">Hacer principal</button>`}
          <button class="modal-photo-apply" type="button" data-apply-rotate="${Number(im.id)}" data-pid="${Number(p.id)}">Actualizar</button>
        </div>`).join('')}</div>`
    : '<p style="color:var(--ink-mute); font-size:13px">Este producto todavía no tiene fotos.</p>';

  // Sumar fotos a un producto ya cargado. El <input file> va fuera de pantalla
  // y se dispara desde el botón: en tablet el botón es mucho más confiable que
  // el input nativo, que se toca chiquito y a veces no abre la galería.
  const addPhotosHtml = `
    <div class="modal-addphotos">
      <button class="btn-ghost" type="button" data-pick-photos="${Number(p.id)}">📷 Agregar fotos</button>
      <input type="file" accept="image/*" multiple id="modal-add-photos"
             class="file-offscreen" data-upload-photos="${Number(p.id)}" />
      <span class="modal-addphotos-hint" id="modal-addphotos-hint">Podés elegir varias de una. Se suman al final y después las girás si hace falta.</span>
    </div>
  `;

  $('#modal-body').innerHTML = `
    <div class="modal-brand-row">
      <label class="modal-field-label" for="modal-brand-input">Marca</label>
      <input id="modal-brand-input" class="modal-brand-input" value="${escapeHtml(p.brand || '')}" placeholder="Ej: Jacquemus" />
    </div>
    <div class="modal-name-row">
      <input id="modal-name-input" class="modal-name-input" value="${escapeHtml(nm)}" />
      <button class="btn-ghost" type="button" data-save-info="${Number(p.id)}">Guardar nombre y marca</button>
    </div>
    <p style="color:var(--ink-mute); font-size:13px"><a href="${esc(url)}" target="_blank">${esc(url)} ↗</a></p>
    ${imagesHtml}
    ${addPhotosHtml}

    <h2 style="margin-top:20px; font-size:14px; letter-spacing:.08em; text-transform:uppercase; color:var(--ink-mute)">Variantes y stock</h2>
    ${variants}

    ${addSizesHtml}

    <div class="modal-actions">
      <button class="btn-primary" data-save-stock="${Number(p.id)}">Guardar cambios de stock</button>
      <button class="btn-ghost" data-open-url="${esc(url)}">Ver en tienda ↗</button>
      <button class="btn-danger" data-delete-product="${Number(p.id)}" style="margin-left:auto">Eliminar producto</button>
    </div>
  `;
}

async function saveProductInfo(pid) {
  const name = (document.getElementById('modal-name-input')?.value || '').trim();
  const brand = (document.getElementById('modal-brand-input')?.value || '').trim();
  if (!name) return toast('El nombre no puede quedar vacío', 'error');
  try {
    await api(`/api/products/${pid}`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, brand }),
    });
    toast('✓ Nombre y marca actualizados', 'success');
    PRODUCTS_CACHE = [];   // que la grilla tome los datos nuevos
  } catch (e) {
    toast('Error al guardar: ' + e.message, 'error');
  }
}

// Gira solo el PREVIEW (acumula grados); se aplica en la tienda con "Actualizar"
function rotatePreview(imageId) {
  const photo = document.querySelector(`.modal-photo[data-img-id="${imageId}"]`);
  if (!photo) return;
  const img = photo.querySelector('img');
  const rot = ((parseInt(photo.dataset.rot) || 0) + 90) % 360;
  photo.dataset.rot = rot;
  setRotClass(img, rot);
  photo.classList.toggle('rotated', rot !== 0);
}

async function applyRotate(pid, imageId) {
  const photo = document.querySelector(`.modal-photo[data-img-id="${imageId}"]`);
  const rot = parseInt(photo?.dataset.rot) || 0;
  if (!rot) return toast('Girá la foto primero con ↻', 'error');
  const applyBtn = photo.querySelector('.modal-photo-apply');
  if (applyBtn) { applyBtn.disabled = true; applyBtn.textContent = '⏳ Actualizando…'; }
  try {
    await api(`/api/products/${pid}/images/${imageId}/rotate`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ degrees: rot }),
    });
    toast('✓ Foto girada y actualizada en la tienda', 'success');
    PRODUCTS_CACHE = [];
    openProduct(pid);   // recargar el modal con la imagen ya rotada
  } catch (e) {
    toast('Error al actualizar la foto: ' + e.message, 'error');
    if (applyBtn) { applyBtn.disabled = false; applyBtn.textContent = 'Actualizar'; }
  }
}

async function adjustStock(pid, vid, delta) {
  const row = document.querySelector(`.modal-row[data-vid="${vid}"]`);
  const input = row.querySelector('[data-stock-input]');
  const newVal = Math.max(0, (parseInt(input.value) || 0) + delta);
  input.value = newVal;
  // guardado optimista visual; el save real se hace con "Guardar cambios"
}

async function saveAllStock(pid) {
  const rows = document.querySelectorAll('.modal-row');
  let ok = 0, fail = 0;
  for (const row of rows) {
    const vid = row.dataset.vid;
    const newStock = parseInt(row.querySelector('[data-stock-input]').value) || 0;
    try {
      await api(`/api/variants/${pid}/${vid}/stock`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ stock: newStock }),
      });
      ok++;
    } catch (e) {
      fail++;
    }
  }
  if (fail === 0) {
    toast(`✓ Stock actualizado en ${ok} variantes`, 'success');
  } else {
    toast(`Actualizadas ${ok}, fallaron ${fail}`, 'error');
  }
  // refrescar el cache
  loadProducts();
}

async function addVariant(pid, talle) {
  try {
    await api(`/api/products/${pid}/variants`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ talle, stock: 0 }),
    });
    toast(`✓ Talle ${talle} agregado (stock 0)`, 'success');
    PRODUCTS_CACHE = [];   // invalidar cache de la grilla
    openProduct(pid);      // refrescar el modal con la variante nueva
  } catch (e) {
    toast('Error al agregar talle: ' + e.message, 'error');
  }
}

// ---- Orden de las fotos (la primera es la portada) ----
// El orden que se manda es el que se ve en pantalla, así que se lee del DOM:
// no hace falta llevar estado aparte ni volver a pedir el producto.
function idsDeFotos() {
  return Array.from(document.querySelectorAll('.modal-photo'))
              .map(el => Number(el.dataset.imgId));
}

async function guardarOrdenFotos(pid, ids, aviso) {
  try {
    await api(`/api/products/${pid}/images/orden`, {
      method: 'PUT', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ ids }),
    });
    toast(aviso, 'success');
    PRODUCTS_CACHE = [];   // la grilla muestra la portada nueva
    openProduct(pid);      // refrescar numeración y flechas
  } catch (e) {
    toast('No se pudo cambiar el orden: ' + e.message, 'error');
  }
}

function makeCover(pid, imageId) {
  const resto = idsDeFotos().filter(i => i !== imageId);
  return guardarOrdenFotos(pid, [imageId].concat(resto),
                           '✓ Es la foto principal del producto');
}

async function deleteImage(pid, imageId) {
  if (!confirm('¿Eliminar esta foto? No se puede deshacer.')) return;
  try {
    await api(`/api/products/${pid}/images/${imageId}`, { method: 'DELETE' });
    toast('✓ Foto eliminada', 'success');
    PRODUCTS_CACHE = [];   // la grilla puede haber cambiado de portada
    openProduct(pid);      // refrescar la galería
  } catch (e) {
    toast('No se pudo eliminar la foto: ' + e.message, 'error');
  }
}

function moveImage(pid, imageId, dir) {
  const ids = idsDeFotos();
  const i = ids.indexOf(imageId);
  const j = i + dir;
  if (i < 0 || j < 0 || j >= ids.length) return;
  const tmp = ids[i]; ids[i] = ids[j]; ids[j] = tmp;
  return guardarOrdenFotos(pid, ids, '✓ Orden de fotos actualizado');
}

// Talle escrito a mano en el modal (cualquier valor, no solo los estándar).
function addCustomSize(pid) {
  const input = document.getElementById('modal-new-size');
  const talle = ((input && input.value) || '').trim();
  if (!talle) {
    toast('Escribí el talle que querés agregar', 'error');
    if (input) input.focus();
    return;
  }
  return addVariant(pid, talle);
}

// Suma fotos a un producto ya cargado. El endpoint recibe un archivo por vez,
// así que van de a una y se avisa el progreso: con fotos de celular y conexión
// del local, subir 5 puede tardar y sin feedback parece colgado.
async function uploadPhotos(pid, files) {
  const lista = Array.from(files || []);
  if (!lista.length) return;
  const hint = document.getElementById('modal-addphotos-hint');
  let ok = 0, fail = 0, ultimoError = '';
  for (let i = 0; i < lista.length; i++) {
    if (hint) hint.textContent = `Subiendo ${i + 1} de ${lista.length}…`;
    const fd = new FormData();
    fd.append('file', lista[i]);
    try {
      // Sin headers: el navegador pone el Content-Type con el boundary del
      // multipart. Si lo forzamos a mano, el backend no puede leer el archivo.
      await api(`/api/products/${pid}/images`, { method: 'POST', body: fd });
      ok++;
    } catch (e) {
      fail++;
      ultimoError = e.message;
    }
  }
  if (fail) {
    toast(`Subidas ${ok}, fallaron ${fail}. ${ultimoError}`.trim(), 'error');
  } else {
    toast(`✓ ${ok} foto${ok === 1 ? '' : 's'} agregada${ok === 1 ? '' : 's'}`, 'success');
  }
  PRODUCTS_CACHE = [];   // que la grilla tome la portada nueva
  openProduct(pid);      // recargar la galería (ya se pueden girar)
}

async function deleteVariant(pid, vid) {
  if (!confirm('¿Quitar este talle del producto? El stock que tenga se pierde.')) return;
  try {
    await api(`/api/variants/${pid}/${vid}`, { method: 'DELETE' });
    toast('✓ Talle quitado', 'success');
    PRODUCTS_CACHE = [];   // invalidar cache de la grilla
    openProduct(pid);      // refrescar el modal
  } catch (e) {
    toast('No se pudo quitar: ' + e.message, 'error');
  }
}

async function deleteProduct(pid) {
  if (!confirm('¿Eliminar este producto? Esta acción NO se puede deshacer.')) return;
  try {
    await api(`/api/products/${pid}`, { method: 'DELETE' });
    toast('✓ Producto eliminado', 'success');
    $('#modal').classList.add('hidden');
    loadProducts();
  } catch (e) {
    toast('Error al eliminar: ' + e.message, 'error');
  }
}

$('#modal-close').addEventListener('click', () => $('#modal').classList.add('hidden'));
$('.modal-backdrop').addEventListener('click', () => $('#modal').classList.add('hidden'));

// ============ Alta producto ============
// Las fotos se ACUMULAN en un array propio (el <input file> nativo reemplaza
// la selección en cada pick, así que no sirve para ir sumando de a tandas).
// Cada item = { file, rotation }. La primera es la portada.
let ALTA_FILES = [];

function setRotClass(img, deg) {
  img.classList.remove('rot-90', 'rot-180', 'rot-270');
  if (deg) img.classList.add('rot-' + deg);
}

function renderAltaPreviews() {
  const cont = $('#alta-previews');
  if (!ALTA_FILES.length) { cont.innerHTML = ''; return; }
  cont.innerHTML = ALTA_FILES.map((it, i) => `
    <div class="alta-thumb" data-idx="${i}">
      ${i === 0 ? '<span class="alta-cover">PORTADA</span>' : ''}
      <img alt="${escapeHtml(it.file.name)}">
      <button class="alta-remove" type="button" data-idx="${i}" title="Quitar foto">×</button>
      <button class="alta-rotate" type="button" data-idx="${i}" title="Rotar 90°">↻</button>
    </div>
  `).join('');
  cont.querySelectorAll('.alta-thumb').forEach(thumb => {
    const i = +thumb.dataset.idx;
    const img = thumb.querySelector('img');
    img.src = URL.createObjectURL(ALTA_FILES[i].file);
    setRotClass(img, ALTA_FILES[i].rotation);
    thumb.querySelector('.alta-rotate').addEventListener('click', () => {
      ALTA_FILES[i].rotation = (ALTA_FILES[i].rotation + 90) % 360;
      setRotClass(img, ALTA_FILES[i].rotation);
    });
    thumb.querySelector('.alta-remove').addEventListener('click', () => {
      ALTA_FILES.splice(i, 1);
      renderAltaPreviews();   // re-render para recalcular índices y portada
    });
  });
}

function clearAltaPreviews() {
  ALTA_FILES = [];
  $('#alta-previews').innerHTML = '';
}

$('#form-nuevo').elements.images.addEventListener('change', e => {
  // Sumar lo elegido a lo que ya había (acumular, no reemplazar)
  Array.from(e.target.files || []).forEach(f => ALTA_FILES.push({ file: f, rotation: 0 }));
  e.target.value = '';   // limpiar el input para poder re-elegir y no duplicar
  renderAltaPreviews();
});

$('#form-nuevo').addEventListener('submit', async e => {
  e.preventDefault();
  const form = e.target;
  const status = $('#alta-status');
  const submitBtn = form.querySelector('button[type=submit]');
  const fd = new FormData(form);

  // checkboxes en FormData: si no están tildados no van, hay que normalizar
  if (!form.publicado.checked) fd.set('publicado', 'false');
  else fd.set('publicado', 'true');
  if (!form.convertir_a_ars.checked) fd.set('convertir_a_ars', 'false');
  else fd.set('convertir_a_ars', 'true');

  // Imágenes: van desde nuestro array acumulado (no del input nativo, ya vacío)
  fd.delete('images');
  ALTA_FILES.forEach(it => fd.append('images', it.file, it.file.name));
  fd.set('rotations', ALTA_FILES.map(it => it.rotation).join(','));

  submitBtn.disabled = true;
  status.textContent = 'Creando producto + subiendo imágenes…';
  const result = $('#alta-result');
  result.classList.add('hidden');

  try {
    const r = await fetch(API + '/api/products', { method: 'POST', body: fd });
    const data = await r.json();
    if (!r.ok) throw new Error(data.detail || r.statusText);

    result.classList.remove('hidden');
    result.classList.remove('error');
    result.innerHTML = `
      <b>✓ Producto creado</b><br>
      ID interno: ${esc(data.product_id ?? data.tiendanube_id)}<br>
      Variantes creadas: ${esc(data.variantes_creadas)}<br>
      Imágenes subidas: ${data.imagenes_subidas}${data.imagenes_fallidas ? ` (${data.imagenes_fallidas} fallaron)` : ''}<br>
      <a href="${esc(data.url)}" target="_blank">Ver en la tienda ↗</a>
    `;
    status.textContent = '';
    form.reset();
    clearAltaPreviews();
    toast('✓ Producto creado', 'success');
    PRODUCTS_CACHE = []; // forzar recarga
  } catch (e) {
    result.classList.remove('hidden');
    result.classList.add('error');
    result.innerHTML = `<b>Error al crear:</b> ${esc(e.message)}`;
    status.textContent = '';
    toast('Error: ' + e.message, 'error');
  } finally {
    submitBtn.disabled = false;
  }
});

// ============ Pedidos ============
async function loadOrders() {
  const list = $('#orders-list');
  list.innerHTML = '<div class="loading">Cargando pedidos…</div>';
  try {
    const orders = await api('/api/orders?per_page=100');
    if (!orders.length) {
      list.innerHTML = '<div class="loading">Todavía no hay pedidos.</div>';
      return;
    }
    list.innerHTML = orders.map(o => {
      const customer = o.contact_name || '—';
      const email = o.contact_email || '';
      const fecha = o.created_at ? new Date(o.created_at).toLocaleDateString('es-AR') : '—';
      const status = o.payment_status || o.status || 'pending';
      const badge = status === 'paid' ? 'paid' : status === 'cancelled' ? 'cancelled' : 'pending';
      // Phone para WhatsApp link (puede venir en contact_phone o en shipping_address.phone)
      const phone = (o.contact_phone || (o.shipping_address && o.shipping_address.phone) || '').toString().replace(/[^0-9]/g, '');
      const orderNum = o.number || o.id;
      // Botón WhatsApp con template "coordinar_caba" pre-cargado
      const waBtn = phone
        ? `<button class="btn-ghost wa-btn" data-phone="${esc(phone)}" data-order="${esc(orderNum)}" data-name="${esc(customer)}" title="Abrir WhatsApp con plantilla">💬 WhatsApp</button>`
        : `<span style="color:#888;font-size:11px;">sin tel</span>`;
      // Dirección de envío: sin esto el pedido no se puede despachar.
      const d = o.shipping_address || {};
      const calle = [d.street, d.number].filter(Boolean).join(' ');
      const piso = d.floor ? `, ${d.floor}` : '';
      const loc = [d.city, d.province, d.zipcode].filter(Boolean).join(' · ');
      const envio = (calle || loc)
        ? `${esc(calle)}${esc(piso)}${calle && loc ? ' — ' : ''}${esc(loc)}`
        : '<span style="color:#888">sin dirección cargada</span>';
      const items = (o.products || [])
        .map(p => `${esc(p.name)}${p.sku ? ' (' + esc(p.sku) + ')' : ''} × ${esc(p.quantity)}`)
        .join('<br>') || '—';

      return `
        <div class="order-row" data-order-toggle="${esc(orderNum)}" style="cursor:pointer">
          <div class="num">#${esc(orderNum)}</div>
          <div class="customer">
            ${esc(customer)}
            <small>${esc(email)}</small>
          </div>
          <div>${esc(fecha)}</div>
          <div class="total">${fmtMoney(o.total)}</div>
          <div class="status"><span class="status-badge ${esc(badge)}">${esc(status)}</span></div>
          <div class="wa-cell">${waBtn}</div>
        </div>
        <div class="order-detail" data-order-detail="${esc(orderNum)}" hidden
             style="padding:14px 18px;margin:-6px 0 10px;background:#0d0d0d;
                    border-left:2px solid var(--gold,#b99b63);border-radius:0 8px 8px 0;
                    font-size:13px;color:#c9c4b8;line-height:1.7">
          <div><strong style="color:#f5f3ee">Enviar a:</strong> ${envio}</div>
          ${d.phone ? `<div><strong style="color:#f5f3ee">Tel:</strong> ${esc(d.phone)}</div>` : ''}
          <div style="margin-top:8px"><strong style="color:#f5f3ee">Productos:</strong><br>${items}</div>
        </div>
      `;
    }).join('');

    // Wire WhatsApp buttons (event delegation seria mejor, pero ok asi)
    list.querySelectorAll('.wa-btn').forEach(btn => {
      btn.addEventListener('click', () => openWhatsappForOrder({
        phone: btn.dataset.phone,
        order: btn.dataset.order,
        name: btn.dataset.name,
      }));
    });
  } catch (e) {
    list.innerHTML = '<div class="loading">Error: ' + esc(e.message) + '</div>';
  }
}

$('#btn-refresh-orders').addEventListener('click', loadOrders);

// Verifica contra Stripe si los pedidos "pendientes" ya fueron cobrados.
// Necesario cuando el webhook no llega: sin esto la plata entra y el pedido
// queda pendiente para siempre.
$('#btn-reconciliar')?.addEventListener('click', async () => {
  const btn = $('#btn-reconciliar');
  const est = $('#reconciliar-status');
  btn.disabled = true; btn.textContent = 'Consultando a Stripe…';
  est.textContent = '';
  try {
    const r = await api('/api/orders/reconciliar', { method: 'POST' });
    const ac = r.acreditados || [];
    const partes = [`Revisados: ${r.revisados}`, `acreditados: ${ac.length}`];
    if ((r.sin_pagar || []).length) partes.push(`sin pagar: ${r.sin_pagar.length}`);
    if ((r.para_revisar || []).length) partes.push(`a revisar: ${r.para_revisar.length}`);
    if ((r.errores || []).length) partes.push(`errores: ${r.errores.length}`);
    est.textContent = partes.join(' · ');
    if (ac.length) {
      toast(`${ac.length} pedido(s) acreditado(s)`, 'success');
      est.textContent += ' — pedidos: ' + ac.map(a => '#' + esc(a.pedido)).join(', ');
    } else {
      toast('No había pagos pendientes de acreditar', '');
    }
    loadOrders();
  } catch (e) {
    est.textContent = '';
    toast('Error: ' + e.message, 'error');
  } finally {
    btn.disabled = false; btn.textContent = 'Verificar pagos pendientes';
  }
});

// ============ WhatsApp helpers (usado desde Pedidos) ============
let WA_TEMPLATES_CACHE = null;
async function ensureTemplatesLoaded() {
  if (WA_TEMPLATES_CACHE) return WA_TEMPLATES_CACHE;
  try {
    WA_TEMPLATES_CACHE = await api('/api/whatsapp_templates');
  } catch (e) {
    WA_TEMPLATES_CACHE = {};
  }
  return WA_TEMPLATES_CACHE;
}

async function openWhatsappForOrder({ phone, order, name }) {
  const tpls = await ensureTemplatesLoaded();
  // Por defecto usamos "coordinar_caba". Si el usuario quiere elegir otra,
  // se puede agregar un menu desplegable, por ahora siempre coordinar.
  const tpl = tpls.coordinar_caba || 'Hola {name}, te aviso por tu pedido #{order}.';
  const txt = tpl.replace(/{name}/g, name || '').replace(/{order}/g, order || '');
  window.open(`https://wa.me/${phone}?text=${encodeURIComponent(txt)}`, '_blank');
}

// ============ Precios USD ============
async function loadUsdPrices() {
  try {
    const [data, products] = await Promise.all([
      api('/api/usd_prices'),
      PRODUCTS_CACHE.length ? Promise.resolve(PRODUCTS_CACHE) : api('/api/products/all'),
    ]);
    PRODUCTS_CACHE = products;
    const prices = data.prices || {};
    const rate = data.rate || 1410;
    $('#usd-rate-input').value = rate;
    $('#usd-rate-current').textContent = '$ ' + fmtNum(rate);

    const listEl = $('#usd-prices-list');
    if (!products.length) {
      listEl.innerHTML = '<div class="loading">Sin productos cargados.</div>';
      return;
    }
    listEl.innerHTML = `
      <table style="width:100%;border-collapse:collapse;">
        <thead>
          <tr style="border-bottom:1px solid #333;">
            <th style="text-align:left;padding:8px 4px;">Producto</th>
            <th style="text-align:left;padding:8px 4px;">Marca</th>
            <th style="text-align:right;padding:8px 4px;">USD</th>
            <th style="text-align:right;padding:8px 4px;">ARS calculado</th>
          </tr>
        </thead>
        <tbody>
          ${products.map(p => {
            const nm = typeof p.name === 'object' ? (p.name.es || '') : (p.name || '');
            const pid = String(p.id);
            const usd = prices[pid] || '';
            const arsCalc = usd ? fmtMoney(Number(usd) * rate) : '—';
            return `<tr style="border-bottom:1px solid #1f1f1f;">
              <td style="padding:8px 4px;">${esc(nm)}</td>
              <td style="padding:8px 4px;color:#888;font-size:13px;">${esc(p.brand || '—')}</td>
              <td style="padding:8px 4px;text-align:right;">
                <input type="number" step="0.01" data-pid="${esc(pid)}" value="${esc(usd)}" style="width:90px;text-align:right;" class="usd-input"/>
              </td>
              <td style="padding:8px 4px;text-align:right;color:#888;" data-ars="${esc(pid)}">${esc(arsCalc)}</td>
            </tr>`;
          }).join('')}
        </tbody>
      </table>
    `;

    // Live update ARS column al editar USD
    listEl.querySelectorAll('.usd-input').forEach(inp => {
      inp.addEventListener('input', () => {
        const pid = inp.dataset.pid;
        const usd = parseFloat(inp.value) || 0;
        const arsCell = listEl.querySelector(`[data-ars="${pid}"]`);
        if (arsCell) arsCell.textContent = usd ? fmtMoney(usd * rate) : '—';
      });
    });
  } catch (e) {
    $('#usd-prices-list').innerHTML = '<div class="loading">Error: ' + esc(e.message) + '</div>';
  }
}

$('#btn-refresh-usd')?.addEventListener('click', loadUsdPrices);

$('#btn-save-rate')?.addEventListener('click', async () => {
  const rate = parseFloat($('#usd-rate-input').value);
  if (!rate || rate <= 0) return toast('Cotización inválida', 'error');
  try {
    // A /api/usd_prices, NO a /api/bot_config: la cotización tiene que quedar
    // en la base, que es de donde la lee el recálculo de precios.
    await api('/api/usd_prices', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ rate }),
    });
    toast('Cotización guardada: $' + fmtNum(rate), 'success');
    loadUsdPrices();
  } catch (e) { toast('Error: ' + e.message, 'error'); }
});

$('#btn-seed-usd')?.addEventListener('click', async () => {
  if (!confirm('Esto va a leer los precios en pesos actuales y dividirlos por la cotización para guardar el USD equivalente. ¿Seguir?')) return;
  $('#usd-action-status').textContent = '⏳ Inicializando...';
  try {
    const r = await api('/api/usd_prices/from_current', { method: 'POST' });
    $('#usd-action-status').textContent = `✓ Listo. ${r.count} productos con USD asignado (cotización $${fmtNum(r.rate)}).`;
    toast('USD prices inicializados desde ARS actual', 'success');
    loadUsdPrices();
  } catch (e) {
    $('#usd-action-status').textContent = '✗ Error: ' + e.message;
    toast('Error: ' + e.message, 'error');
  }
});

$('#btn-sync-usd')?.addEventListener('click', async () => {
  // Primero guardar los cambios pendientes en la tabla
  const inputs = document.querySelectorAll('#usd-prices-list .usd-input');
  const prices = {};
  inputs.forEach(inp => {
    const v = parseFloat(inp.value);
    if (v > 0) prices[inp.dataset.pid] = v;
  });
  if (!Object.keys(prices).length) return toast('No hay USD prices para sincronizar', 'error');
  if (!confirm(`Esto va a SUBIR ${Object.keys(prices).length} precios ARS a Tiendanube (USD × cotización). ¿Confirmar?`)) return;

  $('#usd-action-status').textContent = '⏳ Recalculando precios…';
  try {
    await api('/api/usd_prices', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prices }),
    });
    const r = await api('/api/usd_prices/sync_to_tiendanube', { method: 'POST' });
    $('#usd-action-status').textContent = `✓ ${r.updated_products} productos · ${r.updated_variants} variantes actualizadas (cotización $${fmtNum(r.rate)}).`;
    toast('Precios actualizados en la tienda', 'success');
  } catch (e) {
    $('#usd-action-status').textContent = '✗ Error: ' + e.message;
    toast('Error: ' + e.message, 'error');
  }
});

// ============ WhatsApp Templates editor ============
const WA_LABELS = {
  coordinar_caba: '🚚 Coordinar entrega CABA / GBA',
  salida_camino: '🛵 Aviso "Salí en camino"',
  entregado: '✅ Confirmación de entrega',
  post_venta: '⭐ Follow-up post-venta',
  tracking_correo: '📦 Tracking del correo',
};

async function loadWaTemplates() {
  try {
    WA_TEMPLATES_CACHE = await api('/api/whatsapp_templates');
    const cnt = $('#wa-templates-container');
    cnt.innerHTML = Object.entries(WA_TEMPLATES_CACHE).map(([key, val]) => `
      <div class="form-card">
        <label>
          <b>${esc(WA_LABELS[key] || key)}</b>
          <textarea data-wa-key="${esc(key)}" rows="5">${esc(val)}</textarea>
        </label>
      </div>
    `).join('');
  } catch (e) {
    $('#wa-templates-container').innerHTML = '<div class="loading">Error: ' + esc(e.message) + '</div>';
  }
}

$('#btn-save-wa')?.addEventListener('click', async () => {
  const body = {};
  document.querySelectorAll('[data-wa-key]').forEach(t => { body[t.dataset.waKey] = t.value; });
  try {
    await api('/api/whatsapp_templates', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    WA_TEMPLATES_CACHE = body;
    toast('Plantillas guardadas', 'success');
  } catch (e) { toast('Error: ' + e.message, 'error'); }
});



// ============ Acciones ============
$('#btn-redeploy-bot')?.addEventListener('click', async () => {
  const status = $('#redeploy-status');
  status.textContent = '⏳ Disparando redeploy...';
  try {
    const r = await api('/api/actions/redeploy_bot', { method: 'POST' });
    if (r.ok) {
      status.textContent = `✓ Redeploy disparado (HTTP ${r.status}). Esperá ~3 min y verificá en Render dashboard.`;
      toast('Redeploy disparado', 'success');
    } else {
      status.textContent = '✗ ' + (r.error || 'unknown');
      toast('Error: ' + (r.error || 'unknown'), 'error');
    }
  } catch (e) {
    status.textContent = '✗ Error: ' + e.message;
    toast('Error: ' + e.message, 'error');
  }
});

// ============ Estadísticas detalle ============
async function loadStatsDetail() {
  try {
    const s = await api('/api/stats');
    const grid = $('#stats-grid');
    grid.innerHTML = `
      <div class="kpi-card">
        <div class="kpi-label">Total productos</div>
        <div class="kpi-value">${fmtNum(s.productos.total)}</div>
        <div class="kpi-sub">${s.productos.publicados} publicados</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Total variantes</div>
        <div class="kpi-value">${fmtNum(s.productos.variantes)}</div>
        <div class="kpi-sub">talles + SKUs</div>
      </div>
      <div class="kpi-card kpi-success">
        <div class="kpi-label">Pedidos pagados</div>
        <div class="kpi-value">${fmtNum(s.pedidos.pagados)}</div>
        <div class="kpi-sub">de ${s.pedidos.total} totales</div>
      </div>
      <div class="kpi-card kpi-warn">
        <div class="kpi-label">Pedidos pendientes</div>
        <div class="kpi-value">${fmtNum(s.pedidos.pendientes)}</div>
        <div class="kpi-sub">a procesar</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Ticket promedio</div>
        <div class="kpi-value">${fmtMoney(s.pedidos.ticket_promedio)}</div>
        <div class="kpi-sub">por pedido</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Stock total</div>
        <div class="kpi-value">${fmtNum(s.productos.stock_total)}</div>
        <div class="kpi-sub">unidades en catálogo</div>
      </div>
    `;
  } catch (e) {
    toast('Error: ' + e.message, 'error');
  }
}

$('#btn-refresh-stats2').addEventListener('click', loadStatsDetail);

// ============ Exportar Excel ============
$('#btn-export').addEventListener('click', () => {
  toast('Generando Excel… (puede tardar 10-30 seg)');
  window.location.href = '/api/export/excel';
});


// ============ Activación del segundo factor (MFA) ============
// El panel exige TOTP: sin activarlo, todos los endpoints responden 403. Esta
// pantalla es la única salida de ese estado.
async function abrirSetupMfa() {
  if (MFA_ABIERTO) return;
  MFA_ABIERTO = true;
  const caja = $('#mfa-setup');
  if (!caja) { window.location.href = '/login'; return; }
  caja.hidden = false;
  caja.style.display = 'flex';   // el display se aplica ACÁ, no en el HTML

  try {
    const r = await fetch('/api/auth/totp/setup', { method: 'POST' });
    if (!r.ok) throw new Error('No se pudo iniciar la configuración');
    const d = await r.json();
    $('#mfa-secret').textContent = d.secret || '';
    // El SVG lo genera el backend; es contenido propio, no entrada de usuario.
    $('#mfa-qr').innerHTML = d.qr_svg || '<span style="color:#555">Cargá la clave a mano</span>';
    $('#mfa-code').focus();
  } catch (e) {
    $('#mfa-err').textContent = e.message;
  }
}

$('#mfa-confirm')?.addEventListener('click', async () => {
  const code = ($('#mfa-code').value || '').trim();
  const err = $('#mfa-err');
  err.textContent = '';
  if (!/^\d{6}$/.test(code)) { err.textContent = 'Ingresá los 6 dígitos.'; return; }
  const btn = $('#mfa-confirm');
  btn.disabled = true; btn.textContent = 'Activando…';
  try {
    const r = await fetch('/api/auth/totp/enable', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ totp_code: code }),
    });
    const d = await r.json().catch(() => ({}));
    if (!r.ok) throw new Error(d.detail || 'Código inválido');
    window.location.reload();          // ya con MFA activo, el panel carga
  } catch (e) {
    err.textContent = e.message;
    btn.disabled = false; btn.textContent = 'Activar y entrar';
  }
});

$('#mfa-code')?.addEventListener('keydown', e => {
  if (e.key === 'Enter') $('#mfa-confirm').click();
});

// ============ Cerrar sesión ============
$('#btn-logout')?.addEventListener('click', async () => {
  try { await fetch('/api/auth/logout', { method: 'POST' }); } catch (e) { /* igual salimos */ }
  window.location.href = '/login';
});

// ============ Init ============
// Si la URL no trae hash, arrancamos en #dashboard (deja la URL prolija).
if (!location.hash) {
  history.replaceState(null, '', '#' + currentTabFromHash());
}

// Cargar los datos de la tienda ANTES de pintar (los links de producto los
// necesitan). Si falla, se sigue con los valores por defecto.
(async () => {
  try {
    STORE = { ...STORE, ...(await api('/api/store')) };
    const link = $('#link-tienda');
    if (link && STORE.url) link.href = STORE.url;
  } catch (e) { /* el panel funciona igual sin esto */ }
  activateTab(currentTabFromHash());
})();


// ============ Delegacion de eventos ============
// Los handlers NO van inline (onclick="..."): eso exigiria 'unsafe-inline' en
// script-src y anularia la CSP como defensa contra XSS. Se delega desde
// document, asi funciona igual para el HTML que se genera despues.
document.addEventListener('click', ev => {
  const t = ev.target;

  // Las tarjetas de producto se manejan con listener directo (ver
  // renderProducts): más confiable en tablet. Acá NO se duplica.

  const adj = t.closest('[data-adjust]');
  if (adj) return adjustStock(Number(adj.dataset.pid), Number(adj.dataset.vid),
                              Number(adj.dataset.adjust));

  const addv = t.closest('[data-add-variant]');
  if (addv) return addVariant(Number(addv.dataset.addVariant), addv.dataset.size);

  const addc = t.closest('[data-add-custom-size]');
  if (addc) return addCustomSize(Number(addc.dataset.addCustomSize));

  // El input de archivos está fuera de pantalla: lo abre este botón.
  const pick = t.closest('[data-pick-photos]');
  if (pick) {
    const inp = document.getElementById('modal-add-photos');
    if (inp) inp.click();
    return;
  }

  const delv = t.closest('[data-del-variant]');
  if (delv) return deleteVariant(Number(delv.dataset.pid), Number(delv.dataset.delVariant));

  const rot = t.closest('[data-rotate-preview]');
  if (rot) return rotatePreview(Number(rot.dataset.rotatePreview));

  const app = t.closest('[data-apply-rotate]');
  if (app) return applyRotate(Number(app.dataset.pid), Number(app.dataset.applyRotate));

  const cover = t.closest('[data-make-cover]');
  if (cover) return makeCover(Number(cover.dataset.pid), Number(cover.dataset.makeCover));

  const mov = t.closest('[data-move-img]');
  if (mov) return moveImage(Number(mov.dataset.pid), Number(mov.dataset.moveImg),
                            Number(mov.dataset.dir));

  const dimg = t.closest('[data-del-img]');
  if (dimg) return deleteImage(Number(dimg.dataset.pid), Number(dimg.dataset.delImg));

  const info = t.closest('[data-save-info]');
  if (info) return saveProductInfo(Number(info.dataset.saveInfo));

  const sst = t.closest('[data-save-stock]');
  if (sst) return saveAllStock(Number(sst.dataset.saveStock));

  const del = t.closest('[data-delete-product]');
  if (del) return deleteProduct(Number(del.dataset.deleteProduct));

  const open = t.closest('[data-open-url]');
  if (open) return window.open(open.dataset.openUrl, '_blank');

  // Desplegar el detalle del pedido (dirección de envío y productos).
  // El botón de WhatsApp está adentro de la fila: no debe abrir el detalle.
  const fila = t.closest('[data-order-toggle]');
  if (fila && !t.closest('.wa-btn')) {
    const det = document.querySelector(
      `[data-order-detail="${CSS.escape(fila.dataset.orderToggle)}"]`);
    if (det) det.hidden = !det.hidden;
  }
});

// Elegir fotos para un producto ya cargado (el input se re-crea con el modal,
// por eso también va delegado: `change` burbujea hasta document).
document.addEventListener('change', ev => {
  const up = ev.target.closest && ev.target.closest('[data-upload-photos]');
  if (!up) return;
  const pid = Number(up.dataset.uploadPhotos);
  // Copiar la lista ANTES de limpiar el input: `up.files` es una lista viva y
  // al hacer `value = ''` se vacía, así que la subida se quedaba sin archivos
  // y no pasaba nada. El input se limpia igual para poder volver a elegir la
  // misma foto si alguna falló.
  const files = Array.from(up.files || []);
  up.value = '';
  uploadPhotos(pid, files);
});

// Enter en el campo de talle libre = tocar "Agregar talle".
document.addEventListener('keydown', ev => {
  if (ev.key !== 'Enter') return;
  const inp = ev.target.closest && ev.target.closest('[data-new-size-for]');
  if (!inp) return;
  ev.preventDefault();
  addCustomSize(Number(inp.dataset.newSizeFor));
});

// ============ Vender en el local (punto de venta) ============
// Arma una venta desde la tablet y la cobra con un QR: el cliente escanea y
// paga con su celular. El cobro entra por la misma cuenta de Stripe que la
// tienda online, y la venta queda como un pedido más.
let POS_CARRITO = [];        // [{variant_id, nombre, talle, precio, stock, cantidad}]
let POS_CATALOGO = [];
let POS_VENTA = null;        // venta en curso mientras se espera el pago
let POS_POLL = null;

function posMoney(n) {
  return '$ ' + Math.round(n).toLocaleString('es-AR');
}

async function posBuscar(q) {
  const cont = $('#pos-resultados');
  try {
    const r = await api('/api/pos/buscar?q=' + encodeURIComponent(q || ''));
    POS_CATALOGO = r.productos || [];
    posRenderCatalogo();
  } catch (e) {
    cont.innerHTML = '<div class="loading">Error: ' + esc(e.message) + '</div>';
  }
}

function posRenderCatalogo() {
  const cont = $('#pos-resultados');
  if (!POS_CATALOGO.length) {
    cont.innerHTML = '<div class="loading">No hay productos con stock para vender.</div>';
    return;
  }
  cont.innerHTML = POS_CATALOGO.map(p => `
    <div class="pos-card">
      <div class="pos-card__img">
        ${p.imagen ? `<img src="${esc(p.imagen)}" alt="" loading="lazy">` : '<span>Sin foto</span>'}
      </div>
      <div class="pos-card__info">
        <div class="pos-card__marca">${esc(p.marca)}</div>
        <div class="pos-card__nombre">${esc(p.nombre)}</div>
        <div class="pos-card__talles">
          ${p.variantes.map(v => `
            <button type="button" class="pos-talle" data-add="${Number(v.variant_id)}"
                    title="${esc(v.talle)} - ${v.stock} en stock">
              <span>${esc(v.talle)}</span>
              <small>${posMoney(parseFloat(v.precio))}</small>
            </button>`).join('')}
        </div>
      </div>
    </div>
  `).join('');
}

function posAgregar(vid) {
  let datos = null;
  for (const p of POS_CATALOGO) {
    const v = (p.variantes || []).find(x => x.variant_id === vid);
    if (v) { datos = { p, v }; break; }
  }
  if (!datos) return;
  const existente = POS_CARRITO.find(i => i.variant_id === vid);
  const enCarrito = existente ? existente.cantidad : 0;
  if (enCarrito + 1 > datos.v.stock) {
    return toast(`Solo quedan ${datos.v.stock} de ${datos.p.nombre} (${datos.v.talle})`, 'error');
  }
  if (existente) existente.cantidad++;
  else POS_CARRITO.push({
    variant_id: vid, nombre: datos.p.nombre, talle: datos.v.talle,
    precio: parseFloat(datos.v.precio), stock: datos.v.stock, cantidad: 1,
  });
  posRenderCarrito();
}

function posCambiar(clave, delta) {
  const it = POS_CARRITO.find(i => posClave(i) === clave);
  if (!it) return;
  const nueva = it.cantidad + delta;
  if (nueva < 1) { POS_CARRITO = POS_CARRITO.filter(i => posClave(i) !== clave); }
  else if (!it.libre && nueva > it.stock) { return toast(`Solo quedan ${it.stock}`, 'error'); }
  else if (nueva > 99) { return toast('Máximo 99 por ítem', 'error'); }
  else { it.cantidad = nueva; }
  posRenderCarrito();
}

// Clave estable de cada línea: los sueltos no tienen variant_id, así que
// necesitan su propio identificador para poder sumarles o quitarles unidades.
function posClave(i) {
  return i.libre ? 'L' + i.uid : 'V' + i.variant_id;
}

function posRenderCarrito() {
  const cont = $('#pos-items');
  const total = POS_CARRITO.reduce((a, i) => a + i.precio * i.cantidad, 0);
  $('#pos-total').textContent = posMoney(total);
  $('#pos-cobrar').disabled = POS_CARRITO.length === 0;

  if (!POS_CARRITO.length) {
    cont.innerHTML = '<p class="pos-vacio">Tocá un producto para agregarlo.</p>';
    return;
  }
  cont.innerHTML = POS_CARRITO.map(i => `
    <div class="pos-item">
      <div class="pos-item__txt">
        <div class="pos-item__nombre">${esc(i.nombre)}${i.libre ? '<span class="pos-item__libre">suelto</span>' : ''}</div>
        <div class="pos-item__talle">${i.libre ? '' : 'Talle ' + esc(i.talle) + ' · '}${posMoney(i.precio)}</div>
      </div>
      <div class="pos-item__qty">
        <button type="button" data-qty="${esc(posClave(i))}" data-delta="-1">−</button>
        <span>${i.cantidad}</span>
        <button type="button" data-qty="${esc(posClave(i))}" data-delta="1">+</button>
      </div>
      <div class="pos-item__sub">${posMoney(i.precio * i.cantidad)}</div>
    </div>
  `).join('');
}

function posVaciar() {
  POS_CARRITO = [];
  $('#pos-cliente').value = '';
  $('#pos-telefono').value = '';
  posRenderCarrito();
}

async function posCobrar() {
  const cliente = ($('#pos-cliente').value || '').trim();
  if (!cliente) { $('#pos-cliente').focus(); return toast('Poné el nombre del cliente', 'error'); }
  if (!POS_CARRITO.length) return;

  const btn = $('#pos-cobrar');
  btn.disabled = true; btn.textContent = 'Generando cobro…';
  try {
    const r = await api('/api/pos/venta', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        cliente,
        telefono: ($('#pos-telefono').value || '').trim(),
        items: POS_CARRITO.map(i => (i.libre
          ? { libre: true, nombre: i.nombre, precio: i.precio, cantidad: i.cantidad }
          : { variant_id: i.variant_id, cantidad: i.cantidad })),
      }),
    });
    POS_VENTA = r;
    // El SVG del QR lo genera nuestro backend: es contenido propio.
    $('#pos-qr').innerHTML = r.qr_svg || '';
    $('#pos-cobro-total').textContent = posMoney(parseFloat(r.total));
    $('#pos-link').href = r.url_pago;
    $('#pos-cobro-espera').hidden = false;
    $('#pos-cobro-ok').hidden = true;
    const modal = $('#pos-modal-cobro');
    modal.hidden = false; modal.style.display = 'flex';
    posEsperarPago(r.order_id);
  } catch (e) {
    toast('No se pudo generar el cobro: ' + e.message, 'error');
  } finally {
    btn.disabled = POS_CARRITO.length === 0;
    btn.textContent = 'Cobrar';
  }
}

function posEsperarPago(oid) {
  clearInterval(POS_POLL);
  POS_POLL = setInterval(async () => {
    try {
      const e = await api(`/api/pos/venta/${oid}/estado`);
      if (e.pagado) {
        clearInterval(POS_POLL);
        $('#pos-cobro-espera').hidden = true;
        $('#pos-cobro-ok').hidden = false;
        toast('Pago recibido', 'success');
        POS_CARRITO = [];
        posRenderCarrito();
        PRODUCTS_CACHE = [];      // el stock cambió
      }
    } catch (err) { /* reintenta en el próximo tick */ }
  }, 3000);
}

function posCerrarCobro() {
  clearInterval(POS_POLL);
  const modal = $('#pos-modal-cobro');
  modal.hidden = true; modal.style.display = 'none';
  POS_VENTA = null;
  posBuscar($('#pos-buscar').value);   // refrescar stock
}

async function posCancelarVenta() {
  if (!POS_VENTA) return posCerrarCobro();
  if (!confirm('¿Cancelar esta venta? Se devuelve el stock reservado.')) return;
  try {
    await api(`/api/pos/venta/${POS_VENTA.order_id}/cancelar`, { method: 'POST' });
    toast('Venta cancelada', '');
    posVaciar();
  } catch (e) {
    toast('No se pudo cancelar: ' + e.message, 'error');
  }
  posCerrarCobro();
}

// --- eventos ---
let posDebounce;
$('#pos-buscar')?.addEventListener('input', e => {
  clearTimeout(posDebounce);
  const q = e.target.value;
  posDebounce = setTimeout(() => posBuscar(q), 250);
});
$('#pos-cobrar')?.addEventListener('click', posCobrar);
$('#pos-vaciar')?.addEventListener('click', posVaciar);
$('#pos-cerrar-cobro')?.addEventListener('click', posCerrarCobro);
$('#pos-nueva-venta')?.addEventListener('click', posCerrarCobro);
$('#pos-cancelar-venta')?.addEventListener('click', posCancelarVenta);

document.addEventListener('click', ev => {
  const add = ev.target.closest('[data-add]');
  if (add) return posAgregar(Number(add.dataset.add));
  const qty = ev.target.closest('[data-qty]');
  if (qty) return posCambiar(qty.dataset.qty, Number(qty.dataset.delta));
});


// --- Ítem suelto: cobrar algo que no está en el catálogo ---
let POS_UID = 0;

function posAbrirLibre(abrir) {
  const caja = $('#pos-libre');
  caja.hidden = !abrir;
  if (abrir) $('#pos-libre-nombre').focus();
  else { $('#pos-libre-nombre').value = ''; $('#pos-libre-precio').value = ''; $('#pos-libre-cant').value = '1'; }
}

function posAgregarLibre() {
  const nombre = ($('#pos-libre-nombre').value || '').trim();
  const precio = parseFloat($('#pos-libre-precio').value);
  const cant = parseInt($('#pos-libre-cant').value) || 1;

  if (!nombre) { $('#pos-libre-nombre').focus(); return toast('Poné qué se vende', 'error'); }
  if (!(precio > 0)) { $('#pos-libre-precio').focus(); return toast('Poné un precio válido', 'error'); }
  if (cant < 1 || cant > 99) return toast('Cantidad entre 1 y 99', 'error');

  POS_CARRITO.push({
    libre: true, uid: ++POS_UID, variant_id: null,
    nombre, talle: '', precio, stock: Infinity, cantidad: cant,
  });
  posRenderCarrito();
  posAbrirLibre(false);
  toast('Agregado a la venta', 'success');
}

$('#pos-abrir-libre')?.addEventListener('click', () => posAbrirLibre($('#pos-libre').hidden));
$('#pos-libre-cerrar')?.addEventListener('click', () => posAbrirLibre(false));
$('#pos-libre-agregar')?.addEventListener('click', posAgregarLibre);
// Enter en el precio agrega directamente: en el mostrador se busca velocidad.
$('#pos-libre-precio')?.addEventListener('keydown', e => {
  if (e.key === 'Enter') { e.preventDefault(); posAgregarLibre(); }
});
