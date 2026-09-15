# Miami Import: de Render al VPS de Hostinger

> Hecho el 15-sep-2026. Pedido de Juani: *"la web y el panel debemos llevar a
> hostinger, las automatizaciones y workflows borralo"*.
> **Lo que se mueve:** la tienda y el panel de Diego (stock, QR, pagos).
> **Lo que NO se mueve:** la base (sigue en Supabase) ni Stripe.

---

## Lo que ya está hecho

| Archivo | Para qué |
|---|---|
| `web-tienda/Dockerfile` | La imagen. Dos etapas: el compilador queda afuera de la imagen final |
| `web-tienda/.dockerignore` | Que no entre ningún `.env` ni la base local a la imagen |
| `.github/workflows/imagen-tienda.yml` | Reemplaza el auto-deploy de Render: cada push a `main` publica a ghcr.io |
| `deploy/miami-compose.yml` | El stack del VPS, con Traefik y SSL automático |

## La máquina

```
VPS      srv1972060.hstgr.cloud · 2.25.148.157 · KVM 2 · 2 vCPU · 8 GB · 100 GB
region   Boston (bos2)          ← la base está en Supabase São Paulo
traefik  corriendo, network_mode host, certresolver `letsencrypt`
n8n      corriendo (el del VPS, NO el de Render)
```

🔴 **Boston está más cerca de São Paulo que Oregon**: hoy son ~180 ms por consulta
contra la base; desde Boston, ~130-150. La migración mejora la tienda, no la empeora.

---

## Los pasos

### 1. Habilitar el VPS para bajar la imagen — UNA sola vez
La imagen es **privada** (hereda la visibilidad del repo). Dentro del VPS:
```bash
docker login ghcr.io -u <usuario-github> -p <PAT con read:packages>
```
📌 **Hace falta un PAT de GitHub.** Sin esto el `docker pull` da `denied`.

### 2. Publicar la primera imagen
Push a `main` tocando `web-tienda/`, o disparar el workflow a mano desde la pestaña
Actions. Verificar que aparezca en `ghcr.io/weseka1/miami_import_landing/tienda:latest`.

### 3. Levantarlo en un subdominio de PRUEBA
No se toca el DNS de `miamiimport.com.ar` todavía. Se usa un subdominio del VPS,
igual que n8n:
```
HOST_RULE = Host(`miami.srv1972060.hstgr.cloud`)
STORE_BASE_URL = https://miami.srv1972060.hstgr.cloud
PANEL_BASE_URL = https://miami.srv1972060.hstgr.cloud/panel
```
Se despliega con `VPS_createNewProjectV1` (proyecto `miami-tienda`), pasando el compose
como `content` y las **21 variables** como `environment`.

🔴 **Las 21 variables salen de Render y no pueden faltar ninguna.** Si falta una, el
síntoma suele ser mudo — es el mismo pozo de [[feedback_el_fallback_silencioso_borra_la_feature]].
Se leen con la API de Render (`services/<id>/env-vars`) y se pasan **sin que toquen git
ni un chat**.

Lista: `ANTHROPIC_API_KEY` · `CHECKOUT_CURRENCY` · `COOKIE_SECURE` · `DATABASE_URL` ·
`DEV_MODE` · `FAL_KEY` · `GEMINI_API_KEY` · `META_PIXEL_ID` · `PANEL_BASE_URL` ·
`SECRET_KEY` · `SMTP_PASS` · `SMTP_USER` · `STORE_BASE_URL` · `STRIPE_PUBLISHABLE_KEY` ·
`STRIPE_SECRET_KEY` · `STRIPE_WEBHOOK_SECRET` · `SUPABASE_BUCKET` ·
`SUPABASE_SECRET_KEY` · `SUPABASE_URL` · `TRYON_TOPE_DIARIO` · `USD_TO_ARS_RATE`

### 4. Probar contra el subdominio, ANTES de tocar el DNS
```bash
curl -sI https://miami.srv1972060.hstgr.cloud/health
python scripts/verificar_promo.py --url https://miami.srv1972060.hstgr.cloud
```
El verificador recorre una compra entera y exige que ficha, carrito y checkout digan el
mismo número. A mano, además:
- [ ] `/` y `/productos` cargan con fotos (Supabase Storage responde desde Boston)
- [ ] una ficha, agregar al carrito, `/checkout`
- [ ] **el panel**: `/panel/` entra, se ve el stock, se genera un QR, se ven los pagos
- [ ] el probador virtual (gasta plata: una prueba y basta)

### 5. Un pago de prueba REAL
🔴 El paso que no se puede saltear. Stripe es real.
- Cobrar un pedido de prueba de punta a punta.
- Confirmar que **el webhook llega** — es lo que acredita el pago. Mientras el webhook
  siga apuntando al dominio viejo, sigue entrando por Render; hay que agregar el
  endpoint nuevo en Stripe **antes** de mover el DNS, y dejar los dos un tiempo.

### 6. Recién ahora, el DNS
- `miamiimport.com.ar` es **.com.ar (NIC.ar)**: no se transfiere a Hostinger, se le
  cambian los registros.
- **Bajar el TTL a 300 s al menos 24 h antes.** Es lo que permite volver atrás en
  minutos en vez de en horas.
- Apuntar `@` y `www` a **2.25.148.157**.
- Cambiar `STORE_BASE_URL` y `PANEL_BASE_URL` al dominio real y redesplegar.
- Actualizar `HOST_RULE` para incluir el www:
  ```
  Host(`miamiimport.com.ar`) || Host(`www.miamiimport.com.ar`)
  ```
- Esperar el certificado de Let's Encrypt (necesita el DNS ya apuntando).

### 7. Render se deja PRENDIDO
🔴 No se baja `Miami_import_Landing` hasta que la tienda haya **cobrado un pedido real
desde Hostinger**. Cuesta USD 7 una semana más; volver atrás de un corte mal hecho
cuesta ventas.

---

## Lo que se apaga aparte (no depende de la migración)

| Servicio | USD/mes | Por qué |
|---|---|---|
| `WESEKA` (n8n en Render) | **25** | 2 workflows, los dos apagados, 0 ejecuciones, sin tocar desde el 16-jun. Ya hay n8n en el VPS. **Respaldados en `_CEREBRO/_respaldos/n8n_render_2026-09-15/`** |
| `Miami_import_Panel_2` | **7** | `/` vacío y `/panel/` devuelve `{"detail":"Not Found"}`. El panel real lo sirve Landing |

Son **USD 32/mes ≈ ARS 48.000**, más que el VPS entero (ARS 43.899).

📌 **`we-latam-factory`** (USD 7/mes, repo `yamilpintos/We-Latam_factory`) sigue activo
y facturando. **Falta que Juani diga si se apaga.**

---

Ver [[Migracion Render a Hostinger]] · [[Miami Import]]

---

## ⚠️ El workflow de GitHub Actions hay que subirlo A MANO

El PAT con el que se pushea **no tiene el scope `workflow`**, así que GitHub rechaza
cualquier push que cree o modifique algo en `.github/workflows/`:

```
! [remote rejected] main -> main (refusing to allow a Personal Access Token to
  create or update workflow `.github/workflows/imagen-tienda.yml` without
  `workflow` scope)
```

El archivo quedó en **`deploy/imagen-tienda.yml.PARA-COPIAR`**. Dos formas de activarlo:

1. **Por la web** (30 segundos, es lo más rápido): en el repo →
   *Add file → Create new file* → nombre `.github/workflows/imagen-tienda.yml` →
   pegar el contenido → commit.
2. **Regenerar el PAT** con el scope `workflow` marcado y pushear normal.

Hasta que el workflow exista, la imagen no se publica sola y hay que construirla a mano.
