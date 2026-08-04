// ===== Mapa central de estados del dominio MIAMI IMPORT -> look semántico de badge =====
// Theme CLARO. Semántica de color:
//   brand (rojo MIAMI IMPORT)  = requiere acción / es nuevo
//   verde (sea)        = vivo / ok / listo
//   ámbar              = en espera (de un cliente, de un pago, de una pieza)
//   azul               = en proceso normal
//   neutro             = terminado / sin definir
//   rojo (red)         = cancelado / negativo
// Se usa en todas las páginas para mantener consistencia.

export type Tone = "green" | "amber" | "red" | "blue" | "neutral" | "brand";

export const toneClasses: Record<Tone, string> = {
  green: "bg-sea/10 text-sea ring-1 ring-inset ring-sea/25",
  amber: "bg-amber-500/12 text-amber-700 ring-1 ring-inset ring-amber-500/25",
  red: "bg-red-500/10 text-red-700 ring-1 ring-inset ring-red-500/20",
  blue: "bg-sky-500/10 text-sky-700 ring-1 ring-inset ring-sky-500/20",
  neutral: "bg-graph/[0.05] text-graph-500 ring-1 ring-inset ring-graph/10",
  brand: "bg-brand/10 text-brand-700 ring-1 ring-inset ring-brand/20",
};

// Dot (puntito) con color sólido por tono — para listas compactas.
export const toneDot: Record<Tone, string> = {
  green: "bg-sea",
  amber: "bg-amber-500",
  red: "bg-red-500",
  blue: "bg-sky-500",
  neutral: "bg-graph/30",
  brand: "bg-brand",
};

// ---- Pedidos ----
export const estadoPedido: Record<string, { label: string; tone: Tone }> = {
  nuevo: { label: "Nuevo", tone: "brand" },
  confirmado: { label: "Confirmado", tone: "blue" },
  preparando: { label: "Preparando", tone: "amber" },
  entregado: { label: "Entregado", tone: "green" },
  cancelado: { label: "Cancelado", tone: "neutral" },
};

/** Flujo del kanban (cancelado va aparte, colapsado). */
export const FLUJO_PEDIDO = ["nuevo", "confirmado", "preparando", "entregado"] as const;

// ---- Órdenes de service ----
export const estadoOrden: Record<string, { label: string; tone: Tone }> = {
  ingresada: { label: "Ingresada", tone: "brand" },
  diagnostico: { label: "En diagnóstico", tone: "blue" },
  presupuestada: { label: "Presupuestada", tone: "amber" },
  reparacion: { label: "En reparación", tone: "blue" },
  lista: { label: "Lista para entregar", tone: "green" },
  entregada: { label: "Entregada", tone: "neutral" },
  cancelada: { label: "Cancelada", tone: "red" },
};

/** El flujo natural del taller. Cancelada queda fuera (acción aparte). */
export const FLUJO_ORDEN = ["ingresada", "diagnostico", "presupuestada", "reparacion", "lista", "entregada"] as const;

// ---- Consultas (leads) ----
export const estadoLead: Record<string, { label: string; tone: Tone }> = {
  nueva: { label: "Nueva", tone: "brand" },
  contactado: { label: "Contactado", tone: "blue" },
  cotizado: { label: "Cotizado", tone: "amber" },
  vendido: { label: "Vendido", tone: "green" },
  perdido: { label: "Perdido", tone: "neutral" },
};

export const ESTADOS_LEAD = ["nueva", "contactado", "cotizado", "vendido", "perdido"] as const;

export const interesLead: Record<string, { label: string; tone: Tone }> = {
  producto: { label: "Producto", tone: "blue" },
  service: { label: "Service", tone: "green" },
  mayorista: { label: "Mayorista", tone: "amber" },
};

// ---- Conversaciones (bandeja multicanal) ----
export const estadoConv: Record<string, { label: string; tone: Tone }> = {
  ia: { label: "Responde la IA", tone: "green" },
  vos: { label: "Te toca a vos", tone: "amber" },
  cerrada: { label: "Cerrada", tone: "neutral" },
};

// ---- Clientes ----
export const tipoCliente: Record<string, { label: string; tone: Tone }> = {
  minorista: { label: "Minorista", tone: "blue" },
  mayorista: { label: "Mayorista", tone: "amber" },
  service: { label: "Service", tone: "green" },
};

// ---- Productos ----
export const condicionProducto: Record<string, { label: string; tone: Tone }> = {
  nuevo: { label: "Nuevo", tone: "blue" },
  usado: { label: "Reacondicionado", tone: "amber" },
};

// ---- Canal del pedido (por dónde se vendió) ----
export const canalPedido: Record<string, { label: string; tone: Tone }> = {
  web: { label: "Web", tone: "brand" },
  local: { label: "Local", tone: "neutral" },
  whatsapp: { label: "WhatsApp", tone: "green" },
  mayorista: { label: "Mayorista", tone: "amber" },
};

// ---- Medios de pago ----
export const medioPagoLabel: Record<string, string> = {
  efectivo: "Efectivo",
  transferencia: "Transferencia",
  tarjeta_cuotas: "Tarjeta en cuotas",
  cuenta_corriente: "Cuenta corriente",
};

// ---- Canales de consulta (label legible) ----
export const canalLabel: Record<string, string> = {
  web: "Web propia",
  whatsapp: "WhatsApp",
  instagram: "Instagram",
  mail: "Mail",
  telefono: "Teléfono",
};
