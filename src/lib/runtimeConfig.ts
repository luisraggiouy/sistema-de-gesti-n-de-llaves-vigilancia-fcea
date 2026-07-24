/**
 * Runtime configuration loader.
 *
 * Carga `public/config.json` al arrancar la aplicación. Este archivo se sirve
 * estático desde el mismo origen que el frontend, por lo que se puede modificar
 * en producción SIN recompilar el bundle. Solo hace falta recargar el navegador.
 *
 * Esto es clave para la arquitectura de 3 PCs: cada terminal puede apuntar al
 * servidor con una IP distinta editando este archivo, sin rebuilds.
 */

export type ModoSistema = "desarrollo" | "produccion";

export type RolPC = "monitor" | "terminal-a" | "terminal-b" | "dashboard";

/**
 * Tipo físico de hardware donde corre esta PC. Lo escribe el instalador
 * después de detectar pantalla táctil / monitores / etc., y lo persiste
 * tanto en `config.json` como (opcionalmente) en la colección
 * `sistema_config` de PocketBase. Si no está presente, el frontend cae
 * al fallback de detección automática (useTouchDetection).
 *
 *  - "tactil":      kiosko, sin acceso visible al Dashboard.
 *  - "tradicional": PC de oficina (mouse+teclado). Dashboard visible.
 *  - "desarrollo":  notebook del desarrollador (todo visible).
 */
export type HardwareTipo = "tactil" | "tradicional" | "desarrollo";

export interface RuntimeConfig {
  version: string;
  modo: ModoSistema;
  rol: RolPC;
  /**
   * Tipo de hardware detectado/elegido al instalar. Opcional para mantener
   * compatibilidad con `config.json` viejos (en ese caso el frontend usa
   * heurísticas de useTouchDetection).
   */
  hardware?: HardwareTipo;
  pocketbase_url: string;
  red: {
    ip_servidor: string;
    ip_terminal_a: string;
    ip_terminal_b: string;
  };
  ui: {
    teclado_virtual_forzado: boolean;
    tema: "claro" | "oscuro";
    /**
     * Ensancha las barras de scroll (ScrollArea + listas de terminal) para
     * uso táctil. Especialmente útil con monitores resistivos como el
     * 3nStar TCM008 que no soportan scroll por gesto y solo scrollean
     * tocando la barra lateral. Por defecto true cuando hardware==="tactil".
     */
    scrollbar_ancha?: boolean;
    /**
     * Activa el screensaver / overlay de bienvenida en la Terminal.
     * Cuando no hay interacción durante `screensaver_delay_ms`, se muestra
     * un overlay a pantalla completa con el mensaje `screensaver_texto`.
     * Objetivo: evitar que el usuario encuentre el monitor apagado sin
     * saber cómo prenderlo, manteniendo pixels vivos y dando una pista
     * visual clara de "toque para continuar".
     */
    screensaver_activo?: boolean;
    /** Milisegundos de inactividad antes de mostrar el overlay. Default 60000. */
    screensaver_delay_ms?: number;
    /** Texto del overlay. Default "¡BIENVENIDO/A! TOQUE LA PANTALLA PARA SOLICITAR SU/S LLAVES". */
    screensaver_texto?: string;
  };
}


/**
 * Configuración por defecto usada si `config.json` no se puede cargar
 * (por ejemplo en tests, o si el archivo está corrupto).
 * Equivalente al "modo desarrollo en 1 PC".
 */
export const DEFAULT_CONFIG: RuntimeConfig = {
  version: "2.0.0",
  modo: "desarrollo",
  rol: "monitor",
  hardware: "desarrollo",
  pocketbase_url: "http://127.0.0.1:8090",
  red: {
    ip_servidor: "127.0.0.1",
    ip_terminal_a: "127.0.0.1",
    ip_terminal_b: "127.0.0.1",
  },
  ui: {
    teclado_virtual_forzado: false,
    tema: "claro",
  },
};

let cachedConfig: RuntimeConfig | null = null;
let loadingPromise: Promise<RuntimeConfig> | null = null;

/**
 * Carga la configuración runtime. La primera vez hace fetch a `/config.json`;
 * las siguientes llamadas devuelven el resultado cacheado.
 */
export async function loadRuntimeConfig(): Promise<RuntimeConfig> {
  if (cachedConfig) return cachedConfig;
  if (loadingPromise) return loadingPromise;

  loadingPromise = (async () => {
    try {
      // Cache-busting con timestamp para que los cambios en config.json
      // se reflejen al recargar, incluso si el navegador cachea agresivamente.
      const response = await fetch(`/config.json?t=${Date.now()}`, {
        cache: "no-store",
      });

      if (!response.ok) {
        console.warn(
          `[runtimeConfig] No se pudo cargar /config.json (HTTP ${response.status}). Usando configuración por defecto.`,
        );
        cachedConfig = DEFAULT_CONFIG;
        return cachedConfig;
      }

      const raw = await response.json();
      // Eliminamos el campo _notas si está presente (es solo documentación inline).
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const { _notas, $schema, ...config } = raw;

      // Filtrar strings vacíos: la plantilla neutra en `public/config.json`
      // deja `rol` y `hardware` como "" para que un rebuild NO cocine
      // "monitor" ni "desarrollo" en el bundle. Si el instalador todavía
      // no reescribió el archivo (raro), preferimos caer al DEFAULT_CONFIG
      // en vez de mostrar UI con `rol=""` (sería "auto" y podría romper).
      const configLimpio: Record<string, unknown> = {};
      for (const [k, v] of Object.entries(config)) {
        if (v === "" || v === null || v === undefined) continue;
        configLimpio[k] = v;
      }

      cachedConfig = {
        ...DEFAULT_CONFIG,
        ...configLimpio,
        red: { ...DEFAULT_CONFIG.red, ...(config.red || {}) },
        ui: { ...DEFAULT_CONFIG.ui, ...(config.ui || {}) },
      } as RuntimeConfig;

      console.info(
        `[runtimeConfig] Configuración cargada: modo=${cachedConfig.modo}, rol=${cachedConfig.rol}, pb=${cachedConfig.pocketbase_url}`,
      );
      return cachedConfig;
    } catch (err) {
      console.error(
        "[runtimeConfig] Error cargando config.json, usando defaults:",
        err,
      );
      cachedConfig = DEFAULT_CONFIG;
      return cachedConfig;
    }
  })();

  return loadingPromise;
}

/**
 * Devuelve la configuración cargada de forma síncrona.
 * Solo seguro de usar DESPUÉS de que `loadRuntimeConfig()` haya resuelto
 * (por ejemplo, dentro de componentes React montados después del bootstrap).
 */
export function getRuntimeConfig(): RuntimeConfig {
  if (!cachedConfig) {
    console.warn(
      "[runtimeConfig] getRuntimeConfig() llamado antes de loadRuntimeConfig(). Devolviendo defaults.",
    );
    return DEFAULT_CONFIG;
  }
  return cachedConfig;
}
