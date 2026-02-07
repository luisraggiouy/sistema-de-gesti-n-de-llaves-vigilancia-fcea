import { createContext, useContext, useState, useCallback, ReactNode } from 'react';
import { SolicitudLlave, AccionUndo } from '@/types/solicitud';
import { lugares as lugaresIniciales, Lugar, obtenerTurnoActual } from '@/data/fceaData';
import { RegistroActividad } from '@/types/estadisticas';

const UNDO_TIMEOUT_MS = 2 * 60 * 1000; // 2 minutos
const LUGARES_STORAGE_KEY = 'fcea_lugares';
const REGISTROS_STORAGE_KEY = 'fcea_registros_actividad';

// Cargar lugares desde localStorage o usar los iniciales
const cargarLugares = (): Lugar[] => {
  try {
    const stored = localStorage.getItem(LUGARES_STORAGE_KEY);
    return stored ? JSON.parse(stored) : lugaresIniciales;
  } catch {
    return lugaresIniciales;
  }
};

// Cargar registros desde localStorage
const cargarRegistros = (): RegistroActividad[] => {
  try {
    const stored = localStorage.getItem(REGISTROS_STORAGE_KEY);
    if (stored) {
      const parsed = JSON.parse(stored);
      return parsed.map((r: any) => ({ ...r, timestamp: new Date(r.timestamp) }));
    }
    return [];
  } catch {
    return [];
  }
};

interface SolicitudesContextType {
  solicitudes: SolicitudLlave[];
  solicitudesPendientes: SolicitudLlave[];
  solicitudesEntregadas: SolicitudLlave[];
  solicitudesDevueltas: SolicitudLlave[];
  accionesUndo: AccionUndo[];
  lugaresDisponibles: Lugar[];
  registrosActividad: RegistroActividad[];
  entregarLlave: (solicitudId: string, vigilante: string) => AccionUndo;
  devolverLlave: (solicitudId: string, vigilante: string) => AccionUndo;
  intercambiarLlave: (solicitudId: string, vigilante: string, nuevoUsuario: { nombre: string; celular: string; tipo: string }) => void;
  intercambiarPorLugar: (lugarId: string, nuevoUsuario: { nombre: string; celular: string; tipo: string }) => boolean;
  deshacerAccion: (undoId: string) => boolean;
  getUndoParaSolicitud: (solicitudId: string) => AccionUndo | undefined;
  agregarSolicitud: (lugar: Lugar, usuario: { nombre: string; celular: string; tipo: string }) => void;
  agregarSolicitudes: (llaves: Lugar[], usuario: { nombre: string; celular: string; tipo: string }) => void;
  agregarLlave: (lugar: Omit<Lugar, 'id'>) => void;
  quitarLlave: (lugarId: string) => void;
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
const generarSolicitudesDemo = (lugares: Lugar[]): SolicitudLlave[] => {
  const lugaresDisponiblesDemo = lugares.filter(l => l.disponible);
  const tiposUsuario = ['Docente', 'Alumno', 'Personal TAS'] as const;
  const nombres = ['Prof. García', 'Est. Martínez', 'Lic. Rodríguez'];
  
  if (lugaresDisponiblesDemo.length < 6) return [];
  
  return [
    {
      id: 's1',
      lugar: lugaresDisponiblesDemo[0],
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
      lugar: lugaresDisponiblesDemo[5],
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
  const [lugaresDisponibles, setLugaresDisponibles] = useState<Lugar[]>(cargarLugares);
  const [solicitudes, setSolicitudes] = useState<SolicitudLlave[]>(() => generarSolicitudesDemo(cargarLugares()));
  const [accionesUndo, setAccionesUndo] = useState<AccionUndo[]>([]);
  const [registrosActividad, setRegistrosActividad] = useState<RegistroActividad[]>(cargarRegistros);

  const solicitudesPendientes = solicitudes.filter(s => s.estado === 'pendiente');
  const solicitudesEntregadas = solicitudes.filter(s => s.estado === 'entregada');
  const solicitudesDevueltas = solicitudes.filter(s => s.estado === 'devuelta');

  // Guardar lugares en localStorage cuando cambian
  const guardarLugares = useCallback((lugares: Lugar[]) => {
    localStorage.setItem(LUGARES_STORAGE_KEY, JSON.stringify(lugares));
  }, []);

  // Guardar registros en localStorage
  const guardarRegistros = useCallback((registros: RegistroActividad[]) => {
    localStorage.setItem(REGISTROS_STORAGE_KEY, JSON.stringify(registros));
  }, []);

  const agregarLlave = useCallback((lugar: Omit<Lugar, 'id'>) => {
    const nuevaLlave: Lugar = {
      ...lugar,
      id: `l${Date.now()}`,
    };
    setLugaresDisponibles(prev => {
      const updated = [...prev, nuevaLlave];
      guardarLugares(updated);
      return updated;
    });
  }, [guardarLugares]);

  const quitarLlave = useCallback((lugarId: string) => {
    setLugaresDisponibles(prev => {
      const updated = prev.filter(l => l.id !== lugarId);
      guardarLugares(updated);
      return updated;
    });
    // También quitar solicitudes pendientes de esa llave
    setSolicitudes(prev => prev.filter(s => s.lugar.id !== lugarId));
  }, [guardarLugares]);

  const entregarLlave = useCallback((solicitudId: string, vigilante: string) => {
    const now = new Date();
    const solicitud = solicitudes.find(s => s.id === solicitudId);
    
    setSolicitudes(prev => prev.map(s => 
      s.id === solicitudId 
        ? { ...s, estado: 'entregada' as const, horaEntrega: now, entregadoPor: vigilante }
        : s
    ));

    // Registrar actividad
    if (solicitud) {
      const registro: RegistroActividad = {
        id: `reg-${Date.now()}`,
        solicitudId,
        tipo: 'entrega',
        vigilante,
        turno: obtenerTurnoActual(),
        timestamp: now,
        lugarNombre: solicitud.lugar.nombre,
        usuarioNombre: solicitud.usuario.nombre
      };
      setRegistrosActividad(prev => {
        const updated = [...prev, registro];
        guardarRegistros(updated);
        return updated;
      });
    }

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
  }, [solicitudes, guardarRegistros]);

  const devolverLlave = useCallback((solicitudId: string, vigilante: string) => {
    const now = new Date();
    const solicitud = solicitudes.find(s => s.id === solicitudId);
    
    setSolicitudes(prev => prev.map(s => 
      s.id === solicitudId 
        ? { ...s, estado: 'devuelta' as const, horaDevolucion: now, recibidoPor: vigilante }
        : s
    ));

    // Registrar actividad
    if (solicitud) {
      const registro: RegistroActividad = {
        id: `reg-${Date.now()}-dev`,
        solicitudId,
        tipo: 'devolucion',
        vigilante,
        turno: obtenerTurnoActual(),
        timestamp: now,
        lugarNombre: solicitud.lugar.nombre,
        usuarioNombre: solicitud.usuario.nombre
      };
      setRegistrosActividad(prev => {
        const updated = [...prev, registro];
        guardarRegistros(updated);
        return updated;
      });
    }

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
  }, [solicitudes, guardarRegistros]);

  const intercambiarLlave = useCallback((solicitudId: string, vigilante: string, nuevoUsuario: { nombre: string; celular: string; tipo: string }) => {
    const now = new Date();
    const solicitud = solicitudes.find(s => s.id === solicitudId);
    if (!solicitud) return;

    // Marcar la solicitud actual como devuelta (intercambio)
    setSolicitudes(prev => {
      const updated = prev.map(s => 
        s.id === solicitudId 
          ? { ...s, estado: 'devuelta' as const, horaDevolucion: now, recibidoPor: vigilante }
          : s
      );

      // Crear nueva solicitud ya entregada para el nuevo usuario
      const nuevaSolicitud: SolicitudLlave = {
        id: `s${Date.now()}-int`,
        lugar: solicitud.lugar,
        usuario: {
          nombre: nuevoUsuario.nombre,
          celular: nuevoUsuario.celular,
          tipo: nuevoUsuario.tipo as any
        },
        terminal: solicitud.terminal,
        horaSolicitud: now,
        horaEntrega: now,
        entregadoPor: vigilante,
        estado: 'entregada',
        esIntercambio: true,
        usuarioAnterior: { ...solicitud.usuario }
      };

      return [...updated, nuevaSolicitud];
    });

    // Registrar actividad de intercambio
    const registro: RegistroActividad = {
      id: `reg-${Date.now()}-int`,
      solicitudId,
      tipo: 'devolucion',
      vigilante,
      turno: obtenerTurnoActual(),
      timestamp: now,
      lugarNombre: solicitud.lugar.nombre,
      usuarioNombre: `${solicitud.usuario.nombre} → ${nuevoUsuario.nombre} (intercambio)`
    };
    setRegistrosActividad(prev => {
      const updated = [...prev, registro];
      guardarRegistros(updated);
      return updated;
    });
  }, [solicitudes, guardarRegistros]);

  const intercambiarPorLugar = useCallback((lugarId: string, nuevoUsuario: { nombre: string; celular: string; tipo: string }) => {
    const solicitud = solicitudes.find(s => s.estado === 'entregada' && s.lugar.id === lugarId);
    if (!solicitud) return false;

    const now = new Date();

    setSolicitudes(prev => {
      const updated = prev.map(s => 
        s.id === solicitud.id 
          ? { ...s, estado: 'devuelta' as const, horaDevolucion: now, recibidoPor: 'Intercambio directo' }
          : s
      );

      const nuevaSolicitud: SolicitudLlave = {
        id: `s${Date.now()}-int`,
        lugar: solicitud.lugar,
        usuario: {
          nombre: nuevoUsuario.nombre,
          celular: nuevoUsuario.celular,
          tipo: nuevoUsuario.tipo as any
        },
        terminal: 'Terminal 1',
        horaSolicitud: now,
        horaEntrega: now,
        entregadoPor: 'Intercambio directo',
        estado: 'entregada',
        esIntercambio: true,
        usuarioAnterior: { ...solicitud.usuario }
      };

      return [...updated, nuevaSolicitud];
    });

    const registro: RegistroActividad = {
      id: `reg-${Date.now()}-int-t`,
      solicitudId: solicitud.id,
      tipo: 'devolucion',
      vigilante: 'Intercambio directo',
      turno: obtenerTurnoActual(),
      timestamp: now,
      lugarNombre: solicitud.lugar.nombre,
      usuarioNombre: `${solicitud.usuario.nombre} → ${nuevoUsuario.nombre} (intercambio terminal)`
    };
    setRegistrosActividad(prev => {
      const updated = [...prev, registro];
      guardarRegistros(updated);
      return updated;
    });

    return true;
  }, [solicitudes, guardarRegistros]);

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
      solicitudesDevueltas,
      accionesUndo,
      lugaresDisponibles,
      registrosActividad,
      entregarLlave,
      devolverLlave,
      intercambiarLlave,
      intercambiarPorLugar,
      deshacerAccion,
      getUndoParaSolicitud,
      agregarSolicitud,
      agregarSolicitudes,
      agregarLlave,
      quitarLlave
    }}>
      {children}
    </SolicitudesContext.Provider>
  );
}
