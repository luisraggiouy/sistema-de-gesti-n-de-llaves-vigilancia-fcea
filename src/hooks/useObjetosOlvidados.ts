import { useState, useCallback, useEffect } from 'react';
import { ObjetoOlvidado } from '@/types/objetoOlvidado';
import pb from '@/lib/pocketbase';

const normalizar = (texto: string): string =>
  texto.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();

const mapRecord = (r: any): ObjetoOlvidado => ({
  id: r.id,
  descripcion: r.descripcion,
  lugarEncontrado: r.lugar_encontrado ?? '',
  registradoPor: r.registrado_por ?? '',
  fechaRegistro: r.fecha_registro ? new Date(r.fecha_registro) : new Date(r.created),
  estado: r.estado ?? 'custodia',
  fotos: {
    general: r.foto_general ?? '',
    marca: r.foto_marca ?? '',
    adicional: r.foto_adicional || undefined,
  },
  devolucion: r.devolucion_fecha
    ? {
        fecha: new Date(r.devolucion_fecha),
        vigilanteEntrega: r.devolucion_vigilante ?? '',
        nombreReceptor: r.devolucion_receptor ?? '',
        cedulaReceptor: r.devolucion_cedula ?? '',
      }
    : undefined,
});

export function useObjetosOlvidados() {
  const [objetos, setObjetos] = useState<ObjetoOlvidado[]>([]);

  const cargar = useCallback(async () => {
    try {
      const records = await pb.collection('objetos_olvidados').getFullList({ sort: '-created' });
      setObjetos(records.map(mapRecord));
    } catch (e) {
      console.error('Error cargando objetos olvidados:', e);
    }
  }, []);

  useEffect(() => {
    cargar();
  }, [cargar]);

  const registrarObjeto = useCallback(async (
    objeto: Omit<ObjetoOlvidado, 'id' | 'estado' | 'fechaRegistro'>
  ) => {
    try {
      const record = await pb.collection('objetos_olvidados').create({
        descripcion: objeto.descripcion,
        lugar_encontrado: objeto.lugarEncontrado ?? '',
        registrado_por: objeto.registradoPor ?? '',
        fecha_registro: new Date().toISOString(),
        estado: 'custodia',
        foto_general: objeto.fotos?.general ?? '',
        foto_marca: objeto.fotos?.marca ?? '',
        foto_adicional: objeto.fotos?.adicional ?? '',
      });
      const nuevo = mapRecord(record);
      setObjetos(prev => [nuevo, ...prev]);
      return nuevo;
    } catch (e) {
      console.error('Error registrando objeto:', e);
    }
  }, []);

  const devolverObjeto = useCallback(async (objetoId: string, datos: {
    vigilanteEntrega: string;
    nombreReceptor: string;
    cedulaReceptor: string;
  }) => {
    try {
      const now = new Date().toISOString();
      await pb.collection('objetos_olvidados').update(objetoId, {
        estado: 'devuelto',
        devolucion_fecha: now,
        devolucion_vigilante: datos.vigilanteEntrega,
        devolucion_receptor: datos.nombreReceptor,
        devolucion_cedula: datos.cedulaReceptor,
      });
      setObjetos(prev => prev.map(o =>
        o.id === objetoId
          ? { ...o, estado: 'devuelto' as const, devolucion: { fecha: new Date(now), ...datos } }
          : o
      ));
    } catch (e) {
      console.error('Error devolviendo objeto:', e);
    }
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
        if (!normalizar(o.descripcion).includes(normalizar(filtros.texto))) return false;
      }
      if (filtros.lugar) {
        if (!normalizar(o.lugarEncontrado || '').includes(normalizar(filtros.lugar))) return false;
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