# ============================================================================
#  MIAMI IMPORT — imagen de la tienda + el panel de Diego
# ============================================================================
#  Un solo proceso sirve las dos cosas: la tienda en `/` y el panel en
#  `/panel/` (el `dist` del panel React va commiteado y se sirve tal cual).
#
#  Se construye en DOS etapas a propósito: `libsass` y `argon2-cffi` compilan
#  al instalarse y necesitan gcc. Si eso viviera en la imagen final, la imagen
#  quedaría con un compilador adentro corriendo en producción y pesando de más.
#  Acá el compilador queda en la etapa `builder` y se tira.
#
#  🔴 La versión de Python NO es decorativa: Render corre 3.12.7
#  (render.yaml → PYTHON_VERSION). Se mantiene 3.12 para que la migración no
#  cambie dos cosas a la vez; si algo se rompe, que no sea por el intérprete.
# ============================================================================

# ---------- etapa 1: compilar las dependencias ----------
FROM python:3.12-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# build-essential para libsass; libpq-dev no hace falta porque psycopg2-BINARY
# ya trae la librería adentro del wheel.
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /wheels
COPY requirements.txt .
RUN pip wheel --wheel-dir /wheels -r requirements.txt


# ---------- etapa 2: la imagen que corre ----------
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PORT=8000

# curl es para el HEALTHCHECK de abajo. Nada más entra acá.
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /wheels /wheels
COPY requirements.txt .
RUN pip install --no-index --find-links=/wheels -r requirements.txt \
 && rm -rf /wheels requirements.txt

# Usuario sin privilegios: si alguien se escapa del proceso, no es root.
RUN useradd --create-home --uid 10001 miami
WORKDIR /app
COPY --chown=miami:miami . /app
USER miami

EXPOSE 8000

# `/health` ya existe en app.py:362. Que el contenedor se declare sano recién
# cuando la app contesta de verdad —no cuando el proceso arrancó— es lo que
# permite que Traefik no mande tráfico a una instancia que todavía no levantó.
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD curl -fsS http://127.0.0.1:${PORT}/health || exit 1

# Mismos flags que Render (el servicio corre detrás de un proxy: sin
# --proxy-headers la app ve la IP del proxy y arma los links en http://).
CMD ["sh", "-c", "exec uvicorn app:app --host 0.0.0.0 --port ${PORT} --no-server-header --proxy-headers --forwarded-allow-ips='*'"]
