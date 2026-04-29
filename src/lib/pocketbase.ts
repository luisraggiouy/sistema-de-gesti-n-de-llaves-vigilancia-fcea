import PocketBase from 'pocketbase';
import { create } from 'zustand';

// Create a PocketBase instance
const pb = new PocketBase('http://127.0.0.1:8090');

// Disable auto cancellation for better control over requests
pb.autoCancellation(false);

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
let reconnectInterval: NodeJS.Timeout | null = null;

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

// Add error handler and CORS headers to prevent connection issues
pb.beforeSend = (url, options) => {
  // Configuración CORS para evitar problemas de cross-origin
  if (!options.headers) {
    options.headers = {};
  }
  
  // Añadir cabeceras CORS necesarias para cada solicitud
  options.headers = {
    ...options.headers,
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
  };
  
  return { url, options };
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
  } else {
    consecutiveFailures = 0;
    useConnectionStore.getState().setConnected(true);
  }
  return data;
};

export default pb;
