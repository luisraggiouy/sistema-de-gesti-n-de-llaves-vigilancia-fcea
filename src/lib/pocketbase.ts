import PocketBase from 'pocketbase';
import { create } from 'zustand';
import { DEFAULT_CONFIG, getRuntimeConfig, loadRuntimeConfig } from '@/lib/runtimeConfig';
import { registrarError } from '@/lib/errorLog';

/**
 * Cliente de PocketBase.
 *
 * La URL se determina en este orden:
 *   1. `getRuntimeConfig().pocketbase_url` si la configuración runtime ya fue cargada.
 *   2. `DEFAULT_CONFIG.pocketbase_url` (http://127.0.0.1:8090) como fallback temprano.
 *
 * Llamar a `applyRuntimePocketBaseUrl()` después de `loadRuntimeConfig()` para
 * que el cliente apunte al servidor correcto en las terminales remotas.
 */

// Arrancamos con el default; si runtimeConfig ya está cargado lo usamos.
let initialUrl = DEFAULT_CONFIG.pocketbase_url;
try {
  initialUrl = getRuntimeConfig().pocketbase_url;
} catch {
  // runtimeConfig todavía no cargó, usamos el default.
}

const pb = new PocketBase(initialUrl);

// Disable auto cancellation for better control over requests
pb.autoCancellation(false);

/**
 * Aplica la URL del runtime config al cliente PocketBase.
 * Debe llamarse desde el bootstrap de la aplicación, después de
 * `await loadRuntimeConfig()`.
 */
export async function applyRuntimePocketBaseUrl(): Promise<string> {
  const cfg = await loadRuntimeConfig();
  if (pb.baseUrl !== cfg.pocketbase_url) {
    pb.baseUrl = cfg.pocketbase_url;
    console.info(`[pocketbase] URL actualizada: ${cfg.pocketbase_url}`);
  }
  return cfg.pocketbase_url;
}

// Connection state store
interface ConnectionState {
  isConnected: boolean;
  lastChecked: Date;
  isChecking: boolean;
  checkConnection: () => Promise<boolean>;
  setConnected: (status: boolean) => void;
}

export const useConnectionStore = create<ConnectionState>((set, get) => ({
  isConnected: true, // Optimistically assume connected initially
  lastChecked: new Date(),
  isChecking: false,
  checkConnection: async () => {
    if (get().isChecking) return get().isConnected;

    set({ isChecking: true });

    try {
      // Try to make a simple request to check connection
      await pb.health.check();
      set({ isConnected: true, lastChecked: new Date(), isChecking: false });
      return true;
    } catch (error) {
      console.error('PocketBase connection check failed:', error);
      set({ isConnected: false, lastChecked: new Date(), isChecking: false });
      return false;
    }
  },
  setConnected: (status: boolean) => set({ isConnected: status, lastChecked: new Date() })
}));

// Add reconnection logic
let reconnectInterval: ReturnType<typeof setInterval> | null = null;

export const startReconnectionAttempts = () => {
  if (reconnectInterval) return; // Already trying to reconnect

  reconnectInterval = setInterval(async () => {
    const { isConnected, checkConnection } = useConnectionStore.getState();

    if (!isConnected) {
      const success = await checkConnection();
      if (success && reconnectInterval) {
        clearInterval(reconnectInterval);
        reconnectInterval = null;
      }
    } else if (reconnectInterval) {
      clearInterval(reconnectInterval);
      reconnectInterval = null;
    }
  }, 5000); // Try to reconnect every 5 seconds
};

// Track consecutive failures to avoid false disconnection on wake from sleep
let consecutiveFailures = 0;
const MAX_FAILURES_BEFORE_DISCONNECT = 3;

pb.afterSend = (response, data) => {
  if (!response.ok && (response.status === 0 || response.status >= 500)) {
    consecutiveFailures++;
    // Only mark as disconnected after 3 consecutive failures
    // This prevents false "connection lost" when waking from sleep
    if (consecutiveFailures >= MAX_FAILURES_BEFORE_DISCONNECT) {
      useConnectionStore.getState().setConnected(false);
      startReconnectionAttempts();
    }
    // Registrar cualquier error de red / 5xx en el errorLog
    // para que aparezca en el DiagnosticoModal (kioskos sin DevTools).
    try {
      registrarError('pb.afterSend', {
        status: response.status,
        url: response.url,
        message: `Fallo de red o servidor (${response.status})`,
        data,
      });
    } catch { /* nunca romper la respuesta */ }
  } else if (!response.ok) {
    // 4xx: NO es "desconectado" (el server contesta), pero es un error
    // real de la request (validacion, permisos, not found...) que hay
    // que capturar SI o SI para poder diagnosticarlo desde el kiosko.
    consecutiveFailures = 0;
    useConnectionStore.getState().setConnected(true);
    try {
      registrarError('pb.afterSend', {
        status: response.status,
        url: response.url,
        message: `Request rechazada (${response.status})`,
        data,
      });
    } catch { /* nunca romper la respuesta */ }
  } else {
    consecutiveFailures = 0;
    useConnectionStore.getState().setConnected(true);
  }
  return data;
};

export default pb;
