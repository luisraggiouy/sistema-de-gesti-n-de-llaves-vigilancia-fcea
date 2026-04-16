import { useState, useEffect } from 'react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
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
import { useUsuariosRegistrados } from '@/hooks/useUsuariosRegistrados';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';
import { useToast } from '@/hooks/use-toast';
import { RefreshCw, WifiOff, Loader2, Star } from 'lucide-react';

type TerminalStep = 'main' | 'success';

export default function TerminalUsuario() {
  const { toast } = useToast();
  const { 
    agregarSolicitudes, 
    intercambiarPorLugar, 
    lugaresDisponibles,
    isLoading, 
    isConnected, 
    lastUpdated,
    refrescarDatos
  } = useSolicitudesContext();
  const { buscarPorTexto } = useUsuariosRegistrados();
  const [step, setStep] = useState<TerminalStep>('main');
  const [currentUser, setCurrentUser] = useState<UsuarioRegistrado | null>(null);
  const [selectedKeys, setSelectedKeys] = useState<Lugar[]>([]);
  const [showRegistration, setShowRegistration] = useState(false);
  const [exchangeTarget, setExchangeTarget] = useState<{ lugar: Lugar; usuario: { nombre: string; celular: string; tipo: string } } | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { llavesFrecuentes, registrarUso } = useHistorialLlaves(currentUser?.id ?? null, lugaresDisponibles);
  const isFormValid = currentUser && selectedKeys.length > 0;
  
  // Refresh data automatically when connection is restored
  // Refresh data automatically when connection is restored
  useEffect(() => {
    if (isConnected && lastUpdated === null) {
      refrescarDatos();
    }
  }, [isConnected, lastUpdated, refrescarDatos]);

  // Forzar recarga de llaves frecuentes cuando cambia el usuario
  useEffect(() => {
    if (currentUser) {
      console.log("Usuario seleccionado, cargando llaves frecuentes:", currentUser.nombre);
    }
  }, [currentUser]);

  const handleToggleKey = (lugar: Lugar) => {
    setSelectedKeys(prev => {
      const isSelected = prev.some(k => k.id === lugar.id);
      if (isSelected) return prev.filter(k => k.id !== lugar.id);
      return [...prev, lugar];
    });
  };

  const handleRemoveKey = (lugarId: string) => {
    setSelectedKeys(prev => prev.filter(k => k.id !== lugarId));
  };

  const esHorarioRestringido = () => {
    const hora = new Date().getHours();
    return hora < 7 || hora >= 23;
  };

  const usuarioExentoHorario = () => {
    if (!currentUser) return false;
    return currentUser.tipo === 'Personal TAS' &&
      (currentUser.departamento === 'Servicios Generales' || currentUser.departamento === 'Vigilancia');
  };

  const handleSubmit = async () => {
    if (!isFormValid || !currentUser) return;
    if (esHorarioRestringido() && !usuarioExentoHorario()) {
      toast({ title: "Horario no permitido", description: "No se permite la entrega de llaves en este horario.", variant: "destructive" });
      return;
    }
    setIsSubmitting(true);
    selectedKeys.forEach(key => registrarUso(key.id));
    await agregarSolicitudes(selectedKeys, {
      nombre: currentUser.nombre,
      celular: currentUser.celular,
      tipo: currentUser.tipo,
      departamento: currentUser.departamento,
      nombreEmpresa: currentUser.nombreEmpresa,
    });
    await new Promise(resolve => setTimeout(resolve, 500));
    toast({ title: "Solicitud enviada", description: `${selectedKeys.length} llave(s) solicitada(s).` });
    setIsSubmitting(false);
    setStep('success');
  };

  const handleNewRequest = () => { setCurrentUser(null); setSelectedKeys([]); setStep('main'); };

  const handleCancelRequest = () => {
    toast({ title: "Pedido cancelado", description: "Su solicitud ha sido cancelada", variant: "destructive" });
    setCurrentUser(null); setSelectedKeys([]); setStep('main');
  };

  const handleCancelConfirmation = () => setSelectedKeys([]);

  const handleExchangeRequest = (lugar: Lugar, usuarioConLlave: { nombre: string; celular: string; tipo: string }) => {
    if (!currentUser) {
      toast({ title: "Identifíquese primero", description: "Debe identificarse antes de solicitar un intercambio", variant: "destructive" });
      return;
    }
    
    // Prevent self-exchange (same user exchanging with themselves)
    if (currentUser.nombre === usuarioConLlave.nombre) {
      toast({ 
        title: "Intercambio no permitido", 
        description: "No puede intercambiar una llave consigo mismo", 
        variant: "destructive" 
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
      tipo: currentUser.tipo,
      departamento: currentUser.departamento,
      nombreEmpresa: currentUser.nombreEmpresa,
    } as any);
    if (success) {
      toast({ title: "Intercambio confirmado", description: `${exchangeTarget.lugar.nombre}: ${exchangeTarget.usuario.nombre} → ${currentUser.nombre}.` });
    } else {
      toast({ title: "Error", description: "No se pudo realizar el intercambio", variant: "destructive" });
    }
    setExchangeTarget(null);
  };

  if (step === 'success' && selectedKeys.length > 0 && currentUser) {
  return (
    <div className="min-h-screen bg-background">
      <TerminalHeader />
      
      {/* Connection status and refresh button */}
      <div className="bg-card border-b px-4 py-2">
        <div className="container max-w-4xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-2">
            {!isConnected ? (
              <>
                <WifiOff className="w-4 h-4 text-destructive" />
                <span className="text-sm text-destructive">Sin conexión</span>
              </>
            ) : lastUpdated ? (
              <span className="text-xs text-muted-foreground">
                Actualizado: {lastUpdated.toLocaleTimeString()}
              </span>
            ) : null}
          </div>
          <Button 
            variant="outline" 
            size="sm" 
            className="gap-2"
            onClick={() => refrescarDatos()}
            disabled={isLoading || !isConnected}
          >
            {isLoading ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <RefreshCw className="w-4 h-4" />
            )}
            <span>Actualizar datos</span>
          </Button>
        </div>
      </div>
      
      <main className="container max-w-4xl mx-auto py-8 px-4">
          <RequestSuccess selectedKeys={selectedKeys} onNewRequest={handleNewRequest} onCancelRequest={handleCancelRequest} />
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <TerminalHeader />
      <main className="container max-w-4xl mx-auto py-8 px-4">
        <Card className="p-6 mb-6">
          <UserSearchInput
            selectedUser={currentUser}
            onUserSelect={setCurrentUser}
            onRegisterClick={() => setShowRegistration(true)}
            buscarUsuarios={buscarPorTexto}
          />
        </Card>

        {currentUser && (
          <div className="mb-6">
            {llavesFrecuentes.length > 0 ? (
              <FrequentKeys llavesFrecuentes={llavesFrecuentes} selectedKeys={selectedKeys} onToggleKey={handleToggleKey} />
            ) : (
              <Card className="p-4 bg-primary/5 border-primary/20">
                <h3 className="text-sm font-semibold text-foreground flex items-center gap-2 mb-3">
                  <Star className="w-4 h-4 text-primary fill-primary" />
                  Llaves frecuentes
                </h3>
                <p className="text-sm text-muted-foreground text-center py-2">
                  Aún no tienes llaves de uso frecuente. Las llaves que uses aparecerán aquí para un acceso más rápido.
                </p>
              </Card>
            )}
          </div>
        )}

        {currentUser && esHorarioRestringido() && !usuarioExentoHorario() && (
          <div className="mb-6 p-4 bg-destructive/10 border border-destructive/30 rounded-lg">
            <div className="flex items-center gap-3">
              <span className="text-destructive text-xl">⚠️</span>
              <div>
                <h3 className="font-semibold text-destructive">Horario restringido</h3>
                <p className="text-sm text-destructive/80">No se permite la entrega de llaves antes de las 7:00 AM ni después de las 23:00 PM.</p>
              </div>
            </div>
          </div>
        )}

        <Card className="p-6 relative">
          {isLoading && (
            <div className="absolute inset-0 bg-background/80 flex items-center justify-center z-10">
              <div className="flex flex-col items-center gap-2">
                <Loader2 className="w-8 h-8 animate-spin text-primary" />
                <p className="text-sm text-muted-foreground">Cargando datos...</p>
              </div>
            </div>
          )}
          <KeySearch selectedKeys={selectedKeys} onToggleKey={handleToggleKey} onExchangeRequest={currentUser ? handleExchangeRequest : undefined} tipoUsuario={currentUser?.tipo} />
        </Card>

        {isFormValid && currentUser && (
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

        {!isFormValid && (
          <Card className="mt-6 p-6 bg-muted/50 border-dashed">
            <p className="text-center text-muted-foreground">
              {!currentUser ? "Identifíquese con su celular o regístrese para continuar" : "Seleccione una o más llaves disponibles para continuar"}
            </p>
          </Card>
        )}
      </main>

      <footer className="py-4 text-center text-sm text-muted-foreground border-t">
        <p>Terminal de Usuario • FCEA UdelaR • Sistema de Gestión de Llaves v4.3</p>
      </footer>

      <RegistrationModal open={showRegistration} onOpenChange={setShowRegistration} onRegistered={(usuario) => { setCurrentUser(usuario); setSelectedKeys([]); toast({ title: "Registro exitoso", description: `Bienvenido/a ${usuario.nombre}. Ya puede seleccionar llaves.` }); }} />

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