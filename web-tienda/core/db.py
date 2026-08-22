"""
Conexión a la base de datos (SQLAlchemy 2.x).

- Local: SQLite (un archivo compartido por panel y tienda).
- Producción (Render): Postgres vía DATABASE_URL.
"""
from __future__ import annotations

from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from .config import settings

_is_sqlite = settings.DATABASE_URL.startswith("sqlite")

if _is_sqlite:
    _opciones = {"pool_pre_ping": True,
                 "connect_args": {"check_same_thread": False}}
else:
    # `pool_pre_ping` manda un SELECT 1 cada vez que se saca una conexión del
    # pool, o sea en CADA visita. Con la base en São Paulo y el servidor en
    # Oregon ese chequeo cuesta ~180 ms — lo mismo que una consulta útil.
    # `pool_recycle` cubre el mismo caso (que el pooler haya cerrado una
    # conexión ociosa) descartándola por tiempo, sin pagar el viaje de ida y
    # vuelta: 5 minutos queda bien por debajo del corte del pooler.
    # El pool más grande evita que, con los anuncios mandando visitas, las
    # peticiones hagan cola esperando conexión.
    _opciones = {"pool_pre_ping": False, "pool_recycle": 300,
                 "pool_size": 10, "max_overflow": 20, "connect_args": {}}

engine = create_engine(settings.DATABASE_URL, echo=False, future=True, **_opciones)

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)


class Base(DeclarativeBase):
    pass


def get_db() -> Iterator[Session]:
    """Dependencia FastAPI: una sesión por request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    """Crea las tablas que falten (para dev / primer arranque sin Alembic)."""
    from . import models  # noqa: F401  (registra los modelos en Base.metadata)

    Base.metadata.create_all(bind=engine)
    _ensure_columns()


# Columnas agregadas después de crear la tabla original (migración liviana,
# idempotente, sin Alembic). Compatible con SQLite y Postgres.
_ADDED_COLUMNS = {
    "users": {
        "role": "VARCHAR(20) DEFAULT 'customer'",
        "totp_secret": "VARCHAR(64)",
        "totp_enabled": "BOOLEAN DEFAULT FALSE",
        "token_version": "INTEGER DEFAULT 0",
    },
    "orders": {
        "public_token": "VARCHAR(64)",
        "cart_id": "INTEGER",
        "stock_reserved": "BOOLEAN DEFAULT FALSE",
    },
    "variants": {
        "currency": "VARCHAR(3)",
    },
    "payments": {
        # El rastro del cobro real de Stripe (ver core/models.py:Payment).
        "stripe_charge_id": "VARCHAR(255)",
        "receipt_url": "TEXT",
        "metodo": "VARCHAR(40)",
        "estado_stripe": "VARCHAR(40)",
        "error_code": "VARCHAR(60)",
        "card_brand": "VARCHAR(30)",
        "card_last4": "VARCHAR(4)",
        "paid_at": "TIMESTAMP WITH TIME ZONE",
        "fee": "NUMERIC(12,2)",
        "neto": "NUMERIC(12,2)",
        "moneda_liquidacion": "VARCHAR(3)",
        "disponible_el": "TIMESTAMP WITH TIME ZONE",
        "payout_id": "VARCHAR(255)",
    },
    "products": {
        "a_pedido": "BOOLEAN DEFAULT FALSE",
        "destacado": "BOOLEAN DEFAULT FALSE",
        "mas_vendido": "BOOLEAN DEFAULT FALSE",
    },
}


def _ensure_columns() -> None:
    from sqlalchemy import inspect, text

    insp = inspect(engine)
    existing_tables = set(insp.get_table_names())
    with engine.begin() as conn:
        for table, cols in _ADDED_COLUMNS.items():
            if table not in existing_tables:
                continue
            have = {c["name"] for c in insp.get_columns(table)}
            for col, ddl in cols.items():
                if col not in have:
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {col} {ddl}"))
    _backfill_order_tokens()


def _backfill_order_tokens() -> None:
    """Las órdenes creadas antes de public_token quedarían con NULL y serían
    accesibles por enumeración. Se les asigna un token aleatorio de una vez."""
    import secrets

    from sqlalchemy import inspect, text

    insp = inspect(engine)
    if "orders" not in set(insp.get_table_names()):
        return
    if "public_token" not in {c["name"] for c in insp.get_columns("orders")}:
        return
    with engine.begin() as conn:
        pending = conn.execute(
            text("SELECT id FROM orders WHERE public_token IS NULL OR public_token = ''")
        ).fetchall()
        for (oid,) in pending:
            conn.execute(
                text("UPDATE orders SET public_token = :t WHERE id = :i"),
                {"t": secrets.token_urlsafe(32), "i": oid},
            )
