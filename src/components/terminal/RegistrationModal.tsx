import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { TipoUsuario, tiposUsuario, UsuarioRegistrado } from '@/data/fceaData';
import { useUsuariosRegistrados } from '@/hooks/useUsuariosRegistrados';
import { User, Phone, Mail, UserCog, UserPlus, CheckCircle } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

interface RegistrationModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onRegistered: (usuario: UsuarioRegistrado) => void;
}

export function RegistrationModal({ open, onOpenChange, onRegistered }: RegistrationModalProps) {
  const { toast } = useToast();
  const { registrarUsuario, buscarPorCelular } = useUsuariosRegistrados();
  
  const [nombre, setNombre] = useState('');
  const [celular, setCelular] = useState('');
  const [email, setEmail] = useState('');
  const [tipoUsuario, setTipoUsuario] = useState<TipoUsuario | ''>('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Validación: nombre, tipo, Y (celular O email)
  const tieneContacto = celular.trim() || email.trim();
  const isFormValid = nombre.trim() && tieneContacto && tipoUsuario;

  const handleSubmit = async () => {
    if (!isFormValid || !tipoUsuario) return;
    
    // Verificar si el celular ya está registrado
    if (celular.trim()) {
      const existente = buscarPorCelular(celular);
      if (existente) {
        toast({
          title: "Usuario ya registrado",
          description: `El celular ${celular} ya está asociado a ${existente.nombre}`,
          variant: "destructive"
        });
        return;
      }
    }
    
    setIsSubmitting(true);
    
    // Simular delay de registro
    await new Promise(resolve => setTimeout(resolve, 800));
    
    const nuevoUsuario = registrarUsuario({
      nombre: nombre.trim(),
      celular: celular.trim(),
      email: email.trim() || undefined,
      tipo: tipoUsuario
    });
    
    toast({
      title: "¡Registro exitoso!",
      description: "Ahora puede solicitar llaves usando su celular",
    });
    
    setIsSubmitting(false);
    resetForm();
    onRegistered(nuevoUsuario);
    onOpenChange(false);
  };

  const resetForm = () => {
    setNombre('');
    setCelular('');
    setEmail('');
    setTipoUsuario('');
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <UserPlus className="w-5 h-5 text-primary" />
            Registro de Usuario
          </DialogTitle>
          <DialogDescription>
            Complete sus datos una única vez. Luego podrá identificarse solo con su celular.
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-4 py-4">
          <div className="space-y-2">
            <Label htmlFor="reg-nombre" className="flex items-center gap-2">
              <User className="w-4 h-4 text-muted-foreground" />
              Nombre completo *
            </Label>
            <Input
              id="reg-nombre"
              placeholder="Ingrese su nombre"
              value={nombre}
              onChange={(e) => setNombre(e.target.value)}
              className="h-11"
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="reg-celular" className="flex items-center gap-2">
              <Phone className="w-4 h-4 text-muted-foreground" />
              Número de celular
            </Label>
            <Input
              id="reg-celular"
              type="tel"
              placeholder="094 123 456"
              value={celular}
              onChange={(e) => setCelular(e.target.value)}
              className="h-11"
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="reg-email" className="flex items-center gap-2">
              <Mail className="w-4 h-4 text-muted-foreground" />
              Correo electrónico
              <span className="text-xs text-muted-foreground font-normal">(opcional)</span>
            </Label>
            <Input
              id="reg-email"
              type="email"
              placeholder="usuario@ejemplo.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="h-11"
            />
            <p className="text-xs text-muted-foreground">
              Puede ingresar celular, email o ambos
            </p>
          </div>
          
          <div className="space-y-2">
            <Label className="flex items-center gap-2">
              <UserCog className="w-4 h-4 text-muted-foreground" />
              Tipo de usuario *
            </Label>
            <Select value={tipoUsuario} onValueChange={(val) => setTipoUsuario(val as TipoUsuario)}>
              <SelectTrigger className="h-11">
                <SelectValue placeholder="Seleccione tipo" />
              </SelectTrigger>
              <SelectContent>
                {tiposUsuario.map((tipo) => (
                  <SelectItem key={tipo} value={tipo} className="py-3">
                    {tipo}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>
        
        <div className="flex gap-3 justify-end">
          <Button 
            variant="outline" 
            onClick={() => onOpenChange(false)}
            disabled={isSubmitting}
          >
            Cancelar
          </Button>
          <Button 
            onClick={handleSubmit}
            disabled={!isFormValid || isSubmitting}
            className="gap-2"
          >
            {isSubmitting ? (
              <>Registrando...</>
            ) : (
              <>
                <CheckCircle className="w-4 h-4" />
                Registrarse
              </>
            )}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
