// ============================================================================
//  MARCA — único archivo que cambia por cliente.
//  Este es el corazón del ENLATADO de demos WESEKA: se copia la app entera,
//  se reemplaza SOLO este archivo y el panel queda rebrandeado.
//  Los colores salen como CSS variables (ver src/index.css) para que Tailwind
//  no haya que tocarlo nunca.
//
//  MIAMI IMPORT — indumentaria original importada, Buenos Aires.
//  Theme CLARO + champagne de marca (#B99B63, sacado de su tienda real).
// ============================================================================

export interface Marca {
  slug: string;
  nombre: string;
  nombreCorto: string;
  tagline: string;
  logo: string;
  ciudad: string;
  provincia: string;
  region: string;
  web: string;
  email: string;
  direccion: string;
  whatsapp: string;
  telefonos: { rotulo: string; numero: string; wa?: string }[];
  divisiones: { slug: string; rotulo: string; descripcion: string }[];
  colores: {
    paper: string; paper100: string; paper200: string;
    tinta: string; tinta700: string; tinta500: string; tinta400: string;
    brand: string; brand600: string; brand700: string; brand400: string; brand300: string; brand50: string;
    acento: string;
  };
  /** prefijo de tablas / claves de storage (aísla los datos de cada cliente) */
  dbPrefix: string;
  /** credenciales visibles del demo — en Miami el login es REAL: no se muestran */
  demo: { usuario: string; password: string; nota: string };
  copy: {
    heroTitulo: string;
    heroBajada: string;
    sobreTitulo: string;
    sobreTexto: string;
  };
}

export const MARCA: Marca = {
  slug: "miami",
  nombre: "MIAMI IMPORT",
  nombreCorto: "MIAMI",
  tagline: "Stock Manager",
  // Logo real de la tienda; en dev llega por el proxy de vite (/static → :8001).
  logo: "/static/images/miami-logo-v4.webp",
  ciudad: "Buenos Aires",
  provincia: "Buenos Aires",
  region: "todo el país",
  web: "",
  email: "miamiimport@gmail.com",
  direccion: "Buenos Aires",
  whatsapp: "+5491162321391",
  telefonos: [
    { rotulo: "Ventas (Diego)", numero: "11 6232-1391", wa: "+5491162321391" },
  ],
  divisiones: [
    { slug: "tienda", rotulo: "Tienda", descripcion: "Indumentaria original importada" },
  ],
  colores: {
    // Champagne MIAMI (#B99B63) sobre papel cálido. Theme CLARO. Nunca #000/#fff puros.
    paper: "#F5F4F1", paper100: "#FFFFFF", paper200: "#ECEAE4",
    tinta: "#17161A", tinta700: "#3F3E44", tinta500: "#72707A", tinta400: "#A3A1AA",
    brand: "#B99B63", brand600: "#A6884F", brand700: "#8A6F3F",
    brand400: "#D4BB88", brand300: "#E2CFA4", brand50: "#F8F3E8",
    acento: "#16A34A", // verde: stock/estados vivos
  },
  dbPrefix: "miami",
  demo: {
    usuario: "miamiimport@gmail.com",
    password: "",
    nota: "Acceso exclusivo del equipo de MIAMI IMPORT.",
  },
  copy: {
    heroTitulo: "Indumentaria original importada",
    heroBajada: "Marcas originales, con envíos a todo el país.",
    sobreTitulo: "Original o nada",
    sobreTexto: "Importamos indumentaria original y la despachamos a todo el país.",
  },
};

/** #B99B63 -> "185 155 99" (canales sueltos: así Tailwind puede aplicar /opacidad) */
function canales(hex: string): string {
  const h = hex.replace("#", "").trim();
  const f = h.length === 3 ? h.split("").map((x) => x + x).join("") : h;
  const n = parseInt(f, 16);
  return `${(n >> 16) & 255} ${(n >> 8) & 255} ${n & 255}`;
}

/** Inyecta la paleta de la marca como CSS variables (lo llama main.tsx al arrancar). */
export function aplicarMarca(m: Marca = MARCA) {
  const c = m.colores;
  const r = document.documentElement.style;
  const set = (k: string, hex: string) => r.setProperty(k, canales(hex));
  set("--paper", c.paper);
  set("--paper-100", c.paper100);
  set("--paper-200", c.paper200);
  set("--tinta", c.tinta);
  set("--tinta-700", c.tinta700);
  set("--tinta-500", c.tinta500);
  set("--tinta-400", c.tinta400);
  set("--brand", c.brand);
  set("--brand-600", c.brand600);
  set("--brand-700", c.brand700);
  set("--brand-400", c.brand400);
  set("--brand-50", c.brand50);
  set("--brand-300", c.brand300);
  set("--acento", c.acento);
  document.title = `${m.nombre} — ${m.tagline}`;
}
