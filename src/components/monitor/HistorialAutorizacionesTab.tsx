import { useState, useMemo, useCallback } from 'react';
import { Input } from '@/components/ui/input';
import { ClearableInput } from '@/components/ui/clearable-input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Button } from '@/components/ui/button';
import { Search, CalendarDays, Clock, UserCheck, Mail, X, History, RotateCcw, Trash2, AlertTriangle, Users } from 'lucide-react';
import {
  buscarHistorialAutorizaciones,
  getHistorialAutorizaciones,
  restablecerAutorizacion,
  getPersonasAutorizadas,
  type AutorizacionHistorial
} from '@/data/fceaData';

import { DateInput } from '@/components/ui/date-input';
import { useToast } from '@/hooks/use-toast';

export function HistorialAutorizacionesTab() {
  const { toast } = useToast();
  const [busqLugar, setBusqLugar] = useState('');
  const [fechaDesde, setFechaDesde] = useState('');
  const [fechaHasta, setFechaHasta] = useState('');
  const [refreshKey, setRefreshKey] = useState(0);

  const refresh = useCallback(() => setRefreshKey(k => k + 1), []);

  const totalRegistros = useMemo(() => getHistorialAutorizaciones().length, [refreshKey]);

  const resultados = useMemo(() => {
    if (!busqLugar.trim() && !fechaDesde && !fechaHasta) {
      return getHistorialAutorizaciones().sort((a, b) => b.fechaBaja.localeCompare(a.fechaBaja));
    }
    return buscarHistorialAutorizaciones(busqLugar, fechaDesde || undefined, fechaHasta || undefined)
      .sort((a, b) => b.fechaBaja.localeCompare(a.fechaBaja));
  }, [busqLugar, fechaDesde, fechaHasta, refreshKey]);

  const limpiarFiltros = () => {
    setBusqLugar('');
    setFechaDesde('');
    setFechaHasta('');
  };

  const handleRestablecer = (auth: AutorizacionHistorial) => {
    if (!confirm(`¿Restablecer la autorización de ${auth.personaNombre} para ${auth.lugarAutorizado}?`)) return;
    const resultado = restablecerAutorizacion(auth.id);
    if (resultado) {
      toast({ title: 'Autorización restablecida', description: `${auth.personaNombre} — ${auth.lugarAutorizado}` });
      refresh();
    }
  };

  const hayFiltros = busqLugar.trim() || fechaDesde || fechaHasta;

  // Contadores por tipo
  const totalEliminadas = useMemo(() => resultados.filter(a => a.motivoBaja === 'eliminada').length, [resultados]);
  const totalVencidas = useMemo(() => resultados.filter(a => a.motivoBaja === 'vencida').length, [resultados]);

  return (
    <div className="space-y-3">
      <div className="space-y-2">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <ClearableInput
            placeholder="Buscar por lugar o persona..."
            value={busqLugar}
            onChange={e => setBusqLugar(e.target.value)}
            onClear={() => setBusqLugar('')}
            className="pl-10 h-9"
          />
        </div>
        <div className="grid grid-cols-2 gap-2">
          <div className="space-y-1">
            <Label className="text-xs">Desde</Label>
            <DateInput value={fechaDesde} onChange={v => setFechaDesde(v)} className="h-9" />
          </div>
          <div className="space-y-1">
            <Label className="text-xs">Hasta</Label>
            <DateInput value={fechaHasta} onChange={v => setFechaHasta(v)} className="h-9" />
          </div>
        </div>
        {hayFiltros && (
          <Button variant="ghost" size="sm" onClick={limpiarFiltros} className="h-7 gap-1 text-xs">
            <X className="w-3 h-3" />Limpiar filtros
          </Button>
        )}
        {resultados.length > 0 && (
          <div className="flex gap-2 flex-wrap">
            {totalEliminadas > 0 && (
              <Badge variant="outline" className="bg-destructive/10 text-destructive border-destructive/30 gap-1 text-xs">
                <Trash2 className="w-3 h-3" />{totalEliminadas} eliminada{totalEliminadas > 1 ? 's' : ''}
              </Badge>
            )}
            {totalVencidas > 0 && (
              <Badge variant="outline" className="bg-warning/10 text-warning border-warning/30 gap-1 text-xs">
                <AlertTriangle className="w-3 h-3" />{totalVencidas} vencida{totalVencidas > 1 ? 's' : ''}
              </Badge>
            )}
          </div>
        )}
      </div>

      <ScrollArea className="h-[230px] -mx-1 px-1">
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
              <HistorialCard key={a.id + a.fechaBaja} auth={a} onRestablecer={handleRestablecer} />
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

function fmt(fecha: string): string {
  // Acepta YYYY-MM-DD o ISO completo
  const d = fecha.includes('T') ? new Date(fecha) : new Date(fecha + 'T12:00:00');
  return d.toLocaleDateString('es-UY');
}

function HistorialCard({
  auth,
  onRestablecer,
}: {
  auth: AutorizacionHistorial;
  onRestablecer: (a: AutorizacionHistorial) => void;
}) {
  const esEliminada = auth.motivoBaja === 'eliminada';
  // Upgrade 2026-08-06: mostrar TODAS las personas autorizadas.
  const personas = getPersonasAutorizadas(auth);

  return (
    <div className={`p-3 rounded-lg border bg-card/50 space-y-1.5 ${esEliminada ? 'border-destructive/20' : 'border-warning/20'}`}>
      <div className="flex items-start justify-between gap-2">
        <div className="flex-1 min-w-0">
          {personas.length > 1 && (
            <Badge variant="outline" className="mb-1 gap-1 bg-primary/10 text-primary border-primary/30">
              <Users className="w-3 h-3" />{personas.length} personas
            </Badge>
          )}
          {personas.map((p, i) => (
            <p key={i} className="font-medium truncate">
              {p.nombre}{p.ci ? ` — CI: ${p.ci}` : ''}
            </p>
          ))}
          <div className="flex items-center gap-1.5 mt-0.5 flex-wrap">

            <Badge variant="outline" className="bg-muted text-muted-foreground border-border">
              {auth.lugarAutorizado}
            </Badge>
            {esEliminada ? (
              <Badge variant="outline" className="bg-destructive/10 text-destructive border-destructive/30 gap-1">
                <Trash2 className="w-3 h-3" />Eliminada
              </Badge>
            ) : (
              <Badge variant="outline" className="bg-warning/10 text-warning border-warning/30 gap-1">
                <AlertTriangle className="w-3 h-3" />Vencida
              </Badge>
            )}
          </div>
        </div>
        {/* Solo las eliminadas pueden restablecerse */}
        {esEliminada && (
          <Button
            variant="outline"
            size="sm"
            className="h-7 gap-1 text-xs shrink-0 border-green-500/40 text-green-600 hover:bg-green-500/10 hover:text-green-700"
            onClick={() => onRestablecer(auth)}
          >
            <RotateCcw className="w-3 h-3" />Restablecer
          </Button>
        )}
      </div>

      <div className="flex flex-wrap gap-x-3 gap-y-1 text-xs text-muted-foreground">
        <span className="flex items-center gap-1">
          <UserCheck className="w-3 h-3" />{auth.autorizadoPor}
        </span>

        {/* Vigencia: desde → hasta */}
        {(auth.fechaDesde || auth.fechaHasta) && (
          <span className="flex items-center gap-1">
            <CalendarDays className="w-3 h-3" />
            Vigencia: {auth.fechaDesde ? fmt(auth.fechaDesde) : '...'} → {auth.fechaHasta ? fmt(auth.fechaHasta) : 'indefinida'}
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

        {/* Fecha de baja con etiqueta según motivo */}
        <span className="flex items-center gap-1">
          <History className="w-3 h-3" />
          {esEliminada ? 'Eliminada el' : 'Venció el'}: {fmt(auth.fechaBaja)}
        </span>
      </div>

      {auth.observaciones && (
        <p className="text-xs text-muted-foreground italic">{auth.observaciones}</p>
      )}
    </div>
  );
}
