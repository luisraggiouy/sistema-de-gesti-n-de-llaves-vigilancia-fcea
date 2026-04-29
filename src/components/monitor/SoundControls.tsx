import { Button } from '@/components/ui/button';
import { Slider } from '@/components/ui/slider';
import { Volume2, VolumeX, Volume1, Bell, BellRing, Key } from 'lucide-react';
import { SonidoConfig } from '@/hooks/useSonidos';

interface SoundControlsProps {
  config: SonidoConfig;
  onVolumeChange: (vol: number) => void;
  onToggleMute: () => void;
  onToggleMuteNuevaSolicitud?: () => void;
  onToggleMuteEntregaDevolucion?: () => void;
  onTestSound: () => void;
}

export function SoundControls({ 
  config, 
  onVolumeChange, 
  onToggleMute, 
  onToggleMuteNuevaSolicitud, 
  onToggleMuteEntregaDevolucion, 
  onTestSound 
}: SoundControlsProps) {
  const VolumeIcon = config.muted ? VolumeX : config.volumen > 0.5 ? Volume2 : Volume1;

  return (
    <div className="flex items-center gap-2 flex-wrap">
      <div className="flex items-center gap-1">
        <Bell className="w-3 h-3 text-muted-foreground" />
        <span className="text-xs text-muted-foreground">Sonido</span>
      </div>

      <Button 
        variant="ghost" 
        size="sm" 
        onClick={onToggleMute} 
        className="gap-1 h-6 px-2 text-xs text-muted-foreground hover:text-foreground"
      >
        <VolumeIcon className="w-3 h-3" />
        {config.muted ? 'Silenciado' : 'Activo'}
      </Button>

      <div className="flex items-center gap-1 w-[120px]">
        <Slider
          value={[config.volumen * 100]}
          onValueChange={([v]) => onVolumeChange(v / 100)}
          max={100}
          step={5}
          className="flex-1"
          disabled={config.muted}
        />
        <span className="text-xs text-muted-foreground w-6">{Math.round(config.volumen * 100)}%</span>
      </div>

      {/* Controles de silencio selectivos */}
      {onToggleMuteNuevaSolicitud && onToggleMuteEntregaDevolucion && (
        <div className="flex items-center gap-1">
          <Button 
            variant="ghost" 
            size="sm" 
            onClick={onToggleMuteNuevaSolicitud} 
            className={`gap-1 h-6 px-2 text-xs ${config.mutedNuevaSolicitud ? 'bg-muted/50' : ''}`}
            disabled={config.muted}
          >
            <BellRing className="w-3 h-3" />
            <span className="text-xs">{config.mutedNuevaSolicitud ? 'Silenciado' : 'Activo'}</span>
            <span className="text-xs ml-1">Nuevos pedidos</span>
          </Button>

          <Button 
            variant="ghost" 
            size="sm" 
            onClick={onToggleMuteEntregaDevolucion} 
            className={`gap-1 h-6 px-2 text-xs ${config.mutedEntregaDevolucion ? 'bg-muted/50' : ''}`}
            disabled={config.muted}
          >
            <Key className="w-3 h-3" />
            <span className="text-xs">{config.mutedEntregaDevolucion ? 'Silenciado' : 'Activo'}</span>
            <span className="text-xs ml-1">Entregas/devoluciones</span>
          </Button>
        </div>
      )}

      <Button 
        variant="ghost" 
        size="sm" 
        className="gap-1 h-6 px-2 text-xs text-muted-foreground hover:text-foreground" 
        onClick={onTestSound}
      >
        <Bell className="w-3 h-3" />
        Probar
      </Button>
    </div>
  );
}
