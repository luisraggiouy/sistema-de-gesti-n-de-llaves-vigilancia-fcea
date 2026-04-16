import { useState, useEffect, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { BarChart3, ArrowLeft, Clock, Users, Key, ArrowUpRight, ArrowDownLeft, Sun, Sunset, Moon, FileSpreadsheet, Palmtree, Stethoscope, Package, LogOut, Settings, Usb, DatabaseBackup, PieChart, CalendarDays, CalendarRange } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';
import { Turno } from '@/data/fceaData';
import { useVigilantes } from '@/hooks/useVigilantes';
import { EstadisticasTurno, EstadisticasVigilante } from '@/types/estadisticas';
import { ExportReportModal } from '@/components/dashboard/ExportReportModal';
import { AdminLogin } from '@/components/admin/AdminLogin';
import { AdvancedExportModal } from '@/components/admin/AdvancedExportModal';
import { useObjetosOlvidados } from '@/hooks/useObjetosOlvidados';
import { useAdminAuth } from '@/hooks/useAdminAuth';
import { useToast } from '@/hooks/use-toast';
import { hayUSBConectado, obtenerUSBsConectados } from '@/utils/exportUtils';
import AdvancedChartVisualizations from '@/components/dashboard/AdvancedChartVisualizations';

const turnosConfig: Record<Turno, { label: string; horario: string; color: string; icon: typeof Sun }> = {
  'Matutino': { label: 'Turno Matutino', horario: '06:00 - 14:00', color: 'bg-amber-500', icon: Sun },
  'Vespertino': { label: 'Turno Vespertino', horario: '14:00 - 22:00', color: 'bg-blue-500', icon: Sunset },
  'Nocturno': { label: 'Turno Nocturno', horario: '22:00 - 06:00', color: 'bg-indigo-900', icon: Moon },
};

export default function Dashboard() {
  const { solicitudes } = useSolicitudesContext();
  const { vigilantes } = useVigilantes();
  const { objetos, objetosEnCustodia, objetosDevueltos } = useObjetosOlvidados();
  const { isAuthenticated, isLoading, isCustodian, login, logout, changePassword } = useAdminAuth();
  const { toast } = useToast();
  const [, setTick] = useState(0);
  const [exportModalOpen, setExportModalOpen] = useState(false);
  const [advancedExportOpen, setAdvancedExportOpen] = useState(false);
  const [isChangingPassword, setIsChangingPassword] = useState(false);
  const [usbDetected, setUsbDetected] = useState(false);

  // Verificar periódicamente si hay un USB conectado (para el custodio)
  useEffect(() => {
    if (isCustodian) {
      const checkUsb = () => {
        const hasUsb = hayUSBConectado();
        setUsbDetected(hasUsb);
        if (hasUsb && !usbDetected) {
          toast({
            title: "USB Detectado",
            description: "Se ha detectado un dispositivo USB. Puede exportar reportes directamente.",
          });
        }
      };
      
      checkUsb(); // Verificar inmediatamente
      const interval = setInterval(checkUsb, 5000); // Verificar cada 5 segundos
      return () => clearInterval(interval);
    }
  }, [isCustodian, usbDetected, toast]);
  
  // Función para calcular turno a partir de una hora
  const calcularTurno = (fecha: Date | string): Turno => {
    const d = typeof fecha === 'string' ? new Date(fecha) : fecha;
    const hora = d.getHours();
    if (hora >= 6 && hora < 14) return 'Matutino';
    if (hora >= 14 && hora < 22) return 'Vespertino';
    return 'Nocturno';
  };

  // Crear registros de actividad a partir de las solicitudes
  const registrosActividad = solicitudes
    .filter(s => s.estado === 'entregada' || s.estado === 'devuelta')
    .flatMap(s => {
      const registros = [];
      if (s.horaEntrega && s.entregadoPor) {
        registros.push({
          id: `entrega-${s.id}`,
          tipo: 'entrega' as const,
          lugarNombre: s.lugar.nombre,
          usuarioNombre: s.usuario.nombre,
          vigilante: s.entregadoPor,
          timestamp: s.horaEntrega,
          turno: calcularTurno(s.horaEntrega),
        });
      }
      if (s.horaDevolucion && s.recibidoPor) {
        registros.push({
          id: `devolucion-${s.id}`,
          tipo: 'devolucion' as const,
          lugarNombre: s.lugar.nombre,
          usuarioNombre: s.usuario.nombre,
          vigilante: s.recibidoPor,
          timestamp: s.horaDevolucion,
          turno: calcularTurno(s.horaDevolucion),
        });
      }
      return registros;
    });

  // Crear registros de actividad de objetos olvidados
  const registrosObjetos = objetos.flatMap(o => {
    const registros = [];
    if (o.fechaRegistro && o.registradoPor) {
      registros.push({
        id: `obj-registro-${o.id}`,
        tipo: 'objeto_registro' as const,
        lugarNombre: o.lugarEncontrado || 'Sin lugar',
        usuarioNombre: o.descripcion,
        vigilante: o.registradoPor,
        timestamp: o.fechaRegistro,
        turno: calcularTurno(o.fechaRegistro),
      });
    }
    if (o.devolucion) {
      registros.push({
        id: `obj-devolucion-${o.id}`,
        tipo: 'objeto_devolucion' as const,
        lugarNombre: o.lugarEncontrado || 'Sin lugar',
        usuarioNombre: `${o.descripcion} → ${o.devolucion.nombreReceptor}`,
        vigilante: o.devolucion.vigilanteEntrega,
        timestamp: o.devolucion.fecha,
        turno: calcularTurno(o.devolucion.fecha),
      });
    }
    return registros;
  });

  // Combinar todos los registros
  const todosLosRegistros = [...registrosActividad, ...registrosObjetos];

  // Auto-refresh cada minuto
  useEffect(() => {
    const interval = setInterval(() => setTick(t => t + 1), 60000);
    return () => clearInterval(interval);
  }, []);

  // Estado para el período de las tarjetas por turno
  const [periodoTarjetas, setPeriodoTarjetas] = useState<'hoy' | 'mensual' | 'semestral'>('hoy');

  // Filtrar registros según el período seleccionado
  const registrosFiltrados = useMemo(() => {
    const ahora = new Date();
    const hoyInicio = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate(), 0, 0, 0);
    const mesInicio = new Date(ahora.getFullYear(), ahora.getMonth(), 1);
    const semestreInicio = new Date(ahora.getFullYear(), ahora.getMonth() - 5, 1);

    return todosLosRegistros.filter(r => {
      const fecha = new Date(r.timestamp);
      if (periodoTarjetas === 'hoy') return fecha >= hoyInicio;
      if (periodoTarjetas === 'mensual') return fecha >= mesInicio;
      return fecha >= semestreInicio; // semestral
    });
  }, [todosLosRegistros, periodoTarjetas]);

  // Calcular estadísticas por turno (usando registros filtrados)
  const calcularEstadisticas = (registros: typeof todosLosRegistros): (EstadisticasTurno & { objRegistros: number; objDevoluciones: number })[] => {
    const turnos: Turno[] = ['Matutino', 'Vespertino', 'Nocturno'];
    
    return turnos.map(turno => {
      const registrosTurno = registros.filter(r => r.turno === turno);
      const vigilantesTurno = vigilantes.filter(v => v.turno === turno);
      
      const entregas = registrosTurno.filter(r => r.tipo === 'entrega').length;
      const devoluciones = registrosTurno.filter(r => r.tipo === 'devolucion').length;
      const objRegistros = registrosTurno.filter(r => r.tipo === 'objeto_registro').length;
      const objDevoluciones = registrosTurno.filter(r => r.tipo === 'objeto_devolucion').length;
      
      const estadisticasVigilantes: EstadisticasVigilante[] = vigilantesTurno.map(v => {
        const registrosVigilante = registrosTurno.filter(r => r.vigilante === v.nombre);
        const entregasV = registrosVigilante.filter(r => r.tipo === 'entrega').length;
        const devolucionesV = registrosVigilante.filter(r => r.tipo === 'devolucion').length;
        const objRegV = registrosVigilante.filter(r => r.tipo === 'objeto_registro').length;
        const objDevV = registrosVigilante.filter(r => r.tipo === 'objeto_devolucion').length;
        
        return {
          nombre: v.nombre,
          entregas: entregasV,
          devoluciones: devolucionesV,
          total: entregasV + devolucionesV + objRegV + objDevV
        };
      });
      
      return {
        turno,
        entregas,
        devoluciones,
        objRegistros,
        objDevoluciones,
        vigilantes: estadisticasVigilantes.sort((a, b) => b.total - a.total)
      };
    });
  };

  const handleCustodianExport = () => {
    if (!usbDetected) {
      toast({
        title: "No se detecta USB",
        description: "Para exportar datos, conecte un pendrive al equipo primero.",
        variant: "destructive"
      });
      return;
    }
    setAdvancedExportOpen(true);
  };

  const handleLogin = (password: string, loginAsCustodian: boolean = false) => {
    login(password, loginAsCustodian);
  };

  const handleChangePassword = (oldPassword: string, newPassword: string, type: 'admin' | 'custodian' = 'admin') => {
    changePassword(oldPassword, newPassword, type);
  };

  const estadisticas = calcularEstadisticas(registrosFiltrados);
  const totalEntregas = estadisticas.reduce((acc, e) => acc + e.entregas, 0);
  const totalDevoluciones = estadisticas.reduce((acc, e) => acc + e.devoluciones, 0);

  const ahora = new Date();
  const fecha = ahora.toLocaleDateString('es-UY', { 
    weekday: 'long', 
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  });

  // Si no está autenticado, mostrar el login
  // if (!isAuthenticated && !isLoading) {
  //   return <AdminLogin onLogin={handleLogin} onChangePassword={handleChangePassword} isChangingPassword={false} onToggleChangePassword={() => {}} />;
  // }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className={`${isCustodian ? 'bg-amber-50 border-amber-200' : 'bg-card'} border-b py-4 px-6 shadow-sm`}>
        <div className="max-w-7xl mx-auto flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <div className={`${isCustodian ? 'bg-amber-500' : 'bg-primary'} p-3 rounded-xl`}>
              {isCustodian ? (
                <Key className="w-8 h-8 text-primary-foreground" />
              ) : (
                <BarChart3 className="w-8 h-8 text-primary-foreground" />
              )}
            </div>
            <div>
              <h1 className="text-2xl font-bold tracking-tight">
                {isCustodian ? 'Dashboard de Custodio' : 'Dashboard de Actividad'}
              </h1>
              <p className="text-muted-foreground text-sm">
                FCEA - {isCustodian ? 'Exportación Segura' : 'Estadísticas del Sistema de Llaves'}
              </p>
            </div>
            <div className="flex gap-2">
              {isCustodian ? (
                <Button 
                  variant="default"
                  size="sm" 
                  className="gap-2"
                  onClick={handleCustodianExport}
                >
                  <Usb className="w-4 h-4" />
                  <span className="hidden md:inline">Exportar a Pendrive</span>
                </Button>
              ) : (
                <>
                  <Button 
                    variant="outline" 
                    size="sm" 
                    className="gap-2"
                    onClick={() => setAdvancedExportOpen(true)}
                  >
                    <FileSpreadsheet className="w-4 h-4" />
                    <span className="hidden md:inline">Exportar Avanzado</span>
                  </Button>
                  <Button 
                    variant="outline" 
                    size="sm" 
                    className="gap-2"
                    onClick={() => setExportModalOpen(true)}
                  >
                    <FileSpreadsheet className="w-4 h-4" />
                    <span className="hidden md:inline">Exportar Básico</span>
                  </Button>
                </>
              )}
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

            <div className="flex items-center gap-4">
              <div className="text-right">
                <p className="text-sm text-muted-foreground capitalize">{fecha}</p>
                {isCustodian && (
                  <p className="text-xs font-semibold text-amber-600 flex items-center gap-1 mt-1">
                    <Key className="w-3 h-3" />
                    Modo Custodio
                  </p>
                )}
              </div>
              
              <div className="flex gap-2">
                <Button 
                  variant="outline" 
                  size="sm" 
                  className="gap-2"
                  onClick={() => setIsChangingPassword(true)}
                >
                  <Settings className="w-4 h-4" />
                  <span className="hidden md:inline">Cambiar Contraseña</span>
                </Button>
                <Button 
                  variant="outline" 
                  size="sm" 
                  className="gap-2"
                  onClick={logout}
                >
                  <LogOut className="w-4 h-4" />
                  <span className="hidden md:inline">Cerrar Sesión</span>
                </Button>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Barra de notificación USB para custodios */}
      {isCustodian && (
        <div className={`py-2 px-6 ${usbDetected ? 'bg-green-100 text-green-800' : 'bg-amber-100 text-amber-800'} border-b border-t`}>
          <div className="max-w-7xl mx-auto flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Usb className="w-4 h-4" />
              {usbDetected ? (
                <span>Dispositivo USB conectado. Listo para exportar datos.</span>
              ) : (
                <span>Conecte un dispositivo USB para exportar datos del sistema.</span>
              )}
            </div>
            
            {usbDetected && (
              <Button 
                variant="default"
                size="sm" 
                className="gap-2 bg-green-700"
                onClick={handleCustodianExport}
              >
                <DatabaseBackup className="w-4 h-4" />
                Exportar Ahora
              </Button>
            )}
          </div>
        </div>
      )}

      <main className="max-w-7xl mx-auto py-6 px-4 space-y-6">
        {/* Gráficas de estadísticas avanzadas */}
        {!isCustodian && (
          <AdvancedChartVisualizations solicitudes={solicitudes} />
        )}

        {/* Selector de período + Tarjetas por turno */}
        <div className="flex items-center justify-between flex-wrap gap-4">
          <h2 className="text-lg font-semibold text-muted-foreground flex items-center gap-2">
            📊 Estadísticas por turno
            <span className="text-sm font-normal">
              ({periodoTarjetas === 'hoy' ? 'Hoy' : periodoTarjetas === 'mensual' ? 'Este mes' : 'Último semestre'})
            </span>
          </h2>
          <Tabs value={periodoTarjetas} onValueChange={(v) => setPeriodoTarjetas(v as 'hoy' | 'mensual' | 'semestral')}>
            <TabsList>
              <TabsTrigger value="hoy" className="gap-1">
                <Sun className="w-3 h-3" />
                Hoy
              </TabsTrigger>
              <TabsTrigger value="mensual" className="gap-1">
                <CalendarDays className="w-3 h-3" />
                Mensual
              </TabsTrigger>
              <TabsTrigger value="semestral" className="gap-1">
                <CalendarRange className="w-3 h-3" />
                Semestral
              </TabsTrigger>
            </TabsList>
          </Tabs>
        </div>
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
                  <div className="grid grid-cols-2 gap-2 mb-4 pb-4 border-b">
                    <div className="text-center">
                      <p className="text-2xl font-bold text-success">{stat.entregas}</p>
                      <p className="text-xs text-muted-foreground">Entregas llaves</p>
                    </div>
                    <div className="text-center">
                      <p className="text-2xl font-bold text-info">{stat.devoluciones}</p>
                      <p className="text-xs text-muted-foreground">Devoluciones llaves</p>
                    </div>
                    {((stat as any).objRegistros > 0 || (stat as any).objDevoluciones > 0) && (
                      <>
                        <div className="text-center">
                          <p className="text-lg font-bold text-amber-600">{(stat as any).objRegistros}</p>
                          <p className="text-xs text-muted-foreground">📦 Obj. registrados</p>
                        </div>
                        <div className="text-center">
                          <p className="text-lg font-bold text-emerald-600">{(stat as any).objDevoluciones}</p>
                          <p className="text-xs text-muted-foreground">📦 Obj. devueltos</p>
                        </div>
                      </>
                    )}
                  </div>

                  {/* Vigilantes en licencia */}
                  {(() => {
                    const vigilantesTurno = vigilantes.filter(v => v.turno === stat.turno);
                    const enLicencia = vigilantesTurno.filter(v => v.estadoLicencia && v.estadoLicencia !== 'activo');
                    if (enLicencia.length === 0) return null;
                    return (
                      <div className="mb-4 pb-4 border-b space-y-1">
                        <h4 className="text-xs font-medium text-muted-foreground">Ausencias</h4>
                        {enLicencia.map(v => (
                          <div key={v.id} className="flex items-center gap-2 text-sm">
                            {v.estadoLicencia === 'licencia' ? (
                              <Palmtree className="w-3.5 h-3.5 text-amber-600" />
                            ) : (
                              <Stethoscope className="w-3.5 h-3.5 text-red-600" />
                            )}
                            <span className="text-muted-foreground">{v.nombre}</span>
                            <Badge variant="outline" className="text-xs">
                              {v.estadoLicencia === 'licencia' ? 'Licencia' : 'Lic. Médica'}
                            </Badge>
                          </div>
                        ))}
                      </div>
                    );
                  })()}

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

        {/* Estadísticas de objetos olvidados */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Package className="w-5 h-5" />
              Objetos Olvidados
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="bg-amber-50 border border-amber-200 rounded-lg p-4">
                <h3 className="text-lg font-semibold text-amber-700 mb-2">Total Registrados</h3>
                <p className="text-3xl font-bold text-amber-600">{objetos.length}</p>
                <div className="mt-2 text-sm text-amber-600">
                  Objetos registrados en el sistema
                </div>
              </div>
              
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <h3 className="text-lg font-semibold text-blue-700 mb-2">En Custodia</h3>
                <p className="text-3xl font-bold text-blue-600">{objetosEnCustodia.length}</p>
                <div className="mt-2 text-sm text-blue-600">
                  Objetos actualmente en custodia
                </div>
              </div>
              
              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <h3 className="text-lg font-semibold text-green-700 mb-2">Devueltos</h3>
                <p className="text-3xl font-bold text-green-600">{objetosDevueltos.length}</p>
                <div className="mt-2 text-sm text-green-600">
                  Objetos devueltos a sus dueños
                </div>
              </div>
            </div>
            
            {/* Estadísticas por vigilante */}
            <div className="mt-6">
              <h3 className="text-sm font-medium text-muted-foreground mb-3">Actividad por Vigilante</h3>
              <div className="space-y-2">
                {vigilantes
                  .filter(v => 
                    objetos.some(o => o.registradoPor === v.nombre) ||
                    objetosDevueltos.some(o => o.devolucion?.vigilanteEntrega === v.nombre)
                  )
                  .map(v => {
                    const registrados = objetos.filter(o => o.registradoPor === v.nombre).length;
                    const devueltos = objetosDevueltos.filter(o => o.devolucion?.vigilanteEntrega === v.nombre).length;
                    return (
                      <div key={v.id} className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <Badge variant="outline" className={`${turnosConfig[v.turno].color} text-white`}>
                            {v.turno.charAt(0)}
                          </Badge>
                          <span className="font-medium">{v.nombre}</span>
                        </div>
                        <div className="text-sm text-muted-foreground">
                          <span className="text-amber-600 font-medium">{registrados}</span> registrados / 
                          <span className="text-green-600 font-medium ml-1">{devueltos}</span> devueltos
                        </div>
                      </div>
                    );
                  })}
                {/* Objetos sin vigilante asignado */}
                {objetos.some(o => !o.registradoPor) && (
                  <div className="flex items-center justify-between text-muted-foreground">
                    <div className="flex items-center gap-2">
                      <Badge variant="outline" className="bg-gray-400 text-white">?</Badge>
                      <span className="font-medium italic">Sin vigilante asignado</span>
                    </div>
                    <div className="text-sm">
                      <span className="text-amber-600 font-medium">{objetos.filter(o => !o.registradoPor).length}</span> registrados
                    </div>
                  </div>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
        
        {/* Historial de actividad reciente */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Clock className="w-5 h-5" />
              Actividad Reciente
            </CardTitle>
          </CardHeader>
          <CardContent>
            {todosLosRegistros.length === 0 ? (
              <div className="text-center py-8">
                <Key className="w-12 h-12 mx-auto text-muted-foreground/30 mb-3" />
                <p className="text-muted-foreground">
                  No hay actividad registrada aún. Entrega o recibe llaves desde el Monitor para ver las estadísticas.
                </p>
              </div>
            ) : (
              <div className="space-y-2 max-h-96 overflow-y-auto">
                {[...todosLosRegistros]
                  .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
                  .slice(0, 30)
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
                        ) : registro.tipo === 'devolucion' ? (
                          <div className="p-2 rounded-full bg-info/20">
                            <ArrowDownLeft className="w-4 h-4 text-info" />
                          </div>
                        ) : registro.tipo === 'objeto_registro' ? (
                          <div className="p-2 rounded-full bg-amber-500/20">
                            <Package className="w-4 h-4 text-amber-600" />
                          </div>
                        ) : (
                          <div className="p-2 rounded-full bg-emerald-500/20">
                            <Package className="w-4 h-4 text-emerald-600" />
                          </div>
                        )}
                        <div>
                          <p className="font-medium text-sm">{registro.lugarNombre}</p>
                          <p className="text-xs text-muted-foreground">
                            {registro.tipo === 'entrega' ? 'Entregada a' : 
                             registro.tipo === 'devolucion' ? 'Devuelta por' :
                             registro.tipo === 'objeto_registro' ? '📦 Objeto registrado:' :
                             '📦 Objeto devuelto:'} {registro.usuarioNombre}
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
                          {' '}
                          {new Date(registro.timestamp).toLocaleDateString('es-UY', {
                            day: '2-digit',
                            month: '2-digit'
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

      <AdvancedExportModal
        open={advancedExportOpen}
        onOpenChange={setAdvancedExportOpen}
      />

      {isChangingPassword && (
        <AdminLogin
          onLogin={() => {}}
          onChangePassword={(oldPass, newPass, type) => {
            const success = changePassword(oldPass, newPass, type);
            if (success) {
              setIsChangingPassword(false);
            }
          }}
          isChangingPassword={true}
          onToggleChangePassword={() => setIsChangingPassword(false)}
          isCustodian={isCustodian}
        />
      )}

      <footer className="py-4 text-center text-sm text-muted-foreground border-t mt-8">
        <p>Dashboard de Actividad • FCEA UdelaR • Sistema de Gestión de Llaves v4.3</p>
      </footer>
    </div>
  );
}