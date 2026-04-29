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

export interface ReportePersonalizado {
  titulo: string;
  fechaInicio: Date;
  fechaFin: Date;
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
  
  // Resumen objetos olvidados
  const objRegistros = reporte.registros.filter(r => r.tipo === 'objeto_registro');
  const objDevoluciones = reporte.registros.filter(r => r.tipo === 'objeto_devolucion');
  if (objRegistros.length > 0 || objDevoluciones.length > 0) {
    lineas.push('OBJETOS OLVIDADOS');
    lineas.push(`Objetos Registrados,${objRegistros.length}`);
    lineas.push(`Objetos Devueltos,${objDevoluciones.length}`);
    lineas.push('');
  }

  // Detalle de operaciones
  lineas.push('DETALLE DE OPERACIONES');
  lineas.push('Fecha,Hora,Tipo,Lugar/Descripción,Usuario/Receptor,Vigilante,Turno');
  reporte.registros
    .sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime())
    .forEach(r => {
      const fecha = format(new Date(r.timestamp), 'dd/MM/yyyy', { locale: es });
      const hora = format(new Date(r.timestamp), 'HH:mm', { locale: es });
      const tipo = r.tipo === 'entrega' ? 'Entrega Llave' 
        : r.tipo === 'devolucion' ? 'Devolución Llave'
        : r.tipo === 'objeto_registro' ? 'Objeto Registrado'
        : 'Objeto Devuelto';
      lineas.push(`${fecha},${hora},${tipo},"${r.lugarNombre}","${r.usuarioNombre}","${r.vigilante}",${r.turno}`);
    });
  
  return lineas.join('\n');
}

export function generarReportePersonalizado(
  registros: RegistroActividad[],
  fechaInicio: Date,
  fechaFin: Date,
  vigilantesPorTurno: Record<Turno, string[]>
): ReportePersonalizado {
  // Filtrar registros del rango de fechas seleccionado
  const registrosFiltrados = registros.filter(r => {
    const fecha = new Date(r.timestamp);
    return fecha >= fechaInicio && fecha <= fechaFin;
  });

  const turnos: Turno[] = ['Matutino', 'Vespertino', 'Nocturno'];
  
  const estadisticasPorTurno: EstadisticasTurno[] = turnos.map(turno => {
    const registrosTurno = registrosFiltrados.filter(r => r.turno === turno);
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

  const formatoFecha = (fecha: Date) => format(fecha, 'dd/MM/yyyy', { locale: es });
  const titulo = `${formatoFecha(fechaInicio)} al ${formatoFecha(fechaFin)}`;

  return {
    titulo,
    fechaInicio,
    fechaFin,
    totalEntregas: registrosFiltrados.filter(r => r.tipo === 'entrega').length,
    totalDevoluciones: registrosFiltrados.filter(r => r.tipo === 'devolucion').length,
    estadisticasPorTurno,
    registros: registrosFiltrados
  };
}

export function exportarCSVPersonalizado(reporte: ReportePersonalizado): string {
  const lineas: string[] = [];
  
  // Cabecera del reporte
  lineas.push(`Reporte Personalizado de Llaves - FCEA UdelaR`);
  lineas.push(`Período: ${reporte.titulo}`);
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
  
  // Resumen objetos olvidados
  const objRegP = reporte.registros.filter(r => r.tipo === 'objeto_registro');
  const objDevP = reporte.registros.filter(r => r.tipo === 'objeto_devolucion');
  if (objRegP.length > 0 || objDevP.length > 0) {
    lineas.push('OBJETOS OLVIDADOS');
    lineas.push(`Objetos Registrados,${objRegP.length}`);
    lineas.push(`Objetos Devueltos,${objDevP.length}`);
    lineas.push('');
  }

  // Detalle de operaciones
  lineas.push('DETALLE DE OPERACIONES');
  lineas.push('Fecha,Hora,Tipo,Lugar/Descripción,Usuario/Receptor,Vigilante,Turno');
  reporte.registros
    .sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime())
    .forEach(r => {
      const fecha = format(new Date(r.timestamp), 'dd/MM/yyyy', { locale: es });
      const hora = format(new Date(r.timestamp), 'HH:mm', { locale: es });
      const tipo = r.tipo === 'entrega' ? 'Entrega Llave' 
        : r.tipo === 'devolucion' ? 'Devolución Llave'
        : r.tipo === 'objeto_registro' ? 'Objeto Registrado'
        : 'Objeto Devuelto';
      lineas.push(`${fecha},${hora},${tipo},"${r.lugarNombre}","${r.usuarioNombre}","${r.vigilante}",${r.turno}`);
    });
  
  return lineas.join('\n');
}

export async function descargarCSV(contenido: string, nombreArchivo: string): Promise<boolean> {
  // 1. Mostrar modal 'Copiando...' desde el componente padre
  
  try {
    // 2. Proteger el archivo con una clave fija del sistema
    // Esta clave es conocida solo por el sistema y las aplicaciones autorizadas para leer los reportes
    const claveSeguridad = 'FCEA_SISTEMA_LLAVES_2026_SEGURIDAD';
    const contenidoProtegido = await encryptWithPassword(contenido, claveSeguridad);
    
    // 3. Copiar al USB (solo disponible en modo kiosk con USB conectado)
    if (window.kioskModeAPI?.usbDrives?.length > 0) {
      const usbPath = window.kioskModeAPI.usbDrives[0].mountPoint;
      const filePath = `${usbPath}/${nombreArchivo}.enc`;
      
      await window.kioskModeAPI.writeFile(filePath, contenidoProtegido);
      
      // 4. Éxito - el componente padre mostrará el mensaje
      return true;
    } else {
      // En modo kiosk sin USB, no permitimos la descarga normal
      // ya que no sería accesible para el usuario y representaría un riesgo de seguridad
      return false;
    }
  } catch (error) {
    console.error('Error al exportar:', error);
    return false;
  }
}

async function encryptWithPassword(data: string, password: string): Promise<string> {
  // Implementación mejorada de cifrado
  // En una implementación real, se usaría una biblioteca de cifrado más robusta
  // como crypto-js o la Web Crypto API
  
  // Esta es una implementación básica para demostración
  // que combina el contenido con la clave y aplica múltiples capas de codificación
  const salt = "FCEA_SALT_2026";
  const combinedKey = password + salt;
  
  // Simulamos múltiples rondas de cifrado
  let encrypted = data;
  for (let i = 0; i < 3; i++) {
    encrypted = btoa(encodeURIComponent(encrypted + combinedKey));
  }
  
  return encrypted;
}

/**
 * Verifica si hay un dispositivo USB conectado
 * @returns {boolean} true si hay al menos un USB conectado
 */
export function hayUSBConectado(): boolean {
  return window.kioskModeAPI?.usbDrives?.length > 0;
}

/**
 * Obtiene información sobre los dispositivos USB conectados
 * @returns {Array<{mountPoint: string, label: string}>} Lista de dispositivos USB
 */
export function obtenerUSBsConectados(): Array<{mountPoint: string, label: string}> {
  return window.kioskModeAPI?.usbDrives || [];
}

// Función auxiliar para convertir datos a CSV
function convertToCSV(data: any[]): string {
  if (!data || data.length === 0) return '';
  
  // Si es un array de arrays (datos tabulares simples)
  if (Array.isArray(data[0])) {
    return data.map(row => 
      row.map((cell: any) => {
        const cellStr = String(cell || '');
        // Escapar comillas y envolver en comillas si contiene comas o saltos de línea
        if (cellStr.includes(',') || cellStr.includes('\n') || cellStr.includes('"')) {
          return `"${cellStr.replace(/"/g, '""')}"`;
        }
        return cellStr;
      }).join(',')
    ).join('\n');
  }
  
  // Si es un array de objetos
  if (typeof data[0] === 'object') {
    const headers = Object.keys(data[0]);
    const csvHeaders = headers.join(',');
    const csvRows = data.map(row => 
      headers.map(header => {
        const cellStr = String(row[header] || '');
        if (cellStr.includes(',') || cellStr.includes('\n') || cellStr.includes('"')) {
          return `"${cellStr.replace(/"/g, '""')}"`;
        }
        return cellStr;
      }).join(',')
    );
    return [csvHeaders, ...csvRows].join('\n');
  }
  
  return '';
}

// Función auxiliar para descargar archivos
function downloadFile(content: string, filename: string, mimeType: string): void {
  const blob = new Blob([content], { type: mimeType });
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  window.URL.revokeObjectURL(url);
}

export async function exportToExcel(data: any, filename: string, options: any = {}) {
  // Para una implementación completa de Excel, necesitaríamos una librería como xlsx
  // Por ahora, exportamos como CSV que se puede abrir en Excel
  
  const sheets: { [key: string]: any[] } = {};
  
  // Hoja de resumen
  if (options.includeStats) {
    const stats = [
      ['Estadísticas del Sistema de Gestión de Llaves FCEA'],
      [''],
      ['Período:', `${options.dateRange?.start || 'N/A'} - ${options.dateRange?.end || 'N/A'}`],
      ['Generado:', new Date().toLocaleString('es-UY')],
      ['Generado por:', data.generatedBy || 'Sistema'],
      [''],
      ['Resumen de Datos:'],
      ['Solicitudes Pendientes:', data.solicitudesPendientes?.length || 0],
      ['Llaves Entregadas:', data.solicitudesEntregadas?.length || 0],
      ['Llaves Devueltas:', data.solicitudesDevueltas?.length || 0],
      ['Total de Registros:', (data.solicitudesPendientes?.length || 0) + (data.solicitudesEntregadas?.length || 0) + (data.solicitudesDevueltas?.length || 0)]
    ];
    sheets['Resumen'] = stats;
  }
  
  // Hoja de solicitudes pendientes
  if (data.solicitudesPendientes && data.solicitudesPendientes.length > 0) {
    const pendientes = data.solicitudesPendientes.map((s: any) => ({
      'Fecha Solicitud': new Date(s.horaSolicitud).toLocaleDateString('es-UY'),
      'Hora Solicitud': new Date(s.horaSolicitud).toLocaleTimeString('es-UY'),
      'Usuario': s.usuario.nombre,
      'Celular': s.usuario.celular,
      'Tipo Usuario': s.usuario.tipo,
      'Departamento': s.usuario.departamento || 'N/A',
      'Empresa': s.usuario.nombreEmpresa || 'N/A',
      'Lugar': s.lugar.nombre,
      'Tipo Lugar': s.lugar.tipo,
      'Edificio': s.lugar.edificio,
      'Piso': s.lugar.piso,
      'Estado': 'Pendiente'
    }));
    sheets['Solicitudes Pendientes'] = pendientes;
  }
  
  // Hoja de llaves entregadas
  if (data.solicitudesEntregadas && data.solicitudesEntregadas.length > 0) {
    const entregadas = data.solicitudesEntregadas.map((s: any) => ({
      'Fecha Solicitud': new Date(s.horaSolicitud).toLocaleDateString('es-UY'),
      'Hora Solicitud': new Date(s.horaSolicitud).toLocaleTimeString('es-UY'),
      'Fecha Entrega': s.horaEntrega ? new Date(s.horaEntrega).toLocaleDateString('es-UY') : 'N/A',
      'Hora Entrega': s.horaEntrega ? new Date(s.horaEntrega).toLocaleTimeString('es-UY') : 'N/A',
      'Usuario': s.usuario.nombre,
      'Celular': s.usuario.celular,
      'Tipo Usuario': s.usuario.tipo,
      'Departamento': s.usuario.departamento || 'N/A',
      'Empresa': s.usuario.nombreEmpresa || 'N/A',
      'Lugar': s.lugar.nombre,
      'Tipo Lugar': s.lugar.tipo,
      'Edificio': s.lugar.edificio,
      'Piso': s.lugar.piso,
      'Entregado Por': s.entregadoPor || 'N/A',
      'Tiempo en Uso': s.horaEntrega ? `${Math.round((Date.now() - new Date(s.horaEntrega).getTime()) / (1000 * 60))} min` : 'N/A',
      'Notas': s.notas || '',
      'Estado': 'En Uso'
    }));
    sheets['Llaves Entregadas'] = entregadas;
  }
  
  // Hoja de llaves devueltas
  if (data.solicitudesDevueltas && data.solicitudesDevueltas.length > 0) {
    const devueltas = data.solicitudesDevueltas.map((s: any) => ({
      'Fecha Solicitud': new Date(s.horaSolicitud).toLocaleDateString('es-UY'),
      'Hora Solicitud': new Date(s.horaSolicitud).toLocaleTimeString('es-UY'),
      'Fecha Entrega': s.horaEntrega ? new Date(s.horaEntrega).toLocaleDateString('es-UY') : 'N/A',
      'Hora Entrega': s.horaEntrega ? new Date(s.horaEntrega).toLocaleTimeString('es-UY') : 'N/A',
      'Fecha Devolución': s.horaDevolucion ? new Date(s.horaDevolucion).toLocaleDateString('es-UY') : 'N/A',
      'Hora Devolución': s.horaDevolucion ? new Date(s.horaDevolucion).toLocaleTimeString('es-UY') : 'N/A',
      'Usuario': s.usuario.nombre,
      'Celular': s.usuario.celular,
      'Tipo Usuario': s.usuario.tipo,
      'Departamento': s.usuario.departamento || 'N/A',
      'Empresa': s.usuario.nombreEmpresa || 'N/A',
      'Lugar': s.lugar.nombre,
      'Tipo Lugar': s.lugar.tipo,
      'Edificio': s.lugar.edificio,
      'Piso': s.lugar.piso,
      'Entregado Por': s.entregadoPor || 'N/A',
      'Recibido Por': s.recibidoPor || 'N/A',
      'Tiempo Total': s.horaEntrega && s.horaDevolucion ? 
        `${Math.round((new Date(s.horaDevolucion).getTime() - new Date(s.horaEntrega).getTime()) / (1000 * 60))} min` : 'N/A',
      'Notas': s.notas || '',
      'Estado': 'Devuelta'
    }));
    sheets['Llaves Devueltas'] = devueltas;
  }
  
  // Exportar cada hoja como CSV separado
  for (const [sheetName, sheetData] of Object.entries(sheets)) {
    const csvContent = convertToCSV(sheetData);
    downloadFile(csvContent, `${filename}_${sheetName}.csv`, 'text/csv');
  }
  
  // También crear un archivo combinado
  const allData: any[] = [];
  
  // Agregar encabezado del resumen
  if (sheets['Resumen']) {
    allData.push(...sheets['Resumen']);
    allData.push(['']); // Línea vacía
  }
  
  // Agregar datos de cada hoja
  for (const [sheetName, sheetData] of Object.entries(sheets)) {
    if (sheetName !== 'Resumen' && Array.isArray(sheetData) && sheetData.length > 0) {
      allData.push([`=== ${sheetName.toUpperCase()} ===`]);
      allData.push(['']);
      
      // Agregar encabezados
      if (typeof sheetData[0] === 'object') {
        allData.push(Object.keys(sheetData[0]));
        // Agregar datos
        sheetData.forEach(row => {
          allData.push(Object.values(row));
        });
      } else {
        allData.push(...sheetData);
      }
      
      allData.push(['']); // Línea vacía entre secciones
    }
  }
  
  const combinedCsv = convertToCSV(allData);
  downloadFile(combinedCsv, `${filename}_Completo.csv`, 'text/csv');
}
