import { useState, useEffect } from 'react';
import { Download, FileSpreadsheet, Calendar, CalendarRange, UsbIcon, ShieldAlert, Info } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Card } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Calendar as CalendarComponent } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';
import { useObjetosOlvidados } from '@/hooks/useObjetosOlvidados';
import { useVigilantes } from '@/hooks/useVigilantes';
import { 
  generarReporteMensual, 
  generarReportePersonalizado, 
  exportarCSV, 
  exportarCSVPersonalizado, 
  descargarCSV,
  ReporteMensual,
  ReportePersonalizado,
  hayUSBConectado,
  obtenerUSBsConectados
} from '@/utils/exportUtils';
import { Turno } from '@/data/fceaData';
import { format, isValid, startOfMonth, endOfMonth, subDays } from 'date-fns';
import { es } from 'date-fns/locale';
import { useToast } from '@/hooks/use-toast';
import { RegistroActividad } from '@/types/estadisticas';
import { useAdminAuth } from '@/hooks/useAdminAuth';
import { AdminLogin } from '@/components/admin/AdminLogin';

interface ExportReportModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

const meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
];

export function ExportReportModal({ open, onOpenChange }: ExportReportModalProps) {
  const { toast } = useToast();
  const { solicitudes } = useSolicitudesContext();
  const { vigilantes } = useVigilantes();
  const { isCustodian, login } = useAdminAuth();
  const [showLogin, setShowLogin] = useState(false);
  
  // Estado para verificar USB
  const [usbConectado, setUsbConectado] = useState(false);
  const [usbInfo, setUsbInfo] = useState<Array<{mountPoint: string, label: string}>>([]);
  
  // Verificar USB cada segundo cuando el modal está abierto
  useEffect(() => {
    if (!open) return;
    
    const checkUsb = () => {
      setUsbConectado(hayUSBConectado());
      setUsbInfo(obtenerUSBsConectados());
    };
    
    // Verificar inmediatamente
    checkUsb();
    
    // Configurar intervalo
    const interval = setInterval(checkUsb, 1000);
    
    // Limpiar intervalo al cerrar
    return () => clearInterval(interval);
  }, [open]);
  
  const { objetos } = useObjetosOlvidados();

  // Función para calcular turno desde timestamp
  const calcularTurno = (fecha: Date | string): Turno => {
    const d = typeof fecha === 'string' ? new Date(fecha) : fecha;
    const hora = d.getHours();
    if (hora >= 6 && hora < 14) return 'Matutino';
    if (hora >= 14 && hora < 22) return 'Vespertino';
    return 'Nocturno';
  };

  // Crear registros de actividad a partir de las solicitudes
  const registrosSolicitudes: RegistroActividad[] = solicitudes
    .filter(s => s.estado === 'entregada' || s.estado === 'devuelta')
    .flatMap(s => {
      const registros: RegistroActividad[] = [];
      if (s.horaEntrega && s.entregadoPor) {
        registros.push({
          id: `entrega-${s.id}`,
          solicitudId: s.id,
          tipo: 'entrega',
          lugarNombre: s.lugar?.nombre ?? '',
          usuarioNombre: s.usuario?.nombre ?? '',
          vigilante: s.entregadoPor,
          timestamp: s.horaEntrega,
          turno: calcularTurno(s.horaEntrega),
        });
      }
      if (s.horaDevolucion && s.recibidoPor) {
        registros.push({
          id: `devolucion-${s.id}`,
          solicitudId: s.id,
          tipo: 'devolucion',
          lugarNombre: s.lugar?.nombre ?? '',
          usuarioNombre: s.usuario?.nombre ?? '',
          vigilante: s.recibidoPor,
          timestamp: s.horaDevolucion,
          turno: calcularTurno(s.horaDevolucion),
        });
      }
      return registros;
    });

  // Crear registros de actividad de objetos olvidados
  const registrosObjetos: RegistroActividad[] = objetos.flatMap(o => {
    const registros: RegistroActividad[] = [];
    if (o.fechaRegistro && o.registradoPor) {
      registros.push({
        id: `obj-reg-${o.id}`,
        tipo: 'objeto_registro',
        lugarNombre: o.lugarEncontrado || 'Sin lugar',
        usuarioNombre: o.descripcion,
        vigilante: o.registradoPor,
        timestamp: o.fechaRegistro,
        turno: calcularTurno(o.fechaRegistro),
      });
    }
    if (o.devolucion) {
      registros.push({
        id: `obj-dev-${o.id}`,
        tipo: 'objeto_devolucion',
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
  const registrosActividad: RegistroActividad[] = [...registrosSolicitudes, ...registrosObjetos];
  
  const ahora = new Date();
  const [tipoReporte, setTipoReporte] = useState<'semanal' | 'mensual' | 'anual' | 'personalizado'>('mensual');
  
  // Estado para reporte mensual
  const [mesSeleccionado, setMesSeleccionado] = useState(ahora.getMonth().toString());
  const [anioSeleccionado, setAnioSeleccionado] = useState(ahora.getFullYear().toString());
  
  // Estado para reporte personalizado
  const [fechaInicio, setFechaInicio] = useState<Date | undefined>(subDays(ahora, 30));
  const [fechaFin, setFechaFin] = useState<Date | undefined>(ahora);
  
  // Estado para reporte personalizado con inputs de fecha
  const [fechaInicioStr, setFechaInicioStr] = useState(() => {
    const d = subDays(ahora, 30);
    return format(d, 'yyyy-MM-dd');
  });
  const [fechaFinStr, setFechaFinStr] = useState(() => format(ahora, 'yyyy-MM-dd'));
  
  
  // Reiniciar estado al cerrar el modal
  useEffect(() => {
    if (!open) {
      setShowLogin(false);
    }
  }, [open]);

  // Obtener años disponibles basado en los registros
  const aniosDisponibles = Array.from(new Set(
    registrosActividad.map(r => new Date(r.timestamp).getFullYear())
  )).sort((a, b) => b - a);
  
  // Si no hay registros, usar el año actual
  if (aniosDisponibles.length === 0) {
    aniosDisponibles.push(ahora.getFullYear());
  }

  // Agrupar vigilantes por turno
  const vigilantesPorTurno: Record<Turno, string[]> = {
    'Matutino': vigilantes.filter(v => v.turno === 'Matutino').map(v => v.nombre),
    'Vespertino': vigilantes.filter(v => v.turno === 'Vespertino').map(v => v.nombre),
    'Nocturno': vigilantes.filter(v => v.turno === 'Nocturno').map(v => v.nombre),
  };

  // Generar reportes
  const reporteMensual = generarReporteMensual(
    registrosActividad, 
    parseInt(mesSeleccionado), 
    parseInt(anioSeleccionado),
    vigilantesPorTurno
  );
  
  // Reporte semanal (últimos 7 días)
  const reporteSemanal = generarReportePersonalizado(
    registrosActividad, subDays(ahora, 7), ahora, vigilantesPorTurno
  );

  // Reporte anual
  const inicioAnio = new Date(parseInt(anioSeleccionado), 0, 1);
  const finAnio = new Date(parseInt(anioSeleccionado), 11, 31, 23, 59, 59);
  const reporteAnual = generarReportePersonalizado(
    registrosActividad, inicioAnio, finAnio, vigilantesPorTurno
  );

  // Reporte personalizado con fechas de inputs
  const fechaInicioCustom = fechaInicioStr ? new Date(fechaInicioStr + 'T00:00:00') : undefined;
  const fechaFinCustom = fechaFinStr ? new Date(fechaFinStr + 'T23:59:59') : undefined;
  const reportePersonalizado = fechaInicioCustom && fechaFinCustom && isValid(fechaInicioCustom) && isValid(fechaFinCustom)
    ? generarReportePersonalizado(registrosActividad, fechaInicioCustom, fechaFinCustom, vigilantesPorTurno)
    : null;
  
  // Reporte activo según el tipo seleccionado
  const reporteActivo = tipoReporte === 'semanal' ? reporteSemanal
    : tipoReporte === 'mensual' ? reporteMensual
    : tipoReporte === 'anual' ? reporteAnual
    : reportePersonalizado;
  
  const handleExportCSV = async () => {
    if (!reporteActivo) {
      toast({
        title: "Error",
        description: "No se pudo generar el reporte",
        variant: "destructive"
      });
      return;
    }
    
    if (reporteActivo.registros.length === 0) {
      toast({
        title: "Sin datos",
        description: `No hay registros para el período seleccionado`,
        variant: "destructive"
      });
      return;
    }
    
    // Verificar si hay USB conectado
    if (!usbConectado) {
      toast({
        title: "USB no detectado",
        description: "Conecte un dispositivo USB para exportar el reporte",
        variant: "destructive"
      });
      return;
    }
    
    // Verificar autenticación
    if (!isCustodian) {
      setShowLogin(true);
      return;
    }
    
    try {
      // Mostrar modal de copiando
      const copiandoModal = toast({
        title: "Exportando a USB...",
        description: `Guardando reporte en ${usbInfo[0]?.label || 'dispositivo USB'}`,
        duration: Infinity
      });
      
      let csv: string;
      let nombreArchivo: string;
      
      if (tipoReporte === 'mensual') {
        const reporte = reporteActivo as ReporteMensual;
        csv = exportarCSV(reporte);
        nombreArchivo = `reporte-llaves-${reporte.mes.toLowerCase()}-${reporte.anio}.csv`;
      } else {
        const reporte = reporteActivo as ReportePersonalizado;
        csv = exportarCSVPersonalizado(reporte);
        nombreArchivo = `reporte-llaves-personalizado-${format(reporte.fechaInicio, 'yyyyMMdd')}-${format(reporte.fechaFin, 'yyyyMMdd')}.csv`;
      }
      
      const exito = await descargarCSV(csv, nombreArchivo);
      
      // Cerrar modal de copiando
      copiandoModal.dismiss();
      
      if (exito) {
        toast({
          title: "Éxito",
          description: `Reporte guardado en dispositivo USB (${usbInfo[0]?.label || 'Unidad USB'})`,
        });
        onOpenChange(false);
      } else {
        toast({
          title: "Error",
          description: "No se pudo guardar el reporte en el dispositivo USB",
          variant: "destructive"
        });
      }
    } catch (error) {
      console.error('Error durante exportación:', error);
      toast({
        title: "Error",
        description: "Ocurrió un error al exportar el reporte",
        variant: "destructive"
      });
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <FileSpreadsheet className="w-5 h-5" />
            Exportar Reporte a USB
          </DialogTitle>
          <DialogDescription>
            Genera un reporte CSV cifrado y guárdalo en un dispositivo USB
          </DialogDescription>
        </DialogHeader>

        {/* Estado de conexión USB */}
        <div className={`p-3 rounded-lg flex items-center gap-3 ${usbConectado ? 'bg-green-50 border border-green-200' : 'bg-amber-50 border border-amber-200'}`}>
          <div className={`p-2 rounded-full ${usbConectado ? 'bg-green-100' : 'bg-amber-100'}`}>
            <UsbIcon className={`w-5 h-5 ${usbConectado ? 'text-green-600' : 'text-amber-600'}`} />
          </div>
          <div>
            {usbConectado ? (
              <>
                <p className="font-medium text-green-700">USB detectado</p>
                <p className="text-sm text-green-600">
                  {usbInfo[0]?.label || 'Dispositivo USB'} conectado y listo para usar
                </p>
              </>
            ) : (
              <>
                <p className="font-medium text-amber-700">USB no detectado</p>
                <p className="text-sm text-amber-600">
                  Conecte un dispositivo USB para exportar el reporte
                </p>
              </>
            )}
          </div>
        </div>

        {/* Información de seguridad */}
        <div className="p-3 rounded-lg bg-blue-50 border border-blue-200 flex items-start gap-3">
          <Info className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" />
          <div className="text-sm text-blue-700">
            <p className="font-medium mb-1">Información importante</p>
            <p>Los reportes se guardan cifrados en el dispositivo USB y solo pueden ser abiertos por personal autorizado con el software correspondiente.</p>
          </div>
        </div>

        {showLogin ? (
          <AdminLogin 
            onLogin={(password) => login(password, true)} 
            isChangingPassword={false} 
            onToggleChangePassword={() => {}} 
            onCancel={() => setShowLogin(false)}
          />
        ) : (
          <div className="space-y-6">
          {/* Tabs para tipo de reporte */}
          <Tabs defaultValue="mensual" value={tipoReporte} onValueChange={(v) => setTipoReporte(v as 'semanal' | 'mensual' | 'anual' | 'personalizado')}>
            <TabsList className="grid grid-cols-4">
              <TabsTrigger value="semanal" className="text-xs">
                Semanal
              </TabsTrigger>
              <TabsTrigger value="mensual" className="text-xs">
                Mensual
              </TabsTrigger>
              <TabsTrigger value="anual" className="text-xs">
                Anual
              </TabsTrigger>
              <TabsTrigger value="personalizado" className="text-xs">
                Rango
              </TabsTrigger>
            </TabsList>

            <TabsContent value="semanal" className="space-y-4 pt-4">
              <Card className="p-4 bg-muted/50">
                <h4 className="font-medium mb-3 flex items-center gap-2">
                  <Calendar className="w-4 h-4" />
                  Últimos 7 días
                </h4>
                <p className="text-sm text-muted-foreground mb-3">
                  {format(subDays(ahora, 7), 'dd/MM/yyyy')} — {format(ahora, 'dd/MM/yyyy')}
                </p>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <p className="text-muted-foreground">Total entregas</p>
                    <p className="text-xl font-bold text-success">{reporteSemanal?.totalEntregas ?? 0}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Total devoluciones</p>
                    <p className="text-xl font-bold text-info">{reporteSemanal?.totalDevoluciones ?? 0}</p>
                  </div>
                </div>
                {reporteSemanal && reporteSemanal.registros.length === 0 && (
                  <p className="text-sm text-muted-foreground mt-3 text-center">No hay registros para este período</p>
                )}
              </Card>
            </TabsContent>
            
            <TabsContent value="mensual" className="space-y-4 pt-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Mes</Label>
                  <Select value={mesSeleccionado} onValueChange={setMesSeleccionado}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {meses.map((mes, index) => (
                        <SelectItem key={index} value={index.toString()}>
                          {mes}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                
                <div className="space-y-2">
                  <Label>Año</Label>
                  <Select value={anioSeleccionado} onValueChange={setAnioSeleccionado}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {aniosDisponibles.map(anio => (
                        <SelectItem key={anio} value={anio.toString()}>
                          {anio}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              
              {/* Vista previa mensual */}
              <Card className="p-4 bg-muted/50">
                <h4 className="font-medium mb-3 flex items-center gap-2">
                  <Calendar className="w-4 h-4" />
                  Vista previa: {reporteMensual.mes} {reporteMensual.anio}
                </h4>
                
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <p className="text-muted-foreground">Total entregas</p>
                    <p className="text-xl font-bold text-success">{reporteMensual.totalEntregas}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Total devoluciones</p>
                    <p className="text-xl font-bold text-info">{reporteMensual.totalDevoluciones}</p>
                  </div>
                </div>

                {reporteMensual.registros.length === 0 && (
                  <p className="text-sm text-muted-foreground mt-3 text-center">
                    No hay registros para este período
                  </p>
                )}
              </Card>
            </TabsContent>
            
            <TabsContent value="anual" className="space-y-4 pt-4">
              <div className="space-y-2">
                <Label>Año</Label>
                <Select value={anioSeleccionado} onValueChange={setAnioSeleccionado}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {aniosDisponibles.map(anio => (
                      <SelectItem key={anio} value={anio.toString()}>
                        {anio}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <Card className="p-4 bg-muted/50">
                <h4 className="font-medium mb-3 flex items-center gap-2">
                  <Calendar className="w-4 h-4" />
                  Año {anioSeleccionado}
                </h4>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <p className="text-muted-foreground">Total entregas</p>
                    <p className="text-xl font-bold text-success">{reporteAnual?.totalEntregas ?? 0}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground">Total devoluciones</p>
                    <p className="text-xl font-bold text-info">{reporteAnual?.totalDevoluciones ?? 0}</p>
                  </div>
                </div>
                {reporteAnual && reporteAnual.registros.length === 0 && (
                  <p className="text-sm text-muted-foreground mt-3 text-center">No hay registros para este año</p>
                )}
              </Card>
            </TabsContent>

            <TabsContent value="personalizado" className="space-y-4 pt-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Fecha inicio</Label>
                  <input
                    type="date"
                    value={fechaInicioStr}
                    onChange={(e) => setFechaInicioStr(e.target.value)}
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Fecha fin</Label>
                  <input
                    type="date"
                    value={fechaFinStr}
                    onChange={(e) => setFechaFinStr(e.target.value)}
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
                  />
                </div>
              </div>
              
              <Card className="p-4 bg-muted/50">
                <h4 className="font-medium mb-3 flex items-center gap-2">
                  <CalendarRange className="w-4 h-4" />
                  {reportePersonalizado ? reportePersonalizado.titulo : 'Seleccione fechas'}
                </h4>
                
                {reportePersonalizado ? (
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <p className="text-muted-foreground">Total entregas</p>
                      <p className="text-xl font-bold text-success">{reportePersonalizado.totalEntregas}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Total devoluciones</p>
                      <p className="text-xl font-bold text-info">{reportePersonalizado.totalDevoluciones}</p>
                    </div>
                  </div>
                ) : (
                  <p className="text-sm text-muted-foreground text-center">
                    Seleccione un rango de fechas válido
                  </p>
                )}

                {reportePersonalizado && reportePersonalizado.registros.length === 0 && (
                  <p className="text-sm text-muted-foreground mt-3 text-center">
                    No hay registros para este período
                  </p>
                )}
              </Card>
            </TabsContent>
          </Tabs>

            {/* Acciones */}
            <div className="flex justify-end gap-3">
              <Button variant="outline" onClick={() => onOpenChange(false)}>
                Cancelar
              </Button>
              <Button 
                onClick={handleExportCSV}
                disabled={!reporteActivo || reporteActivo.registros.length === 0 || !usbConectado}
                className="gap-2"
              >
                <Download className="w-4 h-4" />
                Exportar a USB
              </Button>
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
