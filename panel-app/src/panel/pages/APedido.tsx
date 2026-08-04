import { useEffect, useMemo, useState } from "react";
import { Loader2, RefreshCw, Bookmark, UploadCloud, X, Trash2, PackageSearch } from "lucide-react";
import { api, ApiError, fotoDe, precioDe, talleDe, type MiamiProducto } from "../api/miamiApi";
import { fmtARS } from "@/lib/format";
import { PageHeader, EmptyState } from "../components/PageShell";
import { SearchInput } from "../components/Controls";
import Badge from "../components/Badge";
import Drawer from "../components/Drawer";
import ProductoThumb from "../components/ProductoThumb";
import { useToast } from "../components/Toast";
import Select from "@/components/Select";

// ============================================================================
//  A PEDIDO — productos que NO son stock: se consiguen si un cliente los quiere.
//  No aparecen en la tienda. De cada uno se toman RESERVAS (nombre + talle),
//  que después se gestionan en la pestaña Reservas. Todo contra el backend real:
//  POST /products (a_pedido=true) · GET /products/a_pedido · POST /reservas.
// ============================================================================

type FotoLocal = { file: File; url: string };

export default function APedido() {
  const { push } = useToast();
  const [productos, setProductos] = useState<MiamiProducto[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [q, setQ] = useState("");
  const [sel, setSel] = useState<MiamiProducto | null>(null);

  const cargar = async () => {
    try {
      setError(null);
      setProductos(await api.aPedido());
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "No se pudo cargar");
      setProductos([]);
    }
  };
  useEffect(() => { void cargar(); }, []);

  const filtrados = useMemo(() => {
    if (!productos) return [];
    if (!q) return productos;
    const t = q.toLowerCase();
    return productos.filter((p) => `${p.name.es} ${p.brand || ""}`.toLowerCase().includes(t));
  }, [productos, q]);

  const eliminar = async (p: MiamiProducto) => {
    if (!window.confirm(`¿Eliminar "${p.name.es}" de la lista a pedido?`)) return;
    try {
      await api.eliminarProducto(p.id);
      setProductos((prev) => prev?.filter((x) => x.id !== p.id) ?? null);
      setSel(null);
      push("Producto eliminado", "info");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo eliminar", "error");
    }
  };

  return (
    <div>
      <PageHeader
        title="A pedido"
        subtitle="Productos que no tenés en stock pero podés conseguir. No salen en la tienda: acá se anotan los clientes que los quieren."
        actions={
          <button onClick={() => { setProductos(null); void cargar(); }} className="inline-flex h-10 items-center gap-2 rounded-xl border border-graph/15 px-4 text-sm font-medium text-graph-500 transition hover:text-graph">
            <RefreshCw size={15} /> Actualizar
          </button>
        }
      />

      <AltaAPedido onCreado={() => { void cargar(); }} />

      <div className="mb-4 mt-8 flex flex-wrap items-center justify-between gap-3">
        <h2 className="font-display text-lg font-semibold text-graph">Cargados</h2>
        <SearchInput value={q} onChange={setQ} placeholder="Buscar por nombre o marca…" className="w-72 max-w-full" />
      </div>

      {productos === null ? (
        <div className="grid place-items-center py-16 text-graph-400"><Loader2 className="animate-spin" /></div>
      ) : error ? (
        <EmptyState msg={error} />
      ) : filtrados.length === 0 ? (
        <EmptyState msg={q ? "Nada que coincida con la búsqueda." : "Todavía no cargaste productos a pedido. Usá el formulario de arriba."} />
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {filtrados.map((p) => {
            const precio = precioDe(p);
            return (
              <button key={p.id} onClick={() => setSel(p)} className="group pcard pcard-hover overflow-hidden text-left">
                <div className="relative">
                  <ProductoThumb src={fotoDe(p)} marca={p.brand} alt={p.name.es} rounded="rounded-none" className="h-44 w-full" placa />
                  <div className="absolute left-3 top-3"><Badge tone="blue" className="bg-white/90 backdrop-blur">A pedido</Badge></div>
                  <div className="absolute bottom-3 right-3">
                    <span className="rounded-lg bg-white/92 px-2.5 py-1 font-display text-sm font-semibold text-graph shadow-soft backdrop-blur">
                      {precio > 0 ? fmtARS(precio, { short: true }) : "A confirmar"}
                    </span>
                  </div>
                </div>
                <div className="p-4">
                  <h3 className="line-clamp-1 font-display text-base font-semibold text-graph">{p.name.es}</h3>
                  <p className="mt-1 text-xs text-graph-400">{p.brand || "Sin marca"} · {p.variants.map((v) => talleDe(v)).join(" · ")}</p>
                  <p className="mt-2 inline-flex items-center gap-1.5 text-xs font-semibold text-brand">
                    <Bookmark size={13} /> Tocar para reservar a un cliente
                  </p>
                </div>
              </button>
            );
          })}
        </div>
      )}

      <ReservaDrawer producto={sel} onClose={() => setSel(null)} onDelete={eliminar} />
    </div>
  );
}

/* ===================== Alta "a pedido" (multipart real) ===================== */

function AltaAPedido({ onCreado }: { onCreado: () => void }) {
  const { push } = useToast();
  const [f, setF] = useState({ nombre: "", marca: "", precio: "", talles: "", descripcion: "" });
  const [fotos, setFotos] = useState<FotoLocal[]>([]);
  const [enviando, setEnviando] = useState(false);

  const sumarFotos = (files: FileList | null) => {
    if (!files) return;
    const nuevas: FotoLocal[] = [];
    for (const file of Array.from(files)) {
      if (!file.type.startsWith("image/")) continue;
      if (file.size > 8 * 1024 * 1024) { push(`"${file.name}" pesa más de 8 MB`, "error"); continue; }
      nuevas.push({ file, url: URL.createObjectURL(file) });
    }
    if (nuevas.length) setFotos((p) => [...p, ...nuevas]);
  };

  const guardar = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!f.nombre.trim() || !f.marca.trim()) { push("Completá nombre y marca", "info"); return; }
    const fd = new FormData();
    fd.append("name", f.nombre.trim());
    fd.append("brand", f.marca.trim());
    fd.append("description", f.descripcion.trim());
    fd.append("price", f.precio.trim()); // opcional en a_pedido: puede ir vacío
    fd.append("talles", f.talles.trim());
    fd.append("a_pedido", "true");
    fd.append("publicado", "false");
    fd.append("stock_por_talle", "0");
    fd.append("convertir_a_ars", "false");
    fd.append("rotations", fotos.map(() => "0").join(","));
    fotos.forEach((x) => fd.append("images", x.file, x.file.name));
    setEnviando(true);
    try {
      await api.crearProducto(fd);
      push("Producto a pedido guardado", "success");
      fotos.forEach((x) => URL.revokeObjectURL(x.url));
      setF({ nombre: "", marca: "", precio: "", talles: "", descripcion: "" });
      setFotos([]);
      onCreado();
    } catch (err) {
      push(err instanceof ApiError ? err.message : "No se pudo guardar", "error");
    } finally {
      setEnviando(false);
    }
  };

  const inp = "h-10 w-full rounded-xl border border-graph/10 bg-graph/[0.04] px-3 text-sm text-graph placeholder:text-graph-400 outline-none transition focus:border-brand/60";

  return (
    <form onSubmit={guardar} className="pcard p-5">
      <h3 className="mb-4 flex items-center gap-2 font-display text-base font-semibold text-graph">
        <PackageSearch size={16} className="text-brand" /> Cargar producto a pedido
      </h3>
      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block">
          <span className="mb-1.5 block text-[11px] font-medium uppercase tracking-widest2 text-graph-400">Nombre</span>
          <input value={f.nombre} onChange={(e) => setF((s) => ({ ...s, nombre: e.target.value }))} placeholder="Ej: Campera Moncler" className={inp} />
        </label>
        <label className="block">
          <span className="mb-1.5 block text-[11px] font-medium uppercase tracking-widest2 text-graph-400">Marca</span>
          <input value={f.marca} onChange={(e) => setF((s) => ({ ...s, marca: e.target.value }))} placeholder="Ej: Moncler" className={inp} />
        </label>
        <label className="block">
          <span className="mb-1.5 block text-[11px] font-medium uppercase tracking-widest2 text-graph-400">Precio (opcional)</span>
          <input value={f.precio} onChange={(e) => setF((s) => ({ ...s, precio: e.target.value.replace(/[^\d.]/g, "") }))} placeholder="Dejar vacío si todavía no lo sabés" inputMode="decimal" className={inp} />
        </label>
        <label className="block">
          <span className="mb-1.5 block text-[11px] font-medium uppercase tracking-widest2 text-graph-400">Talles (separados por coma)</span>
          <input value={f.talles} onChange={(e) => setF((s) => ({ ...s, talles: e.target.value }))} placeholder="S, M, L, XL — vacío = único" className={inp} />
        </label>
      </div>
      <label className="mt-4 block">
        <span className="mb-1.5 block text-[11px] font-medium uppercase tracking-widest2 text-graph-400">Descripción (opcional)</span>
        <textarea value={f.descripcion} onChange={(e) => setF((s) => ({ ...s, descripcion: e.target.value }))} rows={2} placeholder="Notas del producto."
          className="w-full rounded-xl border border-graph/10 bg-graph/[0.04] p-3 text-sm text-graph outline-none transition placeholder:text-graph-400 focus:border-brand/60" />
      </label>

      <div className="mt-4 flex flex-wrap items-center gap-3">
        <label className="inline-flex cursor-pointer items-center gap-2 rounded-xl border-2 border-dashed border-graph/15 px-4 py-2.5 text-sm font-medium text-graph-500 transition hover:border-brand/50">
          <input type="file" accept="image/*" multiple className="hidden" onChange={(e) => { sumarFotos(e.target.files); e.currentTarget.value = ""; }} />
          <UploadCloud size={16} /> Fotos (opcional)
        </label>
        {fotos.map((x, i) => (
          <span key={i} className="relative">
            <img src={x.url} alt="" className="h-12 w-12 rounded-lg object-cover ring-1 ring-graph/10" />
            <button type="button" onClick={() => setFotos((p) => { URL.revokeObjectURL(p[i].url); return p.filter((_, j) => j !== i); })}
              className="absolute -right-1.5 -top-1.5 grid h-5 w-5 place-items-center rounded-full bg-graph/80 text-white"><X size={11} /></button>
          </span>
        ))}
        <button type="submit" disabled={enviando} className="ml-auto inline-flex h-10 items-center gap-2 rounded-xl bg-brand px-5 text-sm font-semibold text-white transition hover:bg-brand-600 disabled:opacity-60">
          {enviando ? <Loader2 size={15} className="animate-spin" /> : <UploadCloud size={15} />} Guardar a pedido
        </button>
      </div>
    </form>
  );
}

/* ===================== Drawer: tomar reserva ===================== */

function ReservaDrawer({ producto, onClose, onDelete }: { producto: MiamiProducto | null; onClose: () => void; onDelete: (p: MiamiProducto) => void }) {
  const { push } = useToast();
  const [f, setF] = useState({ variantId: "", cliente: "", telefono: "", nota: "" });
  const [guardando, setGuardando] = useState(false);

  useEffect(() => {
    if (producto) setF({ variantId: "", cliente: "", telefono: "", nota: "" });
  }, [producto?.id]); // eslint-disable-line react-hooks/exhaustive-deps

  if (!producto) return <Drawer open={false} onClose={onClose}><span /></Drawer>;
  const p = producto;

  const guardar = async () => {
    if (!f.cliente.trim()) { push("Escribí el nombre del cliente", "info"); return; }
    setGuardando(true);
    try {
      await api.crearReserva({
        product_id: p.id,
        customer_name: f.cliente.trim(),
        customer_phone: f.telefono.trim() || undefined,
        notes: f.nota.trim() || undefined,
        ...(f.variantId ? { variant_id: Number(f.variantId) } : {}),
      });
      push("Reserva guardada — se ve en la pestaña Reservas", "success");
      onClose();
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo guardar la reserva", "error");
    } finally {
      setGuardando(false);
    }
  };

  const inp = "h-10 w-full rounded-xl border border-graph/15 bg-paper-100 px-3 text-sm text-graph outline-none transition placeholder:text-graph-400 focus:border-brand/60 focus:bg-white focus:ring-2 focus:ring-brand/15";

  return (
    <Drawer open onClose={onClose}>
      <div className="p-6">
        <ProductoThumb src={fotoDe(p)} marca={p.brand} alt={p.name.es} rounded="rounded-2xl" className="h-48 w-full" placa />
        <h2 className="mt-4 font-display text-xl font-semibold text-graph">{p.name.es}</h2>
        <p className="mt-1 text-sm text-graph-400">{p.brand || "Sin marca"} · producto a pedido</p>
        <div className="mt-2 flex gap-2">
          <Badge tone="blue">A pedido</Badge>
          {precioDe(p) > 0 && <Badge tone="neutral">{fmtARS(precioDe(p))}</Badge>}
        </div>

        <div className="mt-5 rounded-2xl border border-graph/[0.08] bg-graph/[0.02] p-4">
          <p className="mb-3 flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wide text-graph-400">
            <Bookmark size={13} className="text-brand" /> Reservar para un cliente
          </p>
          <div className="space-y-3">
            {p.variants.length > 0 && (
              <label className="block">
                <span className="mb-1 block text-[11px] font-medium uppercase tracking-wide text-graph-400">Talle</span>
                <Select
                  value={f.variantId}
                  onChange={(v) => setF((s) => ({ ...s, variantId: v }))}
                  options={[{ value: "", label: "Sin talle definido" }, ...p.variants.map((v) => ({ value: String(v.id), label: talleDe(v) }))]}
                />
              </label>
            )}
            <label className="block">
              <span className="mb-1 block text-[11px] font-medium uppercase tracking-wide text-graph-400">Cliente</span>
              <input value={f.cliente} onChange={(e) => setF((s) => ({ ...s, cliente: e.target.value }))} placeholder="Nombre y apellido" className={inp} />
            </label>
            <label className="block">
              <span className="mb-1 block text-[11px] font-medium uppercase tracking-wide text-graph-400">Teléfono (opcional)</span>
              <input value={f.telefono} onChange={(e) => setF((s) => ({ ...s, telefono: e.target.value }))} placeholder="11 2233 4455" inputMode="tel" className={inp} />
            </label>
            <label className="block">
              <span className="mb-1 block text-[11px] font-medium uppercase tracking-wide text-graph-400">Nota (opcional)</span>
              <input value={f.nota} onChange={(e) => setF((s) => ({ ...s, nota: e.target.value }))} placeholder="Seña, color, urgencia…" className={inp} />
            </label>
          </div>
          <button onClick={guardar} disabled={guardando}
            className="mt-4 inline-flex h-10 w-full items-center justify-center gap-2 rounded-xl bg-brand text-sm font-semibold text-white transition hover:bg-brand-600 disabled:opacity-50">
            {guardando ? <Loader2 size={15} className="animate-spin" /> : <Bookmark size={15} />} Guardar reserva
          </button>
        </div>

        <div className="mt-4 flex justify-end border-t border-graph/[0.07] pt-4">
          <button onClick={() => onDelete(p)} className="inline-flex h-9 items-center gap-1.5 rounded-lg px-3 text-xs font-semibold text-graph-400 transition hover:bg-red-500/10 hover:text-red-600">
            <Trash2 size={14} /> Eliminar producto
          </button>
        </div>
      </div>
    </Drawer>
  );
}
