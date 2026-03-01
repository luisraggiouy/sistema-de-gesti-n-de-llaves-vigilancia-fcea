import { useState, useCallback } from 'react';
import { Vigilante, Turno, vigilantes as vigilantesIniciales, obtenerTurnoActual } from '@/data/fceaData';
import { VIGILANTES_STORAGE_KEY } from '@/types/configuracion';

// Cargar vigilantes desde localStorage o usar los iniciales
const cargarVigilantes = (): Vigilante[] => {
  try {
    const stored = localStorage.getItem(VIGILANTES_STORAGE_KEY);
    return stored ? JSON.parse(stored) : vigilantesIniciales;
  } catch {
    return vigilantesIniciales;
  }
};

// Obtener turno anterior
function obtenerTurnoAnterior(turnoActual: Turno): Turno {
  switch (turnoActual) {
    case 'Matutino': return 'Nocturno';
    case 'Vespertino': return 'Matutino';
    case 'Nocturno': return 'Vespertino';
  }
}

// Obtener hora de inicio del turno actual
function obtenerHoraInicioTurno(turno: Turno): number {
  switch (turno) {
    case 'Matutino': return 6;
    case 'Vespertino': return 14;
    case 'Nocturno': return 22;
  }
}

export function useVigilantes() {
  const [vigilantes, setVigilantes] = useState<Vigilante[]>(cargarVigilantes);

  // Guardar vigilantes en localStorage
  const guardarVigilantes = useCallback((nuevosVigilantes: Vigilante[]) => {
    localStorage.setItem(VIGILANTES_STORAGE_KEY, JSON.stringify(nuevosVigilantes));
  }, []);

  // Agregar vigilante
  const agregarVigilante = useCallback((nombre: string, turno: Turno, esJefe: boolean = false) => {
    const nuevoVigilante: Vigilante = {
      id: `v${Date.now()}`,
      nombre,
      turno,
      esJefe
    };
    setVigilantes(prev => {
      const updated = [...prev, nuevoVigilante];
      guardarVigilantes(updated);
      return updated;
    });
    return nuevoVigilante;
  }, [guardarVigilantes]);

  // Eliminar vigilante
  const eliminarVigilante = useCallback((vigilanteId: string) => {
    setVigilantes(prev => {
      const updated = prev.filter(v => v.id !== vigilanteId);
      guardarVigilantes(updated);
      return updated;
    });
  }, [guardarVigilantes]);

  // Actualizar vigilante
  const actualizarVigilante = useCallback((vigilanteId: string, datos: Partial<Omit<Vigilante, 'id'>>) => {
    setVigilantes(prev => {
      const updated = prev.map(v => 
        v.id === vigilanteId ? { ...v, ...datos } : v
      );
      guardarVigilantes(updated);
      return updated;
    });
  }, [guardarVigilantes]);

  // Obtener vigilantes del turno actual + turno anterior en período de transición
  const obtenerVigilantesConTransicion = useCallback((transicionMinutos: number = 30) => {
    const ahora = new Date();
    const turnoActual = obtenerTurnoActual();
    const horaInicioTurno = obtenerHoraInicioTurno(turnoActual);
    
    // Calcular minutos desde inicio del turno
    const minutosHoy = ahora.getHours() * 60 + ahora.getMinutes();
    const minutosInicioTurno = horaInicioTurno * 60;
    
    // Manejar caso especial del turno nocturno (cruza medianoche)
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

    // Vigilantes del turno actual (solo activos, sin licencia)
    const vigilantesTurnoActual = vigilantes.filter(v => v.turno === turnoActual && (!v.estadoLicencia || v.estadoLicencia === 'activo'));
    
    // Si estamos en período de transición, incluir vigilantes del turno anterior
    if (minutosEnTurno < transicionMinutos) {
      const turnoAnterior = obtenerTurnoAnterior(turnoActual);
      const vigilantesTurnoAnterior = vigilantes.filter(v => v.turno === turnoAnterior && (!v.estadoLicencia || v.estadoLicencia === 'activo'));
      return {
        actuales: vigilantesTurnoActual,
        anteriores: vigilantesTurnoAnterior,
        enTransicion: true
      };
    }

    return {
      actuales: vigilantesTurnoActual,
      anteriores: [],
      enTransicion: false
    };
  }, [vigilantes]);

  // Obtener vigilantes por turno
  const obtenerVigilantesPorTurno = useCallback((turno: Turno) => {
    return vigilantes.filter(v => v.turno === turno);
  }, [vigilantes]);

  // Resetear a vigilantes por defecto
  const resetearVigilantes = useCallback(() => {
    localStorage.removeItem(VIGILANTES_STORAGE_KEY);
    setVigilantes(vigilantesIniciales);
  }, []);

  return {
    vigilantes,
    agregarVigilante,
    eliminarVigilante,
    actualizarVigilante,
    obtenerVigilantesConTransicion,
    obtenerVigilantesPorTurno,
    resetearVigilantes
  };
}
