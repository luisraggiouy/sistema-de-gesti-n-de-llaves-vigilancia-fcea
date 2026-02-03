import { useState } from 'react';
import { Download, FileSpreadsheet, Mail, Calendar } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Card } from '@/components/ui/card';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';
import { useVigilantes } from '@/hooks/useVigilantes';
import { generarReporteMensual, exportarCSV, descargarCSV } from '@/utils/exportUtils';
import { Turno } from '@/data/fceaData';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { useToast } from '@/hooks/use-toast';

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
  const { registrosActividad } = useSolicitudesContext();
  const { vigilantes } = useVigilantes();
  
  const ahora = new Date();
  const [mesSeleccionado, setMesSeleccionado] = useState(ahora.getMonth().toString());
  const [anioSeleccionado, setAnioSeleccionado] = useState(ahora.getFullYear().toString());

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

  const handleExportCSV = () => {
    const mes = parseInt(mesSeleccionado);
    const anio = parseInt(anioSeleccionado);
    
    const reporte = generarReporteMensual(registrosActividad, mes, anio, vigilantesPorTurno);
    
    if (reporte.registros.length === 0) {
      toast({
        title: "Sin datos",
        description: `No hay registros para ${meses[mes]} ${anio}`,
        variant: "destructive"
      });
      return;
    }
    
    const csv = exportarCSV(reporte);
    const nombreArchivo = `reporte-llaves-${reporte.mes.toLowerCase()}-${anio}.csv`;
    
    descargarCSV(csv, nombreArchivo);
    
    toast({
      title: "Reporte exportado",
      description: `Se descargó ${nombreArchivo}`,
    });
    
    onOpenChange(false);
  };

  // Vista previa del reporte
  const reporte = generarReporteMensual(
    registrosActividad, 
    parseInt(mesSeleccionado), 
    parseInt(anioSeleccionado),
    vigilantesPorTurno
  );

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <FileSpreadsheet className="w-5 h-5" />
            Exportar Reporte Mensual
          </DialogTitle>
          <DialogDescription>
            Genera un reporte CSV con las estadísticas del mes seleccionado
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Selección de período */}
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

          {/* Vista previa */}
          <Card className="p-4 bg-muted/50">
            <h4 className="font-medium mb-3 flex items-center gap-2">
              <Calendar className="w-4 h-4" />
              Vista previa: {reporte.mes} {reporte.anio}
            </h4>
            
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <p className="text-muted-foreground">Total entregas</p>
                <p className="text-xl font-bold text-success">{reporte.totalEntregas}</p>
              </div>
              <div>
                <p className="text-muted-foreground">Total devoluciones</p>
                <p className="text-xl font-bold text-info">{reporte.totalDevoluciones}</p>
              </div>
            </div>

            {reporte.registros.length === 0 && (
              <p className="text-sm text-muted-foreground mt-3 text-center">
                No hay registros para este período
              </p>
            )}
          </Card>

          {/* Nota sobre automatización */}
          <Card className="p-4 border-dashed">
            <div className="flex items-start gap-3">
              <Mail className="w-5 h-5 text-muted-foreground mt-0.5" />
              <div className="text-sm">
                <p className="font-medium">¿Automatizar envío mensual?</p>
                <p className="text-muted-foreground">
                  Para enviar automáticamente el reporte por email a la intendencia, 
                  activa Lovable Cloud para configurar tareas programadas.
                </p>
              </div>
            </div>
          </Card>

          {/* Acciones */}
          <div className="flex justify-end gap-3">
            <Button variant="outline" onClick={() => onOpenChange(false)}>
              Cancelar
            </Button>
            <Button 
              onClick={handleExportCSV}
              disabled={reporte.registros.length === 0}
              className="gap-2"
            >
              <Download className="w-4 h-4" />
              Descargar CSV
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
