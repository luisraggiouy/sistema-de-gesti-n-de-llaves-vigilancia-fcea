import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { WebcamCapture } from './WebcamCapture';
import { useToast } from '@/hooks/use-toast';
import { Package, MapPin } from 'lucide-react';

interface RegistroObjetoModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  vigilantes: string[];
  onRegistrar: (objeto: {
    descripcion: string;
    lugarEncontrado?: string;
    registradoPor: string;
    fotos: { general: string; marca: string; adicional?: string };
  }) => void;
}

export function RegistroObjetoModal({ open, onOpenChange, vigilantes, onRegistrar }: RegistroObjetoModalProps) {
  const { toast } = useToast();
  const [descripcion, setDescripcion] = useState('');
  const [lugar, setLugar] = useState('');
  const [vigilante, setVigilante] = useState('');
  const [fotoGeneral, setFotoGeneral] = useState('');
  const [fotoMarca, setFotoMarca] = useState('');
  const [fotoAdicional, setFotoAdicional] = useState('');

  const isValid = descripcion.trim() && vigilante && fotoGeneral && fotoMarca;

  const handleRegistrar = () => {
    if (!isValid) return;
    onRegistrar({
      descripcion: descripcion.trim(),
      lugarEncontrado: lugar.trim() || undefined,
      registradoPor: vigilante,
      fotos: {
        general: fotoGeneral,
        marca: fotoMarca,
        adicional: fotoAdicional || undefined,
      },
    });
    toast({
      title: 'Objeto registrado',
      description: `"${descripcion.trim()}" registrado correctamente`,
    });
    resetForm();
    onOpenChange(false);
  };

  const resetForm = () => {
    setDescripcion('');
    setLugar('');
    setVigilante('');
    setFotoGeneral('');
    setFotoMarca('');
    setFotoAdicional('');
  };

  return (
    <Dialog open={open} onOpenChange={(v) => { if (!v) resetForm(); onOpenChange(v); }}>
      <DialogContent className="max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Package className="w-5 h-5" />
            Registrar Objeto Olvidado
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          {/* Descripción */}
          <div className="space-y-2">
            <Label htmlFor="descripcion">Descripción breve <span className="text-destructive">*</span></Label>
            <Input
              id="descripcion"
              placeholder="Ej: jarra térmica azul"
              value={descripcion}
              onChange={(e) => setDescripcion(e.target.value)}
              maxLength={80}
            />
            <p className="text-xs text-muted-foreground">{descripcion.length}/80 caracteres</p>
          </div>

          {/* Lugar */}
          <div className="space-y-2">
            <Label htmlFor="lugar" className="flex items-center gap-1">
              <MapPin className="w-3 h-3" />
              Lugar donde se encontró (opcional)
            </Label>
            <Input
              id="lugar"
              placeholder="Ej: Salón 101, Pasillo 2do piso"
              value={lugar}
              onChange={(e) => setLugar(e.target.value)}
              maxLength={60}
            />
          </div>

          {/* Vigilante */}
          <div className="space-y-2">
            <Label>Registrado por <span className="text-destructive">*</span></Label>
            <Select value={vigilante} onValueChange={setVigilante}>
              <SelectTrigger>
                <SelectValue placeholder="Seleccionar vigilante" />
              </SelectTrigger>
              <SelectContent>
                {vigilantes.map(v => (
                  <SelectItem key={v} value={v}>{v}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Fotos */}
          <div className="space-y-3 pt-2 border-t">
            <h4 className="font-medium text-sm">Fotografías del objeto</h4>
            <WebcamCapture
              label="Foto general"
              required
              capturedImage={fotoGeneral}
              onCapture={setFotoGeneral}
              onClear={() => setFotoGeneral('')}
            />
            <WebcamCapture
              label="Foto de la marca"
              required
              capturedImage={fotoMarca}
              onCapture={setFotoMarca}
              onClear={() => setFotoMarca('')}
            />
            <WebcamCapture
              label="Foto adicional (característica)"
              capturedImage={fotoAdicional}
              onCapture={setFotoAdicional}
              onClear={() => setFotoAdicional('')}
            />
          </div>

          <div className="flex gap-2 pt-2">
            <Button
              className="flex-1"
              onClick={handleRegistrar}
              disabled={!isValid}
            >
              Registrar Objeto
            </Button>
            <Button variant="outline" onClick={() => { resetForm(); onOpenChange(false); }}>
              Cancelar
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
