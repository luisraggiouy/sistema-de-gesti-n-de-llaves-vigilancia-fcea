import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { TipoUsuario, tiposUsuario, DepartamentoTAS, departamentosTAS, UsuarioRegistrado } from '@/data/fceaData';
import { useUsuariosRegistrados } from '@/hooks/useUsuariosRegistrados';
import { User, Phone, Mail, UserCog, UserPlus, CheckCircle, Building2, Building } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

interface RegistrationModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onRegistered: (usuario: UsuarioRegistrado) => void;
}

// Solo letras, espacios, acentos y caracteres especiales de nombres
const soloLetras = (valor: string) =>
  valor.replace(/[^a-zA-ZáéíóúÁÉÍÓÚüÜñÑàèìòùÀÈÌÒÙâêîôûÂÊÎÔÛ\s'-]/g, '');

// Validar email
const esEmailValido = (email: string) =>
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

// Validar celular uruguayo (acepta formatos: 09X XXX XXX, +598 9X XXX XXX, etc.)
// También acepta números extranjeros con código de país
const esCelularValido = (celular: string) => {
  const solo = celular.replace(/\D/g, '');
  // Uruguay: empieza con 09 (8 dígitos) o 598 9 (11 dígitos)
  if (/^09\d{7}$/.test(solo)) return true;
  if (/^5989\d{7}$/.test(solo)) return true;
  // Extranjero: entre 7 y 15 dígitos
  if (solo.length >= 7 && solo.length <= 15) return true;
  return false;
};

export function RegistrationModal({ open, onOpenChange, onRegistered }: RegistrationModalProps) {
  const { toast } = useToast();
  const { registrarUsuario, buscarPorCelular } = useUsuariosRegistrados();

  const [nombre, setNombre] = useState('');
  const [celular, setCelular] = useState('');
  const [email, setEmail] = useState('');
  const [tipoUsuario, setTipoUsuario] = useState<TipoUsuario | ''>('');
  const [departamento, setDepartamento] = useState<DepartamentoTAS | ''>('');
  const [departamentoOtro, setDepartamentoOtro] = useState('');
  const [nombreEmpresa, setNombreEmpresa] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const celularValido = !celular.trim() || esCelularValido(celular);
  const emailValido = !email.trim() || esEmailValido(email);
  const tieneContacto = celular.trim() || email.trim();
  const isFormValid = nombre.trim() && tieneContacto && tipoUsuario &&
    celularValido && emailValido &&
    (tipoUsuario !== 'Empresa' || nombreEmpresa.trim());

  const handleSubmit = async () => {
    if (!isFormValid || !tipoUsuario) return;

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
    try {
      // Si el departamento es "Otro", guardar el texto personalizado como nombre de empresa
      // para que se muestre en la agenda
      const depFinal = tipoUsuario === 'Personal TAS' && departamento ? departamento : undefined;
      const empresaFinal = tipoUsuario === 'Empresa' && nombreEmpresa.trim() 
        ? nombreEmpresa.trim() 
        : (departamento === 'Otro' && departamentoOtro.trim() ? departamentoOtro.trim() : undefined);

      const nuevoUsuario = await registrarUsuario({
        nombre: nombre.trim(),
        celular: celular.trim(),
        email: email.trim() || undefined,
        tipo: tipoUsuario,
        departamento: depFinal,
        nombreEmpresa: empresaFinal,
      });

      toast({
        title: "¡Registro exitoso!",
        description: "Ahora puede identificarse con su celular o email",
      });

      resetForm();
      if (nuevoUsuario) onRegistered(nuevoUsuario);
      onOpenChange(false);
    } catch (e) {
      toast({
        title: "Error al registrar",
        description: "Intente nuevamente",
        variant: "destructive"
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetForm = () => {
    setNombre('');
    setCelular('');
    setEmail('');
    setTipoUsuario('');
    setDepartamento('');
    setDepartamentoOtro('');
    setNombreEmpresa('');
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <UserPlus className="w-5 h-5 text-primary" />
            Registro de Usuario
          </DialogTitle>
          <DialogDescription>
            Complete sus datos una única vez. Luego podrá identificarse con su celular o email.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* Nombre */}
          <div className="space-y-2">
            <Label htmlFor="reg-nombre" className="flex items-center gap-2">
              <User className="w-4 h-4 text-muted-foreground" />
              Nombre completo *
            </Label>
            <Input
              id="reg-nombre"
              placeholder="Ingrese su nombre"
              value={nombre}
              onChange={(e) => setNombre(soloLetras(e.target.value))}
              className="h-11"
            />
          </div>

          {/* Celular */}
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
              className={`h-11 ${celular && !celularValido ? 'border-destructive' : ''}`}
            />
            {celular && !celularValido && (
              <p className="text-xs text-destructive">
                Ingrese un número válido (ej: 094 123 456 o +54 9 11 1234 5678)
              </p>
            )}
          </div>

          {/* Email */}
          <div className="space-y-2">
            <Label htmlFor="reg-email" className="flex items-center gap-2">
              <Mail className="w-4 h-4 text-muted-foreground" />
              Correo electrónico
            </Label>
            <Input
              id="reg-email"
              type="email"
              placeholder="usuario@ejemplo.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className={`h-11 ${email && !emailValido ? 'border-destructive' : ''}`}
            />
            {email && !emailValido && (
              <p className="text-xs text-destructive">Ingrese un email válido (ej: nombre@dominio.com)</p>
            )}
            <p className="text-xs text-muted-foreground">
              Puede ingresar celular, email o ambos para identificarse
            </p>
          </div>

          {/* Tipo */}
          <div className="space-y-2">
            <Label className="flex items-center gap-2">
              <UserCog className="w-4 h-4 text-muted-foreground" />
              Tipo de usuario *
            </Label>
            <Select value={tipoUsuario} onValueChange={(val) => {
              setTipoUsuario(val as TipoUsuario);
              if (val !== 'Personal TAS') setDepartamento('');
              if (val !== 'Empresa') setNombreEmpresa('');
            }}>
              <SelectTrigger className="h-11">
                <SelectValue placeholder="Seleccione tipo" />
              </SelectTrigger>
              <SelectContent>
                {tiposUsuario.map((tipo) => (
                  <SelectItem key={tipo} value={tipo} className="py-3">{tipo}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {tipoUsuario === 'Personal TAS' && (
            <>
              <div className="space-y-2">
                <Label className="flex items-center gap-2">
                  <Building2 className="w-4 h-4 text-muted-foreground" />
                  Departamento
                </Label>
                <Select value={departamento} onValueChange={(val) => {
                  setDepartamento(val as DepartamentoTAS);
                  if (val !== 'Otro') setDepartamentoOtro('');
                }}>
                  <SelectTrigger className="h-11">
                    <SelectValue placeholder="Seleccione departamento" />
                  </SelectTrigger>
                  <SelectContent className="max-h-60">
                    {departamentosTAS.map((dep) => (
                      <SelectItem key={dep} value={dep} className="py-2">{dep}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              {departamento === 'Otro' && (
                <div className="space-y-2">
                  <Label htmlFor="reg-depto-otro" className="flex items-center gap-2">
                    <Building2 className="w-4 h-4 text-muted-foreground" />
                    Especifique el departamento *
                  </Label>
                  <Input
                    id="reg-depto-otro"
                    placeholder="Escriba el nombre del departamento"
                    value={departamentoOtro}
                    onChange={(e) => setDepartamentoOtro(e.target.value)}
                    className="h-11"
                  />
                </div>
              )}
            </>
          )}

          {tipoUsuario === 'Empresa' && (
            <div className="space-y-2">
              <Label htmlFor="reg-empresa" className="flex items-center gap-2">
                <Building className="w-4 h-4 text-muted-foreground" />
                Nombre de la empresa *
              </Label>
              <Input
                id="reg-empresa"
                placeholder="Ingrese el nombre de la empresa"
                value={nombreEmpresa}
                onChange={(e) => setNombreEmpresa(e.target.value)}
                className="h-11"
              />
            </div>
          )}
        </div>

        <div className="flex gap-3 justify-end">
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={isSubmitting}>
            Cancelar
          </Button>
          <Button onClick={handleSubmit} disabled={!isFormValid || isSubmitting} className="gap-2">
            {isSubmitting ? <>Registrando...</> : <><CheckCircle className="w-4 h-4" />Registrarse</>}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}