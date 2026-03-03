import { Button } from '@/components/ui/button';
import { Slider } from '@/components/ui/slider';
import { Volume2, VolumeX, Volume1, Bell } from 'lucide-react';
import { SonidoConfig } from '@/hooks/useSonidos';

interface SoundControlsProps {
  config: SonidoConfig;
  onVolumeChange: (vol: number) => void;
  onToggleMute: () => void;
  onTestSound: () => void;
}

export function SoundControls({ config, onVolumeChange, onToggleMute, onTestSound }: SoundControlsProps) {
  const VolumeIcon = config.muted ? VolumeX : config.volumen > 0.5 ? Volume2 : Volume1;

  return (
    <div className="flex items-center gap-4 flex-wrap">
      <div className="flex items-center gap-2">
        <Bell className="w-4 h-4 text-primary" />
        <span className="text-sm font-medium">Sonido</span>
      </div>

      <Button 
        variant={config.muted ? "destructive" : "outline"} 
        size="sm" 
        onClick={onToggleMute} 
        className="gap-2 h-8"
      >
        <VolumeIcon className="w-4 h-4" />
        {config.muted ? 'Silenciado' : 'Activo'}
      </Button>

      <div className="flex items-center gap-2 min-w-[160px]">
        <Volume1 className="w-4 h-4 text-muted-foreground shrink-0" />
        <Slider
          value={[config.volumen * 100]}
          onValueChange={([v]) => onVolumeChange(v / 100)}
          max={100}
          step={5}
          className="flex-1"
          disabled={config.muted}
        />
        <Volume2 className="w-4 h-4 text-muted-foreground shrink-0" />
        <span className="text-xs text-muted-foreground w-8">{Math.round(config.volumen * 100)}%</span>
      </div>

      <Button 
        variant="outline" 
        size="sm" 
        className="gap-2 h-8" 
        onClick={onTestSound}
      >
        <Bell className="w-3.5 h-3.5" />
        Probar
      </Button>

      <span className="text-[10px] text-muted-foreground hidden lg:inline">
        🔔 Nuevo pedido: doble campana • 🔑 Entrega/devolución: tono por vigilante
      </span>
    </div>
  );
}
