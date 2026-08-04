import { Link } from "react-router-dom";
import {
  Banknote,
  Package,
  PackageX,
  Layers,
  AlertTriangle,
  ShoppingCart,
  ArrowRight,
  RefreshCw,
} from "lucide-react";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  PieChart,
  Pie,
  Cell,
  Legend,
} from "recharts";
import { useData } from "@/lib/DataProvider";
import { fmtARS } from "@/lib/format";
import { fotoDe, precioDe, stockDe } from "../api/miamiApi";
import { useProfiles } from "../profiles";
import KpiCard from "../components/KpiCard";
import ChartCard from "../components/ChartCard";
import Badge from "../components/Badge";
import ProductoThumb from "../components/ProductoThumb";
import { PageHeader, EmptyState } from "../components/PageShell";
import { COLORS, SERIE, tooltipStyle } from "../ui/chartTheme";

// Dashboard 100% sobre datos REALES del backend (/panel/api/stats + catálogo).
// Nada de series inventadas: lo que no existe todavía (ventas) se muestra vacío.

export default function Dashboard() {
  const { loading, error, stats, productos, kpis, stockPorMarca, recargar } = useData();
  const { activo } = useProfiles();

  const hoyLargo = new Date().toLocaleDateString("es-AR", { weekday: "long", day: "numeric", month: "long", year: "numeric" });

  if (error && !stats) {
    return (
      <div className="grid min-h-[50vh] place-items-center">
        <div className="pcard max-w-md p-8 text-center">
          <p className="font-display text-lg font-semibold text-graph">No se pudo hablar con el servidor</p>
          <p className="mt-2 text-sm text-graph-400">{error}</p>
          <button onClick={() => recargar()} className="mt-4 inline-flex h-10 items-center gap-2 rounded-xl bg-brand px-4 text-sm font-semibold text-white transition hover:bg-brand-600">
            <RefreshCw size={15} /> Reintentar
          </button>
        </div>
      </div>
    );
  }

  const topVendidos = stats?.top_vendidos ?? [];
  const stockBajo = stats?.stock_bajo ?? [];
  const marcasTop = stockPorMarca.slice(0, 6);
  const restoMarcas = stockPorMarca.slice(6).reduce((a, m) => a + m.value, 0);
  const tortaMarcas = restoMarcas > 0 ? [...marcasTop, { name: "Otras", value: restoMarcas }] : marcasTop;

  const ultimosCargados = [...productos]
    .sort((a, b) => +(new Date(b.created_at || 0)) - +(new Date(a.created_at || 0)))
    .slice(0, 5);

  return (
    <div>
      <PageHeader
        title={`Buen día, ${activo?.nombre ?? "equipo"}`}
        subtitle={`Resumen real de MIAMI IMPORT · ${hoyLargo}`}
      />

      {/* KPIs — directo de /panel/api/stats */}
      <div className="grid grid-cols-2 gap-3 md:gap-4 lg:grid-cols-3 xl:grid-cols-6">
        <KpiCard
          label="Publicados"
          value={loading ? "…" : `${kpis.publicados}`}
          icon={Package}
          hint={`${kpis.total} en catálogo`}
          accent="brand"
        />
        <KpiCard
          label="Stock total"
          value={loading ? "…" : `${kpis.stockTotal}`}
          icon={Layers}
          hint={`${stats?.productos.variantes ?? 0} talles cargados`}
          accent="ink"
        />
        <KpiCard
          label="Sin stock"
          value={loading ? "…" : `${kpis.sinStock}`}
          icon={PackageX}
          hint={kpis.sinStock > 0 ? "productos agotados" : "nada agotado"}
          accent={kpis.sinStock > 0 ? "red" : "sea"}
        />
        <KpiCard
          label="Stock crítico"
          value={loading ? "…" : `${kpis.stockBajo}`}
          icon={AlertTriangle}
          hint="con 1 unidad o menos"
          accent={kpis.stockBajo > 0 ? "amber" : "sea"}
        />
        <KpiCard
          label="Facturado"
          value={loading ? "…" : fmtARS(kpis.facturado, { short: true })}
          icon={Banknote}
          hint={`${stats?.pedidos.total ?? 0} pedidos en total`}
          accent="brand"
        />
        <KpiCard
          label="Pedidos pagados"
          value={loading ? "…" : `${kpis.pedidosPagados}`}
          icon={ShoppingCart}
          hint={`${kpis.pedidosPendientes} pendientes de pago`}
          accent="ink"
        />
      </div>

      {/* Charts + panel lateral */}
      <div className="mt-5 grid grid-cols-1 gap-4 xl:grid-cols-3">
        {/* columna izquierda: gráficos sobre datos reales */}
        <div className="min-w-0 space-y-4 xl:col-span-2">
          <ChartCard title="Top vendidos" subtitle="Unidades vendidas por producto — sale de los pedidos reales">
            {topVendidos.length === 0 ? (
              <EmptyState msg="Todavía no hay ventas registradas en la tienda." />
            ) : (
              <ResponsiveContainer width="100%" height={Math.max(200, topVendidos.length * 42)}>
                <BarChart data={topVendidos} layout="vertical" margin={{ left: 8, right: 24 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke={COLORS.ink10} horizontal={false} />
                  <XAxis type="number" tickLine={false} axisLine={false} tick={{ fontSize: 12, fill: COLORS.ink60 }} allowDecimals={false} />
                  <YAxis
                    type="category"
                    dataKey="name"
                    tickLine={false}
                    axisLine={false}
                    tick={{ fontSize: 11, fill: COLORS.ink60 }}
                    width={190}
                    tickFormatter={(v: string) => (v.length > 26 ? v.slice(0, 25) + "…" : v)}
                  />
                  <Tooltip contentStyle={tooltipStyle} cursor={{ fill: "rgba(23,22,26,0.03)" }} />
                  <Bar dataKey="vendidos" name="Vendidos" fill={COLORS.brand} radius={[0, 6, 6, 0]} maxBarSize={22} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </ChartCard>

          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
            <ChartCard title="Stock por marca" subtitle="Unidades disponibles por marca (catálogo real)">
              {tortaMarcas.length === 0 ? (
                <EmptyState msg="Sin productos cargados." />
              ) : (
                <ResponsiveContainer width="100%" height={230}>
                  <PieChart>
                    <Pie
                      data={tortaMarcas}
                      dataKey="value"
                      nameKey="name"
                      innerRadius={48}
                      outerRadius={72}
                      paddingAngle={3}
                      stroke="none"
                    >
                      {tortaMarcas.map((_, i) => (
                        <Cell key={i} fill={SERIE[i % SERIE.length]} />
                      ))}
                    </Pie>
                    <Tooltip contentStyle={tooltipStyle} formatter={(v: number) => `${v} u.`} />
                    <Legend
                      iconType="circle"
                      iconSize={8}
                      formatter={(v) => <span style={{ color: COLORS.ink60, fontSize: 12 }}>{v}</span>}
                    />
                  </PieChart>
                </ResponsiveContainer>
              )}
            </ChartCard>

            <ChartCard title="Catálogo por marca" subtitle="Cantidad de modelos por marca">
              {stockPorMarca.length === 0 ? (
                <EmptyState msg="Sin productos cargados." />
              ) : (
                <ResponsiveContainer width="100%" height={230}>
                  <BarChart data={marcasPorModelos(productos)} barGap={4}>
                    <CartesianGrid strokeDasharray="3 3" stroke={COLORS.ink10} vertical={false} />
                    <XAxis dataKey="name" tickLine={false} axisLine={false} tick={{ fontSize: 11, fill: COLORS.ink60 }} interval={0} angle={-18} height={48} textAnchor="end" />
                    <YAxis tickLine={false} axisLine={false} tick={{ fontSize: 12, fill: COLORS.ink60 }} width={28} allowDecimals={false} />
                    <Tooltip contentStyle={tooltipStyle} cursor={{ fill: "rgba(23,22,26,0.03)" }} />
                    <Bar dataKey="modelos" name="Modelos" fill={COLORS.graphite} radius={[6, 6, 0, 0]} maxBarSize={26} />
                  </BarChart>
                </ResponsiveContainer>
              )}
            </ChartCard>
          </div>
        </div>

        {/* columna derecha: lo operativo de hoy */}
        <div className="min-w-0 space-y-4">
          {/* stock crítico */}
          <div className="pcard">
            <div className="flex items-center justify-between border-b border-graph/[0.07] px-5 py-4">
              <div>
                <h3 className="font-display text-base font-semibold text-graph">Stock crítico</h3>
                <p className="text-xs text-graph-400">Productos con 1 unidad o menos</p>
              </div>
              <Link to="/panel/productos?estado=stock_bajo" className="inline-flex items-center gap-1 text-xs font-semibold text-brand hover:text-brand-600">
                Ver todos <ArrowRight size={13} />
              </Link>
            </div>
            {stockBajo.length === 0 ? (
              <p className="px-5 py-6 text-center text-sm text-graph-400">Todo el catálogo tiene stock.</p>
            ) : (
              <ul className="divide-y divide-graph/[0.07]">
                {stockBajo.slice(0, 7).map((p) => (
                  <li key={p.id}>
                    <Link to={`/panel/productos?q=${encodeURIComponent(p.name)}`} className="flex min-h-[44px] items-center gap-3 px-5 py-3 transition hover:bg-graph/[0.03]">
                      <span className={`grid h-9 w-9 shrink-0 place-items-center rounded-xl ${p.stock === 0 ? "bg-red-500/10 text-red-700" : "bg-amber-500/12 text-amber-700"}`}>
                        <AlertTriangle size={15} />
                      </span>
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-sm font-medium text-graph">{p.name}</span>
                        <span className="block truncate text-xs text-graph-400">{p.brand || "Sin marca"}</span>
                      </span>
                      <Badge tone={p.stock === 0 ? "red" : "amber"}>{p.stock === 0 ? "Sin stock" : `Queda ${p.stock}`}</Badge>
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </div>

          {/* últimos cargados */}
          <div className="pcard">
            <div className="flex items-center justify-between border-b border-graph/[0.07] px-5 py-4">
              <h3 className="font-display text-base font-semibold text-graph">Últimos cargados</h3>
              <Link to="/panel/productos" className="inline-flex items-center gap-1 text-xs font-semibold text-brand hover:text-brand-600">
                Catálogo <ArrowRight size={13} />
              </Link>
            </div>
            <ul className="divide-y divide-graph/[0.07]">
              {ultimosCargados.map((p) => (
                <li key={p.id}>
                  <Link to={`/panel/productos?q=${encodeURIComponent(p.name.es)}`} className="flex items-center gap-3 px-5 py-3 transition hover:bg-graph/[0.03]">
                    <ProductoThumb src={fotoDe(p)} marca={p.brand} alt="" className="h-10 w-10 shrink-0 ring-1 ring-graph/10" />
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-semibold text-graph">{p.name.es}</p>
                      <p className="truncate text-xs text-graph-400">{p.brand || "Sin marca"} · stock {stockDe(p)}</p>
                    </div>
                    <span className="font-display text-sm font-semibold text-graph">{fmtARS(precioDe(p), { short: true })}</span>
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* atajo cargar */}
          <Link to="/panel/cargar" className="pcard pcard-hover flex items-center gap-3 p-5 transition">
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-brand/10 text-brand-700 ring-1 ring-inset ring-brand/20">
              <Package size={18} />
            </span>
            <span className="min-w-0 flex-1">
              <span className="block text-sm font-semibold text-graph">Cargar producto</span>
              <span className="block text-xs text-graph-400">Alta con fotos (Ctrl+V), talles y stock</span>
            </span>
            <ArrowRight size={15} className="text-graph-400" />
          </Link>
        </div>
      </div>
    </div>
  );
}

// Modelos (productos distintos) por marca — para el segundo gráfico.
import type { MiamiProducto } from "../api/miamiApi";
function marcasPorModelos(productos: MiamiProducto[]) {
  const map: Record<string, number> = {};
  productos.forEach((p) => {
    const m = (p.brand || "Sin marca").trim() || "Sin marca";
    map[m] = (map[m] || 0) + 1;
  });
  return Object.entries(map)
    .map(([name, modelos]) => ({ name, modelos }))
    .sort((a, b) => b.modelos - a.modelos)
    .slice(0, 8);
}
