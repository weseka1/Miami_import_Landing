import { useEffect, useMemo, useState } from "react";
import { Loader2, RefreshCw, MessageCircle, ChevronDown, CreditCard, Undo2, Printer, FileText } from "lucide-react";
import { api, ApiError, ESTADOS_PEDIDO, type MiamiPedido } from "../api/miamiApi";
import { fmtARS } from "@/lib/format";
import { PageHeader, EmptyState } from "../components/PageShell";
import { Segmented } from "../components/Controls";
import Badge from "../components/Badge";
import { useToast } from "../components/Toast";
import type { Tone } from "../ui/estados";
import { cn } from "../ui/cn";
import Select from "@/components/Select";

// ============================================================================
//  PEDIDOS — lista real (/panel/api/orders), online y de mostrador juntas.
//  Igual que el panel viejo: detalle expandible con dirección + productos,
//  botón de WhatsApp con la plantilla "coordinar" pre-cargada, y "Verificar
//  pagos pendientes" (reconciliación contra Stripe). Suma lo que el backend
//  ya sabía hacer y el viejo no mostraba: cambio de estado y reembolso.
// ============================================================================

// El rótulo dice SIEMPRE si entró la plata. Diego preguntó por audio
// "figura pendiente... ¿porque no lo entregué o porque no pagó?": el estado
// del PAGO y el del ENVÍO son dos cosas distintas y hay que verlas separadas.
const badgePago: Record<string, { label: string; tone: Tone }> = {
  paid: { label: "PAGADO", tone: "green" },
  pending: { label: "SIN PAGAR", tone: "amber" },
  cancelled: { label: "Cancelado", tone: "neutral" },
  refunded: { label: "Reembolsado", tone: "blue" },
  failed: { label: "Pago rechazado", tone: "red" },
};

// Qué significa cada estado de pago, en criollo, dentro del detalle.
const explicaPago: Record<string, string> = {
  paid: "La plata entró. Se puede despachar.",
  pending: "El cliente NO pagó todavía. No despachar hasta que figure PAGADO.",
  cancelled: "El pedido se canceló. No se cobró nada.",
  refunded: "Se le devolvió la plata al cliente.",
  failed: "La tarjeta fue rechazada. No entró plata.",
};

const rotuloEstado: Record<string, string> = {
  pending: "Pendiente", paid: "Pagado", processing: "Preparando",
  shipped: "Enviado", delivered: "Entregado", cancelled: "Cancelado", refunded: "Reembolsado",
};

export default function Pedidos() {
  const { push } = useToast();
  const [pedidos, setPedidos] = useState<MiamiPedido[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [filtro, setFiltro] = useState("todos");
  const [abierto, setAbierto] = useState<number | null>(null);
  const [reconciliando, setReconciliando] = useState(false);
  const [reconcilInfo, setReconcilInfo] = useState("");

  const cargar = async () => {
    try {
      setError(null);
      setPedidos(await api.pedidos(100));
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "No se pudieron cargar los pedidos");
      setPedidos([]);
    }
  };

  useEffect(() => {
    void cargar();
  }, []);

  const filtrados = useMemo(() => {
    if (!pedidos) return [];
    if (filtro === "todos") return pedidos;
    return pedidos.filter((p) => p.payment_status === filtro);
  }, [pedidos, filtro]);

  const conteo = (st: string) => pedidos?.filter((p) => p.payment_status === st).length ?? 0;

  const reconciliar = async () => {
    setReconciliando(true);
    setReconcilInfo("");
    try {
      const r = await api.reconciliarPagos();
      const partes = [`Revisados: ${r.revisados}`, `acreditados: ${r.acreditados.length}`];
      if (r.sin_pagar.length) partes.push(`sin pagar: ${r.sin_pagar.length}`);
      if (r.para_revisar.length) partes.push(`a revisar: ${r.para_revisar.length}`);
      if (r.errores.length) partes.push(`errores: ${r.errores.length}`);
      setReconcilInfo(partes.join(" · ") + (r.acreditados.length ? " — pedidos: " + r.acreditados.map((a) => `#${a.pedido}`).join(", ") : ""));
      push(r.acreditados.length ? `${r.acreditados.length} pedido(s) acreditado(s)` : "No había pagos pendientes de acreditar", r.acreditados.length ? "success" : "info");
      void cargar();
    } catch (e) {
      // Local sin Stripe configurado → 503: se muestra tal cual, sin inventar.
      push(e instanceof ApiError ? e.message : "No se pudo reconciliar", "error");
    } finally {
      setReconciliando(false);
    }
  };

  const cambiarEstado = async (p: MiamiPedido, status: string) => {
    try {
      await api.setEstadoPedido(p.id, status);
      setPedidos((prev) => prev?.map((x) => (x.id === p.id ? { ...x, status } : x)) ?? null);
      push(`Pedido #${p.number} → ${rotuloEstado[status] || status}`, "success");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo cambiar el estado", "error");
    }
  };

  const reembolsar = async (p: MiamiPedido) => {
    if (!window.confirm(`¿Reembolsar el pedido #${p.number} por ${fmtARS(parseFloat(p.total || "0"))}? Se le devuelve la plata al cliente por Stripe y se repone el stock.`)) return;
    try {
      await api.reembolsarPedido(p.id);
      push(`Pedido #${p.number} reembolsado`, "success");
      void cargar();
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo reembolsar", "error");
    }
  };

  const abrirWhatsapp = (p: MiamiPedido) => {
    const phone = p.contact_phone || (p.shipping_address?.phone as string) || "";
    // Mensaje con el DETALLE del pedido (producto + talle + total): antes iba
    // una plantilla genérica y Diego tenía que tipear todo de nuevo.
    const items = p.products
      .map((it) => `• ${it.name}${it.talle ? ` (talle ${it.talle})` : ""} ×${it.quantity}`)
      .join("\n");
    const nombre = (p.contact_name || "").split(" ")[0];
    const pendiente = p.payment_status === "pending";
    const msg = pendiente
      ? `¡Hola${nombre ? " " + nombre : ""}! Te escribo de Miami Import por tu pedido #${p.number}:\n${items}\nTotal: ${fmtARS(parseFloat(p.total || "0"))}\nVi que el pago quedó pendiente, ¿te ayudo a terminarlo?`
      : `¡Hola${nombre ? " " + nombre : ""}! Te escribo de Miami Import por tu pedido #${p.number}:\n${items}\nTotal: ${fmtARS(parseFloat(p.total || "0"))}\n¡Ya lo estamos preparando! Te aviso apenas salga el envío.`;
    window.open(`https://wa.me/${phone.replace(/\D/g, "").replace(/^0/, "").replace(/^(?!54)/, "54")}?text=${encodeURIComponent(msg)}`, "_blank");
  };

  const imprimirEtiqueta = (p: MiamiPedido) => {
    window.open(`/panel/api/orders/${p.id}/etiqueta`, "_blank");
  };

  // Comprobante de la venta, con el ID de la transacción: es el respaldo que
  // Diego pidió para archivar y compartir cada compra.
  const verComprobante = (p: MiamiPedido) => {
    window.open(`/panel/api/orders/${p.id}/comprobante`, "_blank");
  };

  return (
    <div>
      <PageHeader
        title="Pedidos"
        subtitle={pedidos ? `${pedidos.length} pedidos · online y mostrador juntos` : "Cargando…"}
        actions={
          <>
            <button
              onClick={reconciliar}
              disabled={reconciliando}
              title="Consulta a Stripe si los pedidos pendientes ya fueron pagados"
              className="inline-flex h-10 items-center gap-2 rounded-xl border border-graph/15 bg-graph/[0.03] px-4 text-sm font-semibold text-graph transition hover:border-graph/30 disabled:opacity-50"
            >
              {reconciliando ? <Loader2 size={15} className="animate-spin" /> : <CreditCard size={15} />} Verificar pagos pendientes
            </button>
            <button onClick={() => { setPedidos(null); void cargar(); }} className="inline-flex h-10 items-center gap-2 rounded-xl border border-graph/15 px-4 text-sm font-medium text-graph-500 transition hover:text-graph">
              <RefreshCw size={15} /> Actualizar
            </button>
          </>
        }
      />

      {reconcilInfo && <p className="mb-4 rounded-xl bg-graph/[0.03] px-3 py-2 text-xs text-graph-500 ring-1 ring-inset ring-graph/[0.06]">{reconcilInfo}</p>}

      <div className="mb-4">
        <Segmented
          value={filtro}
          onChange={setFiltro}
          options={[
            { value: "todos", label: "Todos", count: pedidos?.length ?? 0 },
            { value: "paid", label: "Pagados ✓", count: conteo("paid") },
            { value: "pending", label: "Sin pagar", count: conteo("pending") },
            { value: "cancelled", label: "Cancelados", count: conteo("cancelled") },
            { value: "refunded", label: "Reembolsados", count: conteo("refunded") },
          ]}
        />
      </div>

      {pedidos === null ? (
        <div className="grid place-items-center py-24 text-graph-400"><Loader2 className="animate-spin" /></div>
      ) : error ? (
        <EmptyState msg={error} />
      ) : filtrados.length === 0 ? (
        <EmptyState msg={filtro === "todos" ? "Todavía no hay pedidos. Cuando alguien compre en la tienda (o cobres en el local) aparecen acá." : "No hay pedidos con ese estado."} />
      ) : (
        <div className="space-y-2.5">
          {filtrados.map((p) => {
            const b = badgePago[p.payment_status] || { label: p.payment_status, tone: "neutral" as Tone };
            const d = p.shipping_address || {};
            const calle = [d.street, d.number].filter(Boolean).join(" ") + (d.floor ? `, ${d.floor}` : "");
            const loc = [d.city, d.province, d.zipcode].filter(Boolean).join(" · ");
            const esLocal = d.canal === "local";
            const open = abierto === p.id;
            const phone = p.contact_phone || (d.phone as string) || "";
            return (
              <div key={p.id} className="pcard overflow-hidden">
                <button onClick={() => setAbierto(open ? null : p.id)} className="flex w-full flex-wrap items-center gap-3 px-4 py-3 text-left transition hover:bg-graph/[0.02] md:flex-nowrap">
                  <span className="w-16 shrink-0 font-display text-sm font-bold text-graph">#{p.number}</span>
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-semibold text-graph">{p.contact_name || "—"}</span>
                    <span className="block truncate text-xs text-graph-400">{p.contact_email || (esLocal ? "venta de mostrador" : "")}</span>
                  </span>
                  <span className="hidden text-xs text-graph-400 sm:block">{p.created_at ? new Date(p.created_at).toLocaleDateString("es-AR") : "—"}</span>
                  <span className="w-24 text-right font-display text-sm font-semibold text-graph">{fmtARS(parseFloat(p.total || "0"))}</span>
                  <Badge tone={b.tone} dot>{b.label}</Badge>
                  {esLocal && <Badge tone="neutral">Local</Badge>}
                  <ChevronDown size={15} className={cn("shrink-0 text-graph-400 transition-transform", open && "rotate-180")} />
                </button>

                {open && (
                  <div className="border-t border-graph/[0.07] bg-graph/[0.02] px-4 py-4">
                    <div className={cn(
                      "mb-4 rounded-xl px-3 py-2 text-sm font-medium",
                      p.payment_status === "paid" ? "bg-green-500/10 text-green-800"
                        : p.payment_status === "pending" ? "bg-amber-500/10 text-amber-900"
                        : "bg-graph/[0.05] text-graph-500",
                    )}>
                      {explicaPago[p.payment_status] || p.payment_status}
                    </div>

                    {/* La prueba de que entro la plata. Un "PAGADO" es palabra
                        nuestra; esto es lo que devolvio Stripe, con el link al
                        recibo oficial que el cliente y el banco pueden abrir. */}
                    {p.pago?.estado === "paid" && (
                      <div className="mb-4 rounded-xl border border-green-600/20 bg-green-500/[0.06] px-3 py-3">
                        <p className="text-[11px] font-semibold uppercase tracking-wide text-green-800">
                          Pago verificado en Stripe
                        </p>
                        <dl className="mt-2 space-y-1 text-xs text-graph-600">
                          {p.pago.acreditado_en && (
                            <div className="flex justify-between gap-3">
                              <dt className="text-graph-400">Acreditado</dt>
                              <dd className="font-medium text-graph">
                                {new Date(p.pago.acreditado_en).toLocaleString("es-AR", {
                                  day: "2-digit", month: "2-digit", year: "numeric",
                                  hour: "2-digit", minute: "2-digit",
                                })} hs
                              </dd>
                            </div>
                          )}
                          {p.pago.tarjeta && (
                            <div className="flex justify-between gap-3">
                              <dt className="text-graph-400">Tarjeta</dt>
                              <dd className="font-medium text-graph">{p.pago.tarjeta}</dd>
                            </div>
                          )}
                          {p.pago.cobro_id && (
                            <div className="flex justify-between gap-3">
                              <dt className="text-graph-400">Cobro</dt>
                              <dd className="truncate font-mono text-[11px] text-graph">{p.pago.cobro_id}</dd>
                            </div>
                          )}
                        </dl>
                        {p.pago.recibo_url && (
                          <a href={p.pago.recibo_url} target="_blank" rel="noreferrer"
                             className="mt-2.5 inline-block text-xs font-semibold text-green-800 underline underline-offset-2">
                            Ver el recibo oficial de Stripe →
                          </a>
                        )}
                      </div>
                    )}

                    <div className="grid gap-4 md:grid-cols-2">
                      <div>
                        <p className="text-[11px] font-semibold uppercase tracking-wide text-graph-400">Cliente</p>
                        <p className="mt-1 text-sm font-semibold text-graph">{p.contact_name || "—"}</p>
                        {p.contact_email && <p className="text-sm text-graph-500">{p.contact_email}</p>}
                        {phone && <p className="text-sm text-graph-500">Tel: {phone}</p>}
                        <p className="mt-2 text-[11px] font-semibold uppercase tracking-wide text-graph-400">Enviar a</p>
                        <p className="mt-1 text-sm text-graph">
                          {calle.trim() || loc ? `${calle.trim()}${calle.trim() && loc ? " — " : ""}${loc}` : <span className="text-graph-400">sin dirección cargada{esLocal ? " (venta en el local)" : ""}</span>}
                        </p>
                        {d.vendedor && <p className="mt-1 text-xs text-graph-400">Vendió: {String(d.vendedor)}</p>}
                      </div>
                      <div>
                        <p className="text-[11px] font-semibold uppercase tracking-wide text-graph-400">Productos</p>
                        <ul className="mt-1 space-y-1.5 text-sm text-graph">
                          {p.products.map((it, i) => (
                            <li key={i} className="flex flex-wrap items-center gap-2">
                              <span>{it.name} × {it.quantity}</span>
                              {it.talle && (
                                <span className="rounded-md bg-brand/10 px-2 py-0.5 font-display text-xs font-bold text-brand-700">
                                  Talle {it.talle}
                                </span>
                              )}
                              {it.price && <span className="text-graph-400">{fmtARS(parseFloat(it.price))}</span>}
                            </li>
                          ))}
                        </ul>
                      </div>
                    </div>

                    <div className="mt-4 flex flex-wrap items-center gap-2 border-t border-graph/[0.07] pt-3">
                      {phone ? (
                        <button onClick={() => abrirWhatsapp(p)} className="inline-flex h-9 items-center gap-1.5 rounded-lg bg-sea/10 px-3 text-xs font-semibold text-sea ring-1 ring-inset ring-sea/25 transition hover:bg-sea hover:text-white">
                          <MessageCircle size={14} /> WhatsApp con el pedido
                        </button>
                      ) : (
                        <span className="text-xs text-graph-400">Sin teléfono para WhatsApp</span>
                      )}
                      <button onClick={() => imprimirEtiqueta(p)} className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-graph/15 px-3 text-xs font-semibold text-graph transition hover:bg-graph/[0.05]" title="Hoja con destinatario, CP y contenido, lista para pegar en el paquete">
                        <Printer size={14} /> Etiqueta
                      </button>
                      <button onClick={() => verComprobante(p)} className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-graph/15 px-3 text-xs font-semibold text-graph transition hover:bg-graph/[0.05]" title="Comprobante de la venta con el número de transacción — para guardar o compartir">
                        <FileText size={14} /> Comprobante
                      </button>

                      <div className="ml-auto flex items-center gap-2">
                        <span className="text-[11px] font-medium uppercase tracking-wide text-graph-400">Estado</span>
                        <Select
                          value={ESTADOS_PEDIDO.includes(p.status as any) ? p.status : "pending"}
                          onChange={(v) => cambiarEstado(p, v)}
                          options={ESTADOS_PEDIDO.map((s) => ({ value: s, label: rotuloEstado[s] || s }))}
                          className="w-40"
                        />
                        {p.payment_status === "paid" && (
                          <button onClick={() => reembolsar(p)} className="inline-flex h-9 items-center gap-1.5 rounded-lg px-3 text-xs font-semibold text-graph-400 transition hover:bg-red-500/10 hover:text-red-600" title="Devuelve la plata por Stripe y repone stock">
                            <Undo2 size={14} /> Reembolsar
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
