import { RegistroActividad, EstadisticasTurno } from '@/types/estadisticas';
import { Turno } from '@/data/fceaData';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

export interface ReporteMensual {
  mes: string;
  anio: number;
  totalEntregas: number;
  totalDevoluciones: number;
  estadisticasPorTurno: EstadisticasTurno[];
  registros: RegistroActividad[];
}

export function generarReporteMensual(
  registros: RegistroActividad[],
  mes: number,
  anio: number,
  vigilantesPorTurno: Record<Turno, string[]>
): ReporteMensual {
  // Filtrar registros del mes seleccionado
  const registrosMes = registros.filter(r => {
    const fecha = new Date(r.timestamp);
    return fecha.getMonth() === mes && fecha.getFullYear() === anio;
  });

  const turnos: Turno[] = ['Matutino', 'Vespertino', 'Nocturno'];
  
  const estadisticasPorTurno: EstadisticasTurno[] = turnos.map(turno => {
    const registrosTurno = registrosMes.filter(r => r.turno === turno);
    const entregas = registrosTurno.filter(r => r.tipo === 'entrega').length;
    const devoluciones = registrosTurno.filter(r => r.tipo === 'devolucion').length;
    
    const vigilantesTurno = vigilantesPorTurno[turno] || [];
    const vigilantes = vigilantesTurno.map(nombre => {
      const registrosVigilante = registrosTurno.filter(r => r.vigilante === nombre);
      return {
        nombre,
        entregas: registrosVigilante.filter(r => r.tipo === 'entrega').length,
        devoluciones: registrosVigilante.filter(r => r.tipo === 'devolucion').length,
        total: registrosVigilante.length
      };
    });

    return { turno, entregas, devoluciones, vigilantes };
  });

  const nombreMes = format(new Date(anio, mes), 'MMMM', { locale: es });

  return {
    mes: nombreMes.charAt(0).toUpperCase() + nombreMes.slice(1),
    anio,
    totalEntregas: registrosMes.filter(r => r.tipo === 'entrega').length,
    totalDevoluciones: registrosMes.filter(r => r.tipo === 'devolucion').length,
    estadisticasPorTurno,
    registros: registrosMes
  };
}

export function exportarCSV(reporte: ReporteMensual): string {
  const lineas: string[] = [];
  
  // Cabecera del reporte
  lineas.push(`Reporte Mensual de Llaves - FCEA UdelaR`);
  lineas.push(`Período: ${reporte.mes} ${reporte.anio}`);
  lineas.push(`Generado: ${format(new Date(), "dd/MM/yyyy HH:mm", { locale: es })}`);
  lineas.push('');
  
  // Resumen general
  lineas.push('RESUMEN GENERAL');
  lineas.push(`Total Entregas,${reporte.totalEntregas}`);
  lineas.push(`Total Devoluciones,${reporte.totalDevoluciones}`);
  lineas.push('');
  
  // Estadísticas por turno
  lineas.push('ESTADÍSTICAS POR TURNO');
  lineas.push('Turno,Entregas,Devoluciones');
  reporte.estadisticasPorTurno.forEach(stat => {
    lineas.push(`${stat.turno},${stat.entregas},${stat.devoluciones}`);
  });
  lineas.push('');
  
  // Estadísticas por vigilante
  lineas.push('ACTIVIDAD POR VIGILANTE');
  lineas.push('Turno,Vigilante,Entregas,Devoluciones,Total');
  reporte.estadisticasPorTurno.forEach(stat => {
    stat.vigilantes.forEach(v => {
      lineas.push(`${stat.turno},${v.nombre},${v.entregas},${v.devoluciones},${v.total}`);
    });
  });
  lineas.push('');
  
  // Detalle de operaciones
  lineas.push('DETALLE DE OPERACIONES');
  lineas.push('Fecha,Hora,Tipo,Llave,Usuario,Vigilante,Turno');
  reporte.registros
    .sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime())
    .forEach(r => {
      const fecha = format(new Date(r.timestamp), 'dd/MM/yyyy', { locale: es });
      const hora = format(new Date(r.timestamp), 'HH:mm', { locale: es });
      const tipo = r.tipo === 'entrega' ? 'Entrega' : 'Devolución';
      lineas.push(`${fecha},${hora},${tipo},"${r.lugarNombre}","${r.usuarioNombre}","${r.vigilante}",${r.turno}`);
    });
  
  return lineas.join('\n');
}

export function descargarCSV(contenido: string, nombreArchivo: string): void {
  const blob = new Blob(['\ufeff' + contenido], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', nombreArchivo);
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
