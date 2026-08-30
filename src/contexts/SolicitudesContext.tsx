import React, { createContext, useContext, useState, useCallback, useEffect, useRef } from 'react';
import { SolicitudLlave, Lugar, ordenNatural } from '@/data/fceaData';
import pb, { useConnectionStore, startReconnectionAttempts } from '@/lib/pocketbase';
import { useToast } from '@/hooks/use-toast';
import { registrarError } from '@/lib/errorLog';

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
  agregarLlave: (lugar: Omit<Lugar, 'id'>) => Promise<void>;
  quitarLlave: (lugarId: string) => Promise<void>;
  modificarLlave: (lugarId: string, datos: Partial<Lugar>) => Promise<void>;
  actualizarNotas: (solicitudId: string, notas: string) => void;
}

const UNDO_TIMEOUT_MS = 1 * 60 * 1000; // 1 minuto (bajado de 2 min el 2026-08-30)
const SolicitudesContext = createContext<SolicitudesContextType | undefined>(undefined);

// Mapea un record de la coleccion 'lugares' de PocketBase al tipo Lugar.
// Se reutiliza en la carga inicial (cargarLugares), en el alta optimista
// (agregarLlave) y en la suscripcion realtime, para que el mapeo sea unico
// y consistente en las tres rutas.
function mapLugarRecord(r: any): Lugar {
  const filaRaw = r.fila;
  const filaNum =
    filaRaw !== undefined && filaRaw !== null && filaRaw !== ''
      ? (typeof filaRaw === 'string' ? parseInt(filaRaw) : filaRaw)
      : undefined;
  return {
    id: r.id,
    nombre: r.nombre,
    tipo: r.tipo,
    disponible: r.disponible ?? true,
    edificio: r.edificio ?? '',
    tablero: r.tablero ?? 'Tablero Principal',
    ubicacion: {
      zona: r.zona ?? 'Fondo',
      fila: filaNum,
      columna: r.columna || undefined,
    },
    esHibrido: r.es_hibrido ?? false,
  };
}

// Inserta o reemplaza un lugar por id (upsert deduplicado) manteniendo el
// orden natural por nombre. Evita filas duplicadas cuando llega el "eco" del
// propio evento realtime tras un alta local (aprendizaje del FIX de
// duplicados de usuarios del 31/07).
function upsertLugar(lista: Lugar[], nuevo: Lugar): Lugar[] {
  const sinDup = lista.filter(l => l.id !== nuevo.id);
  sinDup.push(nuevo);
  sinDup.sort((a, b) => ordenNatural(a.nombre, b.nombre));
  return sinDup;
}

// Compara dos listas de lugares (ambas ordenadas por nombre) para decidir si
// vale la pena hacer setLugares. Lo usa el polling de respaldo de 3s para no
// generar re-renders/parpadeos cuando nada cambio.
function mismaListaLugares(a: Lugar[], b: Lugar[]): boolean {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    const x = a[i];
    const y = b[i];
    if (
      x.id !== y.id ||
      x.nombre !== y.nombre ||
      x.tipo !== y.tipo ||
      x.disponible !== y.disponible ||
      x.edificio !== y.edificio ||
      x.tablero !== y.tablero ||
      x.esHibrido !== y.esHibrido ||
      x.ubicacion.zona !== y.ubicacion.zona ||
      x.ubicacion.fila !== y.ubicacion.fila ||
      x.ubicacion.columna !== y.ubicacion.columna
    ) {
      return false;
    }
  }
  return true;
}

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

      const lista: Lugar[] = records.map(mapLugarRecord);
      lista.sort((a, b) => ordenNatural(a.nombre, b.nombre));
      // Solo actualizar el estado si la lista cambio de verdad. Asi el polling
      // de respaldo de 3s no genera re-renders/parpadeos innecesarios en las
      // terminales cuando no hubo altas/ediciones/bajas de llaves.
      if (!mismaListaLugares(lugaresRef.current, lista)) {
        setLugares(lista);
        lugaresRef.current = lista;
      }
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
        // Fix 2026-08-28: normalizar el espacio a "T" (igual que `created`) para
        // que new Date() parsee la fecha como UTC en todos los navegadores. Sin
        // esto, Edge/Chromium interpretaba "YYYY-MM-DD HH:MM:SSZ" como hora LOCAL
        // y aparecia un desfase de zona horaria (ej. "5 horas" en un intercambio).
        horaSolicitud: r.hora_solicitud ? new Date(String(r.hora_solicitud).replace(' ', 'T')) : new Date(),
        // `created` lo genera PocketBase (server = Monitor) al insertar. Es el
        // ancla confiable para el contador "cuanto hace que llego el pedido"
        // porque comparte reloj con el Date.now() del Monitor. PocketBase lo
        // devuelve como "YYYY-MM-DD HH:MM:SS.mmmZ" (con espacio): normalizamos
        // el espacio a "T" para que new Date() lo parsee como UTC en todos los
        // navegadores.
        horaCreacionServidor: r.created
          ? new Date(String(r.created).replace(' ', 'T'))
          : undefined,

        horaEntrega: r.hora_entrega ? new Date(String(r.hora_entrega).replace(' ', 'T')) : undefined,
        horaDevolucion: r.hora_devolucion ? new Date(String(r.hora_devolucion).replace(' ', 'T')) : undefined,
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
      // Red de seguridad (cinturon + tiradores): si el realtime de 'lugares'
      // se cayera, el polling igual re-sincroniza las llaves en <=3s.
      // cargarLugares solo hace setLugares si la lista realmente cambio.
      Promise.all([cargarSolicitudes(), cargarLugares()]).finally(() => {
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

  // Suscripcion realtime a la coleccion 'lugares' (mismo mecanismo SSE de
  // PocketBase ya probado y funcionando en produccion para usuarios). Propaga
  // en vivo a Terminal A/B y Monitor las altas (create), ediciones (update) y
  // bajas (delete) de llaves. Antes 'lugares' no tenia ni realtime ni polling,
  // por eso una llave nueva creada en el Monitor no aparecia en las terminales.
  // Usa upsert/borrado deduplicado por id para que el "eco" del propio evento
  // no duplique filas.
  useEffect(() => {
    let unsub: (() => void) | undefined;

    (async () => {
      try {
        unsub = await pb.collection('lugares').subscribe('*', (e: any) => {
          if (e.action === 'delete') {
            setLugares(prev => prev.filter(l => l.id !== e.record.id));
            lugaresRef.current = lugaresRef.current.filter(l => l.id !== e.record.id);
          } else {
            // create | update -> upsert deduplicado por id
            const lugar = mapLugarRecord(e.record);
            setLugares(prev => upsertLugar(prev, lugar));
            lugaresRef.current = upsertLugar(lugaresRef.current, lugar);
          }
          setLastUpdated(new Date());
        });
      } catch (err) {
        console.error('Error suscribiendo a lugares (se usara el polling de respaldo de 3s):', err);
      }
    })();

    return () => {
      try {
        if (unsub) {
          unsub();
        } else {
          pb.collection('lugares').unsubscribe('*');
        }
      } catch {
        /* noop */
      }
    };
  }, []);

  const agregarSolicitud = useCallback(async (solicitud: Omit<SolicitudLlave, 'id'>) => {
    // Payload minimo garantizado (solo campos que sabemos existen en el schema
    // original de la coleccion). Los campos "extra" (departamento, nombre_empresa,
    // es_intercambio) se agregan en un segundo intento como update, para evitar
    // que un schema desactualizado en el servidor rechace el CREATE completo
    // con 400 (validation error) y perdamos la solicitud en silencio.
    const payloadBase: Record<string, unknown> = {
      lugar_nombre: solicitud.lugar.nombre,
      lugar_id: solicitud.lugar.id,
      tipo_lugar: solicitud.lugar.tipo,
      usuario_nombre: solicitud.usuario.nombre,
      usuario_celular: solicitud.usuario.celular,
      tipo_usuario: solicitud.usuario.tipo,
      estado: solicitud.estado,
      // hora_solicitud es TEXT en el schema: mandarlo como ISO string
      hora_solicitud:
        solicitud.horaSolicitud instanceof Date
          ? solicitud.horaSolicitud.toISOString()
          : (solicitud.horaSolicitud ?? new Date().toISOString()),
      hora_entrega:
        solicitud.horaEntrega instanceof Date
          ? solicitud.horaEntrega.toISOString()
          : (solicitud.horaEntrega ?? ''),
      hora_devolucion:
        solicitud.horaDevolucion instanceof Date
          ? solicitud.horaDevolucion.toISOString()
          : (solicitud.horaDevolucion ?? ''),
      entregado_por: solicitud.entregadoPor ?? '',
      recibido_por: solicitud.recibidoPor ?? '',
      turno: solicitud.turno ?? '',
      terminal: solicitud.terminal,
    };
    const camposExtra: Record<string, unknown> = {
      departamento: (solicitud.usuario as any).departamento ?? '',
      nombre_empresa: (solicitud.usuario as any).nombreEmpresa ?? '',
      es_intercambio: solicitud.esIntercambio ?? false,
    };

    try {
      // Intento 1: crear con TODOS los campos (rapido si el schema esta al dia).
      const record = await pb.collection('solicitudes').create({
        ...payloadBase,
        ...camposExtra,
      });
      const nueva: SolicitudLlave = { ...solicitud, id: record.id };
      setSolicitudes(prev => [nueva, ...prev]);
      return nueva;
    } catch (e: any) {
      // Si el server rechaza por schema (400) reintentamos con payload minimo.
      const status = e?.status;
      registrarError('agregarSolicitud.intento1', e);
      if (status === 400) {
        try {
          const record = await pb.collection('solicitudes').create(payloadBase);
          // Intento a posteriori guardar los extras (best-effort).
          try {
            await pb.collection('solicitudes').update(record.id, camposExtra);
          } catch (eExtra) {
            registrarError('agregarSolicitud.updateExtras', eExtra);
          }
          const nueva: SolicitudLlave = { ...solicitud, id: record.id };
          setSolicitudes(prev => [nueva, ...prev]);
          toast({
            title: 'Solicitud registrada (modo compatibilidad)',
            description:
              'El servidor tiene un schema viejo. Se guardaron los datos basicos; actualice el schema para incluir todos los campos.',
          });
          return nueva;
        } catch (e2) {
          registrarError('agregarSolicitud.intento2', e2);
        }
      }
      // Fallo definitivo: avisar al usuario. Antes fallaba silencioso y el
      // pedido nunca aparecia en el Monitor.
      toast({
        title: 'No se pudo registrar la solicitud',
        description:
          'La terminal no pudo guardar el pedido en el servidor. Avise a un vigilante. Detalles en Diagnostico (Ctrl+Shift+D).',
        variant: 'destructive',
        duration: 10000,
      });
      return undefined;
    }
  }, [toast]);

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
      // Fix 2026-08-28: guardar SIEMPRE como ISO string. El campo es TEXT en
      // PocketBase; si se manda un objeto Date crudo, se serializa en un formato
      // ambiguo/local y al releerlo aparecia un desfase de zona horaria (ej. el
      // contador mostraba "5 horas" tras un F5 luego de un intercambio).
      if (datos.horaEntrega !== undefined)
        update.hora_entrega = datos.horaEntrega instanceof Date ? datos.horaEntrega.toISOString() : datos.horaEntrega;
      if (datos.horaDevolucion !== undefined)
        update.hora_devolucion = datos.horaDevolucion instanceof Date ? datos.horaDevolucion.toISOString() : datos.horaDevolucion;
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
    // Verificar si existe un undo activo para esta solicitud
    const undoExistente = accionesUndoRef.current.find(a => a.solicitudId === solicitudId);
    
    // Si existe un undo activo de entrega, eliminarlo (la devolución es la acción final)
    if (undoExistente) {
      setAccionesUndo(prev => prev.filter(a => a.solicitudId !== solicitudId));
    }
    
    await actualizarSolicitud(solicitudId, { estado: 'devuelta', horaDevolucion: new Date(), recibidoPor: vigilante });
    
    // NO crear nuevo undo para devoluciones - la devolución es la acción final
    return undefined;
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
        // Fix 2026-08-28: guardar como ISO string (campo TEXT en PocketBase).
        hora_entrega: new Date().toISOString(),
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

  const agregarLlave = useCallback(async (lugar: Omit<Lugar, 'id'>) => {
    try {
      const record = await pb.collection('lugares').create({
        nombre: lugar.nombre,
        tipo: lugar.tipo,
        edificio: lugar.edificio,
        tablero: lugar.tablero ?? 'Tablero Principal',
        zona: lugar.ubicacion.zona,
        fila: lugar.ubicacion.fila ?? '',
        columna: lugar.ubicacion.columna ?? '',
        disponible: true,
        es_hibrido: lugar.esHibrido ?? false,
      });
      // Alta optimista para que el Monitor que ejecuta la accion vea la llave
      // al instante. El upsert por id evita duplicar cuando llegue el eco del
      // evento realtime 'create'.
      const nuevaLlave: Lugar = mapLugarRecord(record);
      setLugares(prev => upsertLugar(prev, nuevaLlave));
      lugaresRef.current = upsertLugar(lugaresRef.current, nuevaLlave);
    } catch (e) {
      console.error('Error agregando llave a PocketBase:', e);
      throw e;
    }
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