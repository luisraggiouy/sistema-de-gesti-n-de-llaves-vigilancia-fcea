import { useState } from 'react';
import { Card } from '@/components/ui/card';
import { TerminalHeader } from '@/components/terminal/TerminalHeader';
import { UserSearchInput } from '@/components/terminal/UserSearchInput';
import { KeySearch } from '@/components/terminal/KeySearch';
import { FrequentKeys } from '@/components/terminal/FrequentKeys';
import { RequestConfirmation } from '@/components/terminal/RequestConfirmation';
import { RequestSuccess } from '@/components/terminal/RequestSuccess';
import { RegistrationModal } from '@/components/terminal/RegistrationModal';
import { ExchangeConfirmation } from '@/components/terminal/ExchangeConfirmation';
import { Lugar, UsuarioRegistrado } from '@/data/fceaData';
import { useHistorialLlaves } from '@/hooks/useHistorialLlaves';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';
import { useToast } from '@/hooks/use-toast';

type TerminalStep = 'main' | 'success';

export default function TerminalUsuario() {
  const { toast } = useToast();
  const { agregarSolicitudes, intercambiarPorLugar } = useSolicitudesContext();
  const [step, setStep] = useState<TerminalStep>('main');
  
  // Usuario identificado
  const [currentUser, setCurrentUser] = useState<UsuarioRegistrado | null>(null);
  
  // Llaves seleccionadas (múltiples)
  const [selectedKeys, setSelectedKeys] = useState<Lugar[]>([]);
  
  // Modal de registro
  const [showRegistration, setShowRegistration] = useState(false);
  
  // Exchange state
  const [exchangeTarget, setExchangeTarget] = useState<{ lugar: Lugar; usuario: { nombre: string; celular: string; tipo: string } } | null>(null);
  
  // Estado de envío
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Hook de historial de llaves frecuentes
  const { llavesFrecuentes, registrarUso } = useHistorialLlaves(currentUser?.id ?? null);

  // Validación: usuario identificado Y al menos una llave seleccionada
  const isFormValid = currentUser && selectedKeys.length > 0;

  const handleToggleKey = (lugar: Lugar) => {
    setSelectedKeys(prev => {
      const isSelected = prev.some(k => k.id === lugar.id);
      if (isSelected) {
        return prev.filter(k => k.id !== lugar.id);
      } else {
        return [...prev, lugar];
      }
    });
  };

  const handleRemoveKey = (lugarId: string) => {
    setSelectedKeys(prev => prev.filter(k => k.id !== lugarId));
  };

  // Verificar restricción horaria
  const verificarHorario = (): boolean => {
    if (!currentUser) return false;
    const hora = new Date().getHours();
    const fueraDeHorario = hora < 7 || hora >= 23;
    if (!fueraDeHorario) return true;
    
    // Tipos exentos de la restricción
    const tiposExentos = ['Personal TAS'];
    const departamentosExentos = ['Servicios Generales'];
    
    if (currentUser.tipo === 'Personal TAS' && currentUser.departamento && departamentosExentos.includes(currentUser.departamento)) {
      return true;
    }
    // Vigilancia no solicita llaves por terminal, pero por si acaso
    return false;
  };

  const esHorarioRestringido = (): boolean => {
    const hora = new Date().getHours();
    return hora < 7 || hora >= 23;
  };

  const usuarioExentoHorario = (): boolean => {
    if (!currentUser) return false;
    if (currentUser.tipo === 'Personal TAS' && currentUser.departamento === 'Servicios Generales') return true;
    return false;
  };

  const handleSubmit = async () => {
    if (!isFormValid || selectedKeys.length === 0 || !currentUser) return;
    
    // Verificar restricción horaria
    if (esHorarioRestringido() && !usuarioExentoHorario()) {
      toast({
        title: "Horario no permitido",
        description: "Por orden del Decano, no se permite la entrega de llaves antes de las 7:00 AM ni después de las 23:00 PM para su tipo de usuario.",
        variant: "destructive",
      });
      return;
    }
    
    setIsSubmitting(true);
    
    // Registrar en historial de llaves frecuentes
    selectedKeys.forEach(key => registrarUso(key.id));
    
    // Agregar solicitudes al contexto compartido (aparecerán en el monitor)
    agregarSolicitudes(selectedKeys, {
      nombre: currentUser.nombre,
      celular: currentUser.celular,
      tipo: currentUser.tipo
    });
    
    // Pequeño delay para feedback visual
    await new Promise(resolve => setTimeout(resolve, 500));
    
    toast({
      title: "Solicitud enviada",
      description: `${selectedKeys.length} llave(s) solicitada(s). Diríjase al mostrador de vigilancia`,
    });
    
    setIsSubmitting(false);
    setStep('success');
  };

  const handleNewRequest = () => {
    setCurrentUser(null);
    setSelectedKeys([]);
    setStep('main');
  };

  const handleCancelRequest = () => {
    toast({
      title: "Pedido cancelado",
      description: "Su solicitud ha sido cancelada",
      variant: "destructive",
    });
    setCurrentUser(null);
    setSelectedKeys([]);
    setStep('main');
  };

  const handleCancelConfirmation = () => {
    setSelectedKeys([]);
  };

  const handleExchangeRequest = (lugar: Lugar, usuarioConLlave: { nombre: string; celular: string; tipo: string }) => {
    if (!currentUser) {
      toast({
        title: "Identifíquese primero",
        description: "Debe identificarse antes de solicitar un intercambio",
        variant: "destructive",
      });
      return;
    }
    setExchangeTarget({ lugar, usuario: usuarioConLlave });
  };

  const handleExchangeConfirm = () => {
    if (!currentUser || !exchangeTarget) return;
    
    const success = intercambiarPorLugar(exchangeTarget.lugar.id, {
      nombre: currentUser.nombre,
      celular: currentUser.celular,
      tipo: currentUser.tipo
    });

    if (success) {
      toast({
        title: "Intercambio confirmado",
        description: `${exchangeTarget.lugar.nombre}: ${exchangeTarget.usuario.nombre} → ${currentUser.nombre}. Diríjase a solicitar la llave al docente saliente.`,
      });
    } else {
      toast({
        title: "Error",
        description: "No se pudo realizar el intercambio",
        variant: "destructive",
      });
    }
    setExchangeTarget(null);
  };

  const handleUserRegistered = (usuario: UsuarioRegistrado) => {
    // No auto-login: reset terminal so user can test their registration
    setCurrentUser(null);
    setSelectedKeys([]);
  };

  const handleUserSelect = (usuario: UsuarioRegistrado | null) => {
    setCurrentUser(usuario);
  };

  if (step === 'success' && selectedKeys.length > 0 && currentUser) {
    return (
      <div className="min-h-screen bg-background">
        <TerminalHeader />
        <main className="container max-w-4xl mx-auto py-8 px-4">
          <RequestSuccess
            selectedKeys={selectedKeys}
            onNewRequest={handleNewRequest}
            onCancelRequest={handleCancelRequest}
          />
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <TerminalHeader />
      
      <main className="container max-w-4xl mx-auto py-8 px-4">
        {/* Panel de identificación de usuario */}
        <Card className="p-6 mb-6">
          <UserSearchInput
            selectedUser={currentUser}
            onUserSelect={handleUserSelect}
            onRegisterClick={() => setShowRegistration(true)}
          />
        </Card>

        {/* Sugerencias de llaves frecuentes */}
        {currentUser && llavesFrecuentes.length > 0 && (
          <div className="mb-6">
            <FrequentKeys
              llavesFrecuentes={llavesFrecuentes}
              selectedKeys={selectedKeys}
              onToggleKey={handleToggleKey}
            />
          </div>
        )}

        {/* Banner de restricción horaria */}
        {currentUser && esHorarioRestringido() && !usuarioExentoHorario() && (
          <div className="mb-6 p-4 bg-destructive/10 border border-destructive/30 rounded-lg">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-destructive/20 rounded-full">
                <span className="text-destructive text-xl">⚠️</span>
              </div>
              <div>
                <h3 className="font-semibold text-destructive">Horario restringido</h3>
                <p className="text-sm text-destructive/80">
                  Por orden del Decano, no se permite la entrega de llaves antes de las 7:00 AM ni después de las 23:00 PM 
                  para {currentUser.tipo === 'Docente' ? 'docentes' : currentUser.tipo === 'Alumno' ? 'alumnos' : currentUser.tipo === 'Empresa' ? 'empresas' : 'personal TAS (excepto Servicios Generales)'}.
                  Solo el personal de vigilancia y servicios generales puede solicitar llaves en este horario.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Panel de búsqueda de llaves */}
        <Card className="p-6">
          <KeySearch
            selectedKeys={selectedKeys}
            onToggleKey={handleToggleKey}
            onExchangeRequest={currentUser ? handleExchangeRequest : undefined}
          />
        </Card>
        
        {/* Confirmación de solicitud */}
        {isFormValid && selectedKeys.length > 0 && currentUser && (
          <div className="mt-6">
            <RequestConfirmation
              selectedKeys={selectedKeys}
              nombre={currentUser.nombre}
              celular={currentUser.celular}
              tipoUsuario={currentUser.tipo}
              isSubmitting={isSubmitting}
              onSubmit={handleSubmit}
              onCancel={handleCancelConfirmation}
              onRemoveKey={handleRemoveKey}
            />
          </div>
        )}
        
        {/* Mensaje si falta completar */}
        {!isFormValid && (
          <Card className="mt-6 p-6 bg-muted/50 border-dashed">
            <p className="text-center text-muted-foreground">
              {!currentUser 
                ? "Identifíquese con su celular o regístrese para continuar"
                : "Seleccione una o más llaves disponibles para continuar"
              }
            </p>
          </Card>
        )}
      </main>
      
      <footer className="py-4 text-center text-sm text-muted-foreground border-t">
        <p>Terminal de Usuario • FCEA UdelaR • Sistema de Gestión de Llaves v4.0</p>
      </footer>

      {/* Modal de registro */}
      <RegistrationModal
        open={showRegistration}
        onOpenChange={setShowRegistration}
        onRegistered={handleUserRegistered}
      />

      {/* Modal de intercambio */}
      {exchangeTarget && currentUser && (
        <ExchangeConfirmation
          open={!!exchangeTarget}
          onOpenChange={(open) => !open && setExchangeTarget(null)}
          lugar={exchangeTarget.lugar}
          usuarioActual={{ nombre: currentUser.nombre, celular: currentUser.celular, tipo: currentUser.tipo }}
          usuarioConLlave={{ nombre: exchangeTarget.usuario.nombre }}
          onConfirmar={handleExchangeConfirm}
        />
      )}
    </div>
  );
}
