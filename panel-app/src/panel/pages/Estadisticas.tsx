import { RefreshCw, Package, Layers, ShoppingCart, Clock, Receipt, Boxes, FileSpreadsheet, ArrowRight } from "lucide-react";
import { Link } from "react-router-dom";
import { useData } from "@/lib/DataProvider";
import { fmtARS } from "@/lib/format";
import { EXPORT_EXCEL_URL } from "../api/miamiApi";
import { PageHeader, EmptyState } from "../components/PageShell";
import KpiCard from "../components/KpiCard";
import Badge from "../components/Badge";

// ============================================================================
//  ESTADÍSTICAS — el detalle numérico de /panel/api/stats (paridad con la tab
//  del panel viejo) + acceso directo al Excel completo.
// ============================================================================

export default function Estadisticas() {
  const { stats, loading, error, recargar } = useData();

  if (error && !stats) return <div><PageHeader title="Estadísticas" /><EmptyState msg={error} /></div>;

  const s = stats;
  return (
    <div>
      <PageHeader
        title="Estadísticas"
        subtitle="Números reales del negocio: catálogo, stock y pedidos."
        actions={
          <button onClick={() => recargar()} className="inline-flex h-10 items-center gap-2 rounded-xl border border-graph/15 px-4 text-sm font-medium text-graph-500 transition hover:text-graph">
            <RefreshCw size={15} /> Actualizar
          </button>
        }
      />

      <div className="grid grid-cols-2 gap-3 md:gap-4 lg:grid-cols-3">
        <KpiCard label="Total productos" value={loading ? "…" : `${s?.productos.total ?? 0}`} icon={Package} hint={`${s?.productos.publicados ?? 0} publicados`} accent="brand" />
        <KpiCard label="Total talles (variantes)" value={loading ? "…" : `${s?.productos.variantes ?? 0}`} icon={Layers} hint="talles + SKUs" accent="ink" />
        <KpiCard label="Stock total" value={loading ? "…" : `${s?.productos.stock_total ?? 0}`} icon={Boxes} hint="unidades en catálogo" accent="ink" />
        <KpiCard label="Pedidos pagados" value={loading ? "…" : `${s?.pedidos.pagados ?? 0}`} icon={ShoppingCart} hint={`de ${s?.pedidos.total ?? 0} totales`} accent="sea" />
        <KpiCard label="Pedidos pendientes" value={loading ? "…" : `${s?.pedidos.pendientes ?? 0}`} icon={Clock} hint="a procesar" accent={s?.pedidos.pendientes ? "amber" : "ink"} />
        <KpiCard label="Ticket promedio" value={loading ? "…" : fmtARS(Math.round(s?.pedidos.ticket_promedio ?? 0), { short: true })} icon={Receipt} hint={`facturado ${fmtARS(s?.pedidos.facturado_total ?? 0, { short: true })}`} accent="brand" />
      </div>

      <div className="mt-5 grid gap-4 lg:grid-cols-2">
        {/* top vendidos */}
        <div className="pcard">
          <div className="border-b border-graph/[0.07] px-5 py-4">
            <h3 className="font-display text-base font-semibold text-graph">Top vendidos</h3>
            <p className="text-xs text-graph-400">Unidades por producto, según los pedidos reales</p>
          </div>
          {!s || s.top_vendidos.length === 0 ? (
            <p className="px-5 py-8 text-center text-sm text-graph-400">Todavía no hay ventas registradas.</p>
          ) : (
            <ol className="divide-y divide-graph/[0.07]">
              {s.top_vendidos.map((t, i) => (
                <li key={t.product_id} className="flex items-center gap-3 px-5 py-3">
                  <span className="grid h-7 w-7 shrink-0 place-items-center rounded-lg bg-brand/10 text-xs font-bold text-brand-700">{i + 1}</span>
                  <span className="min-w-0 flex-1 truncate text-sm font-medium text-graph">{t.name}</span>
                  <Badge tone="brand">{t.vendidos} u.</Badge>
                </li>
              ))}
            </ol>
          )}
        </div>

        {/* excel + atajos */}
        <div className="space-y-4">
          <div className="pcard p-5">
            <h3 className="flex items-center gap-2 font-display text-base font-semibold text-graph">
              <FileSpreadsheet size={17} className="text-brand" /> Excel completo
            </h3>
            <p className="mt-1 text-sm text-graph-400">Catálogo + variantes + pedidos en un solo archivo. Puede tardar unos segundos en generarse.</p>
            <a
              href={EXPORT_EXCEL_URL}
              className="mt-3 inline-flex h-10 items-center gap-2 rounded-xl bg-brand px-4 text-sm font-semibold text-white transition hover:bg-brand-600"
            >
              <FileSpreadsheet size={15} /> Descargar Excel
            </a>
          </div>
          <Link to="/panel" className="pcard pcard-hover flex items-center gap-3 p-5">
            <span className="min-w-0 flex-1">
              <span className="block text-sm font-semibold text-graph">Ver el dashboard</span>
              <span className="block text-xs text-graph-400">Gráficos de stock por marca y alertas del día</span>
            </span>
            <ArrowRight size={15} className="text-graph-400" />
          </Link>
        </div>
      </div>
    </div>
  );
}
