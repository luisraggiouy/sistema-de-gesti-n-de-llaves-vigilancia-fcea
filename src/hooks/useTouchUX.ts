import { useMemo } from "react";
import { getRuntimeConfig } from "@/lib/runtimeConfig";
import { useTouchDetection } from "@/hooks/useTouchDetection";

/**
 * Config derivada de UX táctil, calculada a partir de `hardware` +
 * flags opcionales de `ui.*` en `public/config.json`.
 *
 * Centraliza las decisiones de "cómo adaptamos la interfaz cuando el
 * monitor es táctil pero limitado" (caso 3nStar TCM008 resistivo):
 *   - Scroll: la barra debe ser gorda (≥ 25 px) para ser toqueable.
 *   - Listas: complementadas con botones flotantes ▲ / ▼.
 *   - Screensaver: overlay a pantalla completa tras N segundos de
 *     inactividad, para que el monitor no se apague y el próximo
 *     usuario vea una pista clara.
 *
 * Los tres flags se activan por defecto cuando `hardware === "tactil"`,
 * pero se pueden encender/apagar puntualmente vía `config.json`.
 */
export interface TouchUXConfig {
  /** True si la app debe tratar esta PC como táctil. */
  isTouch: boolean;
  /** True si debe mostrar barra de scroll ancha (touch-friendly). */
  scrollbarAncha: boolean;
  /** True si el screensaver de bienvenida debe estar activo. */
  screensaverActivo: boolean;
  /** Delay de inactividad antes del screensaver (ms). */
  screensaverDelayMs: number;
  /** Texto grande del overlay. */
  screensaverTexto: string;
}

const SCREENSAVER_TEXTO_DEFAULT =
  "¡BIENVENIDO/A! TOQUE LA PANTALLA PARA SOLICITAR SU/S LLAVES";
const SCREENSAVER_DELAY_DEFAULT_MS = 60_000;

export function useTouchUX(): TouchUXConfig {
  const isTouch = useTouchDetection();

  return useMemo(() => {
    let cfg;
    try {
      cfg = getRuntimeConfig();
    } catch {
      cfg = null;
    }

    const uiCfg = cfg?.ui ?? {};

    // Defaults: si estamos en modo táctil, ambos features arrancan encendidos.
    const scrollbarAncha =
      uiCfg.scrollbar_ancha !== undefined
        ? Boolean(uiCfg.scrollbar_ancha)
        : isTouch;

    const screensaverActivo =
      uiCfg.screensaver_activo !== undefined
        ? Boolean(uiCfg.screensaver_activo)
        : isTouch;

    const screensaverDelayMs =
      typeof uiCfg.screensaver_delay_ms === "number" &&
      uiCfg.screensaver_delay_ms > 0
        ? uiCfg.screensaver_delay_ms
        : SCREENSAVER_DELAY_DEFAULT_MS;

    const screensaverTexto =
      typeof uiCfg.screensaver_texto === "string" &&
      uiCfg.screensaver_texto.trim().length > 0
        ? uiCfg.screensaver_texto
        : SCREENSAVER_TEXTO_DEFAULT;

    return {
      isTouch,
      scrollbarAncha,
      screensaverActivo,
      screensaverDelayMs,
      screensaverTexto,
    };
  }, [isTouch]);
}
