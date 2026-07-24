import { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { TipoUsuario, tiposUsuario, DepartamentoTAS, UsuarioRegistrado } from '@/data/fceaData';
import { useUsuariosRegistrados } from '@/hooks/useUsuariosRegistrados';
import { useDepartamentosCustom } from '@/hooks/useDepartamentosCustom';
import { User, Phone, Mail, UserCog, UserPlus, CheckCircle, Building2, Building } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { registrarError } from '@/lib/errorLog';

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

/**
 * Validacion estricta de celular:
 *  - Uruguay: exactamente 9 digitos empezando con 09 (ej: 099123456).
 *  - Uruguay con codigo pais: 5989 + 7 digitos (11 en total).
 *  - Extranjero: DEBE empezar con "+" y tener entre 7 y 15 digitos.
 */
const esCelularValido = (celular: string) => {
  const trimmed = celular.trim();
  if (!trimmed) return false;
  const solo = trimmed.replace(/\D/g, '');
  if (/^09\d{7}$/.test(solo)) return true;
  if (/^5989\d{7}$/.test(solo)) return true;
  if (trimmed.startsWith('+') && solo.length >= 7 && solo.length <= 15) return true;
  return false;
};

/**
 * Modal de registro de usuario.
 *
 * v2.9 (2026-07-23) — Rediseño mouse+teclado.
 *   Se eliminaron todos los elementos específicos del monitor táctil resistivo:
 *   TouchInput con teclado virtual on-screen, botones flotantes de scroll,
 *   modal fullscreen en modo táctil, grilla gigante de departamentos y de
 *   unidades académicas Docente. Ahora usa <Input> HTML nativos y <Select>
 *   de shadcn, que funcionan con teclado físico, mouse y también con dedo
 *   si en el futuro se instala un monitor capacitivo (Windows abrirá TabTip
 *   automáticamente si no hay teclado físico conectado).
 */
export function RegistrationModal({ open, onOpenChange, onRegistered }: RegistrationModalProps) {
  const { toast } = useToast();
  const { registrarUsuario, buscarPorCelular } = useUsuariosRegistrados();
  // Catálogo de departamentos con persistencia en localStorage.
  const { departamentos: departamentosLista, agregar: agregarDepartamento } = useDepartamentosCustom();

  const [nombre, setNombre] = useState('');
  const [celular, setCelular] = useState('');
  const [email, setEmail] = useState('');
  const [tipoUsuario, setTipoUsuario] = useState<TipoUsuario | ''>('');
  const [departamento, setDepartamento] = useState<DepartamentoTAS | ''>('');
  const [departamentoOtro, setDepartamentoOtro] = useState('');
  const [nombreEmpresa, setNombreEmpresa] = useState('');
  // v2.6 (P9): subcategoría para tipoUsuario === 'Docente'.
  //   IESTA  : Instituto de Estadística
  //   IECON  : Instituto de Economía
  //   Otro   : otra unidad (con campo de texto libre)
  // El valor se persiste en el campo `departamento` del usuario.
  const [subcatDocente, setSubcatDocente] = useState<'IESTA' | 'IECON' | 'Otro' | ''>('');
  const [subcatDocenteOtro, setSubcatDocenteOtro] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const celularValido = !celular.trim() || esCelularValido(celular);
  const emailValido = !email.trim() || esEmailValido(email);
  const tieneContacto = celular.trim() || email.trim();
  const isFormValid = nombre.trim() && tieneContacto && tipoUsuario &&
    celularValido && emailValido &&
    (tipoUsuario !== 'Empresa' || nombreEmpresa.trim()) &&
    (tipoUsuario !== 'Docente' || (
      !!subcatDocente && (subcatDocente !== 'Otro' || !!subcatDocenteOtro.trim())
    ));

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
      let depFinal: string | undefined = undefined;
      if (tipoUsuario === 'Personal TAS') {
        if (departamento === 'Otro' && departamentoOtro.trim()) {
          const persistido = agregarDepartamento(departamentoOtro);
          depFinal = persistido || departamentoOtro.trim();
        } else if (departamento) {
          depFinal = departamento;
        }
      } else if (tipoUsuario === 'Docente') {
        if (subcatDocente === 'Otro' && subcatDocenteOtro.trim()) {
          depFinal = subcatDocenteOtro.trim();
        } else if (subcatDocente) {
          depFinal = subcatDocente;
        }
      }
      const empresaFinal = tipoUsuario === 'Empresa' && nombreEmpresa.trim()
        ? nombreEmpresa.trim()
        : undefined;

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
      registrarError('registrarUsuario', e);
      const anyE = e as { status?: number; message?: string; data?: { data?: Record<string, { message?: string }> } };
      const partes: string[] = [];
      if (typeof anyE?.status === 'number') partes.push(`HTTP ${anyE.status}`);
      if (anyE?.message) partes.push(anyE.message);
      const camposErr = anyE?.data?.data;
      if (camposErr && typeof camposErr === 'object') {
        Object.entries(camposErr).forEach(([campo, val]) => {
          if (val?.message) partes.push(`${campo}: ${val.message}`);
        });
      }
      const detalle = partes.length ? partes.join(' — ') : 'Error desconocido. Abra diagnóstico con Ctrl+Shift+D.';
      toast({
        title: 'Error al registrar',
        description: detalle,
        variant: 'destructive',
        duration: 10000,
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
    setSubcatDocente('');
    setSubcatDocenteOtro('');
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="w-[80vw] max-w-[80vw] max-h-[80vh] overflow-y-auto">
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
              autoComplete="off"
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
              inputMode="tel"
              placeholder="094 123 456"
              value={celular}
              onChange={(e) => setCelular(e.target.value)}
              className={`h-11 ${celular && !celularValido ? 'border-destructive' : ''}`}
              autoComplete="off"
            />
            {celular && !celularValido && (
              <p className="text-xs text-destructive">
                Debe ser un celular uruguayo con 9 dígitos que empiece con 09
                (ej: 099 123 456), o un número extranjero con prefijo + (ej:
                +54 9 11 1234 5678).
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
              inputMode="email"
              placeholder="usuario@ejemplo.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className={`h-11 ${email && !emailValido ? 'border-destructive' : ''}`}
              autoComplete="off"
            />
            {email && !emailValido && (
              <p className="text-xs text-destructive">Ingrese un email válido (ej: nombre@dominio.com)</p>
            )}
            <p className="text-xs text-muted-foreground">
              Puede ingresar celular, email o ambos para identificarse
            </p>
          </div>

          {/* Tipo de usuario */}
          <div className="space-y-2">
            <Label className="flex items-center gap-2">
              <UserCog className="w-4 h-4 text-muted-foreground" />
              Tipo de usuario *
            </Label>
            <Select value={tipoUsuario} onValueChange={(val) => {
              setTipoUsuario(val as TipoUsuario);
              if (val !== 'Personal TAS') setDepartamento('');
              if (val !== 'Empresa') setNombreEmpresa('');
              if (val !== 'Docente') { setSubcatDocente(''); setSubcatDocenteOtro(''); }
            }}>
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

          {/* Departamento (solo Personal TAS) */}
          {tipoUsuario === 'Personal TAS' && (
            <>
              <div className="space-y-2">
                <Label className="flex items-center gap-2">
                  <Building2 className="w-4 h-4 text-muted-foreground" />
                  Departamento o sección
                </Label>
                <Select
                  value={departamento}
                  onValueChange={(val) => {
                    setDepartamento(val as DepartamentoTAS);
                    if (val !== 'Otro') setDepartamentoOtro('');
                  }}
                >
                  <SelectTrigger className="h-11">
                    <SelectValue placeholder="Seleccione departamento o sección" />
                  </SelectTrigger>
                  <SelectContent className="max-h-60">
                    {departamentosLista.map((dep) => (
                      <SelectItem key={dep} value={dep} className="py-2">
                        {dep}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {departamento === 'Otro' && (
                <div className="space-y-2">
                  <Label htmlFor="reg-depto-otro" className="flex items-center gap-2">
                    <Building2 className="w-4 h-4 text-muted-foreground" />
                    Especifique el departamento o sección *
                  </Label>
                  <Input
                    id="reg-depto-otro"
                    placeholder="Escriba el nombre del departamento o sección"
                    value={departamentoOtro}
                    onChange={(e) => setDepartamentoOtro(e.target.value)}
                    className="h-11"
                    autoComplete="off"
                  />
                </div>
              )}
            </>
          )}

          {/* Empresa */}
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
                autoComplete="off"
              />
            </div>
          )}

          {/* Subcategoría Docente (IESTA / IECON / Otro) */}
          {tipoUsuario === 'Docente' && (
            <>
              <div className="space-y-2">
                <Label className="flex items-center gap-2">
                  <Building2 className="w-4 h-4 text-muted-foreground" />
                  Unidad académica *
                </Label>
                <Select
                  value={subcatDocente}
                  onValueChange={(val) => {
                    setSubcatDocente(val as 'IESTA' | 'IECON' | 'Otro');
                    if (val !== 'Otro') setSubcatDocenteOtro('');
                  }}
                >
                  <SelectTrigger className="h-11">
                    <SelectValue placeholder="Seleccione unidad académica" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="IESTA" className="py-2">IESTA — Instituto de Estadística</SelectItem>
                    <SelectItem value="IECON" className="py-2">IECON — Instituto de Economía</SelectItem>
                    <SelectItem value="Otro" className="py-2">Otro</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {subcatDocente === 'Otro' && (
                <div className="space-y-2">
                  <Label htmlFor="reg-docente-otro" className="flex items-center gap-2">
                    <Building2 className="w-4 h-4 text-muted-foreground" />
                    Especifique la unidad académica *
                  </Label>
                  <Input
                    id="reg-docente-otro"
                    placeholder="Ej: Instituto de Historia Económica"
                    value={subcatDocenteOtro}
                    onChange={(e) => setSubcatDocenteOtro(e.target.value)}
                    className="h-11"
                    autoComplete="off"
                  />
                </div>
              )}
            </>
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
