import { useState, useEffect } from 'react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SolicitudLlave, AccionUndo } from '@/types/solicitud';
import { Vigilante } from '@/data/fceaData';
import { formatearUbicacion, getColorTipoLugar } from '@/data/fceaData';
import { Key, MapPin, Clock, Undo2, MessageCircle, AlertCircle, ArrowRightLeft } from 'lucide-react';
import { KeyExchangeModal } from './KeyExchangeModal';

interface KeyInUseCardProps {
  solicitud: SolicitudLlave;
  undoAction?: AccionUndo;
  vigilantes: Vigilante[];
  vigilantesAnteriores?: Vigilante[];
  tiempoAlertaMinutos: number;
  mensajeWhatsApp: string;
  onDevolver: (vigilante: string) => void;
  onUndo: () => void;
  onIntercambiar: (vigilante: string, nuevoUsuario: { nombre: string; celular: string; tipo: string }) => void;
}

export function KeyInUseCard({
  solicitud,
  undoAction,
  vigilantes,
  vigilantesAnteriores = [],
  tiempoAlertaMinutos,
  mensajeWhatsApp,
  onDevolver,
  onUndo,
  onIntercambiar
}: KeyInUseCardProps) {
  const [tiempoRestanteUndo, setTiempoRestanteUndo] = useState<number>(0);
  const [tiempoEnUso, setTiempoEnUso] = useState<number>(0);
  const [exchangeModalOpen, setExchangeModalOpen] = useState(false);

  // Timer para el countdown del undo
  useEffect(() => {
    if (!undoAction) {
      setTiempoRestanteUndo(0);
      return;
    }

    const updateTimer = () => {
      const remaining = Math.max(0, undoAction.expiresAt.getTime() - Date.now());
      setTiempoRestanteUndo(Math.ceil(remaining / 1000));
    };

    updateTimer();
    const interval = setInterval(updateTimer, 1000);
    return () => clearInterval(interval);
  }, [undoAction]);

  // Timer para tiempo en uso
  useEffect(() => {
    const updateTiempoEnUso = () => {
      if (solicitud.horaEntrega) {
        const diff = Date.now() - solicitud.horaEntrega.getTime();
        setTiempoEnUso(Math.floor(diff / 1000));
      }
    };

    updateTiempoEnUso();
    const interval = setInterval(updateTiempoEnUso, 1000);
    return () => clearInterval(interval);
  }, [solicitud.horaEntrega]);

  const formatTiempoUndo = (segundos: number) => {
    const min = Math.floor(segundos / 60);
    const seg = segundos % 60;
    return `${min}:${seg.toString().padStart(2, '0')}`;
  };

  const formatTiempoEnUso = (segundos: number) => {
    const horas = Math.floor(segundos / 3600);
    const minutos = Math.floor((segundos % 3600) / 60);
    
    if (horas > 0) {
      return `${horas}h ${minutos}m`;
    }
    return `${minutos}m`;
  };

  const tiempoEnUsoMinutos = tiempoEnUso / 60;
  // Solo alertar por tiempo excedido en salones (las oficinas se quedan con las llaves más tiempo)
  const tiposConAlerta: string[] = ['Salón', 'Salón Híbrido'];
  const aplicaAlerta = tiposConAlerta.includes(solicitud.lugar.tipo);
  const estaEnAlerta = aplicaAlerta && tiempoEnUsoMinutos >= tiempoAlertaMinutos;

  const colorTipo = getColorTipoLugar(solicitud.lugar.tipo);

  const handleEnviarWhatsApp = () => {
    const mensaje = mensajeWhatsApp.replace('{{LLAVE}}', solicitud.lugar.nombre);
    const celular = solicitud.usuario.celular.replace(/\D/g, '');
    // Formato para Uruguay: agregar 598 si no tiene código de país
    const celularFormateado = celular.startsWith('598') ? celular : `598${celular}`;
    const url = `https://wa.me/${celularFormateado}?text=${encodeURIComponent(mensaje)}`;
    window.open(url, '_blank');
  };

  // Estado con undo disponible
  if (undoAction && tiempoRestanteUndo > 0) {
    return (
      <Card className="p-4 border-2 border-warning bg-warning/5 relative overflow-hidden">
        <div 
          className="absolute top-0 left-0 h-1 bg-warning transition-all" 
          style={{ width: `${(tiempoRestanteUndo / 120) * 100}%` }} 
        />
        
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={`p-2 rounded-lg ${colorTipo}`}>
              <Key className="w-5 h-5 text-white" />
            </div>
            <div>
              <p className="font-semibold">{solicitud.lugar.nombre}</p>
              <p className="text-sm text-muted-foreground">
                Entregada por {undoAction.vigilante}
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-3">
            <div className="text-right">
              <p className="text-lg font-mono font-bold text-warning">{formatTiempoUndo(tiempoRestanteUndo)}</p>
              <p className="text-xs text-muted-foreground">para deshacer</p>
            </div>
            <Button 
              variant="outline" 
              className="gap-2 border-warning text-warning hover:bg-warning hover:text-warning-foreground"
              onClick={onUndo}
            >
              <Undo2 className="w-4 h-4" />
              Deshacer
            </Button>
          </div>
        </div>
      </Card>
    );
  }

  // Estado normal - llave en uso
  return (
    <Card className={`p-4 ${estaEnAlerta ? 'bg-destructive/5 border-destructive/30' : 'bg-rose-50 border-rose-200'}`}>
      <div className="flex flex-col lg:flex-row lg:items-center gap-4">
        <div className="flex items-start gap-3 flex-1">
          <div className={`p-3 rounded-xl ${colorTipo}`}>
            <Key className="w-6 h-6 text-white" />
          </div>
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-1 flex-wrap">
              <h3 className="font-semibold text-lg">{solicitud.lugar.nombre}</h3>
              <Badge className="bg-success text-success-foreground text-xs">
                En uso
              </Badge>
              {solicitud.esIntercambio && (
                <Badge variant="outline" className="text-xs border-primary/30 text-primary">
                  <ArrowRightLeft className="w-3 h-3 mr-1" />
                  Intercambio
                </Badge>
              )}
              {estaEnAlerta && (
                <span className="relative flex h-3 w-3">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-destructive opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-3 w-3 bg-destructive"></span>
                </span>
              )}
            </div>
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <MapPin className="w-4 h-4" />
              <span className="font-mono">{formatearUbicacion(solicitud.lugar.ubicacion)}</span>
            </div>
            <p className="text-sm mt-1">
              Entregada por <span className="font-medium">{solicitud.entregadoPor}</span> a{' '}
              <span className="font-medium">{solicitud.usuario.nombre}</span>
              {solicitud.usuarioAnterior && (
                <span className="text-muted-foreground"> (antes: {solicitud.usuarioAnterior.nombre})</span>
              )}
            </p>
          </div>
        </div>

        {/* Tiempo en uso */}
        <div className={`flex items-center gap-2 px-3 py-2 rounded-lg ${estaEnAlerta ? 'bg-destructive/10' : 'bg-muted/50'}`}>
          <Clock className={`w-4 h-4 ${estaEnAlerta ? 'text-destructive' : 'text-muted-foreground'}`} />
          <div>
            <p className={`text-sm font-medium ${estaEnAlerta ? 'text-destructive' : ''}`}>
              En uso hace {formatTiempoEnUso(tiempoEnUso)}
            </p>
            {estaEnAlerta && (
              <p className="text-xs text-destructive flex items-center gap-1">
                <AlertCircle className="w-3 h-3" />
                Tiempo excedido
              </p>
            )}
          </div>
        </div>

        {/* Botón WhatsApp si está en alerta */}
        {estaEnAlerta && (
          <Button
            variant="outline"
            size="sm"
            className="gap-2 border-success text-success hover:bg-success/10 hover:text-success"
            onClick={handleEnviarWhatsApp}
          >
            <MessageCircle className="w-4 h-4" />
            Enviar WhatsApp
          </Button>
        )}
      </div>
      
      {/* Botones para devolución e intercambio */}
      <div className="mt-4 pt-4 border-t border-success/20">
        <div className="flex items-center justify-between mb-2">
          <p className="text-sm font-medium text-muted-foreground">Registrar devolución:</p>
          <Button
            variant="outline"
            size="sm"
            className="gap-2 border-primary/30 text-primary hover:bg-primary/10"
            onClick={() => setExchangeModalOpen(true)}
          >
            <ArrowRightLeft className="w-4 h-4" />
            Intercambiar
          </Button>
        </div>
        <div className="flex flex-wrap gap-2">
          {/* Vigilantes del turno actual */}
          {vigilantes.map(v => (
            <Button
              key={v.id}
              variant="outline"
              size="sm"
              className="gap-2 border-success/30 hover:bg-success/10"
              onClick={() => onDevolver(v.nombre)}
            >
              {v.esJefe && <span className="w-2 h-2 rounded-full bg-primary" />}
              {v.nombre}
            </Button>
          ))}
          
          {/* Vigilantes del turno anterior (en transición) */}
          {vigilantesAnteriores.length > 0 && (
            <>
              <div className="w-px h-6 bg-border mx-1" />
              {vigilantesAnteriores.map(v => (
                <Button
                  key={v.id}
                  variant="ghost"
                  size="sm"
                  className="gap-2 text-muted-foreground hover:bg-muted/50"
                  onClick={() => onDevolver(v.nombre)}
                >
                  {v.nombre}
                  <span className="text-xs">(turno ant.)</span>
                </Button>
              ))}
            </>
          )}
        </div>
      </div>

      <KeyExchangeModal
        open={exchangeModalOpen}
        onOpenChange={setExchangeModalOpen}
        solicitud={solicitud}
        vigilantes={vigilantes}
        vigilantesAnteriores={vigilantesAnteriores}
        onConfirmar={onIntercambiar}
      />
    </Card>
  );
}
