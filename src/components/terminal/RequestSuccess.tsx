import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Lugar } from '@/data/fceaData';
import { CheckCircle2, Key, XCircle, Building2 } from 'lucide-react';

interface RequestSuccessProps {
  selectedKeys: Lugar[];
  onNewRequest: () => void;
  onCancelRequest: () => void;
}

export function RequestSuccess({ selectedKeys, onNewRequest, onCancelRequest }: RequestSuccessProps) {
  const [contador, setContador] = useState(5);

  useEffect(() => {
    if (contador <= 0) {
      onNewRequest();
      return;
    }
    const timer = setTimeout(() => setContador(c => c - 1), 1000);
    return () => clearTimeout(timer);
  }, [contador, onNewRequest]);

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
          <p className="text-lg font-medium text-success mt-1">
            Ya le entregan la llave solicitada, gracias
          </p>
        </div>

        <div className="bg-card rounded-xl p-4 border mb-6">
          <p className="text-sm font-medium text-muted-foreground mb-3">
            Llaves solicitadas ({selectedKeys.length}):
          </p>
          <div className="space-y-2">
            {selectedKeys.map((key) => (
              <div key={key.id} className="flex items-center gap-2 text-left">
                <Key className="w-4 h-4 text-primary flex-shrink-0" />
                <span className="font-medium truncate">{key.nombre}</span>
                <Badge variant="outline" className="text-xs">{key.tipo}</Badge>
                <span className="flex items-center gap-1 text-xs text-muted-foreground">
                  <Building2 className="w-3 h-3" />
                  {key.edificio}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Contador */}
        <div className="mb-4">
          <div className="w-12 h-12 mx-auto rounded-full border-4 border-success flex items-center justify-center">
            <span className="text-xl font-bold text-success">{contador}</span>
          </div>
          <p className="text-xs text-muted-foreground mt-1">Vuelve al inicio en {contador}s</p>
        </div>

        <div className="flex gap-3">
          <Button
            onClick={onCancelRequest}
            variant="destructive"
            className="flex-1 h-12 gap-2"
          >
            <XCircle className="w-5 h-5" />
            Cancelar Pedido
          </Button>
          <Button
            onClick={onNewRequest}
            variant="outline"
            className="flex-1 h-12"
          >
            Nueva Solicitud
          </Button>
        </div>
      </Card>
    </div>
  );
}