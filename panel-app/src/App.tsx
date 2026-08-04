import { Routes, Route, Navigate } from "react-router-dom";
import { lazy, Suspense, type ReactNode } from "react";
import { DataProvider } from "./lib/DataProvider";
import { PanelAuthProvider, usePanelAuth } from "./panel/auth";
import Login from "./panel/Login";
import { ErrorBoundary } from "./ErrorBoundary";

// Esta instancia del enlatado es SOLO el panel: la tienda pública de MIAMI
// IMPORT ya existe (server-rendered en el backend). Todo lo que no es panel
// redirige al login.
const PanelApp = lazy(() => import("./panel/PanelApp"));

// Protege el panel: sin sesión → a la pantalla de login.
// El DataProvider vive acá adentro: recién se monta con la cookie ya puesta,
// así el primer fetch de productos no rebota con 401.
function RequirePanelAuth({ children }: { children: ReactNode }) {
  const { authed, loading } = usePanelAuth();
  if (loading) return <PanelFallback />;
  return authed ? <DataProvider>{children}</DataProvider> : <Navigate to="/ingresar" replace />;
}

function PanelFallback() {
  return (
    <div style={{ minHeight: "100vh", display: "grid", placeItems: "center", background: "#F5F4F1", color: "#17161A", fontFamily: "'General Sans', sans-serif" }}>
      Cargando panel…
    </div>
  );
}

export default function App() {
  return (
    <PanelAuthProvider>
      <ErrorBoundary>
        <Routes>
          <Route path="/ingresar" element={<Login />} />
          <Route
            path="/panel/*"
            element={
              <RequirePanelAuth>
                <Suspense fallback={<PanelFallback />}>
                  <PanelApp />
                </Suspense>
              </RequirePanelAuth>
            }
          />
          {/* /admin es alias del panel; cualquier otra ruta va al login (que
              redirige solo al panel si ya hay sesión). */}
          <Route path="/admin/*" element={<Navigate to="/panel" replace />} />
          <Route path="*" element={<Navigate to="/ingresar" replace />} />
        </Routes>
      </ErrorBoundary>
    </PanelAuthProvider>
  );
}
