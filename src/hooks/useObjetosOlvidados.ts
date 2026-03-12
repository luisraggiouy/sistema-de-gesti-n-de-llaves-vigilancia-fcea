import { useState, useCallback } from 'react';
import { ObjetoOlvidado } from '@/types/objetoOlvidado';

const STORAGE_KEY = 'fcea_objetos_olvidados';

const normalizar = (texto: string): string =>
  texto.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();

const cargarObjetos = (): ObjetoOlvidado[] => {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      const parsed = JSON.parse(stored);
      return parsed.map((o: any) => ({
        ...o,
        fechaRegistro: new Date(o.fechaRegistro),
        devolucion: o.devolucion ? {
          ...o.devolucion,
          fecha: new Date(o.devolucion.fecha),
        } : undefined,
      }));
    }
    return [];
  } catch {
    return [];
  }
};

const guardarObjetos = (objetos: ObjetoOlvidado[]) => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(objetos));
};

export function useObjetosOlvidados() {
  const [objetos, setObjetos] = useState<ObjetoOlvidado[]>(cargarObjetos);

  const registrarObjeto = useCallback((objeto: Omit<ObjetoOlvidado, 'id' | 'estado' | 'fechaRegistro'>) => {
    const nuevo: ObjetoOlvidado = {
      ...objeto,
      id: `obj_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      fechaRegistro: new Date(),
      estado: 'custodia',
    };
    setObjetos(prev => {
      const updated = [nuevo, ...prev];
      guardarObjetos(updated);
      return updated;
    });
    return nuevo;
  }, []);

  const devolverObjeto = useCallback((objetoId: string, datos: {
    vigilanteEntrega: string;
    nombreReceptor: string;
    cedulaReceptor: string;
  }) => {
    setObjetos(prev => {
      const updated = prev.map(o =>
        o.id === objetoId
          ? {
              ...o,
              estado: 'devuelto' as const,
              devolucion: {
                fecha: new Date(),
                ...datos,
              },
            }
          : o
      );
      guardarObjetos(updated);
      return updated;
    });
  }, []);

  const buscarObjetos = useCallback((filtros: {
    texto?: string;
    lugar?: string;
    fechaDesde?: Date;
    fechaHasta?: Date;
    estado?: 'custodia' | 'devuelto' | 'todos';
  }) => {
    return objetos.filter(o => {
      if (filtros.texto) {
        const textoNorm = normalizar(filtros.texto);
        const descNorm = normalizar(o.descripcion);
        if (!descNorm.includes(textoNorm)) return false;
      }
      if (filtros.lugar) {
        const lugarNorm = normalizar(filtros.lugar);
        const objLugarNorm = normalizar(o.lugarEncontrado || '');
        if (!objLugarNorm.includes(lugarNorm)) return false;
      }
      if (filtros.fechaDesde) {
        const desde = new Date(filtros.fechaDesde);
        desde.setHours(0, 0, 0, 0);
        if (o.fechaRegistro < desde) return false;
      }
      if (filtros.fechaHasta) {
        const hasta = new Date(filtros.fechaHasta);
        hasta.setHours(23, 59, 59, 999);
        if (o.fechaRegistro > hasta) return false;
      }
      if (filtros.estado && filtros.estado !== 'todos') {
        if (o.estado !== filtros.estado) return false;
      }
      return true;
    });
  }, [objetos]);

  const objetosEnCustodia = objetos.filter(o => o.estado === 'custodia');
  const objetosDevueltos = objetos.filter(o => o.estado === 'devuelto');

  return {
    objetos,
    objetosEnCustodia,
    objetosDevueltos,
    registrarObjeto,
    devolverObjeto,
    buscarObjetos,
  };
}
