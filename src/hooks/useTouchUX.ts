import { useMemo } from "react";
import { getRuntimeConfig } from "@/lib/runtimeConfig";
import { useTouchDetection } from "@/hooks/useTouchDetection";

/**
 * Config del screensaver de bienvenida de la Terminal.
 *
 * v2.8 (2026-07-23) — ROLLBACK P2/P3/P4/P5:
 *   Antes este hook exponia tambien flags `scrollbarAncha`,
 *   `isTouchProduccion`, `isTouchEfectivo`, etc., que alimentaban
 *   toda una capa de UX tactil (Sheet lateral, chevrones flotantes
 *   ▲/▼, scrollbar gorda 25 px, chips gigantes). Ese experimento se
 *   revirtio: ahora las 3 PCs (Monitor + Terminal A + Terminal B)
 *   corren en modo mouse + teclado, aun cuando la pantalla sea
 *   tactil. Si en el futuro llega hardware capacitivo, Windows aporta
 *   TabTip on-demand y no hace falta codigo especifico.
 *
 * Este hook quedo SOLO para decidir si mostrar el screensaver de
 * bienvenida ("BIENVENIDO/A, TOQUE LA PANTALLA...") en la Terminal.
 * El screensaver a su vez cumple doble proposito:
 *   1. Mantiene pixels en movimiento para que el monitor no entre en
 *      DPMS-off si Windows fallo en desactivar el ahorro de energia.
 *   2. Le da al proximo usuario una pista visual clara de que la PC
 *      esta viva y que debe tocar/hacer click para empezar.
 */
export interface TouchUXConfig {
  /** True si esta PC se considera tactil (para el texto del screensaver). */
  isTouch: boolean;
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

    // Regla dura: si el rol es "monitor" o "dashboard", NUNCA aplicamos
    // screensaver ni consideramos la PC tactil (aunque el config.json
    // diga hardware=tactil por error).
    const rolLower = String(cfg?.rol ?? "").toLowerCase();
    const esMonitor = rolLower === "monitor" || rolLower === "dashboard";

    const isTouchEfectivo = esMonitor ? false : isTouch;

    // Screensaver v2.5 (julio 2026), preservado en v2.8:
    //
    // El screensaver del FRONTEND solo existe como FALLBACK para el caso
    // patologico en que Windows por algun motivo dejara la pantalla
    // activa pero nosotros quisieramos oscurecerla despues de X minutos
    // de inactividad para no "quemar" un panel viejo.
    //
    // El instalador (`scripts/lib/configurar_energia.ps1`) desactiva
    // COMPLETAMENTE el ahorro de energia de Windows, DPMS, screensaver
    // y USB-suspend en las 3 PCs del piloto. Cuando eso corre sin
    // warnings escribe `ui.energia_ahorro_desactivado = true` en el
    // config.json. En ese caso NO queremos que el frontend muestre nada
    // por su cuenta: la pantalla queda encendida 24/7.
    //
    // Reglas de decision (en orden):
    //   1. Rol monitor / dashboard    -> screensaver SIEMPRE OFF
    //   2. `ui.energia_ahorro_desactivado === true`  (setup OK)
    //      -> screensaver OFF por defecto, salvo que el operador lo
    //         fuerce con `ui.screensaver_activo: true`.
    //   3. `ui.energia_ahorro_desactivado === false` (setup con warnings)
    //      -> screensaver ON por defecto en modo tactil (fallback), se
    //         puede apagar con `ui.screensaver_activo: false`.
    //   4. Flag ausente (config viejo) -> se preserva el comportamiento
    //      historico: OFF por defecto, ON solo si el operador lo pide.
    const energiaAhorroOff = uiCfg.energia_ahorro_desactivado === true;
    const energiaAhorroKO  = uiCfg.energia_ahorro_desactivado === false;

    let screensaverActivo: boolean;
    if (esMonitor) {
      screensaverActivo = false;
    } else if (typeof uiCfg.screensaver_activo === "boolean") {
      screensaverActivo = uiCfg.screensaver_activo;
    } else if (energiaAhorroOff) {
      screensaverActivo = false;
    } else if (energiaAhorroKO && isTouchEfectivo) {
      screensaverActivo = true;
    } else {
      screensaverActivo = false;
    }

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
      isTouch: isTouchEfectivo,
      screensaverActivo,
      screensaverDelayMs,
      screensaverTexto,
    };
  }, [isTouch]);
}
