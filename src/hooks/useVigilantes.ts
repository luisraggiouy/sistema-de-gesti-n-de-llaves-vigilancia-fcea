import { useState, useCallback, useEffect } from 'react';
import { Vigilante, Turno, EstadoLicencia, DiaSemana, obtenerTurnoActual } from '@/data/fceaData';
import pb from '@/lib/pocketbase';
import { registrarError } from '@/lib/errorLog';

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
      // v2.8.2 (2026-07-24): fix bug piloto FCEA donde tras agregar un
      // vigilante aparecia el toast "Vigilante agregado" pero NO se
      // veia en el listado del modal. Causas identificadas:
      //   1) El objeto local no incluia `estadoLicencia: 'activo'`, lo
      //      cual podia dejar filas "fantasma" segun como se renderize.
      //   2) Si el `create` de PocketBase devolvia un record con
      //      normalizacion (ej. turno en minusculas) o si tras cierto
      //      tiempo se recargaba desde el servidor, la fila quedaba
      //      fuera del filtro visual `v.turno === turno`.
      // Solucion: mapear el record del servidor con la MISMA logica que
      // `cargarVigilantes`, y forzar una recarga desde servidor como
      // fallback para garantizar consistencia visual.
      const record = await pb.collection('vigilante').create({ nombre, turno, es_jefe: esJefe });
      const nuevo: Vigilante = {
        id: record.id,
        nombre: (record as any).nombre ?? nombre,
        turno: ((record as any).turno as Turno) ?? turno,
        esJefe: (record as any).es_jefe ?? esJefe,
        estadoLicencia: ((record as any).estadoLicencia as EstadoLicencia) || 'activo',
        diasLaborales: (record as any).diasLaborales
          ? (typeof (record as any).diasLaborales === 'string'
              ? JSON.parse((record as any).diasLaborales)
              : (record as any).diasLaborales) as DiaSemana[]
          : undefined,
      };
      setVigilantes(prev => {
        // Evitar duplicados si por alguna razon ya estaba
        if (prev.some(v => v.id === nuevo.id)) return prev;
        return [...prev, nuevo];
      });
      return nuevo;
    } catch (e) {
      // v2.8.3 (2026-07-24 noche): BUG CRITICO detectado por auditoria.
      // Antes el catch se tragaba el error silenciosamente y el modal
      // creia que todo salio bien, mostrando toast VERDE de exito
      // cuando en realidad el vigilante NO se creo. Ahora:
      //   1) Registramos el error en errorLog para que aparezca en el
      //      DiagnosticoModal (Ctrl+Shift+D).
      //   2) Intentamos recargar la lista por si el create llego a
      //      persistir a pesar del error de red/respuesta.
      //   3) RE-LANZAMOS el error para que el modal (GuardManagementModal)
      //      lo capture en su try/catch y muestre el toast ROJO correcto.
      console.error('Error agregando vigilante:', e);
      registrarError('agregarVigilante', e);
      try { await cargarVigilantes(); } catch { /* noop */ }
      throw e;
    }
  }, [cargarVigilantes]);


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

    // Combina dos listas de vigilantes evitando duplicados (por id).
    const combinarSinDuplicados = (a: Vigilante[], b: Vigilante[]) => {
      const idsA = new Set(a.map(v => v.id));
      return [...a, ...b.filter(v => !idsA.has(v.id))];
    };

    // Excepción fija (upgrade 2026-09-03): entre las 05:50 y 05:59, aunque el
    // turno vigente siga siendo el Nocturno, también se muestran los vigilantes
    // del turno Matutino (turno entrante). Motivo: los del turno Matutino suelen
    // llegar ~5 minutos antes de las 6:00, mientras los del Nocturno ya se
    // retiraron o están en retirada, y hay que poder registrar entregas/devoluciones
    // con quien esté físicamente en la cabina. Este período NO es configurable.
    const enExcepcionMatutinoTemprano = turnoActual === 'Nocturno'
      && ahora.getHours() === 5
      && ahora.getMinutes() >= 50;

    if (minutosEnTurno < transicionMinutos) {
      const turnoAnterior = obtenerTurnoAnterior(turnoActual);
      let vigilantesAdicionales = soloActivos(vigilantes.filter(v => v.turno === turnoAnterior));
      if (enExcepcionMatutinoTemprano) {
        const vigilantesMatutino = soloActivos(vigilantes.filter(v => v.turno === 'Matutino'));
        vigilantesAdicionales = combinarSinDuplicados(vigilantesAdicionales, vigilantesMatutino);
      }
      return { actuales: vigilantesTurnoActual, anteriores: vigilantesAdicionales, enTransicion: true };
    }

    if (enExcepcionMatutinoTemprano) {
      const vigilantesMatutino = soloActivos(vigilantes.filter(v => v.turno === 'Matutino'));
      return { actuales: vigilantesTurnoActual, anteriores: vigilantesMatutino, enTransicion: true };
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
