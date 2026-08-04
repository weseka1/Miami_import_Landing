import { useEffect, useRef, useState } from "react";
import { Loader2, Plus, Minus, X, ShoppingBag, QrCode, Check, ExternalLink, PackagePlus } from "lucide-react";
import { api, ApiError, type PosProducto, type PosItemVenta, type PosVentaCreada } from "../api/miamiApi";
import { PageHeader, EmptyState } from "../components/PageShell";
import { SearchInput } from "../components/Controls";
import { useToast } from "../components/Toast";
import { useData } from "@/lib/DataProvider";
import { cn } from "../ui/cn";

// ============================================================================
//  VENDER (punto de venta) — venta de mostrador contra el backend REAL.
//  Flujo (idéntico al panel viejo, ver web-tienda/panel/pos.py):
//    armar carrito → POST /pos/venta (reserva stock) → QR → el cliente paga
//    con su celular por Stripe → la pantalla se entera sola (poll cada 3 s).
//  El precio SIEMPRE lo pone el backend desde la base; el único importe manual
//  es el "ítem suelto", que queda auditado del lado del server.
// ============================================================================

type LineaCarrito =
  | { tipo: "catalogo"; variant_id: number; nombre: string; talle: string; precio: number; stock: number; cantidad: number }
  | { tipo: "libre"; uid: number; nombre: string; precio: number; cantidad: number };

const claveDe = (l: LineaCarrito) => (l.tipo === "libre" ? `L${l.uid}` : `V${l.variant_id}`);

const fmt = (n: number) => "$ " + Math.round(n).toLocaleString("es-AR");

export default function Vender() {
  const { push } = useToast();
  const { recargar } = useData();

  // --- catálogo vendible ---
  const [q, setQ] = useState("");
  const [catalogo, setCatalogo] = useState<PosProducto[]>([]);
  const [buscando, setBuscando] = useState(true);
  const [errorCat, setErrorCat] = useState<string | null>(null);

  const debounce = useRef<ReturnType<typeof setTimeout>>();
  const buscar = async (term: string) => {
    try {
      setErrorCat(null);
      const r = await api.posBuscar(term);
      setCatalogo(r.productos);
    } catch (e) {
      setErrorCat(e instanceof ApiError ? e.message : "No se pudo buscar");
    } finally {
      setBuscando(false);
    }
  };
  useEffect(() => { void buscar(""); }, []);
  useEffect(() => {
    clearTimeout(debounce.current);
    debounce.current = setTimeout(() => { void buscar(q); }, 250);
    return () => clearTimeout(debounce.current);
  }, [q]); // eslint-disable-line react-hooks/exhaustive-deps

  // --- carrito ---
  const [carrito, setCarrito] = useState<LineaCarrito[]>([]);
  const [cliente, setCliente] = useState("");
  const [telefono, setTelefono] = useState("");
  const total = carrito.reduce((a, l) => a + l.precio * l.cantidad, 0);

  const agregar = (p: PosProducto, vid: number) => {
    const v = p.variantes.find((x) => x.variant_id === vid);
    if (!v) return;
    const ya = carrito.find((l) => l.tipo === "catalogo" && l.variant_id === vid);
    const enCarrito = ya?.cantidad ?? 0;
    if (enCarrito + 1 > v.stock) {
      push(`Solo quedan ${v.stock} de ${p.nombre} (${v.talle})`, "error");
      return;
    }
    setCarrito((prev) =>
      ya
        ? prev.map((l) => (claveDe(l) === claveDe(ya) ? { ...l, cantidad: l.cantidad + 1 } : l))
        : [...prev, { tipo: "catalogo", variant_id: vid, nombre: p.nombre, talle: v.talle, precio: parseFloat(v.precio || "0"), stock: v.stock, cantidad: 1 }]
    );
  };

  const cambiar = (clave: string, delta: number) => {
    setCarrito((prev) => prev.flatMap((l) => {
      if (claveDe(l) !== clave) return [l];
      const n = l.cantidad + delta;
      if (n < 1) return [];
      if (l.tipo === "catalogo" && n > l.stock) { push(`Solo quedan ${l.stock}`, "error"); return [l]; }
      if (n > 99) { push("Máximo 99 por ítem", "error"); return [l]; }
      return [{ ...l, cantidad: n }];
    }));
  };

  const vaciar = () => { setCarrito([]); setCliente(""); setTelefono(""); };

  // --- ítem suelto (no está en el catálogo; el precio queda auditado) ---
  const [libreOpen, setLibreOpen] = useState(false);
  const [libre, setLibre] = useState({ nombre: "", precio: "", cantidad: "1" });
  const uidRef = useRef(0);
  const agregarLibre = () => {
    const nombre = libre.nombre.trim();
    const precio = parseFloat(libre.precio);
    const cant = parseInt(libre.cantidad) || 1;
    if (!nombre) { push("Poné qué se vende", "error"); return; }
    if (!(precio > 0)) { push("Poné un precio válido", "error"); return; }
    if (cant < 1 || cant > 99) { push("Cantidad entre 1 y 99", "error"); return; }
    setCarrito((prev) => [...prev, { tipo: "libre", uid: ++uidRef.current, nombre, precio, cantidad: cant }]);
    setLibre({ nombre: "", precio: "", cantidad: "1" });
    setLibreOpen(false);
    push("Agregado a la venta", "success");
  };

  // --- cobro ---
  const [venta, setVenta] = useState<PosVentaCreada | null>(null);
  const [pagado, setPagado] = useState(false);
  const [cobrando, setCobrando] = useState(false);
  const pollRef = useRef<ReturnType<typeof setInterval>>();

  const cobrar = async () => {
    if (!cliente.trim()) { push("Poné el nombre del cliente", "error"); return; }
    if (!carrito.length) return;
    setCobrando(true);
    try {
      const items: PosItemVenta[] = carrito.map((l) =>
        l.tipo === "libre"
          ? { libre: true, nombre: l.nombre, precio: l.precio, cantidad: l.cantidad }
          : { variant_id: l.variant_id, cantidad: l.cantidad }
      );
      const r = await api.posCrearVenta({ cliente: cliente.trim(), telefono: telefono.trim(), items });
      setVenta(r);
      setPagado(false);
      // Poll: la tablet se entera sola cuando Stripe acredita.
      clearInterval(pollRef.current);
      pollRef.current = setInterval(async () => {
        try {
          const e = await api.posEstadoVenta(r.order_id);
          if (e.pagado) {
            clearInterval(pollRef.current);
            setPagado(true);
            push("Pago recibido", "success");
            setCarrito([]);
            void recargar(); // el stock cambió en toda la app
          }
        } catch { /* reintenta en el próximo tick */ }
      }, 3000);
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo generar el cobro", "error");
    } finally {
      setCobrando(false);
    }
  };

  const cerrarCobro = () => {
    clearInterval(pollRef.current);
    setVenta(null);
    void buscar(q); // refrescar stock reservado
  };

  const cancelarVenta = async () => {
    if (!venta) { cerrarCobro(); return; }
    if (!window.confirm("¿Cancelar esta venta? Se devuelve el stock reservado.")) return;
    try {
      await api.posCancelarVenta(venta.order_id);
      push("Venta cancelada — stock devuelto", "info");
      vaciar();
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo cancelar", "error");
    }
    cerrarCobro();
  };

  useEffect(() => () => clearInterval(pollRef.current), []);

  return (
    <div>
      <PageHeader
        title="Vender en el local"
        subtitle="Armá la venta, cobrala con QR y queda registrada en Pedidos. El stock se reserva al cobrar."
      />

      <div className="grid gap-5 xl:grid-cols-[1.6fr_1fr]">
        {/* ===== catálogo ===== */}
        <div className="min-w-0">
          <div className="pcard mb-4 flex flex-wrap items-center gap-2.5 p-3">
            <SearchInput value={q} onChange={setQ} placeholder="Buscar producto o marca…" className="min-w-[220px] flex-1" />
            <button
              onClick={() => setLibreOpen((v) => !v)}
              className="inline-flex h-10 items-center gap-2 rounded-xl border border-dashed border-graph/25 px-3 text-xs font-semibold text-graph-500 transition hover:border-brand hover:text-brand"
            >
              <PackagePlus size={15} /> No está en el catálogo
            </button>
          </div>

          {libreOpen && (
            <div className="pcard mb-4 p-4">
              <p className="mb-3 text-[11px] font-semibold uppercase tracking-wide text-graph-400">Cobrar algo no cargado (queda auditado)</p>
              <div className="grid gap-3 sm:grid-cols-[1fr_140px_100px]">
                <input value={libre.nombre} onChange={(e) => setLibre((s) => ({ ...s, nombre: e.target.value }))} placeholder="¿Qué se vende? Ej: Cinturón de cuero" autoFocus
                  className="h-10 w-full rounded-xl border border-graph/10 bg-graph/[0.04] px-3 text-sm text-graph placeholder:text-graph-400 outline-none transition focus:border-brand/60" />
                <input value={libre.precio} onChange={(e) => setLibre((s) => ({ ...s, precio: e.target.value.replace(/[^\d.]/g, "") }))} placeholder="Precio" inputMode="decimal"
                  onKeyDown={(e) => { if (e.key === "Enter") { e.preventDefault(); agregarLibre(); } }}
                  className="h-10 w-full rounded-xl border border-graph/10 bg-graph/[0.04] px-3 text-sm text-graph placeholder:text-graph-400 outline-none transition focus:border-brand/60" />
                <input value={libre.cantidad} onChange={(e) => setLibre((s) => ({ ...s, cantidad: e.target.value.replace(/[^\d]/g, "") }))} placeholder="Cant." inputMode="numeric"
                  className="h-10 w-full rounded-xl border border-graph/10 bg-graph/[0.04] px-3 text-center text-sm text-graph outline-none transition focus:border-brand/60" />
              </div>
              <div className="mt-3 flex gap-2">
                <button onClick={agregarLibre} className="inline-flex h-10 items-center gap-2 rounded-xl bg-brand px-4 text-sm font-semibold text-white transition hover:bg-brand-600">
                  <Plus size={15} /> Agregar a la venta
                </button>
                <button onClick={() => setLibreOpen(false)} className="inline-flex h-10 items-center rounded-xl border border-graph/15 px-4 text-sm font-medium text-graph-500 transition hover:text-graph">Cancelar</button>
              </div>
            </div>
          )}

          {buscando ? (
            <div className="grid place-items-center py-20 text-graph-400"><Loader2 className="animate-spin" /></div>
          ) : errorCat ? (
            <EmptyState msg={errorCat} />
          ) : catalogo.length === 0 ? (
            <EmptyState msg="No hay productos con stock para vender." />
          ) : (
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              {catalogo.map((p) => (
                <div key={p.product_id} className="pcard flex gap-3 p-3">
                  <div className="h-20 w-20 shrink-0 overflow-hidden rounded-xl bg-paper-200 ring-1 ring-graph/10">
                    {p.imagen ? <img src={p.imagen} alt="" loading="lazy" className="h-full w-full object-cover" /> : <ShoppingBag size={20} className="m-auto mt-7 text-graph-400" />}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-[10px] font-semibold uppercase tracking-widest2 text-graph-400">{p.marca || "Sin marca"}</p>
                    <p className="line-clamp-1 text-sm font-semibold text-graph">{p.nombre}</p>
                    <div className="mt-2 flex flex-wrap gap-1.5">
                      {p.variantes.map((v) => (
                        <button
                          key={v.variant_id}
                          onClick={() => agregar(p, v.variant_id)}
                          title={`${v.talle} — quedan ${v.stock}`}
                          className="inline-flex min-h-[36px] flex-col items-center rounded-lg border border-graph/15 bg-graph/[0.03] px-2.5 py-1 leading-tight transition hover:border-brand hover:bg-brand hover:text-white"
                        >
                          <span className="text-xs font-bold">{v.talle}</span>
                          <span className="text-[10px] opacity-70">{fmt(parseFloat(v.precio || "0"))}</span>
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* ===== carrito ===== */}
        <aside className="min-w-0">
          <div className="pcard sticky top-20 p-5">
            <h3 className="mb-3 font-display text-base font-semibold text-graph">Venta actual</h3>

            {carrito.length === 0 ? (
              <p className="rounded-xl bg-graph/[0.03] px-3 py-6 text-center text-sm text-graph-400">Tocá un talle para agregarlo.</p>
            ) : (
              <div className="space-y-2">
                {carrito.map((l) => (
                  <div key={claveDe(l)} className="flex items-center gap-2 rounded-xl border border-graph/[0.08] p-2.5">
                    <div className="min-w-0 flex-1">
                      <p className="line-clamp-1 text-sm font-semibold text-graph">
                        {l.nombre}
                        {l.tipo === "libre" && <span className="ml-1.5 rounded bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-bold uppercase text-amber-700">suelto</span>}
                      </p>
                      <p className="text-xs text-graph-400">{l.tipo === "catalogo" ? `Talle ${l.talle} · ` : ""}{fmt(l.precio)}</p>
                    </div>
                    <div className="flex items-center gap-1">
                      <button onClick={() => cambiar(claveDe(l), -1)} className="grid h-8 w-8 place-items-center rounded-lg border border-graph/15 text-graph-500 transition hover:border-brand hover:text-brand"><Minus size={13} /></button>
                      <span className="w-6 text-center text-sm font-bold text-graph">{l.cantidad}</span>
                      <button onClick={() => cambiar(claveDe(l), 1)} className="grid h-8 w-8 place-items-center rounded-lg border border-graph/15 text-graph-500 transition hover:border-brand hover:text-brand"><Plus size={13} /></button>
                    </div>
                    <span className="w-20 text-right text-sm font-semibold text-graph">{fmt(l.precio * l.cantidad)}</span>
                  </div>
                ))}
              </div>
            )}

            <div className="mt-4 flex items-center justify-between border-t border-graph/[0.07] pt-3">
              <span className="text-sm font-medium text-graph-500">Total</span>
              <span className="font-display text-xl font-semibold text-graph">{fmt(total)}</span>
            </div>

            <label className="mt-4 block">
              <span className="mb-1 block text-[11px] font-medium uppercase tracking-wide text-graph-400">Cliente</span>
              <input value={cliente} onChange={(e) => setCliente(e.target.value)} placeholder="Nombre y apellido"
                className="h-10 w-full rounded-xl border border-graph/15 bg-paper-100 px-3 text-sm text-graph outline-none transition placeholder:text-graph-400 focus:border-brand/60 focus:ring-2 focus:ring-brand/15" />
            </label>
            <label className="mt-3 block">
              <span className="mb-1 block text-[11px] font-medium uppercase tracking-wide text-graph-400">Teléfono <span className="normal-case text-graph-400">(opcional)</span></span>
              <input value={telefono} onChange={(e) => setTelefono(e.target.value)} placeholder="11 2233 4455" inputMode="tel"
                className="h-10 w-full rounded-xl border border-graph/15 bg-paper-100 px-3 text-sm text-graph outline-none transition placeholder:text-graph-400 focus:border-brand/60 focus:ring-2 focus:ring-brand/15" />
            </label>

            <button
              onClick={cobrar}
              disabled={carrito.length === 0 || cobrando}
              className="mt-4 inline-flex h-11 w-full items-center justify-center gap-2 rounded-xl bg-brand text-sm font-semibold text-white transition hover:bg-brand-600 disabled:opacity-40"
            >
              {cobrando ? <Loader2 size={16} className="animate-spin" /> : <QrCode size={16} />} Cobrar
            </button>
            <button onClick={vaciar} disabled={carrito.length === 0} className="mt-2 inline-flex h-10 w-full items-center justify-center rounded-xl border border-graph/15 text-sm font-medium text-graph-500 transition hover:text-graph disabled:opacity-40">
              Vaciar
            </button>
          </div>
        </aside>
      </div>

      {/* ===== modal de cobro con QR ===== */}
      {venta && (
        <div className="fixed inset-0 z-50 grid place-items-center bg-graph/40 p-4 backdrop-blur-sm">
          <div className="pcard w-full max-w-md p-8 text-center" style={{ animation: "fadeIn .18s ease-out" }}>
            <button onClick={cerrarCobro} className="absolute right-4 top-4 grid h-8 w-8 place-items-center rounded-lg text-graph-400 transition hover:bg-graph/5 hover:text-graph" aria-label="Cerrar">
              <X size={16} />
            </button>

            {!pagado ? (
              <>
                <h2 className="font-display text-xl font-semibold text-graph">Que el cliente escanee el código</h2>
                <p className="mt-1 text-sm text-graph-400">Paga con su celular. La pantalla se actualiza sola.</p>
                {/* SVG generado por NUESTRO backend (pos.py), no un CDN */}
                <div className="mx-auto mt-4 w-52 rounded-2xl bg-white p-3 ring-1 ring-graph/10 [&_svg]:h-full [&_svg]:w-full" dangerouslySetInnerHTML={{ __html: venta.qr_svg }} />
                <div className="mt-4 flex items-center justify-center gap-2 text-sm">
                  <span className="text-graph-400">Total a cobrar</span>
                  <span className="font-display text-lg font-semibold text-graph">{fmt(parseFloat(venta.total))}</span>
                </div>
                <a href={venta.url_pago} target="_blank" rel="noreferrer" className="mt-2 inline-flex items-center gap-1.5 text-xs font-semibold text-brand hover:underline">
                  <ExternalLink size={13} /> ¿No puede escanear? Abrir el link de pago
                </a>
                <p className="mt-4 inline-flex items-center gap-2 rounded-full bg-amber-500/10 px-3 py-1.5 text-xs font-semibold text-amber-700">
                  <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-amber-500" /> Esperando el pago…
                </p>
                <button onClick={cancelarVenta} className="mt-4 block w-full rounded-xl border border-graph/15 py-2.5 text-sm font-medium text-graph-500 transition hover:border-red-400/50 hover:text-red-600">
                  Cancelar venta
                </button>
              </>
            ) : (
              <>
                <span className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-sea/10 text-sea"><Check size={32} /></span>
                <h2 className="mt-4 font-display text-xl font-semibold text-graph">Pago recibido</h2>
                <p className="mt-1 text-sm text-graph-400">Venta #{venta.numero} registrada en Pedidos.</p>
                <button onClick={cerrarCobro} className="mt-5 inline-flex h-11 w-full items-center justify-center rounded-xl bg-brand text-sm font-semibold text-white transition hover:bg-brand-600">
                  Nueva venta
                </button>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
