import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Download, Calendar, FileSpreadsheet, Usb, Info, Check, X } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { exportToExcel, hayUSBConectado, obtenerUSBsConectados } from '@/utils/exportUtils';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';
import { useAdminAuth } from '@/hooks/useAdminAuth';

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
}

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
    includeKeys: false
  });

  const [isExporting, setIsExporting] = useState(false);
  const [usbStatus, setUsbStatus] = useState({ 
    connected: false, 
    drives: [] as Array<{mountPoint: string, label: string}> 
  });
  const { toast } = useToast();
  const { solicitudesPendientes, solicitudesEntregadas, solicitudesDevueltas } = useSolicitudesContext();
  const { isCustodian } = useAdminAuth();

  // Verificar si hay un USB conectado cuando se abre el modal
  useEffect(() => {
    if (open) {
      checkUsbStatus();
      const interval = setInterval(checkUsbStatus, 2000);
      return () => clearInterval(interval);
    }
  }, [open]);

  const checkUsbStatus = () => {
    const connected = hayUSBConectado();
    const drives = obtenerUSBsConectados();
    setUsbStatus({ connected, drives });
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

    // Si es custodio, verificar USB
    if (isCustodian && !usbStatus.connected) {
      toast({
        title: "No hay USB conectado",
        description: "Por favor conecte un dispositivo USB para continuar con la exportación",
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
          }) : []
      };

      // Preparar datos para exportación
      const exportData = {
        ...filteredData,
        dateRange: {
          start: startDate,
          end: endDate
        },
        exportOptions,
        generatedAt: new Date().toISOString(),
        generatedBy: isCustodian ? 'Custodio FCEA' : 'Administrador FCEA'
      };

      // Generar nombre de archivo con fecha y hora
      const now = new Date();
      const formattedDate = now.toISOString().split('T')[0];
      const formattedTime = now.toTimeString().split(' ')[0].replace(/:/g, '-');
      const fileName = `Dashboard_FCEA_${startDate}_${endDate}_${formattedDate}_${formattedTime}`;

      // Exportar a Excel
      await exportToExcel(exportData, fileName, {
        includeStats: exportOptions.includeStats,
        includeUsers: exportOptions.includeUsers,
        includeKeys: exportOptions.includeKeys,
        dateRange: { start: startDate, end: endDate },
        directToUsb: isCustodian && usbStatus.connected, // Si es custodio y hay USB, exportar directamente al USB
        usbPath: isCustodian && usbStatus.connected ? usbStatus.drives[0].mountPoint : undefined
      });

      let exportMessage = "Los datos han sido exportados a Excel.";
      if (isCustodian && usbStatus.connected) {
        exportMessage = "Los datos han sido exportados directamente a su dispositivo USB.";
      } else {
        exportMessage = "Los datos han sido exportados a Excel. El archivo se ha descargado automáticamente.";
      }

      toast({
        title: "Exportación exitosa",
        description: exportMessage,
        duration: 5000
      });

      // Si no es custodio o no hay USB, mostrar instrucciones para pendrive
      if (!isCustodian || !usbStatus.connected) {
        setTimeout(() => {
          toast({
            title: "💾 Copia a Pendrive",
            description: "Puede encontrar el archivo en su carpeta de Descargas. Cópielo a su pendrive para llevarlo.",
            duration: 8000
          });
        }, 2000);
      } else {
        // Si es custodio y hay USB, mostrar confirmación
        setTimeout(() => {
          toast({
            title: "✅ Pendrive Listo",
            description: "Puede retirar el pendrive de forma segura. Los datos ya están guardados.",
            duration: 8000
          });
        }, 2000);
      }

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

    return total;
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            {isCustodian ? (
              <Usb className="w-5 h-5 text-amber-600" />
            ) : (
              <FileSpreadsheet className="w-5 h-5 text-green-600" />
            )}
            {isCustodian ? 'Exportación Segura a USB' : 'Exportación Avanzada a Excel'}
          </DialogTitle>
          <DialogDescription>
            {isCustodian 
              ? "Seleccione el rango de fechas y los datos que desea exportar. Los datos se guardarán directamente en su pendrive."
              : "Seleccione el rango de fechas y los datos que desea exportar. El archivo se descargará automáticamente y podrá copiarlo a un pendrive."}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Estado del USB para custodios */}
          {isCustodian && (
            <Alert className={usbStatus.connected ? "bg-green-50 border-green-200 text-green-800" : "bg-amber-50 border-amber-200 text-amber-800"}>
              <div className="flex items-center gap-2">
                {usbStatus.connected ? (
                  <>
                    <Check className="h-4 w-4 text-green-600" />
                    <AlertDescription className="text-green-700 font-medium">
                      Dispositivo USB detectado: {usbStatus.drives[0]?.label || "Pendrive"}
                    </AlertDescription>
                  </>
                ) : (
                  <>
                    <X className="h-4 w-4 text-amber-600" />
                    <AlertDescription className="text-amber-700 font-medium">
                      No se detecta ningún dispositivo USB. Por favor, conecte un pendrive.
                    </AlertDescription>
                  </>
                )}
              </div>
            </Alert>
          )}

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
                  <Input
                    id="startDate"
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="endDate">Fecha de Fin</Label>
                  <Input
                    id="endDate"
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                  />
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
              </div>
            </CardContent>
          </Card>

          {/* Instrucciones para pendrive */}
          <Alert>
            <Usb className="h-4 w-4" />
            <AlertDescription>
              {isCustodian ? (
                <div>
                  <strong>👑 Modo Custodio:</strong>{' '}
                  {usbStatus.connected 
                    ? "La información se guardará automáticamente en su pendrive. No desconecte el dispositivo durante la exportación."
                    : "Conecte un pendrive para guardar la información directamente."}
                </div>
              ) : (
                <div>
                  <strong>💾 Para llevar en pendrive:</strong> El archivo se descargará en su carpeta de Descargas. 
                  Luego puede copiarlo a un pendrive para llevarlo y abrirlo en cualquier computadora con Excel.
                </div>
              )}
            </AlertDescription>
          </Alert>

          {/* Botones de acción */}
          <div className="flex gap-3 pt-4">
            <Button 
              onClick={handleExport} 
              disabled={isExporting || (isCustodian && !usbStatus.connected)}
              className={`flex-1 ${isCustodian ? (usbStatus.connected ? 'bg-green-600 hover:bg-green-700' : '') : ''}`}
            >
              {isExporting ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                  Exportando...
                </>
              ) : (
                <>
                  {isCustodian ? (
                    <Usb className="w-4 h-4 mr-2" />
                  ) : (
                    <Download className="w-4 h-4 mr-2" />
                  )}
                  {isCustodian ? 'Exportar a USB' : 'Exportar a Excel'}
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
      </DialogContent>
    </Dialog>
  );
}