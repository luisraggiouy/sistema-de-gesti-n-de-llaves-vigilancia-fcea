import { useState, useEffect } from 'react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { TerminalHeader } from '@/components/terminal/TerminalHeader';
import { UserSearchInput } from '@/components/terminal/UserSearchInput';
import { KeySearch } from '@/components/terminal/KeySearch';
import { FrequentKeys } from '@/components/terminal/FrequentKeys';
import { RequestConfirmation } from '@/components/terminal/RequestConfirmation';
import { RegistrationModal } from '@/components/terminal/RegistrationModal';
import { ExchangeConfirmation } from '@/components/terminal/ExchangeConfirmation';
import { ExchangeSuccess } from '@/components/terminal/ExchangeSuccess';
import { TerminalScreensaver } from '@/components/terminal/TerminalScreensaver';

import { Lugar, UsuarioRegistrado } from '@/data/fceaData';
import { useHistorialLlaves } from '@/hooks/useHistorialLlaves';
import { useUsuariosRegistrados } from '@/hooks/useUsuariosRegistrados';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';
import { useToast } from '@/hooks/use-toast';
import { RefreshCw, WifiOff, Loader2, Star } from 'lucide-react';

type TerminalStep = 'main' | 'exchange-success';

export default function TerminalUsuario() {
  const { toast } = useToast();
  const { 
    agregarSolicitudes, 
    intercambiarPorLugar, 
    lugaresDisponibles,
    lugares,
    solicitudesPendientes,
    solicitudesEntregadas,
    isLoading, 
    isConnected, 
    lastUpdated,
    refrescarDatos
  } = useSolicitudesContext();
  const { buscarPorTexto, usuarios } = useUsuariosRegistrados();
  const [step, setStep] = useState<TerminalStep>('main');
  const [currentUser, setCurrentUser] = useState<UsuarioRegistrado | null>(null);
  const [selectedKeys, setSelectedKeys] = useState<Lugar[]>([]);
  const [showRegistration, setShowRegistration] = useState(false);
  const [exchangeTarget, setExchangeTarget] = useState<{ lugar: Lugar; usuario: { nombre: string; celular: string; tipo: string } } | null>(null);
  // Fix 2026-08-25: datos del intercambio confirmado para la pantalla de exito
  // que cierra la sesion y limpia la Terminal para el proximo usuario.
  const [exchangeDone, setExchangeDone] = useState<{ lugar: Lugar; saliente: string; entrante: string } | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  // Fix 2026-08-30: contador para forzar el remontaje de KeySearch al iniciar una
  // nueva sesion. KeySearch guarda su propio estado interno (texto de busqueda y
  // filtros de tipo/edificio). Al enviar una solicitud normal, la terminal volvia
  // a 'main' pero KeySearch NO se desmontaba, por lo que quedaba el texto (ej.
  // "rendi") y la lista de resultados desplegada para el proximo usuario. Al
  // cambiar este key, React remonta KeySearch limpio (mismo efecto que el
  // intercambio, que ya lo desmontaba al pasar por 'exchange-success').
  const [terminalResetKey, setTerminalResetKey] = useState(0);
  // Fix 2026-08-28: usar TODAS las llaves (no solo las disponibles) como base de
  // las frecuentes, para que una llave frecuente que este en uso o ya solicitada
  // siga apareciendo (permite ofrecer intercambio y avisar 'ya solicitada').
  const { llavesFrecuentes, registrarUso } = useHistorialLlaves(currentUser?.id ?? null, lugares);
  const isFormValid = currentUser && selectedKeys.length > 0;
  
  // La carga inicial ya se hace en SolicitudesContext (polling cada 3s)

  // Forzar recarga de llaves frecuentes cuando cambia el usuario
  useEffect(() => {
    if (currentUser) {
      console.log("Usuario seleccionado, cargando llaves frecuentes:", currentUser.nombre);
    }
  }, [currentUser]);

  // Si el usuario actualmente seleccionado es eliminado de la agenda,
  // desseleccionarlo automáticamente y mostrar un aviso.
  useEffect(() => {
    if (!currentUser) return;
    const sigueExistiendo = usuarios.some(u => u.id === currentUser.id);
    if (!sigueExistiendo) {
      toast({
        title: "Usuario eliminado de la agenda",
        description: `${currentUser.nombre} fue eliminado por el vigilante y ya no puede solicitar llaves.`,
        variant: "destructive",
      });
      setCurrentUser(null);
      setSelectedKeys([]);
      setStep('main');
    }
  }, [usuarios, currentUser]);

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
    // Se normaliza tipo y departamento (trim) por si vienen con espacios de más.
    const tipo = (currentUser.tipo || '').trim();
    const depto = (currentUser.departamento || '').trim();
    // Exentos totales (cualquier hora, 24 hs): Personal TAS de Servicios
    // Generales, Vigilancia e Intendencia.
    if (
      tipo === 'Personal TAS' &&
      (depto === 'Servicios Generales' ||
        depto === 'Vigilancia' ||
        depto === 'Intendencia')
    ) {
      return true;
    }
    // Upgrade 2026-08-30 (Opción B): las EMPRESAS (ej. cooperativas de limpieza)
    // pueden solicitar llaves desde las 06:00, una hora antes que el resto, porque
    // suelen empezar a trabajar antes de las 7:00. Solo se les exime la franja
    // 06:00–06:59; el bloqueo nocturno (>= 23:00 y < 06:00) sigue vigente para
    // ellas, y el resto de los usuarios mantiene el corte de las 07:00.
    if (tipo === 'Empresa') {
      const hora = new Date().getHours();
      if (hora === 6) return true;
    }
    return false;
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
    toast({ title: "¡Solicitud enviada!", description: `${selectedKeys.length} llave(s) solicitada(s). Ya le entregan la llave, gracias.` });
    setIsSubmitting(false);
    // Cambio 2026-08-30: se eliminó la pantalla de éxito con cuenta regresiva de
    // 5s (su botón "Cancelar Pedido" no borraba realmente la solicitud, solo
    // limpiaba la terminal y confundía). Ahora, tras enviar, la terminal vuelve
    // INMEDIATAMENTE al inicio limpio para que se loguee el próximo usuario. Si
    // hubo un error en el pedido, el vigilante lo elimina desde el Monitor.
    handleNewRequest();
  };

  const handleNewRequest = () => { setCurrentUser(null); setSelectedKeys([]); setStep('main'); setTerminalResetKey(k => k + 1); };

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
      // Fix 2026-08-25: pasar a la pantalla de exito del intercambio para
      // cerrar luego la sesion del usuario y dejar la Terminal limpia.
      setExchangeDone({
        lugar: exchangeTarget.lugar,
        saliente: exchangeTarget.usuario.nombre,
        entrante: currentUser.nombre,
      });
      setStep('exchange-success');
    } else {
      toast({ title: "Error", description: "No se pudo realizar el intercambio", variant: "destructive" });
    }
    setExchangeTarget(null);
  };

  // Fix 2026-08-25: al finalizar el intercambio, cerrar la sesion del usuario,
  // limpiar las llaves seleccionadas y volver al inicio (esto tambien desmonta
  // KeySearch, por lo que la lista de llaves queda replegada/limpia sin F5).
  const handleExchangeFinish = () => {
    setExchangeDone(null);
    setCurrentUser(null);
    setSelectedKeys([]);
    setStep('main');
    setTerminalResetKey(k => k + 1);
  };

  if (step === 'exchange-success' && exchangeDone) {
    return (
      <div className="min-h-screen bg-background">
        <TerminalHeader />
        <main className="container max-w-4xl mx-auto py-8 px-4">
          <ExchangeSuccess
            lugar={exchangeDone.lugar}
            usuarioSaliente={exchangeDone.saliente}
            usuarioEntrante={exchangeDone.entrante}
            onFinish={handleExchangeFinish}
          />
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <TerminalHeader />
      {/* Banner de bienvenida */}
      <div className="bg-primary/5 border-b border-primary/10 py-3 px-4">
        <div className="container max-w-4xl mx-auto text-center">
          <p className="text-primary font-bold text-lg tracking-wide">¡BIENVENIDOS!</p>
          <p className="text-muted-foreground text-xl font-medium">
            Software diseñado y desarrollado 100% por Sección Vigilancia de FCEA
          </p>
        </div>
      </div>
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
              <FrequentKeys
                llavesFrecuentes={llavesFrecuentes}
                selectedKeys={selectedKeys}
                onToggleKey={handleToggleKey}
                solicitudesPendientes={solicitudesPendientes}
                solicitudesEntregadas={solicitudesEntregadas}
                onExchangeRequest={currentUser ? handleExchangeRequest : undefined}
              />
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
          <KeySearch key={terminalResetKey} selectedKeys={selectedKeys} onToggleKey={handleToggleKey} onExchangeRequest={currentUser ? handleExchangeRequest : undefined} tipoUsuario={currentUser?.tipo} />
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
              {!currentUser ? (
                <>
                  Identifíquese con su número de celular o con su email, de lo contrario{' '}
                  <button
                    onClick={() => setShowRegistration(true)}
                    className="text-blue-600 hover:text-blue-800 underline font-medium cursor-pointer"
                  >
                    regístrese
                  </button>
                  {' '}para continuar.
                </>
              ) : "Seleccione una o más llaves disponibles para continuar"}
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

      {/* Screensaver / overlay de bienvenida. En hardware táctil se muestra
          tras N segundos de inactividad y evita que el monitor se apague
          sin que el próximo usuario sepa cómo prenderlo. En hardware
          tradicional (o desarrollo) el componente no renderiza nada. */}
      <TerminalScreensaver />
    </div>
  );
}


