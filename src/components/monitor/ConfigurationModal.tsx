import { useState, useEffect, useRef } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Card } from '@/components/ui/card';
import { ConfiguracionSistema, CONFIGURACION_DEFAULT } from '@/types/configuracion';
import { Clock, MessageCircle, RefreshCw, Settings, Plus, Minus } from 'lucide-react';
import { ConfirmarAccionSensible } from '@/components/ConfirmarAccionSensible';

interface ConfigurationModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  configuracion: ConfiguracionSistema;
  onGuardar: (config: Partial<ConfiguracionSistema>) => void;
  onResetear: () => void;
}

function NumericStepper({ value, onChange, min = 0, max = 999, label }: {
  value: number;
  onChange: (v: number) => void;
  min?: number;
  max?: number;
  label: string;
}) {
  return (
    <div className="flex items-center gap-3">
      <button
        type="button"
        onClick={() => onChange(Math.max(min, value - 1))}
        className="w-12 h-12 rounded-full border-2 border-gray-300 flex items-center justify-center hover:bg-gray-100 active:bg-gray-200 text-xl font-bold"
      >
        <Minus className="w-5 h-5" />
      </button>
      <div className="text-center min-w-[60px]">
        <div className="text-3xl font-bold">{value}</div>
        <div className="text-xs text-muted-foreground">{label}</div>
      </div>
      <button
        type="button"
        onClick={() => onChange(Math.min(max, value + 1))}
        className="w-12 h-12 rounded-full border-2 border-gray-300 flex items-center justify-center hover:bg-gray-100 active:bg-gray-200 text-xl font-bold"
      >
        <Plus className="w-5 h-5" />
      </button>
    </div>
  );
}

export function ConfigurationModal({ open, onOpenChange, configuracion, onGuardar, onResetear }: ConfigurationModalProps) {
  const [tiempoAlertaHoras, setTiempoAlertaHoras] = useState(0);
  const [tiempoAlertaMinutos, setTiempoAlertaMinutos] = useState(0);
  const [mensaje, setMensaje] = useState('');
  const [transicion, setTransicion] = useState(30);
  const inicializadoRef = useRef(false);
  // Que accion sensible se esta confirmando: null = ninguna.
  // Requerido por jefaturas: cualquier cambio en Configuracion debe
  // pasar por el cartel de advertencia de accion sensible.
  const [accionSensible, setAccionSensible] = useState<null | 'guardar' | 'restaurar'>(null);


  // Solo inicializar cuando se abre el modal, no en cada recarga de configuracion
  useEffect(() => {
    if (open && !inicializadoRef.current) {
      setTiempoAlertaHoras(Math.floor(configuracion.tiempoAlertaMinutos / 60));
      setTiempoAlertaMinutos(configuracion.tiempoAlertaMinutos % 60);
      setMensaje(configuracion.mensajeWhatsApp);
      setTransicion(configuracion.transicionTurnoMinutos);
      inicializadoRef.current = true;
    }
    if (!open) {
      inicializadoRef.current = false;
    }
  }, [open, configuracion]);

  const handleGuardar = () => {
    onGuardar({
      tiempoAlertaMinutos: tiempoAlertaHoras * 60 + tiempoAlertaMinutos,
      mensajeWhatsApp: mensaje,
      transicionTurnoMinutos: transicion,
    });
    onOpenChange(false);
  };

  const handleRestaurar = () => {
    // Actualizar estado local del modal inmediatamente
    setTiempoAlertaHoras(Math.floor(CONFIGURACION_DEFAULT.tiempoAlertaMinutos / 60));
    setTiempoAlertaMinutos(CONFIGURACION_DEFAULT.tiempoAlertaMinutos % 60);
    setMensaje(CONFIGURACION_DEFAULT.mensajeWhatsApp);
    setTransicion(CONFIGURACION_DEFAULT.transicionTurnoMinutos);
    // Persistir en PocketBase
    onResetear();
  };

  // Texto exacto requerido por jefaturas para toda accion sensible en
  // la pestana Configuracion (guardar o restaurar).
  const TEXTO_ADVERTENCIA =
    'Atención! acción sensible, usted quiere modificar datos en el sistema ' +
    'que requieren permisos de jefaturas, de continuar con esta acción ' +
    'quedará registro de los cambios que realiza.';

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
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
          <Card className="p-4">
            <div className="flex items-start gap-3">
              <Clock className="w-5 h-5 mt-1 text-warning" />
              <div className="flex-1">
                <Label className="text-sm font-medium">Tiempo para alerta de devolución</Label>
                <p className="text-xs text-muted-foreground mb-4">
                  Se mostrará el punto rojo y panel de WhatsApp después de este tiempo
                </p>
                <div className="flex items-center gap-6">
                  <NumericStepper value={tiempoAlertaHoras} onChange={setTiempoAlertaHoras} min={0} max={12} label="horas" />
                  <NumericStepper value={tiempoAlertaMinutos} onChange={setTiempoAlertaMinutos} min={0} max={59} label="minutos" />
                </div>
              </div>
            </div>
          </Card>

          <Card className="p-4">
            <div className="flex items-start gap-3">
              <MessageCircle className="w-5 h-5 mt-1 text-success" />
              <div className="flex-1">
                <Label className="text-sm font-medium">Mensaje de WhatsApp</Label>
                <p className="text-xs text-muted-foreground mb-2">
                  Usa <code className="bg-muted px-1 rounded">{'{{LLAVE}}'}</code> para insertar el nombre de la llave
                </p>
                <Textarea value={mensaje} onChange={(e) => setMensaje(e.target.value)} rows={4} placeholder="Mensaje a enviar por WhatsApp..." />
              </div>
            </div>
          </Card>

          <Card className="p-4">
            <div className="flex items-start gap-3">
              <RefreshCw className="w-5 h-5 mt-1 text-primary" />
              <div className="flex-1">
                <Label className="text-sm font-medium">Período de transición de turno</Label>
                <p className="text-xs text-muted-foreground mb-4">
                  Tiempo que se muestran los vigilantes del turno anterior
                </p>
                <NumericStepper value={transicion} onChange={setTransicion} min={0} max={120} label="minutos" />
              </div>
            </div>
          </Card>
        </div>

        <DialogFooter className="flex-col sm:flex-row gap-2">
          <Button
            variant="outline"
            onClick={() => setAccionSensible('restaurar')}
            className="gap-2"
          >
            <RefreshCw className="w-4 h-4" />
            Restaurar valores
          </Button>
          <Button onClick={() => setAccionSensible('guardar')}>Guardar cambios</Button>
        </DialogFooter>
      </DialogContent>

      {/*
        Cartel de advertencia de accion sensible. Se muestra al confirmar
        CUALQUIER cambio de la pestana Configuracion (guardar o restaurar).
        Texto exacto exigido por jefaturas -> se pasa via descripcionExtra.
      */}
      <ConfirmarAccionSensible
        open={accionSensible !== null}
        onOpenChange={(v) => { if (!v) setAccionSensible(null); }}
        tipoAccion="editar"
        entidad="otro"
        detalle="Configuración del Sistema"
        descripcionExtra={TEXTO_ADVERTENCIA}
        onConfirmar={() => {
          if (accionSensible === 'guardar') handleGuardar();
          else if (accionSensible === 'restaurar') handleRestaurar();
          setAccionSensible(null);
        }}
      />
    </Dialog>
  );
}
