import { useCallback, useEffect, useState } from "react";
import { RefreshCw, ExternalLink, Copy, Check, Download, Landmark, AlertTriangle } from "lucide-react";
import { api, DINERO_EXPORT_URL, type MiamiDinero } from "../api/miamiApi";
import { PageHeader, EmptyState } from "../components/PageShell";
import { cn } from "../ui/cn";

// ============================================================================
//  MI PLATA — la pantalla para reclamarle a la LLC.
//
//  La cuenta de Stripe está a nombre de la LLC que se la abrió: el dinero cae
//  en el banco de ELLOS y después se lo giran a Diego. Reclamar de memoria no
//  sirve. Esta pantalla contesta tres preguntas, en este orden:
//
//    1. ¿Cuánto entró?          -> lo cobrado, bruto
//    2. ¿Cuánto queda?          -> menos la comisión de Stripe = neto
//    3. ¿Stripe ya lo giró?     -> los depósitos al banco, con fecha
//
//  Y todo baja a un CSV con los ids de cobro y los links a los recibos
//  oficiales de Stripe, que es lo que se manda como reclamo.
// ============================================================================

const hoy = () => new Date().toISOString().slice(0, 10);
const primeroDeMes = () => new Date().toISOString().slice(0, 8) + "01";
const primeroMesPasado = () => {
  const d = new Date();
  d.setDate(1);
  d.setMonth(d.getMonth() - 1);
  return d.toISOString().slice(0, 10);
};
const ultimoMesPasado = () => {
  const d = new Date();
  d.setDate(0);
  return d.toISOString().slice(0, 10);
};

/** Plata con su moneda. No usamos fmtARS: acá conviven ARS y la moneda de
 *  liquidación de la cuenta (que puede ser USD). Mezclarlas sería mentir. */
function plata(monto: number | null | undefined, moneda: string | null | undefined) {
  if (monto === null || monto === undefined) return "—";
  const n = monto.toLocaleString("es-AR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  return `${moneda === "USD" ? "US$" : "$"} ${n}${moneda && moneda !== "USD" && moneda !== "ARS" ? " " + moneda : ""}`;
}

const fecha = (iso: string | null) =>
  iso ? new Date(iso).toLocaleDateString("es-AR", { day: "2-digit", month: "2-digit", year: "numeric" }) : "—";

function Copiar({ texto }: { texto: string }) {
  const [listo, setListo] = useState(false);
  return (
    <button
      onClick={() => { navigator.clipboard.writeText(texto); setListo(true); setTimeout(() => setListo(false), 1400); }}
      title="Copiar el ID para buscarlo en Stripe"
      className="inline-flex items-center gap-1 rounded-md px-1.5 py-0.5 text-graph-400 transition hover:bg-graph/[0.06] hover:text-graph"
    >
      {listo ? <Check size={13} className="text-green-700" /> : <Copy size={13} />}
    </button>
  );
}

export default function MiPlata() {
  const [datos, setDatos] = useState<MiamiDinero | null>(null);
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [desde, setDesde] = useState("");
  const [hasta, setHasta] = useState("");

  const cargar = useCallback(async (d: string, h: string) => {
    setCargando(true); setError(null);
    try {
      setDatos(await api.dinero(d || undefined, h || undefined));
    } catch (e: any) {
      setError(e?.message || "No se pudo cargar");
    } finally {
      setCargando(false);
    }
  }, []);

  useEffect(() => { cargar(desde, hasta); }, [cargar, desde, hasta]);

  const r = datos?.resumen;
  const periodos: [string, string, string][] = [
    ["Todo", "", ""],
    ["Este mes", primeroDeMes(), hoy()],
    ["Mes pasado", primeroMesPasado(), ultimoMesPasado()],
  ];
  const activo = (d: string, h: string) => desde === d && hasta === h;

  if (error && !datos) return <div><PageHeader title="Mi plata" /><EmptyState msg={error} /></div>;

  return (
    <div>
      <PageHeader
        title="Mi plata"
        subtitle="Cuánto entró, cuánto queda neto y qué ya te giró Stripe. Con las pruebas para reclamar."
        actions={
          <button
            onClick={() => cargar(desde, hasta)}
            className="inline-flex h-10 items-center gap-2 rounded-xl border border-graph/15 px-4 text-sm font-medium text-graph-500 transition hover:text-graph"
          >
            <RefreshCw size={15} className={cargando ? "animate-spin" : ""} /> Actualizar
          </button>
        }
      />

      {/* --- período --- */}
      <div className="mb-5 flex flex-wrap items-center gap-2">
        {periodos.map(([label, d, h]) => (
          <button
            key={label}
            onClick={() => { setDesde(d); setHasta(h); }}
            className={cn(
              "h-9 rounded-full px-4 text-sm font-medium transition",
              activo(d, h) ? "bg-graph text-white" : "border border-graph/15 text-graph-500 hover:text-graph",
            )}
          >
            {label}
          </button>
        ))}
        <span className="ml-1 flex items-center gap-2 text-sm text-graph-400">
          <input type="date" value={desde} onChange={(e) => setDesde(e.target.value)}
                 className="h-9 rounded-xl border border-graph/15 px-3 text-sm text-graph" />
          <span>a</span>
          <input type="date" value={hasta} onChange={(e) => setHasta(e.target.value)}
                 className="h-9 rounded-xl border border-graph/15 px-3 text-sm text-graph" />
        </span>
      </div>

      {/* --- los tres números que importan --- */}
      <div className="grid gap-3 md:grid-cols-3 md:gap-4">
        <div className="rounded-2xl border border-graph/10 bg-white p-5">
          <p className="text-[11px] font-semibold uppercase tracking-wide text-graph-400">Entró</p>
          <p className="mt-1 font-display text-3xl font-bold text-graph">
            {cargando ? "…" : plata(r?.bruto, r?.moneda)}
          </p>
          <p className="mt-1 text-xs text-graph-400">{r?.cantidad ?? 0} cobros acreditados</p>
        </div>
        <div className="rounded-2xl border border-graph/10 bg-white p-5">
          <p className="text-[11px] font-semibold uppercase tracking-wide text-graph-400">Se llevó Stripe</p>
          <p className="mt-1 font-display text-3xl font-bold text-graph-500">
            {cargando ? "…" : plata(r?.comision, r?.moneda_neto)}
          </p>
          <p className="mt-1 text-xs text-graph-400">comisión de la pasarela</p>
        </div>
        <div className="rounded-2xl border-2 border-green-600/25 bg-green-500/[0.06] p-5">
          <p className="text-[11px] font-semibold uppercase tracking-wide text-green-800">Te queda neto</p>
          <p className="mt-1 font-display text-3xl font-bold text-green-900">
            {cargando ? "…" : plata(r?.neto, r?.moneda_neto)}
          </p>
          <p className="mt-1 text-xs text-green-800/70">esto es lo que se reclama</p>
        </div>
      </div>

      {/* --- aviso: faltan datos de liquidación --- */}
      {!!r?.sin_liquidacion && (
        <div className="mt-4 flex items-start gap-3 rounded-xl border border-amber-500/30 bg-amber-500/[0.08] px-4 py-3">
          <AlertTriangle size={17} className="mt-0.5 shrink-0 text-amber-700" />
          <p className="text-sm text-amber-900">
            <strong>{r.sin_liquidacion} {r.sin_liquidacion === 1 ? "cobro no tiene" : "cobros no tienen"} el detalle de comisión.</strong>{" "}
            El neto de arriba está incompleto. Andá a <strong>Pedidos → Reconciliar</strong> y volvé:
            el sistema se lo pide a Stripe y completa los números.
          </p>
        </div>
      )}

      {/* --- lo que Stripe YA depositó en el banco de la LLC --- */}
      <div className="mt-6 rounded-2xl border border-graph/10 bg-white p-5">
        <div className="flex items-center gap-2">
          <Landmark size={17} className="text-graph-400" />
          <h2 className="font-display text-base font-bold text-graph">Lo que Stripe ya depositó en el banco</h2>
        </div>
        <p className="mt-1 text-sm text-graph-400">
          Esta es la prueba más fuerte: no es lo que decimos nosotros, es lo que Stripe informa que giró.
          Si acá figura depositado y a vos no te llegó, es exactamente lo que hay que reclamarle a la LLC.
        </p>

        {datos?.error_stripe ? (
          <p className="mt-4 rounded-xl bg-graph/[0.04] px-4 py-3 text-sm text-graph-500">
            No se pudo consultar Stripe en este momento. Los cobros de abajo salen de la base y siguen siendo válidos.
          </p>
        ) : !datos?.giros_al_banco?.length ? (
          <p className="mt-4 rounded-xl bg-graph/[0.04] px-4 py-3 text-sm text-graph-500">
            Stripe todavía no hizo ningún depósito a la cuenta bancaria.
          </p>
        ) : (
          <div className="mt-4 overflow-x-auto">
            <table className="w-full min-w-[420px] text-sm">
              <thead>
                <tr className="text-left text-[11px] uppercase tracking-wide text-graph-400">
                  <th className="pb-2 font-semibold">Fecha</th>
                  <th className="pb-2 font-semibold">Monto</th>
                  <th className="pb-2 font-semibold">Estado</th>
                  <th className="pb-2 font-semibold">Referencia</th>
                </tr>
              </thead>
              <tbody>
                {datos.giros_al_banco.map((g) => (
                  <tr key={g.id} className="border-t border-graph/[0.07]">
                    <td className="py-2.5 text-graph">{fecha(g.llega_el)}</td>
                    <td className="py-2.5 font-semibold text-graph">{plata(g.monto, g.moneda)}</td>
                    <td className="py-2.5">
                      <span className={cn(
                        "rounded-md px-2 py-0.5 text-xs font-medium",
                        g.estado === "paid" ? "bg-green-500/10 text-green-800"
                          : g.estado === "failed" || g.estado === "canceled" ? "bg-red-500/10 text-red-800"
                          : "bg-amber-500/10 text-amber-900",
                      )}>
                        {g.estado === "paid" ? "Depositado" : g.estado === "in_transit" ? "En camino"
                          : g.estado === "pending" ? "Pendiente" : g.estado}
                      </span>
                    </td>
                    <td className="py-2.5">
                      <span className="font-mono text-[11px] text-graph-400">{g.id}</span>
                      <Copiar texto={g.id} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {!!datos?.saldo_stripe?.disponible?.length && (
          <p className="mt-4 text-sm text-graph-500">
            Esperando en Stripe:{" "}
            <strong className="text-graph">
              {datos.saldo_stripe.disponible.map((x) => plata(x.monto, x.moneda)).join(" · ")}
            </strong>
            {!!datos.saldo_stripe.pendiente?.length && (
              <> · en camino: {datos.saldo_stripe.pendiente.map((x) => plata(x.monto, x.moneda)).join(" · ")}</>
            )}
          </p>
        )}
      </div>

      {/* --- cobro por cobro, con su prueba --- */}
      <div className="mt-6 rounded-2xl border border-graph/10 bg-white p-5">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h2 className="font-display text-base font-bold text-graph">Cobro por cobro</h2>
            <p className="mt-1 text-sm text-graph-400">Cada uno con su recibo oficial de Stripe.</p>
          </div>
          <a
            href={`${DINERO_EXPORT_URL}?desde=${desde}&hasta=${hasta}`}
            className="inline-flex h-10 items-center gap-2 rounded-xl bg-graph px-4 text-sm font-semibold text-white transition hover:opacity-90"
          >
            <Download size={15} /> Planilla para la LLC
          </a>
        </div>

        {cargando ? (
          <p className="mt-5 text-sm text-graph-400">Cargando…</p>
        ) : !datos?.cobros?.length ? (
          <p className="mt-5 rounded-xl bg-graph/[0.04] px-4 py-3 text-sm text-graph-500">
            No hay cobros acreditados en este período.
          </p>
        ) : (
          <div className="mt-4 overflow-x-auto">
            <table className="w-full min-w-[720px] text-sm">
              <thead>
                <tr className="text-left text-[11px] uppercase tracking-wide text-graph-400">
                  <th className="pb-2 font-semibold">Fecha</th>
                  <th className="pb-2 font-semibold">Pedido</th>
                  <th className="pb-2 font-semibold">Cliente</th>
                  <th className="pb-2 font-semibold">Medio</th>
                  <th className="pb-2 text-right font-semibold">Entró</th>
                  <th className="pb-2 text-right font-semibold">Neto</th>
                  <th className="pb-2 font-semibold">Prueba</th>
                </tr>
              </thead>
              <tbody>
                {datos.cobros.map((c) => (
                  <tr key={c.order_id} className="border-t border-graph/[0.07]">
                    <td className="py-2.5 whitespace-nowrap text-graph">{fecha(c.fecha)}</td>
                    <td className="py-2.5 font-display font-bold text-graph">#{c.pedido}</td>
                    <td className="py-2.5 text-graph-600">
                      <span className="block max-w-[180px] truncate">{c.cliente || "—"}</span>
                    </td>
                    <td className="py-2.5 whitespace-nowrap text-graph-500">{c.medio || "—"}</td>
                    <td className="py-2.5 whitespace-nowrap text-right font-semibold text-graph">
                      {plata(c.bruto, c.moneda)}
                    </td>
                    <td className="py-2.5 whitespace-nowrap text-right font-semibold text-green-800">
                      {plata(c.neto, c.moneda_neto)}
                    </td>
                    <td className="py-2.5 whitespace-nowrap">
                      {c.recibo_url ? (
                        <a href={c.recibo_url} target="_blank" rel="noreferrer"
                           className="inline-flex items-center gap-1 text-xs font-semibold text-graph underline underline-offset-2">
                          Recibo <ExternalLink size={12} />
                        </a>
                      ) : (
                        <span className="text-xs text-graph-400">sin recibo</span>
                      )}
                      {c.cobro_id && <Copiar texto={c.cobro_id} />}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <p className="mt-5 text-xs leading-relaxed text-graph-400">
        Los importes de <strong>neto</strong> vienen de Stripe, en la moneda en que liquida la cuenta.
        El <strong>ID de cobro</strong> se pega tal cual en el buscador de Stripe y muestra la operación completa.
      </p>
    </div>
  );
}
