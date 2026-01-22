import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Lugar, TipoUsuario, formatearUbicacion } from '@/data/fceaData';
import { Key, User, Phone, Building2, MapPin, AlertTriangle, Send, Loader2 } from 'lucide-react';

interface RequestConfirmationProps {
  selectedKey: Lugar;
  nombre: string;
  celular: string;
  tipoUsuario: TipoUsuario;
  isSubmitting: boolean;
  onSubmit: () => void;
  onCancel: () => void;
}

export function RequestConfirmation({
  selectedKey,
  nombre,
  celular,
  tipoUsuario,
  isSubmitting,
  onSubmit,
  onCancel
}: RequestConfirmationProps) {
  return (
    <Card className="p-6 border-primary/20 bg-gradient-to-br from-card to-primary/5">
      <div className="space-y-4">
        <div className="flex items-center gap-3">
          <div className="bg-primary/10 p-2 rounded-lg">
            <Key className="w-6 h-6 text-primary" />
          </div>
          <div>
            <h3 className="font-semibold text-lg">Confirmar Solicitud</h3>
            <p className="text-sm text-muted-foreground">Verifique los datos antes de enviar</p>
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
          
          {/* Datos de la llave */}
          <div className="mt-4 pt-3 border-t border-border">
            <div className="flex items-center gap-3 mb-2">
              <Key className="w-5 h-5 text-primary" />
              <p className="font-semibold text-lg text-primary">{selectedKey.nombre}</p>
            </div>
            
            <div className="grid grid-cols-2 gap-2 text-sm">
              <div className="flex items-center gap-2">
                <Badge variant="outline">{selectedKey.tipo}</Badge>
              </div>
              <div className="flex items-center gap-2 text-muted-foreground">
                <Building2 className="w-4 h-4" />
                {selectedKey.edificio}
              </div>
              <div className="flex items-center gap-2 text-muted-foreground col-span-2">
                <MapPin className="w-4 h-4" />
                {formatearUbicacion(selectedKey.ubicacion)}
              </div>
            </div>
          </div>
        </div>
        
        {selectedKey.esHibrido && (
          <div className="flex items-start gap-2 text-sm bg-warning/10 text-warning-foreground rounded-lg p-3">
            <AlertTriangle className="w-5 h-5 text-warning flex-shrink-0 mt-0.5" />
            <div>
              <p className="font-medium">Salón Híbrido - Alta Seguridad</p>
              <p className="text-muted-foreground">Este salón debe permanecer cerrado cuando no haya clase.</p>
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
                Solicitar Llave
              </>
            )}
          </Button>
        </div>
      </div>
    </Card>
  );
}
