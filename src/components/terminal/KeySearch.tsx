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
  normalizarTexto,
  ordenNatural
} from '@/data/fceaData';
import { useSolicitudesContext } from '@/contexts/SolicitudesContext';
import { Search, Building2, Check, AlertTriangle, Lock, CheckSquare, ArrowRightLeft, User } from 'lucide-react';
import { cn } from '@/lib/utils';

interface KeySearchProps {
  selectedKeys: Lugar[];
  onToggleKey: (lugar: Lugar) => void;
  onExchangeRequest?: (lugar: Lugar, usuarioConLlave: { nombre: string; celular: string; tipo: string }) => void;
  tipoUsuario?: string;
}

export function KeySearch({ selectedKeys, onToggleKey, onExchangeRequest, tipoUsuario }: KeySearchProps) {
  const { lugaresDisponibles, solicitudesEntregadas } = useSolicitudesContext();
  const [busqueda, setBusqueda] = useState('');
  const [filtroTipo, setFiltroTipo] = useState<TipoLugar | 'todos'>('todos');
  const [filtroEdificio, setFiltroEdificio] = useState<string>('todos');

  const esDocente = tipoUsuario === 'Docente';

  const lugaresFiltrados = useMemo(() => {
    const busquedaNormalizada = normalizarTexto(busqueda);
    
    const filtrados = lugaresDisponibles.filter((lugar) => {
      // Docentes: para salones, solo ven llaves de "Equipos" (laptop, mouse, control proyector)
      // Pueden pedir cualquier otra llave (oficinas, salas, etc.)
      if (esDocente) {
        const esSalon = lugar.tipo === 'Salón' || lugar.tipo === 'Salón Híbrido';
        if (esSalon) {
          const nombreLower = normalizarTexto(lugar.nombre);
          if (!nombreLower.includes('equipo')) return false;
        }
      }

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

    // Sort results: prioritize name starts with search term, then contains
    if (busquedaNormalizada.length > 0) {
      filtrados.sort((a, b) => {
        const nombreA = normalizarTexto(a.nombre);
        const nombreB = normalizarTexto(b.nombre);
        const aStartsWith = nombreA.startsWith(busquedaNormalizada);
        const bStartsWith = nombreB.startsWith(busquedaNormalizada);
        
        // First priority: name starts with search term
        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;
        
        // Second priority: name contains search term (vs only type matches)
        const aNameContains = nombreA.includes(busquedaNormalizada);
        const bNameContains = nombreB.includes(busquedaNormalizada);
        if (aNameContains && !bNameContains) return -1;
        if (!aNameContains && bNameContains) return 1;
        
        // Third priority: earlier position of match in name
        const aIndex = nombreA.indexOf(busquedaNormalizada);
        const bIndex = nombreB.indexOf(busquedaNormalizada);
        if (aIndex !== bIndex) return aIndex - bIndex;
        
        // Finally: natural order
        return ordenNatural(a.nombre, b.nombre);
      });
    } else {
      // No search term: sort by natural order
      filtrados.sort((a, b) => ordenNatural(a.nombre, b.nombre));
    }

    return filtrados;
  }, [busqueda, filtroTipo, filtroEdificio, lugaresDisponibles, esDocente]);

  const isSelected = (lugarId: string) => selectedKeys.some(k => k.id === lugarId);

  const getTipoColor = (tipo: TipoLugar): string => {
    const colores: Partial<Record<TipoLugar, string>> = {
      'Salón': 'bg-blue-100 text-blue-800 border-blue-200',
      'Salón Híbrido': 'bg-rose-100 text-rose-800 border-rose-200',
      'Oficina': 'bg-emerald-100 text-emerald-800 border-emerald-200',
      'Sala': 'bg-violet-100 text-violet-800 border-violet-200',
      'Depósito': 'bg-slate-100 text-slate-800 border-slate-200',
      'Baño': 'bg-cyan-100 text-cyan-800 border-cyan-200',
      'Área Común': 'bg-amber-100 text-amber-800 border-amber-200',
      'Biblioteca': 'bg-purple-100 text-purple-800 border-purple-200',
      'Taller': 'bg-orange-100 text-orange-800 border-orange-200',
      'Recreación': 'bg-lime-100 text-lime-800 border-lime-200',
      'Acceso': 'bg-gray-100 text-gray-800 border-gray-200',
      'Espacio Común': 'bg-indigo-100 text-indigo-800 border-indigo-200',
      'Otro': 'bg-stone-100 text-stone-800 border-stone-200',
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

      {/* Info banner for docentes */}
      {esDocente && (
        <div className="flex items-center gap-2 p-3 bg-blue-50 border border-blue-200 rounded-lg text-sm text-blue-800">
          <span>📋</span>
          <span>Como docente, para salones solo se muestran las llaves de <strong>Equipos</strong> (laptop, mouse y control del proyector). Las demás llaves están disponibles normalmente.</span>
        </div>
      )}

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
