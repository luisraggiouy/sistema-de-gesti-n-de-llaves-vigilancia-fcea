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

      cachedConfig = {
        ...DEFAULT_CONFIG,
        ...config,
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
