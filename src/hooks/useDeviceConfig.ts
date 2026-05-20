import { useMemo } from "react";
import { getRuntimeConfig, RolPC } from "@/lib/runtimeConfig";

export type DeviceType = "monitor" | "terminal" | "auto";

interface DeviceConfig {
  /** Tipo de dispositivo lógico (derivado del rol del runtime config). */
  deviceType: DeviceType;
  /** True si está en modo producción (kiosk). */
  isProductionMode: boolean;
  /** Identificador del rol específico ("monitor", "terminal-a", "terminal-b", "dashboard"). */
  rol: RolPC;
  /** En modo desarrollo se muestran los botones para alternar entre Monitor y Terminal. */
  shouldShowNavigationButtons: boolean;
  /** Ruta por defecto según el rol/modo. */
  getDefaultRoute: () => string;
}

/**
 * Lee la configuración del dispositivo desde `public/config.json` (runtime config).
 *
 * En la arquitectura v2.0 de 3 PCs, cada PC tiene su propio `config.json`
 * con su `rol` correspondiente. En modo "desarrollo" (1 PC) se muestran
 * los botones que permiten alternar entre Monitor y Terminal.
 */
export function useDeviceConfig(): DeviceConfig {
  const config = useMemo((): DeviceConfig => {
    const rt = getRuntimeConfig();
    const isProductionMode = rt.modo === "produccion";

    const deviceType: DeviceType =
      rt.rol === "monitor"
        ? "monitor"
        : rt.rol === "terminal-a" || rt.rol === "terminal-b"
        ? "terminal"
        : "auto";

    // En modo desarrollo, mostramos los botones de cambio de vista.
    // En modo producción (3 PCs), cada PC tiene un rol fijo, sin alternar.
    const shouldShowNavigationButtons = !isProductionMode;

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
      shouldShowNavigationButtons,
      getDefaultRoute,
    };
  }, []);

  return config;
}
