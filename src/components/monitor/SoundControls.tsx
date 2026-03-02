import { Button } from '@/components/ui/button';
import { Slider } from '@/components/ui/slider';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
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
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="outline" size="sm" className="gap-2 relative">
          <VolumeIcon className="w-4 h-4" />
          {config.muted && (
            <span className="absolute -top-1 -right-1 w-2 h-2 rounded-full bg-destructive" />
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-56" align="end">
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium">Sonido</span>
            <Button variant="ghost" size="sm" onClick={onToggleMute} className="h-7 px-2">
              {config.muted ? (
                <span className="text-xs text-destructive flex items-center gap-1">
                  <VolumeX className="w-3.5 h-3.5" /> Muted
                </span>
              ) : (
                <span className="text-xs text-muted-foreground flex items-center gap-1">
                  <Volume2 className="w-3.5 h-3.5" /> Activo
                </span>
              )}
            </Button>
          </div>
          
          <div className="flex items-center gap-3">
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
          </div>
          
          <div className="text-center text-xs text-muted-foreground">
            {Math.round(config.volumen * 100)}%
          </div>

          <Button 
            variant="outline" 
            size="sm" 
            className="w-full gap-2" 
            onClick={onTestSound}
          >
            <Bell className="w-3.5 h-3.5" />
            Probar sonido
          </Button>

          <p className="text-[10px] text-muted-foreground leading-tight">
            🔔 Nuevo pedido: doble campana<br/>
            🔑 Entrega/devolución: sonido único por vigilante
          </p>
        </div>
      </PopoverContent>
    </Popover>
  );
}
