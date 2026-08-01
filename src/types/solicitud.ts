import { TipoUsuario, Lugar } from '@/data/fceaData';

export type EstadoSolicitud = 'pendiente' | 'entregada' | 'devuelta';

export interface SolicitudLlave {
  id: string;
  lugar: Lugar;
  usuario: {
    nombre: string;
    celular: string;
    tipo: TipoUsuario;
    departamento?: string;
    nombreEmpresa?: string;
  };
  terminal: string;
  horaSolicitud: Date;
  // Timestamp que genera PocketBase (campo `created`) al insertar el registro.
  // Como PocketBase corre EN el Monitor, este timestamp usa el MISMO reloj que
  // el Monitor usa para pintar el contador -> elimina cualquier desfase de
  // zona horaria / reloj entre la Terminal y el Monitor. Es el ancla preferida
  // para calcular "cuanto hace que llego el pedido".
  horaCreacionServidor?: Date;
  horaEntrega?: Date;
  horaDevolucion?: Date;
  entregadoPor?: string;
  recibidoPor?: string;
  estado: EstadoSolicitud;
  // Intercambio entre usuarios
  esIntercambio?: boolean;
  usuarioAnterior?: {
    nombre: string;
    celular: string;
    tipo: TipoUsuario;
    departamento?: string;
    nombreEmpresa?: string;
  };
  notas?: string;
  turno?: string;
  lugarId?: string;
}

export interface AccionUndo {
  id: string;
  solicitudId: string;
  tipo: 'entrega' | 'devolucion';
  vigilante: string;
  timestamp: Date;
  expiresAt: Date;
}
