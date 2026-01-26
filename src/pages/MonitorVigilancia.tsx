import { useState, useEffect } from 'react';
import { MonitorHeader } from '@/components/monitor/MonitorHeader';
import { SolicitudCard } from '@/components/monitor/SolicitudCard';
import { useSolicitudes } from '@/hooks/useSolicitudes';
import { useToast } from '@/hooks/use-toast';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { ScrollArea } from '@/components/ui/scroll-area';
import { ClipboardList, Key, CheckCircle2, AlertCircle } from 'lucide-react';

export default function MonitorVigilancia() {
  const { toast } = useToast();
  const {
    solicitudesPendientes,
    solicitudesEntregadas,
    entregarLlave,
    devolverLlave,
    deshacerAccion,
    getUndoParaSolicitud,
    accionesUndo
  } = useSolicitudes();

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

  // Combinar todas las solicitudes activas para mostrar (con sus undos)
  const todasActivas = [...solicitudesPendientes, ...solicitudesEntregadas]
    .sort((a, b) => b.horaSolicitud.getTime() - a.horaSolicitud.getTime());

  return (
    <div className="min-h-screen bg-background">
      <MonitorHeader 
        pendientes={solicitudesPendientes.length} 
        enUso={solicitudesEntregadas.length} 
      />

      <main className="max-w-7xl mx-auto py-6 px-4">
        <Tabs defaultValue="cola" className="space-y-6">
          <TabsList className="grid w-full max-w-md grid-cols-2">
            <TabsTrigger value="cola" className="gap-2">
              <ClipboardList className="w-4 h-4" />
              Cola de Solicitudes
              {solicitudesPendientes.length > 0 && (
                <Badge variant="secondary" className="ml-1">
                  {solicitudesPendientes.length}
                </Badge>
              )}
            </TabsTrigger>
            <TabsTrigger value="enuso" className="gap-2">
              <Key className="w-4 h-4" />
              Llaves en Uso
              {solicitudesEntregadas.length > 0 && (
                <Badge variant="secondary" className="ml-1 bg-success/20 text-success">
                  {solicitudesEntregadas.length}
                </Badge>
              )}
            </TabsTrigger>
          </TabsList>

          {/* Cola de pendientes */}
          <TabsContent value="cola" className="space-y-4">
            {solicitudesPendientes.length === 0 ? (
              <Card className="p-12 text-center">
                <CheckCircle2 className="w-16 h-16 mx-auto text-success/50 mb-4" />
                <h3 className="text-xl font-semibold mb-2">No hay solicitudes pendientes</h3>
                <p className="text-muted-foreground">
                  Las nuevas solicitudes aparecerán aquí automáticamente
                </p>
              </Card>
            ) : (
              <ScrollArea className="h-[calc(100vh-280px)]">
                <div className="space-y-4 pr-4">
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
              </ScrollArea>
            )}

            {/* Acciones de undo activas */}
            {accionesUndo.length > 0 && (
              <Card className="p-4 bg-warning/5 border-warning/20">
                <div className="flex items-center gap-2 text-warning mb-2">
                  <AlertCircle className="w-5 h-5" />
                  <span className="font-medium">
                    {accionesUndo.length} acción(es) pendiente(s) de deshacer
                  </span>
                </div>
                <p className="text-sm text-muted-foreground">
                  Revise las tarjetas amarillas arriba para deshacer si cometió un error
                </p>
              </Card>
            )}
          </TabsContent>

          {/* Llaves en uso */}
          <TabsContent value="enuso" className="space-y-4">
            {solicitudesEntregadas.length === 0 ? (
              <Card className="p-12 text-center">
                <Key className="w-16 h-16 mx-auto text-muted-foreground/30 mb-4" />
                <h3 className="text-xl font-semibold mb-2">No hay llaves en uso</h3>
                <p className="text-muted-foreground">
                  Las llaves entregadas aparecerán aquí
                </p>
              </Card>
            ) : (
              <ScrollArea className="h-[calc(100vh-280px)]">
                <div className="space-y-4 pr-4">
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
              </ScrollArea>
            )}
          </TabsContent>
        </Tabs>
      </main>

      <footer className="py-4 text-center text-sm text-muted-foreground border-t">
        <p>Monitor de Vigilancia • FCEA UdelaR • Sistema de Gestión de Llaves v3.6</p>
      </footer>
    </div>
  );
}
