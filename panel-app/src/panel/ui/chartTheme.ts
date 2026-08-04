// Paleta de marca para charts (recharts) — theme CLARO MIAMI IMPORT.
// Rojo #DF0A0A = serie principal (tienda / lo que importa), grafito para contraste,
// verde sea para lo "vivo" (service) y ámbar para mayorista/espera.
export const COLORS = {
  ink: "#16161A", // grafito (tinta)
  brand: "#DF0A0A", // rojo MIAMI IMPORT — serie principal
  brand300: "#F07A7A",
  graphite: "#3F3F46", // serie secundaria
  green: "#16A34A", // service / ok
  amber: "#D97706", // mayorista / espera
  sky: "#0369A1",
  // grilla y ejes sobre fondo claro
  grid: "rgba(22,22,26,0.07)",
  axis: "rgba(22,22,26,0.45)",
  // alias de opacidad
  ink10: "rgba(22,22,26,0.08)",
  ink60: "rgba(22,22,26,0.55)",
};

// Secuencia para series categóricas (torta/donut/barras por categoría).
// Arranca por el rojo de marca y alterna tonos con buen contraste en claro.
export const SERIE = ["#DF0A0A", "#16161A", "#D97706", "#16A34A", "#0369A1", "#E63B3B", "#71717A"];

// Tooltip claro premium reutilizable.
export const tooltipStyle = {
  background: "rgba(255,255,255,0.96)",
  border: "1px solid rgba(22,22,26,0.10)",
  borderRadius: 12,
  boxShadow: "0 18px 44px -20px rgba(22,22,26,0.28)",
  fontSize: 12,
  padding: "8px 12px",
  color: "#16161A",
  backdropFilter: "blur(8px)",
} as const;

export const tooltipItemStyle = { color: "#16161A" } as const;
export const tooltipLabelStyle = { color: "rgba(22,22,26,0.55)", marginBottom: 2 } as const;
