// ============================================================================
//  Auth del panel — sesión REAL contra el backend de MIAMI IMPORT.
//  POST /panel/api/auth/login setea la cookie HttpOnly `mi_admin` (12 h);
//  acá solo preguntamos "¿estoy adentro?" con GET /auth/me. Sin puentes demo.
// ============================================================================
import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { api, ApiError } from "./api/miamiApi";

type SignInResult = { ok: boolean; mfa?: boolean; error?: string };

type AuthCtx = {
  authed: boolean;
  loading: boolean;
  email: string | null;
  signIn: (email: string, pass: string, totp?: string) => Promise<SignInResult>;
  signOut: () => Promise<void>;
};
const Ctx = createContext<AuthCtx | null>(null);
export const usePanelAuth = () => { const c = useContext(Ctx); if (!c) throw new Error("usePanelAuth fuera de PanelAuthProvider"); return c; };

export function PanelAuthProvider({ children }: { children: ReactNode }) {
  const [authed, setAuthed] = useState(false);
  const [email, setEmail] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  // Al montar: ¿la cookie sigue viva? (F5 no debe pedir login de nuevo)
  useEffect(() => {
    let cancel = false;
    api.me()
      .then((me) => { if (!cancel) { setAuthed(true); setEmail(me.email); } })
      .catch(() => { /* 401 = sin sesión, es el caso normal */ })
      .finally(() => { if (!cancel) setLoading(false); });
    return () => { cancel = true; };
  }, []);

  const signIn = async (em: string, pass: string, totp?: string): Promise<SignInResult> => {
    try {
      const r = await api.login(em.trim().toLowerCase(), pass, totp);
      if (r.mfa_required) return { ok: false, mfa: true };
      if (r.ok) {
        setAuthed(true);
        setEmail(r.email ?? em.trim().toLowerCase());
        return { ok: true };
      }
      return { ok: false, error: "No se pudo iniciar sesión." };
    } catch (e) {
      if (e instanceof ApiError) {
        if (e.status === 401) return { ok: false, error: "Email o contraseña incorrectos." };
        if (e.status === 429) return { ok: false, error: e.message };
        return { ok: false, error: e.message };
      }
      return { ok: false, error: "No se pudo hablar con el servidor. ¿Está corriendo?" };
    }
  };

  const signOut = async () => {
    try { await api.logout(); } catch { /* la cookie igual muere sola */ }
    setAuthed(false);
    setEmail(null);
  };

  return <Ctx.Provider value={{ authed, loading, email, signIn, signOut }}>{children}</Ctx.Provider>;
}
