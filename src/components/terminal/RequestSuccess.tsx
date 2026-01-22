import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Lugar, formatearUbicacion } from '@/data/fceaData';
import { CheckCircle2, Key, MapPin, ArrowRight } from 'lucide-react';

interface RequestSuccessProps {
  selectedKey: Lugar;
  ticketNumber: string;
  onNewRequest: () => void;
}

export function RequestSuccess({ selectedKey, ticketNumber, onNewRequest }: RequestSuccessProps) {
  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] text-center">
      <Card className="p-8 max-w-md w-full bg-gradient-to-br from-success/10 to-card border-success/20">
        <div className="mb-6">
          <div className="mx-auto w-20 h-20 bg-success/20 rounded-full flex items-center justify-center mb-4">
            <CheckCircle2 className="w-12 h-12 text-success" />
          </div>
          <h2 className="text-2xl font-bold text-foreground mb-2">
            ¡Solicitud Enviada!
          </h2>
          <p className="text-muted-foreground">
            Un vigilante procesará su solicitud en breve
          </p>
        </div>
        
        <div className="bg-card rounded-xl p-4 border mb-6">
          <div className="flex items-center gap-3 mb-3">
            <Key className="w-6 h-6 text-primary" />
            <p className="font-semibold text-lg">{selectedKey.nombre}</p>
          </div>
          <div className="flex items-center gap-2 text-muted-foreground mb-4">
            <MapPin className="w-4 h-4" />
            <span>Ubicación: {formatearUbicacion(selectedKey.ubicacion)}</span>
          </div>
          
          <div className="bg-primary/5 rounded-lg p-3">
            <p className="text-sm text-muted-foreground mb-1">Número de ticket</p>
            <p className="text-2xl font-mono font-bold text-primary">{ticketNumber}</p>
          </div>
        </div>
        
        <div className="space-y-3">
          <div className="flex items-center justify-center gap-2 text-sm text-muted-foreground">
            <ArrowRight className="w-4 h-4" />
            <span>Diríjase al mostrador de vigilancia</span>
          </div>
          
          <Button 
            onClick={onNewRequest}
            variant="outline"
            className="w-full h-12"
          >
            Nueva Solicitud
          </Button>
        </div>
      </Card>
    </div>
  );
}
