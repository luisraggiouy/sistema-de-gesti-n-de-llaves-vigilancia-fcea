import { createRoot } from "react-dom/client";
import App from "./App.tsx";
import "./index.css";
import { loadRuntimeConfig } from "@/lib/runtimeConfig";
import { applyRuntimePocketBaseUrl } from "@/lib/pocketbase";
import { instalarListenersGlobales, registrarError } from "@/lib/errorLog";

/**
 * Bootstrap:
 *   1. Carga `public/config.json` (modo, rol, URL del servidor PocketBase).
 *   2. Apunta el cliente PocketBase al servidor correcto.
 *   3. Renderiza React.
 *
 * Si la carga del config falla, se usa la configuración por defecto
 * (modo desarrollo, PocketBase en 127.0.0.1:8090).
 */
async function bootstrap() {
  console.log("[Sistema Llaves FCEA v2.0] Iniciando…");
  // Instalamos captura de errores no manejados ANTES de cualquier otra
  // cosa para que si algo falla en bootstrap quede en el log visible
  // via el DiagnosticoModal (Ctrl+Shift+D / 5 toques).
  instalarListenersGlobales();
  const cfg = await loadRuntimeConfig();
  await applyRuntimePocketBaseUrl();
  console.log(
    `[Sistema Llaves FCEA v2.0] Listo. Modo=${cfg.modo} | Rol=${cfg.rol} | PB=${cfg.pocketbase_url} | HW=${cfg.hardware}`,
  );

  // v2.8 (2026-07-23) — ROLLBACK P2/P3/P4/P5:
  //   Antes marcabamos <html>/<body> con `hw-tactil` y `scrollbar-touch`
  //   cuando el config decia hardware=tactil, para que index.css engordara
  //   la scrollbar del documento y activara los chevrones flotantes ▲/▼.
  //   Ese experimento se revirtio: las 3 PCs corren con UX de mouse +
  //   teclado y usan la scrollbar nativa del navegador. No agregamos
  //   ninguna clase global aca.

  createRoot(document.getElementById("root")!).render(<App />);
}

bootstrap().catch((err) => {
  console.error("[Sistema Llaves FCEA] Error fatal en bootstrap:", err);
  registrarError("bootstrap", err);
  // Aún así renderizamos para no dejar la pantalla en blanco.
  createRoot(document.getElementById("root")!).render(<App />);
});
