import { useMemo, useState } from 'react';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';

export interface HistorialLlaveItem {
  lugarNombre: string;
  usuarioNombre: string;
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

export function useBusquedaHistorial() {
  const { registrosActividad } = useSolicitudesContext();
  const [filtros, setFiltros] = useState<FiltrosHistorial>({
    busqueda: '',
    fechaInicio: undefined,
    fechaFin: undefined,
  });

  // Agrupar entregas con sus devoluciones
  const historial = useMemo((): HistorialLlaveItem[] => {
    const entregas = registrosActividad.filter(r => r.tipo === 'entrega');
    const devoluciones = registrosActividad.filter(r => r.tipo === 'devolucion');

    return entregas.map(entrega => {
      const devolucion = devoluciones.find(d => d.solicitudId === entrega.solicitudId);
      
      let tiempoUso: string | undefined;
      let tiempoUsoMinutos: number | undefined;

      if (devolucion) {
        const entregaTime = new Date(entrega.timestamp).getTime();
        const devolucionTime = new Date(devolucion.timestamp).getTime();
        tiempoUsoMinutos = Math.floor((devolucionTime - entregaTime) / (1000 * 60));
        
        const horas = Math.floor(tiempoUsoMinutos / 60);
        const minutos = tiempoUsoMinutos % 60;
        tiempoUso = horas > 0 ? `${horas}h ${minutos}m` : `${minutos}m`;
      }

      return {
        lugarNombre: entrega.lugarNombre,
        usuarioNombre: entrega.usuarioNombre,
        vigilanteEntrega: entrega.vigilante,
        vigilanteDevolucion: devolucion?.vigilante,
        horaEntrega: new Date(entrega.timestamp),
        horaDevolucion: devolucion ? new Date(devolucion.timestamp) : undefined,
        tiempoUso,
        tiempoUsoMinutos,
        turno: entrega.turno,
      };
    }).sort((a, b) => b.horaEntrega.getTime() - a.horaEntrega.getTime());
  }, [registrosActividad]);

  // Normalizar texto para búsqueda
  const normalizar = (texto: string) => 
    texto.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');

  // Filtrar historial
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
