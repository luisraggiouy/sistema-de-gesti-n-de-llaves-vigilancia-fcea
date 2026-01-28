import { useState, useEffect } from 'react';
import { MonitorHeader } from '@/components/monitor/MonitorHeader';
import { SolicitudCard } from '@/components/monitor/SolicitudCard';
import { KeyManagementModal } from '@/components/monitor/KeyManagementModal';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';
import { useToast } from '@/hooks/use-toast';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ClipboardList, Key, CheckCircle2, Settings2 } from 'lucide-react';

export default function MonitorVigilancia() {
  const { toast } = useToast();
  const {
    solicitudesPendientes,
    solicitudesEntregadas,
    lugaresDisponibles,
    entregarLlave,
    devolverLlave,
    deshacerAccion,
    getUndoParaSolicitud,
    agregarLlave,
    quitarLlave,
  } = useSolicitudesContext();

  const [keyModalOpen, setKeyModalOpen] = useState(false);

  // Auto-refresh de hora cada segundo
  const [, setTick] = useState(0);
  useEffect(() => {
    const interval = setInterval(() => setTick(t => t + 1), 1000);
    return () => clearInterval(interval);
  }, []);

  const handleEntregar = (solicitudId: string, vigilante: string) => {
    const solicitud = solicitudesPendientes.find(s => s.id === solicitudId);
    if (!solicitud) return;

    entregarLlave(solicitudId, vigilante);
    
    toast({
      title: "Llave entregada",
      description: `${solicitud.lugar.nombre} entregada por ${vigilante}. Tienes 2 minutos para deshacer.`,
    });
  };

  const handleDevolver = (solicitudId: string, vigilante: string) => {
    const solicitud = solicitudesEntregadas.find(s => s.id === solicitudId);
    if (!solicitud) return;

    devolverLlave(solicitudId, vigilante);
    
    toast({
      title: "Llave devuelta",
      description: `${solicitud.lugar.nombre} recibida por ${vigilante}`,
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
        <Button 
          variant="outline" 
          onClick={() => setKeyModalOpen(true)}
          className="gap-2"
        >
          <Settings2 className="w-4 h-4" />
          Gestionar Llaves
        </Button>
      </MonitorHeader>

      <KeyManagementModal
        open={keyModalOpen}
        onOpenChange={setKeyModalOpen}
        lugares={lugaresDisponibles}
        onAgregarLlave={agregarLlave}
        onQuitarLlave={quitarLlave}
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
              {solicitudesPendientes.map(solicitud => {
                const undoAction = getUndoParaSolicitud(solicitud.id);
                return (
                  <SolicitudCard
                    key={solicitud.id}
                    solicitud={solicitud}
                    undoAction={undoAction}
                    onEntregar={(v) => handleEntregar(solicitud.id, v)}
                    onDevolver={(v) => handleDevolver(solicitud.id, v)}
                    onUndo={() => handleUndo(solicitud.id)}
                  />
                );
              })}
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
                  <SolicitudCard
                    key={solicitud.id}
                    solicitud={solicitud}
                    undoAction={undoAction}
                    onEntregar={(v) => handleEntregar(solicitud.id, v)}
                    onDevolver={(v) => handleDevolver(solicitud.id, v)}
                    onUndo={() => handleUndo(solicitud.id)}
                  />
                );
              })}
            </div>
          )}
        </section>
      </main>

      <footer className="py-4 text-center text-sm text-muted-foreground border-t mt-8">
        <p>Monitor de Vigilancia • FCEA UdelaR • Sistema de Gestión de Llaves v3.6</p>
      </footer>
    </div>
  );
}