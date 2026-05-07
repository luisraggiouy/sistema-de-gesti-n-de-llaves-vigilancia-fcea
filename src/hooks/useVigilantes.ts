import { useState, useCallback, useEffect } from 'react';
import { Vigilante, Turno, EstadoLicencia, DiaSemana, obtenerTurnoActual } from '@/data/fceaData';
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
        estadoLicencia: (r.estadoLicencia as EstadoLicencia) || 'activo',
        // diasLaborales: array JSON guardado en PocketBase; null/vacío → trabaja todos los días
        diasLaborales: r.diasLaborales
          ? (typeof r.diasLaborales === 'string'
              ? JSON.parse(r.diasLaborales)
              : r.diasLaborales) as DiaSemana[]
          : undefined,
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
      // Construir objeto de actualización solo con campos definidos
      const payload: Record<string, unknown> = {};
      if (datos.nombre !== undefined) payload.nombre = datos.nombre;
      if (datos.turno !== undefined) payload.turno = datos.turno;
      if (datos.esJefe !== undefined) payload.es_jefe = datos.esJefe;
      // estadoLicencia se guarda en PocketBase para que persista entre recargas
      if (datos.estadoLicencia !== undefined) payload.estadoLicencia = datos.estadoLicencia;
      // diasLaborales se guarda como JSON string en PocketBase
      if (datos.diasLaborales !== undefined) {
        payload.diasLaborales = datos.diasLaborales && datos.diasLaborales.length > 0
          ? JSON.stringify(datos.diasLaborales)
          : null;
      }

      await pb.collection('vigilante').update(vigilanteId, payload);
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
    // Solo vigilantes ACTIVOS aparecen en botones de entrega/devolución
    const soloActivos = (lista: Vigilante[]) => lista.filter(v => !v.estadoLicencia || v.estadoLicencia === 'activo');

    const vigilantesTurnoActual = soloActivos(vigilantes.filter(v => v.turno === turnoActual));
    if (minutosEnTurno < transicionMinutos) {
      const turnoAnterior = obtenerTurnoAnterior(turnoActual);
      const vigilantesTurnoAnterior = soloActivos(vigilantes.filter(v => v.turno === turnoAnterior));
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
