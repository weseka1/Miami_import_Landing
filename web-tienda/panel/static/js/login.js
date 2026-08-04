// Login del panel.
//
// Vive en un archivo aparte (no inline en el HTML) porque la CSP del panel es
// estricta: script-src sin 'unsafe-inline'. Un <script> inline acá quedaba
// bloqueado por el navegador y el formulario no hacía absolutamente nada.

// Base del panel cuando se monta como sub-app (p.ej. "/panel"). Standalone = ''.
// La CSP estricta del panel no permite <script> inline, así que la base viaja
// como data-attribute del <html> que inyecta el backend.
const API = document.documentElement.getAttribute('data-panel-base') || '';

const form = document.getElementById('login-form');
const btn = document.getElementById('submit');
const err = document.getElementById('err');
const mfaWrap = document.getElementById('mfa-wrap');
const mfaInput = document.getElementById('totp_code');

function showMfa(msg) {
  mfaWrap.hidden = false;
  mfaInput.required = true;
  mfaInput.focus();
  err.textContent = msg || '';
}

form.addEventListener('submit', async (e) => {
  e.preventDefault();
  err.textContent = '';
  btn.disabled = true;
  btn.textContent = 'Ingresando…';

  const body = {
    email: document.getElementById('email').value,
    password: document.getElementById('password').value,
  };
  // Solo se manda si el server ya lo pidió (segundo paso).
  const code = (mfaInput.value || '').trim();
  if (code) body.totp_code = code;

  try {
    const r = await fetch(API + '/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const data = await r.json().catch(() => ({}));

    if (!r.ok) throw new Error(data.detail || 'Error de acceso');

    // El backend responde 200 con ok:false cuando falta el segundo factor.
    // Tratarlo como éxito dejaba al usuario en un bucle contra /login.
    if (data.ok === false && data.mfa_required) {
      showMfa('Ingresá el código de tu app de autenticación.');
      return;
    }
    if (data.ok !== true) throw new Error(data.detail || 'No se pudo ingresar');

    window.location.href = API + '/';
  } catch (ex) {
    err.textContent = ex.message;
  } finally {
    btn.disabled = false;
    btn.textContent = 'Ingresar';
  }
});
