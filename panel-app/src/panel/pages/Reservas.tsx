import { useEffect, useState } from "react";
import { Loader2, RefreshCw, MessageCircle, Trash2 } from "lucide-react";
import { api, ApiError, ESTADOS_RESERVA, type MiamiReserva } from "../api/miamiApi";
import { PageHeader, EmptyState } from "../components/PageShell";
import Badge from "../components/Badge";
import { useToast } from "../components/Toast";
import type { Tone } from "../ui/estados";
import { cn } from "../ui/cn";

// ============================================================================
//  RESERVAS — clientes esperando un producto "a pedido" (/panel/api/reservas).
//  El backend ya las ordena: pendientes primero, después avisadas, entregadas.
// ============================================================================

const rotulo: Record<string, { label: string; tone: Tone }> = {
  pendiente: { label: "Pendiente", tone: "amber" },
  avisado: { label: "Avisado", tone: "blue" },
  entregado: { label: "Entregado", tone: "green" },
  cancelado: { label: "Cancelada", tone: "neutral" },
};

export default function Reservas() {
  const { push } = useToast();
  const [reservas, setReservas] = useState<MiamiReserva[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  const cargar = async () => {
    try {
      setError(null);
      setReservas(await api.reservas());
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "No se pudieron cargar las reservas");
      setReservas([]);
    }
  };
  useEffect(() => { void cargar(); }, []);

  const cambiarEstado = async (r: MiamiReserva, status: string) => {
    try {
      const nueva = await api.setEstadoReserva(r.id, status);
      setReservas((prev) => prev?.map((x) => (x.id === r.id ? nueva : x)) ?? null);
      push("Estado actualizado", "success");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo cambiar el estado", "error");
    }
  };

  const eliminar = async (r: MiamiReserva) => {
    if (!window.confirm(`¿Eliminar la reserva de ${r.customer_name}? No se puede deshacer.`)) return;
    try {
      await api.borrarReserva(r.id);
      setReservas((prev) => prev?.filter((x) => x.id !== r.id) ?? null);
      push("Reserva eliminada", "info");
    } catch (e) {
      push(e instanceof ApiError ? e.message : "No se pudo eliminar", "error");
    }
  };

  const pendientes = reservas?.filter((r) => r.status === "pendiente").length ?? 0;

  return (
    <div>
      <PageHeader
        title="Reservas"
        subtitle={reservas ? `${reservas.length} reservas · ${pendientes} pendientes` : "Cargando…"}
        actions={
          <button onClick={() => { setReservas(null); void cargar(); }} className="inline-flex h-10 items-center gap-2 rounded-xl border border-graph/15 px-4 text-sm font-medium text-graph-500 transition hover:text-graph">
            <RefreshCw size={15} /> Actualizar
          </button>
        }
      />

      {reservas === null ? (
        <div className="grid place-items-center py-24 text-graph-400"><Loader2 className="animate-spin" /></div>
      ) : error ? (
        <EmptyState msg={error} />
      ) : reservas.length === 0 ? (
        <EmptyState msg='Todavía no hay reservas. Se crean desde "A pedido", tocando un producto → Reservar.' />
      ) : (
        <div className="space-y-2.5">
          {reservas.map((r) => {
            const b = rotulo[r.status] || { label: r.status, tone: "neutral" as Tone };
            const digits = (r.customer_phone || "").replace(/[^0-9]/g, "");
            return (
              <div key={r.id} className={cn("pcard flex flex-wrap items-start gap-3 p-4", r.status === "pendiente" && "ring-1 ring-amber-500/25")}>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold text-graph">
                    {r.product_name}
                    {r.talle && <span className="ml-1.5 rounded bg-graph/[0.06] px-1.5 py-0.5 text-[10px] font-bold text-graph-500">Talle {r.talle}</span>}
                  </p>
                  <p className="mt-0.5 text-sm text-graph-500">{r.customer_name}{r.customer_phone ? ` · ${r.customer_phone}` : ""}</p>
                  {r.notes && <p className="mt-1 rounded-lg bg-graph/[0.03] px-2.5 py-1.5 text-xs text-graph-500">{r.notes}</p>}
                  <p className="mt-1 text-[11px] text-graph-400">Reservado el {r.created_at ? new Date(r.created_at).toLocaleDateString("es-AR") : "—"}</p>
                </div>

                <div className="flex flex-col items-end gap-2">
                  <div className="flex flex-wrap items-center gap-1.5">
                    {ESTADOS_RESERVA.map((st) =>
                      st === r.status ? (
                        <Badge key={st} tone={b.tone} dot>{rotulo[st]?.label || st}</Badge>
                      ) : (
                        <button
                          key={st}
                          onClick={() => cambiarEstado(r, st)}
                          className="rounded-lg border border-graph/15 px-2.5 py-1 text-[11px] font-medium text-graph-400 transition hover:border-brand/50 hover:text-brand"
                        >
                          {rotulo[st]?.label || st}
                        </button>
                      )
                    )}
                  </div>
                  <div className="flex items-center gap-1.5">
                    {digits && (
                      <a href={`https://wa.me/${digits}`} target="_blank" rel="noreferrer"
                        className="inline-flex h-8 items-center gap-1.5 rounded-lg bg-sea/10 px-2.5 text-[11px] font-semibold text-sea ring-1 ring-inset ring-sea/25 transition hover:bg-sea hover:text-white">
                        <MessageCircle size={13} /> WhatsApp
                      </a>
                    )}
                    <button onClick={() => eliminar(r)} className="inline-flex h-8 items-center gap-1.5 rounded-lg px-2.5 text-[11px] font-semibold text-graph-400 transition hover:bg-red-500/10 hover:text-red-600">
                      <Trash2 size={13} /> Eliminar
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
