/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // ===== ENLATADO WESEKA: los colores salen de src/marca.ts vía CSS vars =====
        // No se toca este archivo para rebrandear. Se cambia marca.ts y listo.
        // (Los fallbacks son la paleta YAGÜE: oro sobre negro patagónico.)
        // Los canales van sueltos ("194 147 15") para que funcione bg-brand/20.
        paper: {
          DEFAULT: "rgb(var(--paper, 14 14 13) / <alpha-value>)", // fondo de página
          100: "rgb(var(--paper-100, 23 23 20) / <alpha-value>)", // tarjetas
          200: "rgb(var(--paper-200, 34 33 29) / <alpha-value>)", // sub-bloques
        },
        graph: {
          DEFAULT: "rgb(var(--tinta, 242 239 231) / <alpha-value>)", // texto principal
          700: "rgb(var(--tinta-700, 207 201 187) / <alpha-value>)",
          500: "rgb(var(--tinta-500, 154 147 132) / <alpha-value>)", // secundario
          400: "rgb(var(--tinta-400, 110 106 95) / <alpha-value>)", // muted
        },
        brand: {
          // acento = información (precio, hectáreas, CTA)
          DEFAULT: "rgb(var(--brand, 194 147 15) / <alpha-value>)",
          600: "rgb(var(--brand-600, 168 125 8) / <alpha-value>)",
          700: "rgb(var(--brand-700, 133 98 5) / <alpha-value>)",
          400: "rgb(var(--brand-400, 214 172 53) / <alpha-value>)",
          300: "rgb(var(--brand-300, 230 203 124) / <alpha-value>)",
          50: "rgb(var(--brand-50, 247 240 218) / <alpha-value>)",
          950: "rgb(var(--brand-950, 58 43 4) / <alpha-value>)",
        },
        sea: {
          // estado vivo (disponible, datos del panel)
          DEFAULT: "rgb(var(--acento, 107 127 91) / <alpha-value>)",
          300: "rgb(var(--acento-300, 157 174 141) / <alpha-value>)",
          50: "rgb(var(--acento-50, 237 241 233) / <alpha-value>)",
        },

        // ===== Sistema OSCURO heredado (panel, hasta su barrido a blanco) =====
        ink: { DEFAULT: "#0B1220", 800: "#111A2B", 700: "#1A2436", 600: "#243044" },
        bone: { DEFAULT: "#F6F2E9", 200: "#ECE6D8", 300: "#DED5C2" },
        wheat: { DEFAULT: "#C9A24E", 400: "#D8B566", 600: "#A9842F" },
        field: { DEFAULT: "#5B6B43", 700: "#46532F", 300: "#8FA06B" },
        clay: "#9C6B3C",
      },
      fontFamily: {
        // Par tipográfico Potente: Clash Display (titulares) + General Sans (todo lo demás)
        display: ['"Clash Display"', '"General Sans"', "system-ui", "sans-serif"],
        sans: ['"General Sans"', "system-ui", "sans-serif"],
      },
      letterSpacing: {
        widest2: "0.28em",
      },
      boxShadow: {
        card: "0 14px 44px -18px rgba(13,21,33,0.20)",
        soft: "0 4px 22px -10px rgba(13,21,33,0.14)",
        ring: "0 0 0 1px rgba(13,21,33,0.06)",
      },
      maxWidth: {
        container: "1240px",
      },
      keyframes: {
        kenburns: {
          "0%": { transform: "scale(1.05) translate3d(0,0,0)" },
          "100%": { transform: "scale(1.18) translate3d(-1.5%,-1.5%,0)" },
        },
        shimmer: {
          "100%": { transform: "translateX(100%)" },
        },
        horizon: {
          "0%, 100%": { transform: "translateX(-12%) scaleY(1)" },
          "50%": { transform: "translateX(12%) scaleY(1.6)" },
        },
        drift: {
          "0%, 100%": { transform: "translate3d(-2%, 1%, 0) scale(1)" },
          "50%": { transform: "translate3d(2%, -1%, 0) scale(1.06)" },
        },
      },
      animation: {
        kenburns: "kenburns 22s ease-out forwards",
        horizon: "horizon 14s ease-in-out infinite",
        drift: "drift 18s ease-in-out infinite",
      },
    },
  },
  plugins: [],
};
