import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  // ENLATADO: en local queda "/". En producción el panel se sirve desde el
  // mismo dominio que el backend de MIAMI IMPORT (cookies same-origin).
  base: process.env.DEMO_BASE || "/",
  resolve: {
    alias: { "@": path.resolve(__dirname, "src") },
  },
  server: {
    host: "127.0.0.1",
    port: 5173,
    // Backend REAL de Miami (FastAPI). Solo /panel/api va al backend: la ruta
    // /panel (sin /api) es la SPA. /static sirve las fotos locales y el logo.
    proxy: {
      "/panel/api": { target: "http://127.0.0.1:8001", changeOrigin: false },
      "/static": { target: "http://127.0.0.1:8001", changeOrigin: false },
    },
  },
});
