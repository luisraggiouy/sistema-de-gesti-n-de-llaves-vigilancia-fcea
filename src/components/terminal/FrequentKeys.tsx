import { Lugar, TipoLugar } from '@/data/fceaData';
import { SolicitudLlave } from '@/types/solicitud';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Star, Building2, Check, Lock, AlertTriangle, User, ArrowRightLeft, Clock } from 'lucide-react';
import { cn } from '@/lib/utils';

interface FrequentKeysProps {
  llavesFrecuentes: Lugar[];
  selectedKeys: Lugar[];
  onToggleKey: (lugar: Lugar) => void;
  // Fix 2026-08-28: para que las frecuentes reflejen el estado real (igual que
  // el buscador) y eviten pedidos duplicados / permitan intercambio.
  solicitudesPendientes?: SolicitudLlave[];
  solicitudesEntregadas?: SolicitudLlave[];
  onExchangeRequest?: (lugar: Lugar, usuarioConLlave: { nombre: string; celular: string; tipo: string }) => void;
}

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

export function FrequentKeys({
  llavesFrecuentes,
  selectedKeys,
  onToggleKey,
  solicitudesPendientes = [],
  solicitudesEntregadas = [],
  onExchangeRequest,
}: FrequentKeysProps) {
  if (llavesFrecuentes.length === 0) return null;

  const isSelected = (lugarId: string) => selectedKeys.some(k => k.id === lugarId);

  return (
    <Card className="p-4 bg-primary/5 border-primary/20">
      <h3 className="text-sm font-semibold text-foreground flex items-center gap-2 mb-3">
        <Star className="w-4 h-4 text-primary fill-primary" />
        Tus llaves frecuentes
        <span className="text-xs text-muted-foreground font-normal">(puedes seleccionar varias)</span>
      </h3>
      
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
        {llavesFrecuentes.map((lugar) => {
          const selected = isSelected(lugar.id);
          // Estado REAL derivado de las solicitudes (no del flag disponible):
          //  - en uso     -> hay una solicitud 'entregada' para este lugar
          //  - pendiente  -> hay una solicitud 'pendiente' (ya pedida, sin entregar)
          //  - disponible -> ninguna de las anteriores
          const solicitudEnUso = solicitudesEntregadas.find(s => s.lugar.id === lugar.id) || null;
          const solicitudPendiente = solicitudesPendientes.find(s => s.lugar.id === lugar.id) || null;
          const estaEnUso = !!solicitudEnUso;
          const estaPendiente = !estaEnUso && !!solicitudPendiente;
          const seleccionable = !estaEnUso && !estaPendiente;
          return (
            <div
              key={lugar.id}
              onClick={() => { if (seleccionable) onToggleKey(lugar); }}
              className={cn(
                "p-3 rounded-lg text-left transition-all duration-200 border",
                !seleccionable && "bg-muted/40",
                seleccionable && selected
                  ? "bg-primary/10 border-primary ring-1 ring-primary cursor-pointer"
                  : seleccionable
                    ? "bg-background hover:bg-muted/50 border-border hover:border-primary/50 cursor-pointer"
                    : "border-border"
              )}
            >
              <div className="flex items-start justify-between gap-2">
                <div className="flex items-center gap-2">
                  {/* Checkbox visual */}
                  <div className={cn(
                    "flex-shrink-0 w-4 h-4 rounded border-2 flex items-center justify-center transition-colors",
                    !seleccionable && "opacity-30",
                    selected 
                      ? "bg-primary border-primary text-primary-foreground" 
                      : "border-muted-foreground/30"
                  )}>
                    {selected && <Check className="w-3 h-3" />}
                  </div>
                  
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <span className="font-medium text-sm text-foreground truncate">
                        {lugar.nombre}
                      </span>
                      {lugar.esHibrido && (
                        <Lock className="w-3.5 h-3.5 text-destructive flex-shrink-0" />
                      )}
                    </div>
                    <div className="flex items-center gap-2 mt-1">
                      <Badge variant="outline" className={cn("text-xs", getTipoColor(lugar.tipo))}>
                        {lugar.tipo}
                      </Badge>
                      <span className="flex items-center gap-1 text-xs text-muted-foreground">
                        <Building2 className="w-3 h-3" />
                        {lugar.edificio}
                      </span>
                    </div>
                  </div>
                </div>
                
                {estaEnUso && (
                  <Badge variant="secondary" className="text-xs bg-rose-100 text-rose-800 border-rose-200">
                    En uso
                  </Badge>
                )}
                {estaPendiente && (
                  <Badge variant="secondary" className="text-xs bg-amber-100 text-amber-800 border-amber-200">
                    Ya solicitada
                  </Badge>
                )}
              </div>

              {/* Caso EN USO: mostrar quién la tiene y ofrecer intercambio */}
              {estaEnUso && solicitudEnUso && onExchangeRequest && (
                <div className="mt-2 flex items-center justify-between gap-2 p-2 bg-rose-50 rounded-md border border-rose-200">
                  <div className="flex items-center gap-1.5 text-xs min-w-0">
                    <User className="w-3.5 h-3.5 text-rose-600 flex-shrink-0" />
                    <span className="text-muted-foreground">En poder de:</span>
                    <span className="font-medium text-rose-800 truncate">{solicitudEnUso.usuario.nombre}</span>
                  </div>
                  <Button
                    variant="outline"
                    size="sm"
                    className="gap-1 border-primary/30 text-primary hover:bg-primary/10 h-8 flex-shrink-0"
                    onClick={(e) => {
                      e.stopPropagation();
                      onExchangeRequest(lugar, solicitudEnUso.usuario);
                    }}
                  >
                    <ArrowRightLeft className="w-3.5 h-3.5" />
                    Intercambiar
                  </Button>
                </div>
              )}

              {/* Caso PENDIENTE: avisar que ya fue solicitada (evita duplicado) */}
              {estaPendiente && (
                <div className="mt-2 flex items-center gap-1.5 text-xs text-amber-700 bg-amber-50 rounded-md px-2 py-1.5 border border-amber-200">
                  <Clock className="w-3.5 h-3.5 flex-shrink-0" />
                  Ya solicitada, esperando entrega del vigilante
                </div>
              )}

              {lugar.esHibrido && seleccionable && (
                <div className="mt-2 ml-6 flex items-center gap-1 text-xs text-warning">
                  <AlertTriangle className="w-3 h-3" />
                  Solo clases programadas
                </div>
              )}
            </div>
          );
        })}
      </div>
    </Card>
  );
}
