import { useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Plus, Trash2, Key, MapPin, Building2, Search, X } from 'lucide-react';
import { 
  Lugar, 
  TipoLugar, 
  TipoTablero,
  ZonaTablero, 
  tiposLugar, 
  tiposTablero,
  zonasTablero, 
  edificios,
  formatearUbicacion,
  normalizarTexto 
} from '@/data/fceaData';
import { useToast } from '@/hooks/use-toast';

interface KeyManagementModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  lugares: Lugar[];
  onAgregarLlave: (lugar: Omit<Lugar, 'id'>) => void;
  onQuitarLlave: (lugarId: string) => void;
}

export function KeyManagementModal({
  open,
  onOpenChange,
  lugares,
  onAgregarLlave,
  onQuitarLlave,
}: KeyManagementModalProps) {
  const { toast } = useToast();
  const [activeTab, setActiveTab] = useState<'agregar' | 'quitar'>('agregar');
  
  // Estado para agregar llave
  const [nombre, setNombre] = useState('');
  const [edificio, setEdificio] = useState('');
  const [tipo, setTipo] = useState<TipoLugar | ''>('');
  const [tablero, setTablero] = useState<TipoTablero>('Tablero Principal');
  const [zona, setZona] = useState<ZonaTablero | ''>('');
  const [fila, setFila] = useState('');
  const [columna, setColumna] = useState('');
  
  // Estado para quitar llave
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedToDelete, setSelectedToDelete] = useState<string | null>(null);

  const resetForm = () => {
    setNombre('');
    setEdificio('');
    setTipo('');
    setTablero('Tablero Principal');
    setZona('');
    setFila('');
    setColumna('');
  };

  const handleAgregar = () => {
    if (!nombre.trim() || !edificio || !tipo || !zona) {
      toast({
        title: "Campos requeridos",
        description: "Complete nombre, edificio, tipo y zona del tablero",
        variant: "destructive"
      });
      return;
    }

    const nuevaLlave: Omit<Lugar, 'id'> = {
      nombre: nombre.trim(),
      edificio,
      tipo: tipo as TipoLugar,
      tablero,
      ubicacion: {
        zona: zona as ZonaTablero,
        fila: fila ? parseInt(fila) : undefined,
        columna: columna.toUpperCase() || undefined,
      },
      disponible: true,
      esHibrido: tipo === 'Salón Híbrido',
    };

    onAgregarLlave(nuevaLlave);
    resetForm();
    
    toast({
      title: "Llave agregada",
      description: `${nombre} se agregó al sistema correctamente`,
    });
  };

  const handleQuitar = () => {
    if (!selectedToDelete) {
      toast({
        title: "Seleccione una llave",
        description: "Debe seleccionar una llave para quitar",
        variant: "destructive"
      });
      return;
    }

    const lugar = lugares.find(l => l.id === selectedToDelete);
    if (lugar) {
      onQuitarLlave(selectedToDelete);
      setSelectedToDelete(null);
      setSearchQuery('');
      
      toast({
        title: "Llave eliminada",
        description: `${lugar.nombre} fue eliminada del sistema`,
      });
    }
  };

  const filteredLugares = searchQuery.trim()
    ? lugares.filter(l => 
        normalizarTexto(l.nombre).includes(normalizarTexto(searchQuery)) ||
        normalizarTexto(l.edificio).includes(normalizarTexto(searchQuery))
      )
    : lugares;

  const zonaRequiereCoords = zona && !['Lateral derecho', 'Lateral izquierdo'].includes(zona);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Key className="w-5 h-5" />
            Gestión de Llaves
          </DialogTitle>
        </DialogHeader>

        <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as 'agregar' | 'quitar')}>
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="agregar" className="gap-2">
              <Plus className="w-4 h-4" />
              Agregar Llave
            </TabsTrigger>
            <TabsTrigger value="quitar" className="gap-2">
              <Trash2 className="w-4 h-4" />
              Quitar Llave
            </TabsTrigger>
          </TabsList>

          <TabsContent value="agregar" className="space-y-4 mt-4">
            {/* Nombre de la llave */}
            <div className="space-y-2">
              <Label htmlFor="nombre">Nombre de la llave *</Label>
              <Input
                id="nombre"
                placeholder="Ej: Salón 301, Oficina Contaduría..."
                value={nombre}
                onChange={(e) => setNombre(e.target.value)}
              />
            </div>

            {/* Edificio y Tipo en fila */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Edificio *</Label>
                <Select value={edificio} onValueChange={setEdificio}>
                  <SelectTrigger>
                    <SelectValue placeholder="Seleccionar edificio" />
                  </SelectTrigger>
                  <SelectContent className="max-h-60 overflow-y-auto">
                    {edificios.map((ed) => (
                      <SelectItem key={ed} value={ed}>{ed}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>Tipo de lugar *</Label>
                <Select value={tipo} onValueChange={(v) => setTipo(v as TipoLugar)}>
                  <SelectTrigger>
                    <SelectValue placeholder="Seleccionar tipo" />
                  </SelectTrigger>
                  <SelectContent className="max-h-60 overflow-y-auto">
                    {tiposLugar.map((t) => (
                      <SelectItem key={t} value={t}>{t}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            {/* Ubicación en tablero */}
            <div className="space-y-3 p-4 border rounded-lg bg-muted/30">
              <div className="flex items-center gap-2 text-sm font-medium">
                <MapPin className="w-4 h-4" />
                Ubicación en el Tablero
              </div>

              <div className="space-y-2">
                <Label>Tablero *</Label>
                <Select value={tablero} onValueChange={(v) => setTablero(v as TipoTablero)}>
                  <SelectTrigger>
                    <SelectValue placeholder="Seleccionar tablero" />
                  </SelectTrigger>
                  <SelectContent className="max-h-60 overflow-y-auto">
                    {tiposTablero.map((t) => (
                      <SelectItem key={t} value={t}>{t}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>Zona del tablero *</Label>
                <Select value={zona} onValueChange={(v) => setZona(v as ZonaTablero)}>
                  <SelectTrigger>
                    <SelectValue placeholder="Seleccionar zona" />
                  </SelectTrigger>
                  <SelectContent className="max-h-60 overflow-y-auto">
                    {zonasTablero.map((z) => (
                      <SelectItem key={z} value={z}>{z}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {zonaRequiereCoords && (
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="fila">Fila (número)</Label>
                    <Input
                      id="fila"
                      type="number"
                      min="1"
                      max="20"
                      placeholder="Ej: 5"
                      value={fila}
                      onChange={(e) => setFila(e.target.value)}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="columna">Columna (letra)</Label>
                    <Input
                      id="columna"
                      placeholder="Ej: A, B, C..."
                      maxLength={2}
                      value={columna}
                      onChange={(e) => setColumna(e.target.value.toUpperCase())}
                    />
                  </div>
                </div>
              )}
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => onOpenChange(false)}>
                Cancelar
              </Button>
              <Button onClick={handleAgregar} className="gap-2">
                <Plus className="w-4 h-4" />
                Agregar Llave
              </Button>
            </DialogFooter>
          </TabsContent>

          <TabsContent value="quitar" className="space-y-4 mt-4">
            {/* Búsqueda */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                placeholder="Buscar llave por nombre o edificio..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9"
              />
              {searchQuery && (
                <Button
                  variant="ghost"
                  size="icon"
                  className="absolute right-1 top-1/2 -translate-y-1/2 h-7 w-7"
                  onClick={() => setSearchQuery('')}
                >
                  <X className="w-4 h-4" />
                </Button>
              )}
            </div>

            {/* Lista de llaves */}
            <ScrollArea className="h-[300px] pr-4">
              <div className="space-y-2">
                {filteredLugares.length === 0 ? (
                  <div className="text-center py-8 text-muted-foreground">
                    {searchQuery ? 'No se encontraron llaves' : 'No hay llaves registradas'}
                  </div>
                ) : (
                  filteredLugares.map((lugar) => (
                    <Card
                      key={lugar.id}
                      className={`p-3 cursor-pointer transition-all ${
                        selectedToDelete === lugar.id
                          ? 'ring-2 ring-destructive bg-destructive/5'
                          : 'hover:bg-muted/50'
                      }`}
                      onClick={() => setSelectedToDelete(
                        selectedToDelete === lugar.id ? null : lugar.id
                      )}
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <Key className="w-4 h-4 text-muted-foreground" />
                          <div>
                            <div className="font-medium">{lugar.nombre}</div>
                            <div className="text-xs text-muted-foreground flex items-center gap-2">
                              <Building2 className="w-3 h-3" />
                              {lugar.edificio} • {lugar.tipo}
                            </div>
                          </div>
                        </div>
                        <div className="text-right">
                          <Badge variant="outline" className="text-xs">
                            <MapPin className="w-3 h-3 mr-1" />
                            {formatearUbicacion(lugar.ubicacion)}
                          </Badge>
                        </div>
                      </div>
                    </Card>
                  ))
                )}
              </div>
            </ScrollArea>

            <DialogFooter>
              <Button variant="outline" onClick={() => onOpenChange(false)}>
                Cancelar
              </Button>
              <Button 
                variant="destructive" 
                onClick={handleQuitar}
                disabled={!selectedToDelete}
                className="gap-2"
              >
                <Trash2 className="w-4 h-4" />
                Quitar Llave
              </Button>
            </DialogFooter>
          </TabsContent>
        </Tabs>
      </DialogContent>
    </Dialog>
  );
}
