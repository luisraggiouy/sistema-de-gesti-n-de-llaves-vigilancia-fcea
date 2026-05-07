import { RegistroActividad, EstadisticasTurno } from '@/types/estadisticas';
import { Turno, EstadoLicencia } from '@/data/fceaData';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

// Tipo mínimo de vigilante necesario para los reportes
export interface VigilanteReporte {
  nombre: string;
  estadoLicencia?: EstadoLicencia;
  esJefe?: boolean;
}

function etiquetaLicencia(estado?: EstadoLicencia): string {
  if (!estado || estado === 'activo') return 'Activo';
  if (estado === 'licencia') return 'Licencia';
  return 'Licencia Médica';
}

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
  vigilantesPorTurno: Record<Turno, VigilanteReporte[]>
): ReporteMensual {
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
    const vigilantes = vigilantesTurno.map(v => {
      const registrosVigilante = registrosTurno.filter(r => r.vigilante === v.nombre);
      return {
        nombre: v.nombre,
        entregas: registrosVigilante.filter(r => r.tipo === 'entrega').length,
        devoluciones: registrosVigilante.filter(r => r.tipo === 'devolucion').length,
        total: registrosVigilante.length,
        estadoLicencia: v.estadoLicencia,
        esJefe: v.esJefe,
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
  lineas.push('Turno,Vigilante,Rol,Estado,Entregas,Devoluciones,Total');
  reporte.estadisticasPorTurno.forEach(stat => {
    stat.vigilantes.forEach((v: any) => {
      const rol = v.esJefe ? 'Jefe de Turno' : 'Vigilante';
      const estado = etiquetaLicencia(v.estadoLicencia);
      lineas.push(`${stat.turno},${v.nombre},${rol},${estado},${v.entregas},${v.devoluciones},${v.total}`);
    });
  });
  lineas.push('');

  // Personal en licencia durante el período
  const enLicencia = reporte.estadisticasPorTurno.flatMap(stat =>
    (stat.vigilantes as any[])
      .filter(v => v.estadoLicencia && v.estadoLicencia !== 'activo')
      .map(v => ({ turno: stat.turno, nombre: v.nombre, estado: etiquetaLicencia(v.estadoLicencia) }))
  );
  if (enLicencia.length > 0) {
    lineas.push('PERSONAL EN LICENCIA');
    lineas.push('Turno,Vigilante,Tipo de Licencia');
    enLicencia.forEach(v => lineas.push(`${v.turno},${v.nombre},${v.estado}`));
    lineas.push('');
  }

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
  vigilantesPorTurno: Record<Turno, VigilanteReporte[]>
): ReportePersonalizado {
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
    const vigilantes = vigilantesTurno.map(v => {
      const registrosVigilante = registrosTurno.filter(r => r.vigilante === v.nombre);
      return {
        nombre: v.nombre,
        entregas: registrosVigilante.filter(r => r.tipo === 'entrega').length,
        devoluciones: registrosVigilante.filter(r => r.tipo === 'devolucion').length,
        total: registrosVigilante.length,
        estadoLicencia: v.estadoLicencia,
        esJefe: v.esJefe,
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
  lineas.push('Turno,Vigilante,Rol,Estado,Entregas,Devoluciones,Total');
  reporte.estadisticasPorTurno.forEach(stat => {
    stat.vigilantes.forEach((v: any) => {
      const rol = v.esJefe ? 'Jefe de Turno' : 'Vigilante';
      const estado = etiquetaLicencia(v.estadoLicencia);
      lineas.push(`${stat.turno},${v.nombre},${rol},${estado},${v.entregas},${v.devoluciones},${v.total}`);
    });
  });
  lineas.push('');

  // Personal en licencia durante el período
  const enLicenciaP = reporte.estadisticasPorTurno.flatMap(stat =>
    (stat.vigilantes as any[])
      .filter(v => v.estadoLicencia && v.estadoLicencia !== 'activo')
      .map(v => ({ turno: stat.turno, nombre: v.nombre, estado: etiquetaLicencia(v.estadoLicencia) }))
  );
  if (enLicenciaP.length > 0) {
    lineas.push('PERSONAL EN LICENCIA');
    lineas.push('Turno,Vigilante,Tipo de Licencia');
    enLicenciaP.forEach(v => lineas.push(`${v.turno},${v.nombre},${v.estado}`));
    lineas.push('');
  }

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
 * Verifica si el navegador soporta exportación de archivos.
 * Siempre retorna true — el usuario elige dónde guardar al momento de exportar.
 */
export function hayUSBConectado(): boolean {
  return true;
}

/**
 * Retorna una entrada ficticia para mantener compatibilidad con el modal.
 * La ruta real se elige en el diálogo de guardado al momento de exportar.
 */
export function obtenerUSBsConectados(): Array<{mountPoint: string, label: string}> {
  return [{ mountPoint: '', label: 'Seleccionar destino al exportar' }];
}

/**
 * Guarda contenido en un archivo usando File System Access API (Chrome/Edge)
 * o descarga normal como fallback (Firefox/Safari).
 * @param content Contenido del archivo
 * @param suggestedName Nombre sugerido para el archivo
 * @param mimeType Tipo MIME
 */
export async function guardarArchivo(content: string, suggestedName: string, mimeType: string): Promise<boolean> {
  // Intentar File System Access API (Chrome 86+, Edge 86+)
  if ('showSaveFilePicker' in window) {
    try {
      const extension = suggestedName.endsWith('.csv') ? '.csv' : '.txt';
      const fileHandle = await (window as any).showSaveFilePicker({
        suggestedName,
        types: [
          {
            description: 'Archivo CSV',
            accept: { 'text/csv': ['.csv'] },
          },
        ],
        startIn: 'downloads',
      });
      const writable = await fileHandle.createWritable();
      // Agregar BOM UTF-8 para que Excel abra correctamente con tildes
      const bom = '\uFEFF';
      await writable.write(bom + content);
      await writable.close();
      return true;
    } catch (err: any) {
      // El usuario canceló el diálogo
      if (err.name === 'AbortError') return false;
      // Otro error — caer al método de descarga normal
      console.warn('showSaveFilePicker falló, usando descarga normal:', err);
    }
  }
  // Fallback: descarga normal del navegador
  const bom = '\uFEFF';
  const blob = new Blob([bom + content], { type: mimeType });
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = suggestedName;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  window.URL.revokeObjectURL(url);
  return true;
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

// ─── Generador de informe HTML con gráficas SVG ───────────────────────────────

function svgBarChart(items: { label: string; value: number; color: string }[], maxVal: number, height = 180): string {
  const barW = 48;
  const gap = 16;
  const totalW = items.length * (barW + gap) + gap;
  const chartH = height;
  const labelH = 56;
  const topPad = 28; // espacio para el número encima de la barra más alta
  const svgH = chartH + labelH + topPad;

  const bars = items.map((item, i) => {
    const x = gap + i * (barW + gap);
    const barH = maxVal > 0 ? Math.round((item.value / maxVal) * chartH) : 0;
    const y = topPad + (chartH - barH);
    const labelLines = item.label.split(' ');
    return `
      <rect x="${x}" y="${y}" width="${barW}" height="${barH}" fill="${item.color}" rx="4"/>
      <text x="${x + barW / 2}" y="${y - 6}" text-anchor="middle" font-size="13" font-weight="bold" fill="#1e293b">${item.value}</text>
      ${labelLines.map((l, li) => `<text x="${x + barW / 2}" y="${topPad + chartH + 18 + li * 16}" text-anchor="middle" font-size="11" fill="#475569">${l}</text>`).join('')}
    `;
  }).join('');

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${totalW}" height="${svgH}">
    <line x1="0" y1="${topPad + chartH}" x2="${totalW}" y2="${topPad + chartH}" stroke="#e2e8f0" stroke-width="2"/>
    ${bars}
  </svg>`;
}

function badgeRendimiento(total: number, max: number): string {
  if (max === 0) return '<span style="background:#e2e8f0;color:#64748b;padding:2px 10px;border-radius:12px;font-size:12px">Sin datos</span>';
  const pct = total / max;
  if (pct >= 0.8) return '<span style="background:#dcfce7;color:#166534;padding:2px 10px;border-radius:12px;font-size:12px">Excelente</span>';
  if (pct >= 0.5) return '<span style="background:#fef9c3;color:#854d0e;padding:2px 10px;border-radius:12px;font-size:12px">Bueno</span>';
  if (pct >= 0.2) return '<span style="background:#ffedd5;color:#9a3412;padding:2px 10px;border-radius:12px;font-size:12px">Regular</span>';
  return '<span style="background:#fee2e2;color:#991b1b;padding:2px 10px;border-radius:12px;font-size:12px">Bajo</span>';
}

// Calcula cuántos días dentro de un rango de fechas corresponden a los días laborales de un vigilante
function calcularDiasEsperados(fechaInicioStr: string, fechaFinStr: string, diasLaborales?: number[]): number {
  if (!fechaInicioStr || !fechaFinStr) return 0;
  // Parsear dd/MM/yyyy
  const parseFecha = (s: string) => {
    const [d, m, y] = s.split('/');
    return new Date(Number(y), Number(m) - 1, Number(d));
  };
  const fi = parseFecha(fechaInicioStr);
  const ff = parseFecha(fechaFinStr);
  if (isNaN(fi.getTime()) || isNaN(ff.getTime())) return 0;
  // Si no tiene días laborales configurados → trabaja todos los días
  if (!diasLaborales || diasLaborales.length === 0 || diasLaborales.length === 7) {
    return Math.max(1, Math.round((ff.getTime() - fi.getTime()) / 86400000) + 1);
  }
  // Contar días del período que coinciden con los días laborales
  let count = 0;
  const cur = new Date(fi);
  while (cur <= ff) {
    if (diasLaborales.includes(cur.getDay())) count++;
    cur.setDate(cur.getDate() + 1);
  }
  return count;
}

function generarInformeHTML(data: any, options: any): string {
  const periodo = `${options.dateRange?.start || ''} al ${options.dateRange?.end || ''}`;
  const ahora = new Date().toLocaleString('es-UY');

  // ── Calcular estadísticas por vigilante ──────────────────────────────────────
  type VigStat = { nombre: string; turno: string; entregas: number; devoluciones: number; objetos: number; total: number };
  const vigMap: Record<string, VigStat> = {};

  const todasSolicitudes = [
    ...(data.solicitudesEntregadas || []),
    ...(data.solicitudesDevueltas || []),
  ];

  todasSolicitudes.forEach((s: any) => {
    if (s.entregadoPor) {
      if (!vigMap[s.entregadoPor]) vigMap[s.entregadoPor] = { nombre: s.entregadoPor, turno: s.turno || '', entregas: 0, devoluciones: 0, objetos: 0, total: 0 };
      vigMap[s.entregadoPor].entregas++;
      vigMap[s.entregadoPor].total++;
    }
    if (s.recibidoPor) {
      if (!vigMap[s.recibidoPor]) vigMap[s.recibidoPor] = { nombre: s.recibidoPor, turno: s.turno || '', entregas: 0, devoluciones: 0, objetos: 0, total: 0 };
      vigMap[s.recibidoPor].devoluciones++;
      vigMap[s.recibidoPor].total++;
    }
  });

  (data.objetosOlvidados || []).forEach((o: any) => {
    if (o.registradoPor) {
      if (!vigMap[o.registradoPor]) vigMap[o.registradoPor] = { nombre: o.registradoPor, turno: '', entregas: 0, devoluciones: 0, objetos: 0, total: 0 };
      vigMap[o.registradoPor].objetos++;
      vigMap[o.registradoPor].total++;
    }
  });

  const vigilantes = Object.values(vigMap).sort((a, b) => b.total - a.total);
  const maxTotal = vigilantes.length > 0 ? vigilantes[0].total : 1;

  // ── Estadísticas por turno ───────────────────────────────────────────────────
  type TurnoStat = { entregas: number; devoluciones: number; total: number };
  const turnos: Record<string, TurnoStat> = {
    'Matutino': { entregas: 0, devoluciones: 0, total: 0 },
    'Vespertino': { entregas: 0, devoluciones: 0, total: 0 },
    'Nocturno': { entregas: 0, devoluciones: 0, total: 0 },
  };

  (data.solicitudesEntregadas || []).forEach((s: any) => {
    const h = s.horaEntrega ? new Date(s.horaEntrega).getHours() : -1;
    const t = h >= 6 && h < 14 ? 'Matutino' : h >= 14 && h < 22 ? 'Vespertino' : h >= 0 ? 'Nocturno' : null;
    if (t) { turnos[t].entregas++; turnos[t].total++; }
  });
  (data.solicitudesDevueltas || []).forEach((s: any) => {
    const h = s.horaDevolucion ? new Date(s.horaDevolucion).getHours() : -1;
    const t = h >= 6 && h < 14 ? 'Matutino' : h >= 14 && h < 22 ? 'Vespertino' : h >= 0 ? 'Nocturno' : null;
    if (t) { turnos[t].devoluciones++; turnos[t].total++; }
  });

  const maxTurno = Math.max(...Object.values(turnos).map(t => t.total), 1);

  // ── Gráfica de turnos ────────────────────────────────────────────────────────
  const turnoColors: Record<string, string> = { Matutino: '#f59e0b', Vespertino: '#3b82f6', Nocturno: '#6366f1' };
  const turnoItems = Object.entries(turnos).map(([nombre, stat]) => ({
    label: nombre, value: stat.total, color: turnoColors[nombre]
  }));
  const svgTurnos = svgBarChart(turnoItems, maxTurno, 160);

  // ── Gráfica de vigilantes (top 10) ──────────────────────────────────────────
  const top10 = vigilantes.slice(0, 10);
  const vigItems = top10.map((v, i) => ({
    label: v.nombre.split(' ').slice(0, 2).join(' '),
    value: v.total,
    color: i === 0 ? '#16a34a' : i === 1 ? '#2563eb' : i === 2 ? '#7c3aed' : '#64748b'
  }));
  const svgVigilantes = vigItems.length > 0 ? svgBarChart(vigItems, maxTotal, 180) : '<p style="color:#94a3b8">Sin datos en el período</p>';

  // ── Calcular días del período exportado ──────────────────────────────────────
  const fechaInicioStr = options.dateRange?.start || '';
  const fechaFinStr = options.dateRange?.end || '';
  let diasPeriodo = 0;
  let diasActividadPorVigilante: Record<string, Set<string>> = {};

  if (fechaInicioStr && fechaFinStr) {
    const fi = new Date(fechaInicioStr.split('/').reverse().join('-'));
    const ff = new Date(fechaFinStr.split('/').reverse().join('-'));
    diasPeriodo = Math.max(1, Math.round((ff.getTime() - fi.getTime()) / 86400000) + 1);
  } else {
    // Inferir período desde las fechas de las solicitudes
    const todasFechas = todasSolicitudes.map((s: any) => new Date(s.horaEntrega || s.horaDevolucion || s.horaSolicitud)).filter(d => !isNaN(d.getTime()));
    if (todasFechas.length > 0) {
      const minF = new Date(Math.min(...todasFechas.map(d => d.getTime())));
      const maxF = new Date(Math.max(...todasFechas.map(d => d.getTime())));
      diasPeriodo = Math.max(1, Math.round((maxF.getTime() - minF.getTime()) / 86400000) + 1);
    } else {
      diasPeriodo = 1;
    }
  }

  // Calcular días únicos con actividad por vigilante
  todasSolicitudes.forEach((s: any) => {
    const ts = s.horaEntrega || s.horaDevolucion || s.horaSolicitud;
    if (!ts) return;
    const dia = new Date(ts).toISOString().slice(0, 10);
    if (s.entregadoPor) {
      if (!diasActividadPorVigilante[s.entregadoPor]) diasActividadPorVigilante[s.entregadoPor] = new Set();
      diasActividadPorVigilante[s.entregadoPor].add(dia);
    }
    if (s.recibidoPor) {
      if (!diasActividadPorVigilante[s.recibidoPor]) diasActividadPorVigilante[s.recibidoPor] = new Set();
      diasActividadPorVigilante[s.recibidoPor].add(dia);
    }
  });

  // ── Mapa de diasLaborales por nombre de vigilante (si se pasan en data.vigilantes) ──
  const diasLaboralesMap: Record<string, number[] | undefined> = {};
  (data.vigilantes || []).forEach((v: any) => {
    if (v.nombre && v.diasLaborales) diasLaboralesMap[v.nombre] = v.diasLaborales;
  });

  // ── Tabla de ranking de vigilantes ──────────────────────────────────────────
  const rankingRows = vigilantes.map((v, i) => {
    const medal = `${i + 1}`;
    const badge = badgeRendimiento(v.total, maxTotal);
    const pct = maxTotal > 0 ? Math.round((v.total / maxTotal) * 100) : 0;
    const diasConActividad = diasActividadPorVigilante[v.nombre]?.size || 0;
    // Usar diasLaborales del vigilante para calcular días esperados en el período
    const diasLaboralesVig = diasLaboralesMap[v.nombre];
    const diasEsperados = (fechaInicioStr && fechaFinStr)
      ? calcularDiasEsperados(fechaInicioStr, fechaFinStr, diasLaboralesVig)
      : diasPeriodo;
    const diasSinActividad = Math.max(0, diasEsperados - diasConActividad);
    const pctLicencia = diasEsperados > 0 ? Math.round((diasSinActividad / diasEsperados) * 100) : 0;
    // Mostrar días laborales configurados como chips pequeños
    const diasChips = diasLaboralesVig && diasLaboralesVig.length > 0 && diasLaboralesVig.length < 7
      ? `<br><span style="font-size:10px;color:#94a3b8">${['Do','Lu','Ma','Mi','Ju','Vi','Sá'].filter((_,idx) => diasLaboralesVig.includes(idx === 0 ? 0 : idx)).join(' ')}</span>`
      : '';
    const licenciaLabel = diasEsperados > 0
      ? `<span style="font-size:12px;color:#64748b">${diasSinActividad}/${diasEsperados} días <span style="color:${pctLicencia > 30 ? '#dc2626' : pctLicencia > 10 ? '#f59e0b' : '#16a34a'};font-weight:700">(${pctLicencia}%)</span>${diasChips}</span>`
      : '<span style="font-size:12px;color:#94a3b8">—</span>';
    return `<tr style="border-bottom:1px solid #f1f5f9">
      <td style="padding:10px 8px;font-weight:600;font-size:15px">${medal}</td>
      <td style="padding:10px 8px;font-weight:600">${v.nombre}</td>
      <td style="padding:10px 8px;text-align:center;color:#16a34a;font-weight:700">${v.entregas}</td>
      <td style="padding:10px 8px;text-align:center;color:#2563eb;font-weight:700">${v.devoluciones}</td>
      <td style="padding:10px 8px;text-align:center;color:#7c3aed;font-weight:700">${v.objetos}</td>
      <td style="padding:10px 8px;text-align:center;font-weight:800;font-size:16px">${v.total}</td>
      <td style="padding:10px 8px">
        <div style="background:#e2e8f0;border-radius:8px;height:10px;width:120px;display:inline-block;vertical-align:middle">
          <div style="background:#3b82f6;border-radius:8px;height:10px;width:${pct}%"></div>
        </div>
      </td>
      <td style="padding:10px 8px">${licenciaLabel}</td>
      <td style="padding:10px 8px">${badge}</td>
    </tr>`;
  }).join('');

  // ── Vigilantes en licencia (sin actividad en el período) ─────────────────────
  const licenciaMap: Record<string, string> = {};
  [...(data.solicitudesEntregadas || []), ...(data.solicitudesDevueltas || [])].forEach((s: any) => {
    if (s.estadoLicenciaVigilante && s.estadoLicenciaVigilante !== 'activo') {
      const nombre = s.entregadoPor || s.recibidoPor;
      if (nombre) licenciaMap[nombre] = s.estadoLicenciaVigilante === 'licencia' ? 'Licencia' : 'Licencia Médica';
    }
  });
  const vigilantesEnLicencia = Object.entries(licenciaMap);

  // ── Tabla de desempeño por turno ─────────────────────────────────────────────
  const turnoRows = Object.entries(turnos).map(([nombre, stat]) => {
    const badge = badgeRendimiento(stat.total, maxTurno);
    const pct = maxTurno > 0 ? Math.round((stat.total / maxTurno) * 100) : 0;
    return `<tr style="border-bottom:1px solid #f1f5f9">
      <td style="padding:10px 8px;font-weight:700;font-size:15px">${nombre}</td>
      <td style="padding:10px 8px;text-align:center;color:#16a34a;font-weight:700">${stat.entregas}</td>
      <td style="padding:10px 8px;text-align:center;color:#2563eb;font-weight:700">${stat.devoluciones}</td>
      <td style="padding:10px 8px;text-align:center;font-weight:800;font-size:16px">${stat.total}</td>
      <td style="padding:10px 8px">
        <div style="background:#e2e8f0;border-radius:8px;height:10px;width:160px;display:inline-block;vertical-align:middle">
          <div style="background:${turnoColors[nombre]};border-radius:8px;height:10px;width:${pct}%"></div>
        </div>
      </td>
      <td style="padding:10px 8px">${badge}</td>
    </tr>`;
  }).join('');

  // ── Datos secundarios: solicitudes ──────────────────────────────────────────
  const totalPendientes = (data.solicitudesPendientes || []).length;
  const totalEntregadas = (data.solicitudesEntregadas || []).length;
  const totalDevueltas = (data.solicitudesDevueltas || []).length;
  const totalObjetos = (data.objetosOlvidados || []).length;
  const totalAutorizaciones = (data.autorizaciones || []).length;

  const detalleSolicitudesRows = [...(data.solicitudesEntregadas || []), ...(data.solicitudesDevueltas || [])]
    .sort((a: any, b: any) => new Date(b.horaSolicitud).getTime() - new Date(a.horaSolicitud).getTime())
    .slice(0, 50)
    .map((s: any) => {
      const fecha = new Date(s.horaSolicitud).toLocaleDateString('es-UY');
      const hora = new Date(s.horaSolicitud).toLocaleTimeString('es-UY', { hour: '2-digit', minute: '2-digit' });
      const estado = s.estado === 'devuelta' ? '<span style="color:#16a34a">Devuelta</span>' : '<span style="color:#2563eb">Entregada</span>';
      return `<tr style="border-bottom:1px solid #f8fafc">
        <td style="padding:6px 8px">${fecha} ${hora}</td>
        <td style="padding:6px 8px">${s.usuario?.nombre || '-'}</td>
        <td style="padding:6px 8px">${s.lugar?.nombre || '-'}</td>
        <td style="padding:6px 8px">${s.entregadoPor || '-'}</td>
        <td style="padding:6px 8px">${estado}</td>
      </tr>`;
    }).join('');

  const detalleObjetosRows = (data.objetosOlvidados || []).map((o: any) => {
    const fecha = new Date(o.fechaRegistro).toLocaleDateString('es-UY');
    const estado = o.estado === 'devuelto' ? '<span style="color:#16a34a">Devuelto</span>' : '<span style="color:#f59e0b">En custodia</span>';
    return `<tr style="border-bottom:1px solid #f8fafc">
      <td style="padding:6px 8px">${fecha}</td>
      <td style="padding:6px 8px">${o.descripcion || '-'}</td>
      <td style="padding:6px 8px">${o.lugarEncontrado || '-'}</td>
      <td style="padding:6px 8px">${o.registradoPor || '-'}</td>
      <td style="padding:6px 8px">${estado}</td>
    </tr>`;
  }).join('');

  const detalleAutorizacionesRows = (data.autorizaciones || []).map((a: any) => {
    const fecha = new Date(a.fechaAutorizacion).toLocaleDateString('es-UY');
    return `<tr style="border-bottom:1px solid #f8fafc">
      <td style="padding:6px 8px">${fecha}</td>
      <td style="padding:6px 8px">${a.personaNombre || '-'}</td>
      <td style="padding:6px 8px">${a.personaCI || '-'}</td>
      <td style="padding:6px 8px">${a.lugarAutorizado || '-'}</td>
      <td style="padding:6px 8px">${a.autorizadoPor || '-'}</td>
    </tr>`;
  }).join('');

  // ── HTML final ───────────────────────────────────────────────────────────────
  return `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Informe de Desempeño — FCEA</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: 'Segoe UI', Arial, sans-serif; background: #f8fafc; color: #1e293b; }
  .page { max-width: 960px; margin: 0 auto; padding: 32px 24px; }
  h1 { font-size: 28px; font-weight: 800; color: #0f172a; }
  h2 { font-size: 20px; font-weight: 700; color: #1e293b; margin: 32px 0 12px; border-left: 4px solid #3b82f6; padding-left: 12px; }
  h3 { font-size: 15px; font-weight: 600; color: #475569; margin: 20px 0 8px; }
  .portada { background: linear-gradient(135deg,#1e3a5f,#2563eb); color: white; border-radius: 16px; padding: 36px 40px; margin-bottom: 32px; }
  .portada h1 { color: white; font-size: 32px; }
  .portada p { color: #bfdbfe; margin-top: 8px; font-size: 15px; }
  .kpi-grid { display: grid; grid-template-columns: repeat(5,1fr); gap: 12px; margin-bottom: 24px; }
  .kpi { background: white; border-radius: 12px; padding: 16px; text-align: center; box-shadow: 0 1px 4px rgba(0,0,0,.08); }
  .kpi .num { font-size: 32px; font-weight: 800; }
  .kpi .lbl { font-size: 12px; color: #64748b; margin-top: 4px; }
  .card { background: white; border-radius: 12px; padding: 24px; box-shadow: 0 1px 4px rgba(0,0,0,.08); margin-bottom: 20px; overflow-x: auto; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; }
  thead tr { background: #f1f5f9; }
  thead th { padding: 10px 8px; text-align: left; font-weight: 600; color: #475569; font-size: 12px; text-transform: uppercase; letter-spacing: .5px; }
  .chart-wrap { overflow-x: auto; padding-bottom: 8px; }
  .footer { text-align: center; color: #94a3b8; font-size: 12px; margin-top: 40px; padding-top: 20px; border-top: 1px solid #e2e8f0; }
  @media print { body { background: white; } .page { padding: 16px; } }
</style>
</head>
<body>
<div class="page">

  <!-- PORTADA -->
  <div class="portada">
    <h1>Informe de Desempeño del Personal</h1>
    <p>Sistema de Gestión de Llaves — FCEA UdelaR</p>
    <p style="margin-top:16px;font-size:14px">Período: <strong style="color:white">${periodo}</strong> &nbsp;|&nbsp; Generado: ${ahora}</p>
  </div>

  <!-- KPIs -->
  <div class="kpi-grid">
    <div class="kpi"><div class="num" style="color:#16a34a">${totalEntregadas}</div><div class="lbl">Llaves Entregadas</div></div>
    <div class="kpi"><div class="num" style="color:#2563eb">${totalDevueltas}</div><div class="lbl">Llaves Devueltas</div></div>
    <div class="kpi"><div class="num" style="color:#f59e0b">${totalPendientes}</div><div class="lbl">Pendientes</div></div>
    <div class="kpi"><div class="num" style="color:#7c3aed">${totalObjetos}</div><div class="lbl">Objetos Olvidados</div></div>
    <div class="kpi"><div class="num" style="color:#0891b2">${totalAutorizaciones}</div><div class="lbl">Autorizaciones</div></div>
  </div>

  <!-- SECCIÓN 1: RANKING DE VIGILANTES -->
  <h2>Ranking de Desempeño — Vigilantes</h2>
  <div class="card">
    <h3>Gráfica de actividad por vigilante (top ${top10.length})</h3>
    <div class="chart-wrap">${svgVigilantes}</div>
  </div>
  <div class="card">
    <table>
      <thead><tr>
        <th>#</th><th>Vigilante</th>
        <th style="text-align:center;color:#16a34a">Entregas</th>
        <th style="text-align:center;color:#2563eb">Devoluciones</th>
        <th style="text-align:center;color:#7c3aed">Objetos</th>
        <th style="text-align:center">Total</th>
        <th>Actividad</th>
        <th>Días sin actividad / Total período</th>
        <th>Rendimiento</th>
      </tr></thead>
      <tbody>${rankingRows || '<tr><td colspan="9" style="padding:20px;text-align:center;color:#94a3b8">Sin actividad en el período seleccionado</td></tr>'}</tbody>
    </table>
  </div>

  <!-- SECCIÓN 2: DESEMPEÑO POR TURNO -->
  <h2>Desempeño por Turno</h2>
  <div class="card">
    <h3>Actividad total por turno</h3>
    <div class="chart-wrap">${svgTurnos}</div>
  </div>
  <div class="card">
    <table>
      <thead><tr>
        <th>Turno</th>
        <th style="text-align:center;color:#16a34a">Entregas</th>
        <th style="text-align:center;color:#2563eb">Devoluciones</th>
        <th style="text-align:center">Total</th>
        <th>Carga de trabajo</th>
        <th>Nivel</th>
      </tr></thead>
      <tbody>${turnoRows}</tbody>
    </table>
  </div>

  <!-- SECCIÓN 3 (SECUNDARIA): DETALLE DE SOLICITUDES -->
  ${detalleSolicitudesRows ? `
  <h2>Detalle de Solicitudes (últimas 50)</h2>
  <div class="card">
    <table>
      <thead><tr><th>Fecha/Hora</th><th>Usuario</th><th>Lugar</th><th>Vigilante</th><th>Estado</th></tr></thead>
      <tbody>${detalleSolicitudesRows}</tbody>
    </table>
  </div>` : ''}

  <!-- SECCIÓN 4 (SECUNDARIA): OBJETOS OLVIDADOS -->
  ${detalleObjetosRows ? `
  <h2>Objetos Olvidados</h2>
  <div class="card">
    <table>
      <thead><tr><th>Fecha</th><th>Descripción</th><th>Lugar</th><th>Registrado Por</th><th>Estado</th></tr></thead>
      <tbody>${detalleObjetosRows}</tbody>
    </table>
  </div>` : ''}

  <!-- SECCIÓN 5 (SECUNDARIA): AUTORIZACIONES -->
  ${detalleAutorizacionesRows ? `
  <h2>Autorizaciones</h2>
  <div class="card">
    <table>
      <thead><tr><th>Fecha</th><th>Persona</th><th>CI</th><th>Lugar</th><th>Autorizado Por</th></tr></thead>
      <tbody>${detalleAutorizacionesRows}</tbody>
    </table>
  </div>` : ''}

  <!-- SECCIÓN 6 (SECUNDARIA): VIGILANTES EN LICENCIA -->
  ${vigilantesEnLicencia.length > 0 ? `
  <h2>Personal en Licencia durante el Período</h2>
  <div class="card">
    <table>
      <thead><tr>
        <th>Vigilante</th>
        <th>Tipo de Licencia</th>
      </tr></thead>
      <tbody>
        ${vigilantesEnLicencia.map(([nombre, tipo]) => `
        <tr style="border-bottom:1px solid #f8fafc">
          <td style="padding:8px">${nombre}</td>
          <td style="padding:8px">
            ${tipo === 'Licencia Médica'
              ? '<span style="background:#fee2e2;color:#991b1b;padding:2px 10px;border-radius:12px;font-size:12px">🏥 Licencia Médica</span>'
              : '<span style="background:#fef9c3;color:#854d0e;padding:2px 10px;border-radius:12px;font-size:12px">🌴 Licencia</span>'}
          </td>
        </tr>`).join('')}
      </tbody>
    </table>
  </div>` : ''}

  <!-- SECCIÓN 7 (SECUNDARIA): DATOS COMPLETOS CSV -->
  <h2>Datos Completos del Período (formato tabla)</h2>
  <div class="card">
    <h3>Todas las operaciones registradas</h3>
    <div style="overflow-x:auto">
    <table>
      <thead><tr>
        <th>Fecha</th><th>Hora</th><th>Tipo</th><th>Lugar / Descripción</th><th>Usuario / Receptor</th><th>Vigilante</th><th>Turno</th>
      </tr></thead>
      <tbody>
        ${[
          ...(data.solicitudesEntregadas || []).map((s: any) => ({
            fecha: s.horaEntrega ? new Date(s.horaEntrega).toLocaleDateString('es-UY') : '-',
            hora: s.horaEntrega ? new Date(s.horaEntrega).toLocaleTimeString('es-UY', { hour: '2-digit', minute: '2-digit' }) : '-',
            tipo: '<span style="color:#16a34a">Entrega Llave</span>',
            lugar: s.lugar?.nombre || '-',
            usuario: s.usuario?.nombre || '-',
            vigilante: s.entregadoPor || '-',
            turno: (() => { const h = s.horaEntrega ? new Date(s.horaEntrega).getHours() : -1; return h >= 6 && h < 14 ? 'Matutino' : h >= 14 && h < 22 ? 'Vespertino' : h >= 0 ? 'Nocturno' : '-'; })(),
            ts: s.horaEntrega || '',
          })),
          ...(data.solicitudesDevueltas || []).map((s: any) => ({
            fecha: s.horaDevolucion ? new Date(s.horaDevolucion).toLocaleDateString('es-UY') : '-',
            hora: s.horaDevolucion ? new Date(s.horaDevolucion).toLocaleTimeString('es-UY', { hour: '2-digit', minute: '2-digit' }) : '-',
            tipo: '<span style="color:#2563eb">Devolución Llave</span>',
            lugar: s.lugar?.nombre || '-',
            usuario: s.usuario?.nombre || '-',
            vigilante: s.recibidoPor || s.entregadoPor || '-',
            turno: (() => { const h = s.horaDevolucion ? new Date(s.horaDevolucion).getHours() : -1; return h >= 6 && h < 14 ? 'Matutino' : h >= 14 && h < 22 ? 'Vespertino' : h >= 0 ? 'Nocturno' : '-'; })(),
            ts: s.horaDevolucion || '',
          })),
          ...(data.objetosOlvidados || []).map((o: any) => ({
            fecha: o.fechaRegistro ? new Date(o.fechaRegistro).toLocaleDateString('es-UY') : '-',
            hora: o.fechaRegistro ? new Date(o.fechaRegistro).toLocaleTimeString('es-UY', { hour: '2-digit', minute: '2-digit' }) : '-',
            tipo: '<span style="color:#f59e0b">📦 Objeto Registrado</span>',
            lugar: o.lugarEncontrado || '-',
            usuario: o.descripcion || '-',
            vigilante: o.registradoPor || '-',
            turno: (() => { const h = o.fechaRegistro ? new Date(o.fechaRegistro).getHours() : -1; return h >= 6 && h < 14 ? 'Matutino' : h >= 14 && h < 22 ? 'Vespertino' : h >= 0 ? 'Nocturno' : '-'; })(),
            ts: o.fechaRegistro || '',
          })),
          ...(data.autorizaciones || []).map((a: any) => ({
            fecha: a.fechaAutorizacion ? new Date(a.fechaAutorizacion).toLocaleDateString('es-UY') : '-',
            hora: a.fechaAutorizacion ? new Date(a.fechaAutorizacion).toLocaleTimeString('es-UY', { hour: '2-digit', minute: '2-digit' }) : '-',
            tipo: '<span style="color:#0891b2">✅ Autorización</span>',
            lugar: a.lugarAutorizado || '-',
            usuario: `${a.personaNombre || '-'} (CI: ${a.personaCI || '-'})`,
            vigilante: a.autorizadoPor || '-',
            turno: '-',
            ts: a.fechaAutorizacion || '',
          })),
        ]
        .sort((a: any, b: any) => new Date(b.ts).getTime() - new Date(a.ts).getTime())
        .map((r: any) => `<tr style="border-bottom:1px solid #f8fafc">
          <td style="padding:6px 8px;white-space:nowrap">${r.fecha}</td>
          <td style="padding:6px 8px;white-space:nowrap">${r.hora}</td>
          <td style="padding:6px 8px;white-space:nowrap">${r.tipo}</td>
          <td style="padding:6px 8px">${r.lugar}</td>
          <td style="padding:6px 8px">${r.usuario}</td>
          <td style="padding:6px 8px;white-space:nowrap">${r.vigilante}</td>
          <td style="padding:6px 8px;white-space:nowrap">${r.turno}</td>
        </tr>`).join('')}
      </tbody>
    </table>
    </div>
  </div>

  <div class="footer">
    <p>Informe generado automáticamente por el Sistema de Gestión de Llaves — FCEA UdelaR</p>
    <p style="margin-top:4px">Para imprimir: Ctrl+P → Guardar como PDF</p>
  </div>
</div>
</body>
</html>`;
}

export async function exportToExcel(data: any, filename: string, options: any = {}) {
  const htmlContent = generarInformeHTML(data, options);
  return await guardarArchivo(htmlContent, `${filename}_Informe.html`, 'text/html');
}