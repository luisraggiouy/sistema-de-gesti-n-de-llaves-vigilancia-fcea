import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { BarChart3, ArrowLeft, Clock, Users, Key, ArrowUpRight, ArrowDownLeft, Sun, Sunset, Moon, FileSpreadsheet } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';
import { Turno, vigilantes } from '@/data/fceaData';
import { EstadisticasTurno, EstadisticasVigilante } from '@/types/estadisticas';
import { ExportReportModal } from '@/components/dashboard/ExportReportModal';

const turnosConfig: Record<Turno, { label: string; horario: string; color: string; icon: typeof Sun }> = {
  'Matutino': { label: 'Turno Matutino', horario: '06:00 - 14:00', color: 'bg-amber-500', icon: Sun },
  'Vespertino': { label: 'Turno Vespertino', horario: '14:00 - 22:00', color: 'bg-blue-500', icon: Sunset },
  'Nocturno': { label: 'Turno Nocturno', horario: '22:00 - 06:00', color: 'bg-indigo-900', icon: Moon },
};

export default function Dashboard() {
  const { registrosActividad } = useSolicitudesContext();
  const [, setTick] = useState(0);
  const [exportModalOpen, setExportModalOpen] = useState(false);

  // Auto-refresh cada minuto
  useEffect(() => {
    const interval = setInterval(() => setTick(t => t + 1), 60000);
    return () => clearInterval(interval);
  }, []);

  // Calcular estadísticas por turno
  const calcularEstadisticas = (): EstadisticasTurno[] => {
    const turnos: Turno[] = ['Matutino', 'Vespertino', 'Nocturno'];
    
    return turnos.map(turno => {
      const registrosTurno = registrosActividad.filter(r => r.turno === turno);
      const vigilantesTurno = vigilantes.filter(v => v.turno === turno);
      
      const entregas = registrosTurno.filter(r => r.tipo === 'entrega').length;
      const devoluciones = registrosTurno.filter(r => r.tipo === 'devolucion').length;
      
      const estadisticasVigilantes: EstadisticasVigilante[] = vigilantesTurno.map(v => {
        const registrosVigilante = registrosTurno.filter(r => r.vigilante === v.nombre);
        const entregasV = registrosVigilante.filter(r => r.tipo === 'entrega').length;
        const devolucionesV = registrosVigilante.filter(r => r.tipo === 'devolucion').length;
        
        return {
          nombre: v.nombre,
          entregas: entregasV,
          devoluciones: devolucionesV,
          total: entregasV + devolucionesV
        };
      });
      
      return {
        turno,
        entregas,
        devoluciones,
        vigilantes: estadisticasVigilantes.sort((a, b) => b.total - a.total)
      };
    });
  };

  const estadisticas = calcularEstadisticas();
  const totalEntregas = estadisticas.reduce((acc, e) => acc + e.entregas, 0);
  const totalDevoluciones = estadisticas.reduce((acc, e) => acc + e.devoluciones, 0);

  const ahora = new Date();
  const fecha = ahora.toLocaleDateString('es-UY', { 
    weekday: 'long', 
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  });

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="bg-card border-b py-4 px-6 shadow-sm">
        <div className="max-w-7xl mx-auto flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <div className="bg-primary p-3 rounded-xl">
              <BarChart3 className="w-8 h-8 text-primary-foreground" />
            </div>
            <div>
              <h1 className="text-2xl font-bold tracking-tight">Dashboard de Actividad</h1>
              <p className="text-muted-foreground text-sm">
                FCEA - Estadísticas del Sistema de Llaves
              </p>
            </div>
            <div className="flex gap-2">
              <Button 
                variant="outline" 
                size="sm" 
                className="gap-2"
                onClick={() => setExportModalOpen(true)}
              >
                <FileSpreadsheet className="w-4 h-4" />
                <span className="hidden md:inline">Exportar</span>
              </Button>
              <Button asChild variant="outline" size="sm" className="gap-2">
                <Link to="/monitor">
                  <ArrowLeft className="w-4 h-4" />
                  Volver al Monitor
                </Link>
              </Button>
            </div>
          </div>

          <div className="flex items-center gap-6">
            {/* Totales del día */}
            <div className="flex items-center gap-4">
              <div className="text-center px-4 py-2 bg-success/10 rounded-lg">
                <p className="text-2xl font-bold text-success">{totalEntregas}</p>
                <p className="text-xs text-muted-foreground flex items-center gap-1">
                  <ArrowUpRight className="w-3 h-3" />
                  Entregas
                </p>
              </div>
              <div className="text-center px-4 py-2 bg-info/10 rounded-lg">
                <p className="text-2xl font-bold text-info">{totalDevoluciones}</p>
                <p className="text-xs text-muted-foreground flex items-center gap-1">
                  <ArrowDownLeft className="w-3 h-3" />
                  Devoluciones
                </p>
              </div>
            </div>

            <div className="text-right">
              <p className="text-sm text-muted-foreground capitalize">{fecha}</p>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto py-6 px-4 space-y-6">
        {/* Tarjetas por turno */}
        <div className="grid gap-6 md:grid-cols-3">
          {estadisticas.map((stat) => {
            const config = turnosConfig[stat.turno];
            const Icon = config.icon;
            const maxTotal = Math.max(...stat.vigilantes.map(v => v.total), 1);
            
            return (
              <Card key={stat.turno} className="overflow-hidden">
                <CardHeader className={`${config.color} text-white pb-3`}>
                  <CardTitle className="flex items-center justify-between">
                    <span className="flex items-center gap-2">
                      <Icon className="w-5 h-5" />
                      {config.label}
                    </span>
                    <span className="text-sm font-normal opacity-90">{config.horario}</span>
                  </CardTitle>
                </CardHeader>
                <CardContent className="pt-4">
                  {/* Resumen del turno */}
                  <div className="flex justify-around mb-4 pb-4 border-b">
                    <div className="text-center">
                      <p className="text-2xl font-bold text-success">{stat.entregas}</p>
                      <p className="text-xs text-muted-foreground">Entregas</p>
                    </div>
                    <div className="text-center">
                      <p className="text-2xl font-bold text-info">{stat.devoluciones}</p>
                      <p className="text-xs text-muted-foreground">Devoluciones</p>
                    </div>
                  </div>

                  {/* Desglose por vigilante */}
                  <div className="space-y-3">
                    <h4 className="text-sm font-medium text-muted-foreground flex items-center gap-2">
                      <Users className="w-4 h-4" />
                      Actividad por Vigilante
                    </h4>
                    
                    {stat.vigilantes.length === 0 ? (
                      <p className="text-sm text-muted-foreground text-center py-2">
                        Sin vigilantes asignados
                      </p>
                    ) : (
                      <div className="space-y-2">
                        {stat.vigilantes.map((v) => (
                          <div key={v.nombre} className="space-y-1">
                            <div className="flex justify-between text-sm">
                              <span className="font-medium">{v.nombre}</span>
                              <span className="text-muted-foreground">
                                <span className="text-success">{v.entregas}</span>
                                {' / '}
                                <span className="text-info">{v.devoluciones}</span>
                              </span>
                            </div>
                            <Progress 
                              value={(v.total / maxTotal) * 100} 
                              className="h-2"
                            />
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>

        {/* Historial de actividad reciente */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Clock className="w-5 h-5" />
              Actividad Reciente
            </CardTitle>
          </CardHeader>
          <CardContent>
            {registrosActividad.length === 0 ? (
              <div className="text-center py-8">
                <Key className="w-12 h-12 mx-auto text-muted-foreground/30 mb-3" />
                <p className="text-muted-foreground">
                  No hay actividad registrada aún. Entrega o recibe llaves desde el Monitor para ver las estadísticas.
                </p>
              </div>
            ) : (
              <div className="space-y-2 max-h-96 overflow-y-auto">
                {[...registrosActividad]
                  .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
                  .slice(0, 20)
                  .map((registro) => (
                    <div 
                      key={registro.id}
                      className="flex items-center justify-between p-3 rounded-lg bg-muted/50"
                    >
                      <div className="flex items-center gap-3">
                        {registro.tipo === 'entrega' ? (
                          <div className="p-2 rounded-full bg-success/20">
                            <ArrowUpRight className="w-4 h-4 text-success" />
                          </div>
                        ) : (
                          <div className="p-2 rounded-full bg-info/20">
                            <ArrowDownLeft className="w-4 h-4 text-info" />
                          </div>
                        )}
                        <div>
                          <p className="font-medium text-sm">{registro.lugarNombre}</p>
                          <p className="text-xs text-muted-foreground">
                            {registro.tipo === 'entrega' ? 'Entregada a' : 'Devuelta por'} {registro.usuarioNombre}
                          </p>
                        </div>
                      </div>
                      <div className="text-right">
                        <Badge variant="outline" className="mb-1">
                          {registro.vigilante}
                        </Badge>
                        <p className="text-xs text-muted-foreground">
                          {new Date(registro.timestamp).toLocaleTimeString('es-UY', {
                            hour: '2-digit',
                            minute: '2-digit'
                          })}
                        </p>
                      </div>
                    </div>
                  ))}
              </div>
            )}
          </CardContent>
        </Card>
      </main>

      <ExportReportModal 
        open={exportModalOpen} 
        onOpenChange={setExportModalOpen} 
      />

      <footer className="py-4 text-center text-sm text-muted-foreground border-t mt-8">
        <p>Dashboard de Actividad • FCEA UdelaR • Sistema de Gestión de Llaves v3.6</p>
      </footer>
    </div>
  );
}
