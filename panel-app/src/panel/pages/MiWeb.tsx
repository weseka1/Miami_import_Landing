import { useEffect, useRef, useState } from "react";
import {
  Loader2, Save, RotateCcw, Plus, Trash2, ArrowUp, ArrowDown,
  ImagePlus, Sparkles, ExternalLink, Eye, EyeOff,
} from "lucide-react";
import { api, ApiError, type HomeConfig, type HomeMarca, type HomePieza, type HomeValor } from "../api/miamiApi";
import { PageHeader } from "../components/PageShell";
import { useToast } from "../components/Toast";
import { cn } from "../ui/cn";

// ============================================================================
//  MI WEB — Diego edita la home de la tienda sin depender de nosotros.
//  Cada bloque (Portada, Vitrina, Marcas, Valores, Cierre) se guarda por
//  separado: el backend hace merge, así que guardar uno nunca pisa los otros.
//  Las fotos de la vitrina/marcas se suben y la IA les saca el fondo.
// ============================================================================

const INP =
  "h-10 w-full rounded-xl border border-graph/15 bg-paper-100 px-3 text-sm text-graph outline-none " +
  "transition placeholder:text-graph-400 focus:border-brand/60 focus:bg-white focus:ring-2 focus:ring-brand/15";
const TXT = INP.replace("h-10", "min-h-[76px] py-2");
const LBL = "mb-1 block text-[11px] font-medium uppercase tracking-wide text-graph-400";

/** Caja de una sección, con su propio botón de guardar. */
function Bloque({
  titulo, ayuda, children, onGuardar, guardando, sucio, extra,
}: {
  titulo: string; ayuda?: string; children: React.ReactNode;
  onGuardar: () => void; guardando: boolean; sucio: boolean; extra?: React.ReactNode;
}) {
  return (
    <section className="rounded-2xl border border-graph/[0.08] bg-white p-5 shadow-sm">
      <div className="mb-4 flex flex-wrap items-start justify-between gap-3">
        <div className="min-w-0">
          <h2 className="font-display text-lg font-semibold text-graph">{titulo}</h2>
          {ayuda && <p className="mt-0.5 text-xs text-graph-400">{ayuda}</p>}
        </div>
        <div className="flex items-center gap-2">
          {extra}
          <button
            onClick={onGuardar}
            disabled={guardando || !sucio}
            className={cn(
              "inline-flex h-9 items-center gap-1.5 rounded-xl px-4 text-xs font-semibold transition",
              sucio ? "bg-brand text-white hover:bg-brand-700" : "bg-graph/[0.06] text-graph-400",
              guardando && "opacity-60",
            )}
          >
            {guardando ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
            {sucio ? "Guardar" : "Guardado"}
          </button>
        </div>
      </div>
      {children}
    </section>
  );
}

/** Subida de foto con recorte por IA + vista previa sobre fondo negro (como se ve en la web). */
function FotoCampo({
  valor, destino, recorteIA, onCambio, alto = "h-32",
}: {
  valor: string; destino: string; recorteIA: boolean;
  onCambio: (url: string) => void; alto?: string;
}) {
  const { push } = useToast();
  const [subiendo, setSubiendo] = useState(false);
  const ref = useRef<HTMLInputElement>(null);

  const subir = async (file: File | undefined, quitarFondo: boolean) => {
    if (!file) return;
    if (file.size > 8 * 1024 * 1024) { push("La foto pesa más de 8 MB", "error"); return; }
    setSubiendo(true);
    try {
      const r = await api.webImagen(file, quitarFondo, destino);
      onCambio(r.url);
      if (r.aviso) push(r.aviso, "info");
      else if (r.motor) push("Fondo quitado ✓ acordate de guardar", "success");
      else push("Foto subida ✓ acordate de guardar", "success");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo subir la foto", "error");
    } finally {
      setSubiendo(false);
      if (ref.current) ref.current.value = "";
    }
  };

  return (
    <div>
      {/* fondo oscuro: así se ve igual que en la web y se nota si quedó fondo */}
      <div className={cn("mb-2 grid place-items-center overflow-hidden rounded-xl bg-[#0E0B08] p-2", alto)}>
        {valor
          ? <img src={valor} alt="" className="max-h-full max-w-full object-contain" />
          : <span className="text-[11px] uppercase tracking-wide text-white/30">Sin foto</span>}
      </div>
      <input ref={ref} type="file" accept="image/*" className="hidden"
             onChange={(e) => subir(e.target.files?.[0], recorteIA)} />
      <div className="flex flex-wrap gap-1.5">
        <button
          onClick={() => ref.current?.click()} disabled={subiendo}
          className="inline-flex h-8 items-center gap-1.5 rounded-lg bg-brand/10 px-3 text-[11px] font-semibold text-brand-700 transition hover:bg-brand hover:text-white disabled:opacity-50"
        >
          {subiendo ? <Loader2 size={12} className="animate-spin" /> : (recorteIA ? <Sparkles size={12} /> : <ImagePlus size={12} />)}
          {subiendo ? "Procesando…" : (recorteIA ? "Subir y quitar fondo" : "Subir foto")}
        </button>
        {valor && (
          <button onClick={() => onCambio("")}
                  className="inline-flex h-8 items-center gap-1 rounded-lg px-2.5 text-[11px] text-graph-400 transition hover:bg-red-500/10 hover:text-red-600">
            <Trash2 size={12} /> Quitar
          </button>
        )}
      </div>
    </div>
  );
}

export default function MiWeb() {
  const { push } = useToast();
  const [cfg, setCfg] = useState<HomeConfig | null>(null);
  const [orig, setOrig] = useState<string>("");     // JSON de referencia para saber qué cambió
  const [recorteIA, setRecorteIA] = useState(false);
  const [cargando, setCargando] = useState(true);
  const [guardando, setGuardando] = useState<string | null>(null);

  const cargar = async () => {
    setCargando(true);
    try {
      const r = await api.webHome();
      setCfg(r.config);
      setOrig(JSON.stringify(r.config));
      setRecorteIA(r.recorte_ia);
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo cargar la web", "error");
    } finally {
      setCargando(false);
    }
  };
  useEffect(() => { void cargar(); }, []); // eslint-disable-line react-hooks/exhaustive-deps

  if (cargando || !cfg) {
    return (
      <div className="grid place-items-center py-20 text-graph-400">
        <Loader2 className="animate-spin" />
      </div>
    );
  }

  const previo: HomeConfig | null = orig ? JSON.parse(orig) : null;
  const sucio = (k: keyof HomeConfig) =>
    !previo || JSON.stringify(cfg[k]) !== JSON.stringify(previo[k]);

  const set = <K extends keyof HomeConfig>(k: K, v: HomeConfig[K]) =>
    setCfg((c) => (c ? { ...c, [k]: v } : c));

  const guardar = async (k: keyof HomeConfig) => {
    setGuardando(k);
    try {
      const r = await api.webHomeGuardar({ [k]: cfg[k] } as Partial<HomeConfig>);
      setCfg(r.config);
      setOrig(JSON.stringify(r.config));
      push("Listo, ya está en la web", "success");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo guardar", "error");
    } finally {
      setGuardando(null);
    }
  };

  const resetear = async () => {
    if (!window.confirm("¿Volver TODA la home a como vino de fábrica? Se pierden los cambios.")) return;
    try {
      const r = await api.webHomeReset();
      setCfg(r.config);
      setOrig(JSON.stringify(r.config));
      push("La home volvió a los valores originales", "info");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo restaurar", "error");
    }
  };

  /** Mueve un ítem dentro de una lista (para ordenar piezas/marcas/valores). */
  const mover = <T,>(arr: T[], i: number, delta: number): T[] => {
    const j = i + delta;
    if (j < 0 || j >= arr.length) return arr;
    const out = [...arr];
    [out[i], out[j]] = [out[j], out[i]];
    return out;
  };

  const ojo = (activo: boolean, onToggle: () => void) => (
    <button onClick={onToggle}
            title={activo ? "Se está mostrando en la web" : "Oculto en la web"}
            className={cn("inline-flex h-9 items-center gap-1.5 rounded-xl px-3 text-xs font-medium transition",
                          activo ? "bg-green-500/10 text-green-700" : "bg-graph/[0.06] text-graph-400")}>
      {activo ? <Eye size={14} /> : <EyeOff size={14} />}
      {activo ? "Visible" : "Oculta"}
    </button>
  );

  return (
    <>
      <PageHeader
        title="Mi web"
        subtitle="Todo lo que se ve en la portada de miamiimport.com.ar. Los cambios salen al instante."
        actions={
          <>
            <a href="https://miamiimport.com.ar" target="_blank" rel="noopener noreferrer"
               className="inline-flex h-9 items-center gap-1.5 rounded-xl border border-graph/15 px-3 text-xs font-medium text-graph transition hover:bg-graph/[0.04]">
              <ExternalLink size={14} /> Ver la web
            </a>
            <button onClick={resetear}
                    className="inline-flex h-9 items-center gap-1.5 rounded-xl border border-graph/15 px-3 text-xs font-medium text-graph-400 transition hover:bg-red-500/10 hover:text-red-600">
              <RotateCcw size={14} /> Restaurar todo
            </button>
          </>
        }
      />

      {!recorteIA && (
        <div className="mb-5 rounded-xl border border-amber-400/30 bg-amber-50 px-4 py-3 text-sm text-amber-900">
          <strong>Ojo:</strong> falta configurar la IA que saca el fondo de las fotos. Podés subir
          imágenes igual, pero van con su fondo — para la vitrina conviene subir un PNG ya recortado.
        </div>
      )}

      <div className="space-y-5 pb-10">
        {/* ---------------- PORTADA ---------------- */}
        <Bloque titulo="Portada" ayuda="El video grande de arriba de todo y su texto."
                onGuardar={() => guardar("hero")} guardando={guardando === "hero"} sucio={sucio("hero")}>
          <div className="grid gap-3 md:grid-cols-2">
            <label className="block md:col-span-2">
              <span className={LBL}>Línea de arriba</span>
              <input className={INP} value={cfg.hero.eyebrow}
                     onChange={(e) => set("hero", { ...cfg.hero, eyebrow: e.target.value })} />
            </label>
            <label className="block">
              <span className={LBL}>Título</span>
              <input className={INP} value={cfg.hero.titulo}
                     onChange={(e) => set("hero", { ...cfg.hero, titulo: e.target.value })} />
            </label>
            <label className="block">
              <span className={LBL}>Frase destacada</span>
              <input className={INP} value={cfg.hero.subtitulo}
                     onChange={(e) => set("hero", { ...cfg.hero, subtitulo: e.target.value })} />
            </label>
            <label className="block">
              <span className={LBL}>Botón principal</span>
              <input className={INP} value={cfg.hero.cta_texto}
                     onChange={(e) => set("hero", { ...cfg.hero, cta_texto: e.target.value })} />
            </label>
            <label className="block">
              <span className={LBL}>Botón secundario</span>
              <input className={INP} value={cfg.hero.cta2_texto}
                     onChange={(e) => set("hero", { ...cfg.hero, cta2_texto: e.target.value })} />
            </label>
          </div>
        </Bloque>

        {/* ---------------- VITRINA ---------------- */}
        <Bloque
          titulo="Vitrina de piezas" guardando={guardando === "vitrina"} sucio={sucio("vitrina")}
          ayuda="Las prendas grandes que giran al principio. Subí la foto y la IA le saca el fondo."
          onGuardar={() => guardar("vitrina")}
          extra={ojo(cfg.vitrina.activo, () => set("vitrina", { ...cfg.vitrina, activo: !cfg.vitrina.activo }))}
        >
          <div className="space-y-4">
            {cfg.vitrina.piezas.map((p, i) => {
              const upd = (patch: Partial<HomePieza>) => {
                const piezas = [...cfg.vitrina.piezas];
                piezas[i] = { ...piezas[i], ...patch };
                set("vitrina", { ...cfg.vitrina, piezas });
              };
              return (
                <div key={i} className="rounded-xl border border-graph/[0.08] bg-graph/[0.02] p-4">
                  <div className="grid gap-4 md:grid-cols-[190px_1fr]">
                    <FotoCampo valor={p.imagen} destino="vitrina" recorteIA={recorteIA} alto="h-40"
                               onCambio={(url) => upd({ imagen: url })} />
                    <div className="grid gap-3 sm:grid-cols-2">
                      <label className="block">
                        <span className={LBL}>Nombre</span>
                        <input className={INP} value={p.nombre} onChange={(e) => upd({ nombre: e.target.value })} />
                      </label>
                      <label className="block">
                        <span className={LBL}>Sección</span>
                        <select className={INP} value={p.genero || "hombre"}
                                onChange={(e) => upd({ genero: e.target.value })}>
                          <option value="hombre">Hombre</option>
                          <option value="mujer">Mujer</option>
                        </select>
                      </label>
                      <label className="block">
                        <span className={LBL}>Color</span>
                        <input className={INP} value={p.colorway || ""} onChange={(e) => upd({ colorway: e.target.value })} />
                      </label>
                      <label className="block">
                        <span className={LBL}>Talles</span>
                        <input className={INP} value={p.talles || ""} onChange={(e) => upd({ talles: e.target.value })} />
                      </label>
                      <label className="block sm:col-span-2">
                        <span className={LBL}>Descripción</span>
                        <textarea className={TXT} value={p.descripcion || ""}
                                  onChange={(e) => upd({ descripcion: e.target.value })} />
                      </label>
                      <label className="block sm:col-span-2">
                        <span className={LBL}>A dónde lleva al tocarla</span>
                        <input className={INP} placeholder="/tipo/camperas" value={p.link || ""}
                               onChange={(e) => upd({ link: e.target.value })} />
                      </label>
                    </div>
                  </div>
                  <div className="mt-3 flex justify-end gap-1 border-t border-graph/[0.07] pt-3">
                    <button onClick={() => set("vitrina", { ...cfg.vitrina, piezas: mover(cfg.vitrina.piezas, i, -1) })}
                            disabled={i === 0} title="Subir"
                            className="grid h-8 w-8 place-items-center rounded-lg text-graph-400 transition hover:bg-graph/[0.06] disabled:opacity-30"><ArrowUp size={14} /></button>
                    <button onClick={() => set("vitrina", { ...cfg.vitrina, piezas: mover(cfg.vitrina.piezas, i, 1) })}
                            disabled={i === cfg.vitrina.piezas.length - 1} title="Bajar"
                            className="grid h-8 w-8 place-items-center rounded-lg text-graph-400 transition hover:bg-graph/[0.06] disabled:opacity-30"><ArrowDown size={14} /></button>
                    <button onClick={() => {
                              if (!window.confirm(`¿Sacar "${p.nombre}" de la vitrina?`)) return;
                              set("vitrina", { ...cfg.vitrina, piezas: cfg.vitrina.piezas.filter((_, j) => j !== i) });
                            }}
                            title="Sacar de la vitrina"
                            className="grid h-8 w-8 place-items-center rounded-lg text-graph-400 transition hover:bg-red-500/10 hover:text-red-600"><Trash2 size={14} /></button>
                  </div>
                </div>
              );
            })}
            <button
              onClick={() => set("vitrina", { ...cfg.vitrina, piezas: [...cfg.vitrina.piezas,
                { nombre: "NUEVA PIEZA", genero: "hombre", imagen: "", colorway: "", talles: "S — 2XL",
                  peso: "", link: "/productos", descripcion: "" }] })}
              className="inline-flex h-10 items-center gap-1.5 rounded-xl border border-dashed border-brand/40 px-4 text-sm font-medium text-brand-700 transition hover:bg-brand/[0.06]"
            ><Plus size={15} /> Agregar pieza</button>
          </div>
        </Bloque>

        {/* ---------------- MARCAS ---------------- */}
        <Bloque
          titulo="Marcas" guardando={guardando === "marcas"} sucio={sucio("marcas")}
          ayuda="El carrusel de marcas con su foto." onGuardar={() => guardar("marcas")}
          extra={ojo(cfg.marcas.activo, () => set("marcas", { ...cfg.marcas, activo: !cfg.marcas.activo }))}
        >
          <div className="mb-4 grid gap-3 md:grid-cols-2">
            <label className="block">
              <span className={LBL}>Título de la sección</span>
              <input className={INP} value={cfg.marcas.titulo}
                     onChange={(e) => set("marcas", { ...cfg.marcas, titulo: e.target.value })} />
            </label>
            <label className="block">
              <span className={LBL}>Bajada</span>
              <input className={INP} value={cfg.marcas.bajada}
                     onChange={(e) => set("marcas", { ...cfg.marcas, bajada: e.target.value })} />
            </label>
          </div>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {cfg.marcas.items.map((m, i) => {
              const upd = (patch: Partial<HomeMarca>) => {
                const items = [...cfg.marcas.items];
                items[i] = { ...items[i], ...patch };
                set("marcas", { ...cfg.marcas, items });
              };
              return (
                <div key={i} className="rounded-xl border border-graph/[0.08] bg-graph/[0.02] p-3">
                  <FotoCampo valor={m.imagen} destino="marcas" recorteIA={recorteIA}
                             onCambio={(url) => upd({ imagen: url })} />
                  <label className="mt-2 block">
                    <span className={LBL}>Marca</span>
                    <input className={INP} value={m.nombre} onChange={(e) => upd({ nombre: e.target.value })} />
                  </label>
                  <label className="mt-2 block">
                    <span className={LBL}>Link</span>
                    <input className={INP} placeholder="/categoria/diesel" value={m.link}
                           onChange={(e) => upd({ link: e.target.value })} />
                  </label>
                  <div className="mt-2 flex justify-end gap-1">
                    <button onClick={() => set("marcas", { ...cfg.marcas, items: mover(cfg.marcas.items, i, -1) })}
                            disabled={i === 0}
                            className="grid h-8 w-8 place-items-center rounded-lg text-graph-400 transition hover:bg-graph/[0.06] disabled:opacity-30"><ArrowUp size={14} /></button>
                    <button onClick={() => set("marcas", { ...cfg.marcas, items: mover(cfg.marcas.items, i, 1) })}
                            disabled={i === cfg.marcas.items.length - 1}
                            className="grid h-8 w-8 place-items-center rounded-lg text-graph-400 transition hover:bg-graph/[0.06] disabled:opacity-30"><ArrowDown size={14} /></button>
                    <button onClick={() => {
                              if (!window.confirm(`¿Sacar ${m.nombre}?`)) return;
                              set("marcas", { ...cfg.marcas, items: cfg.marcas.items.filter((_, j) => j !== i) });
                            }}
                            className="grid h-8 w-8 place-items-center rounded-lg text-graph-400 transition hover:bg-red-500/10 hover:text-red-600"><Trash2 size={14} /></button>
                  </div>
                </div>
              );
            })}
          </div>
          <button
            onClick={() => set("marcas", { ...cfg.marcas, items: [...cfg.marcas.items, { nombre: "NUEVA MARCA", link: "/productos", imagen: "" }] })}
            className="mt-3 inline-flex h-10 items-center gap-1.5 rounded-xl border border-dashed border-brand/40 px-4 text-sm font-medium text-brand-700 transition hover:bg-brand/[0.06]"
          ><Plus size={15} /> Agregar marca</button>
        </Bloque>

        {/* ---------------- TÍTULOS DE SECCIONES ---------------- */}
        <Bloque titulo="Títulos de las secciones" ayuda="Los encabezados de las tres franjas de productos."
                onGuardar={() => guardar("secciones")} guardando={guardando === "secciones"} sucio={sucio("secciones")}>
          <div className="grid gap-3 md:grid-cols-2">
            {([
              ["mas_vendidos_eyebrow", "Más vendidos · línea chica"],
              ["mas_vendidos_titulo", "Más vendidos · título"],
              ["destacados_eyebrow", "Destacados · línea chica"],
              ["destacados_titulo", "Destacados · título"],
              ["ultimos_eyebrow", "Últimos · línea chica"],
              ["ultimos_titulo", "Últimos · título"],
            ] as const).map(([k, label]) => (
              <label className="block" key={k}>
                <span className={LBL}>{label}</span>
                <input className={INP} value={cfg.secciones[k] || ""}
                       onChange={(e) => set("secciones", { ...cfg.secciones, [k]: e.target.value })} />
              </label>
            ))}
          </div>
        </Bloque>

        {/* ---------------- VALORES ---------------- */}
        <Bloque titulo="Por qué comprarnos" ayuda="Los cuadraditos numerados de más abajo."
                onGuardar={() => guardar("valores")} guardando={guardando === "valores"} sucio={sucio("valores")}
                extra={ojo(cfg.valores.activo, () => set("valores", { ...cfg.valores, activo: !cfg.valores.activo }))}>
          <div className="space-y-3">
            {cfg.valores.items.map((v, i) => {
              const upd = (patch: Partial<HomeValor>) => {
                const items = [...cfg.valores.items];
                items[i] = { ...items[i], ...patch };
                set("valores", { ...cfg.valores, items });
              };
              return (
                <div key={i} className="grid gap-2 rounded-xl border border-graph/[0.08] bg-graph/[0.02] p-3 sm:grid-cols-[70px_1fr_2fr_40px]">
                  <input className={INP} value={v.num} onChange={(e) => upd({ num: e.target.value })} placeholder="01" />
                  <input className={INP} value={v.titulo} onChange={(e) => upd({ titulo: e.target.value })} placeholder="Título" />
                  <input className={INP} value={v.texto} onChange={(e) => upd({ texto: e.target.value })} placeholder="Texto" />
                  <button onClick={() => set("valores", { ...cfg.valores, items: cfg.valores.items.filter((_, j) => j !== i) })}
                          className="grid h-10 w-10 place-items-center rounded-lg text-graph-400 transition hover:bg-red-500/10 hover:text-red-600"><Trash2 size={14} /></button>
                </div>
              );
            })}
            <button
              onClick={() => set("valores", { ...cfg.valores, items: [...cfg.valores.items,
                { num: String(cfg.valores.items.length + 1).padStart(2, "0"), titulo: "", texto: "" }] })}
              className="inline-flex h-10 items-center gap-1.5 rounded-xl border border-dashed border-brand/40 px-4 text-sm font-medium text-brand-700 transition hover:bg-brand/[0.06]"
            ><Plus size={15} /> Agregar</button>
          </div>
        </Bloque>

        {/* ---------------- CIERRE ---------------- */}
        <Bloque titulo="Cierre con WhatsApp" ayuda="La última franja, la que invita a escribirte."
                onGuardar={() => guardar("cierre")} guardando={guardando === "cierre"} sucio={sucio("cierre")}
                extra={ojo(cfg.cierre.activo, () => set("cierre", { ...cfg.cierre, activo: !cfg.cierre.activo }))}>
          <div className="grid gap-3 md:grid-cols-2">
            <label className="block">
              <span className={LBL}>Título</span>
              <input className={INP} value={cfg.cierre.titulo}
                     onChange={(e) => set("cierre", { ...cfg.cierre, titulo: e.target.value })} />
            </label>
            <label className="block">
              <span className={LBL}>Texto</span>
              <input className={INP} value={cfg.cierre.texto}
                     onChange={(e) => set("cierre", { ...cfg.cierre, texto: e.target.value })} />
            </label>
            <label className="block">
              <span className={LBL}>Texto del botón</span>
              <input className={INP} value={cfg.cierre.cta_texto}
                     onChange={(e) => set("cierre", { ...cfg.cierre, cta_texto: e.target.value })} />
            </label>
            <label className="block">
              <span className={LBL}>Mensaje que le llega por WhatsApp</span>
              <input className={INP} value={cfg.cierre.wa_mensaje}
                     onChange={(e) => set("cierre", { ...cfg.cierre, wa_mensaje: e.target.value })} />
            </label>
          </div>
        </Bloque>
      </div>
    </>
  );
}
