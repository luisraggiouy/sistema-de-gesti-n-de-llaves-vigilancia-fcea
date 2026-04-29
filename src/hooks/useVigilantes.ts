import { useState, useCallback, useEffect } from 'react';
import { Vigilante, Turno, obtenerTurnoActual } from '@/data/fceaData';
import pb from '@/lib/pocketbase';

function obtenerTurnoAnterior(turnoActual: Turno): Turno {
  switch (turnoActual) {
    case 'Matutino': return 'Nocturno';
    case 'Vespertino': return 'Matutino';
    case 'Nocturno': return 'Vespertino';
  }
}

function obtenerHoraInicioTurno(turno: Turno): number {
  switch (turno) {
    case 'Matutino': return 6;
    case 'Vespertino': return 14;
    case 'Nocturno': return 22;
  }
}

export function useVigilantes() {
  const [vigilantes, setVigilantes] = useState<Vigilante[]>([]);

  const cargarVigilantes = useCallback(async () => {
    try {
      const records = await pb.collection('vigilante').getFullList({ sort: 'nombre' });
      const lista: Vigilante[] = records.map((r: any) => ({
        id: r.id,
        nombre: r.nombre,
        turno: r.turno as Turno,
        esJefe: r.es_jefe ?? false,
      }));
      setVigilantes(lista);
    } catch (e) {
      console.error('Error cargando vigilantes:', e);
    }
  }, []);

  useEffect(() => { cargarVigilantes(); }, [cargarVigilantes]);

  const agregarVigilante = useCallback(async (nombre: string, turno: Turno, esJefe: boolean = false) => {
    try {
      const record = await pb.collection('vigilante').create({ nombre, turno, es_jefe: esJefe });
      const nuevo: Vigilante = { id: record.id, nombre, turno, esJefe };
      setVigilantes(prev => [...prev, nuevo]);
      return nuevo;
    } catch (e) {
      console.error('Error agregando vigilante:', e);
    }
  }, []);

  const eliminarVigilante = useCallback(async (vigilanteId: string) => {
    try {
      await pb.collection('vigilante').delete(vigilanteId);
      setVigilantes(prev => prev.filter(v => v.id !== vigilanteId));
    } catch (e) {
      console.error('Error eliminando vigilante:', e);
    }
  }, []);

  const actualizarVigilante = useCallback(async (vigilanteId: string, datos: Partial<Omit<Vigilante, 'id'>>) => {
    try {
      await pb.collection('vigilante').update(vigilanteId, {
        nombre: datos.nombre,
        turno: datos.turno,
        es_jefe: datos.esJefe,
      });
      setVigilantes(prev => prev.map(v => v.id === vigilanteId ? { ...v, ...datos } : v));
    } catch (e) {
      console.error('Error actualizando vigilante:', e);
    }
  }, []);

  const obtenerVigilantesPorTurno = useCallback((turno: Turno) => {
    return vigilantes.filter(v => v.turno === turno);
  }, [vigilantes]);

  const obtenerVigilantesConTransicion = useCallback((transicionMinutos: number = 30) => {
    const ahora = new Date();
    const turnoActual = obtenerTurnoActual();
    const horaInicioTurno = obtenerHoraInicioTurno(turnoActual);
    const minutosHoy = ahora.getHours() * 60 + ahora.getMinutes();
    const minutosInicioTurno = horaInicioTurno * 60;
    let minutosEnTurno: number;
    if (turnoActual === 'Nocturno') {
      if (ahora.getHours() >= 22) {
        minutosEnTurno = minutosHoy - minutosInicioTurno;
      } else {
        minutosEnTurno = minutosHoy + (24 * 60 - minutosInicioTurno);
      }
    } else {
      minutosEnTurno = minutosHoy - minutosInicioTurno;
    }
    const vigilantesTurnoActual = vigilantes.filter(v => v.turno === turnoActual);
    if (minutosEnTurno < transicionMinutos) {
      const turnoAnterior = obtenerTurnoAnterior(turnoActual);
      const vigilantesTurnoAnterior = vigilantes.filter(v => v.turno === turnoAnterior);
      return { actuales: vigilantesTurnoActual, anteriores: vigilantesTurnoAnterior, enTransicion: true };
    }
    return { actuales: vigilantesTurnoActual, anteriores: [], enTransicion: false };
  }, [vigilantes]);

  const resetearVigilantes = useCallback(async () => {
    await cargarVigilantes();
  }, [cargarVigilantes]);

  return {
    vigilantes,
    agregarVigilante,
    eliminarVigilante,
    actualizarVigilante,
    obtenerVigilantesConTransicion,
    obtenerVigilantesPorTurno,
    resetearVigilantes,
  };
}
