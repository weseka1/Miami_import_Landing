# Despliegue en Render — MIAMI IMPORT

Dos servicios web (panel + tienda) sobre **una sola base Postgres** compartida.

## Arquitectura
- **miami-panel** (este repo `panel-control/`) → admin + dueño de la base. Crea la Postgres `miami-import-db`.
- **miami-tienda** (repo `web-tienda/`) → tienda pública. Se conecta a la MISMA base.

---

## Paso a paso

### 1. Crear el panel + la base (Blueprint)
1. Subí `panel-control/` a un repo de GitHub.
2. En Render → **New → Blueprint** → elegí ese repo. Detecta `render.yaml` y crea:
   - la base **miami-import-db** (Postgres),
   - el servicio **miami-panel**.
3. En **miami-panel → Environment** completá los secretos (`sync:false`):
   - `ADMIN_EMAIL`, `ADMIN_PASSWORD` (tu admin del panel),
   - `STORE_BASE_URL` = la URL pública de la tienda (ej. `https://miami-tienda.onrender.com`),
   - `PANEL_BASE_URL` = la URL del panel,
   - `CORS_ORIGINS` = `https://miami-tienda.onrender.com,https://miami-panel.onrender.com`,
   - `STRIPE_SECRET_KEY` (para reembolsos desde el panel).
4. Deploy. El panel crea las tablas solo al arrancar (`init_db`).

### 2. Cargar el catálogo en la base de producción
Desde tu PC, apuntá el migrador a la base de Render y corré la importación:

```bash
# Copiá la "External Database URL" de miami-import-db (dashboard de Render)
set DATABASE_URL=postgresql://...   # PowerShell: $env:DATABASE_URL="postgresql://..."
cd panel-control
.venv\Scripts\python migrate_from_tiendanube.py            # backup JSON local
#  o  .venv\Scripts\python migrate_from_tiendanube.py --live   (API de Tiendanube)
```

> Las imágenes hoy se sirven del CDN de Tiendanube. Para independencia total,
> corré el migrador SIN `--skip-images` (baja las fotos a `web-tienda/static/products/`)
> y commiteá esa carpeta, o subilas a un bucket/CDN propio.

### 3. Crear la tienda
1. Subí `web-tienda/` a otro repo de GitHub.
2. Render → **New → Blueprint** → ese repo (usa `web-tienda/render.yaml`).
3. En **miami-tienda → Environment**:
   - `DATABASE_URL` = **Internal Database URL** de `miami-import-db` (la MISMA base del panel),
   - `STORE_BASE_URL`, `PANEL_BASE_URL`,
   - `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`, `STRIPE_WEBHOOK_SECRET`,
   - `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` (opcional, login con Google).
4. Deploy.

### 4. Stripe
- Dashboard de Stripe → **Developers → Webhooks → Add endpoint**:
  `https://miami-tienda.onrender.com/api/stripe/webhook`
  Eventos: `payment_intent.succeeded`, `payment_intent.payment_failed`.
  Copiá el **Signing secret** a `STRIPE_WEBHOOK_SECRET`.
- Probá con tarjeta de test `4242 4242 4242 4242`.

### 5. Google OAuth (opcional)
- Google Cloud Console → OAuth client (Web). Redirect URI:
  `https://miami-tienda.onrender.com/auth/google/callback`.
- Cargá `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` en miami-tienda.

### 6. Dominio propio
- Apuntá tu dominio a la tienda (Render → Custom Domains).
- Actualizá `STORE_BASE_URL` y la redirect URI de Google al dominio final.

---

## Notas de producción
- `DEV_MODE=false` y `COOKIE_SECURE=true` en ambos servicios (cookies sobre HTTPS).
- `SECRET_KEY` se autogenera por servicio (cada uno firma sus propios JWT).
- El plan free de Render duerme por inactividad; para tienda real usá `starter`.
- Seguridad activa: headers/CSP, HSTS (en prod), rate limiting en login/registro/checkout.
