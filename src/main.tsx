import { createRoot } from "react-dom/client";
import App from "./App.tsx";
import "./index.css";
import { loadRuntimeConfig } from "@/lib/runtimeConfig";
import { applyRuntimePocketBaseUrl } from "@/lib/pocketbase";
import { instalarListenersGlobales, registrarError } from "@/lib/errorLog";
import { hayVisorSnapshot } from "@/lib/visorSnapshot";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { TooltipProvider } from "@/components/ui/tooltip";
import { Toaster } from "@/components/ui/toaster";
import { SolicitudesProvider } from "@/contexts/SolicitudesContext";
import { UsuariosRegistradosProvider } from "@/hooks/useUsuariosRegistrados";
import { HashRouter } from "react-router-dom";
import VisorInforme from "./pages/VisorInforme";

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

  // Modo VISOR OFFLINE (informe exportado a pendrive): hay un snapshot de datos
  // embebido y NO hay PocketBase. Montamos DIRECTAMENTE <VisorInforme/> con sus
  // providers, SIN React Router. Esto es clave: el informe se abre con file://
  // (doble clic), donde las rutas tipo "/visor" NO existen y el router caia en
  // la pagina 404 ("Oops! Page not found"). Renderizando el visor directo, sin
  // rutas, el problema desaparece.
  if (hayVisorSnapshot()) {
    console.log("[Sistema Llaves FCEA] Modo VISOR offline (informe exportado).");
    const queryClient = new QueryClient();
    createRoot(document.getElementById("root")!).render(
      <QueryClientProvider client={queryClient}>
        <UsuariosRegistradosProvider>
          <SolicitudesProvider>
            <TooltipProvider>
              <Toaster />
              {/* HashRouter: funciona bajo file:// (doble clic) sin 404.
                  Los <Link> internos del Dashboard necesitan un Router. */}
              <HashRouter>
                <VisorInforme />
              </HashRouter>
            </TooltipProvider>
          </SolicitudesProvider>
        </UsuariosRegistradosProvider>
      </QueryClientProvider>
    );
    return;
  }

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
