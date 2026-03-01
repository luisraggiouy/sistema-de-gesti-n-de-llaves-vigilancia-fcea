import { Lugar, formatearUbicacion, ZonaTablero } from '@/data/fceaData';
import { MapPin } from 'lucide-react';

interface BoardLocationProps {
  lugar: Lugar;
  size?: 'sm' | 'md' | 'lg';
}

const zonaColors: Record<ZonaTablero, string> = {
  'Puerta derecha': 'bg-blue-500',
  'Puerta izquierda': 'bg-green-500',
  'Fondo': 'bg-purple-500',
  'Lateral derecho': 'bg-orange-500',
  'Lateral izquierdo': 'bg-pink-500',
};

export function BoardLocation({ lugar, size = 'md' }: BoardLocationProps) {
  const { ubicacion } = lugar;
  const zonaColor = zonaColors[ubicacion.zona] || 'bg-muted';
  
  const sizeClasses = {
    sm: 'text-xs gap-1 px-2 py-1',
    md: 'text-sm gap-2 px-3 py-1.5',
    lg: 'text-base gap-2 px-4 py-2',
  };

  const iconSizes = {
    sm: 'w-3 h-3',
    md: 'w-4 h-4',
    lg: 'w-5 h-5',
  };

  return (
    <div className={`inline-flex items-center rounded-full ${sizeClasses[size]}`}>
      <span className={`w-2 h-2 rounded-full ${zonaColor}`} />
      <MapPin className={`${iconSizes[size]} text-muted-foreground`} />
      <span className="font-mono font-medium">
        {lugar.tablero !== 'Tablero Principal' && <span className="text-muted-foreground mr-1">[{lugar.tablero.replace('Tablero ', '')}]</span>}
        {formatearUbicacion(ubicacion)}
      </span>
    </div>
  );
}

// Mini tablero visual
export function BoardMiniMap({ highlightZona }: { highlightZona?: ZonaTablero }) {
  const zonas: { zona: ZonaTablero; position: string }[] = [
    { zona: 'Puerta izquierda', position: 'left-0 top-1/2 -translate-y-1/2 w-2 h-16' },
    { zona: 'Puerta derecha', position: 'right-0 top-1/2 -translate-y-1/2 w-2 h-16' },
    { zona: 'Fondo', position: 'bottom-0 left-1/2 -translate-x-1/2 h-2 w-24' },
    { zona: 'Lateral izquierdo', position: 'left-4 top-4 w-8 h-8 rounded' },
    { zona: 'Lateral derecho', position: 'right-4 top-4 w-8 h-8 rounded' },
  ];

  return (
    <div className="relative w-40 h-24 bg-muted/50 rounded-lg border-2 border-muted">
      {/* Etiqueta central */}
      <div className="absolute inset-0 flex items-center justify-center text-xs text-muted-foreground">
        Tablero
      </div>
      
      {/* Zonas */}
      {zonas.map(({ zona, position }) => (
        <div
          key={zona}
          className={`absolute ${position} ${zonaColors[zona]} transition-all ${
            highlightZona === zona ? 'opacity-100 scale-110' : 'opacity-30'
          }`}
          title={zona}
        />
      ))}
    </div>
  );
}
