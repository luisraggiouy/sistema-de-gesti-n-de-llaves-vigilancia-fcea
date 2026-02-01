import { useState, useEffect, useCallback } from 'react';
import { 
  ConfiguracionSistema, 
  CONFIGURACION_DEFAULT, 
  CONFIG_STORAGE_KEY 
} from '@/types/configuracion';

export function useConfiguracion() {
  const [configuracion, setConfiguracion] = useState<ConfiguracionSistema>(() => {
    try {
      const stored = localStorage.getItem(CONFIG_STORAGE_KEY);
      return stored ? { ...CONFIGURACION_DEFAULT, ...JSON.parse(stored) } : CONFIGURACION_DEFAULT;
    } catch {
      return CONFIGURACION_DEFAULT;
    }
  });

  const actualizarConfiguracion = useCallback((nuevaConfig: Partial<ConfiguracionSistema>) => {
    setConfiguracion(prev => {
      const updated = { ...prev, ...nuevaConfig };
      localStorage.setItem(CONFIG_STORAGE_KEY, JSON.stringify(updated));
      return updated;
    });
  }, []);

  const resetearConfiguracion = useCallback(() => {
    localStorage.removeItem(CONFIG_STORAGE_KEY);
    setConfiguracion(CONFIGURACION_DEFAULT);
  }, []);

  return {
    configuracion,
    actualizarConfiguracion,
    resetearConfiguracion
  };
}
