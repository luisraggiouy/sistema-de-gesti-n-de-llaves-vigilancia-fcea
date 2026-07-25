import { useMemo } from "react";
import { getRuntimeConfig, HardwareTipo, RolPC } from "@/lib/runtimeConfig";

export type DeviceType = "monitor" | "terminal" | "auto";

interface DeviceConfig {
  /** Tipo de dispositivo lógico (derivado del rol del runtime config). */
  deviceType: DeviceType;
  /** True si está en modo producción (kiosk). */
  isProductionMode: boolean;
  /** Identificador del rol específico ("monitor", "terminal-a", "terminal-b", "dashboard"). */
  rol: RolPC;
  /**
   * Tipo físico de hardware detectado/configurado por el instalador.
   * "tactil" | "tradicional" | "desarrollo" | undefined (sin configurar).
   */
  hardware: HardwareTipo | undefined;
  /** Atajos derivados: true si el hardware NO es táctil. */
  isTradicional: boolean;
  /** Atajos derivados: true si la PC corre en modo desarrollo. */
  isDevMode: boolean;
  /** En modo desarrollo se muestran los botones para alternar entre Monitor y Terminal. */
  shouldShowNavigationButtons: boolean;
  /**
   * Visibilidad específica del botón Dashboard en el header del Monitor.
   * - Siempre visible en hardware "tradicional" o en modo desarrollo.
   * - Oculto (entra por menú admin) en kiosks táctiles.
   */
  shouldShowDashboardButton: boolean;
  /** Ruta por defecto según el rol/modo. */
  getDefaultRoute: () => string;
}

/**
 * Lee la configuración del dispositivo desde `public/config.json` (runtime config).
 *
 * En la arquitectura v2.0 de 3 PCs, cada PC tiene su propio `config.json`
 * con su `rol` correspondiente. En modo "desarrollo" (1 PC) se muestran
 * los botones que permiten alternar entre Monitor y Terminal.
 *
 * El campo `hardware` (introducido en v2.1 con el rediseño del instalador
 * unificado) permite tomar decisiones de UI independientes del rol: por
 * ejemplo mostrar el botón Dashboard en PCs tradicionales aunque corran en
 * modo producción.
 */
export function useDeviceConfig(): DeviceConfig {
  const config = useMemo((): DeviceConfig => {
    const rt = getRuntimeConfig();
    const isProductionMode = rt.modo === "produccion";
    const isDevMode = rt.modo === "desarrollo";
    const hardware = rt.hardware;
    const isTradicional = hardware === "tradicional";

    const deviceType: DeviceType =
      rt.rol === "monitor"
        ? "monitor"
        : rt.rol === "terminal-a" || rt.rol === "terminal-b"
        ? "terminal"
        : "auto";

    // BotÃ³n "Monitor Vigilancia" en el TerminalHeader:
    //   - Solo se muestra en modo desarrollo (1 PC con todas las vistas), o
    //   - En modo producciÃ³n cuando esta PC es realmente la del monitor
    //     (o dashboard) con hardware tradicional. Las terminales de usuario
    //     (rol terminal-a / terminal-b) NUNCA muestran este botÃ³n porque
    //     no tiene sentido: los usuarios no navegan al Monitor Vigilancia.
    const isMonitorRole = rt.rol === "monitor" || rt.rol === "dashboard";
    const shouldShowNavigationButtons =
      isDevMode || (isProductionMode && isTradicional && isMonitorRole);

    // Botón Dashboard: es un módulo dentro del Monitor Vigilancia.
    // Se muestra únicamente cuando esta PC tiene rol "monitor" (o en
    // desarrollo, para poder probarlo en la notebook del dev). Las
    // Terminales A/B nunca lo muestran — son kioskos de usuario y no
    // corresponde que accedan al Dashboard.
    //
    // NO depende del tipo de hardware: si mañana el Monitor se cambia
    // por una pantalla capacitiva, sigue siendo un Monitor y el botón
    // debe aparecer igual.
    const shouldShowDashboardButton = isMonitorRole || isDevMode;

    const getDefaultRoute = (): string => {
      if (rt.rol === "monitor") return "/monitor";
      if (rt.rol === "dashboard") return "/dashboard";
      // terminal-a, terminal-b y "auto" → terminal
      return "/terminal";
    };

    return {
      deviceType,
      isProductionMode,
      rol: rt.rol,
      hardware,
      isTradicional,
      isDevMode,
      shouldShowNavigationButtons,
      shouldShowDashboardButton,
      getDefaultRoute,
    };
  }, []);

  return config;
}
