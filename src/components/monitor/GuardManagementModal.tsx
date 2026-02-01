import { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Card } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Switch } from '@/components/ui/switch';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Vigilante, Turno } from '@/data/fceaData';
import { UserPlus, Trash2, Crown, Sun, Sunset, Moon } from 'lucide-react';

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

const turnoColors = {
  'Matutino': 'bg-amber-100 text-amber-800',
  'Vespertino': 'bg-orange-100 text-orange-800',
  'Nocturno': 'bg-indigo-100 text-indigo-800'
};

export function GuardManagementModal({
  open,
  onOpenChange,
  vigilantes,
  onAgregar,
  onEliminar,
  onActualizar
}: GuardManagementModalProps) {
  const [nuevoNombre, setNuevoNombre] = useState('');
  const [nuevoTurno, setNuevoTurno] = useState<Turno>('Matutino');
  const [esJefe, setEsJefe] = useState(false);

  const handleAgregar = () => {
    if (!nuevoNombre.trim()) return;
    onAgregar(nuevoNombre.trim(), nuevoTurno, esJefe);
    setNuevoNombre('');
    setEsJefe(false);
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
          <ScrollArea className="h-[200px]">
            <div className="space-y-2 pr-4">
              {lista.map(v => (
                <Card key={v.id} className="p-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                    {v.esJefe && (
                      <Crown className="w-4 h-4 text-warning" />
                    )}
                    <span className="font-medium">{v.nombre}</span>
                    {v.esJefe && (
                      <Badge className="bg-warning/20 text-warning border-warning/30 text-xs">
                        Jefe de turno
                      </Badge>
                    )}
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="flex items-center gap-2">
                        <Label htmlFor={`jefe-${v.id}`} className="text-xs text-muted-foreground">
                          Jefe
                        </Label>
                        <Switch
                          id={`jefe-${v.id}`}
                          checked={v.esJefe}
                          onCheckedChange={(checked) => onActualizar(v.id, { esJefe: checked })}
                        />
                      </div>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8 text-destructive hover:text-destructive hover:bg-destructive/10"
                        onClick={() => onEliminar(v.id)}
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          </ScrollArea>
        )}
      </div>
    );
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[85vh] overflow-hidden flex flex-col">
        <DialogHeader>
          <DialogTitle>Gestión de Vigilantes</DialogTitle>
          <DialogDescription>
            Administrar el personal de vigilancia por turno
          </DialogDescription>
        </DialogHeader>

        {/* Formulario para agregar */}
        <Card className="p-4 bg-muted/30">
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

        {/* Lista por turnos */}
        <Tabs defaultValue="Matutino" className="flex-1 overflow-hidden">
          <TabsList className="grid grid-cols-3">
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
      </DialogContent>
    </Dialog>
  );
}
