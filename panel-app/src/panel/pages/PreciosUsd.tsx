import { useEffect, useMemo, useState } from "react";
import { Loader2, RefreshCw, DollarSign, Calculator, Save } from "lucide-react";
import { api, ApiError, type MiamiProducto } from "../api/miamiApi";
import { fmtARS } from "@/lib/format";
import { useData } from "@/lib/DataProvider";
import { PageHeader, EmptyState } from "../components/PageShell";
import { SearchInput } from "../components/Controls";
import { useToast } from "../components/Toast";

// ============================================================================
//  PRECIOS USD — el costo real se maneja en dólares; el cliente paga en pesos.
//  Flujo (igual que el panel viejo, con el fix del rate en la DB):
//    1. Cotización → POST /usd_prices {rate}  (queda en la tabla settings)
//    2. "Inicializar" → POST /usd_prices/from_current (ARS ÷ rate, primera vez)
//    3. Editar USD por producto → se guardan junto con "Recalcular"
//    4. "Recalcular" → POST /usd_prices {prices} + POST sync (ARS = USD × rate)
// ============================================================================

export default function PreciosUsd() {
  const { push } = useToast();
  const { productos, recargar } = useData();
  const [rate, setRate] = useState<string>("");
  const [rateGuardado, setRateGuardado] = useState<number | null>(null);
  const [usd, setUsd] = useState<Record<string, string>>({});
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [q, setQ] = useState("");
  const [accion, setAccion] = useState<string>("");
  const [busy, setBusy] = useState(false);

  const cargar = async () => {
    setCargando(true);
    try {
      setError(null);
      const data = await api.usdPrices();
      setRate(String(data.rate));
      setRateGuardado(data.rate);
      const m: Record<string, string> = {};
      Object.entries(data.prices).forEach(([pid, v]) => { m[pid] = String(v); });
      setUsd(m);
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "No se pudo cargar");
    } finally {
      setCargando(false);
    }
  };
  useEffect(() => { void cargar(); }, []);

  const rateNum = parseFloat(rate) || 0;

  const filtrados = useMemo(() => {
    const t = q.toLowerCase();
    return productos.filter((p) => !q || `${p.name.es} ${p.brand || ""}`.toLowerCase().includes(t));
  }, [productos, q]);

  const guardarRate = async () => {
    const r = parseFloat(rate);
    if (!r || r <= 0) { push("Cotización inválida", "error"); return; }
    setBusy(true);
    try {
      // A /usd_prices, NO a /bot_config: la cotización tiene que quedar en la
      // base, que es de donde la lee el recálculo de precios.
      await api.usdPricesSave({ rate: r });
      setRateGuardado(r);
      push(`Cotización guardada: $${r.toLocaleString("es-AR")}`, "success");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo guardar", "error");
    } finally {
      setBusy(false);
    }
  };

  const inicializar = async () => {
    if (!window.confirm("Esto lee los precios en pesos actuales y los divide por la cotización para guardar el USD equivalente. ¿Seguir?")) return;
    setBusy(true);
    setAccion("Inicializando…");
    try {
      const r = await api.usdSeedFromCurrent();
      setAccion(`Listo: ${r.count} productos con USD asignado (cotización $${r.rate.toLocaleString("es-AR")}).`);
      push("USD inicializados desde los ARS actuales", "success");
      void cargar();
    } catch (e) {
      const msg = e instanceof ApiError ? e.message : "No se pudo inicializar";
      setAccion(`Error: ${msg}`);
      push(msg, "error");
    } finally {
      setBusy(false);
    }
  };

  const recalcular = async () => {
    const prices: Record<string, number> = {};
    Object.entries(usd).forEach(([pid, v]) => {
      const n = parseFloat(v);
      if (n > 0) prices[pid] = n;
    });
    if (!Object.keys(prices).length) { push("No hay precios USD cargados para recalcular", "error"); return; }
    if (!window.confirm(`Esto actualiza los precios ARS de ${Object.keys(prices).length} productos en la tienda (USD × cotización). ¿Confirmar?`)) return;
    setBusy(true);
    setAccion("Recalculando precios…");
    try {
      await api.usdPricesSave({ prices });          // primero los USD editados
      const r = await api.usdRecalcularArs();       // después ARS = USD × rate
      setAccion(`Listo: ${r.updated_products} productos · ${r.updated_variants} variantes actualizadas (cotización $${r.rate.toLocaleString("es-AR")}).`);
      push("Precios ARS actualizados en la tienda", "success");
      void recargar();                              // el catálogo cambió
    } catch (e) {
      const msg = e instanceof ApiError ? e.message : "No se pudo recalcular";
      setAccion(`Error: ${msg}`);
      push(msg, "error");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <PageHeader
        title="Precios en USD"
        subtitle="El costo se maneja en dólares; la tienda cobra en pesos. Cambió el dólar → ajustás la cotización y recalculás todo con un click."
        actions={
          <button onClick={() => void cargar()} className="inline-flex h-10 items-center gap-2 rounded-xl border border-graph/15 px-4 text-sm font-medium text-graph-500 transition hover:text-graph">
            <RefreshCw size={15} /> Actualizar
          </button>
        }
      />

      {cargando ? (
        <div className="grid place-items-center py-24 text-graph-400"><Loader2 className="animate-spin" /></div>
      ) : error ? (
        <EmptyState msg={error} />
      ) : (
        <>
          <div className="grid gap-4 lg:grid-cols-2">
            {/* cotización */}
            <div className="pcard p-5">
              <h3 className="mb-3 flex items-center gap-2 font-display text-base font-semibold text-graph">
                <DollarSign size={16} className="text-brand" /> Cotización USD → ARS
              </h3>
              <div className="flex items-end gap-3">
                <label className="block flex-1">
                  <span className="mb-1 block text-[11px] font-medium uppercase tracking-wide text-graph-400">Cotización actual</span>
                  <input value={rate} onChange={(e) => setRate(e.target.value.replace(/[^\d.]/g, ""))} inputMode="decimal"
                    className="h-11 w-full rounded-xl border border-graph/15 bg-paper-100 px-3 font-display text-lg font-semibold text-graph outline-none transition focus:border-brand/60 focus:ring-2 focus:ring-brand/15" />
                </label>
                <button onClick={guardarRate} disabled={busy} className="inline-flex h-11 items-center gap-2 rounded-xl bg-brand px-4 text-sm font-semibold text-white transition hover:bg-brand-600 disabled:opacity-50">
                  <Save size={15} /> Guardar
                </button>
              </div>
              <p className="mt-2 text-xs text-graph-400">Última guardada: <b className="text-graph-500">{rateGuardado ? `$ ${rateGuardado.toLocaleString("es-AR")}` : "—"}</b> · vive en la base, es la que usa el recálculo.</p>
            </div>

            {/* acciones */}
            <div className="pcard p-5">
              <h3 className="mb-3 flex items-center gap-2 font-display text-base font-semibold text-graph">
                <Calculator size={16} className="text-brand" /> Acciones de precios
              </h3>
              <div className="flex flex-wrap gap-2">
                <button onClick={inicializar} disabled={busy} className="inline-flex h-10 items-center rounded-xl border border-graph/15 bg-graph/[0.03] px-4 text-sm font-semibold text-graph transition hover:border-graph/30 disabled:opacity-50">
                  Inicializar USD desde los precios actuales
                </button>
                <button onClick={recalcular} disabled={busy} className="inline-flex h-10 items-center gap-2 rounded-xl bg-brand px-4 text-sm font-semibold text-white transition hover:bg-brand-600 disabled:opacity-50">
                  {busy ? <Loader2 size={15} className="animate-spin" /> : null} Recalcular ARS = USD × cotización
                </button>
              </div>
              <p className="mt-2 text-xs leading-relaxed text-graph-400">
                <b>Inicializar</b>: primera vez — toma los ARS actuales y guarda el USD equivalente.<br />
                <b>Recalcular</b>: guarda los USD editados abajo y actualiza los ARS de TODAS las variantes.
              </p>
              {accion && <p className="mt-2 rounded-lg bg-graph/[0.03] px-3 py-2 text-xs font-medium text-graph-500">{accion}</p>}
            </div>
          </div>

          {/* tabla */}
          <div className="pcard mt-4 overflow-hidden">
            <div className="flex flex-wrap items-center justify-between gap-3 border-b border-graph/[0.07] px-5 py-4">
              <div>
                <h3 className="font-display text-base font-semibold text-graph">USD por producto</h3>
                <p className="text-xs text-graph-400">Editá el USD y después tocá "Recalcular" arriba. {Object.keys(usd).length} con USD cargado.</p>
              </div>
              <SearchInput value={q} onChange={setQ} placeholder="Filtrar…" className="w-64 max-w-full" />
            </div>
            <div className="max-h-[560px] overflow-auto">
              <table className="w-full min-w-[640px] text-sm">
                <thead className="sticky top-0 bg-paper-100">
                  <tr className="border-b border-graph/[0.07] text-left text-xs font-semibold uppercase tracking-wide text-graph-400">
                    <th className="px-5 py-3">Producto</th>
                    <th className="px-4 py-3">Marca</th>
                    <th className="px-4 py-3 text-right">USD</th>
                    <th className="px-5 py-3 text-right">ARS calculado</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-graph/[0.06]">
                  {filtrados.map((p: MiamiProducto) => {
                    const pid = String(p.id);
                    const val = usd[pid] ?? "";
                    const n = parseFloat(val) || 0;
                    return (
                      <tr key={p.id} className="transition hover:bg-graph/[0.02]">
                        <td className="px-5 py-2.5 font-medium text-graph">{p.name.es}</td>
                        <td className="px-4 py-2.5 text-graph-400">{p.brand || "—"}</td>
                        <td className="px-4 py-2.5 text-right">
                          <input
                            value={val}
                            onChange={(e) => setUsd((s) => ({ ...s, [pid]: e.target.value.replace(/[^\d.]/g, "") }))}
                            inputMode="decimal"
                            placeholder="—"
                            className="h-9 w-24 rounded-lg border border-graph/15 bg-paper-100 px-2 text-right text-sm text-graph outline-none transition focus:border-brand/60 focus:ring-2 focus:ring-brand/15"
                          />
                        </td>
                        <td className="px-5 py-2.5 text-right text-graph-500">{n > 0 && rateNum > 0 ? fmtARS(Math.round(n * rateNum)) : "—"}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
              {filtrados.length === 0 && <p className="px-5 py-8 text-center text-sm text-graph-400">Sin productos que coincidan.</p>}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
