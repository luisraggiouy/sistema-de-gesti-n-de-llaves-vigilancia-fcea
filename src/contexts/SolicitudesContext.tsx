import React, { createContext, useContext, useState, useCallback, useEffect, useRef } from 'react';
import { SolicitudLlave, Lugar, ordenNatural } from '@/data/fceaData';
import pb, { useConnectionStore, startReconnectionAttempts } from '@/lib/pocketbase';
import { useToast } from '@/hooks/use-toast';

interface AccionUndo {
  id: string;
  solicitudId: string;
  tipo: 'entrega' | 'devolucion';
  vigilante: string;
  timestamp: Date;
  expiresAt: Date;
}

interface SolicitudesContextType {
  solicitudes: SolicitudLlave[];
  lugares: Lugar[];
  lugaresDisponibles: Lugar[];
  solicitudesPendientes: SolicitudLlave[];
  solicitudesEntregadas: SolicitudLlave[];
  solicitudesDevueltas: SolicitudLlave[];
  accionesUndo: AccionUndo[];
  isLoading: boolean;
  isConnected: boolean;
  lastUpdated: Date | null;
  agregarSolicitud: (solicitud: Omit<SolicitudLlave, 'id'>) => Promise<SolicitudLlave | undefined>;
  agregarSolicitudes: (lugares: Lugar[], usuario: { nombre: string; celular: string; tipo: string; departamento?: string; nombreEmpresa?: string }) => Promise<void>;
  actualizarSolicitud: (id: string, datos: Partial<SolicitudLlave>) => Promise<void>;
  eliminarSolicitud: (id: string) => Promise<void>;
  cargarSolicitudes: () => Promise<void>;
  cargarLugares: () => Promise<void>;
  refrescarDatos: () => Promise<void>;
  entregarLlave: (solicitudId: string, vigilante: string) => Promise<AccionUndo | undefined>;
  devolverLlave: (solicitudId: string, vigilante: string) => Promise<AccionUndo | undefined>;
  intercambiarLlave: (solicitudId: string, vigilante: string, nuevoUsuario: { nombre: string; celular: string; tipo: string }) => Promise<void>;
  intercambiarPorLugar: (lugarId: string, nuevoUsuario: { nombre: string; celular: string; tipo: string }) => boolean;
  deshacerAccion: (undoId: string) => boolean;
  getUndoParaSolicitud: (solicitudId: string) => AccionUndo | undefined;
  agregarLlave: (lugar: Lugar) => void;
  quitarLlave: (lugarId: string) => Promise<void>;
  modificarLlave: (lugarId: string, datos: Partial<Lugar>) => Promise<void>;
  actualizarNotas: (solicitudId: string, notas: string) => void;
}

const UNDO_TIMEOUT_MS = 2 * 60 * 1000;
const SolicitudesContext = createContext<SolicitudesContextType | undefined>(undefined);

export function SolicitudesProvider({ children }: { children: React.ReactNode }) {
  const { toast } = useToast();
  const [solicitudes, setSolicitudes] = useState<SolicitudLlave[]>([]);
  const [lugares, setLugares] = useState<Lugar[]>([]);
  const [accionesUndo, setAccionesUndo] = useState<AccionUndo[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const accionesUndoRef = useRef<AccionUndo[]>([]);
  const notasPendientesRef = useRef<Record<string, string>>({});
  const isBackgroundRefreshRef = useRef(false);
  const lugaresRef = useRef<Lugar[]>([]);
  
  // Get connection status from the store
  const isConnected = useConnectionStore(state => state.isConnected);
  const checkConnection = useConnectionStore(state => state.checkConnection);

  useEffect(() => {
    accionesUndoRef.current = accionesUndo;
  }, [accionesUndo]);
  
  // Monitor connection status - reconnect silently without spamming toasts
  const wasConnectedRef = useRef(true);
  const connectionLostTimerRef = useRef<NodeJS.Timeout | null>(null);
  
  useEffect(() => {
    if (!isConnected) {
      // Only show toast if we were previously connected AND it's been more than 10 seconds
      // This prevents toast spam when waking from sleep
      if (wasConnectedRef.current && !connectionLostTimerRef.current) {
        connectionLostTimerRef.current = setTimeout(() => {
          // Only show if still disconnected after 10 seconds
          if (!useConnectionStore.getState().isConnected) {
            toast({
              title: "Conexión perdida",
              description: "Intentando reconectar automáticamente...",
              variant: "destructive",
              duration: 5000,
            });
          }
          connectionLostTimerRef.current = null;
        }, 10000);
      }
      wasConnectedRef.current = false;
      startReconnectionAttempts();
    } else {
      // Clear the timer if we reconnected before 10 seconds
      if (connectionLostTimerRef.current) {
        clearTimeout(connectionLostTimerRef.current);
        connectionLostTimerRef.current = null;
      }
      wasConnectedRef.current = true;
    }
  }, [isConnected, toast]);

  const cargarLugares = useCallback(async () => {
    if (!isConnected) {
      await checkConnection();
      if (!isConnected) return;
    }
    
    // Only show loading indicator if this is not a background refresh
    if (!isBackgroundRefreshRef.current) {
      setIsLoading(true);
    }
    
    try {
      const records = await pb.collection('lugares').getFullList();
      const lista: Lugar[] = records.map((r: any) => ({
        id: r.id,
        nombre: r.nombre,
        tipo: r.tipo,
        disponible: r.disponible ?? true,
        edificio: r.edificio ?? '',
        tablero: r.tablero ?? 'Tablero Principal',
        ubicacion: { 
          zona: r.zona ?? 'Fondo', 
          fila: r.fila ? (typeof r.fila === 'string' ? parseInt(r.fila) : r.fila) : undefined, 
          columna: r.columna || undefined 
        },
        esHibrido: r.es_hibrido ?? false,
      }));
      lista.sort((a, b) => ordenNatural(a.nombre, b.nombre));
      setLugares(lista);
      lugaresRef.current = lista;
      setLastUpdated(new Date());
    } catch (e) {
      console.error('Error cargando lugares:', e);
      // No mostrar toast - las cargas automáticas fallan silenciosamente
      // El usuario verá el indicador de "sin conexión" si persiste
    } finally {
      if (!isBackgroundRefreshRef.current) {
        setIsLoading(false);
      }
    }
  }, [isConnected, checkConnection, toast]);

  const cargarSolicitudes = useCallback(async () => {
    if (!isConnected) {
      await checkConnection();
      if (!isConnected) return;
    }
    
    // Only show loading indicator if this is not a background refresh
    if (!isBackgroundRefreshRef.current) {
      setIsLoading(true);
    }
    
    try {
      const records = await pb.collection('solicitudes').getFullList({ sort: '-created' });
      const lista: SolicitudLlave[] = records.map((r: any) => {
        // Look up the actual lugar from loaded lugares to get full location data
        // Try by ID first, then by name as fallback (IDs may change after re-sync)
        const lugarReal = lugaresRef.current.find(l => l.id === r.lugar_id) 
          || lugaresRef.current.find(l => l.nombre === r.lugar_nombre);
        return {
        id: r.id,
        lugar: lugarReal ? { ...lugarReal, disponible: false } : {
          id: r.lugar_id ?? r.id,
          nombre: r.lugar_nombre ?? '',
          tipo: r.tipo_lugar ?? 'Salón',
          disponible: false,
          edificio: r.edificio ?? '',
          tablero: 'Tablero Principal' as const,
          ubicacion: { zona: 'Fondo' as const },
          esHibrido: false,
        },
        usuario: {
          nombre: r.usuario_nombre ?? '',
          celular: r.usuario_celular ?? '',
          tipo: r.tipo_usuario ?? 'Docente',
          departamento: r.departamento || undefined,
          nombreEmpresa: r.nombre_empresa || undefined,
        },
        terminal: r.terminal ?? 'terminal',
        horaSolicitud: r.hora_solicitud ? new Date(r.hora_solicitud) : new Date(),
        horaEntrega: r.hora_entrega ? new Date(r.hora_entrega) : undefined,
        horaDevolucion: r.hora_devolucion ? new Date(r.hora_devolucion) : undefined,
        entregadoPor: r.entregado_por || undefined,
        recibidoPor: r.recibido_por || undefined,
        estado: r.estado ?? 'pendiente',
        turno: r.turno,
        notas: notasPendientesRef.current[r.id] ?? r.notas ?? undefined,
        esIntercambio: r.es_intercambio ?? false,
        lugarId: r.lugar_id ?? '',
        // Load previous user information for exchanges
        usuarioAnterior: r.usuario_anterior_nombre ? {
          nombre: r.usuario_anterior_nombre,
          celular: r.usuario_anterior_celular || '',
          tipo: r.usuario_anterior_tipo || 'Empresa',
          departamento: r.usuario_anterior_departamento || undefined,
          nombreEmpresa: r.usuario_anterior_empresa || undefined
        } : undefined,
      }});
      setSolicitudes(lista);
      setLastUpdated(new Date());
    } catch (e) {
      console.error('Error cargando solicitudes:', e);
      // No mostrar toast - las cargas automáticas fallan silenciosamente
      // El sistema reintenta cada 3 segundos y se recupera solo
    } finally {
      if (!isBackgroundRefreshRef.current) {
        setIsLoading(false);
      }
    }
  }, [isConnected, checkConnection, toast]);
  
  // Function to refresh all data (manual refresh)
  const refrescarDatos = useCallback(async () => {
    if (isLoading) return; // Prevent multiple simultaneous refreshes
    
    // This is a manual refresh, not a background refresh
    isBackgroundRefreshRef.current = false;
    
    setIsLoading(true);
    try {
      await Promise.all([cargarLugares(), cargarSolicitudes()]);
      toast({
        title: "Datos actualizados",
        description: "Los datos se han actualizado correctamente",
      });
    } catch (error) {
      console.error('Error al refrescar datos:', error);
      toast({
        title: "Error al actualizar",
        description: "No se pudieron actualizar los datos",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  }, [cargarLugares, cargarSolicitudes, isLoading, toast]);

  useEffect(() => {
    // Initial load
    cargarLugares();
    cargarSolicitudes();
    
    // Track last successful poll time to detect sleep/wake
    let lastPollTime = Date.now();
    
    // Set up interval for background refresh
    const interval = setInterval(() => {
      const now = Date.now();
      const timeSinceLastPoll = now - lastPollTime;
      lastPollTime = now;
      
      // If more than 30 seconds passed since last poll, the PC was likely sleeping
      // In that case, do a silent full refresh instead of showing errors
      if (timeSinceLastPoll > 30000) {
        console.log('[Sistema] PC despertó de suspensión, reconectando silenciosamente...');
        isBackgroundRefreshRef.current = true;
        Promise.all([cargarLugares(), cargarSolicitudes()]).finally(() => {
          isBackgroundRefreshRef.current = false;
        });
        return;
      }
      
      isBackgroundRefreshRef.current = true;
      cargarSolicitudes().finally(() => {
        isBackgroundRefreshRef.current = false;
      });
    }, 3000);
    
    // Also handle visibility change (tab becomes visible again)
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible') {
        console.log('[Sistema] Pestaña visible, refrescando datos silenciosamente...');
        isBackgroundRefreshRef.current = true;
        Promise.all([cargarLugares(), cargarSolicitudes()]).finally(() => {
          isBackgroundRefreshRef.current = false;
        });
      }
    };
    document.addEventListener('visibilitychange', handleVisibilityChange);
    
    return () => {
      clearInterval(interval);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [cargarLugares, cargarSolicitudes]);

  const agregarSolicitud = useCallback(async (solicitud: Omit<SolicitudLlave, 'id'>) => {
    try {
      const record = await pb.collection('solicitudes').create({
        lugar_nombre: solicitud.lugar.nombre,
        lugar_id: solicitud.lugar.id,
        tipo_lugar: solicitud.lugar.tipo,
        usuario_nombre: solicitud.usuario.nombre,
        usuario_celular: solicitud.usuario.celular,
        tipo_usuario: solicitud.usuario.tipo,
        departamento: (solicitud.usuario as any).departamento ?? '',
        nombre_empresa: (solicitud.usuario as any).nombreEmpresa ?? '',
        estado: solicitud.estado,
        hora_solicitud: solicitud.horaSolicitud,
        hora_entrega: solicitud.horaEntrega ?? '',
        hora_devolucion: solicitud.horaDevolucion ?? '',
        entregado_por: solicitud.entregadoPor ?? '',
        recibido_por: solicitud.recibidoPor ?? '',
        turno: solicitud.turno ?? '',
        terminal: solicitud.terminal,
        es_intercambio: solicitud.esIntercambio ?? false,
      });
      const nueva: SolicitudLlave = { ...solicitud, id: record.id };
      setSolicitudes(prev => [nueva, ...prev]);
      return nueva;
    } catch (e) {
      console.error('Error agregando solicitud:', e);
    }
  }, []);

  const agregarSolicitudes = useCallback(async (
    lugaresSeleccionados: Lugar[],
    usuario: { nombre: string; celular: string; tipo: string; departamento?: string; nombreEmpresa?: string }
  ) => {
    for (const lugar of lugaresSeleccionados) {
      await agregarSolicitud({
        lugar,
        lugarId: lugar.id,
        usuario: { ...usuario, tipo: usuario.tipo as any },
        terminal: 'Terminal Usuario',
        horaSolicitud: new Date(),
        estado: 'pendiente',
        esIntercambio: false,
      });
    }
  }, [agregarSolicitud]);

  const actualizarSolicitud = useCallback(async (id: string, datos: Partial<SolicitudLlave>) => {
    try {
      const update: any = {};
      if (datos.estado !== undefined) update.estado = datos.estado;
      if (datos.horaEntrega !== undefined) update.hora_entrega = datos.horaEntrega;
      if (datos.horaDevolucion !== undefined) update.hora_devolucion = datos.horaDevolucion;
      if (datos.entregadoPor !== undefined) update.entregado_por = datos.entregadoPor;
      if (datos.recibidoPor !== undefined) update.recibido_por = datos.recibidoPor;
      if (datos.turno !== undefined) update.turno = datos.turno;
      if ((datos as any).notas !== undefined) update.notas = (datos as any).notas;
      if (datos.esIntercambio !== undefined) update.es_intercambio = datos.esIntercambio;
      if (datos.usuarioAnterior !== undefined) {
        update.usuario_anterior_nombre = datos.usuarioAnterior.nombre;
        update.usuario_anterior_celular = datos.usuarioAnterior.celular;
        update.usuario_anterior_tipo = datos.usuarioAnterior.tipo;
        update.usuario_anterior_departamento = datos.usuarioAnterior.departamento || '';
        update.usuario_anterior_empresa = datos.usuarioAnterior.nombreEmpresa || '';
      }
      if (datos.usuario !== undefined) {
        update.usuario_nombre = datos.usuario.nombre;
        update.usuario_celular = datos.usuario.celular;
        update.tipo_usuario = datos.usuario.tipo;
        update.departamento = (datos.usuario as any).departamento || '';
        update.nombre_empresa = (datos.usuario as any).nombreEmpresa || '';
      }
      await pb.collection('solicitudes').update(id, update);
      setSolicitudes(prev => prev.map(s => s.id === id ? { ...s, ...datos } : s));
    } catch (e) {
      console.error('Error actualizando solicitud:', e);
    }
  }, []);

  const eliminarSolicitud = useCallback(async (id: string) => {
    try {
      await pb.collection('solicitudes').delete(id);
      setSolicitudes(prev => prev.filter(s => s.id !== id));
    } catch (e) {
      console.error('Error eliminando solicitud:', e);
    }
  }, []);

  const crearUndo = (solicitudId: string, tipo: 'entrega' | 'devolucion', vigilante: string): AccionUndo => {
    const now = new Date();
    const undoAction: AccionUndo = {
      id: `undo-${Date.now()}`,
      solicitudId, tipo, vigilante, timestamp: now,
      expiresAt: new Date(now.getTime() + UNDO_TIMEOUT_MS),
    };
    setAccionesUndo(prev => [...prev, undoAction]);
    setTimeout(() => setAccionesUndo(prev => prev.filter(a => a.id !== undoAction.id)), UNDO_TIMEOUT_MS);
    return undoAction;
  };

  const entregarLlave = useCallback(async (solicitudId: string, vigilante: string) => {
    await actualizarSolicitud(solicitudId, { estado: 'entregada', horaEntrega: new Date(), entregadoPor: vigilante });
    return crearUndo(solicitudId, 'entrega', vigilante);
  }, [actualizarSolicitud]);

  const devolverLlave = useCallback(async (solicitudId: string, vigilante: string) => {
    await actualizarSolicitud(solicitudId, { estado: 'devuelta', horaDevolucion: new Date(), recibidoPor: vigilante });
    return crearUndo(solicitudId, 'devolucion', vigilante);
  }, [actualizarSolicitud]);

  const intercambiarLlave = useCallback(async (
    solicitudId: string,
    vigilante: string,
    nuevoUsuario: { nombre: string; celular: string; tipo: string }
  ) => {
    // Get the current solicitud to save the previous user info
    const solicitud = solicitudes.find(s => s.id === solicitudId);
    if (!solicitud) return;

    // Create update with exchange information
    const update: Partial<SolicitudLlave> = {
      usuario: { ...nuevoUsuario, tipo: nuevoUsuario.tipo as any },
      horaEntrega: new Date(),
      entregadoPor: vigilante,
      estado: 'entregada',
      esIntercambio: true,
      usuarioAnterior: {
        nombre: solicitud.usuario.nombre,
        celular: solicitud.usuario.celular,
        tipo: solicitud.usuario.tipo,
        departamento: solicitud.usuario.departamento,
        nombreEmpresa: solicitud.usuario.nombreEmpresa
      }
    };

    // Update the solicitud with exchange info
    await actualizarSolicitud(solicitudId, update);

    // Also update in PocketBase
    try {
      await pb.collection('solicitudes').update(solicitudId, {
        es_intercambio: true,
        usuario_anterior_nombre: solicitud.usuario.nombre,
        usuario_anterior_celular: solicitud.usuario.celular,
        usuario_anterior_tipo: solicitud.usuario.tipo,
        usuario_anterior_departamento: solicitud.usuario.departamento || '',
        usuario_anterior_empresa: solicitud.usuario.nombreEmpresa || ''
      });
    } catch (e) {
      console.error('Error updating exchange info in PocketBase:', e);
    }
  }, [solicitudes, actualizarSolicitud]);

  const intercambiarPorLugar = useCallback((
    lugarId: string,
    nuevoUsuario: { nombre: string; celular: string; tipo: string; departamento?: string; nombreEmpresa?: string }
  ): boolean => {
    const solicitud = solicitudes.find(s => s.lugar?.id === lugarId && s.estado === 'entregada');
    if (!solicitud) return false;
    
    // Guardar todos los datos del usuario anterior (quien tenía la llave)
    const update: Partial<SolicitudLlave> = {
      usuario: { ...nuevoUsuario, tipo: nuevoUsuario.tipo as any },
      horaEntrega: new Date(),
      entregadoPor: solicitud.usuario.nombre, // Siempre usar el nombre del usuario anterior
      estado: 'entregada',
      esIntercambio: true,
      usuarioAnterior: {
        nombre: solicitud.usuario.nombre,
        celular: solicitud.usuario.celular,
        tipo: solicitud.usuario.tipo,
        departamento: solicitud.usuario.departamento,
        nombreEmpresa: solicitud.usuario.nombreEmpresa
      }
    };
    
    actualizarSolicitud(solicitud.id, update);
    
    // Actualizar en PocketBase con todos los datos del usuario anterior
    try {
      pb.collection('solicitudes').update(solicitud.id, {
        es_intercambio: true,
        usuario_anterior_nombre: solicitud.usuario.nombre,
        usuario_anterior_celular: solicitud.usuario.celular,
        usuario_anterior_tipo: solicitud.usuario.tipo,
        usuario_anterior_departamento: solicitud.usuario.departamento || '',
        usuario_anterior_empresa: solicitud.usuario.nombreEmpresa || '',
        entregado_por: solicitud.usuario.nombre,
        usuario_nombre: nuevoUsuario.nombre,
        usuario_celular: nuevoUsuario.celular,
        tipo_usuario: nuevoUsuario.tipo,
        departamento: nuevoUsuario.departamento || '',
        nombre_empresa: nuevoUsuario.nombreEmpresa || '',
        hora_entrega: new Date(),
      });
    } catch (e) {
      console.error('Error updating exchange info in PocketBase:', e);
    }
    
    return true;
  }, [solicitudes, actualizarSolicitud]);

  const deshacerAccion = useCallback((undoId: string): boolean => {
    const accion = accionesUndoRef.current.find(a => a.id === undoId);
    if (!accion) return false;
    if (new Date() > accion.expiresAt) {
      setAccionesUndo(prev => prev.filter(a => a.id !== undoId));
      return false;
    }
    const revertido: Partial<SolicitudLlave> = accion.tipo === 'entrega'
      ? { estado: 'pendiente', horaEntrega: undefined, entregadoPor: undefined }
      : { estado: 'entregada', horaDevolucion: undefined, recibidoPor: undefined };
    actualizarSolicitud(accion.solicitudId, revertido);
    setAccionesUndo(prev => prev.filter(a => a.id !== undoId));
    return true;
  }, [actualizarSolicitud]);

  const getUndoParaSolicitud = useCallback((solicitudId: string) => {
    return accionesUndo.find(a => a.solicitudId === solicitudId && new Date() < a.expiresAt);
  }, [accionesUndo]);

  const agregarLlave = useCallback((lugar: Lugar) => {
    setLugares(prev =>
      prev.some(l => l.id === lugar.id)
        ? prev.map(l => l.id === lugar.id ? { ...l, disponible: true } : l)
        : [...prev, { ...lugar, disponible: true }]
    );
  }, []);

  const quitarLlave = useCallback(async (lugarId: string) => {
    try {
      await pb.collection('lugares').delete(lugarId);
    } catch (e) {
      console.error('Error eliminando lugar de PocketBase:', e);
    }
    setLugares(prev => prev.filter(l => l.id !== lugarId));
    lugaresRef.current = lugaresRef.current.filter(l => l.id !== lugarId);
  }, []);

  const modificarLlave = useCallback(async (lugarId: string, datos: Partial<Lugar>) => {
    try {
      const update: any = {};
      if (datos.nombre !== undefined) update.nombre = datos.nombre;
      if (datos.tipo !== undefined) update.tipo = datos.tipo;
      if (datos.edificio !== undefined) update.edificio = datos.edificio;
      if (datos.tablero !== undefined) update.tablero = datos.tablero;
      if (datos.esHibrido !== undefined) update.es_hibrido = datos.esHibrido;
      if (datos.ubicacion !== undefined) {
        update.zona = datos.ubicacion.zona;
        update.fila = datos.ubicacion.fila ?? '';
        update.columna = datos.ubicacion.columna ?? '';
      }
      await pb.collection('lugares').update(lugarId, update);
      setLugares(prev => prev.map(l => l.id === lugarId ? { ...l, ...datos } : l));
      lugaresRef.current = lugaresRef.current.map(l => l.id === lugarId ? { ...l, ...datos } : l);
    } catch (e) {
      console.error('Error modificando llave:', e);
      throw e;
    }
  }, []);

  const actualizarNotas = useCallback((solicitudId: string, notas: string) => {
    notasPendientesRef.current[solicitudId] = notas;
    setSolicitudes(prev => prev.map(s => s.id === solicitudId ? { ...s, notas } : s));
    pb.collection('solicitudes').update(solicitudId, { notas }).then(() => {
      delete notasPendientesRef.current[solicitudId];
    }).catch(console.error);
  }, []);

  const lugaresDisponibles = lugares.filter(l => l.disponible);
  const solicitudesPendientes = solicitudes.filter(s => s.estado === 'pendiente');
  const solicitudesEntregadas = solicitudes.filter(s => s.estado === 'entregada');
  const solicitudesDevueltas = solicitudes.filter(s => s.estado === 'devuelta');

  return (
    <SolicitudesContext.Provider value={{
      solicitudes, lugares, lugaresDisponibles,
      solicitudesPendientes, solicitudesEntregadas, solicitudesDevueltas,
      accionesUndo, isLoading, isConnected, lastUpdated,
      agregarSolicitud, agregarSolicitudes, actualizarSolicitud,
      eliminarSolicitud, cargarSolicitudes, cargarLugares, refrescarDatos,
      entregarLlave, devolverLlave, intercambiarLlave, intercambiarPorLugar, 
      deshacerAccion, getUndoParaSolicitud, agregarLlave, quitarLlave, modificarLlave, actualizarNotas,
    }}>
      {children}
    </SolicitudesContext.Provider>
  );
}

export function useSolicitudes() {
  const context = useContext(SolicitudesContext);
  if (!context) throw new Error('useSolicitudes debe usarse dentro de SolicitudesProvider');
  return context;
}

export { useSolicitudes as useSolicitudesContext };