"""
Modelos ORM de MIAMI_IMPORT — esquema único compartido por panel y tienda.

Convenciones:
- Dinero en Numeric(12, 2). Moneda base: ARS (igual que hoy en Tiendanube).
- Fechas en UTC (timezone-aware).
- Los `tn_id` guardan el id original de Tiendanube para trazabilidad de la migración.
- Estados como String (portable entre SQLite local y Postgres en Render).
"""
from __future__ import annotations

import secrets
from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Table,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.types import JSON

from .db import Base


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


# Estados (constantes, no enums de DB, para portabilidad)
ORDER_STATUSES = (
    "pending", "paid", "processing", "shipped", "delivered", "cancelled", "refunded",
)
PAYMENT_STATUSES = ("pending", "authorized", "paid", "failed", "refunded", "voided")


# --------------------------------------------------------------------------- #
# Usuarios / direcciones
# --------------------------------------------------------------------------- #
class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    password_hash: Mapped[str | None] = mapped_column(String(255))  # null = solo OAuth
    full_name: Mapped[str | None] = mapped_column(String(255))
    phone: Mapped[str | None] = mapped_column(String(50))
    google_id: Mapped[str | None] = mapped_column(String(255), unique=True, index=True)
    email_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    # RBAC: customer | staff | admin | owner  (is_admin sigue siendo el gate del panel)
    role: Mapped[str] = mapped_column(String(20), default="customer")
    # MFA / TOTP (obligatorio para administradores)
    totp_secret: Mapped[str | None] = mapped_column(String(64))
    totp_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    # Versión de sesión: va como claim `tv` en el JWT y se compara al validar.
    # Incrementarla invalida TODAS las sesiones vivas del usuario (cambio de
    # contraseña, reset, "cerrar sesión en todos lados"). Sin esto un token
    # robado sigue sirviendo hasta su exp aunque la víctima cambie la clave.
    token_version: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    addresses: Mapped[list["Address"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    orders: Mapped[list["Order"]] = relationship(back_populates="user")
    carts: Mapped[list["Cart"]] = relationship(back_populates="user")
    refresh_tokens: Mapped[list["RefreshToken"]] = relationship(back_populates="user", cascade="all, delete-orphan")


class RefreshToken(Base):
    """Refresh tokens rotativos (revocables). El JWT de acceso es de corta vida."""
    __tablename__ = "refresh_tokens"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    token_hash: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    revoked: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    user: Mapped["User"] = relationship(back_populates="refresh_tokens")


class PasswordReset(Base):
    __tablename__ = "password_resets"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    token_hash: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    used: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Address(Base):
    __tablename__ = "addresses"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    label: Mapped[str | None] = mapped_column(String(100))
    full_name: Mapped[str | None] = mapped_column(String(255))
    phone: Mapped[str | None] = mapped_column(String(50))
    street: Mapped[str | None] = mapped_column(String(255))
    number: Mapped[str | None] = mapped_column(String(50))
    floor: Mapped[str | None] = mapped_column(String(50))
    city: Mapped[str | None] = mapped_column(String(120))
    province: Mapped[str | None] = mapped_column(String(120))
    zipcode: Mapped[str | None] = mapped_column(String(30))
    country: Mapped[str] = mapped_column(String(2), default="AR")
    is_default: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    user: Mapped["User"] = relationship(back_populates="addresses")


# --------------------------------------------------------------------------- #
# Catálogo
# --------------------------------------------------------------------------- #
product_categories = Table(
    "product_categories",
    Base.metadata,
    Column("product_id", ForeignKey("products.id", ondelete="CASCADE"), primary_key=True),
    Column("category_id", ForeignKey("categories.id", ondelete="CASCADE"), primary_key=True),
)


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(primary_key=True)
    tn_id: Mapped[int | None] = mapped_column(Integer, unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    handle: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    description: Mapped[str | None] = mapped_column(Text)
    parent_id: Mapped[int | None] = mapped_column(ForeignKey("categories.id", ondelete="SET NULL"), index=True)
    seo_title: Mapped[str | None] = mapped_column(String(255))
    seo_description: Mapped[str | None] = mapped_column(Text)
    position: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    parent: Mapped["Category | None"] = relationship(remote_side=[id], backref="subcategories")
    products: Mapped[list["Product"]] = relationship(secondary=product_categories, back_populates="categories")


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(primary_key=True)
    tn_id: Mapped[int | None] = mapped_column(Integer, unique=True, index=True)
    name: Mapped[str] = mapped_column(String(500), nullable=False)
    handle: Mapped[str] = mapped_column(String(500), unique=True, index=True)
    description: Mapped[str | None] = mapped_column(Text)  # HTML
    brand: Mapped[str | None] = mapped_column(String(255), index=True)
    published: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    # Producto "a pedido": no es stock real, no se muestra en la tienda. Vive en
    # una pestaña aparte del panel y sirve para tomar reservas de clientes.
    a_pedido: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    # Curación manual de la home desde el panel. Sin ninguno marcado, cada
    # sección cae a su lógica automática (más nuevos / ventas reales).
    destacado: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    mas_vendido: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    free_shipping: Mapped[bool] = mapped_column(Boolean, default=False)
    video_url: Mapped[str | None] = mapped_column(String(500))
    seo_title: Mapped[str | None] = mapped_column(String(255))
    seo_description: Mapped[str | None] = mapped_column(Text)
    canonical_url: Mapped[str | None] = mapped_column(String(500))
    tags: Mapped[list | None] = mapped_column(JSON, default=list)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    categories: Mapped[list["Category"]] = relationship(secondary=product_categories, back_populates="products")
    images: Mapped[list["ProductImage"]] = relationship(
        back_populates="product", cascade="all, delete-orphan", order_by="ProductImage.position"
    )
    variants: Mapped[list["Variant"]] = relationship(
        back_populates="product", cascade="all, delete-orphan", order_by="Variant.position"
    )

    @property
    def total_stock(self) -> int:
        return sum(int(v.stock or 0) for v in self.variants)

    @property
    def min_price(self) -> Decimal | None:
        prices = [v.price for v in self.variants if v.price is not None]
        return min(prices) if prices else None


class ProductImage(Base):
    __tablename__ = "product_images"

    id: Mapped[int] = mapped_column(primary_key=True)
    tn_id: Mapped[int | None] = mapped_column(Integer, index=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id", ondelete="CASCADE"), index=True)
    src: Mapped[str] = mapped_column(String(1000))          # URL original (CDN TN)
    local_path: Mapped[str | None] = mapped_column(String(500))  # ruta local tras descarga
    position: Mapped[int] = mapped_column(Integer, default=1)
    alt: Mapped[str | None] = mapped_column(String(500))
    width: Mapped[int | None] = mapped_column(Integer)
    height: Mapped[int | None] = mapped_column(Integer)

    product: Mapped["Product"] = relationship(back_populates="images")

    @property
    def url(self) -> str:
        """URL a servir: local si se descargó, si no el CDN original."""
        return self.local_path or self.src


class Variant(Base):
    # NOTA: `currency` (más abajo) permite cobrar una variante puntual en otra
    # moneda que la de la tienda. Vacío = se usa CHECKOUT_CURRENCY.
    __tablename__ = "variants"

    id: Mapped[int] = mapped_column(primary_key=True)
    tn_id: Mapped[int | None] = mapped_column(Integer, unique=True, index=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id", ondelete="CASCADE"), index=True)
    sku: Mapped[str | None] = mapped_column(String(120), index=True)
    price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))            # ARS
    compare_at_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    promotional_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    usd_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))        # control en USD
    # Moneda en la que se COBRA esta variante. Vacío = la de la tienda
    # (CHECKOUT_CURRENCY, hoy "ars"). Permite tener un producto puntual en otra
    # moneda sin tocar el resto del catálogo. `price` se interpreta en ESTA
    # moneda, así que cargarla implica cargar el precio correspondiente.
    currency: Mapped[str | None] = mapped_column(String(3))
    stock: Mapped[int] = mapped_column(Integer, default=0)
    value: Mapped[str | None] = mapped_column(String(255))  # talle/color (ej "M")
    position: Mapped[int] = mapped_column(Integer, default=1)
    weight: Mapped[Decimal | None] = mapped_column(Numeric(10, 3))
    visible: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    product: Mapped["Product"] = relationship(back_populates="variants")


# --------------------------------------------------------------------------- #
# Carrito (persistente: anónimo por token o ligado a usuario)
# --------------------------------------------------------------------------- #
class Cart(Base):
    __tablename__ = "carts"

    id: Mapped[int] = mapped_column(primary_key=True)
    token: Mapped[str] = mapped_column(String(64), unique=True, index=True)  # carrito anónimo
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), index=True)
    currency: Mapped[str] = mapped_column(String(3), default="ARS")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    user: Mapped["User | None"] = relationship(back_populates="carts")
    items: Mapped[list["CartItem"]] = relationship(back_populates="cart", cascade="all, delete-orphan")


class CartItem(Base):
    __tablename__ = "cart_items"
    __table_args__ = (UniqueConstraint("cart_id", "variant_id", name="uq_cart_variant"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    cart_id: Mapped[int] = mapped_column(ForeignKey("carts.id", ondelete="CASCADE"), index=True)
    variant_id: Mapped[int] = mapped_column(ForeignKey("variants.id", ondelete="CASCADE"))
    quantity: Mapped[int] = mapped_column(Integer, default=1)
    unit_price: Mapped[Decimal] = mapped_column(Numeric(12, 2))  # snapshot al agregar
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    cart: Mapped["Cart"] = relationship(back_populates="items")
    variant: Mapped["Variant"] = relationship()


# --------------------------------------------------------------------------- #
# Pedidos / pagos / cupones
# --------------------------------------------------------------------------- #
class Coupon(Base):
    __tablename__ = "coupons"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(60), unique=True, index=True)
    type: Mapped[str] = mapped_column(String(20), default="percent")  # percent | fixed
    value: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    min_amount: Mapped[Decimal | None] = mapped_column(Numeric(12, 2))
    usage_limit: Mapped[int | None] = mapped_column(Integer)
    used_count: Mapped[int] = mapped_column(Integer, default=0)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(primary_key=True)
    number: Mapped[int] = mapped_column(Integer, unique=True, index=True)
    # Token opaco para ver la confirmación sin estar logueado. El `number` es
    # secuencial y adivinable: sin esto, /pedido/{n} deja enumerar las ventas.
    public_token: Mapped[str] = mapped_column(String(64), unique=True, index=True,
                                              default=lambda: secrets.token_urlsafe(32))
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), index=True)
    # Carrito exacto que originó la orden: al acreditarse el pago se vacía ESE,
    # también para compras de invitado (si no, el invitado vuelve y repaga).
    cart_id: Mapped[int | None] = mapped_column(ForeignKey("carts.id", ondelete="SET NULL"))
    email: Mapped[str | None] = mapped_column(String(255), index=True)
    contact_name: Mapped[str | None] = mapped_column(String(255))
    contact_phone: Mapped[str | None] = mapped_column(String(50))

    status: Mapped[str] = mapped_column(String(20), default="pending", index=True)
    payment_status: Mapped[str] = mapped_column(String(20), default="pending", index=True)
    currency: Mapped[str] = mapped_column(String(3), default="ARS")

    subtotal: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0)
    shipping_cost: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0)
    discount: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0)
    total: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0)

    # El stock se descuenta al CREAR el intent (reserva), no al acreditarse el
    # pago: si no, dos clientes compran la última unidad en la ventana entre
    # ambos momentos. Este flag hace idempotentes la reserva y la devolución.
    stock_reserved: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    coupon_id: Mapped[int | None] = mapped_column(ForeignKey("coupons.id", ondelete="SET NULL"))
    shipping_address: Mapped[dict | None] = mapped_column(JSON)  # snapshot
    notes: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    user: Mapped["User | None"] = relationship(back_populates="orders")
    items: Mapped[list["OrderItem"]] = relationship(back_populates="order", cascade="all, delete-orphan")
    payments: Mapped[list["Payment"]] = relationship(back_populates="order", cascade="all, delete-orphan")


class OrderItem(Base):
    __tablename__ = "order_items"

    id: Mapped[int] = mapped_column(primary_key=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id", ondelete="CASCADE"), index=True)
    variant_id: Mapped[int | None] = mapped_column(ForeignKey("variants.id", ondelete="SET NULL"))
    product_id: Mapped[int | None] = mapped_column(ForeignKey("products.id", ondelete="SET NULL"))
    product_name: Mapped[str] = mapped_column(String(500))  # snapshot
    variant_value: Mapped[str | None] = mapped_column(String(255))
    sku: Mapped[str | None] = mapped_column(String(120))
    unit_price: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    quantity: Mapped[int] = mapped_column(Integer, default=1)
    subtotal: Mapped[Decimal] = mapped_column(Numeric(12, 2))

    order: Mapped["Order"] = relationship(back_populates="items")


class Payment(Base):
    __tablename__ = "payments"

    id: Mapped[int] = mapped_column(primary_key=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id", ondelete="CASCADE"), index=True)
    provider: Mapped[str] = mapped_column(String(30), default="stripe")
    stripe_payment_intent_id: Mapped[str | None] = mapped_column(String(255), index=True)
    stripe_checkout_session_id: Mapped[str | None] = mapped_column(String(255), index=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0)
    currency: Mapped[str] = mapped_column(String(3), default="ARS")
    status: Mapped[str] = mapped_column(String(20), default="pending", index=True)
    error_message: Mapped[str | None] = mapped_column(Text)
    raw: Mapped[dict | None] = mapped_column(JSON)  # payload bruto del evento
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    order: Mapped["Order"] = relationship(back_populates="payments")


class WebhookEvent(Base):
    """Eventos de Stripe ya procesados — idempotencia real por event.id.

    Stripe reintenga la entrega hasta 3 días y no garantiza el orden. Sin esta
    tabla, la única defensa es inferir el estado de la orden, que es frágil:
    dos entregas concurrentes del mismo evento pueden colarse a la vez.
    El insert del `event_id` (PK única) es el que gana la carrera.
    """
    __tablename__ = "webhook_events"

    event_id: Mapped[str] = mapped_column(String(255), primary_key=True)
    event_type: Mapped[str] = mapped_column(String(80))
    processed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


# --------------------------------------------------------------------------- #
# Configuración / auditoría
# --------------------------------------------------------------------------- #
class Setting(Base):
    __tablename__ = "settings"

    key: Mapped[str] = mapped_column(String(120), primary_key=True)
    value: Mapped[dict | None] = mapped_column(JSON)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), index=True)
    action: Mapped[str] = mapped_column(String(120), index=True)
    entity: Mapped[str | None] = mapped_column(String(80))
    entity_id: Mapped[str | None] = mapped_column(String(80))
    ip: Mapped[str | None] = mapped_column(String(64))
    detail: Mapped[dict | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


# Estados posibles de una reserva de producto "a pedido".
RESERVA_STATUSES = ("pendiente", "avisado", "entregado", "cancelado")


class Reserva(Base):
    """Un cliente que quiere un producto 'a pedido' (y su talle).

    Se guardan copias del nombre del producto y del talle (snapshot) para que
    la reserva se siga leyendo aunque después se borre el producto. Por eso las
    FK son SET NULL: si el producto desaparece, la reserva queda con el texto.
    """
    __tablename__ = "reservas"

    id: Mapped[int] = mapped_column(primary_key=True)
    product_id: Mapped[int | None] = mapped_column(
        ForeignKey("products.id", ondelete="SET NULL"), index=True)
    variant_id: Mapped[int | None] = mapped_column(
        ForeignKey("variants.id", ondelete="SET NULL"), index=True)
    product_name: Mapped[str] = mapped_column(String(500))     # snapshot
    talle: Mapped[str | None] = mapped_column(String(255))     # snapshot
    customer_name: Mapped[str] = mapped_column(String(255), index=True)
    customer_phone: Mapped[str | None] = mapped_column(String(50))
    notes: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), default="pendiente", index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
