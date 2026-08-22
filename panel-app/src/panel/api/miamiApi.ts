// ============================================================================
//  miamiApi — cliente del backend REAL de MIAMI IMPORT (FastAPI).
//
//  Todos los endpoints viven bajo /panel/api/* y exigen la cookie de admin
//  `mi_admin` (HttpOnly). En dev, vite proxya /panel/api → 127.0.0.1:8001,
//  así el navegador ve todo same-origin y la cookie viaja sola.
//
//  Los productos vienen en "forma Tiendanube" (name.es, values[].es, etc.)
//  porque el backend mantiene ese contrato — ver web-tienda/panel/serializers.py.
// ============================================================================

const BASE = "/panel/api";

// ---------- Tipos (espejo de serializers.py) ----------

export interface TnTexto { es: string }

export interface MiamiVariante {
  id: number;
  product_id: number;
  position: number | null;
  price: string | null;              // "242857.14"
  compare_at_price: string | null;
  promotional_price: string | null;
  usd_price: string | null;
  stock: number;
  sku: string | null;
  values: TnTexto[];                 // [{es: "XL"}] — el talle
  visible: boolean;
}

export interface MiamiImagen {
  id: number;
  product_id: number;
  src: string;
  position: number | null;
  alt: string[];
  width: number | null;
  height: number | null;
}

export interface MiamiCategoria {
  id: number;
  name: TnTexto;
  handle: TnTexto;
  parent: number | null;
}

export interface MiamiProducto {
  id: number;
  name: TnTexto;
  handle: TnTexto;
  brand: string | null;
  published: boolean;
  a_pedido: boolean;
  /** Curación manual de la home: sección "Destacados". */
  destacado: boolean;
  /** Curación manual de la home: sección "Más vendidos". */
  mas_vendido: boolean;
  free_shipping: boolean;
  variants: MiamiVariante[];
  images: MiamiImagen[];
  categories: MiamiCategoria[];
  description?: TnTexto;
  created_at?: string | null;
  updated_at?: string | null;
}

export interface MiamiStats {
  productos: { total: number; publicados: number; sin_stock: number; variantes: number; stock_total: number };
  pedidos: { total: number; pagados: number; pendientes: number; facturado_total: number; ticket_promedio: number };
  top_vendidos: { product_id: number; name: string; vendidos: number }[];
  stock_bajo: { id: number; name: string; brand: string | null; stock: number }[];
}

export interface MiamiStore {
  name: string;
  url: string;
  product_url_base: string;
  usd_rate: number;
}

// ---- LA WEB: la home que Diego edita desde el panel ----
export interface HomePieza {
  nombre: string; genero?: string; imagen: string; ref?: string;
  colorway?: string; talles?: string; peso?: string; link?: string; descripcion?: string;
}
export interface HomeMarca { nombre: string; link: string; imagen: string }
export interface HomeValor { num: string; titulo: string; texto: string }
export interface HomeConfig {
  hero: { activo: boolean; eyebrow: string; titulo: string; subtitulo: string;
          cta_texto: string; cta_link: string; cta2_texto: string; cta2_link: string; video: string };
  vitrina: { activo: boolean; eyebrow: string; titulo: string; piezas: HomePieza[] };
  marcas: { activo: boolean; eyebrow: string; titulo: string; bajada: string; items: HomeMarca[] };
  secciones: Record<string, string>;
  valores: { activo: boolean; items: HomeValor[] };
  cierre: { activo: boolean; titulo: string; texto: string; cta_texto: string; wa_mensaje: string };
}

export interface LoginRespuesta {
  ok: boolean;
  mfa_required?: boolean;
  email?: string;
  name?: string | null;
}

// ---- Pedidos (order_to_tn) ----
export interface MiamiPedidoItem {
  product_id: number | null;
  variant_id: number | null;
  name: string;
  /** El talle, explícito (antes había que adivinarlo dentro del SKU). */
  talle: string | null;
  sku: string | null;
  quantity: number;
  price: string | null;
}
export interface MiamiPedido {
  id: number;
  number: number;
  created_at: string | null;
  status: string;
  payment_status: string;
  total: string | null;
  currency: string | null;
  contact_name: string | null;
  contact_email: string | null;
  contact_phone: string | null;
  shipping_address: Record<string, any>;
  products: MiamiPedidoItem[];
  /** Rastro del cobro en Stripe: la prueba de que la plata entro. */
  pago?: MiamiPago;
}

/** Lo que Stripe devuelve del cobro. `recibo_url` es el recibo oficial que
 *  hospeda Stripe: lo abre el cliente y lo reconoce el banco. */
export interface MiamiPago {
  estado: string;
  intent_id: string | null;
  cobro_id: string | null;
  recibo_url: string | null;
  tarjeta: string | null;
  acreditado_en: string | null;
  monto: string | null;
  moneda: string | null;
  detalle: string | null;
  /** Frase lista para leer que contesta "¿intentó pagar y no pudo?". */
  motivo: string | null;
}

/** Estados de pedido que el backend acepta (core.models.ORDER_STATUSES).
 *  "refunded" NO se setea a mano: solo el botón de reembolso (regla del backend). */
export const ESTADOS_PEDIDO = ["pending", "paid", "processing", "shipped", "delivered", "cancelled"] as const;

// ---- Reservas ----
export interface MiamiReserva {
  id: number;
  product_id: number | null;
  variant_id: number | null;
  product_name: string;
  talle: string | null;
  customer_name: string;
  customer_phone: string | null;
  notes: string | null;
  status: string; // pendiente | avisado | entregado | cancelado
  created_at: string | null;
}
export const ESTADOS_RESERVA = ["pendiente", "avisado", "entregado", "cancelado"] as const;

// ---- POS (punto de venta) ----
export interface PosVariante {
  variant_id: number;
  talle: string;
  sku: string | null;
  precio: string | null;
  stock: number;
}
export interface PosProducto {
  product_id: number;
  nombre: string;
  marca: string;
  imagen: string | null;
  variantes: PosVariante[];
}
export interface PosVentaCreada {
  ok: boolean;
  order_id: number;
  numero: number;
  total: string;
  moneda: string;
  url_pago: string;
  qr_svg: string;
}
export interface PosEstado {
  numero: number;
  pagado: boolean;
  estado_pago: string;
  estado: string;
  total: string;
}
/** Ítem que viaja a POST /pos/venta: del catálogo o "suelto" (precio a mano). */
export type PosItemVenta =
  | { variant_id: number; cantidad: number }
  | { libre: true; nombre: string; precio: number; cantidad: number };

// ---- Precios USD / WhatsApp / bot ----
export interface UsdPrices { prices: Record<string, number>; rate: number }
export type WaTemplates = Record<string, string>;
export interface BotConfig {
  shipping_info: string;
  payment_info: string;
  exchange_info: string;
  usd_rate: number;
  [k: string]: unknown;
}

export interface ReconciliarResultado {
  ok: boolean;
  revisados: number;
  acreditados: { pedido: number; monto: string }[];
  sin_pagar: { pedido: number; estado_stripe: string }[];
  para_revisar: { pedido: number; cobrado: string; esperado: string }[];
  errores: { pedido: number; error: string }[];
}

// ---------- Helpers de dominio ----------

/** Talle legible de una variante ("XL", "42"…). */
export const talleDe = (v: MiamiVariante): string => v.values?.[0]?.es ?? "Único";

/** Precio (ARS, número) de una variante. */
export const precioVar = (v: MiamiVariante): number => (v.price ? parseFloat(v.price) : 0);

/** Precio "desde" del producto: el mínimo entre variantes con precio. */
export function precioDe(p: MiamiProducto): number {
  const precios = p.variants.map(precioVar).filter((n) => n > 0);
  return precios.length ? Math.min(...precios) : 0;
}

/** Stock total del producto (suma de talles). */
export const stockDe = (p: MiamiProducto): number =>
  p.variants.reduce((a, v) => a + (v.stock || 0), 0);

/** Foto principal (posición 1) o undefined. */
export const fotoDe = (p: MiamiProducto): string | undefined =>
  [...p.images].sort((a, b) => (a.position || 0) - (b.position || 0))[0]?.src;

// ---------- Transporte ----------

export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

async function req<T>(path: string, init: RequestInit = {}): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    credentials: "include",
    ...init,
  });
  if (!res.ok) {
    let detalle = `Error ${res.status}`;
    try {
      const j = await res.json();
      if (typeof j?.detail === "string") detalle = j.detail;
    } catch { /* cuerpo no-JSON */ }
    throw new ApiError(res.status, detalle);
  }
  return res.json() as Promise<T>;
}

const json = (body: unknown): RequestInit => ({
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body),
});

// ---------- Auth ----------

export const api = {
  // --- sesión ---
  login: (email: string, password: string, totp_code?: string) =>
    req<LoginRespuesta>("/auth/login", json(totp_code ? { email, password, totp_code } : { email, password })),
  logout: () => req<{ ok: boolean }>("/auth/logout", { method: "POST" }),
  me: () => req<{ id: number; email: string; name: string | null }>("/auth/me"),

  // --- tienda ---
  store: () => req<MiamiStore>("/store"),

  // --- el dinero (pantalla Mi plata) ---
  dinero: (desde?: string, hasta?: string) => {
    const q = new URLSearchParams();
    if (desde) q.set("desde", desde);
    if (hasta) q.set("hasta", hasta);
    const cola = q.toString();
    return req<MiamiDinero>("/dinero" + (cola ? "?" + cola : ""));
  },

  // --- productos ---
  productos: () => req<MiamiProducto[]>("/products/all"),
  producto: (id: number) => req<MiamiProducto>(`/products/${id}`),
  aPedido: () => req<MiamiProducto[]>("/products/a_pedido"),

  /** Edita nombre / marca / descripción / publicado / destacado. Devuelve el producto actualizado. */
  actualizarProducto: (id: number, patch: { name?: string; brand?: string; description?: string; published?: boolean; destacado?: boolean; mas_vendido?: boolean }) =>
    req<MiamiProducto>(`/products/${id}`, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify(patch) }),

  eliminarProducto: (id: number) => req<{ ok: boolean }>(`/products/${id}`, { method: "DELETE" }),

  /** Edita PRECIO y/o STOCK (y sku) de un talle. El backend responde {ok:true}.
   *  `usd_price` es el precio principal de la tienda: el backend recalcula los
   *  pesos con la cotización del panel (y viceversa si se manda `price`). */
  actualizarVariante: (pid: number, vid: number, patch: { price?: number; usd_price?: number; stock?: number; sku?: string }) =>
    req<{ ok: boolean }>(`/variants/${pid}/${vid}`, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify(patch) }),

  /** Agrega un talle nuevo. Devuelve el producto actualizado. */
  agregarTalle: (pid: number, body: { talle: string; stock?: number; price?: number }) =>
    req<MiamiProducto>(`/products/${pid}/variants`, json(body)),

  /** Quita un talle (si no es el único ni está reservado). Devuelve el producto. */
  quitarTalle: (pid: number, vid: number) =>
    req<MiamiProducto>(`/variants/${pid}/${vid}`, { method: "DELETE" }),

  // --- LA WEB (home editable) ---
  /** Config de la home + si hay IA de recorte configurada en el server. */
  webHome: () => req<{ config: HomeConfig; recorte_ia: boolean }>("/web/home"),

  /** Guarda SOLO los bloques que se manden (el resto queda intacto). */
  webHomeGuardar: (bloques: Partial<HomeConfig>) =>
    req<{ config: HomeConfig }>("/web/home", {
      method: "PUT", headers: { "Content-Type": "application/json" },
      body: JSON.stringify(bloques),
    }),

  /** Vuelve la home a como vino de fábrica. */
  webHomeReset: () => req<{ config: HomeConfig }>("/web/home/reset", { method: "POST" }),

  /** Sube una foto de la home; con quitarFondo la IA la recorta sobre transparente. */
  webImagen: (file: File, quitarFondo: boolean, destino: string) => {
    const fd = new FormData();
    fd.append("file", file);
    fd.append("quitar_fondo", quitarFondo ? "true" : "false");
    fd.append("destino", destino);
    return req<{ ok: boolean; url: string; motor: string | null; aviso: string | null }>(
      "/web/imagen", { method: "POST", body: fd });
  },

  /** Alta de producto — multipart (name, brand, price, talles, stock_por_talle, images[]…). */
  crearProducto: (form: FormData) =>
    req<{ ok: boolean; product_id: number; url: string | null; imagenes_subidas: number; variantes_creadas: number }>(
      "/products", { method: "POST", body: form }),

  /** Suma una foto a un producto existente. */
  subirImagen: (pid: number, file: File) => {
    const fd = new FormData();
    fd.append("file", file);
    return req<{ ok: boolean; src: string }>(`/products/${pid}/images`, { method: "POST", body: fd });
  },

  borrarImagen: (pid: number, imageId: number) =>
    req<MiamiProducto>(`/products/${pid}/images/${imageId}`, { method: "DELETE" }),

  /** Reordena la galería: ids COMPLETOS en el orden nuevo (el primero = portada). */
  reordenarImagenes: (pid: number, ids: number[]) =>
    req<MiamiProducto>(`/products/${pid}/images/orden`, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ ids }) }),

  // --- métricas ---
  stats: () => req<MiamiStats>("/stats"),

  // --- pedidos ---
  pedidos: (perPage = 100) => req<MiamiPedido[]>(`/orders?per_page=${perPage}`),
  pedido: (oid: number) => req<MiamiPedido>(`/orders/${oid}`),
  setEstadoPedido: (oid: number, status: string) =>
    req<{ ok: boolean; status: string; payment_status: string; aviso: string | null }>(
      `/orders/${oid}/status`, json({ status })),
  reembolsarPedido: (oid: number) =>
    req<{ ok: boolean; status: string }>(`/orders/${oid}/refund`, { method: "POST" }),
  /** Pregunta a Stripe por los pendientes y acredita los ya cobrados. */
  reconciliarPagos: () => req<ReconciliarResultado>("/orders/reconciliar", { method: "POST" }),

  // --- reservas ---
  reservas: () => req<MiamiReserva[]>("/reservas"),
  crearReserva: (body: { product_id: number; customer_name: string; customer_phone?: string; notes?: string; variant_id?: number }) =>
    req<MiamiReserva>("/reservas", json(body)),
  setEstadoReserva: (rid: number, status: string) =>
    req<MiamiReserva>(`/reservas/${rid}/status`, json({ status })),
  borrarReserva: (rid: number) => req<{ ok: boolean }>(`/reservas/${rid}`, { method: "DELETE" }),

  // --- punto de venta (POS) ---
  posBuscar: (q: string) =>
    req<{ productos: PosProducto[] }>(`/pos/buscar?q=${encodeURIComponent(q || "")}`),
  posCrearVenta: (body: { cliente: string; telefono?: string; email?: string; nota?: string; items: PosItemVenta[] }) =>
    req<PosVentaCreada>("/pos/venta", json(body)),
  posEstadoVenta: (oid: number) => req<PosEstado>(`/pos/venta/${oid}/estado`),
  posCancelarVenta: (oid: number) => req<{ ok: boolean }>(`/pos/venta/${oid}/cancelar`, { method: "POST" }),

  // --- precios USD ---
  usdPrices: () => req<UsdPrices>("/usd_prices"),
  /** Guarda cotización y/o USD por producto (la cotización vive en la DB). */
  usdPricesSave: (body: { rate?: number; prices?: Record<string, number> }) =>
    req<{ ok: boolean; saved_count: number; rate: number }>("/usd_prices", json(body)),
  usdSeedFromCurrent: () =>
    req<{ ok: boolean; count: number; rate: number }>("/usd_prices/from_current", { method: "POST" }),
  /** Recalcula ARS = USD × rate en todas las variantes (nombre legacy del endpoint). */
  usdRecalcularArs: () =>
    req<{ ok: boolean; updated_products: number; updated_variants: number; rate: number }>("/usd_prices/sync_to_tiendanube", { method: "POST" }),

  // --- WhatsApp + bot ---
  waTemplates: () => req<WaTemplates>("/whatsapp_templates"),
  waTemplatesSave: (tpls: WaTemplates) => req<{ ok: boolean }>("/whatsapp_templates", json(tpls)),
  botConfig: () => req<BotConfig>("/bot_config"),
  botConfigSave: (body: Partial<BotConfig>) => req<{ ok: boolean; saved: BotConfig }>("/bot_config", json(body)),

  // --- acciones ---
  redeployBot: () => req<{ ok: boolean; status?: number; error?: string }>("/actions/redeploy_bot", { method: "POST" }),
};

/** URL directa del Excel completo (descarga con la cookie de sesión). */

/** ---- EL DINERO: lo que Diego le reclama a la LLC ---- */
export interface MiamiCobro {
  pedido: number;
  order_id: number;
  fecha: string | null;
  cliente: string | null;
  email: string | null;
  bruto: number;
  moneda: string | null;
  /** Comision de Stripe. null = todavia no se consulto (apretar Reconciliar). */
  comision: number | null;
  neto: number | null;
  moneda_neto: string | null;
  disponible_el: string | null;
  medio: string | null;
  cobro_id: string | null;
  recibo_url: string | null;
}
export interface MiamiGiro {
  id: string;
  monto: number;
  moneda: string;
  estado: string;
  llega_el: string | null;
}
/** Estado de la cuenta de Stripe: contesta por que la plata no sale. */
export interface MiamiCuentaStripe {
  pais: string | null;
  cobra: boolean;
  puede_girar: boolean;
  /** "manual" = la plata se queda hasta que alguien la saque a mano. */
  frecuencia: string | null;
  demora_dias: number | null;
  bancos: { banco: string | null; ultimos4: string | null; pais: string | null; moneda: string }[];
  pendiente: string[];
  vence: number | null;
  motivo_freno: string | null;
}

export interface MiamiDinero {
  resumen: {
    cantidad: number;
    bruto: number;
    moneda: string | null;
    comision: number;
    neto: number;
    moneda_neto: string | null;
    /** Cobros sin detalle de liquidacion: si es > 0 el neto esta incompleto. */
    sin_liquidacion: number;
  };
  cobros: MiamiCobro[];
  saldo_stripe: { disponible: { monto: number; moneda: string }[];
                  pendiente: { monto: number; moneda: string }[] } | null;
  giros_al_banco: MiamiGiro[];
  cuenta_stripe: MiamiCuentaStripe | null;
  error_stripe: string | null;
  desde: string | null;
  hasta: string | null;
}

export const EXPORT_EXCEL_URL = `${BASE}/export/excel`;

/** Link wa.me con una plantilla aplicada ({name}/{order} reemplazados). */
export function waLink(phone: string, plantilla: string, datos: { name?: string; order?: string | number }) {
  const digits = (phone || "").replace(/[^0-9]/g, "");
  const txt = plantilla
    .replace(/{name}/g, datos.name ?? "")
    .replace(/{order}/g, String(datos.order ?? ""));
  return `https://wa.me/${digits}?text=${encodeURIComponent(txt)}`;
}

/** CSV de cobros para mandarle a la LLC como reclamo. */
export const DINERO_EXPORT_URL = `${BASE}/dinero/export`;
