import { useState, useMemo } from 'react';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Card } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { 
  lugares, 
  tiposLugar, 
  edificios, 
  Lugar, 
  TipoLugar,
  normalizarTexto
} from '@/data/fceaData';
import { Search, Building2, Check, AlertTriangle, Lock, Square, CheckSquare } from 'lucide-react';
import { cn } from '@/lib/utils';

interface KeySearchProps {
  selectedKeys: Lugar[];
  onToggleKey: (lugar: Lugar) => void;
}

export function KeySearch({ selectedKeys, onToggleKey }: KeySearchProps) {
  const [busqueda, setBusqueda] = useState('');
  const [filtroTipo, setFiltroTipo] = useState<TipoLugar | 'todos'>('todos');
  const [filtroEdificio, setFiltroEdificio] = useState<string>('todos');

  const lugaresFiltrados = useMemo(() => {
    const busquedaNormalizada = normalizarTexto(busqueda);
    
    return lugares.filter((lugar) => {
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
  }, [busqueda, filtroTipo, filtroEdificio]);

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
            return (
              <Card
                key={lugar.id}
                onClick={() => lugar.disponible && onToggleKey(lugar)}
                className={cn(
                  "p-4 cursor-pointer transition-all duration-200",
                  !lugar.disponible && "opacity-60 cursor-not-allowed",
                  selected 
                    ? "ring-2 ring-primary bg-primary/5 border-primary" 
                    : "hover:bg-muted/50 hover:border-primary/50"
                )}
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center gap-3">
                    {/* Checkbox visual */}
                    <div className={cn(
                      "flex-shrink-0 w-5 h-5 rounded border-2 flex items-center justify-center transition-colors",
                      selected 
                        ? "bg-primary border-primary text-primary-foreground" 
                        : "border-muted-foreground/30"
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
                    {lugar.disponible ? (
                      <Badge className="bg-success text-success-foreground">
                        Disponible
                      </Badge>
                    ) : (
                      <Badge variant="secondary" className="bg-muted">
                        En uso
                      </Badge>
                    )}
                  </div>
                </div>
                
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
        Mostrando {lugaresFiltrados.length} de {lugares.length} llaves
      </p>
    </div>
  );
}
