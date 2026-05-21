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

    // En modo desarrollo, mostramos los botones de cambio de vista.
    // En modo producción tradicional (PC de oficina, no kiosk) también los
    // mostramos: es el caso donde vigilancia opera con teclado/mouse y
    // necesita acceder al Dashboard sin trucos.
    const shouldShowNavigationButtons = isDevMode || isTradicional;

    // Botón Dashboard: visible en cualquier escenario donde NO sea un kiosk
    // táctil "puro". El kiosk táctil expone el Dashboard solo vía menú admin.
    const shouldShowDashboardButton =
      isDevMode || isTradicional || hardware === undefined;

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
