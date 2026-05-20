import { createRoot } from "react-dom/client";
import App from "./App.tsx";
import "./index.css";
import { loadRuntimeConfig } from "@/lib/runtimeConfig";
import { applyRuntimePocketBaseUrl } from "@/lib/pocketbase";

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
  const cfg = await loadRuntimeConfig();
  await applyRuntimePocketBaseUrl();
  console.log(
    `[Sistema Llaves FCEA v2.0] Listo. Modo=${cfg.modo} | Rol=${cfg.rol} | PB=${cfg.pocketbase_url}`,
  );

  createRoot(document.getElementById("root")!).render(<App />);
}

bootstrap().catch((err) => {
  console.error("[Sistema Llaves FCEA] Error fatal en bootstrap:", err);
  // Aún así renderizamos para no dejar la pantalla en blanco.
  createRoot(document.getElementById("root")!).render(<App />);
});
