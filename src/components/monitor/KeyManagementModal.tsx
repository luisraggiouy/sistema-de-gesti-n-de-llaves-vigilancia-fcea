import { useState, useEffect } from 'react';
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
import { Plus, Trash2, Key, MapPin, Building2, Search, X, Pencil, Save } from 'lucide-react';
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
  normalizarTexto,
  ordenNatural 
} from '@/data/fceaData';
import { useToast } from '@/hooks/use-toast';

interface KeyManagementModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  lugares: Lugar[];
  onAgregarLlave: (lugar: Omit<Lugar, 'id'>) => void;
  onQuitarLlave: (lugarId: string) => void;
  onModificarLlave: (lugarId: string, datos: Partial<Lugar>) => Promise<void>;
}

export function KeyManagementModal({
  open,
  onOpenChange,
  lugares,
  onAgregarLlave,
  onQuitarLlave,
  onModificarLlave,
}: KeyManagementModalProps) {
  const { toast } = useToast();
  const [activeTab, setActiveTab] = useState<'agregar' | 'quitar' | 'modificar'>('agregar');
  
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
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  // Estado para modificar llave
  const [searchModQuery, setSearchModQuery] = useState('');
  const [selectedToEdit, setSelectedToEdit] = useState<string | null>(null);
  const [editNombre, setEditNombre] = useState('');
  const [editEdificio, setEditEdificio] = useState('');
  const [editTipo, setEditTipo] = useState<TipoLugar | ''>('');
  const [editTablero, setEditTablero] = useState<TipoTablero>('Tablero Principal');
  const [editZona, setEditZona] = useState<ZonaTablero | ''>('');
  const [editFila, setEditFila] = useState('');
  const [editColumna, setEditColumna] = useState('');
  const [isSaving, setIsSaving] = useState(false);

  // When a key is selected for editing, populate the form (only on selection change)
  useEffect(() => {
    if (selectedToEdit) {
      const lugar = lugares.find(l => l.id === selectedToEdit);
      if (lugar) {
        setEditNombre(lugar.nombre);
        setEditEdificio(lugar.edificio);
        setEditTipo(lugar.tipo);
        setEditTablero(lugar.tablero);
        setEditZona(lugar.ubicacion.zona);
        setEditFila(lugar.ubicacion.fila?.toString() ?? '');
        setEditColumna(lugar.ubicacion.columna ?? '');
      }
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedToEdit]);

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

  const handleModificar = async () => {
    if (!selectedToEdit || !editNombre.trim() || !editEdificio || !editTipo || !editZona) {
      toast({
        title: "Campos requeridos",
        description: "Complete nombre, edificio, tipo y zona del tablero",
        variant: "destructive"
      });
      return;
    }

    setIsSaving(true);
    try {
      await onModificarLlave(selectedToEdit, {
        nombre: editNombre.trim(),
        edificio: editEdificio,
        tipo: editTipo as TipoLugar,
        tablero: editTablero,
        ubicacion: {
          zona: editZona as ZonaTablero,
          fila: editFila ? parseInt(editFila) : undefined,
          columna: editColumna.toUpperCase() || undefined,
        },
        esHibrido: editTipo === 'Salón Híbrido',
      });

      toast({
        title: "Llave modificada",
        description: `${editNombre} se actualizó correctamente`,
      });
      setSelectedToEdit(null);
      setSearchModQuery('');
    } catch (e) {
      toast({
        title: "Error al modificar",
        description: "No se pudo actualizar la llave",
        variant: "destructive"
      });
    } finally {
      setIsSaving(false);
    }
  };

  const filteredLugares = (searchQuery.trim()
    ? lugares.filter(l => 
        normalizarTexto(l.nombre).includes(normalizarTexto(searchQuery)) ||
        normalizarTexto(l.edificio).includes(normalizarTexto(searchQuery))
      )
    : [...lugares]
  ).sort((a, b) => ordenNatural(a.nombre, b.nombre));

  const filteredLugaresMod = (searchModQuery.trim()
    ? lugares.filter(l => 
        normalizarTexto(l.nombre).includes(normalizarTexto(searchModQuery)) ||
        normalizarTexto(l.edificio).includes(normalizarTexto(searchModQuery))
      )
    : [...lugares]
  ).sort((a, b) => ordenNatural(a.nombre, b.nombre));

  const zonaRequiereCoords = zona && !['Lateral derecho', 'Lateral izquierdo'].includes(zona);
  const editZonaPuedeCoords = editZona && !['Lateral derecho', 'Lateral izquierdo'].includes(editZona);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Key className="w-5 h-5" />
            Gestión de Llaves
          </DialogTitle>
        </DialogHeader>

        <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as 'agregar' | 'quitar' | 'modificar')}>
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="agregar" className="gap-2 data-[state=active]:bg-blue-600 data-[state=active]:text-white">
              <Plus className="w-4 h-4" />
              Agregar
            </TabsTrigger>
            <TabsTrigger value="modificar" className="gap-2 data-[state=active]:bg-blue-600 data-[state=active]:text-white">
              <Pencil className="w-4 h-4" />
              Modificar
            </TabsTrigger>
            <TabsTrigger value="quitar" className="gap-2 data-[state=active]:bg-blue-600 data-[state=active]:text-white">
              <Trash2 className="w-4 h-4" />
              Quitar
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

          {/* ===== MODIFICAR TAB ===== */}
          <TabsContent value="modificar" className="space-y-4 mt-4">
            {!selectedToEdit ? (
              <>
                {/* Search to select key to edit */}
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                  <Input
                    placeholder="Buscar llave para modificar..."
                    value={searchModQuery}
                    onChange={(e) => setSearchModQuery(e.target.value)}
                    className="pl-9"
                  />
                  {searchModQuery && (
                    <Button
                      variant="ghost"
                      size="icon"
                      className="absolute right-1 top-1/2 -translate-y-1/2 h-7 w-7"
                      onClick={() => setSearchModQuery('')}
                    >
                      <X className="w-4 h-4" />
                    </Button>
                  )}
                </div>

                <ScrollArea className="h-[350px] pr-4">
                  <div className="space-y-2">
                    {filteredLugaresMod.length === 0 ? (
                      <div className="text-center py-8 text-muted-foreground">
                        {searchModQuery ? 'No se encontraron llaves' : 'No hay llaves registradas'}
                      </div>
                    ) : (
                      filteredLugaresMod.map((lugar) => (
                        <Card
                          key={lugar.id}
                          className="p-3 cursor-pointer transition-all hover:bg-muted/50 hover:border-primary/50"
                          onClick={() => setSelectedToEdit(lugar.id)}
                        >
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                              <Pencil className="w-4 h-4 text-muted-foreground" />
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
              </>
            ) : (
              <>
                {/* Edit form */}
                <div className="flex items-center justify-between mb-2">
                  <h3 className="text-sm font-medium text-muted-foreground">Editando llave:</h3>
                  <Button variant="ghost" size="sm" onClick={() => setSelectedToEdit(null)} className="gap-1">
                    <X className="w-4 h-4" />
                    Cancelar edición
                  </Button>
                </div>

                <div className="space-y-2">
                  <Label>Nombre de la llave *</Label>
                  <Input
                    value={editNombre}
                    onChange={(e) => setEditNombre(e.target.value)}
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Edificio *</Label>
                    <Select value={editEdificio} onValueChange={setEditEdificio}>
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
                    <Select value={editTipo} onValueChange={(v) => setEditTipo(v as TipoLugar)}>
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

                <div className="space-y-3 p-4 border rounded-lg bg-muted/30">
                  <div className="flex items-center gap-2 text-sm font-medium">
                    <MapPin className="w-4 h-4" />
                    Ubicación en el Tablero
                  </div>

                  <div className="space-y-2">
                    <Label>Tablero *</Label>
                    <Select value={editTablero} onValueChange={(v) => setEditTablero(v as TipoTablero)}>
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
                    <Select value={editZona} onValueChange={(v) => setEditZona(v as ZonaTablero)}>
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

                  {editZonaPuedeCoords && (
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <Label>Fila (número)</Label>
                        <Input
                          type="number"
                          min="1"
                          max="20"
                          placeholder="Ej: 5"
                          value={editFila}
                          onChange={(e) => setEditFila(e.target.value)}
                        />
                      </div>
                      <div className="space-y-2">
                        <Label>Columna (letra)</Label>
                        <Input
                          placeholder="Ej: A, B, C..."
                          maxLength={2}
                          value={editColumna}
                          onChange={(e) => setEditColumna(e.target.value.toUpperCase())}
                        />
                      </div>
                    </div>
                  )}
                </div>

                <DialogFooter>
                  <Button variant="outline" onClick={() => setSelectedToEdit(null)}>
                    Cancelar
                  </Button>
                  <Button onClick={handleModificar} disabled={isSaving} className="gap-2">
                    <Save className="w-4 h-4" />
                    {isSaving ? 'Guardando...' : 'Guardar Cambios'}
                  </Button>
                </DialogFooter>
              </>
            )}
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

            {/* Confirmation banner */}
            {showDeleteConfirm && selectedToDelete && (
              <div className="p-4 bg-destructive/10 border border-destructive/30 rounded-lg space-y-3">
                <p className="text-sm font-medium text-destructive">
                  ⚠️ ¿Está seguro de eliminar la llave "{lugares.find(l => l.id === selectedToDelete)?.nombre}"?
                </p>
                <p className="text-xs text-muted-foreground">
                  Esta acción es permanente y no se puede deshacer. La llave será eliminada del sistema por completo. Quedará un registro horario de la hora en que se eliminó esta llave del listado.
                </p>
                <div className="flex gap-2 justify-end">
                  <Button variant="outline" size="sm" onClick={() => setShowDeleteConfirm(false)}>
                    No, cancelar
                  </Button>
                  <Button variant="destructive" size="sm" className="gap-1" onClick={() => {
                    handleQuitar();
                    setShowDeleteConfirm(false);
                  }}>
                    <Trash2 className="w-3.5 h-3.5" />
                    Sí, eliminar
                  </Button>
                </div>
              </div>
            )}

            <DialogFooter>
              <Button variant="outline" onClick={() => onOpenChange(false)}>
                Cancelar
              </Button>
              <Button 
                variant="destructive" 
                onClick={() => {
                  if (!selectedToDelete) {
                    toast({ title: "Seleccione una llave", description: "Debe seleccionar una llave para quitar", variant: "destructive" });
                    return;
                  }
                  setShowDeleteConfirm(true);
                }}
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
