import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { getRuntimeConfig } from "@/lib/runtimeConfig";
import TerminalUsuario from "./TerminalUsuario";
import MonitorVigilancia from "./MonitorVigilancia";
import Dashboard from "./Dashboard";

/**
 * Página raíz: decide qué interfaz mostrar según `config.json`.
 *
 * - modo "produccion": kiosk fijo según el rol (sin botón de cambio).
 *     - rol "monitor"      → MonitorVigilancia
 *     - rol "terminal-a"   → TerminalUsuario
 *     - rol "terminal-b"   → TerminalUsuario
 *     - rol "dashboard"    → Dashboard
 *
 * - modo "desarrollo": una sola PC con interfaz alternable.
 *     Renderiza TerminalUsuario (que contiene el botón "Monitor" en su header
 *     para cambiar a la vista de vigilancia desde la misma pantalla).
 */
const Index = () => {
  const cfg = getRuntimeConfig();
  const navigate = useNavigate();

  // En modo producción con rol "monitor" o "dashboard", redirigimos
  // a sus rutas dedicadas para que la URL refleje claramente el rol
  // (útil para diagnóstico y para el atajo Ctrl+R/F5 desde kiosk).
  useEffect(() => {
    if (cfg.modo === "produccion") {
      if (cfg.rol === "monitor" && window.location.pathname !== "/monitor") {
        navigate("/monitor", { replace: true });
      } else if (
        cfg.rol === "dashboard" &&
        window.location.pathname !== "/dashboard"
      ) {
        navigate("/dashboard", { replace: true });
      }
    }
  }, [cfg.modo, cfg.rol, navigate]);

  if (cfg.modo === "produccion") {
    if (cfg.rol === "monitor") return <MonitorVigilancia />;
    if (cfg.rol === "dashboard") return <Dashboard />;
    // terminal-a y terminal-b usan la misma UI; el id concreto lo lee
    // TerminalUsuario desde getRuntimeConfig() si necesita diferenciarlas.
    return <TerminalUsuario />;
  }

  // Modo desarrollo: la terminal con el botón "Monitor" en el header.
  return <TerminalUsuario />;
};

export default Index;
