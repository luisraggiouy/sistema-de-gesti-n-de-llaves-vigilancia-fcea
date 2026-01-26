import { useState, useCallback } from 'react';
import { SolicitudLlave, AccionUndo } from '@/types/solicitud';
import { lugares, Lugar } from '@/data/fceaData';

// Datos de demostración
const generarSolicitudesDemo = (): SolicitudLlave[] => {
  const lugaresDisponibles = lugares.filter(l => l.disponible);
  const tiposUsuario = ['Docente', 'Estudiante', 'Administrativo'] as const;
  const nombres = ['Prof. García', 'Est. Martínez', 'Lic. Rodríguez', 'Dr. Pérez', 'Est. Fernández'];
  
  return [
    {
      id: 's1',
      lugar: lugaresDisponibles[0],
      usuario: {
        nombre: nombres[0],
        celular: '099123456',
        tipo: tiposUsuario[0]
      },
      terminal: 'Terminal 1',
      horaSolicitud: new Date(Date.now() - 5 * 60000), // hace 5 min
      estado: 'pendiente'
    },
    {
      id: 's2',
      lugar: lugaresDisponibles[5],
      usuario: {
        nombre: nombres[1],
        celular: '098765432',
        tipo: tiposUsuario[1]
      },
      terminal: 'Terminal 1',
      horaSolicitud: new Date(Date.now() - 2 * 60000), // hace 2 min
      estado: 'pendiente'
    },
    {
      id: 's3',
      lugar: lugaresDisponibles[2],
      usuario: {
        nombre: nombres[2],
        celular: '097654321',
        tipo: tiposUsuario[2]
      },
      terminal: 'Terminal 2',
      horaSolicitud: new Date(Date.now() - 1 * 60000), // hace 1 min
      estado: 'pendiente'
    }
  ];
};

const UNDO_TIMEOUT_MS = 2 * 60 * 1000; // 2 minutos

export function useSolicitudes() {
  const [solicitudes, setSolicitudes] = useState<SolicitudLlave[]>(generarSolicitudesDemo);
  const [accionesUndo, setAccionesUndo] = useState<AccionUndo[]>([]);

  const solicitudesPendientes = solicitudes.filter(s => s.estado === 'pendiente');
  const solicitudesEntregadas = solicitudes.filter(s => s.estado === 'entregada');

  const entregarLlave = useCallback((solicitudId: string, vigilante: string) => {
    const now = new Date();
    
    setSolicitudes(prev => prev.map(s => 
      s.id === solicitudId 
        ? { ...s, estado: 'entregada' as const, horaEntrega: now, entregadoPor: vigilante }
        : s
    ));

    // Crear acción de undo
    const undoAction: AccionUndo = {
      id: `undo-${Date.now()}`,
      solicitudId,
      tipo: 'entrega',
      vigilante,
      timestamp: now,
      expiresAt: new Date(now.getTime() + UNDO_TIMEOUT_MS)
    };

    setAccionesUndo(prev => [...prev, undoAction]);

    // Auto-limpiar después de 2 minutos
    setTimeout(() => {
      setAccionesUndo(prev => prev.filter(a => a.id !== undoAction.id));
    }, UNDO_TIMEOUT_MS);

    return undoAction;
  }, []);

  const devolverLlave = useCallback((solicitudId: string, vigilante: string) => {
    const now = new Date();
    
    setSolicitudes(prev => prev.map(s => 
      s.id === solicitudId 
        ? { ...s, estado: 'devuelta' as const, horaDevolucion: now, recibidoPor: vigilante }
        : s
    ));

    // Crear acción de undo
    const undoAction: AccionUndo = {
      id: `undo-${Date.now()}`,
      solicitudId,
      tipo: 'devolucion',
      vigilante,
      timestamp: now,
      expiresAt: new Date(now.getTime() + UNDO_TIMEOUT_MS)
    };

    setAccionesUndo(prev => [...prev, undoAction]);

    setTimeout(() => {
      setAccionesUndo(prev => prev.filter(a => a.id !== undoAction.id));
    }, UNDO_TIMEOUT_MS);

    return undoAction;
  }, []);

  const deshacerAccion = useCallback((undoId: string) => {
    const accion = accionesUndo.find(a => a.id === undoId);
    if (!accion) return false;

    // Verificar que no haya expirado
    if (new Date() > accion.expiresAt) {
      setAccionesUndo(prev => prev.filter(a => a.id !== undoId));
      return false;
    }

    // Revertir la acción
    setSolicitudes(prev => prev.map(s => {
      if (s.id !== accion.solicitudId) return s;
      
      if (accion.tipo === 'entrega') {
        return { ...s, estado: 'pendiente' as const, horaEntrega: undefined, entregadoPor: undefined };
      } else {
        return { ...s, estado: 'entregada' as const, horaDevolucion: undefined, recibidoPor: undefined };
      }
    }));

    setAccionesUndo(prev => prev.filter(a => a.id !== undoId));
    return true;
  }, [accionesUndo]);

  const getUndoParaSolicitud = useCallback((solicitudId: string) => {
    return accionesUndo.find(a => a.solicitudId === solicitudId && new Date() < a.expiresAt);
  }, [accionesUndo]);

  const agregarSolicitud = useCallback((lugar: Lugar, usuario: { nombre: string; celular: string; tipo: string }) => {
    const nuevaSolicitud: SolicitudLlave = {
      id: `s${Date.now()}`,
      lugar,
      usuario: {
        nombre: usuario.nombre,
        celular: usuario.celular,
        tipo: usuario.tipo as any
      },
      terminal: 'Terminal 1',
      horaSolicitud: new Date(),
      estado: 'pendiente'
    };

    setSolicitudes(prev => [...prev, nuevaSolicitud]);
  }, []);

  return {
    solicitudes,
    solicitudesPendientes,
    solicitudesEntregadas,
    accionesUndo,
    entregarLlave,
    devolverLlave,
    deshacerAccion,
    getUndoParaSolicitud,
    agregarSolicitud
  };
}
