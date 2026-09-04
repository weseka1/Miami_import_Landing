import { useState } from "react";
import { Loader2, FileSpreadsheet, Rocket, Shirt, Zap } from "lucide-react";
import { api, ApiError, EXPORT_EXCEL_URL } from "../api/miamiApi";
import { PageHeader } from "../components/PageShell";
import { useToast } from "../components/Toast";

// ============================================================================
//  ACCIONES — utilidades sueltas: Excel completo y redeploy del bot en Render.
//  (El upload de theme por FTP del panel viejo era de la era Tiendanube y ya
//  no aplica: la tienda ahora es nuestra.)
// ============================================================================

export default function Acciones() {
  const { push } = useToast();
  const [redeployando, setRedeployando] = useState(false);
  const [redeployInfo, setRedeployInfo] = useState("");

  const [precalentando, setPrecalentando] = useState(false);
  const [precalentarInfo, setPrecalentarInfo] = useState("");

  const precalentar = async () => {
    setPrecalentando(true);
    setPrecalentarInfo("");
    try {
      const r = await api.precalentarRecortes();
      if (r.error) {
        setPrecalentarInfo(`No se pudo: ${r.error}`);
        push(r.error, "error");
      } else {
        const nuevas = r.recortados ?? 0;
        setPrecalentarInfo(
          `${nuevas} prendas preparadas · ${r.ya_estaban ?? 0} ya estaban · ` +
          `${r.fallaron ?? 0} fallaron · ${r.no_aplican ?? 0} no se prueban (gorras, calzado…)`);
        push(nuevas ? `${nuevas} prendas listas para el probador` : "Ya estaban todas listas", "success");
      }
    } catch (e) {
      const msg = e instanceof ApiError ? e.message : "No se pudo preparar las prendas";
      setPrecalentarInfo(`No se pudo: ${msg}`);
      push(msg, "error");
    } finally {
      setPrecalentando(false);
    }
  };

  const redeploy = async () => {
    setRedeployando(true);
    setRedeployInfo("");
    try {
      const r = await api.redeployBot();
      if (r.ok) {
        setRedeployInfo(`Redeploy disparado (HTTP ${r.status}). Esperá ~3 minutos y verificá en el dashboard de Render.`);
        push("Redeploy disparado", "success");
      } else {
        setRedeployInfo(`No se pudo: ${r.error || "error desconocido"}`);
        push(r.error || "No se pudo disparar el redeploy", "error");
      }
    } catch (e) {
      const msg = e instanceof ApiError ? e.message : "No se pudo disparar el redeploy";
      setRedeployInfo(`No se pudo: ${msg}`);
      push(msg, "error");
    } finally {
      setRedeployando(false);
    }
  };

  return (
    <div>
      <PageHeader title="Acciones rápidas" subtitle="Utilidades del negocio que no son del día a día." />

      <div className="grid gap-4 lg:grid-cols-2">
        <div className="pcard p-5">
          <h3 className="flex items-center gap-2 font-display text-base font-semibold text-graph">
            <FileSpreadsheet size={17} className="text-brand" /> Descargar Excel completo
          </h3>
          <p className="mt-1 text-sm text-graph-400">
            Todo el negocio en un archivo: productos, variantes con stock y precio, y los últimos 1.000 pedidos. Puede tardar 10–30 segundos.
          </p>
          <a href={EXPORT_EXCEL_URL} className="mt-4 inline-flex h-10 items-center gap-2 rounded-xl bg-brand px-4 text-sm font-semibold text-white transition hover:bg-brand-600">
            <FileSpreadsheet size={15} /> Generar y descargar
          </a>
        </div>

        <div className="pcard p-5">
          <h3 className="flex items-center gap-2 font-display text-base font-semibold text-graph">
            <Rocket size={17} className="text-brand" /> Redeploy del bot en Render
          </h3>
          <p className="mt-1 text-sm text-graph-400">
            Dispara un redeploy del Bot-Miami en Render. Requiere <code className="rounded bg-graph/[0.06] px-1.5 py-0.5 text-[12px]">RENDER_DEPLOY_HOOK</code> configurado en el servidor.
          </p>
          <button onClick={redeploy} disabled={redeployando} className="mt-4 inline-flex h-10 items-center gap-2 rounded-xl border border-graph/15 bg-graph/[0.03] px-4 text-sm font-semibold text-graph transition hover:border-graph/30 disabled:opacity-50">
            {redeployando ? <Loader2 size={15} className="animate-spin" /> : <Zap size={15} />} Redeploy bot ahora
          </button>
          {redeployInfo && <p className="mt-3 rounded-lg bg-graph/[0.03] px-3 py-2 text-xs font-medium text-graph-500">{redeployInfo}</p>}
        </div>

        <div className="pcard p-5">
          <h3 className="flex items-center gap-2 font-display text-base font-semibold text-graph">
            <Shirt size={17} className="text-brand" /> Preparar prendas para el probador
          </h3>
          <p className="mt-1 text-sm text-graph-400">
            El probador virtual necesita la prenda <strong>sola</strong>, sin la percha ni el
            local de fondo. Esto la recorta de antemano para todo el catálogo, así el
            cliente que prueba una prenda por primera vez ya la ve bien.
            Correlo después de cargar productos nuevos.
          </p>
          <button onClick={precalentar} disabled={precalentando} className="mt-4 inline-flex h-10 items-center gap-2 rounded-xl border border-graph/15 bg-graph/[0.03] px-4 text-sm font-semibold text-graph transition hover:border-graph/30 disabled:opacity-50">
            {precalentando ? <Loader2 size={15} className="animate-spin" /> : <Shirt size={15} />}
            {precalentando ? "Preparando…" : "Preparar prendas ahora"}
          </button>
          {precalentando && (
            <p className="mt-3 text-xs text-graph-400">
              Tarda varios minutos: es una prenda por vez. Podés seguir usando el panel.
            </p>
          )}
          {precalentarInfo && <p className="mt-3 rounded-lg bg-graph/[0.03] px-3 py-2 text-xs font-medium text-graph-500">{precalentarInfo}</p>}
        </div>
      </div>
    </div>
  );
}
