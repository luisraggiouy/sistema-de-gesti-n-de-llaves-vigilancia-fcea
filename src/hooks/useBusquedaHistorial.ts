import { useMemo, useState } from 'react';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';

export interface HistorialLlaveItem {
  lugarNombre: string;
  usuarioNombre: string;
  tipoUsuario: string;
  departamento?: string;
  nombreEmpresa?: string;
  vigilanteEntrega: string;
  vigilanteDevolucion?: string;
  horaEntrega: Date;
  horaDevolucion?: Date;
  tiempoUso?: string;
  tiempoUsoMinutos?: number;
  turno: string;
}

interface FiltrosHistorial {
  busqueda: string;
  fechaInicio?: Date;
  fechaFin?: Date;
}

const normalizar = (texto: string) =>
  texto.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');

export function useBusquedaHistorial() {
  const { solicitudes } = useSolicitudesContext();
  const [filtros, setFiltros] = useState<FiltrosHistorial>({
    busqueda: '',
    fechaInicio: undefined,
    fechaFin: undefined,
  });

  // Derivar historial desde solicitudes que ya fueron entregadas
  const historial = useMemo((): HistorialLlaveItem[] => {
    return (solicitudes ?? [])
      .filter(s => s.estado === 'entregada' || s.estado === 'devuelta')
      .filter(s => s.horaEntrega)
      .map(s => {
        let tiempoUso: string | undefined;
        let tiempoUsoMinutos: number | undefined;

        if (s.horaEntrega && s.horaDevolucion) {
          const entregaTime = new Date(s.horaEntrega).getTime();
          const devolucionTime = new Date(s.horaDevolucion).getTime();
          tiempoUsoMinutos = Math.floor((devolucionTime - entregaTime) / (1000 * 60));
          const horas = Math.floor(tiempoUsoMinutos / 60);
          const minutos = tiempoUsoMinutos % 60;
          tiempoUso = horas > 0 ? `${horas}h ${minutos}m` : `${minutos}m`;
        }

        return {
          lugarNombre: s.lugar?.nombre ?? '',
          usuarioNombre: s.usuario?.nombre ?? '',
          tipoUsuario: s.usuario?.tipo ?? '',
          departamento: (s.usuario as any).departamento,
          nombreEmpresa: (s.usuario as any).nombreEmpresa,
          vigilanteEntrega: s.entregadoPor ?? '',
          vigilanteDevolucion: s.recibidoPor,
          horaEntrega: new Date(s.horaEntrega!),
          horaDevolucion: s.horaDevolucion ? new Date(s.horaDevolucion) : undefined,
          tiempoUso,
          tiempoUsoMinutos,
          turno: s.turno ?? '',
        };
      })
      .sort((a, b) => b.horaEntrega.getTime() - a.horaEntrega.getTime());
  }, [solicitudes]);

  const historialFiltrado = useMemo(() => {
    return historial.filter(item => {
      if (filtros.busqueda) {
        const busqueda = normalizar(filtros.busqueda);
        const coincide =
          normalizar(item.lugarNombre).includes(busqueda) ||
          normalizar(item.usuarioNombre).includes(busqueda) ||
          normalizar(item.vigilanteEntrega).includes(busqueda) ||
          (item.vigilanteDevolucion && normalizar(item.vigilanteDevolucion).includes(busqueda));
        if (!coincide) return false;
      }
      if (filtros.fechaInicio) {
        const fechaItem = new Date(item.horaEntrega);
        fechaItem.setHours(0, 0, 0, 0);
        const fechaInicio = new Date(filtros.fechaInicio);
        fechaInicio.setHours(0, 0, 0, 0);
        if (fechaItem < fechaInicio) return false;
      }
      if (filtros.fechaFin) {
        const fechaItem = new Date(item.horaEntrega);
        fechaItem.setHours(23, 59, 59, 999);
        const fechaFin = new Date(filtros.fechaFin);
        fechaFin.setHours(23, 59, 59, 999);
        if (fechaItem > fechaFin) return false;
      }
      return true;
    });
  }, [historial, filtros]);

  return {
    historial: historialFiltrado,
    totalRegistros: historial.length,
    filtros,
    setFiltros,
    setBusqueda: (busqueda: string) => setFiltros(f => ({ ...f, busqueda })),
    setFechaInicio: (fecha?: Date) => setFiltros(f => ({ ...f, fechaInicio: fecha })),
    setFechaFin: (fecha?: Date) => setFiltros(f => ({ ...f, fechaFin: fecha })),
    limpiarFiltros: () => setFiltros({ busqueda: '', fechaInicio: undefined, fechaFin: undefined }),
  };
}