import { useState, useEffect } from 'react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Card } from '@/components/ui/card';
import { ConfiguracionSistema } from '@/types/configuracion';
import { Clock, MessageCircle, RefreshCw, Settings } from 'lucide-react';

interface ConfigurationModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  configuracion: ConfiguracionSistema;
  onGuardar: (config: Partial<ConfiguracionSistema>) => void;
  onResetear: () => void;
}

export function ConfigurationModal({
  open,
  onOpenChange,
  configuracion,
  onGuardar,
  onResetear
}: ConfigurationModalProps) {
  const [tiempoAlertaHoras, setTiempoAlertaHoras] = useState(0);
  const [tiempoAlertaMinutos, setTiempoAlertaMinutos] = useState(0);
  const [mensaje, setMensaje] = useState('');
  const [transicion, setTransicion] = useState(30);

  useEffect(() => {
    const horas = Math.floor(configuracion.tiempoAlertaMinutos / 60);
    const minutos = configuracion.tiempoAlertaMinutos % 60;
    setTiempoAlertaHoras(horas);
    setTiempoAlertaMinutos(minutos);
    setMensaje(configuracion.mensajeWhatsApp);
    setTransicion(configuracion.transicionTurnoMinutos);
  }, [configuracion]);

  const handleGuardar = () => {
    const tiempoTotalMinutos = tiempoAlertaHoras * 60 + tiempoAlertaMinutos;
    onGuardar({
      tiempoAlertaMinutos: tiempoTotalMinutos,
      mensajeWhatsApp: mensaje,
      transicionTurnoMinutos: transicion
    });
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Settings className="w-5 h-5" />
            Configuración del Sistema
          </DialogTitle>
          <DialogDescription>
            Personalizar tiempos y mensajes del sistema de vigilancia
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Tiempo de alerta */}
          <Card className="p-4">
            <div className="flex items-start gap-3">
              <Clock className="w-5 h-5 mt-1 text-warning" />
              <div className="flex-1">
                <Label className="text-sm font-medium">Tiempo para alerta de devolución</Label>
                <p className="text-xs text-muted-foreground mb-2">
                  Se mostrará el punto rojo y botón de WhatsApp después de este tiempo
                </p>
                <div className="flex items-center gap-2">
                  <div className="flex items-center gap-1">
                    <Input
                      type="number"
                      min={0}
                      max={12}
                      value={tiempoAlertaHoras}
                      onChange={(e) => setTiempoAlertaHoras(parseInt(e.target.value) || 0)}
                      className="w-16"
                    />
                    <span className="text-sm">h</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Input
                      type="number"
                      min={0}
                      max={59}
                      value={tiempoAlertaMinutos}
                      onChange={(e) => setTiempoAlertaMinutos(parseInt(e.target.value) || 0)}
                      className="w-16"
                    />
                    <span className="text-sm">min</span>
                  </div>
                </div>
              </div>
            </div>
          </Card>

          {/* Mensaje de WhatsApp */}
          <Card className="p-4">
            <div className="flex items-start gap-3">
              <MessageCircle className="w-5 h-5 mt-1 text-success" />
              <div className="flex-1">
                <Label className="text-sm font-medium">Mensaje de WhatsApp</Label>
                <p className="text-xs text-muted-foreground mb-2">
                  Usa <code className="bg-muted px-1 rounded">{'{{LLAVE}}'}</code> para insertar el nombre de la llave
                </p>
                <Textarea
                  value={mensaje}
                  onChange={(e) => setMensaje(e.target.value)}
                  rows={4}
                  placeholder="Mensaje a enviar por WhatsApp..."
                />
              </div>
            </div>
          </Card>

          {/* Tiempo de transición de turno */}
          <Card className="p-4">
            <div className="flex items-start gap-3">
              <RefreshCw className="w-5 h-5 mt-1 text-primary" />
              <div className="flex-1">
                <Label className="text-sm font-medium">Período de transición de turno</Label>
                <p className="text-xs text-muted-foreground mb-2">
                  Tiempo que se muestran los vigilantes del turno anterior
                </p>
                <div className="flex items-center gap-1">
                  <Input
                    type="number"
                    min={0}
                    max={120}
                    value={transicion}
                    onChange={(e) => setTransicion(parseInt(e.target.value) || 0)}
                    className="w-20"
                  />
                  <span className="text-sm">minutos</span>
                </div>
              </div>
            </div>
          </Card>
        </div>

        <DialogFooter className="flex-col sm:flex-row gap-2">
          <Button variant="outline" onClick={onResetear} className="gap-2">
            <RefreshCw className="w-4 h-4" />
            Restaurar valores
          </Button>
          <Button onClick={handleGuardar}>
            Guardar cambios
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
