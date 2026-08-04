import { useEffect, useState } from "react";
import { Loader2, Save, MessageCircle, Bot } from "lucide-react";
import { api, ApiError, type WaTemplates, type BotConfig } from "../api/miamiApi";
import { PageHeader, EmptyState } from "../components/PageShell";
import { useToast } from "../components/Toast";

// ============================================================================
//  WHATSAPP — plantillas que usa el botón "WhatsApp" de Pedidos, con
//  {name} / {order} / {eta} / {carrier} / {tracking} como placeholders.
//  Abajo, la info que responde el bot (envíos / pagos / cambios): bot_config.
// ============================================================================

const WA_LABELS: Record<string, string> = {
  coordinar_caba: "Coordinar entrega CABA / GBA",
  salida_camino: 'Aviso "Salí en camino"',
  entregado: "Confirmación de entrega",
  post_venta: "Follow-up post-venta",
  tracking_correo: "Tracking del correo",
};

export default function WhatsappPage() {
  const { push } = useToast();
  const [tpls, setTpls] = useState<WaTemplates | null>(null);
  const [cfg, setCfg] = useState<BotConfig | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [guardando, setGuardando] = useState(false);
  const [guardandoCfg, setGuardandoCfg] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const [t, c] = await Promise.all([api.waTemplates(), api.botConfig()]);
        setTpls(t);
        setCfg(c);
      } catch (e) {
        setError(e instanceof ApiError ? e.message : "No se pudo cargar");
      }
    })();
  }, []);

  const guardarTpls = async () => {
    if (!tpls) return;
    setGuardando(true);
    try {
      await api.waTemplatesSave(tpls);
      push("Plantillas guardadas", "success");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo guardar", "error");
    } finally {
      setGuardando(false);
    }
  };

  const guardarCfg = async () => {
    if (!cfg) return;
    setGuardandoCfg(true);
    try {
      await api.botConfigSave({
        shipping_info: cfg.shipping_info,
        payment_info: cfg.payment_info,
        exchange_info: cfg.exchange_info,
      });
      push("Info del bot guardada", "success");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo guardar", "error");
    } finally {
      setGuardandoCfg(false);
    }
  };

  if (error) return <div><PageHeader title="WhatsApp" /><EmptyState msg={error} /></div>;
  if (!tpls || !cfg) return <div className="grid place-items-center py-24 text-graph-400"><Loader2 className="animate-spin" /></div>;

  const areaCls = "w-full rounded-xl border border-graph/10 bg-graph/[0.04] p-3 font-mono text-[13px] leading-relaxed text-graph outline-none transition placeholder:text-graph-400 focus:border-brand/60";

  return (
    <div>
      <PageHeader
        title="WhatsApp"
        subtitle="Plantillas del botón WhatsApp de Pedidos. Placeholders: {name}, {order}, {eta}, {carrier}, {tracking}."
        actions={
          <button onClick={guardarTpls} disabled={guardando} className="inline-flex h-10 items-center gap-2 rounded-xl bg-brand px-5 text-sm font-semibold text-white transition hover:bg-brand-600 disabled:opacity-50">
            {guardando ? <Loader2 size={15} className="animate-spin" /> : <Save size={15} />} Guardar plantillas
          </button>
        }
      />

      <div className="grid gap-4 lg:grid-cols-2">
        {Object.entries(tpls).map(([key, val]) => (
          <div key={key} className="pcard p-5">
            <label className="block">
              <span className="mb-2 flex items-center gap-2 text-sm font-semibold text-graph">
                <MessageCircle size={14} className="text-brand" /> {WA_LABELS[key] || key}
              </span>
              <textarea
                value={val}
                onChange={(e) => setTpls((s) => (s ? { ...s, [key]: e.target.value } : s))}
                rows={5}
                className={areaCls}
              />
            </label>
          </div>
        ))}
      </div>

      {/* ===== Info del bot ===== */}
      <div className="mt-8">
        <div className="mb-4 flex flex-wrap items-end justify-between gap-3">
          <div>
            <h2 className="flex items-center gap-2 font-display text-lg font-semibold text-graph"><Bot size={18} className="text-brand" /> Info del bot</h2>
            <p className="mt-1 text-sm text-graph-400">Lo que el bot responde sobre envíos, pagos y cambios. La cotización NO va acá: se maneja en Precios USD.</p>
          </div>
          <button onClick={guardarCfg} disabled={guardandoCfg} className="inline-flex h-10 items-center gap-2 rounded-xl border border-graph/15 bg-graph/[0.03] px-4 text-sm font-semibold text-graph transition hover:border-graph/30 disabled:opacity-50">
            {guardandoCfg ? <Loader2 size={15} className="animate-spin" /> : <Save size={15} />} Guardar info del bot
          </button>
        </div>
        <div className="grid gap-4 lg:grid-cols-3">
          {([
            ["shipping_info", "Envíos"],
            ["payment_info", "Pagos"],
            ["exchange_info", "Cambios y devoluciones"],
          ] as const).map(([key, label]) => (
            <div key={key} className="pcard p-5">
              <label className="block">
                <span className="mb-2 block text-sm font-semibold text-graph">{label}</span>
                <textarea
                  value={String(cfg[key] ?? "")}
                  onChange={(e) => setCfg((s) => (s ? { ...s, [key]: e.target.value } : s))}
                  rows={6}
                  placeholder="Todavía sin texto cargado."
                  className={areaCls}
                />
              </label>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
