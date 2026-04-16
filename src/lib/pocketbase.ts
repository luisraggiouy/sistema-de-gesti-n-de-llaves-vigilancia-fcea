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
  
  console.log('[PocketBase] Enviando solicitud con cabeceras CORS:', url);
  
  return { url, options };
};

pb.afterSend = (response, data) => {
  if (!response.ok && (response.status === 0 || response.status >= 500)) {
    // Connection issue detected
    useConnectionStore.getState().setConnected(false);
    startReconnectionAttempts();
  } else {
    useConnectionStore.getState().setConnected(true);
  }
  return data;
};

export default pb;
