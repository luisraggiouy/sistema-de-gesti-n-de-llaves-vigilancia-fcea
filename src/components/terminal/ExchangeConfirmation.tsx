import { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { AlertTriangle, ArrowRightLeft, Key, User, ShieldAlert } from 'lucide-react';
import { Lugar } from '@/data/fceaData';

interface ExchangeConfirmationProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  lugar: Lugar;
  usuarioActual: { nombre: string; celular: string; tipo: string };
  usuarioConLlave: { nombre: string };
  onConfirmar: () => void;
}

export function ExchangeConfirmation({
  open,
  onOpenChange,
  lugar,
  usuarioActual,
  usuarioConLlave,
  onConfirmar,
}: ExchangeConfirmationProps) {
  const [accepted, setAccepted] = useState(false);

  const handleConfirm = () => {
    onConfirmar();
    setAccepted(false);
    onOpenChange(false);
  };

  const handleClose = (val: boolean) => {
    if (!val) setAccepted(false);
    onOpenChange(val);
  };

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <ArrowRightLeft className="w-5 h-5 text-primary" />
            Intercambiar Llave
          </DialogTitle>
          <DialogDescription>
            Solicitar el intercambio de una llave que está actualmente en uso
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* Info de la llave */}
          <div className="flex items-center gap-3 p-3 bg-muted/50 rounded-lg">
            <Key className="w-5 h-5 text-primary" />
            <div>
              <p className="font-semibold">{lugar.nombre}</p>
              <p className="text-sm text-muted-foreground">{lugar.tipo} • {lugar.edificio}</p>
            </div>
          </div>

          {/* Quién la tiene */}
          <div className="flex items-center gap-3 p-3 bg-muted/50 rounded-lg">
            <User className="w-5 h-5 text-muted-foreground" />
            <div>
              <p className="text-sm text-muted-foreground">Actualmente en poder de:</p>
              <p className="font-medium">{usuarioConLlave.nombre}</p>
            </div>
          </div>

          {/* Flecha de intercambio */}
          <div className="flex items-center justify-center gap-3 text-sm text-muted-foreground">
            <span>{usuarioConLlave.nombre}</span>
            <ArrowRightLeft className="w-4 h-4 text-primary" />
            <span className="font-medium text-foreground">{usuarioActual.nombre}</span>
          </div>

          {/* Banner de advertencia */}
          <div className="flex items-start gap-3 p-4 bg-warning/10 border border-warning/30 rounded-lg">
            <ShieldAlert className="w-6 h-6 text-warning flex-shrink-0 mt-0.5" />
            <div className="space-y-1">
              <p className="font-semibold text-warning">Aviso de responsabilidad</p>
              <p className="text-sm text-muted-foreground">
                Al confirmar el intercambio, <strong className="text-foreground">{usuarioActual.nombre}</strong> pasa a ser 
                responsable de la llave <strong className="text-foreground">{lugar.nombre}</strong>. 
                Usted debe solicitar la llave directamente al docente saliente.
              </p>
            </div>
          </div>

          {/* Checkbox de aceptación */}
          <label className="flex items-start gap-3 cursor-pointer select-none">
            <input
              type="checkbox"
              checked={accepted}
              onChange={(e) => setAccepted(e.target.checked)}
              className="mt-1 h-4 w-4 rounded border-input accent-primary"
            />
            <span className="text-sm">
              Entiendo que la llave pasa a ser mi responsabilidad y me comprometo a devolverla al finalizar su uso.
            </span>
          </label>
        </div>

        <DialogFooter className="gap-2 sm:gap-0">
          <Button variant="outline" onClick={() => handleClose(false)}>
            Cancelar
          </Button>
          <Button
            onClick={handleConfirm}
            disabled={!accepted}
            className="gap-2"
          >
            <ArrowRightLeft className="w-4 h-4" />
            Confirmar Intercambio
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
