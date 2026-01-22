import { useState } from 'react';
import { Card } from '@/components/ui/card';
import { TerminalHeader } from '@/components/terminal/TerminalHeader';
import { UserDataForm } from '@/components/terminal/UserDataForm';
import { KeySearch } from '@/components/terminal/KeySearch';
import { RequestConfirmation } from '@/components/terminal/RequestConfirmation';
import { RequestSuccess } from '@/components/terminal/RequestSuccess';
import { Lugar, TipoUsuario } from '@/data/fceaData';
import { useToast } from '@/hooks/use-toast';

type TerminalStep = 'form' | 'success';

export default function TerminalUsuario() {
  const { toast } = useToast();
  const [step, setStep] = useState<TerminalStep>('form');
  
  // Datos del usuario
  const [nombre, setNombre] = useState('');
  const [celular, setCelular] = useState('');
  const [tipoUsuario, setTipoUsuario] = useState<TipoUsuario | ''>('');
  
  // Llave seleccionada
  const [selectedKey, setSelectedKey] = useState<Lugar | null>(null);
  
  // Estado de envío
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [ticketNumber, setTicketNumber] = useState('');

  const isFormValid = nombre.trim() && celular.trim() && tipoUsuario && selectedKey;

  const handleSubmit = async () => {
    if (!isFormValid || !selectedKey) return;
    
    setIsSubmitting(true);
    
    // Simular envío (en producción sería una llamada a la API)
    await new Promise(resolve => setTimeout(resolve, 1500));
    
    // Generar número de ticket
    const ticket = `T${Date.now().toString().slice(-6)}`;
    setTicketNumber(ticket);
    
    toast({
      title: "Solicitud enviada",
      description: `Ticket ${ticket} - Diríjase al mostrador de vigilancia`,
    });
    
    setIsSubmitting(false);
    setStep('success');
  };

  const handleNewRequest = () => {
    setNombre('');
    setCelular('');
    setTipoUsuario('');
    setSelectedKey(null);
    setTicketNumber('');
    setStep('form');
  };

  const handleCancelConfirmation = () => {
    setSelectedKey(null);
  };

  if (step === 'success' && selectedKey) {
    return (
      <div className="min-h-screen bg-background">
        <TerminalHeader />
        <main className="container max-w-4xl mx-auto py-8 px-4">
          <RequestSuccess
            selectedKey={selectedKey}
            ticketNumber={ticketNumber}
            onNewRequest={handleNewRequest}
          />
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <TerminalHeader />
      
      <main className="container max-w-4xl mx-auto py-8 px-4">
        <div className="grid md:grid-cols-2 gap-6">
          {/* Panel izquierdo: Datos del usuario */}
          <Card className="p-6">
            <UserDataForm
              nombre={nombre}
              celular={celular}
              tipoUsuario={tipoUsuario}
              onNombreChange={setNombre}
              onCelularChange={setCelular}
              onTipoChange={setTipoUsuario}
            />
          </Card>
          
          {/* Panel derecho: Búsqueda de llaves */}
          <Card className="p-6">
            <KeySearch
              selectedKey={selectedKey}
              onSelectKey={setSelectedKey}
            />
          </Card>
        </div>
        
        {/* Confirmación de solicitud */}
        {isFormValid && selectedKey && tipoUsuario && (
          <div className="mt-6">
            <RequestConfirmation
              selectedKey={selectedKey}
              nombre={nombre}
              celular={celular}
              tipoUsuario={tipoUsuario}
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
              Complete sus datos y seleccione una llave disponible para continuar
            </p>
          </Card>
        )}
      </main>
      
      <footer className="py-4 text-center text-sm text-muted-foreground border-t">
        <p>Terminal de Usuario • FCEA UdelaR • Sistema de Gestión de Llaves v3.6</p>
      </footer>
    </div>
  );
}
