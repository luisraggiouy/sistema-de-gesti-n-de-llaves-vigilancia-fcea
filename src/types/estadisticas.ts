import { Turno } from '@/data/fceaData';

export interface RegistroActividad {
  id: string;
  solicitudId: string;
  tipo: 'entrega' | 'devolucion';
  vigilante: string;
  turno: Turno;
  timestamp: Date;
  lugarNombre: string;
  usuarioNombre: string;
}

export interface EstadisticasVigilante {
  nombre: string;
  entregas: number;
  devoluciones: number;
  total: number;
}

export interface EstadisticasTurno {
  turno: Turno;
  entregas: number;
  devoluciones: number;
  vigilantes: EstadisticasVigilante[];
}
