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
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { SolicitudLlave } from '@/types/solicitud';
import { Vigilante, tiposUsuario, buscarUsuarioPorCelular } from '@/data/fceaData';
import { ArrowRightLeft, User, Phone, UserCheck } from 'lucide-react';

interface KeyExchangeModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  solicitud: SolicitudLlave;
  vigilantes: Vigilante[];
  vigilantesAnteriores?: Vigilante[];
  onConfirmar: (vigilante: string, nuevoUsuario: { nombre: string; celular: string; tipo: string }) => void;
}

export function KeyExchangeModal({
  open,
  onOpenChange,
  solicitud,
  vigilantes,
  vigilantesAnteriores = [],
  onConfirmar
}: KeyExchangeModalProps) {
  const [nombre, setNombre] = useState('');
  const [celular, setCelular] = useState('');
  const [tipo, setTipo] = useState('Docente');
  const [vigilanteSeleccionado, setVigilanteSeleccionado] = useState('');

  const handleCelularChange = (value: string) => {
    setCelular(value);
    // Auto-completar si el usuario está registrado
    const usuario = buscarUsuarioPorCelular(value);
    if (usuario) {
      setNombre(usuario.nombre);
      setTipo(usuario.tipo);
    }
  };

  const handleConfirmar = () => {
    if (!nombre.trim() || !celular.trim() || !vigilanteSeleccionado) return;
    onConfirmar(vigilanteSeleccionado, { nombre: nombre.trim(), celular: celular.trim(), tipo });
    // Reset
    setNombre('');
    setCelular('');
    setTipo('Docente');
    setVigilanteSeleccionado('');
    onOpenChange(false);
  };

  const isValid = nombre.trim() && celular.trim() && vigilanteSeleccionado;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <ArrowRightLeft className="w-5 h-5" />
            Intercambio de Llave
          </DialogTitle>
          <DialogDescription>
            Transferir <strong>{solicitud.lugar.nombre}</strong> de {solicitud.usuario.nombre} a otro usuario
          </DialogDescription>
        </DialogHeader>

        <Alert>
          <UserCheck className="w-4 h-4" />
          <AlertDescription>
            La llave pasa directamente al nuevo usuario sin necesidad de devolverla al tablero.
          </AlertDescription>
        </Alert>

        <div className="space-y-4">
          <div>
            <Label htmlFor="celular-intercambio" className="flex items-center gap-1 mb-1">
              <Phone className="w-3.5 h-3.5" />
              Celular del nuevo usuario
            </Label>
            <Input
              id="celular-intercambio"
              value={celular}
              onChange={(e) => handleCelularChange(e.target.value)}
              placeholder="099123456"
            />
          </div>

          <div>
            <Label htmlFor="nombre-intercambio" className="flex items-center gap-1 mb-1">
              <User className="w-3.5 h-3.5" />
              Nombre del nuevo usuario
            </Label>
            <Input
              id="nombre-intercambio"
              value={nombre}
              onChange={(e) => setNombre(e.target.value)}
              placeholder="Nombre completo"
            />
          </div>

          <div>
            <Label className="mb-1 block">Tipo de usuario</Label>
            <Select value={tipo} onValueChange={setTipo}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {tiposUsuario.map(t => (
                  <SelectItem key={t} value={t}>{t}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div>
            <Label className="mb-2 block">Vigilante que registra el intercambio</Label>
            <div className="flex flex-wrap gap-2">
              {vigilantes.map(v => (
                <Button
                  key={v.id}
                  variant={vigilanteSeleccionado === v.nombre ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => setVigilanteSeleccionado(v.nombre)}
                >
                  {v.esJefe && <span className="w-2 h-2 rounded-full bg-primary-foreground mr-1" />}
                  {v.nombre}
                </Button>
              ))}
              {vigilantesAnteriores.length > 0 && (
                <>
                  <div className="w-px h-6 bg-border mx-1" />
                  {vigilantesAnteriores.map(v => (
                    <Button
                      key={v.id}
                      variant={vigilanteSeleccionado === v.nombre ? 'default' : 'ghost'}
                      size="sm"
                      className="text-muted-foreground"
                      onClick={() => setVigilanteSeleccionado(v.nombre)}
                    >
                      {v.nombre} <span className="text-xs ml-1">(ant.)</span>
                    </Button>
                  ))}
                </>
              )}
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancelar
          </Button>
          <Button onClick={handleConfirmar} disabled={!isValid} className="gap-2">
            <ArrowRightLeft className="w-4 h-4" />
            Confirmar Intercambio
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
