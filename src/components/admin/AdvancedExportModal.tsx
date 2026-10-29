import { useState, useEffect, useRef } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Download, Calendar, FileSpreadsheet, Usb, Info, Check, X, Eye, EyeOff } from 'lucide-react';
import { DateInput } from '@/components/ui/date-input';
import { useToast } from '@/hooks/use-toast';
import { exportToExcel, exportarVisorOffline, hayUSBConectado, obtenerUSBsConectados } from '@/utils/exportUtils';
import pb from '@/lib/pocketbase';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';
import { useAdminAuth } from '@/hooks/useAdminAuth';
import { useObjetosOlvidados } from '@/hooks/useObjetosOlvidados';
import { getAutorizaciones } from '@/data/fceaData';
import { useVigilantes } from '@/hooks/useVigilantes';

interface AdvancedExportModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

interface ExportOptions {
  includeRequests: boolean;
  includeDeliveries: boolean;
  includeReturns: boolean;
  includeStats: boolean;
  includeUsers: boolean;
  includeKeys: boolean;
  includeObjetos: boolean;
  includeAutorizaciones: boolean;
  includeHistorial: boolean;
}

// Tope temporal del Historial exportado: como la autoridad NO elige rango al
// grabar, se incluye SIEMPRE hasta 2 anios (24 meses) hacia atras desde hoy,
// para que el archivo no crezca sin control cuando el sistema tenga anios.
const HISTORIAL_MAX_ANIOS = 2;

export function AdvancedExportModal({ open, onOpenChange }: AdvancedExportModalProps) {
  const [startDate, setStartDate] = useState(() => {
    const date = new Date();
    date.setDate(date.getDate() - 30); // 30 días atrás por defecto
    return date.toISOString().split('T')[0];
  });
  
  const [endDate, setEndDate] = useState(() => {
    return new Date().toISOString().split('T')[0];
  });

  const [exportOptions, setExportOptions] = useState<ExportOptions>({
    includeRequests: true,
    includeDeliveries: true,
    includeReturns: true,
    includeStats: true,
    includeUsers: false,
    includeKeys: false,
    includeObjetos: true,
    includeAutorizaciones: true,
    includeHistorial: true
  });

  const [isExporting, setIsExporting] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  // USB siempre "conectado" — el diálogo del SO permite elegir el destino (pendrive, escritorio, etc.)
  const usbStatus = { connected: true, drives: [{ mountPoint: '', label: 'Seleccionar al guardar' }] };
  const { toast } = useToast();
  const { solicitudesPendientes, solicitudesEntregadas, solicitudesDevueltas } = useSolicitudesContext();
  const { isAuthenticated, login } = useAdminAuth();
  const { objetos } = useObjetosOlvidados();
  const { vigilantes } = useVigilantes();
  const [autenticado, setAutenticado] = useState(false);
  const [passwordInput, setPasswordInput] = useState('');
  const [passwordError, setPasswordError] = useState('');

  // Resetear autenticación al cerrar el modal
  useEffect(() => {
    if (!open) {
      setAutenticado(false);
      setPasswordInput('');
      setPasswordError('');
    }
  }, [open]);

  const handleLoginExport = async () => {
    if (!passwordInput.trim()) {
      setPasswordError('Debe ingresar la contraseña');
      return;
    }
    const ok = await login(passwordInput);
    if (ok) {
      setAutenticado(true);
      setPasswordError('');
    } else {
      setPasswordError('Contraseña incorrecta');
    }
  };

  const handleExport = async () => {
    if (!startDate || !endDate) {
      toast({
        title: "Error",
        description: "Debe seleccionar las fechas de inicio y fin",
        variant: "destructive"
      });
      return;
    }

    if (new Date(startDate) > new Date(endDate)) {
      toast({
        title: "Error",
        description: "La fecha de inicio no puede ser posterior a la fecha de fin",
        variant: "destructive"
      });
      return;
    }

    const hasSelectedOptions = Object.values(exportOptions).some(option => option);
    if (!hasSelectedOptions) {
      toast({
        title: "Error",
        description: "Debe seleccionar al menos una opción de exportación",
        variant: "destructive"
      });
      return;
    }

    setIsExporting(true);

    try {
      // Filtrar datos por rango de fechas
      const start = new Date(startDate);
      const end = new Date(endDate);
      end.setHours(23, 59, 59, 999); // Incluir todo el día final

      // Obtener autorizaciones
      const autorizaciones = getAutorizaciones();

      const filteredData = {
        solicitudesPendientes: exportOptions.includeRequests ? 
          solicitudesPendientes.filter(s => {
            const fecha = new Date(s.horaSolicitud);
            return fecha >= start && fecha <= end;
          }) : [],
        
        solicitudesEntregadas: exportOptions.includeDeliveries ? 
          solicitudesEntregadas.filter(s => {
            const fecha = new Date(s.horaSolicitud);
            return fecha >= start && fecha <= end;
          }) : [],
        
        solicitudesDevueltas: exportOptions.includeReturns ? 
          solicitudesDevueltas.filter(s => {
            const fecha = new Date(s.horaSolicitud);
            return fecha >= start && fecha <= end;
          }) : [],

        // Objetos olvidados filtrados por fecha de registro
        objetosOlvidados: exportOptions.includeObjetos ?
          objetos.filter(o => {
            const fecha = new Date(o.fechaRegistro);
            return fecha >= start && fecha <= end;
          }) : [],

        // Autorizaciones filtradas por fecha de autorización
        autorizaciones: exportOptions.includeAutorizaciones ?
          autorizaciones.filter(a => {
            const fecha = new Date(a.fechaAutorizacion);
            return fecha >= start && fecha <= end;
          }) : []
      };

      // ── Historial de Llaves (igual que el buscador del Monitor, con notas) ──
      // La autoridad NO elige rango: se incluye SIEMPRE hasta 2 anios hacia
      // atras desde hoy (tope duro) para que el archivo no sea pesado. Mismo
      // mapeo y orden que useBusquedaHistorial (mas reciente primero).
      let historial: any[] = [];
      if (exportOptions.includeHistorial) {
        const limiteHistorial = new Date();
        limiteHistorial.setFullYear(limiteHistorial.getFullYear() - HISTORIAL_MAX_ANIOS);
        historial = [...solicitudesEntregadas, ...solicitudesDevueltas]
          .filter(s => s.horaEntrega && new Date(s.horaEntrega) >= limiteHistorial)
          .map((s: any) => {
            let tiempoUso: string | undefined;
            if (s.horaEntrega && s.horaDevolucion) {
              const mins = Math.floor((new Date(s.horaDevolucion).getTime() - new Date(s.horaEntrega).getTime()) / 60000);
              const horas = Math.floor(mins / 60);
              const resto = mins % 60;
              tiempoUso = horas > 0 ? `${horas}h ${resto}m` : `${resto}m`;
            }
            return {
              lugarNombre: s.lugar?.nombre ?? '',
              usuarioNombre: s.usuario?.nombre ?? '',
              tipoUsuario: s.usuario?.tipo ?? '',
              departamento: s.usuario?.departamento,
              nombreEmpresa: s.usuario?.nombreEmpresa,
              vigilanteEntrega: s.entregadoPor ?? '',
              vigilanteDevolucion: s.recibidoPor,
              horaEntrega: s.horaEntrega,
              horaDevolucion: s.horaDevolucion,
              tiempoUso,
              turno: s.turno ?? '',
              notas: s.notas?.trim() ? s.notas.trim() : undefined,
            };
          })
          .sort((a, b) => new Date(b.horaEntrega).getTime() - new Date(a.horaEntrega).getTime());
      }
      (filteredData as any).historial = historial;

      // Preparar datos para exportación
      const exportData = {
        ...filteredData,
        // Incluir vigilantes con diasLaborales y estadoLicencia para el informe de personal
        vigilantes: vigilantes.map(v => ({
          nombre: v.nombre,
          turno: v.turno,
          esJefe: v.esJefe,
          estadoLicencia: v.estadoLicencia || 'activo',
          diasLaborales: v.diasLaborales,
        })),
        dateRange: {
          start: startDate,
          end: endDate
        },
        exportOptions,
        generatedAt: new Date().toISOString(),
        generatedBy: 'Autorizado FCEA'
      };

      // Generar nombre de archivo legible con fechas y hora
      const now = new Date();
      const meses = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
      const fmtFechaLegible = (iso: string) => {
        const [y, m, d] = iso.split('-');
        return `${parseInt(d)} de ${meses[parseInt(m) - 1]}`;
      };
      const diaGen = now.getDate();
      const mesGen = now.getMonth() + 1;
      const anioGen = String(now.getFullYear()).slice(2);
      const horaGen = String(now.getHours()).padStart(2, '0');
      const minGen = String(now.getMinutes()).padStart(2, '0');
      const fileName = `Datos Dashboard Vigilancia, desde ${fmtFechaLegible(startDate)} hasta ${fmtFechaLegible(endDate)}, generado ${diaGen}-${mesGen}-${anioGen} hora ${horaGen}.${minGen}`;

      // ── VISOR OFFLINE ──────────────────────────────────────────────────────
      // Se genera UN archivo .html autocontenido que, al abrirlo en la PC de la
      // autoridad (sin servidor), muestra el MISMO Dashboard + Buscador
      // Historico del Monitor con los datos CONGELADOS. La autoridad NO elige
      // rango al grabar; filtra despues en su PC. Leemos los registros CRUDOS de
      // PocketBase para que el visor los mapee con el mismo codigo que el Monitor.
      const [solRaw, vigRaw, objRaw] = await Promise.all([
        pb.collection('solicitudes').getFullList({ sort: '-created' }),
        pb.collection('vigilante').getFullList({ sort: 'nombre' }),
        pb.collection('objetos_olvidados').getFullList({ sort: '-created' }),
      ]);
      const snapshot = {
        generadoEn: new Date().toISOString(),
        solicitudes: solRaw,
        vigilantes: vigRaw,
        objetos: objRaw,
        autorizaciones: getAutorizaciones(),
      };
      await exportarVisorOffline(snapshot, fileName);

      // TODOS exportan a USB - Mensaje unificado
      toast({
        title: "Exportación exitosa",
        description: "Los datos han sido exportados directamente a su dispositivo USB.",
        duration: 5000
      });

      // Mostrar confirmación de que puede retirar el pendrive
      setTimeout(() => {
        toast({
          title: "Pendrive Listo",
          description: "Puede retirar el pendrive de forma segura. Los datos ya están guardados.",
          duration: 8000
        });
      }, 2000);

      onOpenChange(false);

    } catch (error) {
      console.error('Error exporting data:', error);
      toast({
        title: "Error en la exportación",
        description: "Ocurrió un error al exportar los datos. Intente nuevamente.",
        variant: "destructive"
      });
    } finally {
      setIsExporting(false);
    }
  };

  const handleOptionChange = (option: keyof ExportOptions, checked: boolean) => {
    setExportOptions(prev => ({
      ...prev,
      [option]: checked
    }));
  };

  const getTotalRecords = () => {
    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    let total = 0;
    
    if (exportOptions.includeRequests) {
      total += solicitudesPendientes.filter(s => {
        const fecha = new Date(s.horaSolicitud);
        return fecha >= start && fecha <= end;
      }).length;
    }
    
    if (exportOptions.includeDeliveries) {
      total += solicitudesEntregadas.filter(s => {
        const fecha = new Date(s.horaSolicitud);
        return fecha >= start && fecha <= end;
      }).length;
    }
    
    if (exportOptions.includeReturns) {
      total += solicitudesDevueltas.filter(s => {
        const fecha = new Date(s.horaSolicitud);
        return fecha >= start && fecha <= end;
      }).length;
    }

    // Contar objetos olvidados
    if (exportOptions.includeObjetos) {
      total += objetos.filter(o => {
        const fecha = new Date(o.fechaRegistro);
        return fecha >= start && fecha <= end;
      }).length;
    }

    // Contar autorizaciones
    if (exportOptions.includeAutorizaciones) {
      const autorizaciones = getAutorizaciones();
      total += autorizaciones.filter(a => {
        const fecha = new Date(a.fechaAutorizacion);
        return fecha >= start && fecha <= end;
      }).length;
    }

    return total;
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Usb className="w-5 h-5 text-green-600" />
            Exportar Datos a Pendrive
          </DialogTitle>
          <DialogDescription>
            Seleccione el rango de fechas y los datos que desea exportar. Los datos se guardaran directamente en su pendrive.
          </DialogDescription>
        </DialogHeader>

        {/* Pantalla de login — solo si no esta autenticado */}
        {!autenticado ? (
          <div className="space-y-4 py-4">
            <Alert className="bg-blue-50 border-blue-200">
              <AlertDescription className="text-blue-700">
                Para exportar datos debe ingresar la contraseña de acceso autorizado.
              </AlertDescription>
            </Alert>
            <div className="space-y-2">
              <Label htmlFor="export-password">Contraseña de exportación</Label>
              <div className="relative">
                <Input
                  id="export-password"
                  type={showPassword ? 'text' : 'password'}
                  value={passwordInput}
                  onChange={(e) => setPasswordInput(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleLoginExport()}
                  placeholder="Ingrese la contraseña"
                  autoFocus
                  className="pr-10"
                />
                <button
                  type="button"
                  tabIndex={-1}
                  className="absolute right-0 top-0 h-full px-3 py-2 text-muted-foreground hover:text-foreground"
                  onClick={() => setShowPassword(!showPassword)}
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
              {passwordError && (
                <p className="text-sm text-destructive">{passwordError}</p>
              )}
            </div>
            <div className="flex gap-2">
              <Button onClick={handleLoginExport} className="flex-1">
                Verificar y Continuar
              </Button>
              <Button variant="outline" onClick={() => onOpenChange(false)}>
                Cancelar
              </Button>
            </div>
          </div>
        ) : (
        <div className="space-y-6">
          {/* Instrucción de destino */}
          <Alert className="bg-blue-50 border-blue-200">
            <div className="flex items-center gap-2">
              <Usb className="h-4 w-4 text-blue-600" />
              <AlertDescription className="text-blue-700 font-medium">
                Al exportar se abrirá el explorador de archivos. Navegue al pendrive y guarde el archivo ahí.
              </AlertDescription>
            </div>
          </Alert>

          {/* Selección de fechas */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center gap-2">
                <Calendar className="w-4 h-4" />
                Rango de Fechas
              </CardTitle>
              <CardDescription>
                Seleccione el período de tiempo para la exportación
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="startDate">Fecha de Inicio</Label>
                  <DateInput value={startDate} onChange={v => setStartDate(v)} className="h-9" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="endDate">Fecha de Fin</Label>
                  <DateInput value={endDate} onChange={v => setEndDate(v)} className="h-9" />
                </div>
              </div>
              
              {startDate && endDate && (
                <Alert>
                  <Info className="h-4 w-4" />
                  <AlertDescription>
                    Se exportarán aproximadamente <strong>{getTotalRecords()} registros</strong> del período seleccionado.
                  </AlertDescription>
                </Alert>
              )}
            </CardContent>
          </Card>

          {/* Opciones de exportación */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Datos a Incluir</CardTitle>
              <CardDescription>
                Seleccione qué información desea incluir en la exportación
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 gap-3">
                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="includeRequests"
                    checked={exportOptions.includeRequests}
                    onCheckedChange={(checked) => handleOptionChange('includeRequests', checked as boolean)}
                  />
                  <Label htmlFor="includeRequests" className="text-sm font-medium">
                    Solicitudes Pendientes
                  </Label>
                </div>

                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="includeDeliveries"
                    checked={exportOptions.includeDeliveries}
                    onCheckedChange={(checked) => handleOptionChange('includeDeliveries', checked as boolean)}
                  />
                  <Label htmlFor="includeDeliveries" className="text-sm font-medium">
                    Llaves Entregadas
                  </Label>
                </div>

                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="includeReturns"
                    checked={exportOptions.includeReturns}
                    onCheckedChange={(checked) => handleOptionChange('includeReturns', checked as boolean)}
                  />
                  <Label htmlFor="includeReturns" className="text-sm font-medium">
                    Llaves Devueltas
                  </Label>
                </div>

                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="includeStats"
                    checked={exportOptions.includeStats}
                    onCheckedChange={(checked) => handleOptionChange('includeStats', checked as boolean)}
                  />
                  <Label htmlFor="includeStats" className="text-sm font-medium">
                    Estadísticas y Resúmenes
                  </Label>
                </div>

                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="includeUsers"
                    checked={exportOptions.includeUsers}
                    onCheckedChange={(checked) => handleOptionChange('includeUsers', checked as boolean)}
                  />
                  <Label htmlFor="includeUsers" className="text-sm font-medium">
                    Lista de Usuarios Registrados
                  </Label>
                </div>

                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="includeKeys"
                    checked={exportOptions.includeKeys}
                    onCheckedChange={(checked) => handleOptionChange('includeKeys', checked as boolean)}
                  />
                  <Label htmlFor="includeKeys" className="text-sm font-medium">
                    Catálogo de Llaves/Lugares
                  </Label>
                </div>

                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="includeObjetos"
                    checked={exportOptions.includeObjetos}
                    onCheckedChange={(checked) => handleOptionChange('includeObjetos', checked as boolean)}
                  />
                  <Label htmlFor="includeObjetos" className="text-sm font-medium">
                    Objetos Olvidados (Registro y Devolución)
                  </Label>
                </div>

                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="includeAutorizaciones"
                    checked={exportOptions.includeAutorizaciones}
                    onCheckedChange={(checked) => handleOptionChange('includeAutorizaciones', checked as boolean)}
                  />
                  <Label htmlFor="includeAutorizaciones" className="text-sm font-medium">
                    Autorizaciones Ingresadas
                  </Label>
                </div>

                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="includeHistorial"
                    checked={exportOptions.includeHistorial}
                    onCheckedChange={(checked) => handleOptionChange('includeHistorial', checked as boolean)}
                  />
                  <Label htmlFor="includeHistorial" className="text-sm font-medium">
                    Historial de Llaves (últimos 2 años — entregas, devoluciones y notas)
                  </Label>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Botones de acción */}
          <div className="flex gap-3 pt-4">
            <Button 
              onClick={handleExport} 
              disabled={isExporting}
              className="flex-1 bg-green-600 hover:bg-green-700"
            >
              {isExporting ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                  Exportando...
                </>
              ) : (
                <>
                  <Download className="w-4 h-4 mr-2" />
                  Exportar y Guardar
                </>
              )}
            </Button>
            
            <Button 
              variant="outline" 
              onClick={() => onOpenChange(false)}
              disabled={isExporting}
            >
              Cancelar
            </Button>
          </div>
        </div>
        )}
      </DialogContent>
    </Dialog>
  );
}