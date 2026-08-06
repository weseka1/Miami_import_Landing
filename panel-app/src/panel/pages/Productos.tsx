import { useState, useMemo, useEffect } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { Plus, LayoutGrid, List, AlertTriangle, Trash2, ExternalLink, Loader2, ImagePlus, X, Check, Star, Flame } from "lucide-react";
import { useData } from "@/lib/DataProvider";
import { api, ApiError, fotoDe, precioDe, stockDe, talleDe, type MiamiProducto, type MiamiVariante } from "../api/miamiApi";
import { fmtARS } from "@/lib/format";
import { PageHeader, EmptyState } from "../components/PageShell";
import { SearchInput, FilterSelect } from "../components/Controls";
import Badge from "../components/Badge";
import Drawer from "../components/Drawer";
import ProductoThumb from "../components/ProductoThumb";
import { useToast } from "../components/Toast";
import { cn } from "../ui/cn";

/** Botoncito de curación de la home (estrella = Destacado, llama = Más vendido). */
function FlagBtn({ on, onClick, title, icon: Icon }: { on: boolean; onClick: () => void; title: string; icon: typeof Star }) {
  return (
    <button
      type="button"
      title={title}
      onClick={(e) => { e.stopPropagation(); onClick(); }}
      className={cn(
        "grid h-7 w-7 place-items-center rounded-lg shadow-soft backdrop-blur transition",
        on ? "bg-brand text-white" : "bg-white/90 text-graph-400 hover:text-brand"
      )}
    >
      <Icon size={14} className={on ? "fill-current" : undefined} />
    </button>
  );
}

function Switch({ on, onChange, title }: { on: boolean; onChange: (v: boolean) => void; title?: string }) {
  return (
    <button
      type="button"
      title={title}
      onClick={(e) => { e.stopPropagation(); onChange(!on); }}
      className={cn("relative h-5 w-9 shrink-0 rounded-full transition", on ? "bg-sea" : "bg-graph/20")}
    >
      <span className={cn("absolute top-0.5 h-4 w-4 rounded-full bg-white shadow transition-all", on ? "left-[18px]" : "left-0.5")} />
    </button>
  );
}

export default function Productos() {
  const { loading, productos, getProducto, actualizarProducto, eliminarProducto, kpis } = useData();
  const { push } = useToast();
  const [params] = useSearchParams();
  const [q, setQ] = useState(params.get("q") || "");
  const [estado, setEstado] = useState(params.get("estado") || "todos");
  useEffect(() => {
    const p = params.get("q"); if (p !== null) setQ(p);
    const e = params.get("estado"); if (e !== null) setEstado(e);
  }, [params]);
  const [marca, setMarca] = useState("todas");
  const [view, setView] = useState<"grid" | "list">("grid");
  const [selId, setSelId] = useState<number | null>(null);

  // El drawer resuelve el producto EN VIVO desde el contexto → refleja ediciones al instante.
  const sel = selId != null ? getProducto(selId) ?? null : null;

  const marcas = useMemo(() => {
    const s = new Set<string>();
    productos.forEach((p) => s.add((p.brand || "Sin marca").trim() || "Sin marca"));
    return [...s].sort((a, b) => a.localeCompare(b));
  }, [productos]);

  const filtrados = useMemo(() => {
    return productos.filter((p) => {
      const texto = `${p.name.es} ${p.brand || ""} ${p.id}`.toLowerCase();
      if (q && !texto.includes(q.toLowerCase())) return false;
      if (marca !== "todas" && ((p.brand || "Sin marca").trim() || "Sin marca") !== marca) return false;
      const st = stockDe(p);
      if (estado === "publicados" && !p.published) return false;
      if (estado === "borradores" && p.published) return false;
      if (estado === "sin_stock" && st > 0) return false;
      if (estado === "stock_bajo" && st > 1) return false;
      if (estado === "destacados" && !p.destacado) return false;
      if (estado === "mas_vendidos" && !p.mas_vendido) return false;
      return true;
    });
  }, [productos, q, marca, estado]);

  const togglePublicado = async (p: MiamiProducto, v: boolean) => {
    try {
      await actualizarProducto(p.id, { published: v });
      push(v ? `"${p.name.es}" publicado en la tienda` : `"${p.name.es}" pasó a borrador (no sale en la web)`, "info");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo guardar", "error");
    }
  };

  // Curación de la home: Destacados / Más vendidos (PUT /products/{pid}).
  const toggleFlag = async (p: MiamiProducto, campo: "destacado" | "mas_vendido") => {
    const v = campo === "destacado" ? !p.destacado : !p.mas_vendido;
    const rotulo = campo === "destacado" ? "Destacados" : "Más vendidos";
    try {
      await actualizarProducto(p.id, campo === "destacado" ? { destacado: v } : { mas_vendido: v });
      push(v ? `"${p.name.es}" entra en ${rotulo} de la home` : `"${p.name.es}" sale de ${rotulo}`, "success");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo guardar", "error");
    }
  };

  return (
    <div>
      <PageHeader
        title="Productos y stock"
        subtitle={loading ? "Cargando catálogo…" : `${productos.length} en catálogo · ${kpis.publicados} publicados · ${kpis.sinStock} sin stock`}
        actions={
          <Link
            to="/panel/cargar"
            className="inline-flex h-10 items-center justify-center gap-2 rounded-xl bg-brand px-4 text-sm font-semibold text-white transition hover:bg-brand-600 hover:shadow-soft"
          >
            <Plus size={16} /> Cargar producto
          </Link>
        }
      />

      {/* toolbar */}
      <div className="pcard mb-5 flex flex-wrap items-center gap-2.5 p-3">
        <SearchInput value={q} onChange={setQ} placeholder="Buscar por nombre, marca o ID…" className="min-w-[220px] flex-1" />
        <FilterSelect
          value={marca}
          onChange={setMarca}
          options={[
            { value: "todas", label: "Marca: todas" },
            ...marcas.map((m) => ({ value: m, label: m })),
          ]}
        />
        <FilterSelect
          value={estado}
          onChange={setEstado}
          options={[
            { value: "todos", label: "Estado: todos" },
            { value: "publicados", label: "Publicados" },
            { value: "borradores", label: "Borradores" },
            { value: "sin_stock", label: "Sin stock" },
            { value: "stock_bajo", label: "Stock crítico (≤1)" },
            { value: "destacados", label: "Destacados (home)" },
            { value: "mas_vendidos", label: "Más vendidos (home)" },
          ]}
        />
        <div className="ml-auto flex items-center gap-1 rounded-xl border border-graph/10 p-1">
          <button
            onClick={() => setView("grid")}
            className={cn("rounded-lg p-1.5 transition", view === "grid" ? "bg-brand text-white" : "text-graph-400 hover:text-graph")}
            aria-label="Grilla"
          >
            <LayoutGrid size={16} />
          </button>
          <button
            onClick={() => setView("list")}
            className={cn("rounded-lg p-1.5 transition", view === "list" ? "bg-brand text-white" : "text-graph-400 hover:text-graph")}
            aria-label="Lista"
          >
            <List size={16} />
          </button>
        </div>
      </div>

      {loading ? (
        <div className="grid place-items-center py-24 text-graph-400"><Loader2 className="animate-spin" /></div>
      ) : filtrados.length === 0 ? (
        <EmptyState msg="No hay productos que coincidan con los filtros." />
      ) : view === "grid" ? (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {filtrados.map((p) => {
            const st = stockDe(p);
            const sinStock = st <= 0;
            const stockBajo = st === 1;
            return (
              <button
                key={p.id}
                onClick={() => setSelId(p.id)}
                className="group pcard pcard-hover overflow-hidden text-left"
              >
                <div className="relative">
                  <ProductoThumb
                    src={fotoDe(p)}
                    marca={p.brand}
                    alt={p.name.es}
                    rounded="rounded-none"
                    className="h-44 w-full"
                    placa
                  />
                  <div className="absolute left-3 top-3 flex flex-wrap gap-2 pr-12">
                    {p.destacado && (
                      <Badge tone="brand" className="bg-white/90 backdrop-blur">
                        <Star size={10} className="fill-current" /> Destacado
                      </Badge>
                    )}
                    {p.mas_vendido && (
                      <Badge tone="brand" className="bg-white/90 backdrop-blur">
                        <Flame size={10} className="fill-current" /> Más vendido
                      </Badge>
                    )}
                    {sinStock && <Badge tone="red" className="bg-white/90 backdrop-blur">Sin stock</Badge>}
                    {stockBajo && <Badge tone="amber" className="bg-white/90 backdrop-blur">Queda 1</Badge>}
                    {!p.published && <Badge tone="neutral" className="bg-white/90 backdrop-blur">Borrador</Badge>}
                    {p.a_pedido && <Badge tone="blue" className="bg-white/90 backdrop-blur">A pedido</Badge>}
                  </div>
                  {/* curación de la home: estrella (Destacados) + llama (Más vendidos) */}
                  <div className="absolute right-3 top-3 flex flex-col gap-1.5">
                    <FlagBtn on={p.destacado} onClick={() => toggleFlag(p, "destacado")} title={p.destacado ? "Sacar de Destacados de la home" : "Destacar en la home"} icon={Star} />
                    <FlagBtn on={p.mas_vendido} onClick={() => toggleFlag(p, "mas_vendido")} title={p.mas_vendido ? 'Sacar de "Más vendidos" de la home' : 'Mostrar en "Más vendidos" de la home'} icon={Flame} />
                  </div>
                  <div className="absolute bottom-3 right-3">
                    <span className="rounded-lg bg-white/92 px-2.5 py-1 font-display text-sm font-semibold text-graph shadow-soft backdrop-blur">
                      {fmtARS(precioDe(p), { short: true })}
                    </span>
                  </div>
                </div>
                <div className="p-4">
                  <h3 className="line-clamp-1 font-display text-base font-semibold text-graph">{p.name.es}</h3>
                  <p className="mt-1 text-xs text-graph-400">
                    #{p.id} · {p.brand || "Sin marca"} · {p.variants.length} talle{p.variants.length === 1 ? "" : "s"}
                  </p>
                  <div className="mt-3 flex items-center justify-between border-t border-graph/[0.07] pt-3 text-xs">
                    <span className={cn("inline-flex items-center gap-1 font-semibold", sinStock || stockBajo ? "text-red-700" : "text-graph-500")}>
                      {(sinStock || stockBajo) && <AlertTriangle size={12} />}
                      Stock: {st}
                    </span>
                    <span className="text-graph-400">
                      {p.variants.map((v) => talleDe(v)).join(" · ")}
                    </span>
                    <span className="inline-flex items-center gap-1.5 text-graph-400">
                      Publicado <Switch on={p.published} onChange={(v) => togglePublicado(p, v)} title={p.published ? "Sacar de la web" : "Publicar en la web"} />
                    </span>
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      ) : (
        <div className="pcard overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[860px] text-sm">
              <thead>
                <tr className="border-b border-graph/[0.07] bg-graph/[0.03] text-left text-xs font-semibold uppercase tracking-wide text-graph-400">
                  <th className="px-4 py-3">Producto</th>
                  <th className="px-4 py-3">Marca</th>
                  <th className="px-4 py-3">Talles</th>
                  <th className="px-4 py-3 text-right">Precio</th>
                  <th className="px-4 py-3 text-center">Stock</th>
                  <th className="px-4 py-3 text-center">Home</th>
                  <th className="px-4 py-3 text-center">Publicado</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-graph/[0.07]">
                {filtrados.map((p) => {
                  const st = stockDe(p);
                  const alerta = st <= 1;
                  return (
                    <tr key={p.id} onClick={() => setSelId(p.id)} className="cursor-pointer transition hover:bg-graph/[0.03]">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          <ProductoThumb src={fotoDe(p)} marca={p.brand} alt="" className="h-10 w-14 shrink-0 ring-1 ring-graph/10" />
                          <div className="min-w-0">
                            <p className="line-clamp-1 font-semibold text-graph">{p.name.es}</p>
                            <p className="text-xs text-graph-400">#{p.id}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-graph-500">{p.brand || "Sin marca"}</td>
                      <td className="px-4 py-3 text-graph-500">{p.variants.map((v) => talleDe(v)).join(" · ")}</td>
                      <td className="px-4 py-3 text-right">
                        <p className="font-display font-semibold text-graph">{fmtARS(precioDe(p), { short: true })}</p>
                      </td>
                      <td className={cn("px-4 py-3 text-center font-semibold", alerta ? "text-red-700" : "text-graph")}>
                        <span className="inline-flex items-center gap-1">{alerta && <AlertTriangle size={12} />}{st}</span>
                      </td>
                      <td className="px-4 py-3 text-center">
                        <span className="inline-flex items-center gap-1.5">
                          <FlagBtn on={p.destacado} onClick={() => toggleFlag(p, "destacado")} title="Destacado en la home" icon={Star} />
                          <FlagBtn on={p.mas_vendido} onClick={() => toggleFlag(p, "mas_vendido")} title='"Más vendidos" de la home' icon={Flame} />
                        </span>
                      </td>
                      <td className="px-4 py-3 text-center">
                        <Switch on={p.published} onChange={(v) => togglePublicado(p, v)} />
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ===== Editar producto ===== */}
      <ProductoDrawer
        producto={sel}
        onToggleFlag={toggleFlag}
        onClose={() => setSelId(null)}
        onDelete={async (p) => {
          if (!window.confirm(`¿Eliminar "${p.name.es}" del catálogo? No se puede deshacer.`)) return;
          try {
            await eliminarProducto(p.id);
            setSelId(null);
            push("Producto eliminado del catálogo", "info");
          } catch (e) {
            push(e instanceof ApiError ? e.message : "No se pudo eliminar", "error");
          }
        }}
      />
    </div>
  );
}

/* ===================== Drawer de edición ===================== */

const INP = "h-10 w-full rounded-xl border border-graph/15 bg-paper-100 px-3 text-sm text-graph outline-none transition placeholder:text-graph-400 focus:border-brand/60 focus:bg-white focus:ring-2 focus:ring-brand/15";
const INP_SM = "h-9 w-full rounded-lg border border-graph/15 bg-paper-100 px-2.5 text-sm text-graph outline-none transition focus:border-brand/60 focus:bg-white focus:ring-2 focus:ring-brand/15";

function ProductoDrawer({
  producto,
  onToggleFlag,
  onClose,
  onDelete,
}: {
  producto: MiamiProducto | null;
  onToggleFlag: (p: MiamiProducto, campo: "destacado" | "mas_vendido") => void;
  onClose: () => void;
  onDelete: (p: MiamiProducto) => void;
}) {
  const { actualizarProducto, actualizarVariante, agregarTalle, quitarTalle, subirImagen, refrescarProducto, store } = useData();
  const { push } = useToast();

  const rate = store?.usd_rate || 0;
  // El precio que se edita acá es el de la TIENDA: dólares. Si la variante no
  // tiene usd_price guardado (cargas viejas), se deriva de los pesos con la
  // cotización — igual que lo muestra la web.
  const usdDe = (v: MiamiVariante): number => {
    if (v.usd_price && parseFloat(v.usd_price) > 0) return Math.round(parseFloat(v.usd_price));
    return rate > 0 && v.price ? Math.round(parseFloat(v.price) / rate) : 0;
  };

  // --- datos base (nombre / marca) ---
  const [f, setF] = useState({ nombre: "", marca: "" });
  // --- variantes: precio USD/stock como strings de edición, por id ---
  const [vf, setVf] = useState<Record<number, { precio: string; stock: string }>>({});
  const [busy, setBusy] = useState(false);
  const [busyFoto, setBusyFoto] = useState(false);
  // --- talle nuevo ---
  const [nuevoTalle, setNuevoTalle] = useState({ talle: "", stock: "1", precio: "" });

  useEffect(() => {
    if (producto) {
      setF({ nombre: producto.name.es, marca: producto.brand || "" });
      const m: Record<number, { precio: string; stock: string }> = {};
      producto.variants.forEach((v) => { m[v.id] = { precio: usdDe(v) ? String(usdDe(v)) : "", stock: String(v.stock ?? 0) }; });
      setVf(m);
      setNuevoTalle({ talle: "", stock: "1", precio: "" });
    }
  }, [producto?.id, producto?.variants.length]); // eslint-disable-line react-hooks/exhaustive-deps

  if (!producto) return <Drawer open={false} onClose={onClose}><span /></Drawer>;

  const p = producto;
  const fotos = [...p.images].sort((a, b) => (a.position || 0) - (b.position || 0));

  const cambioDatos = f.nombre.trim() !== p.name.es || f.marca.trim() !== (p.brand || "");
  const varsCambiadas = p.variants.filter((v) => {
    const e = vf[v.id];
    if (!e) return false;
    return (Number(e.precio) || 0) !== usdDe(v) || (Number(e.stock) || 0) !== (v.stock ?? 0);
  });

  const guardar = async () => {
    setBusy(true);
    try {
      if (cambioDatos) {
        await actualizarProducto(p.id, { name: f.nombre.trim(), brand: f.marca.trim() });
      }
      // PUT /panel/api/variants/{pid}/{vid} — precio USD y stock POR TALLE.
      // Se manda usd_price: el backend fija el USD y recalcula los pesos con
      // la cotización del panel (así el precio grande de la tienda queda BIEN).
      for (const v of varsCambiadas) {
        const e = vf[v.id];
        const patch: { usd_price?: number; stock?: number } = {};
        const precioNuevo = Number(e.precio) || 0;
        if (precioNuevo > 0 && precioNuevo !== usdDe(v)) patch.usd_price = precioNuevo;
        const stockNuevo = Number(e.stock) || 0;
        if (stockNuevo !== (v.stock ?? 0)) patch.stock = stockNuevo;
        if (Object.keys(patch).length) await actualizarVariante(p.id, v.id, patch);
      }
      push("Cambios guardados", "success");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo guardar", "error");
    } finally {
      setBusy(false);
    }
  };

  const addTalle = async () => {
    const t = nuevoTalle.talle.trim().toUpperCase();
    if (!t) { push("Escribí el talle (ej: XL, 42)", "info"); return; }
    setBusy(true);
    try {
      // El input del talle nuevo también es US$: se convierte a pesos acá
      // porque el alta de talles del backend recibe `price` (ARS).
      await agregarTalle(p.id, {
        talle: t,
        stock: Math.max(0, Number(nuevoTalle.stock) || 0),
        ...(Number(nuevoTalle.precio) > 0 && rate > 0 ? { price: Math.round(Number(nuevoTalle.precio) * rate) } : {}),
      });
      setNuevoTalle({ talle: "", stock: "1", precio: "" });
      push(`Talle ${t} agregado`, "success");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo agregar el talle", "error");
    } finally {
      setBusy(false);
    }
  };

  const delTalle = async (v: MiamiVariante) => {
    if (!window.confirm(`¿Quitar el talle ${talleDe(v)}?`)) return;
    setBusy(true);
    try {
      await quitarTalle(p.id, v.id);
      push(`Talle ${talleDe(v)} eliminado`, "info");
    } catch (e) {
      // 409 del backend: único talle o comprometido en un pedido pendiente.
      push(e instanceof ApiError ? e.message : "No se pudo quitar el talle", "error");
    } finally {
      setBusy(false);
    }
  };

  const subirFotos = async (files: FileList | null) => {
    if (!files?.length) return;
    setBusyFoto(true);
    try {
      for (const file of Array.from(files)) {
        if (file.size > 8 * 1024 * 1024) { push(`"${file.name}" pesa más de 8 MB`, "error"); continue; }
        await subirImagen(p.id, file);
      }
      push("Fotos subidas", "success");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo subir la foto", "error");
    } finally {
      setBusyFoto(false);
    }
  };

  const urlTienda = store && p.published ? `${store.product_url_base}${p.handle.es}/` : null;

  return (
    <Drawer open onClose={onClose}>
      <div className="p-6">
        <ProductoThumb src={fotoDe(p)} marca={p.brand} alt={p.name.es} rounded="rounded-2xl" className="h-52 w-full" placa />

        {fotos.length > 0 && (
          <div className="mt-2 flex gap-2 overflow-x-auto pb-1">
            {fotos.map((img, i) => (
              <div key={img.id} className="group/foto relative shrink-0">
                <img src={img.src} alt="" className="h-16 w-16 rounded-lg object-cover ring-1 ring-graph/10" />
                {i === 0 && <span className="absolute left-0.5 top-0.5 rounded bg-graph/80 px-1 py-0.5 text-[8px] font-bold uppercase text-white">Portada</span>}
                <div className="absolute inset-x-0 bottom-0 flex justify-center gap-1 rounded-b-lg bg-graph/70 py-0.5 opacity-0 transition group-hover/foto:opacity-100">
                  {i !== 0 && (
                    <button
                      title="Hacer portada"
                      onClick={async () => {
                        // PUT /products/{pid}/images/orden con la lista COMPLETA (regla del backend)
                        const ids = [img.id, ...fotos.filter((x) => x.id !== img.id).map((x) => x.id)];
                        try { await api.reordenarImagenes(p.id, ids); await refrescarProducto(p.id); push("Ahora es la foto principal", "success"); }
                        catch (e) { push(e instanceof ApiError ? e.message : "No se pudo reordenar", "error"); }
                      }}
                      className="grid h-5 w-5 place-items-center rounded text-[10px] text-white transition hover:bg-white/20"
                    >★</button>
                  )}
                  <button
                    title="Borrar foto"
                    onClick={async () => {
                      if (!window.confirm("¿Eliminar esta foto? No se puede deshacer.")) return;
                      try { await api.borrarImagen(p.id, img.id); await refrescarProducto(p.id); push("Foto eliminada", "info"); }
                      catch (e) { push(e instanceof ApiError ? e.message : "No se pudo borrar", "error"); }
                    }}
                    className="grid h-5 w-5 place-items-center rounded text-[10px] text-white transition hover:bg-red-500/60"
                  >✕</button>
                </div>
              </div>
            ))}
          </div>
        )}

        <div className="mt-4 flex flex-wrap items-center gap-2 pr-8">
          <h2 className="font-display text-xl font-semibold text-graph">{p.name.es}</h2>
        </div>
        <p className="mt-1 text-sm text-graph-400">
          #{p.id} · {p.brand || "Sin marca"} · {fotos.length} foto{fotos.length === 1 ? "" : "s"}
        </p>
        <div className="mt-2 flex flex-wrap gap-2">
          <Badge tone={p.published ? "green" : "neutral"}>{p.published ? "Publicado" : "Borrador"}</Badge>
          <Badge tone={stockDe(p) > 1 ? "neutral" : stockDe(p) === 1 ? "amber" : "red"}>Stock {stockDe(p)}</Badge>
          {p.destacado && <Badge tone="brand"><Star size={10} className="fill-current" /> Destacado</Badge>}
          {p.mas_vendido && <Badge tone="brand"><Flame size={10} className="fill-current" /> Más vendido</Badge>}
          {p.a_pedido && <Badge tone="blue">A pedido</Badge>}
        </div>

        {/* ===== Curación de la home ===== */}
        <div className="mt-5 rounded-2xl border border-graph/[0.08] bg-graph/[0.02] p-4">
          <p className="mb-2 text-[11px] font-semibold uppercase tracking-wide text-graph-400">En la home de la tienda</p>
          <label className="flex min-h-[40px] items-center justify-between text-sm text-graph">
            <span className="inline-flex items-center gap-2"><Star size={15} className="text-brand" /> Destacado</span>
            <Switch on={p.destacado} onChange={() => onToggleFlag(p, "destacado")} />
          </label>
          <label className="flex min-h-[40px] items-center justify-between text-sm text-graph">
            <span className="inline-flex items-center gap-2"><Flame size={15} className="text-brand" /> Más vendido</span>
            <Switch on={p.mas_vendido} onChange={() => onToggleFlag(p, "mas_vendido")} />
          </label>
          <p className="mt-1 text-xs text-graph-400">Si no hay ninguno marcado, cada sección de la home se arma sola (más nuevos / ventas reales).</p>
        </div>

        {/* ===== Datos ===== */}
        <div className="mt-5 rounded-2xl border border-graph/[0.08] bg-graph/[0.02] p-4">
          <p className="mb-3 text-[11px] font-semibold uppercase tracking-wide text-graph-400">Datos del producto</p>
          <div className="space-y-3">
            <label className="block">
              <span className="mb-1 block text-[11px] font-medium uppercase tracking-wide text-graph-400">Nombre</span>
              <input value={f.nombre} onChange={(e) => setF((s) => ({ ...s, nombre: e.target.value }))} className={INP} />
            </label>
            <label className="block">
              <span className="mb-1 block text-[11px] font-medium uppercase tracking-wide text-graph-400">Marca</span>
              <input value={f.marca} onChange={(e) => setF((s) => ({ ...s, marca: e.target.value }))} placeholder="Nike, Lacoste, Supreme…" className={INP} />
            </label>
          </div>
        </div>

        {/* ===== Precio y stock POR TALLE (PUT /variants) ===== */}
        <div className="mt-4 rounded-2xl border border-graph/[0.08] bg-graph/[0.02] p-4">
          <p className="mb-1 text-[11px] font-semibold uppercase tracking-wide text-graph-400">Precio y stock por talle</p>
          {rate > 0 && (
            <p className="mb-3 text-xs text-graph-400">
              El precio va en <strong>dólares</strong> — los pesos de la tienda se calculan solos (US$ 1 = $ {Math.round(rate).toLocaleString("es-AR")}).
            </p>
          )}
          <div className="space-y-2">
            <div className="grid grid-cols-[56px_1fr_72px_36px] items-center gap-2 px-1 text-[10px] font-semibold uppercase tracking-wide text-graph-400">
              <span>Talle</span><span>Precio US$</span><span>Stock</span><span />
            </div>
            {p.variants.map((v) => {
              const e = vf[v.id] || { precio: "", stock: "" };
              const cambiada = varsCambiadas.some((x) => x.id === v.id);
              return (
                <div key={v.id} className={cn("grid grid-cols-[56px_1fr_72px_36px] items-center gap-2 rounded-xl px-1 py-1", cambiada && "bg-brand/[0.06]")}>
                  <span className="inline-flex h-9 items-center justify-center rounded-lg bg-graph/[0.05] text-sm font-semibold text-graph">{talleDe(v)}</span>
                  <input
                    value={e.precio}
                    onChange={(ev) => setVf((s) => ({ ...s, [v.id]: { ...e, precio: ev.target.value.replace(/[^\d]/g, "") } }))}
                    inputMode="numeric"
                    className={INP_SM}
                  />
                  <input
                    value={e.stock}
                    onChange={(ev) => setVf((s) => ({ ...s, [v.id]: { ...e, stock: ev.target.value.replace(/[^\d]/g, "") } }))}
                    inputMode="numeric"
                    className={cn(INP_SM, "text-center")}
                  />
                  <button
                    onClick={() => delTalle(v)}
                    disabled={busy || p.variants.length <= 1}
                    title={p.variants.length <= 1 ? "Es el único talle: no se puede quitar" : "Quitar talle"}
                    className="grid h-9 w-9 place-items-center rounded-lg text-graph-400 transition hover:bg-red-500/10 hover:text-red-600 disabled:opacity-30"
                  >
                    <X size={15} />
                  </button>
                </div>
              );
            })}
          </div>

          {/* agregar talle */}
          <div className="mt-3 grid grid-cols-[56px_1fr_72px_36px] items-center gap-2 border-t border-graph/[0.07] px-1 pt-3">
            <input
              value={nuevoTalle.talle}
              onChange={(e) => setNuevoTalle((s) => ({ ...s, talle: e.target.value.toUpperCase() }))}
              placeholder="XL"
              className={cn(INP_SM, "text-center font-semibold uppercase")}
            />
            <input
              value={nuevoTalle.precio}
              onChange={(e) => setNuevoTalle((s) => ({ ...s, precio: e.target.value.replace(/[^\d]/g, "") }))}
              placeholder="US$ (opcional: hereda)"
              inputMode="numeric"
              className={INP_SM}
            />
            <input
              value={nuevoTalle.stock}
              onChange={(e) => setNuevoTalle((s) => ({ ...s, stock: e.target.value.replace(/[^\d]/g, "") }))}
              inputMode="numeric"
              className={cn(INP_SM, "text-center")}
            />
            <button
              onClick={addTalle}
              disabled={busy}
              title="Agregar talle"
              className="grid h-9 w-9 place-items-center rounded-lg bg-brand/10 text-brand-700 transition hover:bg-brand hover:text-white disabled:opacity-40"
            >
              <Plus size={15} />
            </button>
          </div>

          <button
            onClick={guardar}
            disabled={busy || (!cambioDatos && varsCambiadas.length === 0)}
            className="mt-4 inline-flex h-10 w-full items-center justify-center gap-2 rounded-xl bg-brand text-sm font-semibold text-white transition hover:bg-brand-600 disabled:opacity-40"
          >
            {busy ? <Loader2 size={16} className="animate-spin" /> : <Check size={16} />}
            Guardar cambios{varsCambiadas.length > 0 ? ` (${varsCambiadas.length} talle${varsCambiadas.length === 1 ? "" : "s"})` : ""}
          </button>
        </div>

        {/* ===== Fotos ===== */}
        <div className="mt-4 rounded-2xl border border-graph/[0.08] bg-graph/[0.02] p-4">
          <p className="mb-3 text-[11px] font-semibold uppercase tracking-wide text-graph-400">Fotos</p>
          <label className="flex cursor-pointer items-center justify-center gap-2 rounded-xl border-2 border-dashed border-graph/15 bg-graph/[0.02] py-4 text-center transition hover:border-brand/50">
            <input type="file" accept="image/*" multiple className="hidden" onChange={(e) => { void subirFotos(e.target.files); e.target.value = ""; }} />
            {busyFoto ? <Loader2 size={18} className="animate-spin text-brand" /> : <ImagePlus size={18} className="text-graph-400" />}
            <span className="text-sm font-medium text-graph-500">{busyFoto ? "Subiendo…" : "Agregar fotos"}</span>
          </label>
        </div>

        <div className="mt-4 flex items-center justify-between border-t border-graph/[0.07] pt-4">
          {urlTienda ? (
            <a href={urlTienda} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1.5 text-xs font-semibold text-brand hover:underline">
              <ExternalLink size={13} /> Ver en la tienda
            </a>
          ) : <span className="text-xs text-graph-400">{p.published ? "" : "No visible en la tienda (borrador)"}</span>}
          <button
            onClick={() => onDelete(p)}
            className="inline-flex h-9 items-center gap-1.5 rounded-lg px-3 text-xs font-semibold text-graph-400 transition hover:bg-red-500/10 hover:text-red-600"
          >
            <Trash2 size={14} /> Eliminar
          </button>
        </div>
      </div>
    </Drawer>
  );
}
