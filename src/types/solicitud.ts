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
