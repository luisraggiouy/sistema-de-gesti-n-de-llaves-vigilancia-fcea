import { useState, useEffect } from 'react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SolicitudLlave, AccionUndo } from '@/types/solicitud';
import { formatearUbicacion, getColorTipoLugar, obtenerVigilantesActuales } from '@/data/fceaData';
import { Key, MapPin, User, Phone, Clock, Undo2, CheckCircle } from 'lucide-react';

interface SolicitudCardProps {
  solicitud: SolicitudLlave;
  undoAction?: AccionUndo;
  onEntregar: (vigilante: string) => void;
  onDevolver: (vigilante: string) => void;
  onUndo: () => void;
}

export function SolicitudCard({ 
  solicitud, 
  undoAction,
  onEntregar, 
  onDevolver, 
  onUndo 
}: SolicitudCardProps) {
  const [tiempoRestante, setTiempoRestante] = useState<number>(0);
  const vigilantesActuales = obtenerVigilantesActuales();
  
  // Timer para el countdown del undo
  useEffect(() => {
    if (!undoAction) {
      setTiempoRestante(0);
      return;
    }

    const updateTimer = () => {
      const remaining = Math.max(0, undoAction.expiresAt.getTime() - Date.now());
      setTiempoRestante(Math.ceil(remaining / 1000));
    };

    updateTimer();
    const interval = setInterval(updateTimer, 1000);
    return () => clearInterval(interval);
  }, [undoAction]);

  const formatTiempo = (segundos: number) => {
    const min = Math.floor(segundos / 60);
    const seg = segundos % 60;
    return `${min}:${seg.toString().padStart(2, '0')}`;
  };

  const tiempoDesdeCreacion = () => {
    const diff = Date.now() - solicitud.horaSolicitud.getTime();
    const minutos = Math.floor(diff / 60000);
    if (minutos < 1) return 'Ahora';
    if (minutos === 1) return 'Hace 1 min';
    return `Hace ${minutos} min`;
  };

  const colorTipo = getColorTipoLugar(solicitud.lugar.tipo);

  // Estado con undo disponible
  if (undoAction && tiempoRestante > 0) {
    return (
      <Card className="p-4 border-2 border-warning bg-warning/5 relative overflow-hidden">
        <div className="absolute top-0 left-0 h-1 bg-warning transition-all" 
          style={{ width: `${(tiempoRestante / 120) * 100}%` }} 
        />
        
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={`p-2 rounded-lg ${colorTipo}`}>
              <Key className="w-5 h-5 text-white" />
            </div>
            <div>
              <p className="font-semibold">{solicitud.lugar.nombre}</p>
              <p className="text-sm text-muted-foreground">
                {undoAction.tipo === 'entrega' ? 'Entregada' : 'Devuelta'} por {undoAction.vigilante}
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-3">
            <div className="text-right">
              <p className="text-lg font-mono font-bold text-warning">{formatTiempo(tiempoRestante)}</p>
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

  // Estado pendiente
  if (solicitud.estado === 'pendiente') {
    return (
      <Card className="p-4 hover:shadow-md transition-shadow">
        <div className="flex flex-col lg:flex-row lg:items-center gap-4">
          {/* Info del lugar */}
          <div className="flex items-start gap-3 flex-1">
            <div className={`p-3 rounded-xl ${colorTipo}`}>
              <Key className="w-6 h-6 text-white" />
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1">
                <h3 className="font-semibold text-lg">{solicitud.lugar.nombre}</h3>
                <Badge variant="secondary" className="text-xs">
                  {solicitud.lugar.tipo}
                </Badge>
              </div>
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <MapPin className="w-4 h-4" />
                <span className="font-mono">{formatearUbicacion(solicitud.lugar.ubicacion)}</span>
              </div>
            </div>
          </div>
          
          {/* Info del usuario */}
          <div className="flex items-center gap-4 text-sm">
            <div className="flex items-center gap-2">
              <User className="w-4 h-4 text-muted-foreground" />
              <span>{solicitud.usuario.nombre}</span>
              <Badge variant="outline" className="text-xs">{solicitud.usuario.tipo}</Badge>
            </div>
            <div className="flex items-center gap-2 text-muted-foreground">
              <Phone className="w-4 h-4" />
              <span className="font-mono">{solicitud.usuario.celular}</span>
            </div>
            <div className="flex items-center gap-2 text-muted-foreground">
              <Clock className="w-4 h-4" />
              <span>{tiempoDesdeCreacion()}</span>
            </div>
          </div>
        </div>
        
        {/* Botones de vigilantes */}
        <div className="mt-4 pt-4 border-t">
          <p className="text-sm font-medium text-muted-foreground mb-2">Entregar llave:</p>
          <div className="flex flex-wrap gap-2">
            {vigilantesActuales.map(v => (
              <Button
                key={v.id}
                variant={v.esJefe ? 'default' : 'outline'}
                size="sm"
                className="gap-2"
                onClick={() => onEntregar(v.nombre)}
              >
                {v.esJefe && <CheckCircle className="w-3 h-3" />}
                {v.nombre}
              </Button>
            ))}
          </div>
        </div>
      </Card>
    );
  }

  // Estado entregada (esperando devolución)
  return (
    <Card className="p-4 bg-success/5 border-success/20">
      <div className="flex flex-col lg:flex-row lg:items-center gap-4">
        <div className="flex items-start gap-3 flex-1">
          <div className={`p-3 rounded-xl ${colorTipo}`}>
            <Key className="w-6 h-6 text-white" />
          </div>
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-1">
              <h3 className="font-semibold text-lg">{solicitud.lugar.nombre}</h3>
              <Badge className="bg-success text-success-foreground text-xs">
                En uso
              </Badge>
            </div>
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <MapPin className="w-4 h-4" />
              <span className="font-mono">{formatearUbicacion(solicitud.lugar.ubicacion)}</span>
            </div>
            <p className="text-sm mt-1">
              Entregada por <span className="font-medium">{solicitud.entregadoPor}</span> a{' '}
              <span className="font-medium">{solicitud.usuario.nombre}</span>
            </p>
          </div>
        </div>
      </div>
      
      {/* Botones para devolución */}
      <div className="mt-4 pt-4 border-t border-success/20">
        <p className="text-sm font-medium text-muted-foreground mb-2">Registrar devolución:</p>
        <div className="flex flex-wrap gap-2">
          {vigilantesActuales.map(v => (
            <Button
              key={v.id}
              variant="outline"
              size="sm"
              className="gap-2 border-success/30 hover:bg-success/10"
              onClick={() => onDevolver(v.nombre)}
            >
              {v.nombre}
            </Button>
          ))}
        </div>
      </div>
    </Card>
  );
}
