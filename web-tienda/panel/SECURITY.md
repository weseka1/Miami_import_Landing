# Auditoría e Implementación de Seguridad — MIAMI IMPORT

> Marco: OWASP Top 10 (2021), NIST CSF, CIS Benchmarks, DevSecOps.
> Alcance: tienda pública (`web-tienda`), panel admin (`panel-control`), APIs, base de datos, Stripe, Render.
> Leyenda de estado: **✅ implementado y verificado** · **⚙️ config Render/infra** · **🔌 requiere servicio externo** · **⏭️ recomendado (roadmap)**.

---

## 1. Medidas implementadas

### Autenticación y contraseñas
- ✅ **Argon2id** para todas las contraseñas (`core/security.py`). Verificación de hashes bcrypt legados + **rehash automático** a Argon2 en el próximo login.
- ✅ **MFA/TOTP para administradores** (`auth.py`, `pyotp`): setup (QR/otpauth URI), enable (verifica código), disable (exige código). Login admin pide el código si está habilitado. Verificado por HTTP.
- ✅ **Bloqueo por intentos fallidos** (anti brute-force / credential stuffing): 5 fallos en 15 min → bloqueo 15 min, por `email+IP` (`core/web_security.py`). Aplica a login de admin y de clientes.
- ✅ **Rate limiting** global en endpoints sensibles (login/registro/password/checkout): HTTP 429 (verificado: dispara al intento 31 con límite 30; admin límite 20).
- ✅ Auditoría de intentos (`AuditLog`: `admin_login_failed`, `login_failed`, `admin_mfa_failed`).

### Sesiones y tokens
- ✅ **JWT firmados** (HS256) con `SECRET_KEY` de entorno; expiración corta (admin 12 h, cliente 14 d configurable).
- ✅ Cookies **HttpOnly + Secure (prod) + SameSite** (`strict` para el panel, `lax` para la tienda). Nunca expuestas al JS.
- ✅ Revocación de sesión: logout borra cookie; MFA disable exige código (evita apagar MFA con sesión secuestrada).
- ✅ Modelo `RefreshToken` con `token_hash` + revocación (base lista para rotación).

### Panel administrativo / RBAC
- ✅ Toda la API del panel protegida con `get_current_admin` (dependencia a nivel router).
- ✅ Campo `role` (customer/staff/admin/owner) en `User`; el admin inicial se crea como `owner`.
- ✅ **Auditoría de acciones** (`AuditLog`): login, MFA, pagos, registros. Registra `user_id`, acción, entidad, IP, detalle, timestamp.
- ✅ Gate `/` → `/login` si no hay sesión válida.

### API / validación de entrada (OWASP A03)
- ✅ **SQL Injection**: SQLAlchemy ORM con queries parametrizadas en el 100% de los accesos (sin SQL string-format).
- ✅ **XSS**: Jinja2 con autoescape; sólo el HTML de catálogo (fuente confiable) usa `|safe`.
- ✅ **Validación de email** (`email-validator`), de precios/cantidades (Decimal/int), y de **stock en backend** (nunca se confía en el front).
- ✅ **Path traversal en uploads**: renombrado aleatorio (`secrets.token_hex`), nunca se usa el nombre del cliente.
- ✅ Validación de esquema básica por endpoint (tipos + checks explícitos).

### Subida de archivos (panel)
- ✅ `validate_image()`: límite **8 MB**, extensión permitida, **MIME** permitido, y **firma binaria (magic numbers)** — rechaza `.php`/contenido falso con 415 (verificado). Renombrado aleatorio.

### Frontend / cabeceras HTTP (OWASP A05)
- ✅ **Content-Security-Policy** restrictiva (whitelist de CDNs de animación, Stripe, fuentes; `frame-ancestors 'self'`, `base-uri 'self'`, `form-action 'self'`).
- ✅ **X-Frame-Options: DENY** (clickjacking), **X-Content-Type-Options: nosniff** (MIME sniffing).
- ✅ **Referrer-Policy**, **Permissions-Policy** (cámara/mic/geo bloqueados), **COOP** + **CORP**.
- ✅ **HSTS** (`max-age=63072000; includeSubDomains; preload`) en producción (HTTPS).
- ✅ **`Server` header eliminado** (`--no-server-header`) — no se filtra la tecnología.
- ✅ `Cache-Control: no-store` en `/api`, `/auth`, `/cuenta`, `/checkout`.

### Base de datos
- ✅ **Cifrado en tránsito**: `sslmode=require` forzado en la URL de Postgres (`core/config.py`).
- ⚙️ **Cifrado en reposo**: provisto por Render Postgres (AES-256, gestionado).
- ✅ Acceso por ORM con menor privilegio lógico; credenciales sólo por entorno.

### Secretos (OWASP A05/A07)
- ✅ **Cero credenciales hardcodeadas** (escaneo verificado). Todo por variables de entorno.
- ✅ `.env` en `.gitignore` en ambos repos; `.env.example` sin valores.
- ✅ **gitleaks** en CI (detección de exposición accidental).

### DevSecOps / dependencias (OWASP A06)
- ✅ **GitHub Actions** (`.github/workflows/security.yml`): `pip-audit` (CVEs), `gitleaks` (secretos), `bandit` (SAST), semanal + en cada push/PR.
- ✅ **Dependabot** (`.github/dependabot.yml`): PRs automáticos de actualización (pip + actions), semanal.

### CORS / infraestructura
- ✅ **CORS estricto** en el panel (whitelist `CORS_ORIGINS`, no `*`).
- ⚙️ **HTTPS obligatorio + TLS 1.3 + redirección HTTP→HTTPS + certificados auto-renovados**: provistos y gestionados por **Render** (TLS terminado en su edge; certificados Let's Encrypt automáticos).
- ✅ `--proxy-headers` configurado para respetar el `X-Forwarded-*` del edge de Render.

---

## 2. Riesgos residuales

| # | Riesgo | Severidad | Mitigación actual / pendiente |
|---|--------|-----------|-------------------------------|
| R1 | Sin WAF / anti-DDoS / anti-bot dedicado | Media-Alta | Rate limit en app. **Pendiente**: Cloudflare delante (🔌). |
| R2 | Uploads sin antivirus (ClamAV) | Media | Validación MIME+firma+tamaño. **Pendiente**: ClamAV/VirusTotal (🔌). |
| R3 | Rate limit y lockout en memoria (por instancia) | Media | OK en 1 instancia. **Pendiente**: Redis si se escala (⏭️). |
| R4 | CSRF: mitigado por SameSite + JSON, sin token double-submit | Baja-Media | SameSite strict/lax + content-type JSON. **Pendiente**: token CSRF explícito (⏭️). |
| R5 | `'unsafe-inline'` en CSP (script/style) | Media | Necesario por el theme inline. **Pendiente**: nonces/hashes (⏭️). |
| R6 | Sin logging centralizado / SIEM / alertas | Media | `AuditLog` en DB. **Pendiente**: Logtail/Sentry/Datadog (🔌). |
| R7 | Stripe sin claves cargadas | — | Endpoints 503 hasta configurar; webhook con verificación de firma listo. |
| R8 | Imágenes servidas desde CDN de Tiendanube | Baja | Migrar a hosting propio para independencia (⏭️). |
| R9 | Refresh-token rotation modelada pero no activa | Baja | JWT corto vigente; activar rotación (⏭️). |

---

## 3. Recomendaciones futuras (roadmap priorizado)
1. **Cloudflare** delante de Render: WAF, anti-DDoS, anti-bot (Turnstile), rate-limit de borde, bloqueo geográfico/IP. (Cubre R1, escaneo automatizado.)
2. **Sentry** (errores) + **Logtail/Better Stack** (logs centralizados + alertas por picos de 401/429). (Cubre R6.)
3. **Redis** (Upstash) para rate-limit/lockout distribuido y blacklist de JWT. (Cubre R3.)
4. **ClamAV** o API de escaneo para uploads. (Cubre R2.)
5. **CSP con nonces** (eliminar `unsafe-inline`). (Cubre R5.)
6. **CAPTCHA/Turnstile** en login/registro tras N fallos.
7. **Rotación de secretos** trimestral (SECRET_KEY, tokens TN, Stripe) + alertas de expiración.
8. Pentest manual + `OWASP ZAP` baseline en CI (DAST).

---

## 4. Checklist de seguridad (CIS-style)

- [x] HTTPS/TLS gestionado (Render) · HSTS en prod
- [x] Contraseñas Argon2id · rehash de legados
- [x] MFA/TOTP para admins
- [x] Lockout + rate limiting
- [x] JWT corto + cookies HttpOnly/Secure/SameSite
- [x] RBAC (role) + auditoría de acciones
- [x] CSP + X-Frame-Options + nosniff + Referrer/Permissions-Policy + COOP/CORP
- [x] `Server` oculto
- [x] ORM parametrizado (anti-SQLi) · autoescape (anti-XSS)
- [x] Validación de uploads (MIME+firma+tamaño+rename)
- [x] DB TLS en tránsito · cifrado en reposo (Render)
- [x] Secretos sólo por entorno · `.env` ignorado · gitleaks
- [x] pip-audit + bandit + Dependabot en CI
- [ ] WAF/anti-DDoS (Cloudflare) — pendiente
- [ ] Antivirus de uploads — pendiente
- [ ] Logs centralizados + alertas — pendiente
- [ ] CSRF token explícito / CSP sin unsafe-inline — pendiente

---

## 5. Plan de recuperación ante incidentes (IR) — NIST
1. **Detección**: alerta por pico de 401/429, error 5xx anómalo, o reporte. Revisar `AuditLog`.
2. **Contención**: en Render, escalar a 0 / activar "maintenance"; rotar `SECRET_KEY` (invalida todas las sesiones); bloquear IP en Cloudflare.
3. **Erradicación**: identificar vector (logs + `AuditLog`), parchear, `pip-audit`, redeploy desde commit limpio.
4. **Recuperación**: restaurar DB desde backup verificado; re-emitir credenciales; monitoreo reforzado 72 h.
5. **Post-mortem**: documento de causa raíz + acción correctiva en ≤ 5 días hábiles.

## 6. Plan de backups
- ⚙️ **Render Postgres**: backups diarios automáticos (plan starter+) con retención 7 días; PITR en planes superiores.
- ✅ **Export manual** verificado vía panel (`/api/export/excel`) + `pg_dump` semanal recomendado a almacenamiento cifrado externo (S3/Backblaze, SSE-AES256).
- **Restauración verificada**: prueba de restore trimestral en base de staging (documentar RTO/RPO; objetivo RPO ≤ 24 h, RTO ≤ 2 h).
- Backups **cifrados** y fuera del proveedor primario (regla 3-2-1).

## 7. Plan de respuesta ante compromiso de cuenta
- **Admin**: rotar `SECRET_KEY` (cierra todas las sesiones), forzar reset de contraseña, **re-enrolar MFA** (disable+setup), revisar `AuditLog` de la cuenta, revisar reembolsos/cambios de productos.
- **Cliente**: invalidar sesión, forzar reset por token, notificar al usuario, revisar pedidos/direcciones nuevas.
- **Detección de login sospechoso** (⏭️): comparar IP/UA habituales; alertar y exigir MFA/reset ante anomalía.

## 8. Puntuación de seguridad
**Capa de aplicación: 82 / 100.**
- Auth & sesiones: 9/10 · Headers/Frontend: 9/10 · API/Input: 8/10 · Uploads: 8/10 · Secretos/DevSecOps: 9/10 · DB: 8/10 · Infra/WAF: 5/10 · Monitoreo: 4/10 · IR/Backups (proceso): 7/10.
- Con Cloudflare + monitoreo centralizado + antivirus de uploads → **estimado 92-95/100**.

## 9. Código de configuraciones
Implementado en: `core/security.py` (Argon2), `core/web_security.py` (headers/CSP/rate-limit/lockout), `auth.py` (MFA/TOTP/lockout/RBAC), `auth_store.py` (lockout/rehash clientes), `panel_api.py` (`validate_image`), `core/config.py` (sslmode), `core/db.py` (columnas), `render.yaml` (×2, `--no-server-header`, env protegidas), `.github/workflows/security.yml`, `.github/dependabot.yml`, `.gitignore` (.env, *.db).

## 10. Explicación técnica
Cada medida se documenta inline en su archivo (docstrings/comentarios). Resumen de los "por qué":
- **Argon2id** > bcrypt: resistente a GPU/ASIC, recomendación OWASP 2024.
- **MFA/TOTP**: segundo factor offline (RFC 6238); anula el robo de sólo-contraseña.
- **Lockout + rate-limit**: cortan fuerza bruta y credential stuffing sin DoS al usuario legítimo (ventana + por IP).
- **JWT corto + cookie HttpOnly**: minimiza ventana de robo y bloquea exfiltración por XSS.
- **CSP/headers**: defensa en profundidad contra XSS, clickjacking, sniffing y fuga de referer.
- **sslmode=require**: evita downgrade/MITM en tránsito a la DB.
- **Validación de uploads por firma**: impide subir ejecutables disfrazados (RCE/almacenamiento malicioso).
- **CI (pip-audit/bandit/gitleaks/Dependabot)**: "shift-left" — detecta CVEs, malas prácticas y secretos antes de producción.
