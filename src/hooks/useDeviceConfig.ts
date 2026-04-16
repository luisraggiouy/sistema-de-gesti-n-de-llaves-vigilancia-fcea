import { useMemo } from 'react';

export type DeviceType = 'monitor' | 'terminal' | 'auto';

interface DeviceConfig {
  deviceType: DeviceType;
  isProductionMode: boolean;
  deviceId?: string;
  shouldShowNavigationButtons: boolean;
  getDefaultRoute: () => string;
}

export function useDeviceConfig(): DeviceConfig {
  const config = useMemo((): DeviceConfig => {
    // Leer variables de entorno
    const deviceType = (import.meta.env.VITE_DEVICE_TYPE || 'auto') as DeviceType;
    const isProductionMode = import.meta.env.VITE_PRODUCTION_MODE === 'true';
    const deviceId = import.meta.env.VITE_DEVICE_ID;

    // Determinar si mostrar botones de navegación
    const shouldShowNavigationButtons = !isProductionMode;

    // Función para obtener la ruta por defecto
    const getDefaultRoute = (): string => {
      if (deviceType === 'monitor') {
        return '/monitor';
      } else if (deviceType === 'terminal') {
        return '/';
      } else {
        // Modo auto: detectar basado en la URL actual o localStorage
        const savedDeviceType = localStorage.getItem('deviceType');
        if (savedDeviceType === 'monitor') {
          return '/monitor';
        } else if (savedDeviceType === 'terminal') {
          return '/';
        }
        
        // Por defecto, ir a terminal de usuario
        return '/';
      }
    };

    return {
      deviceType,
      isProductionMode,
      deviceId,
      shouldShowNavigationButtons,
      getDefaultRoute,
    };
  }, []);

  return config;
}

// Función para guardar el tipo de dispositivo en localStorage (útil para modo auto)
export function setDeviceType(type: 'monitor' | 'terminal'): void {
  localStorage.setItem('deviceType', type);
}

// Función para detectar automáticamente el tipo de dispositivo basado en características del navegador/pantalla
export function detectDeviceType(): 'monitor' | 'terminal' {
  // Detectar basado en el tamaño de pantalla
  const screenWidth = window.screen.width;
  const screenHeight = window.screen.height;
  
  // Si la pantalla es muy grande, probablemente es el monitor de vigilancia
  if (screenWidth >= 1920 && screenHeight >= 1080) {
    return 'monitor';
  }
  
  // Si es una pantalla táctil, probablemente es una terminal
  if ('ontouchstart' in window || navigator.maxTouchPoints > 0) {
    return 'terminal';
  }
  
  // Por defecto, asumir que es terminal
  return 'terminal';
}