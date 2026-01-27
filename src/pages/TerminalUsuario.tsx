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
  
  // Llave seleccionada
  const [selectedKey, setSelectedKey] = useState<Lugar | null>(null);
  
  // Modal de registro
  const [showRegistration, setShowRegistration] = useState(false);
  
  // Estado de envío
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Hook de historial de llaves frecuentes
  const { llavesFrecuentes, registrarUso } = useHistorialLlaves(currentUser?.id ?? null);

  // Validación: usuario identificado Y llave seleccionada
  const isFormValid = currentUser && selectedKey;

  const handleSubmit = async () => {
    if (!isFormValid || !selectedKey || !currentUser) return;
    
    setIsSubmitting(true);
    
    // Registrar en historial de llaves frecuentes
    registrarUso(selectedKey.id);
    
    // Simular envío (en producción sería una llamada a la API)
    await new Promise(resolve => setTimeout(resolve, 1500));
    
    toast({
      title: "Solicitud enviada",
      description: "Diríjase al mostrador de vigilancia",
    });
    
    setIsSubmitting(false);
    setStep('success');
  };

  const handleNewRequest = () => {
    setCurrentUser(null);
    setSelectedKey(null);
    setStep('main');
  };

  const handleCancelRequest = () => {
    toast({
      title: "Pedido cancelado",
      description: "Su solicitud ha sido cancelada",
      variant: "destructive",
    });
    setCurrentUser(null);
    setSelectedKey(null);
    setStep('main');
  };

  const handleCancelConfirmation = () => {
    setSelectedKey(null);
  };

  const handleUserRegistered = (usuario: UsuarioRegistrado) => {
    setCurrentUser(usuario);
  };

  const handleUserSelect = (usuario: UsuarioRegistrado | null) => {
    setCurrentUser(usuario);
  };

  if (step === 'success' && selectedKey && currentUser) {
    return (
      <div className="min-h-screen bg-background">
        <TerminalHeader />
        <main className="container max-w-4xl mx-auto py-8 px-4">
          <RequestSuccess
            selectedKey={selectedKey}
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
        {currentUser && llavesFrecuentes.length > 0 && !selectedKey && (
          <div className="mb-6">
            <FrequentKeys
              llavesFrecuentes={llavesFrecuentes}
              selectedKey={selectedKey}
              onSelectKey={setSelectedKey}
            />
          </div>
        )}

        {/* Panel de búsqueda de llaves */}
        <Card className="p-6">
          <KeySearch
            selectedKey={selectedKey}
            onSelectKey={setSelectedKey}
          />
        </Card>
        
        {/* Confirmación de solicitud */}
        {isFormValid && selectedKey && currentUser && (
          <div className="mt-6">
            <RequestConfirmation
              selectedKey={selectedKey}
              nombre={currentUser.nombre}
              celular={currentUser.celular}
              tipoUsuario={currentUser.tipo}
              isSubmitting={isSubmitting}
              onSubmit={handleSubmit}
              onCancel={handleCancelConfirmation}
            />
          </div>
        )}
        
        {/* Mensaje si falta completar */}
        {!isFormValid && (
          <Card className="mt-6 p-6 bg-muted/50 border-dashed">
            <p className="text-center text-muted-foreground">
              {!currentUser 
                ? "Identifíquese con su celular o regístrese para continuar"
                : "Seleccione una llave disponible para continuar"
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
