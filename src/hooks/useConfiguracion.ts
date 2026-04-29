import { useState, useCallback, useEffect } from 'react';
import pb from '@/lib/pocketbase';

interface Configuracion {
  tiempoAlertaMinutos: number;
  transicionTurnoMinutos: number;
  mensajeWhatsApp: string;
}

const CONFIG_DEFAULT: Configuracion = {
  tiempoAlertaMinutos: 135,
  transicionTurnoMinutos: 30,
  mensajeWhatsApp: 'Lo saludamos desde vigilancia de FCEA, tenemos en registro que usted tiene la llave de {{LLAVE}}. Le agradecemos si la puede devolver a la cabina de vigilancia. Muchas gracias y saludos cordiales.',
};

export function useConfiguracion() {
  const [configuracion, setConfiguracion] = useState<Configuracion>(CONFIG_DEFAULT);

  const cargarConfiguracion = useCallback(async () => {
    try {
      const records = await pb.collection('configuracion').getFullList();
      if (records.length > 0) {
        const config: Record<string, string> = {};
        records.forEach((r: any) => { config[r.clave as string] = r.valor as string; });
        setConfiguracion({
          tiempoAlertaMinutos: config['tiempoAlertaMinutos']
            ? Number(config['tiempoAlertaMinutos'])
            : CONFIG_DEFAULT.tiempoAlertaMinutos,
          transicionTurnoMinutos: config['transicionTurnoMinutos']
            ? Number(config['transicionTurnoMinutos'])
            : CONFIG_DEFAULT.transicionTurnoMinutos,
          mensajeWhatsApp: config['mensajeWhatsApp'] ?? CONFIG_DEFAULT.mensajeWhatsApp,
        });
      }
    } catch (e) {
      console.error('Error cargando configuracion:', e);
    }
  }, []);

  useEffect(() => {
    cargarConfiguracion();
    const interval = setInterval(cargarConfiguracion, 5000);
    return () => clearInterval(interval);
  }, [cargarConfiguracion]);

  const actualizarConfiguracion = useCallback(async (nuevaConfig: Partial<Configuracion>) => {
    try {
      const merged = { ...configuracion, ...nuevaConfig };
      const entries = Object.entries(merged) as [string, string | number][];
      for (const [key, val] of entries) {
        const existing = await pb.collection('configuracion').getFullList({
          filter: `clave = "${key}"`,
        });
        if (existing.length > 0) {
          await pb.collection('configuracion').update(existing[0].id, { valor: String(val) });
        } else {
          await pb.collection('configuracion').create({ clave: key, valor: String(val) });
        }
      }
      setConfiguracion(merged);
    } catch (e) {
      console.error('Error guardando configuracion:', e);
    }
  }, [configuracion]);

  const resetearConfiguracion = useCallback(async () => {
    await actualizarConfiguracion(CONFIG_DEFAULT);
  }, [actualizarConfiguracion]);

  return { configuracion, actualizarConfiguracion, resetearConfiguracion };
}