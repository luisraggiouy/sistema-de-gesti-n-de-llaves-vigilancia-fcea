import { useState, useEffect, useRef } from 'react';
import { MonitorHeader } from '@/components/monitor/MonitorHeader';
import { PendingRequestCard } from '@/components/monitor/PendingRequestCard';
import { KeyInUseCard } from '@/components/monitor/KeyInUseCard';
import { KeyManagementModal } from '@/components/monitor/KeyManagementModal';
import { GuardManagementModal } from '@/components/monitor/GuardManagementModal';
import { ConfigurationModal } from '@/components/monitor/ConfigurationModal';
import { KeyHistorySearch } from '@/components/monitor/KeyHistorySearch';
import { AgendaModal } from '@/components/monitor/AgendaModal';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';
import { useVigilantes } from '@/hooks/useVigilantes';
import { useConfiguracion } from '@/hooks/useConfiguracion';
import { useToast } from '@/hooks/use-toast';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ClipboardList, Key, CheckCircle2, Settings2, Users, Settings, History, BookUser, Package } from 'lucide-react';
import { useSonidos } from '@/hooks/useSonidos';
import { SoundControls } from '@/components/monitor/SoundControls';
import { ObjetosOlvidadosModal } from '@/components/monitor/ObjetosOlvidadosModal';
import { useObjetosOlvidados } from '@/hooks/useObjetosOlvidados';

export default function MonitorVigilancia() {
  const { toast } = useToast();
  const {
    solicitudesPendientes,
    solicitudesEntregadas,
    solicitudesDevueltas,
    lugaresDisponibles,
    entregarLlave,
    devolverLlave,
    intercambiarLlave,
    deshacerAccion,
    getUndoParaSolicitud,
    agregarLlave,
    quitarLlave,
    actualizarNotas,
  } = useSolicitudesContext();

  const {
    vigilantes,
    agregarVigilante,
    eliminarVigilante,
    actualizarVigilante,
    obtenerVigilantesConTransicion
  } = useVigilantes();

  const { configuracion, actualizarConfiguracion, resetearConfiguracion } = useConfiguracion();
  const { config: sonidoConfig, setVolumen, toggleMute, sonarNuevaSolicitud, sonarEntrega, sonarDevolucion, sonarPrueba } = useSonidos();

  // Detectar nuevas solicitudes para sonar
  const prevPendientesRef = useRef(solicitudesPendientes.length);
  useEffect(() => {
    if (solicitudesPendientes.length > prevPendientesRef.current) {
      sonarNuevaSolicitud();
    }
    prevPendientesRef.current = solicitudesPendientes.length;
  }, [solicitudesPendientes.length, sonarNuevaSolicitud]);

  const [keyModalOpen, setKeyModalOpen] = useState(false);
  const [guardModalOpen, setGuardModalOpen] = useState(false);
  const [configModalOpen, setConfigModalOpen] = useState(false);
  const [historySearchOpen, setHistorySearchOpen] = useState(false);
  const [agendaOpen, setAgendaOpen] = useState(false);
  const [objetosOpen, setObjetosOpen] = useState(false);

  const {
    objetos,
    objetosEnCustodia,
    objetosDevueltos,
    registrarObjeto,
    devolverObjeto,
    buscarObjetos,
  } = useObjetosOlvidados();

  // Auto-refresh de hora cada segundo
  const [, setTick] = useState(0);
  useEffect(() => {
    const interval = setInterval(() => setTick(t => t + 1), 1000);
    return () => clearInterval(interval);
  }, []);

  // Obtener vigilantes con transición
  const { actuales: vigilantesActuales, anteriores: vigilantesAnteriores } = 
    obtenerVigilantesConTransicion(configuracion.transicionTurnoMinutos);

  const handleEntregar = (solicitudId: string, vigilante: string) => {
    const solicitud = solicitudesPendientes.find(s => s.id === solicitudId);
    if (!solicitud) return;

    entregarLlave(solicitudId, vigilante);
    sonarEntrega(vigilante);
    
    toast({
      title: "Llave entregada",
      description: `${solicitud.lugar.nombre} entregada por ${vigilante}. Tienes 2 minutos para deshacer.`,
    });
  };

  const handleDevolver = (solicitudId: string, vigilante: string) => {
    const solicitud = solicitudesEntregadas.find(s => s.id === solicitudId);
    if (!solicitud) return;

    devolverLlave(solicitudId, vigilante);
    sonarDevolucion(vigilante);
    
    toast({
      title: "Llave devuelta",
      description: `${solicitud.lugar.nombre} recibida por ${vigilante}`,
    });
  };

  const handleIntercambiar = (solicitudId: string, vigilante: string, nuevoUsuario: { nombre: string; celular: string; tipo: string }) => {
    const solicitud = solicitudesEntregadas.find(s => s.id === solicitudId);
    if (!solicitud) return;

    intercambiarLlave(solicitudId, vigilante, nuevoUsuario);
    
    toast({
      title: "Llave intercambiada",
      description: `${solicitud.lugar.nombre}: ${solicitud.usuario.nombre} → ${nuevoUsuario.nombre}`,
    });
  };

  const handleUndo = (solicitudId: string) => {
    const undoAction = getUndoParaSolicitud(solicitudId);
    if (!undoAction) return;

    const success = deshacerAccion(undoAction.id);
    
    if (success) {
      toast({
        title: "Acción deshecha",
        description: "La operación fue revertida correctamente",
        variant: "default"
      });
    } else {
      toast({
        title: "Error",
        description: "No se pudo deshacer la acción (tiempo expirado)",
        variant: "destructive"
      });
    }
  };

  return (
    <div className="min-h-screen bg-background">
      <MonitorHeader 
        pendientes={solicitudesPendientes.length} 
        enUso={solicitudesEntregadas.length}
      >
        <div className="flex gap-2">
           <Button 
            variant="outline" 
            onClick={() => setObjetosOpen(true)}
            className="gap-2"
            size="sm"
          >
            <Package className="w-4 h-4" />
            <span className="hidden md:inline">Objetos</span>
            {objetosEnCustodia.length > 0 && (
              <Badge variant="secondary" className="ml-1">{objetosEnCustodia.length}</Badge>
            )}
          </Button>
          <Button 
            variant="outline" 
            onClick={() => setAgendaOpen(true)}
            className="gap-2"
            size="sm"
          >
            <BookUser className="w-4 h-4" />
            <span className="hidden md:inline">Agenda / Autorizaciones</span>
          </Button>
          <Button 
            variant="outline" 
            onClick={() => setHistorySearchOpen(true)}
            className="gap-2"
            size="sm"
          >
            <History className="w-4 h-4" />
            <span className="hidden md:inline">Historial</span>
          </Button>
          <Button 
            variant="outline" 
            onClick={() => setConfigModalOpen(true)}
            className="gap-2"
            size="sm"
          >
            <Settings className="w-4 h-4" />
            <span className="hidden md:inline">Configuración</span>
          </Button>
          <Button 
            variant="outline" 
            onClick={() => setGuardModalOpen(true)}
            className="gap-2"
            size="sm"
          >
            <Users className="w-4 h-4" />
            <span className="hidden md:inline">Vigilantes</span>
          </Button>
          <Button 
            variant="outline" 
            onClick={() => setKeyModalOpen(true)}
            className="gap-2"
            size="sm"
          >
            <Settings2 className="w-4 h-4" />
            <span className="hidden md:inline">Llaves</span>
          </Button>
        </div>
      </MonitorHeader>

      {/* Sound controls bar - always visible */}
      <div className="bg-card border-b px-6 py-2">
        <div className="max-w-7xl mx-auto">
          <SoundControls
            config={sonidoConfig}
            onVolumeChange={setVolumen}
            onToggleMute={toggleMute}
            onTestSound={sonarPrueba}
          />
        </div>
      </div>

      <KeyManagementModal
        open={keyModalOpen}
        onOpenChange={setKeyModalOpen}
        lugares={lugaresDisponibles}
        onAgregarLlave={agregarLlave}
        onQuitarLlave={quitarLlave}
      />

      <GuardManagementModal
        open={guardModalOpen}
        onOpenChange={setGuardModalOpen}
        vigilantes={vigilantes}
        onAgregar={agregarVigilante}
        onEliminar={eliminarVigilante}
        onActualizar={actualizarVigilante}
      />

      <ConfigurationModal
        open={configModalOpen}
        onOpenChange={setConfigModalOpen}
        configuracion={configuracion}
        onGuardar={actualizarConfiguracion}
        onResetear={resetearConfiguracion}
      />

      <KeyHistorySearch
        open={historySearchOpen}
        onOpenChange={setHistorySearchOpen}
      />

      <AgendaModal
        open={agendaOpen}
        onOpenChange={setAgendaOpen}
      />

      <ObjetosOlvidadosModal
        open={objetosOpen}
        onOpenChange={setObjetosOpen}
        objetos={objetos}
        objetosEnCustodia={objetosEnCustodia}
        objetosDevueltos={objetosDevueltos}
        vigilantes={vigilantesActuales}
        onRegistrar={registrarObjeto}
        onDevolver={devolverObjeto}
        buscarObjetos={buscarObjetos}
      />

      <main className="max-w-7xl mx-auto py-6 px-4 space-y-8">
        {/* Sección: Cola de Solicitudes */}
        <section>
          <div className="flex items-center gap-3 mb-4">
            <ClipboardList className="w-6 h-6 text-primary" />
            <h2 className="text-xl font-semibold">Cola de Solicitudes</h2>
            {solicitudesPendientes.length > 0 && (
              <Badge variant="destructive">
                {solicitudesPendientes.length} pendiente{solicitudesPendientes.length !== 1 ? 's' : ''}
              </Badge>
            )}
          </div>

          {solicitudesPendientes.length === 0 ? (
            <Card className="p-8 text-center">
              <CheckCircle2 className="w-12 h-12 mx-auto text-success/50 mb-3" />
              <h3 className="text-lg font-semibold mb-1">No hay solicitudes pendientes</h3>
              <p className="text-muted-foreground text-sm">
                Las nuevas solicitudes aparecerán aquí automáticamente
              </p>
            </Card>
          ) : (
            <div className="space-y-4">
              {solicitudesPendientes.map(solicitud => (
                <PendingRequestCard
                  key={solicitud.id}
                  solicitud={solicitud}
                  vigilantes={vigilantesActuales}
                  vigilantesAnteriores={vigilantesAnteriores}
                  onEntregar={(v) => handleEntregar(solicitud.id, v)}
                />
              ))}
            </div>
          )}
        </section>

        {/* Separador visual */}
        <div className="border-t border-border" />

        {/* Sección: Llaves en Uso */}
        <section>
          <div className="flex items-center gap-3 mb-4">
            <Key className="w-6 h-6 text-success" />
            <h2 className="text-xl font-semibold">Llaves en Uso</h2>
            {solicitudesEntregadas.length > 0 && (
              <Badge className="bg-success/20 text-success border-success/30">
                {solicitudesEntregadas.length} en uso
              </Badge>
            )}
          </div>

          {solicitudesEntregadas.length === 0 ? (
            <Card className="p-8 text-center">
              <Key className="w-12 h-12 mx-auto text-muted-foreground/30 mb-3" />
              <h3 className="text-lg font-semibold mb-1">No hay llaves en uso</h3>
              <p className="text-muted-foreground text-sm">
                Las llaves entregadas aparecerán aquí
              </p>
            </Card>
          ) : (
            <div className="space-y-4">
              {solicitudesEntregadas.map(solicitud => {
                const undoAction = getUndoParaSolicitud(solicitud.id);
                return (
                  <KeyInUseCard
                    key={solicitud.id}
                    solicitud={solicitud}
                    undoAction={undoAction}
                    vigilantes={vigilantesActuales}
                    vigilantesAnteriores={vigilantesAnteriores}
                    tiempoAlertaMinutos={configuracion.tiempoAlertaMinutos}
                    mensajeWhatsApp={configuracion.mensajeWhatsApp}
                    onDevolver={(v) => handleDevolver(solicitud.id, v)}
                    onUndo={() => handleUndo(solicitud.id)}
                    onIntercambiar={(v, u) => handleIntercambiar(solicitud.id, v, u)}
                    onNotasChange={(notas) => actualizarNotas(solicitud.id, notas)}
                  />
                );
              })}
            </div>
          )}
        </section>

        {/* Separador visual */}
        {solicitudesDevueltas.length > 0 && <div className="border-t border-border" />}

        {/* Sección: Llaves Devueltas */}
        {solicitudesDevueltas.length > 0 && (
          <section>
            <div className="flex items-center gap-3 mb-4">
              <CheckCircle2 className="w-6 h-6 text-emerald-600" />
              <h2 className="text-xl font-semibold">Llaves Devueltas</h2>
              <Badge className="bg-emerald-100 text-emerald-800 border-emerald-200">
                {solicitudesDevueltas.length} devuelta{solicitudesDevueltas.length !== 1 ? 's' : ''}
              </Badge>
            </div>
            <div className="space-y-2">
              {solicitudesDevueltas.slice(-10).reverse().map(solicitud => (
                <Card key={solicitud.id} className="p-4 bg-emerald-50 border-emerald-200">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <Key className="w-5 h-5 text-emerald-600" />
                      <div>
                        <span className="font-semibold">{solicitud.lugar.nombre}</span>
                        <span className="text-sm text-muted-foreground ml-2">
                          Devuelta por {solicitud.usuario.nombre}
                        </span>
                        {solicitud.recibidoPor && (
                          <span className="text-sm text-muted-foreground">
                            {' '}• Recibida por {solicitud.recibidoPor}
                          </span>
                        )}
                      </div>
                    </div>
                    {solicitud.horaDevolucion && (
                      <span className="text-sm text-emerald-700">
                        {solicitud.horaDevolucion.toLocaleTimeString('es-UY', { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    )}
                  </div>
                </Card>
              ))}
            </div>
          </section>
        )}
      </main>

      <footer className="py-4 text-center text-sm text-muted-foreground border-t mt-8">
        <p>Monitor de Vigilancia • FCEA UdelaR • Sistema de Gestión de Llaves v4.3</p>
      </footer>
    </div>
  );
}
