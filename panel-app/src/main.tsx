import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter, HashRouter } from "react-router-dom";
import App from "./App";
import "./index.css";
import { aplicarMarca } from "./marca";

// ENLATADO: pinta la paleta y el título de la marca antes del primer render.
// Rebrandear el demo = cambiar src/marca.ts. Nada más.
aplicarMarca();

// En wsk.com.ar/demos/<slug> no hay rewrite de SPA: usamos hash routing para que
// /panel y /propiedades funcionen igual. En local y en dominio propio, history API.
const Router = import.meta.env.BASE_URL !== "/" ? HashRouter : BrowserRouter;

// URLs limpias (/panel, /admin, /propiedades). En estático necesita el rewrite SPA:
// Netlify lo resuelve con public/_redirects (/* -> /index.html 200). Local (vite dev) ya hace el fallback.
ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <Router>
      <App />
    </Router>
  </React.StrictMode>
);
