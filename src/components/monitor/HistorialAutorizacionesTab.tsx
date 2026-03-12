import { useState, useMemo } from 'react';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Button } from '@/components/ui/button';
import { Search, CalendarDays, Clock, UserCheck, Mail, X, History } from 'lucide-react';
import { buscarHistorialAutorizaciones, getHistorialAutorizaciones, type AutorizacionHistorial } from '@/data/fceaData';

export function HistorialAutorizacionesTab() {
  const [busqLugar, setBusqLugar] = useState('');
  const [fechaDesde, setFechaDesde] = useState('');
  const [fechaHasta, setFechaHasta] = useState('');

  const totalRegistros = useMemo(() => getHistorialAutorizaciones().length, []);

  const resultados = useMemo(() => {
    if (!busqLugar.trim() && !fechaDesde && !fechaHasta) {
      return getHistorialAutorizaciones().sort((a, b) => b.fechaBaja.localeCompare(a.fechaBaja));
    }
    return buscarHistorialAutorizaciones(busqLugar, fechaDesde || undefined, fechaHasta || undefined);
  }, [busqLugar, fechaDesde, fechaHasta]);

  const limpiarFiltros = () => {
    setBusqLugar('');
    setFechaDesde('');
    setFechaHasta('');
  };

  const hayFiltros = busqLugar.trim() || fechaDesde || fechaHasta;

  return (
    <div className="space-y-3">
      <div className="space-y-2">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            placeholder="Buscar por lugar o persona..."
            value={busqLugar}
            onChange={e => setBusqLugar(e.target.value)}
            className="pl-10 h-9"
          />
        </div>
        <div className="grid grid-cols-2 gap-2">
          <div className="space-y-1">
            <Label className="text-xs">Desde</Label>
            <Input type="date" value={fechaDesde} onChange={e => setFechaDesde(e.target.value)} className="h-9" />
          </div>
          <div className="space-y-1">
            <Label className="text-xs">Hasta</Label>
            <Input type="date" value={fechaHasta} onChange={e => setFechaHasta(e.target.value)} className="h-9" />
          </div>
        </div>
        {hayFiltros && (
          <Button variant="ghost" size="sm" onClick={limpiarFiltros} className="h-7 gap-1 text-xs">
            <X className="w-3 h-3" />Limpiar filtros
          </Button>
        )}
      </div>

      <ScrollArea className="h-[260px] -mx-1 px-1">
        {resultados.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground space-y-2">
            <History className="w-8 h-8 mx-auto opacity-40" />
            <p className="text-sm">
              {totalRegistros === 0
                ? 'No hay historial de autorizaciones aún'
                : 'Sin resultados para estos filtros'}
            </p>
            {totalRegistros === 0 && (
              <p className="text-xs">Las autorizaciones eliminadas o vencidas aparecerán aquí</p>
            )}
          </div>
        ) : (
          <div className="space-y-2">
            {resultados.map(a => (
              <HistorialCard key={a.id + a.fechaBaja} auth={a} />
            ))}
          </div>
        )}
      </ScrollArea>

      <p className="text-xs text-muted-foreground text-center">
        {resultados.length} de {totalRegistros} registro{totalRegistros !== 1 ? 's' : ''} histórico{totalRegistros !== 1 ? 's' : ''}
      </p>
    </div>
  );
}

function HistorialCard({ auth }: { auth: AutorizacionHistorial }) {
  return (
    <div className="p-3 rounded-lg border bg-card/50 space-y-1.5 opacity-90">
      <div className="flex items-start justify-between gap-2">
        <div className="flex-1 min-w-0">
          <p className="font-medium truncate">{auth.personaNombre}</p>
          <div className="flex items-center gap-1.5 mt-0.5">
            <Badge variant="outline" className="bg-muted text-muted-foreground border-border">
              {auth.lugarAutorizado}
            </Badge>
            <Badge variant="outline" className={
              auth.motivoBaja === 'vencida'
                ? 'bg-warning/10 text-warning border-warning/30'
                : 'bg-destructive/10 text-destructive border-destructive/30'
            }>
              {auth.motivoBaja === 'vencida' ? 'Vencida' : 'Eliminada'}
            </Badge>
          </div>
        </div>
      </div>
      <div className="flex flex-wrap gap-x-3 gap-y-1 text-xs text-muted-foreground">
        <span className="flex items-center gap-1">
          <UserCheck className="w-3 h-3" />{auth.autorizadoPor}
        </span>
        {auth.fechaAutorizacion && (
          <span className="flex items-center gap-1">
            <CalendarDays className="w-3 h-3" />Autorizado: {new Date(auth.fechaAutorizacion).toLocaleDateString('es-UY')}
          </span>
        )}
        {(auth.fechaDesde || auth.fechaHasta) && (
          <span className="flex items-center gap-1">
            <CalendarDays className="w-3 h-3" />
            Vigencia: {auth.fechaDesde ? new Date(auth.fechaDesde).toLocaleDateString('es-UY') : '...'} — {auth.fechaHasta ? new Date(auth.fechaHasta).toLocaleDateString('es-UY') : '...'}
          </span>
        )}
        {auth.horario && (
          <span className="flex items-center gap-1">
            <Clock className="w-3 h-3" />{auth.horario}
          </span>
        )}
        {auth.emailReferencia && (
          <span className="flex items-center gap-1">
            <Mail className="w-3 h-3" />{auth.emailReferencia}
          </span>
        )}
        <span className="flex items-center gap-1">
          <History className="w-3 h-3" />Baja: {new Date(auth.fechaBaja).toLocaleDateString('es-UY')}
        </span>
      </div>
      {auth.observaciones && (
        <p className="text-xs text-muted-foreground italic">{auth.observaciones}</p>
      )}
    </div>
  );
}
