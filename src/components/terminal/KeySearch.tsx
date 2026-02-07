import { useState, useMemo } from 'react';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { 
  tiposLugar, 
  edificios, 
  Lugar, 
  TipoLugar,
  normalizarTexto
} from '@/data/fceaData';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';
import { Search, Building2, Check, AlertTriangle, Lock, CheckSquare, ArrowRightLeft, User } from 'lucide-react';
import { cn } from '@/lib/utils';

interface KeySearchProps {
  selectedKeys: Lugar[];
  onToggleKey: (lugar: Lugar) => void;
  onExchangeRequest?: (lugar: Lugar, usuarioConLlave: { nombre: string; celular: string; tipo: string }) => void;
}

export function KeySearch({ selectedKeys, onToggleKey, onExchangeRequest }: KeySearchProps) {
  const { lugaresDisponibles, solicitudesEntregadas } = useSolicitudesContext();
  const [busqueda, setBusqueda] = useState('');
  const [filtroTipo, setFiltroTipo] = useState<TipoLugar | 'todos'>('todos');
  const [filtroEdificio, setFiltroEdificio] = useState<string>('todos');

  const lugaresFiltrados = useMemo(() => {
    const busquedaNormalizada = normalizarTexto(busqueda);
    
    return lugaresDisponibles.filter((lugar) => {
      // Filtro de búsqueda (insensible a acentos)
      const nombreNormalizado = normalizarTexto(lugar.nombre);
      const tipoNormalizado = normalizarTexto(lugar.tipo);
      const coincideBusqueda = 
        nombreNormalizado.includes(busquedaNormalizada) ||
        tipoNormalizado.includes(busquedaNormalizada);
      
      // Filtro de tipo
      const coincideTipo = filtroTipo === 'todos' || lugar.tipo === filtroTipo;
      
      // Filtro de edificio
      const coincideEdificio = filtroEdificio === 'todos' || lugar.edificio === filtroEdificio;
      
      return coincideBusqueda && coincideTipo && coincideEdificio;
    });
  }, [busqueda, filtroTipo, filtroEdificio, lugaresDisponibles]);

  const isSelected = (lugarId: string) => selectedKeys.some(k => k.id === lugarId);

  const getTipoColor = (tipo: TipoLugar): string => {
    const colores: Record<TipoLugar, string> = {
      'Salón': 'bg-blue-100 text-blue-800 border-blue-200',
      'Salón Híbrido': 'bg-rose-100 text-rose-800 border-rose-200',
      'Oficina': 'bg-emerald-100 text-emerald-800 border-emerald-200',
      'Sala': 'bg-violet-100 text-violet-800 border-violet-200',
      'Depósito': 'bg-slate-100 text-slate-800 border-slate-200',
      'Baño': 'bg-cyan-100 text-cyan-800 border-cyan-200',
      'Área Común': 'bg-amber-100 text-amber-800 border-amber-200',
      'Biblioteca': 'bg-purple-100 text-purple-800 border-purple-200',
      'Auditorio': 'bg-orange-100 text-orange-800 border-orange-200'
    };
    return colores[tipo] || 'bg-muted text-muted-foreground';
  };

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-foreground flex items-center gap-2">
          <Search className="w-5 h-5 text-primary" />
          Buscar Llaves
        </h2>
        {selectedKeys.length > 0 && (
          <Badge variant="default" className="gap-1">
            <CheckSquare className="w-3.5 h-3.5" />
            {selectedKeys.length} seleccionada(s)
          </Badge>
        )}
      </div>

      {/* Filtros */}
      <div className="space-y-3">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
          <Input
            placeholder="Buscar por nombre o tipo..."
            value={busqueda}
            onChange={(e) => setBusqueda(e.target.value)}
            className="pl-10 h-12 text-lg"
          />
        </div>
        
        <div className="flex gap-3">
          <Select value={filtroTipo} onValueChange={(val) => setFiltroTipo(val as TipoLugar | 'todos')}>
            <SelectTrigger className="flex-1">
              <SelectValue placeholder="Tipo" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Todos los tipos</SelectItem>
              {tiposLugar.map((tipo) => (
                <SelectItem key={tipo} value={tipo}>{tipo}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          
          <Select value={filtroEdificio} onValueChange={setFiltroEdificio}>
            <SelectTrigger className="flex-1">
              <SelectValue placeholder="Edificio" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="todos">Todos los edificios</SelectItem>
              {edificios.map((ed) => (
                <SelectItem key={ed} value={ed}>{ed}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Lista de llaves */}
      <div className="space-y-2 max-h-80 overflow-y-auto pr-1">
        {lugaresFiltrados.length === 0 ? (
          <p className="text-center text-muted-foreground py-8">
            No se encontraron llaves con esos criterios
          </p>
        ) : (
          lugaresFiltrados.map((lugar) => {
            const selected = isSelected(lugar.id);
            // Check if key is dynamically in use via active solicitudes
            const solicitudEnUso = solicitudesEntregadas.find(s => s.lugar.id === lugar.id) || null;
            const estaEnUso = !!solicitudEnUso;

            return (
              <Card
                key={lugar.id}
                onClick={() => !estaEnUso && onToggleKey(lugar)}
                className={cn(
                  "p-4 transition-all duration-200",
                  !estaEnUso && "cursor-pointer",
                  estaEnUso && !onExchangeRequest && "opacity-60 cursor-not-allowed",
                  estaEnUso && onExchangeRequest && "cursor-default",
                  selected 
                    ? "ring-2 ring-primary bg-primary/5 border-primary" 
                    : !estaEnUso ? "hover:bg-muted/50 hover:border-primary/50" : ""
                )}
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center gap-3">
                    {/* Checkbox visual */}
                    <div className={cn(
                      "flex-shrink-0 w-5 h-5 rounded border-2 flex items-center justify-center transition-colors",
                      selected 
                        ? "bg-primary border-primary text-primary-foreground" 
                        : "border-muted-foreground/30",
                      estaEnUso && "opacity-30"
                    )}>
                      {selected && <Check className="w-3.5 h-3.5" />}
                    </div>
                    
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="font-semibold text-foreground truncate">
                          {lugar.nombre}
                        </span>
                        {lugar.esHibrido && (
                          <Lock className="w-4 h-4 text-salon-hibrido flex-shrink-0" />
                        )}
                      </div>
                      
                      <div className="flex flex-wrap items-center gap-2 text-sm">
                        <Badge variant="outline" className={getTipoColor(lugar.tipo)}>
                          {lugar.tipo}
                        </Badge>
                        <span className="flex items-center gap-1 text-muted-foreground">
                          <Building2 className="w-3.5 h-3.5" />
                          {lugar.edificio}
                        </span>
                      </div>
                    </div>
                  </div>
                  
                  <div className="flex-shrink-0">
                    {!estaEnUso ? (
                      <Badge className="bg-success text-success-foreground">
                        Disponible
                      </Badge>
                    ) : (
                      <Badge variant="secondary" className="bg-rose-100 text-rose-800 border-rose-200">
                        En uso
                      </Badge>
                    )}
                  </div>
                </div>
                
                {/* Show who has the key and exchange button when in use */}
                {estaEnUso && solicitudEnUso && onExchangeRequest && (
                  <div className="mt-3 ml-8 flex items-center justify-between gap-3 p-3 bg-rose-50 rounded-lg border border-rose-200">
                    <div className="flex items-center gap-2 text-sm">
                      <User className="w-4 h-4 text-rose-600" />
                      <span className="text-muted-foreground">En poder de:</span>
                      <span className="font-medium text-rose-800">{solicitudEnUso.usuario.nombre}</span>
                    </div>
                    <Button
                      variant="outline"
                      size="sm"
                      className="gap-2 border-primary/30 text-primary hover:bg-primary/10"
                      onClick={(e) => {
                        e.stopPropagation();
                        onExchangeRequest(lugar, solicitudEnUso.usuario);
                      }}
                    >
                      <ArrowRightLeft className="w-4 h-4" />
                      Intercambiar llave
                    </Button>
                  </div>
                )}

                {lugar.esHibrido && (
                  <div className="mt-2 ml-8 flex items-center gap-2 text-xs text-warning bg-warning/10 rounded-md px-2 py-1">
                    <AlertTriangle className="w-3.5 h-3.5" />
                    Salón Híbrido - Solo para clases programadas
                  </div>
                )}
              </Card>
            );
          })
        )}
      </div>
      
      <p className="text-sm text-muted-foreground text-center">
        Mostrando {lugaresFiltrados.length} de {lugaresDisponibles.length} llaves
      </p>
    </div>
  );
}
