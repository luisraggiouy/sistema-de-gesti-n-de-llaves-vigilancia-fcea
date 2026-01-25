import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { TipoUsuario, tiposUsuario } from '@/data/fceaData';
import { User, Phone, UserCog, Mail } from 'lucide-react';

interface UserDataFormProps {
  nombre: string;
  celular: string;
  email: string;
  tipoUsuario: TipoUsuario | '';
  onNombreChange: (value: string) => void;
  onCelularChange: (value: string) => void;
  onEmailChange: (value: string) => void;
  onTipoChange: (value: TipoUsuario) => void;
}

export function UserDataForm({
  nombre,
  celular,
  email,
  tipoUsuario,
  onNombreChange,
  onCelularChange,
  onEmailChange,
  onTipoChange
}: UserDataFormProps) {
  return (
    <div className="space-y-5">
      <h2 className="text-lg font-semibold text-foreground flex items-center gap-2">
        <UserCog className="w-5 h-5 text-primary" />
        Datos del Usuario
      </h2>
      
      <div className="grid gap-4">
        <div className="space-y-2">
          <Label htmlFor="nombre" className="flex items-center gap-2">
            <User className="w-4 h-4 text-muted-foreground" />
            Nombre completo
          </Label>
          <Input
            id="nombre"
            placeholder="Ingrese su nombre"
            value={nombre}
            onChange={(e) => onNombreChange(e.target.value)}
            className="h-12 text-lg"
          />
        </div>
        
        <div className="space-y-2">
          <Label htmlFor="celular" className="flex items-center gap-2">
            <Phone className="w-4 h-4 text-muted-foreground" />
            Número de celular
          </Label>
          <Input
            id="celular"
            type="tel"
            placeholder="094 123 456"
            value={celular}
            onChange={(e) => onCelularChange(e.target.value)}
            className="h-12 text-lg"
          />
        </div>
        
        <div className="space-y-2">
          <Label htmlFor="email" className="flex items-center gap-2">
            <Mail className="w-4 h-4 text-muted-foreground" />
            Correo electrónico
            <span className="text-xs text-muted-foreground font-normal">(opcional)</span>
          </Label>
          <Input
            id="email"
            type="email"
            placeholder="usuario@ejemplo.com"
            value={email}
            onChange={(e) => onEmailChange(e.target.value)}
            className="h-12 text-lg"
          />
          <p className="text-xs text-muted-foreground">
            Puede ingresar celular, email o ambos
          </p>
        </div>
        
        <div className="space-y-2">
          <Label className="flex items-center gap-2">
            <UserCog className="w-4 h-4 text-muted-foreground" />
            Tipo de usuario
          </Label>
          <Select value={tipoUsuario} onValueChange={(val) => onTipoChange(val as TipoUsuario)}>
            <SelectTrigger className="h-12 text-lg">
              <SelectValue placeholder="Seleccione tipo" />
            </SelectTrigger>
            <SelectContent>
              {tiposUsuario.map((tipo) => (
                <SelectItem key={tipo} value={tipo} className="text-base py-3">
                  {tipo}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>
    </div>
  );
}
