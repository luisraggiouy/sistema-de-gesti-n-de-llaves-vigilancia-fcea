import { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Card } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Vigilante, Turno, EstadoLicencia, DiaSemana, estadosLicencia, diasSemanaLabels } from '@/data/fceaData';
import { UserPlus, Trash2, Crown, Sun, Sunset, Moon, Maximize2, Minimize2, CheckCircle2, Palmtree, Stethoscope, Calendar } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { ConfirmarAccionSensible } from '@/components/ConfirmarAccionSensible';

interface GuardManagementModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  vigilantes: Vigilante[];
  onAgregar: (nombre: string, turno: Turno, esJefe: boolean) => void;
  onEliminar: (vigilanteId: string) => void;
  onActualizar: (vigilanteId: string, datos: Partial<Omit<Vigilante, 'id'>>) => void;
}

const turnoIcons = {
  'Matutino': Sun,
  'Vespertino': Sunset,
  'Nocturno': Moon
};

export function GuardManagementModal({
  open,
  onOpenChange,
  vigilantes,
  onAgregar,
  onEliminar,
  onActualizar
}: GuardManagementModalProps) {
  const { toast } = useToast();
  const [nuevoNombre, setNuevoNombre] = useState('');
  const [nuevoTurno, setNuevoTurno] = useState<Turno>('Matutino');
  const [esJefe, setEsJefe] = useState(false);
  const [maximizado, setMaximizado] = useState(false);
  const [cambiosRealizados, setCambiosRealizados] = useState(0);

  // v2.8 (2026-07-23): estado para el modal `ConfirmarAccionSensible`
  // al borrar vigilante. Los switches de licencia/jefe/dias son
  // reversibles con un clic y quedan fuera del alcance del modal.
  const [confirmDeleteVigilante, setConfirmDeleteVigilante] = useState<Vigilante | null>(null);

  const handleAgregar = async () => {
    if (!nuevoNombre.trim()) return;
    const nombreParaMostrar = nuevoNombre.trim();
    const turnoParaMostrar = nuevoTurno;
    // v2.8.2 (2026-07-24): esperar a que el backend confirme la creacion
    // ANTES de mostrar el toast de exito. Antes se disparaba el toast
    // sincronicamente aunque el `create` de PocketBase todavia no
    // hubiera retornado (o hubiera fallado), lo cual explicaba el
    // sintoma: "aparece el mensaje verde pero no aparece en la lista".
    try {
      await onAgregar(nombreParaMostrar, turnoParaMostrar, esJefe);
      setNuevoNombre('');
      setEsJefe(false);
      setCambiosRealizados(prev => prev + 1);
      toast({
        title: "Vigilante agregado",
        description: `${nombreParaMostrar} fue agregado al turno ${turnoParaMostrar}`,
      });
    } catch (e) {
      console.error('Error al agregar vigilante:', e);
      toast({
        title: "Error al agregar vigilante",
        description: "No se pudo guardar. Verificá la conexión con el servidor e intentá nuevamente.",
        variant: "destructive",
      });
    }
  };


  // v2.8 (2026-07-23): `handleEliminar` ahora solo abre el modal
  // intimidatorio. El borrado real vive en `confirmarEliminar`.
  const handleEliminar = (v: Vigilante) => {
    setConfirmDeleteVigilante(v);
  };

  const confirmarEliminar = () => {
    const v = confirmDeleteVigilante;
    if (!v) return;
    onEliminar(v.id);
    setCambiosRealizados(prev => prev + 1);
    toast({
      title: "Vigilante eliminado",
      description: `${v.nombre} fue removido del turno ${v.turno}`,
      variant: "destructive",
    });
  };

  const handleListo = () => {
    if (cambiosRealizados > 0) {
      toast({
        title: "Cambios guardados",
        description: `Se realizaron ${cambiosRealizados} cambio${cambiosRealizados !== 1 ? 's' : ''} en el equipo de vigilancia`,
      });
    }
    setCambiosRealizados(0);
    onOpenChange(false);
  };

  const vigilantesPorTurno = (turno: Turno) =>
    vigilantes.filter(v => v.turno === turno);

  const renderVigilantesList = (turno: Turno) => {
    const lista = vigilantesPorTurno(turno);
    const TurnoIcon = turnoIcons[turno];

    return (
      <div className="space-y-2">
        <div className="flex items-center gap-2 mb-3">
          <TurnoIcon className="w-5 h-5" />
          <span className="font-medium">{turno}</span>
          <Badge variant="secondary">{lista.length} vigilantes</Badge>
        </div>

        {lista.length === 0 ? (
          <p className="text-sm text-muted-foreground text-center py-4">
            No hay vigilantes registrados en este turno
          </p>
        ) : (
          <div className="space-y-2">
            {lista.map(v => (
              <Card key={v.id} className={`p-3 ${v.estadoLicencia && v.estadoLicencia !== 'activo' ? 'opacity-60 bg-muted/50' : ''}`}>
                {/* Fila superior: nombre + controles */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2 flex-wrap">
                    {v.esJefe && <Crown className="w-4 h-4 text-warning" />}
                    <span className="font-medium">{v.nombre}</span>
                    {v.esJefe && (
                      <Badge className="bg-warning/20 text-warning border-warning/30 text-xs">
                        Jefe de turno
                      </Badge>
                    )}
                    {v.estadoLicencia === 'licencia' && (
                      <Badge variant="outline" className="text-xs border-amber-300 text-amber-700 gap-1">
                        <Palmtree className="w-3 h-3" />
                        Licencia
                      </Badge>
                    )}
                    {v.estadoLicencia === 'licencia_medica' && (
                      <Badge variant="outline" className="text-xs border-red-300 text-red-700 gap-1">
                        <Stethoscope className="w-3 h-3" />
                        Lic. Médica
                      </Badge>
                    )}
                  </div>
                  <div className="flex items-center gap-2">
                    {/* Selector de licencia */}
                    <Select
                      value={v.estadoLicencia || 'activo'}
                      onValueChange={(val) => {
                        onActualizar(v.id, { estadoLicencia: val as EstadoLicencia });
                        setCambiosRealizados(prev => prev + 1);
                      }}
                    >
                      <SelectTrigger className="h-8 w-[120px] text-xs">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {estadosLicencia.map(e => (
                          <SelectItem key={e.value} value={e.value}>{e.label}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <div className="flex items-center gap-2">
                      <Label htmlFor={`jefe-${v.id}`} className="text-xs text-muted-foreground">
                        Jefe
                      </Label>
                      <Switch
                        id={`jefe-${v.id}`}
                        checked={v.esJefe}
                        onCheckedChange={(checked) => {
                          onActualizar(v.id, { esJefe: checked });
                          setCambiosRealizados(prev => prev + 1);
                        }}
                      />
                    </div>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-destructive hover:text-destructive hover:bg-destructive/10"
                      onClick={() => handleEliminar(v)}
                    >
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </div>
                </div>

                {/* Fila inferior: selector de días laborales */}
                <div className="mt-2 pt-2 border-t border-dashed border-muted-foreground/20">
                  <div className="flex items-center gap-2 flex-wrap">
                    <Calendar className="w-3 h-3 text-muted-foreground shrink-0" />
                    <span className="text-xs text-muted-foreground shrink-0">Días de trabajo:</span>
                    <div className="flex gap-1 flex-wrap">
                      {diasSemanaLabels.map(dia => {
                        const activo = !v.diasLaborales || v.diasLaborales.length === 0
                          ? true
                          : v.diasLaborales.includes(dia.value);
                        const esFinde = dia.value === 0 || dia.value === 6;
                        return (
                          <button
                            key={dia.value}
                            type="button"
                            title={dia.label}
                            onClick={() => {
                              // Calcular nuevo array de días
                              const actual: DiaSemana[] = v.diasLaborales && v.diasLaborales.length > 0
                                ? [...v.diasLaborales]
                                : [1, 2, 3, 4, 5, 6, 0] as DiaSemana[];
                              const nuevo = actual.includes(dia.value)
                                ? actual.filter(d => d !== dia.value)
                                : [...actual, dia.value].sort() as DiaSemana[];
                              // Si todos los días están activos, guardar undefined (trabaja todos)
                              const todosActivos = nuevo.length === 7;
                              onActualizar(v.id, { diasLaborales: todosActivos ? undefined : nuevo });
                              setCambiosRealizados(prev => prev + 1);
                            }}
                            className={`w-7 h-7 rounded-full text-[10px] font-bold border transition-colors ${
                              activo
                                ? esFinde
                                  ? 'bg-orange-100 border-orange-400 text-orange-700'
                                  : 'bg-blue-100 border-blue-400 text-blue-700'
                                : 'bg-muted border-muted-foreground/20 text-muted-foreground line-through'
                            }`}
                          >
                            {dia.abrev}
                          </button>
                        );
                      })}
                    </div>
                    {v.diasLaborales && v.diasLaborales.length > 0 && v.diasLaborales.length < 7 && (
                      <span className="text-xs text-muted-foreground ml-1">
                        ({v.diasLaborales.length} días/sem)
                      </span>
                    )}
                    {(!v.diasLaborales || v.diasLaborales.length === 0 || v.diasLaborales.length === 7) && (
                      <span className="text-xs text-green-600 ml-1">Todos los días</span>
                    )}
                  </div>
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>
    );
  };

  return (
    <Dialog open={open} onOpenChange={(v) => { if (!v) handleListo(); else onOpenChange(v); }}>
      <DialogContent
        className={`flex flex-col ${
          maximizado
            ? 'max-w-[95vw] max-h-[95vh] w-[95vw] h-[95vh]'
            : 'max-w-2xl max-h-[85vh]'
        }`}
      >
        <DialogHeader>
          <div className="flex items-center justify-between">
            <div>
              <DialogTitle>Gestión de Vigilantes</DialogTitle>
              <DialogDescription>
                Administrar el personal de vigilancia por turno
              </DialogDescription>
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setMaximizado(!maximizado)}
              className="mr-8"
              title={maximizado ? 'Minimizar' : 'Maximizar'}
            >
              {maximizado ? <Minimize2 className="w-5 h-5" /> : <Maximize2 className="w-5 h-5" />}
            </Button>
          </div>
        </DialogHeader>

        {/* Formulario para agregar */}
        <Card className="p-4 bg-muted/30 shrink-0">
          <h4 className="font-medium mb-3 flex items-center gap-2">
            <UserPlus className="w-4 h-4" />
            Agregar Vigilante
          </h4>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-3">
            <div className="md:col-span-2">
              <Label htmlFor="nombre">Nombre</Label>
              <Input
                id="nombre"
                placeholder="Nombre del vigilante"
                value={nuevoNombre}
                onChange={(e) => setNuevoNombre(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleAgregar()}
              />
            </div>
            <div>
              <Label>Turno</Label>
              <div className="flex gap-1 mt-1">
                {(['Matutino', 'Vespertino', 'Nocturno'] as Turno[]).map(t => {
                  const Icon = turnoIcons[t];
                  return (
                    <Button
                      key={t}
                      variant={nuevoTurno === t ? 'default' : 'outline'}
                      size="sm"
                      className="flex-1"
                      onClick={() => setNuevoTurno(t)}
                      title={t}
                    >
                      <Icon className="w-4 h-4" />
                    </Button>
                  );
                })}
              </div>
            </div>
            <div className="flex flex-col justify-end">
              <div className="flex items-center gap-2 mb-2">
                <Switch
                  id="esJefe"
                  checked={esJefe}
                  onCheckedChange={setEsJefe}
                />
                <Label htmlFor="esJefe" className="text-sm">Es jefe de turno</Label>
              </div>
              <Button onClick={handleAgregar} className="w-full">
                <UserPlus className="w-4 h-4 mr-2" />
                Agregar
              </Button>
            </div>
          </div>
        </Card>

        {/* Lista por turnos - scrollable */}
        <div className="flex-1 overflow-y-auto min-h-0">
          <Tabs defaultValue="Matutino">
            <TabsList className="grid grid-cols-3 sticky top-0 z-10">
              {(['Matutino', 'Vespertino', 'Nocturno'] as Turno[]).map(t => {
                const Icon = turnoIcons[t];
                return (
                  <TabsTrigger key={t} value={t} className="gap-2">
                    <Icon className="w-4 h-4" />
                    <span className="hidden sm:inline">{t}</span>
                    <Badge variant="secondary" className="ml-1">
                      {vigilantesPorTurno(t).length}
                    </Badge>
                  </TabsTrigger>
                );
              })}
            </TabsList>

            {(['Matutino', 'Vespertino', 'Nocturno'] as Turno[]).map(t => (
              <TabsContent key={t} value={t} className="mt-4">
                {renderVigilantesList(t)}
              </TabsContent>
            ))}
          </Tabs>
        </div>

        {/* Footer con botón Listo */}
        <DialogFooter className="shrink-0 border-t pt-4">
          {cambiosRealizados > 0 && (
            <span className="text-sm text-muted-foreground mr-auto">
              {cambiosRealizados} cambio{cambiosRealizados !== 1 ? 's' : ''} realizado{cambiosRealizados !== 1 ? 's' : ''}
            </span>
          )}
          <Button onClick={handleListo} className="gap-2">
            <CheckCircle2 className="w-4 h-4" />
            Listo
          </Button>
        </DialogFooter>
      </DialogContent>

      {/* v2.8 (2026-07-23): modal `ConfirmarAccionSensible` para
          proteger el borrado de vigilantes. */}
      <ConfirmarAccionSensible
        open={!!confirmDeleteVigilante}
        onOpenChange={(v) => { if (!v) setConfirmDeleteVigilante(null); }}
        tipoAccion="borrar"
        entidad="vigilante"
        detalle={
          confirmDeleteVigilante
            ? `${confirmDeleteVigilante.nombre} — ${confirmDeleteVigilante.turno}`
            : undefined
        }
        descripcionExtra={
          "Vas a eliminar este vigilante del equipo. Perdera su turno, su rol de jefe (si lo tenia) y su configuracion de dias laborales. Las solicitudes historicas que este vigilante haya gestionado se mantienen, pero ya no aparecera en el listado de personal activo. Esta accion NO se puede deshacer."
        }
        onConfirmar={() => {
          confirmarEliminar();
          setConfirmDeleteVigilante(null);
        }}
      />
    </Dialog>
  );
}
