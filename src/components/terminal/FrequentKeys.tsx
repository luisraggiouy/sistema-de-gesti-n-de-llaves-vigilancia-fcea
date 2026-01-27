import { Lugar, TipoLugar } from '@/data/fceaData';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Star, Building2, Check, Lock, AlertTriangle } from 'lucide-react';
import { cn } from '@/lib/utils';

interface FrequentKeysProps {
  llavesFrecuentes: Lugar[];
  selectedKey: Lugar | null;
  onSelectKey: (lugar: Lugar) => void;
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

export function FrequentKeys({ llavesFrecuentes, selectedKey, onSelectKey }: FrequentKeysProps) {
  if (llavesFrecuentes.length === 0) return null;

  return (
    <Card className="p-4 bg-primary/5 border-primary/20">
      <h3 className="text-sm font-semibold text-foreground flex items-center gap-2 mb-3">
        <Star className="w-4 h-4 text-primary fill-primary" />
        Tus llaves frecuentes
      </h3>
      
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
        {llavesFrecuentes.map((lugar) => (
          <button
            key={lugar.id}
            onClick={() => onSelectKey(lugar)}
            disabled={!lugar.disponible}
            className={cn(
              "p-3 rounded-lg text-left transition-all duration-200 border",
              !lugar.disponible && "opacity-50 cursor-not-allowed bg-muted",
              lugar.disponible && selectedKey?.id === lugar.id 
                ? "bg-primary/10 border-primary ring-1 ring-primary" 
                : "bg-background hover:bg-muted/50 border-border hover:border-primary/50"
            )}
          >
            <div className="flex items-start justify-between gap-2">
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <span className="font-medium text-sm text-foreground truncate">
                    {lugar.nombre}
                  </span>
                  {lugar.esHibrido && (
                    <Lock className="w-3.5 h-3.5 text-destructive flex-shrink-0" />
                  )}
                  {selectedKey?.id === lugar.id && (
                    <Check className="w-4 h-4 text-primary flex-shrink-0" />
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
              
              {!lugar.disponible && (
                <Badge variant="secondary" className="text-xs bg-muted">
                  En uso
                </Badge>
              )}
            </div>
            
            {lugar.esHibrido && lugar.disponible && (
              <div className="mt-2 flex items-center gap-1 text-xs text-warning">
                <AlertTriangle className="w-3 h-3" />
                Solo clases programadas
              </div>
            )}
          </button>
        ))}
      </div>
    </Card>
  );
}
