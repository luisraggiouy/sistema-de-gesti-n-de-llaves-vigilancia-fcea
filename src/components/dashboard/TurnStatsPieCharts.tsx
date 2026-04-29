import React, { useState, useMemo } from 'react';
import { 
  PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip, 
  Sector, Label
} from 'recharts';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { CalendarClock, Clock, BarChart } from 'lucide-react';
import { Turno } from '@/data/fceaData';

// Tipos para los datos de estadísticas
interface TurnStats {
  turno: Turno;
  entregadas: number;
  devueltas: number;
  pendientes: number;
  porcentajeDevolucion: number;
}

interface StatsPeriod {
  label: string;
  stats: TurnStats[];
  desde: Date;
  hasta: Date;
}

// Props del componente
interface TurnStatsPieChartsProps {
  solicitudes: any[]; // Adaptar al tipo correcto de solicitudes
}

// Colores para los gráficos
const COLORS = {
  devueltas: '#4ade80', // verde
  pendientes: '#f87171', // rojo
  matutino: '#f59e0b', // amarillo ámbar
  vespertino: '#3b82f6', // azul
  nocturno: '#6366f1' // violeta
};

// Renderizador personalizado para el sector activo del gráfico
const renderActiveShape = (props: any) => {
  const { 
    cx, cy, innerRadius, outerRadius, startAngle, endAngle,
    fill, payload, value, percent
  } = props;

  return (
    <g>
      <Sector
        cx={cx}
        cy={cy}
        innerRadius={innerRadius}
        outerRadius={outerRadius + 6}
        startAngle={startAngle}
        endAngle={endAngle}
        fill={fill}
      />
      <text x={cx} y={cy - 8} textAnchor="middle" dominantBaseline="central" fill="#000">
        {payload.name}
      </text>
      <text x={cx} y={cy + 8} textAnchor="middle" dominantBaseline="central" fill="#666" fontSize={12}>
        {`${(percent * 100).toFixed(0)}%`}
      </text>
    </g>
  );
};

// Calcular turno a partir de la hora
function calcularTurnoDesdeHora(fecha: Date): Turno {
  const hora = fecha.getHours();
  if (hora >= 6 && hora < 14) return 'Matutino';
  if (hora >= 14 && hora < 22) return 'Vespertino';
  return 'Nocturno';
}

// Funciones auxiliares para calcular las estadísticas
function calcularEstadisticasPeriodo(
  solicitudes: any[], 
  desde: Date, 
  hasta: Date
): StatsPeriod {
  const turnos: Turno[] = ['Matutino', 'Vespertino', 'Nocturno'];
  const filtradas = solicitudes.filter(s => {
    const fecha = new Date(s.horaEntrega || s.horaSolicitud || s.fechaSolicitud);
    return fecha >= desde && fecha <= hasta && (s.estado === 'entregada' || s.estado === 'devuelta');
  });

  const stats = turnos.map(turno => {
    // Calcular turno desde la hora de entrega
    const solicitudesTurno = filtradas.filter(s => {
      const fecha = new Date(s.horaEntrega || s.horaSolicitud);
      return calcularTurnoDesdeHora(fecha) === turno;
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

  return {
    label: `${desde.toLocaleDateString('es-UY')} - ${hasta.toLocaleDateString('es-UY')}`,
    stats,
    desde,
    hasta
  };
}

export default function TurnStatsPieCharts({ solicitudes }: TurnStatsPieChartsProps) {
  const [activeIndex, setActiveIndex] = useState<number | null>(null);
  const [periodType, setPeriodType] = useState<'mensual' | 'semestral' | 'anual'>('mensual');

  // Calcular los periodos de tiempo para las estadísticas
  const periodos = useMemo(() => {
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

    // Últimos 3 meses
    const inicioTresMeses = new Date(ahora.getFullYear(), ahora.getMonth() - 2, 1);
    periodos.mensual.push(
      calcularEstadisticasPeriodo(solicitudes, inicioTresMeses, finMes)
    );

    // Último semestre
    const inicioSemestre = new Date(ahora.getFullYear(), ahora.getMonth() - 5, 1);
    periodos.semestral.push(
      calcularEstadisticasPeriodo(solicitudes, inicioSemestre, finMes)
    );

    // Último año
    const inicioAño = new Date(ahora.getFullYear(), ahora.getMonth() - 11, 1);
    periodos.anual.push(
      calcularEstadisticasPeriodo(solicitudes, inicioAño, finMes)
    );

    return periodos;
  }, [solicitudes]);

  // Datos actuales según el periodo seleccionado
  const periodoActual = useMemo(() => {
    return periodos[periodType][0];
  }, [periodos, periodType]);

  // Manejar el hover en los sectores del gráfico
  const onPieEnter = (dataIndex: number) => {
    setActiveIndex(dataIndex);
  };

  const onPieLeave = () => {
    setActiveIndex(null);
  };

  return (
    <Card className="col-span-full">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <BarChart className="w-5 h-5" />
          Estadísticas de Devoluciones por Turno
        </CardTitle>
        <CardDescription>
          Análisis de la tasa de devoluciones por turno en diferentes períodos de tiempo.
          Las gráficas muestran el porcentaje de llaves que fueron devueltas satisfactoriamente.
        </CardDescription>
        
        <Tabs defaultValue="mensual" value={periodType} onValueChange={(v: string) => setPeriodType(v as any)}>
          <TabsList className="grid grid-cols-3 w-[400px]">
            <TabsTrigger value="mensual" className="flex items-center gap-1">
              <Clock className="w-3 h-3" />
              <span>Mensual</span>
            </TabsTrigger>
            <TabsTrigger value="semestral" className="flex items-center gap-1">
              <Clock className="w-3 h-3" />
              <span>Semestral</span>
            </TabsTrigger>
            <TabsTrigger value="anual" className="flex items-center gap-1">
              <CalendarClock className="w-3 h-3" />
              <span>Anual</span>
            </TabsTrigger>
          </TabsList>
        </Tabs>
      </CardHeader>

      <CardContent className="pt-2 pb-6">
        <div className="flex items-center justify-between mb-2">
          <p className="text-sm text-muted-foreground">
            Período: <strong>{periodoActual?.label}</strong>
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {periodoActual?.stats.map((stat, index) => {
            // Datos para el gráfico circular
            const pieData = [
              { name: 'Devueltas', value: stat.devueltas, color: COLORS.devueltas },
              { name: 'Pendientes', value: stat.pendientes, color: COLORS.pendientes }
            ].filter(item => item.value > 0);

            // Solo mostrar turnos con entrega
            if (stat.entregadas === 0) {
              return null;
            }

            // Color del turno
            let turnColor = '';
            switch(stat.turno) {
              case 'Matutino': turnColor = COLORS.matutino; break;
              case 'Vespertino': turnColor = COLORS.vespertino; break;
              case 'Nocturno': turnColor = COLORS.nocturno; break;
            }

            return (
              <div key={stat.turno} className="flex flex-col items-center">
                <div className="mb-2 w-full text-center">
                  <div className="flex justify-center items-center gap-2">
                    <Badge style={{ backgroundColor: turnColor }} className="text-white">
                      {stat.turno}
                    </Badge>
                    <span className="text-sm text-muted-foreground">
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
                        activeIndex={activeIndex}
                        activeShape={renderActiveShape}
                        onMouseEnter={onPieEnter}
                        onMouseLeave={onPieLeave}
                      >
                        {pieData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                        <Label 
                          value={`${stat.porcentajeDevolucion.toFixed(0)}%`} 
                          position="center"
                          fill="#666"
                          style={{ fontSize: '24px', fontWeight: 'bold', color: '#333' }}
                        />
                      </Pie>
                      <Tooltip formatter={(value) => [`${value} llaves`, '']} />
                      <Legend 
                        verticalAlign="bottom" 
                        iconType="circle"
                        iconSize={10}
                      />
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

        <div className="mt-6 border-t pt-4">
          <div className="flex items-center justify-between">
            <p className="text-sm text-muted-foreground">
              <span className="font-semibold">Total de Llaves:</span> {
                periodoActual?.stats.reduce((acc, stat) => acc + stat.entregadas, 0)
              }
            </p>
            <p className="text-sm text-muted-foreground">
              <span className="font-semibold">Tasa Media de Devolución:</span> {
                periodoActual?.stats.reduce((acc, stat, _, arr) => {
                  const totalEntregadas = arr.reduce((sum, s) => sum + s.entregadas, 0);
                  const totalDevueltas = arr.reduce((sum, s) => sum + s.devueltas, 0);
                  return totalEntregadas > 0 ? (totalDevueltas / totalEntregadas) * 100 : 0;
                }, 0).toFixed(1)
              }%
            </p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}