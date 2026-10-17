import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';

// Cuantos registros se PINTAN en pantalla por tanda (scroll infinito).
// El historial completo puede tener miles de registros (crece con el uso):
// renderizar TODAS las tarjetas de golpe hacia que el dialogo tardara varios
// segundos en abrir y cerrar. Se limita SOLO el render (no la busqueda ni los
// filtros, que siguen operando sobre el total) y se van sumando tandas a medida
// que el usuario baja el scroll. Fix latencia historial 2026-10-03.
const TANDA_HISTORIAL = 40;

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
  notas?: string;
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
          notas: s.notas?.trim() ? s.notas.trim() : undefined,
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

  // Cantidad de registros efectivamente renderizados (scroll infinito).
  // Arranca en una tanda y crece al bajar el scroll. Se reinicia cada vez que
  // cambian los filtros para no quedar "mostrando mas" sobre una lista nueva.
  const [visibles, setVisibles] = useState(TANDA_HISTORIAL);

  useEffect(() => {
    setVisibles(TANDA_HISTORIAL);
  }, [filtros.busqueda, filtros.fechaInicio, filtros.fechaFin]);

  const historialVisible = useMemo(
    () => historialFiltrado.slice(0, visibles),
    [historialFiltrado, visibles],
  );

  const hayMas = visibles < historialFiltrado.length;

  const cargarMas = useCallback(() => {
    setVisibles(v => Math.min(v + TANDA_HISTORIAL, historialFiltrado.length));
  }, [historialFiltrado.length]);

  return {
    // Lista YA recortada para pintar (scroll infinito).
    historial: historialVisible,
    // Total que matchea los filtros (todo lo buscado, no solo lo pintado).
    totalFiltrado: historialFiltrado.length,
    // Total absoluto de registros del historial (sin filtrar).
    totalRegistros: historial.length,
    // Hay mas tandas para cargar al seguir bajando.
    hayMas,
    // Suma la siguiente tanda al render.
    cargarMas,
    filtros,
    setFiltros,
    setBusqueda: (busqueda: string) => setFiltros(f => ({ ...f, busqueda })),
    setFechaInicio: (fecha?: Date) => setFiltros(f => ({ ...f, fechaInicio: fecha })),
    setFechaFin: (fecha?: Date) => setFiltros(f => ({ ...f, fechaFin: fecha })),
    limpiarFiltros: () => setFiltros({ busqueda: '', fechaInicio: undefined, fechaFin: undefined }),
  };
}