import { useEffect, useMemo, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { UploadCloud, ImagePlus, X, Loader2, Check, Plus, Package, DollarSign } from "lucide-react";
import { useData } from "@/lib/DataProvider";
import { ApiError } from "../api/miamiApi";
import { useToast } from "../components/Toast";
import { PageHeader } from "../components/PageShell";
import { fmtARS, fmtUSD } from "@/lib/format";

// Alta REAL: POST /panel/api/products (multipart). El backend crea el producto,
// sus variantes por talle y sube las fotos a storage. Nada queda en el navegador.

const TALLES_ROPA = ["S", "M", "L", "XL", "XXL"];
const MAX_IMG_MB = 8;

type FotoLocal = { file: File; url: string };

export default function CargarProducto() {
  const { crearProducto, store } = useData();
  const { push } = useToast();
  const navigate = useNavigate();

  const [f, setF] = useState({
    nombre: "",
    marca: "",
    precio: "",
    enUSD: false,        // convertir_a_ars: el precio se carga en dólares
    stockPorTalle: "1",
    descripcion: "",
    publicado: true,
    aPedido: false,
  });
  const [talles, setTalles] = useState<string[]>([]);
  const [talleInput, setTalleInput] = useState("");
  const [fotos, setFotos] = useState<FotoLocal[]>([]);
  const [enviando, setEnviando] = useState(false);
  const [guardado, setGuardado] = useState(false);

  const set = (k: keyof typeof f, v: any) => setF((p) => ({ ...p, [k]: v }));
  const setNum = (k: keyof typeof f, v: string) => set(k, v.replace(/[^\d.]/g, ""));

  // ----- talles (chips) -----
  const addTalle = (t: string) => {
    const limpio = t.trim().toUpperCase();
    if (!limpio) return;
    setTalles((prev) => (prev.includes(limpio) ? prev : [...prev, limpio]));
    setTalleInput("");
  };
  const delTalle = (t: string) => setTalles((prev) => prev.filter((x) => x !== t));

  // ----- fotos: archivos reales (van al multipart) -----
  const sumarFotos = (lista: File[], aviso = "Fotos agregadas") => {
    const validas: FotoLocal[] = [];
    for (const file of lista) {
      if (!file.type.startsWith("image/")) continue;
      if (file.size > MAX_IMG_MB * 1024 * 1024) {
        push(`"${file.name}" pesa más de ${MAX_IMG_MB} MB — el servidor la rechaza`, "error");
        continue;
      }
      validas.push({ file, url: URL.createObjectURL(file) });
    }
    if (validas.length) {
      setFotos((p) => [...p, ...validas]);
      push(aviso, "success");
    }
  };
  const subirArchivos = (files: FileList | null) => files && sumarFotos(Array.from(files));
  const quitarFoto = (i: number) => setFotos((p) => {
    URL.revokeObjectURL(p[i]?.url);
    return p.filter((_, j) => j !== i);
  });

  // Ctrl+V en cualquier lado de la página: si el portapapeles trae una IMAGEN
  // (copiada de Google, WhatsApp, donde sea), entra directo al alta sin
  // descargar nada. Si trae texto, no interfiere (pega normal en los campos).
  const sumarFotosRef = useRef(sumarFotos);
  sumarFotosRef.current = sumarFotos;
  useEffect(() => {
    const onPaste = (e: ClipboardEvent) => {
      const items = e.clipboardData?.items;
      if (!items) return;
      const imagenes = Array.from(items)
        .filter((it) => it.kind === "file" && it.type.startsWith("image/"))
        .map((it) => it.getAsFile())
        .filter((x): x is File => !!x);
      if (!imagenes.length) return;
      e.preventDefault();
      sumarFotosRef.current(imagenes, imagenes.length > 1 ? "Imágenes pegadas" : "Imagen pegada");
    };
    document.addEventListener("paste", onPaste);
    return () => document.removeEventListener("paste", onPaste);
  }, []);

  // Limpieza de object URLs al desmontar.
  useEffect(() => () => { fotos.forEach((x) => URL.revokeObjectURL(x.url)); }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const precioNum = Number(f.precio) || 0;
  const rate = store?.usd_rate || 0;
  const previewARS = useMemo(() => {
    if (!precioNum) return null;
    return f.enUSD && rate ? precioNum * rate : precioNum;
  }, [precioNum, f.enUSD, rate]);

  const guardar = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!f.nombre.trim()) { push("Completá el nombre del producto", "info"); return; }
    if (!f.marca.trim()) { push("Completá la marca (el servidor la exige)", "info"); return; }
    if (!f.aPedido && !precioNum) { push("Completá el precio (solo los 'a pedido' pueden no tenerlo)", "info"); return; }

    const fd = new FormData();
    fd.append("name", f.nombre.trim());
    fd.append("brand", f.marca.trim());
    fd.append("description", f.descripcion.trim());
    fd.append("price", precioNum ? String(precioNum) : "");
    fd.append("talles", talles.join(","));
    fd.append("stock_por_talle", String(Math.max(0, Number(f.stockPorTalle) || 0)));
    fd.append("publicado", String(f.publicado));
    fd.append("a_pedido", String(f.aPedido));
    fd.append("convertir_a_ars", String(f.enUSD));
    fd.append("rotations", fotos.map(() => "0").join(","));
    fotos.forEach((x) => fd.append("images", x.file, x.file.name));

    setEnviando(true);
    try {
      await crearProducto(fd);
      setGuardado(true);
      push(
        f.aPedido
          ? "Producto 'a pedido' guardado — queda para tomar reservas"
          : f.publicado ? "Producto publicado — ya está en la tienda" : "Producto guardado como borrador",
        "success"
      );
      setTimeout(() => navigate("/panel/productos"), 1400);
    } catch (err) {
      push(err instanceof ApiError ? err.message : "No se pudo crear el producto", "error");
    } finally {
      setEnviando(false);
    }
  };

  if (guardado) {
    return (
      <div className="grid min-h-[60vh] place-items-center">
        <div className="pcard max-w-md p-10 text-center">
          <span className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-sea/10 text-sea"><Check size={32} /></span>
          <h2 className="mt-5 font-display text-2xl text-graph">Producto cargado</h2>
          <p className="mt-2 text-sm text-graph-400">
            {f.publicado && !f.aPedido ? "Ya quedó guardado y visible en la tienda." : "Quedó guardado en el catálogo."} Te llevo al listado…
          </p>
        </div>
      </div>
    );
  }

  return (
    <form onSubmit={guardar}>
      <PageHeader
        title="Cargar producto"
        subtitle="Alta de una prenda al catálogo real: datos, precio, talles con stock y fotos."
        actions={
          <button type="submit" disabled={enviando} className="inline-flex h-10 items-center gap-2 rounded-xl bg-brand px-5 text-sm font-semibold text-white transition hover:bg-brand-600 disabled:opacity-60">
            {enviando ? <Loader2 size={16} className="animate-spin" /> : <UploadCloud size={16} />} Guardar producto
          </button>
        }
      />

      <div className="grid gap-6 lg:grid-cols-[1.5fr_1fr]">
        {/* ===== Columna izquierda: datos ===== */}
        <div className="min-w-0 space-y-6">
          {/* Básicos */}
          <section className="pcard p-5">
            <h3 className="mb-4 flex items-center gap-2 font-display text-base font-semibold text-graph"><Package size={16} className="text-brand" /> Datos principales</h3>
            <div className="grid gap-4 sm:grid-cols-2">
              <Campo label="Nombre del producto" full>
                <Inp value={f.nombre} onChange={(v) => set("nombre", v)} ph="Ej: Remera Supreme negra con strass" autoFocus />
              </Campo>
              <Campo label="Marca">
                <Inp value={f.marca} onChange={(v) => set("marca", v)} ph="Nike, Lacoste, Supreme…" />
              </Campo>
            </div>
          </section>

          {/* Precio y stock */}
          <section className="pcard p-5">
            <h3 className="mb-4 font-display text-base font-semibold text-graph">Precio, talles y stock</h3>
            <div className="grid gap-4 sm:grid-cols-3">
              <Campo label={f.enUSD ? "Precio (USD)" : "Precio (ARS)"}>
                <Inp value={f.precio} onChange={(v) => setNum("precio", v)} ph={f.enUSD ? "170" : "250000"} mode="numeric" />
              </Campo>
              <Campo label="Stock por talle">
                <Inp value={f.stockPorTalle} onChange={(v) => setNum("stockPorTalle", v)} ph="1" mode="numeric" />
              </Campo>
              <div className="flex items-end pb-1">
                <button
                  type="button"
                  onClick={() => set("enUSD", !f.enUSD)}
                  className={`inline-flex h-10 items-center gap-2 rounded-xl border px-3 text-xs font-semibold transition ${f.enUSD ? "border-brand bg-brand text-white" : "border-graph/15 bg-graph/[0.03] text-graph-500 hover:border-brand/40"}`}
                  title="El precio está en dólares: el servidor lo convierte a pesos con la cotización cargada"
                >
                  <DollarSign size={14} /> Precio en USD
                </button>
              </div>
            </div>

            {/* Talles */}
            <div className="mt-4">
              <SubLabel>Talles</SubLabel>
              <div className="flex flex-wrap gap-1.5">
                {TALLES_ROPA.map((t) => (
                  <button
                    type="button"
                    key={t}
                    onClick={() => (talles.includes(t) ? delTalle(t) : addTalle(t))}
                    className={`min-h-[36px] rounded-lg border px-3 py-1 text-xs font-semibold transition ${talles.includes(t) ? "border-brand bg-brand text-white" : "border-graph/15 bg-graph/[0.03] text-graph-500 hover:border-brand/40 hover:text-graph"}`}
                  >
                    {t}
                  </button>
                ))}
              </div>
              <div className="mt-2 flex items-center gap-2">
                <input
                  value={talleInput}
                  onChange={(e) => setTalleInput(e.target.value.toUpperCase())}
                  onKeyDown={(e) => { if (e.key === "Enter" || e.key === ",") { e.preventDefault(); addTalle(talleInput); } }}
                  placeholder="Otro talle (ej: 42, XS, ÚNICO) — Enter para agregar"
                  className="h-10 min-w-0 flex-1 rounded-xl border border-graph/10 bg-graph/[0.04] px-3 text-sm text-graph placeholder:text-graph-400 outline-none transition focus:border-brand/60"
                />
                <button type="button" onClick={() => addTalle(talleInput)} className="inline-flex h-10 shrink-0 items-center gap-1 rounded-xl border border-graph/15 px-3 text-xs font-semibold text-graph-500 transition hover:border-brand/40 hover:text-brand">
                  <Plus size={14} /> Agregar
                </button>
              </div>
              {talles.length > 0 && (
                <div className="mt-2.5 flex flex-wrap gap-1.5">
                  {talles.map((t) => (
                    <span key={t} className="inline-flex items-center gap-1.5 rounded-full bg-brand/10 px-2.5 py-1 text-xs font-semibold text-brand-700 ring-1 ring-inset ring-brand/20">
                      {t}
                      <button type="button" onClick={() => delTalle(t)} className="transition hover:text-red-600"><X size={12} /></button>
                    </span>
                  ))}
                </div>
              )}
              <p className="mt-2 text-xs text-graph-400">
                Sin talles, se crea con talle único. Cada talle arranca con el stock de arriba.
              </p>
            </div>

            {previewARS !== null && (
              <p className="mt-3 rounded-xl bg-graph/[0.03] px-3 py-2.5 text-xs text-graph-500 ring-1 ring-inset ring-graph/[0.06]">
                Se publica: <b className="text-graph">{fmtARS(Math.round(previewARS))}</b>
                {f.enUSD && rate ? <> ({fmtUSD(precioNum)} × {rate.toLocaleString("es-AR")} de cotización)</> : null}
                {talles.length > 0 && <> · {talles.length} talle{talles.length === 1 ? "" : "s"} × {Number(f.stockPorTalle) || 0} u.</>}
              </p>
            )}
          </section>

          {/* Descripción */}
          <section className="pcard p-5">
            <h3 className="mb-4 font-display text-base font-semibold text-graph">Descripción</h3>
            <textarea
              value={f.descripcion}
              onChange={(e) => set("descripcion", e.target.value)}
              rows={4}
              placeholder="Describí la prenda: modelo, color, detalles, por qué conviene…"
              className="w-full rounded-xl border border-graph/10 bg-graph/[0.04] p-3 text-sm text-graph outline-none transition placeholder:text-graph-400 focus:border-brand/60"
            />
          </section>
        </div>

        {/* ===== Columna derecha: fotos + publicación ===== */}
        <div className="min-w-0 space-y-6">
          {/* Fotos */}
          <section className="pcard p-5">
            <h3 className="mb-3 flex items-center gap-2 font-display text-base font-semibold text-graph"><ImagePlus size={16} className="text-brand" /> Fotos</h3>
            <label className="flex cursor-pointer flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed border-graph/15 bg-graph/[0.02] py-8 text-center transition hover:border-brand/50 hover:bg-graph/[0.04]">
              <input type="file" accept="image/*" multiple className="hidden" onChange={(e) => { subirArchivos(e.target.files); e.currentTarget.value = ""; }} />
              <UploadCloud size={24} className="text-graph-400" />
              <span className="text-sm font-medium text-graph-500">Arrastrá, hacé clic o pegá con Ctrl+V</span>
              <span className="text-xs text-graph-400">JPG, PNG, WEBP — hasta {MAX_IMG_MB} MB c/u</span>
            </label>
            {fotos.length > 0 && (
              <div className="mt-3 grid grid-cols-3 gap-2">
                {fotos.map((x, i) => (
                  <div key={i} className="group relative overflow-hidden rounded-lg bg-paper-200 ring-1 ring-graph/10">
                    <img src={x.url} alt="" className="aspect-square w-full object-contain" />
                    {i === 0 && <span className="absolute left-1 top-1 rounded bg-graph/80 px-1.5 py-0.5 text-[9px] font-bold uppercase text-white">Portada</span>}
                    <button type="button" onClick={() => quitarFoto(i)} className="absolute right-1 top-1 grid h-6 w-6 place-items-center rounded-full bg-graph/80 text-white opacity-0 transition group-hover:opacity-100">
                      <X size={13} />
                    </button>
                  </div>
                ))}
              </div>
            )}
            <p className="mt-3 text-[11px] leading-snug text-graph-400">
              Tip: copiá una imagen (clic derecho → "Copiar imagen") y apretá Ctrl+V acá. Entra sola, sin descargar nada.
            </p>
            <p className="mt-1.5 text-[11px] leading-snug text-graph-400">
              La primera foto es la portada en la tienda. Sin foto, el producto sale con una placa tipográfica (marca).
            </p>
          </section>

          {/* Publicación */}
          <section className="pcard p-5">
            <h3 className="mb-3 font-display text-base font-semibold text-graph">Publicación</h3>
            <div className="space-y-2.5">
              <Toggle label="Publicar en la tienda" v={f.publicado && !f.aPedido} on={() => set("publicado", !f.publicado)} disabled={f.aPedido} />
              <Toggle label="Producto a pedido (sin stock real)" v={f.aPedido} on={() => set("aPedido", !f.aPedido)} />
            </div>
            <div className="mt-4 rounded-xl border border-brand/20 bg-brand/[0.05] p-3 text-xs text-graph-500">
              {f.aPedido
                ? "Los 'a pedido' no se publican ni descuentan stock: quedan en la pestaña A pedido para tomar reservas."
                : f.publicado
                  ? "Al guardar, el producto queda visible en la tienda al instante."
                  : "Queda como borrador interno: no sale en la web hasta que lo publiques."}
            </div>
            <button type="submit" disabled={enviando} className="mt-4 inline-flex h-11 w-full items-center justify-center gap-2 rounded-xl bg-brand text-sm font-semibold text-white transition hover:bg-brand-600 disabled:opacity-60">
              {enviando ? <Loader2 size={16} className="animate-spin" /> : <UploadCloud size={16} />} Guardar producto
            </button>
          </section>
        </div>
      </div>
    </form>
  );
}

// ----- piezas de formulario -----
function Campo({ label, children, full }: { label: string; children: React.ReactNode; full?: boolean }) {
  return (
    <label className={`block ${full ? "sm:col-span-full" : ""}`}>
      <span className="mb-1.5 block text-[11px] font-medium uppercase tracking-widest2 text-graph-400">{label}</span>
      {children}
    </label>
  );
}
function SubLabel({ children }: { children: React.ReactNode }) {
  return <span className="mb-2 block text-[11px] font-medium uppercase tracking-widest2 text-graph-400">{children}</span>;
}
function Inp({ value, onChange, ph, mode, autoFocus }: { value: string; onChange: (v: string) => void; ph?: string; mode?: "numeric"; autoFocus?: boolean }) {
  return (
    <input
      value={value}
      onChange={(e) => onChange(e.target.value)}
      placeholder={ph}
      inputMode={mode}
      autoFocus={autoFocus}
      className="h-10 w-full rounded-xl border border-graph/10 bg-graph/[0.04] px-3 text-sm text-graph placeholder:text-graph-400 outline-none transition focus:border-brand/60"
    />
  );
}
function Toggle({ label, v, on, disabled }: { label: string; v: boolean; on: () => void; disabled?: boolean }) {
  return (
    <button type="button" onClick={on} disabled={disabled} className="flex min-h-[40px] w-full items-center justify-between rounded-lg px-1 py-1.5 text-sm text-graph disabled:opacity-40">
      <span>{label}</span>
      <span className={`relative h-5 w-9 rounded-full transition ${v ? "bg-brand" : "bg-graph/15"}`}>
        <span className={`absolute top-0.5 h-4 w-4 rounded-full bg-white transition-all ${v ? "left-[18px]" : "left-0.5"}`} />
      </span>
    </button>
  );
}
