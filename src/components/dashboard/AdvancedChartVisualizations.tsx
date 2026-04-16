import React, { useState, useRef, useCallback } from 'react';
import { 
  PieChart, Pie, Cell, Legend, Tooltip, Label,
  BarChart, Bar, XAxis, YAxis, CartesianGrid, 
  LineChart, Line, ResponsiveContainer
} from 'recharts';
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { 
  BarChart2, LineChart as LineChartIcon, PieChart as PieChartIcon,
  CalendarClock, Download, ImageDown, Clock
} from 'lucide-react';
import { Turno } from '@/data/fceaData';
import html2canvas from 'html2canvas';
import { saveAs } from 'file-saver';

// Tipos para los datos de estadísticas
interface TurnStats {
  turno: Turno;
  entregadas: number;
  devueltas: number;
  pendientes: number;
  porcentajeDevolucion: number;
}

interface MonthlyStatsData {
  mes: string;
  Matutino: number;
  Vespertino: number;
  Nocturno: number;
  total: number;
}

interface StatsPeriod {
  label: string;
  stats: TurnStats[];
  monthlyData: MonthlyStatsData[];
  desde: Date;
  hasta: Date;
}

// Props del componente
interface AdvancedChartVisualizationsProps {
  solicitudes: any[]; // Adaptar al tipo correcto de solicitudes
  className?: string;
}

// Colores para los gráficos
const COLORS = {
  devueltas: '#4ade80', // verde
  pendientes: '#f87171', // rojo
  matutino: '#f59e0b', // amarillo ámbar
  vespertino: '#3b82f6', // azul
  nocturno: '#6366f1', // violeta
  total: '#64748b' // gris azulado
};

// Función auxiliar para generar datos mensuales
function generateMonthlyData(solicitudes: any[], desde: Date, hasta: Date): MonthlyStatsData[] {
  const monthlyData: MonthlyStatsData[] = [];
  const currentDate = new Date(desde);
  
  // Creamos un array con todos los meses en el rango
  while (currentDate <= hasta) {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    const monthName = new Date(year, month, 1).toLocaleString('es', { month: 'short' });
    
    // Filtrar solicitudes para este mes
    const solicitudesMes = solicitudes.filter(s => {
      const fecha = new Date(s.horaSolicitud);
      return fecha.getFullYear() === year && fecha.getMonth() === month;
    });
    
    // Contar por turno
    const calcTurno = (s: any) => {
      const fecha = new Date(s.horaEntrega || s.horaSolicitud);
      const hora = fecha.getHours();
      if (hora >= 6 && hora < 14) return 'Matutino';
      if (hora >= 14 && hora < 22) return 'Vespertino';
      return 'Nocturno';
    };
    const matutino = solicitudesMes.filter(s => calcTurno(s) === 'Matutino').length;
    const vespertino = solicitudesMes.filter(s => calcTurno(s) === 'Vespertino').length;
    const nocturno = solicitudesMes.filter(s => calcTurno(s) === 'Nocturno').length;
    
    monthlyData.push({
      mes: monthName,
      Matutino: matutino,
      Vespertino: vespertino,
      Nocturno: nocturno,
      total: matutino + vespertino + nocturno
    });
    
    // Avanzar al siguiente mes
    currentDate.setMonth(currentDate.getMonth() + 1);
  }
  
  return monthlyData;
}

// Funciones auxiliares para calcular las estadísticas
function calcTurnoFromDate(fecha: Date): Turno {
  const hora = fecha.getHours();
  if (hora >= 6 && hora < 14) return 'Matutino';
  if (hora >= 14 && hora < 22) return 'Vespertino';
  return 'Nocturno';
}

function calcularEstadisticasPeriodo(
  solicitudes: any[], 
  desde: Date, 
  hasta: Date
): StatsPeriod {
  const turnos: Turno[] = ['Matutino', 'Vespertino', 'Nocturno'];
  const filtradas = solicitudes.filter(s => {
    const fecha = new Date(s.horaEntrega || s.horaSolicitud);
    return fecha >= desde && fecha <= hasta && (s.estado === 'entregada' || s.estado === 'devuelta');
  });

  const stats = turnos.map(turno => {
    const solicitudesTurno = filtradas.filter(s => {
      const fecha = new Date(s.horaEntrega || s.horaSolicitud);
      return calcTurnoFromDate(fecha) === turno;
    });
    const entregadas = solicitudesTurno.length;
    const devueltas = solicitudesTurno.filter(s => s.estado === 'devuelta').length;
    const pendientes = entregadas - devueltas;
    const porcentajeDevolucion = entregadas > 0 ? (devueltas / entregadas) * 100 : 0;

    return {
      turno,
      entregadas,
      devueltas,
      pendientes,
      porcentajeDevolucion
    };
  });

  // Generar datos mensuales para gráficas temporales
  const monthlyData = generateMonthlyData(filtradas, desde, hasta);

  return {
    label: `${desde.toLocaleDateString()} - ${hasta.toLocaleDateString()}`,
    stats,
    monthlyData,
    desde,
    hasta
  };
}

export default function AdvancedChartVisualizations({ solicitudes, className = "" }: AdvancedChartVisualizationsProps) {
  const [chartType, setChartType] = useState<'pie' | 'bar' | 'line'>('pie');
  const [periodType, setPeriodType] = useState<'mensual' | 'semestral' | 'anual'>('mensual');
  const chartContainerRef = useRef<HTMLDivElement>(null);
  
  // Calcular los periodos de tiempo para las estadísticas
  const periodos = React.useMemo(() => {
    const ahora = new Date();
    const periodos: {
      mensual: StatsPeriod[],
      semestral: StatsPeriod[],
      anual: StatsPeriod[]
    } = {
      mensual: [],
      semestral: [],
      anual: []
    };

    // Último mes
    const inicioMes = new Date(ahora.getFullYear(), ahora.getMonth(), 1);
    const finMes = new Date(ahora.getFullYear(), ahora.getMonth() + 1, 0);
    periodos.mensual.push(
      calcularEstadisticasPeriodo(solicitudes, inicioMes, finMes)
    );

    // Último semestre (6 meses)
    const inicioSemestre = new Date(ahora.getFullYear(), ahora.getMonth() - 5, 1);
    periodos.semestral.push(
      calcularEstadisticasPeriodo(solicitudes, inicioSemestre, finMes)
    );

    // Último año (12 meses)
    const inicioAño = new Date(ahora.getFullYear(), ahora.getMonth() - 11, 1);
    periodos.anual.push(
      calcularEstadisticasPeriodo(solicitudes, inicioAño, finMes)
    );

    return periodos;
  }, [solicitudes]);

  // Datos actuales según el periodo seleccionado
  const periodoActual = React.useMemo(() => {
    return periodos[periodType][0];
  }, [periodos, periodType]);

  // Función para exportar a imagen
  const exportToImage = useCallback(() => {
    if (!chartContainerRef.current) return;

    // Manejar la exportación del gráfico como imagen
    html2canvas(chartContainerRef.current, {
      scale: 2, // Mayor calidad
      backgroundColor: '#ffffff',
      logging: false
    }).then(canvas => {
      // Convertir a blob
      canvas.toBlob((blob) => {
        if (!blob) return;
        
        // Generar nombre de archivo
        const ahora = new Date();
        const timestamp = ahora.toISOString().replace(/[:.]/g, '-');
        const fileName = `estadisticas_llaves_${chartType}_${periodType}_${timestamp}.png`;
        
        // Descargar imagen
        saveAs(blob, fileName);
      });
    });
  }, [chartType, periodType]);

  // Datos para el gráfico de barras
  const barData = React.useMemo(() => {
    if (!periodoActual) return [];
    
    return periodoActual.stats.map(stat => ({
      turno: stat.turno,
      Entregadas: stat.entregadas,
      Devueltas: stat.devueltas,
      Pendientes: stat.pendientes,
      "% Devolución": parseFloat(stat.porcentajeDevolucion.toFixed(1))
    }));
  }, [periodoActual]);

  // Datos para la línea temporal
  const lineData = React.useMemo(() => {
    if (!periodoActual) return [];
    return periodoActual.monthlyData;
  }, [periodoActual]);

  return (
    <Card className={`col-span-full ${className}`}>
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            {chartType === 'pie' && <PieChartIcon className="w-5 h-5" />}
            {chartType === 'bar' && <BarChart2 className="w-5 h-5" />}
            {chartType === 'line' && <LineChartIcon className="w-5 h-5" />}
            Estadísticas de Devoluciones por Turno
          </div>
          <Button 
            variant="outline" 
            size="sm" 
            className="gap-2"
            onClick={exportToImage}
          >
            <ImageDown className="w-4 h-4" />
            Exportar como Imagen
          </Button>
        </CardTitle>
        <CardDescription>
          {chartType === 'pie' && 'Visualización de la proporción de devoluciones por turno en gráficos circulares.'}
          {chartType === 'bar' && 'Comparación entre llaves entregadas y devueltas por turno en gráficos de barras.'}
          {chartType === 'line' && 'Evolución temporal de la actividad de llaves por turno.'}
        </CardDescription>
      </CardHeader>

      <CardContent>
        <div className="flex flex-wrap justify-between mb-4 gap-4">
          {/* Selector de tipo de gráfico */}
          <Tabs defaultValue="pie" value={chartType} onValueChange={(v) => setChartType(v as any)}>
            <TabsList>
              <TabsTrigger value="pie" className="flex items-center gap-1">
                <PieChartIcon className="w-4 h-4" />
                <span>Torta</span>
              </TabsTrigger>
              <TabsTrigger value="bar" className="flex items-center gap-1">
                <BarChart2 className="w-4 h-4" />
                <span>Barras</span>
              </TabsTrigger>
              <TabsTrigger value="line" className="flex items-center gap-1">
                <LineChartIcon className="w-4 h-4" />
                <span>Línea Temporal</span>
              </TabsTrigger>
            </TabsList>
          </Tabs>

          {/* Selector de periodo */}
          <Tabs defaultValue="mensual" value={periodType} onValueChange={(v) => setPeriodType(v as any)}>
            <TabsList>
              <TabsTrigger value="mensual" className="flex items-center gap-1">
                <Clock className="w-4 h-4" />
                <span>Mensual</span>
              </TabsTrigger>
              <TabsTrigger value="semestral" className="flex items-center gap-1">
                <Clock className="w-4 h-4" />
                <span>Semestral</span>
              </TabsTrigger>
              <TabsTrigger value="anual" className="flex items-center gap-1">
                <CalendarClock className="w-4 h-4" />
                <span>Anual</span>
              </TabsTrigger>
            </TabsList>
          </Tabs>
        </div>

        <div className="text-sm text-muted-foreground mb-4">
          Período: <strong>{periodoActual?.label}</strong>
        </div>

        {/* Contenedor de gráficos */}
        <div 
          ref={chartContainerRef}
          className="bg-white p-4 rounded-lg border border-gray-200"
        >
          {/* Gráfico de tipo Torta */}
          {chartType === 'pie' && (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {periodoActual?.stats.map((stat) => {
                if (stat.entregadas === 0) return null;
                
                // Datos para el gráfico circular
                const pieData = [
                  { name: 'Devueltas', value: stat.devueltas, color: COLORS.devueltas },
                  { name: 'Pendientes', value: stat.pendientes, color: COLORS.pendientes }
                ].filter(item => item.value > 0);

                // Color según el turno
                let turnColor = '';
                switch(stat.turno) {
                  case 'Matutino': turnColor = COLORS.matutino; break;
                  case 'Vespertino': turnColor = COLORS.vespertino; break;
                  case 'Nocturno': turnColor = COLORS.nocturno; break;
                }

                return (
                  <div key={stat.turno} className="flex flex-col items-center">
                    <div className="mb-2 w-full text-center">
                      <Badge style={{ backgroundColor: turnColor }} className="text-white">
                        {stat.turno}
                      </Badge>
                      <div className="mt-1">
                        <span className="text-sm">
                          Tasa de devolución: 
                          <span 
                            className={`ml-1 font-bold ${
                              stat.porcentajeDevolucion >= 98 ? 'text-green-600' : 
                              stat.porcentajeDevolucion >= 90 ? 'text-amber-500' : 
                              'text-red-500'
                            }`}
                          >
                            {stat.porcentajeDevolucion.toFixed(1)}%
                          </span>
                        </span>
                      </div>
                    </div>

                    <div className="w-full h-[180px]">
                      <ResponsiveContainer width="100%" height="100%">
                        <PieChart>
                          <Pie
                            data={pieData}
                            cx="50%"
                            cy="50%"
                            innerRadius={60}
                            outerRadius={80}
                            paddingAngle={1}
                            dataKey="value"
                          >
                            {pieData.map((entry, index) => (
                              <Cell key={`cell-${index}`} fill={entry.color} />
                            ))}
                            <Label 
                              value={`${stat.porcentajeDevolucion.toFixed(0)}%`} 
                              position="center"
                              style={{ fontSize: '24px', fontWeight: 'bold', fill: '#333' }}
                            />
                          </Pie>
                          <Tooltip formatter={(value) => [`${value} llaves`, '']} />
                          <Legend verticalAlign="bottom" iconType="circle" iconSize={10} />
                        </PieChart>
                      </ResponsiveContainer>
                    </div>

                    <div className="mt-2 text-center">
                      <div className="text-sm grid grid-cols-1 gap-1">
                        <div className="flex justify-between">
                          <span>Entregadas:</span>
                          <span className="font-bold">{stat.entregadas}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Devueltas:</span>
                          <span className="font-bold text-green-600">{stat.devueltas}</span>
                        </div>
                        <div className="flex justify-between">
                          <span>Pendientes:</span>
                          <span className="font-bold text-red-500">{stat.pendientes}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Gráfico de tipo Barras */}
          {chartType === 'bar' && (
            <div className="h-[400px] w-full">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={barData}
                  margin={{ top: 20, right: 30, left: 20, bottom: 5 }}
                >
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="turno" />
                  <YAxis yAxisId="left" orientation="left" stroke="#000" />
                  <YAxis yAxisId="right" orientation="right" stroke="#FF8042" />
                  <Tooltip />
                  <Legend />
                  <Bar yAxisId="left" dataKey="Entregadas" fill={COLORS.vespertino} />
                  <Bar yAxisId="left" dataKey="Devueltas" fill={COLORS.devueltas} />
                  <Bar yAxisId="left" dataKey="Pendientes" fill={COLORS.pendientes} />
                  <Bar yAxisId="right" dataKey="% Devolución" fill={COLORS.matutino} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}

          {/* Gráfico de tipo Línea Temporal */}
          {chartType === 'line' && (
            <div className="h-[400px] w-full">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart
                  data={lineData}
                  margin={{ top: 5, right: 30, left: 20, bottom: 5 }}
                >
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="mes" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="Matutino" stroke={COLORS.matutino} strokeWidth={2} />
                  <Line type="monotone" dataKey="Vespertino" stroke={COLORS.vespertino} strokeWidth={2} />
                  <Line type="monotone" dataKey="Nocturno" stroke={COLORS.nocturno} strokeWidth={2} />
                  <Line type="monotone" dataKey="total" stroke={COLORS.total} strokeWidth={3} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          )}
        </div>
      </CardContent>

      <CardFooter className="flex justify-between border-t pt-4">
        <div className="text-sm text-muted-foreground">
          <span className="font-semibold">Total de Llaves:</span> {
            periodoActual?.stats.reduce((acc, stat) => acc + stat.entregadas, 0)
          }
        </div>
        <div className="text-sm text-muted-foreground">
          <span className="font-semibold">Tasa Media de Devolución:</span> {
            periodoActual?.stats.reduce((acc, stat, _, arr) => {
              const totalEntregadas = arr.reduce((sum, s) => sum + s.entregadas, 0);
              const totalDevueltas = arr.reduce((sum, s) => sum + s.devueltas, 0);
              return totalEntregadas > 0 ? (totalDevueltas / totalEntregadas) * 100 : 0;
            }, 0).toFixed(1)
          }%
        </div>
      </CardFooter>
    </Card>
  );
}