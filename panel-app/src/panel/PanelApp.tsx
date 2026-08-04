import { useState, useEffect } from "react";
import { Routes, Route, Navigate, useLocation } from "react-router-dom";
import { cn } from "./ui/cn";
import Sidebar from "./components/Sidebar";
import Topbar from "./components/Topbar";
import ProfileGate from "./components/ProfileGate";
import { ProfilesProvider, useProfiles, canAccess } from "./profiles";
import { ToastProvider } from "./components/Toast";

// Si el perfil activo no puede ver la sección actual, lo manda a la primera permitida.
function PermGuard() {
  const { activo } = useProfiles();
  const { pathname } = useLocation();
  const seg = pathname.replace(/^\/panel\/?/, "");
  const key = seg === "" ? "inicio" : seg.split("/")[0];
  if (canAccess(activo, key)) return null;
  const order = ["venta", "productos", "cargar", "apedido", "reservas", "pedidos"];
  const landing = activo?.admin ? "/panel" : "/panel/" + (order.find((k) => canAccess(activo, k)) || "productos");
  return <Navigate to={landing} replace />;
}

import Dashboard from "./pages/Dashboard";
import Productos from "./pages/Productos";
import CargarProducto from "./pages/CargarProducto";
import Vender from "./pages/Vender";
import APedido from "./pages/APedido";
import Reservas from "./pages/Reservas";
import Pedidos from "./pages/Pedidos";
import Estadisticas from "./pages/Estadisticas";
import PreciosUsd from "./pages/PreciosUsd";
import WhatsappPage from "./pages/WhatsappPage";
import Acciones from "./pages/Acciones";

// Panel MIAMI IMPORT completo — paridad con el Stock Manager viejo, todo
// contra el backend real (127.0.0.1:8001 vía proxy en dev).

// Estilos propios del panel (keyframes para modal/toast).
const panelStyles = `
@keyframes fadeIn { from { opacity: 0; transform: scale(.98) } to { opacity: 1; transform: scale(1) } }
@keyframes slideUp { from { opacity: 0; transform: translateY(8px) } to { opacity: 1; transform: translateY(0) } }
`;

export default function PanelApp() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(() => {
    try { return localStorage.getItem("miami_panel_collapsed") === "1"; } catch { return false; }
  });
  const toggleCollapse = () =>
    setCollapsed((c) => {
      const n = !c;
      try { localStorage.setItem("miami_panel_collapsed", n ? "1" : "0"); } catch {}
      return n;
    });

  // ESC: solo cierra el menú mobile si está abierto. NO saca del panel (eso molestaba).
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape" && sidebarOpen) setSidebarOpen(false); };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [sidebarOpen]);

  return (
    <ToastProvider>
      <ProfilesProvider>
        <style>{panelStyles}</style>
        <div className="panel-bg min-h-screen font-sans text-graph antialiased">
          <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} collapsed={collapsed} onToggleCollapse={toggleCollapse} />

          <div className={cn("transition-[padding] duration-300", collapsed ? "lg:pl-[100px]" : "lg:pl-[276px]")}>
            <Topbar onMenu={() => setSidebarOpen(true)} />
            <main className="mx-auto w-full max-w-[1400px] px-4 py-6 md:px-8 md:py-8">
              <PermGuard />
              <Routes>
                <Route path="" element={<Dashboard />} />
                <Route path="venta" element={<Vender />} />
                <Route path="productos" element={<Productos />} />
                <Route path="cargar" element={<CargarProducto />} />
                <Route path="apedido" element={<APedido />} />
                <Route path="reservas" element={<Reservas />} />
                <Route path="pedidos" element={<Pedidos />} />
                <Route path="estadisticas" element={<Estadisticas />} />
                <Route path="precios-usd" element={<PreciosUsd />} />
                <Route path="whatsapp" element={<WhatsappPage />} />
                <Route path="acciones" element={<Acciones />} />
                <Route path="*" element={<Navigate to="/panel" replace />} />
              </Routes>
            </main>
          </div>
        </div>
        <ProfileGate />
      </ProfilesProvider>
    </ToastProvider>
  );
}
