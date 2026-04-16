import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { WebcamCapture } from './WebcamCapture';
import { useToast } from '@/hooks/use-toast';
import { Package, MapPin, X } from 'lucide-react';

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
  const [sinFotos, setSinFotos] = useState(false);

  const isValid = descripcion.trim() && vigilante && (sinFotos || (fotoGeneral && fotoMarca));

  const handleRegistrar = () => {
    if (!isValid) return;
    
    // Si está marcado "sin fotos", usamos strings vacías para las fotos
    const fotosObj = sinFotos 
      ? { general: '', marca: '', adicional: undefined }
      : { general: fotoGeneral, marca: fotoMarca, adicional: fotoAdicional || undefined };
    
    onRegistrar({
      descripcion: descripcion.trim(),
      lugarEncontrado: lugar.trim() || undefined,
      registradoPor: vigilante,
      fotos: fotosObj,
    });
    
    toast({ 
      title: 'Objeto registrado', 
      description: `"${descripcion.trim()}" registrado correctamente${sinFotos ? ' (sin fotos)' : ''}` 
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
    setSinFotos(false);
  };

  const handleClose = () => {
    resetForm();
    onOpenChange(false);
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Overlay */}
      <div className="absolute inset-0 bg-black/50" onClick={handleClose} />
      
      {/* Modal */}
      <div className="relative z-10 bg-white rounded-lg shadow-xl w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b sticky top-0 bg-white z-10">
          <h2 className="text-lg font-semibold flex items-center gap-2">
            <Package className="w-5 h-5" />
            Registrar Objeto Olvidado
          </h2>
          <button onClick={handleClose} className="p-1 rounded hover:bg-gray-100">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="p-6 space-y-4">
          <div className="space-y-2">
            <Label htmlFor="descripcion">Descripción breve <span className="text-red-500">*</span></Label>
            <Input id="descripcion" placeholder="Ej: jarra térmica azul" value={descripcion} onChange={(e) => setDescripcion(e.target.value)} maxLength={80} />
            <p className="text-xs text-gray-500">{descripcion.length}/80 caracteres</p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="lugar" className="flex items-center gap-1">
              <MapPin className="w-3 h-3" />
              Lugar donde se encontró (opcional)
            </Label>
            <Input id="lugar" placeholder="Ej: Salón 101, Pasillo 2do piso" value={lugar} onChange={(e) => setLugar(e.target.value)} maxLength={60} />
          </div>

          <div className="space-y-2">
            <Label>Registrado por <span className="text-red-500">*</span></Label>
            <Select value={vigilante} onValueChange={setVigilante}>
              <SelectTrigger>
                <SelectValue placeholder="Seleccionar vigilante" />
              </SelectTrigger>
              <SelectContent>
                {vigilantes.map(v => <SelectItem key={v} value={v}>{v}</SelectItem>)}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-3 pt-2 border-t">
            <div className="flex items-center justify-between">
              <h4 className="font-medium text-sm">Fotografías del objeto</h4>
              <div className="flex items-center gap-3">
                <input 
                  type="checkbox" 
                  id="sinFotos" 
                  checked={sinFotos} 
                  onChange={(e) => setSinFotos(e.target.checked)} 
                  className="w-5 h-5 rounded border-gray-300 text-primary focus:ring-primary"
                />
                <Label htmlFor="sinFotos" className="text-base cursor-pointer">Registrar sin fotos</Label>
              </div>
            </div>
            
            {!sinFotos && (
              <>
                <WebcamCapture label="Foto general" required capturedImage={fotoGeneral} onCapture={setFotoGeneral} onClear={() => setFotoGeneral('')} />
                <WebcamCapture label="Foto de la marca" required capturedImage={fotoMarca} onCapture={setFotoMarca} onClear={() => setFotoMarca('')} />
                <WebcamCapture label="Foto adicional (característica)" capturedImage={fotoAdicional} onCapture={setFotoAdicional} onClear={() => setFotoAdicional('')} />
              </>
            )}
            
            {sinFotos && (
              <div className="bg-amber-50 border border-amber-200 rounded-lg p-3 text-sm text-amber-800">
                <p>Se registrará el objeto sin fotografías. Considere agregar una descripción detallada.</p>
              </div>
            )}
          </div>

          <div className="flex gap-2 pt-2">
            <Button className="flex-1" onClick={handleRegistrar} disabled={!isValid}>
              Registrar Objeto
            </Button>
            <Button variant="outline" onClick={handleClose}>
              Cancelar
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}