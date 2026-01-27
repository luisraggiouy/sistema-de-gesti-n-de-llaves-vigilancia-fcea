import { useState } from 'react';
import { Card } from '@/components/ui/card';
import { TerminalHeader } from '@/components/terminal/TerminalHeader';
import { UserSearchInput } from '@/components/terminal/UserSearchInput';
import { KeySearch } from '@/components/terminal/KeySearch';
import { FrequentKeys } from '@/components/terminal/FrequentKeys';
import { RequestConfirmation } from '@/components/terminal/RequestConfirmation';
import { RequestSuccess } from '@/components/terminal/RequestSuccess';
import { RegistrationModal } from '@/components/terminal/RegistrationModal';
import { Lugar, UsuarioRegistrado } from '@/data/fceaData';
import { useHistorialLlaves } from '@/hooks/useHistorialLlaves';
import { useToast } from '@/hooks/use-toast';

type TerminalStep = 'main' | 'success';

export default function TerminalUsuario() {
  const { toast } = useToast();
  const [step, setStep] = useState<TerminalStep>('main');
  
  // Usuario identificado
  const [currentUser, setCurrentUser] = useState<UsuarioRegistrado | null>(null);
  
  // Llaves seleccionadas (múltiples)
  const [selectedKeys, setSelectedKeys] = useState<Lugar[]>([]);
  
  // Modal de registro
  const [showRegistration, setShowRegistration] = useState(false);
  
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

  const handleSubmit = async () => {
    if (!isFormValid || selectedKeys.length === 0 || !currentUser) return;
    
    setIsSubmitting(true);
    
    // Registrar en historial de llaves frecuentes
    selectedKeys.forEach(key => registrarUso(key.id));
    
    // Simular envío (en producción sería una llamada a la API)
    await new Promise(resolve => setTimeout(resolve, 1500));
    
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

  const handleUserRegistered = (usuario: UsuarioRegistrado) => {
    setCurrentUser(usuario);
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

        {/* Panel de búsqueda de llaves */}
        <Card className="p-6">
          <KeySearch
            selectedKeys={selectedKeys}
            onToggleKey={handleToggleKey}
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
        <p>Terminal de Usuario • FCEA UdelaR • Sistema de Gestión de Llaves v3.6</p>
      </footer>

      {/* Modal de registro */}
      <RegistrationModal
        open={showRegistration}
        onOpenChange={setShowRegistration}
        onRegistered={handleUserRegistered}
      />
    </div>
  );
}
