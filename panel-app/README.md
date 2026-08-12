# Panel MIAMI IMPORT (enlatado WESEKA)

Panel React (Vite + TS + Tailwind) del Stock Manager. En producción lo sirve el
MISMO FastAPI de la tienda desde `/panel` (ver `web-tienda/panel/app.py`), usando
el build commiteado en `dist/`. La API vive en `/panel/api/*` (cookie `mi_admin`).

## Desarrollo

```bash
npm install
npm run dev        # http://127.0.0.1:5173 — proxy /panel/api y /static → 127.0.0.1:8001
```

El backend tiene que estar corriendo en 127.0.0.1:8001 (ver `web-tienda/`).

## Rebuild para producción (IMPORTANTE: el dist/ va commiteado)

Render corre runtime Python (sin Node en el build), así que `dist/` se versiona.
Después de cualquier cambio en `src/`:

```powershell
$env:DEMO_BASE = "/panel/"     # base del build: el panel vive bajo /panel
npm run build                  # regenera dist/ (assets con hash)
# commitear dist/ junto con el cambio
```

Con base ≠ "/" el molde usa HashRouter automáticamente (`src/main.tsx`):
las rutas quedan `/panel/#/ingresar`, `/panel/#/panel`, etc. — no hace falta
rewrite del lado del server.

- Panel viejo (plan B): `/panel/legacy`
- Rebrandear el enlatado para otro cliente: `src/marca.ts` + `scripts/rebrandear.mjs`

## Checks antes de commitear

```bash
npx tsc --noEmit
npm run build
```
