import { MARCA } from "@/marca";
import { NavLink, useNavigate } from "react-router-dom";
import {
  LayoutDashboard,
  Package,
  PackagePlus,
  PackageSearch,
  Bookmark,
  Receipt,
  ShoppingBag,
  BarChart3,
  CircleDollarSign,
  MessageCircle,
  Zap,
  Gem,
  LogOut,
  ExternalLink,
  ChevronsLeft,
} from "lucide-react";
import { useData } from "@/lib/DataProvider";
import { cn } from "../ui/cn";
import { useProfiles, canAccess } from "../profiles";
import { usePanelAuth } from "../auth";

export default function Sidebar({
  open,
  onClose,
  collapsed,
  onToggleCollapse,
}: {
  open: boolean;
  onClose: () => void;
  collapsed: boolean;
  onToggleCollapse: () => void;
}) {
  const { kpis, store } = useData();
  const { activo } = useProfiles();
  const { signOut } = usePanelAuth();
  const navigate = useNavigate();
  const cerrarSesion = async () => { await signOut(); navigate("/ingresar"); };
  // Paridad completa con el Stock Manager viejo — todas las secciones, todas reales.
  const nav = [
    { to: "/panel", end: true, key: "inicio", label: "Inicio", icon: LayoutDashboard },
    { to: "/panel/venta", key: "venta", label: "Vender", icon: ShoppingBag },
    { to: "/panel/productos", key: "productos", label: "Productos", icon: Package, badge: kpis.sinStock },
    { to: "/panel/cargar", key: "cargar", label: "Cargar producto", icon: PackagePlus },
    { to: "/panel/apedido", key: "apedido", label: "A pedido", icon: PackageSearch },
    { to: "/panel/reservas", key: "reservas", label: "Reservas", icon: Bookmark },
    { to: "/panel/pedidos", key: "pedidos", label: "Pedidos", icon: Receipt, badge: kpis.pedidosPendientes },
    { to: "/panel/estadisticas", key: "estadisticas", label: "Estadísticas", icon: BarChart3 },
    { to: "/panel/precios-usd", key: "precios-usd", label: "Precios USD", icon: CircleDollarSign },
    { to: "/panel/whatsapp", key: "whatsapp", label: "WhatsApp", icon: MessageCircle },
    { to: "/panel/acciones", key: "acciones", label: "Acciones", icon: Zap },
  ].filter((i) => canAccess(activo, i.key));
  // En desktop colapsado, el texto se oculta (lg:hidden) pero en el drawer mobile siempre se ve.
  const hideOnCollapse = collapsed ? "lg:hidden" : "";

  return (
    <>
      {/* overlay mobile */}
      <div
        className={cn(
          "fixed inset-0 z-30 bg-graph/30 backdrop-blur-sm transition-opacity lg:hidden",
          open ? "opacity-100" : "pointer-events-none opacity-0"
        )}
        onClick={onClose}
      />
      {/* sidebar glass flotante (Apple) */}
      <aside
        className={cn(
          "glass-strong fixed inset-y-3 left-3 z-40 flex flex-col rounded-[26px] text-graph transition-[transform,width] duration-300 ease-out lg:translate-x-0",
          "shadow-[0_24px_60px_-30px_rgba(23,22,26,0.40)]",
          collapsed ? "w-[248px] lg:w-[76px]" : "w-[248px]",
          open ? "translate-x-0" : "-translate-x-[112%]"
        )}
      >
        {/* toggle colapsar (solo desktop, sobre el borde) */}
        <button
          onClick={onToggleCollapse}
          title={collapsed ? "Expandir menú" : "Colapsar menú"}
          className="absolute -right-3 top-[72px] z-50 hidden h-6 w-6 place-items-center rounded-full border border-graph/10 bg-paper-100 text-graph-500 shadow-md transition hover:text-brand lg:grid"
        >
          <ChevronsLeft size={14} className={cn("transition-transform", collapsed && "rotate-180")} />
        </button>

        {/* logo */}
        <div className={cn("flex items-center gap-3 px-5 py-5", collapsed && "lg:justify-center lg:px-0")}>
          <div className="grid h-10 w-10 shrink-0 place-items-center rounded-[14px] bg-paper-100 p-1 shadow-[0_8px_20px_-8px_rgba(185,155,99,0.55)] ring-1 ring-brand/15">
            <img src={MARCA.logo} alt={MARCA.nombre} className="h-full w-full object-contain" />
          </div>
          <div className={cn("leading-tight", hideOnCollapse)}>
            <p className="font-display text-base font-semibold tracking-tight text-graph">MIAMI <span className="text-brand">IMPORT</span></p>
            <p className="text-[10px] uppercase tracking-widest2 text-brand">Stock Manager</p>
          </div>
        </div>

        {/* nav */}
        <nav className="flex-1 space-y-0.5 overflow-y-auto px-3 py-2">
          {nav.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.end}
                onClick={onClose}
                title={collapsed ? item.label : undefined}
                className={({ isActive }) =>
                  cn(
                    "group relative flex items-center gap-3 rounded-2xl px-3 py-2.5 text-sm font-medium transition-all duration-200 ease-out",
                    collapsed && "lg:justify-center lg:px-0",
                    isActive
                      ? "bg-brand text-white shadow-[0_10px_24px_-10px_rgba(185,155,99,0.65)]"
                      : "text-graph-500 hover:bg-graph/[0.05] hover:text-graph"
                  )
                }
              >
                {({ isActive }) => (
                  <>
                    <Icon size={18} strokeWidth={2} className={isActive ? "text-white" : "text-graph-400 group-hover:text-graph"} />
                    <span className={cn("flex-1", hideOnCollapse)}>{item.label}</span>
                    {item.badge ? (
                      <>
                        <span
                          className={cn(
                            "min-w-[20px] rounded-full px-1.5 py-0.5 text-center text-[11px] font-bold",
                            hideOnCollapse,
                            isActive ? "bg-white/25 text-white" : "bg-brand text-white"
                          )}
                        >
                          {item.badge}
                        </span>
                        {/* puntito en modo colapsado */}
                        <span className={cn("absolute right-2 top-2 hidden h-1.5 w-1.5 rounded-full bg-brand", collapsed && "lg:block")} />
                      </>
                    ) : null}
                  </>
                )}
              </NavLink>
            );
          })}
        </nav>

        {/* footer */}
        <div className="border-t border-graph/[0.08] px-3 py-3">
          {store?.url && (
            <a
              href={store.url}
              target="_blank"
              rel="noreferrer"
              onClick={onClose}
              title={collapsed ? "Ver la tienda" : undefined}
              className={cn(
                "mb-1 flex items-center gap-3 rounded-2xl px-3 py-2.5 text-sm font-medium text-graph-500 transition hover:bg-graph/[0.05] hover:text-brand",
                collapsed && "lg:justify-center lg:px-0"
              )}
            >
              <ExternalLink size={18} strokeWidth={2} className="shrink-0" />
              <span className={hideOnCollapse}>Ver la tienda</span>
            </a>
          )}
          <div className={cn("mb-2 flex items-center gap-2 rounded-2xl bg-graph/[0.04] px-3 py-2.5", collapsed && "lg:justify-center lg:px-0")}>
            <Gem size={16} className="shrink-0 text-brand" />
            <div className={cn("leading-tight", hideOnCollapse)}>
              <p className="text-xs font-semibold text-graph">{MARCA.nombre} · original o nada</p>
              <p className="text-[10px] text-graph-400">WhatsApp {MARCA.telefonos[0].numero}</p>
            </div>
          </div>
          <button
            onClick={cerrarSesion}
            title={collapsed ? "Cerrar sesión" : undefined}
            className={cn(
              "flex w-full items-center gap-3 rounded-2xl px-3 py-2.5 text-sm font-medium text-graph-400 transition hover:bg-graph/[0.05] hover:text-graph",
              collapsed && "lg:justify-center lg:px-0"
            )}
          >
            <LogOut size={18} strokeWidth={2} className="shrink-0" />
            <span className={hideOnCollapse}>Cerrar sesión</span>
          </button>
        </div>
      </aside>
    </>
  );
}
