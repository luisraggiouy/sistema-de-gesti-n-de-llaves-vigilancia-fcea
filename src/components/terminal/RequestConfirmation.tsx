import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Lugar, TipoUsuario } from '@/data/fceaData';
import { Key, User, Phone, Building2, AlertTriangle, Send, Loader2, X } from 'lucide-react';

interface RequestConfirmationProps {
  selectedKeys: Lugar[];
  nombre: string;
  celular: string;
  tipoUsuario: TipoUsuario;
  isSubmitting: boolean;
  onSubmit: () => void;
  onCancel: () => void;
  onRemoveKey: (lugarId: string) => void;
}

export function RequestConfirmation({
  selectedKeys,
  nombre,
  celular,
  tipoUsuario,
  isSubmitting,
  onSubmit,
  onCancel,
  onRemoveKey
}: RequestConfirmationProps) {
  const hasHybridKey = selectedKeys.some(k => k.esHibrido);

  return (
    <Card className="p-6 border-primary/20 bg-gradient-to-br from-card to-primary/5">
      <div className="space-y-4">
        <div className="flex items-center gap-3">
          <div className="bg-primary/10 p-2 rounded-lg">
            <Key className="w-6 h-6 text-primary" />
          </div>
          <div>
            <h3 className="font-semibold text-lg">Confirmar Solicitud</h3>
            <p className="text-sm text-muted-foreground">
              {selectedKeys.length} llave(s) seleccionada(s)
            </p>
          </div>
        </div>
        
        <div className="space-y-3 py-3 border-y border-border">
          {/* Datos del usuario */}
          <div className="flex items-center gap-3">
            <User className="w-5 h-5 text-muted-foreground" />
            <div>
              <p className="font-medium">{nombre}</p>
              <p className="text-sm text-muted-foreground">{tipoUsuario}</p>
            </div>
          </div>
          
          <div className="flex items-center gap-3">
            <Phone className="w-5 h-5 text-muted-foreground" />
            <p>{celular}</p>
          </div>
          
          {/* Lista de llaves seleccionadas */}
          <div className="mt-4 pt-3 border-t border-border">
            <p className="text-sm font-medium text-muted-foreground mb-2">Llaves a solicitar:</p>
            <div className="space-y-2">
              {selectedKeys.map((key) => (
                <div
                  key={key.id}
                  className="flex items-center justify-between gap-2 p-2 bg-muted/50 rounded-lg"
                >
                  <div className="flex items-center gap-2 min-w-0">
                    <Key className="w-4 h-4 text-primary flex-shrink-0" />
                    <span className="font-medium truncate">{key.nombre}</span>
                    <Badge variant="outline" className="text-xs">{key.tipo}</Badge>
                    <span className="flex items-center gap-1 text-xs text-muted-foreground">
                      <Building2 className="w-3 h-3" />
                      {key.edificio}
                    </span>
                    {key.esHibrido && (
                      <Badge variant="destructive" className="text-xs">Híbrido</Badge>
                    )}
                  </div>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-6 w-6 flex-shrink-0 text-muted-foreground hover:text-destructive"
                    onClick={() => onRemoveKey(key.id)}
                    disabled={isSubmitting}
                  >
                    <X className="w-4 h-4" />
                  </Button>
                </div>
              ))}
            </div>
          </div>
        </div>
        
        {hasHybridKey && (
          <div className="flex items-start gap-2 text-sm bg-warning/10 text-warning-foreground rounded-lg p-3">
            <AlertTriangle className="w-5 h-5 text-warning flex-shrink-0 mt-0.5" />
            <div>
              <p className="font-medium">Salón(es) Híbrido(s) - Alta Seguridad</p>
              <p className="text-muted-foreground">Estos salones deben permanecer cerrados cuando no haya clase.</p>
            </div>
          </div>
        )}
        
        <div className="flex gap-3 pt-2">
          <Button
            variant="outline"
            className="flex-1 h-12"
            onClick={onCancel}
            disabled={isSubmitting}
          >
            Cancelar
          </Button>
          <Button
            className="flex-1 h-12 gap-2"
            onClick={onSubmit}
            disabled={isSubmitting}
          >
            {isSubmitting ? (
              <>
                <Loader2 className="w-5 h-5 animate-spin" />
                Enviando...
              </>
            ) : (
              <>
                <Send className="w-5 h-5" />
                Solicitar {selectedKeys.length} Llave(s)
              </>
            )}
          </Button>
        </div>
      </div>
    </Card>
  );
}
