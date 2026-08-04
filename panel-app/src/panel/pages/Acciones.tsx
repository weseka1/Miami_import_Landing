import { useState } from "react";
import { Loader2, FileSpreadsheet, Rocket, Zap } from "lucide-react";
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
      </div>
    </div>
  );
}
