import { useEffect, useMemo, useState } from "react";
import { Loader2, RefreshCw, MessageCircle, ChevronDown, CreditCard, Undo2, Printer, FileText, Link2, Banknote, ArrowRightLeft } from "lucide-react";
import { api, ApiError, ESTADOS_PEDIDO, type MiamiPedido } from "../api/miamiApi";
import { fmtARS } from "@/lib/format";
import { PageHeader, EmptyState } from "../components/PageShell";
import Modal from "../components/Modal";
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
  // La plata entró por un monto que no coincide con el pedido.
  review: { label: "REVISAR — PLATA RARA", tone: "red" },
};

// Qué significa cada estado de pago, en criollo, dentro del detalle.
const explicaPago: Record<string, string> = {
  paid: "La plata entró. Se puede despachar.",
  pending: "El cliente NO pagó todavía. No despachar hasta que figure PAGADO.",
  cancelled: "El pedido se canceló. No se cobró nada.",
  refunded: "Se le devolvió la plata al cliente.",
  // 🔴 Decía "La tarjeta fue rechazada" — y `failed` también cubre al que
  // NUNCA puso una tarjeta. Quedaba contra la línea de abajo, que ahora sí
  // distingue los casos: el encabezado afirmaba un motivo que no sabía.
  // Acá va SOLO lo que es cierto en los tres casos; el motivo lo dice el
  // renglón siguiente, que viene del backend con el dato de Stripe.
  failed: "El pago no se concretó. No entró plata.",
  review: "Stripe cobró un monto distinto al del pedido. La plata puede estar adentro. NO despaches hasta chequearlo en Stripe.",
};

const rotuloEstado: Record<string, string> = {
  pending: "Pendiente", paid: "Pagado", processing: "Preparando",
  shipped: "Enviado", delivered: "Entregado", cancelled: "Cancelado", refunded: "Reembolsado",
  backorder: "COBRADO SIN STOCK",
};

export default function Pedidos() {
  const { push } = useToast();
  const [pedidos, setPedidos] = useState<MiamiPedido[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [filtro, setFiltro] = useState("todos");
  const [abierto, setAbierto] = useState<number | null>(null);
  const [reconciliando, setReconciliando] = useState(false);
  // Devolver plata es irreversible: se confirma en un modal propio, no con el
  // window.confirm del navegador (bloquea el hilo y queda feo en el celular).
  const [aReembolsar, setAReembolsar] = useState<MiamiPedido | null>(null);
  const [reembolsando, setReembolsando] = useState(false);
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
      const res = await api.setEstadoPedido(p.id, status);
      // Cancelar devuelve la mercadería al stock y reactivar la vuelve a tomar.
      // Es plata: tiene que decirlo, no pasar en silencio. Y recargamos, porque
      // el estado del PAGO también pudo cambiar.
      push(`Pedido #${p.number} → ${rotuloEstado[status] || status}` +
           (res.aviso ? ` · ${res.aviso}` : ""), "success");
      void cargar();
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo cambiar el estado", "error");
    }
  };

  // Cobro por fuera de Stripe (mostrador, transferencia). Antes no habia
  // donde anotarlo y Diego terminaba usando el desplegable de ENVIO, que no
  // registra plata y encima dejaba que el barrido devolviera al stock algo ya
  // entregado.
  const registrarCobro = async (p: MiamiPedido,
                                medio: "efectivo" | "transferencia" | "posnet",
                                cuotas = 1) => {
    try {
      const r = await api.registrarCobroManual(p.id, medio, cuotas);
      push(r.aviso || `Cobro en ${medio} registrado`, r.estado === "backorder" ? "error" : "success");
      void cargar();
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo registrar el cobro", "error");
    }
  };

  const confirmarReembolso = async () => {
    const p = aReembolsar;
    if (!p) return;
    setReembolsando(true);
    try {
      await api.reembolsarPedido(p.id);
      push(`Pedido #${p.number} reembolsado · la mercadería volvió al stock`, "success");
      setAReembolsar(null);
      void cargar();
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo reembolsar", "error");
    } finally {
      setReembolsando(false);
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
    // 'review' NO va aca: a ese cliente la plata ya se le movio. Mandarle
    // "¿te ayudo a terminarlo?" es invitarlo a pagar dos veces.
    const pendiente = p.payment_status === "pending" || p.payment_status === "failed";
    const cabecera = `¡Hola${nombre ? " " + nombre : ""}! Te escribo de Miami Import por tu pedido #${p.number}:
${items}
Total: ${fmtARS(parseFloat(p.total || "0"))}`;

    // EL LINK ES LO QUE RESCATA LA VENTA. Antes decía "¿te ayudo a terminarlo?"
    // y no mandaba nada: el cliente tenía que volver a la web y rearmar el
    // carrito — y si era la última unidad, la veía agotada por su propia
    // reserva. El link cobra ESTE pedido, con su precio y su talle.
    const linkPago = p.link_pago ? window.location.origin + p.link_pago : null;

    let msg: string;
    if (pendiente && linkPago) {
      msg = `${cabecera}
Te dejo el link para terminar de pagarlo:
${linkPago}`;
    } else if (pendiente) {
      // Sin link = la reserva venció y el pedido se cerró. Prometer que "lo
      // terminás con este link" sería mentira: hay que rearmar la compra.
      msg = `${cabecera}
El pedido quedó sin pagar y se liberó. Si lo querés, avisame y lo armamos de nuevo.`;
    } else {
      msg = `${cabecera}
¡Ya lo estamos preparando! Te aviso apenas salga el envío.`;
    }
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
            // "Cobrado sin stock" pisa al cartel verde de PAGADO: es el UNICO
            // caso donde la plata entro y NO hay que despachar. Si se muestra
            // como un pagado normal, Diego manda algo que no tiene.
            const b = p.status === "backorder"
              ? { label: "COBRADO SIN STOCK", tone: "red" as Tone }
              : (badgePago[p.payment_status] || { label: p.payment_status, tone: "neutral" as Tone });
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
                      p.status === "backorder" || p.payment_status === "review"
                        ? "bg-red-500/10 text-red-900"
                        : p.payment_status === "paid" ? "bg-green-500/10 text-green-800"
                        : p.payment_status === "pending" ? "bg-amber-500/10 text-amber-900"
                        : "bg-graph/[0.05] text-graph-500",
                    )}>
                      {p.status === "backorder"
                        ? "Cobrado, pero NO hay mercadería para este pedido. NO despachar."
                        : (explicaPago[p.payment_status] || p.payment_status)}
                      {/* La pregunta textual de Diego: "¿intentó pagar y no pudo
                          o cómo es?". Esto lo contesta con lo que dice Stripe. */}
                      {p.pago?.motivo && (
                        <p className="mt-1.5 font-normal opacity-90">{p.pago.motivo}</p>
                      )}
                      {/* El cartel de "consultá a Stripe" solo tiene sentido si
                          la venta pasó por la web: una venta de mostrador nunca
                          tuvo un pago online que consultar. */}
                      {p.payment_status === "pending" && !p.pago?.motivo && !esLocal && (
                        <p className="mt-1.5 text-xs font-normal opacity-75">
                          Para saber si llegó a intentar el pago, apretá <strong>Reconciliar</strong> arriba:
                          le pregunta a Stripe y lo escribe acá.
                        </p>
                      )}
                      {esLocal && !p.pago?.motivo && (
                        <p className="mt-1.5 text-xs font-normal opacity-75">
                          Venta de mostrador: no pasó por la web, se cobra en el local.
                        </p>
                      )}
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
                        <ul className="mt-1 space-y-2.5 text-sm text-graph">
                          {p.products.map((it, i) => (
                            <li key={i} className="flex items-center gap-3">
                              {/* La prenda, en foto. Diego despacha mirando esto:
                                  "Remera Diesel de dama, talle S" son tres remeras
                                  distintas. Click = la foto entera en otra pestaña. */}
                              {it.foto ? (
                                <a href={it.foto.split("?")[0]} target="_blank" rel="noreferrer"
                                   title="Ver la foto entera"
                                   className="shrink-0 overflow-hidden rounded-lg ring-1 ring-graph/10 transition hover:ring-graph/30">
                                  <img src={it.foto} alt={it.name} loading="lazy"
                                       className="h-16 w-12 bg-graph/[0.03] object-cover" />
                                </a>
                              ) : (
                                <span className="grid h-16 w-12 shrink-0 place-items-center rounded-lg bg-graph/[0.03] text-[10px] leading-tight text-graph-400 ring-1 ring-graph/10">
                                  sin<br />foto
                                </span>
                              )}
                              <span className="flex flex-wrap items-center gap-2">
                                <span>{it.name} × {it.quantity}</span>
                                {it.talle && (
                                  <span className="rounded-md bg-brand/10 px-2 py-0.5 font-display text-xs font-bold text-brand-700">
                                    Talle {it.talle}
                                  </span>
                                )}
                                {it.price && <span className="text-graph-400">{fmtARS(parseFloat(it.price))}</span>}
                              </span>
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
                        {p.payment_status !== "paid" && p.payment_status !== "refunded"
                          && p.status !== "cancelled" && (
                          <>
                            <button
                              onClick={() => void registrarCobro(p, "efectivo")}
                              title="Anota que lo cobraste en efectivo. Queda registrado en Mi plata."
                              className="inline-flex h-9 items-center gap-1.5 rounded-lg px-3 text-xs font-semibold text-graph-500 transition hover:bg-green-500/10 hover:text-green-700"
                            >
                              <Banknote size={14} /> Cobré en efectivo
                            </button>
                            <button
                              onClick={() => void registrarCobro(p, "transferencia")}
                              title="Anota que te transfirieron. Queda registrado en Mi plata."
                              className="inline-flex h-9 items-center gap-1.5 rounded-lg px-3 text-xs font-semibold text-graph-500 transition hover:bg-green-500/10 hover:text-green-700"
                            >
                              <ArrowRightLeft size={14} /> Me transfirieron
                            </button>
                            {/* EN CUOTAS. Stripe no las hace para tarjetas
                                argentinas, así que hoy la única forma es el link
                                de pago del posnet propio. Se cobra por afuera y
                                se anota acá, con el plan, para que la venta
                                exista en Mi plata. */}
                            <select
                              defaultValue=""
                              onChange={(e) => {
                                const c = parseInt(e.target.value, 10);
                                e.target.value = "";
                                if (c) void registrarCobro(p, "posnet", c);
                              }}
                              title="Cobraste con el link de pago de tu posnet, en cuotas"
                              className="h-9 rounded-lg border border-graph/15 bg-transparent px-2 text-xs font-semibold text-graph-500"
                            >
                              <option value="">Cobré en cuotas…</option>
                              <option value="1">Posnet · 1 pago</option>
                              <option value="3">Posnet · 3 cuotas</option>
                              <option value="6">Posnet · 6 cuotas</option>
                              <option value="9">Posnet · 9 cuotas</option>
                              <option value="12">Posnet · 12 cuotas</option>
                            </select>
                          </>
                        )}
                        {p.link_pago && (
                          <button
                            onClick={() => {
                              navigator.clipboard.writeText(window.location.origin + p.link_pago);
                              push("Link de pago copiado", "success");
                            }}
                            title="Copia el link para que el cliente pague ESTE pedido"
                            className="inline-flex h-9 items-center gap-1.5 rounded-lg px-3 text-xs font-semibold text-graph-500 transition hover:bg-graph/[0.06] hover:text-graph"
                          >
                            <Link2 size={14} /> Copiar link de pago
                          </button>
                        )}
                        {p.payment_status === "paid" && (
                          <button onClick={() => setAReembolsar(p)} className="inline-flex h-9 items-center gap-1.5 rounded-lg px-3 text-xs font-semibold text-graph-400 transition hover:bg-red-500/10 hover:text-red-600" title="Devuelve la plata por Stripe y repone stock">
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

      {/* Devolver plata es irreversible: modal propio, con el monto y el nombre
          a la vista, para que no se reembolse el pedido equivocado de un click. */}
      <Modal
        open={!!aReembolsar}
        onClose={() => !reembolsando && setAReembolsar(null)}
        title={aReembolsar ? `Reembolsar el pedido #${aReembolsar.number}` : ""}
        subtitle="Esto no se puede deshacer."
        footer={
          <div className="flex justify-end gap-2">
            <button
              onClick={() => setAReembolsar(null)}
              disabled={reembolsando}
              className="h-10 rounded-xl border border-graph/15 px-4 text-sm font-medium text-graph-500 transition hover:text-graph disabled:opacity-50"
            >
              No, volver
            </button>
            <button
              onClick={() => void confirmarReembolso()}
              disabled={reembolsando}
              className="h-10 rounded-xl bg-red-600 px-4 text-sm font-semibold text-white transition hover:bg-red-700 disabled:opacity-60"
            >
              {reembolsando ? "Reembolsando…" : "Sí, devolver la plata"}
            </button>
          </div>
        }
      >
        {aReembolsar && (
          <div className="space-y-3 text-sm text-graph">
            <p>
              Se le devuelven <strong>{fmtARS(parseFloat(aReembolsar.total || "0"))}</strong> a{" "}
              <strong>{aReembolsar.contact_name || "el cliente"}</strong> por Stripe.
            </p>
            <ul className="list-disc space-y-1 pl-5 text-graph-500">
              <li>La plata sale de la cuenta de Stripe y vuelve a su tarjeta.</li>
              <li>La mercadería vuelve al stock y queda otra vez a la venta.</li>
              <li>El pedido queda marcado como <strong>Reembolsado</strong>.</li>
            </ul>
          </div>
        )}
      </Modal>
    </div>
  );
}
