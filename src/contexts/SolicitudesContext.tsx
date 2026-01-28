import { createContext, useContext, useState, useCallback, ReactNode } from 'react';
import { SolicitudLlave, AccionUndo } from '@/types/solicitud';
import { lugares, Lugar } from '@/data/fceaData';

const UNDO_TIMEOUT_MS = 2 * 60 * 1000; // 2 minutos

interface SolicitudesContextType {
  solicitudes: SolicitudLlave[];
  solicitudesPendientes: SolicitudLlave[];
  solicitudesEntregadas: SolicitudLlave[];
  accionesUndo: AccionUndo[];
  entregarLlave: (solicitudId: string, vigilante: string) => AccionUndo;
  devolverLlave: (solicitudId: string, vigilante: string) => AccionUndo;
  deshacerAccion: (undoId: string) => boolean;
  getUndoParaSolicitud: (solicitudId: string) => AccionUndo | undefined;
  agregarSolicitud: (lugar: Lugar, usuario: { nombre: string; celular: string; tipo: string }) => void;
  agregarSolicitudes: (llaves: Lugar[], usuario: { nombre: string; celular: string; tipo: string }) => void;
}

const SolicitudesContext = createContext<SolicitudesContextType | null>(null);

export function useSolicitudesContext() {
  const context = useContext(SolicitudesContext);
  if (!context) {
    throw new Error('useSolicitudesContext debe usarse dentro de SolicitudesProvider');
  }
  return context;
}

// Datos de demostración inicial
const generarSolicitudesDemo = (): SolicitudLlave[] => {
  const lugaresDisponibles = lugares.filter(l => l.disponible);
  const tiposUsuario = ['Docente', 'Estudiante', 'Administrativo'] as const;
  const nombres = ['Prof. García', 'Est. Martínez', 'Lic. Rodríguez'];
  
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
      horaSolicitud: new Date(Date.now() - 5 * 60000),
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
      horaSolicitud: new Date(Date.now() - 2 * 60000),
      estado: 'pendiente'
    }
  ];
};

export function SolicitudesProvider({ children }: { children: ReactNode }) {
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

    const undoAction: AccionUndo = {
      id: `undo-${Date.now()}`,
      solicitudId,
      tipo: 'entrega',
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

  const devolverLlave = useCallback((solicitudId: string, vigilante: string) => {
    const now = new Date();
    
    setSolicitudes(prev => prev.map(s => 
      s.id === solicitudId 
        ? { ...s, estado: 'devuelta' as const, horaDevolucion: now, recibidoPor: vigilante }
        : s
    ));

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

    if (new Date() > accion.expiresAt) {
      setAccionesUndo(prev => prev.filter(a => a.id !== undoId));
      return false;
    }

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

  const agregarSolicitudes = useCallback((llaves: Lugar[], usuario: { nombre: string; celular: string; tipo: string }) => {
    const nuevasSolicitudes: SolicitudLlave[] = llaves.map((lugar, index) => ({
      id: `s${Date.now()}-${index}`,
      lugar,
      usuario: {
        nombre: usuario.nombre,
        celular: usuario.celular,
        tipo: usuario.tipo as any
      },
      terminal: 'Terminal 1',
      horaSolicitud: new Date(),
      estado: 'pendiente' as const
    }));

    setSolicitudes(prev => [...prev, ...nuevasSolicitudes]);
  }, []);

  return (
    <SolicitudesContext.Provider value={{
      solicitudes,
      solicitudesPendientes,
      solicitudesEntregadas,
      accionesUndo,
      entregarLlave,
      devolverLlave,
      deshacerAccion,
      getUndoParaSolicitud,
      agregarSolicitud,
      agregarSolicitudes
    }}>
      {children}
    </SolicitudesContext.Provider>
  );
}
