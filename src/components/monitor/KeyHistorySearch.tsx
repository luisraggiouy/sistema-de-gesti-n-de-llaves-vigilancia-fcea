import { Search, Calendar, X, Clock, User, Key, CheckCircle2, AlertCircle } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Calendar as CalendarComponent } from '@/components/ui/calendar';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { useBusquedaHistorial, HistorialLlaveItem } from '@/hooks/useBusquedaHistorial';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

interface KeyHistorySearchProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function KeyHistorySearch({ open, onOpenChange }: KeyHistorySearchProps) {
  const {
    historial,
    totalRegistros,
    filtros,
    setBusqueda,
    setFechaInicio,
    setFechaFin,
    limpiarFiltros,
  } = useBusquedaHistorial();

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-4xl h-[90vh] flex flex-col overflow-hidden">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Search className="w-5 h-5" />
            Buscador Histórico de Llaves
          </DialogTitle>
        </DialogHeader>

        {/* Filtros */}
        <div className="space-y-4 pb-4 border-b flex-shrink-0">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Buscar por nombre de llave, usuario o vigilante..."
              value={filtros.busqueda}
              onChange={(e) => setBusqueda(e.target.value)}
              className="pl-10"
            />
          </div>

          <div className="flex flex-wrap gap-3 items-center">
            <Popover>
              <PopoverTrigger asChild>
                <Button variant="outline" size="sm" className="gap-2">
                  <Calendar className="w-4 h-4" />
                  {filtros.fechaInicio
                    ? format(filtros.fechaInicio, 'dd/MM/yyyy', { locale: es })
                    : 'Desde'}
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0" align="start">
                <CalendarComponent mode="single" selected={filtros.fechaInicio} onSelect={setFechaInicio} locale={es} />
              </PopoverContent>
            </Popover>

            <Popover>
              <PopoverTrigger asChild>
                <Button variant="outline" size="sm" className="gap-2">
                  <Calendar className="w-4 h-4" />
                  {filtros.fechaFin
                    ? format(filtros.fechaFin, 'dd/MM/yyyy', { locale: es })
                    : 'Hasta'}
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0" align="start">
                <CalendarComponent mode="single" selected={filtros.fechaFin} onSelect={setFechaFin} locale={es} />
              </PopoverContent>
            </Popover>

            {(filtros.busqueda || filtros.fechaInicio || filtros.fechaFin) && (
              <Button variant="ghost" size="sm" onClick={limpiarFiltros} className="gap-2 text-muted-foreground">
                <X className="w-4 h-4" />
                Limpiar
              </Button>
            )}

            <div className="ml-auto text-sm text-muted-foreground">
              {historial.length} de {totalRegistros} registros
            </div>
          </div>
        </div>

        {/* Resultados con scroll */}
        <div className="flex-1 overflow-y-auto min-h-0 pr-1">
          {historial.length === 0 ? (
            <div className="text-center py-12">
              <Key className="w-12 h-12 mx-auto text-muted-foreground/30 mb-3" />
              <h3 className="font-medium mb-1">No se encontraron registros</h3>
              <p className="text-sm text-muted-foreground">
                {totalRegistros === 0
                  ? 'Aún no hay historial de llaves registrado'
                  : 'Intenta ajustar los filtros de búsqueda'}
              </p>
            </div>
          ) : (
            <div className="space-y-3 py-2">
              {historial.map((item, index) => (
                <HistorialCard key={index} item={item} />
              ))}
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}

function HistorialCard({ item }: { item: HistorialLlaveItem }) {
  const fechaEntrega = format(item.horaEntrega, "dd/MM/yyyy 'a las' HH:mm", { locale: es });
  const fechaDevolucion = item.horaDevolucion
    ? format(item.horaDevolucion, "dd/MM/yyyy 'a las' HH:mm", { locale: es })
    : null;

  return (
    <Card className="p-4">
      <div className="flex flex-wrap gap-4 items-start justify-between">
        <div className="space-y-2 flex-1 min-w-[200px]">
          <div className="flex items-center gap-2">
            <Key className="w-4 h-4 text-primary" />
            <span className="font-semibold">{item.lugarNombre}</span>
            <Badge variant="outline" className="text-xs">{item.turno}</Badge>
          </div>
          <div className="flex items-center gap-2 text-base text-muted-foreground">
            <User className="w-4 h-4" />
            <span>Usuario: <span className="text-foreground font-medium">{item.usuarioNombre}</span></span>
            {item.tipoUsuario && (
              <>
                <span className="mx-1">•</span>
                <span>{item.tipoUsuario}</span>
              </>
            )}
            {item.tipoUsuario === 'Personal TAS' && item.departamento && (
              <>
                <span className="mx-1">•</span>
                <span>Depto: {item.departamento}</span>
              </>
            )}
            {item.tipoUsuario === 'Empresa' && item.nombreEmpresa && (
              <>
                <span className="mx-1">•</span>
                <span>Empresa: {item.nombreEmpresa}</span>
              </>
            )}
          </div>
        </div>

        <div className="text-right">
          {item.horaDevolucion ? (
            <Badge className="bg-success/20 text-success border-success/30 gap-1">
              <CheckCircle2 className="w-3 h-3" />
              Devuelta
            </Badge>
          ) : (
            <Badge variant="destructive" className="gap-1">
              <AlertCircle className="w-3 h-3" />
              En uso
            </Badge>
          )}
          {item.tiempoUso && (
            <div className="text-sm text-muted-foreground mt-1 flex items-center gap-1 justify-end">
              <Clock className="w-3 h-3" />
              Tiempo: <span className="text-foreground font-medium">{item.tiempoUso}</span>
            </div>
          )}
        </div>
      </div>

      <div className="mt-3 pt-3 border-t grid gap-2 text-sm sm:grid-cols-2">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-success" />
          <span className="text-muted-foreground">Entrega:</span>
          <span>{fechaEntrega}</span>
          <span className="text-muted-foreground">por</span>
          <span className="font-medium">{item.vigilanteEntrega}</span>
        </div>
        {item.horaDevolucion && item.vigilanteDevolucion ? (
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-info" />
            <span className="text-muted-foreground">Devolución:</span>
            <span>{fechaDevolucion}</span>
            <span className="text-muted-foreground">por</span>
            <span className="font-medium">{item.vigilanteDevolucion}</span>
          </div>
        ) : (
          <div className="flex items-center gap-2 text-muted-foreground">
            <div className="w-2 h-2 rounded-full bg-destructive animate-pulse" />
            <span>Pendiente de devolución</span>
          </div>
        )}
      </div>
    </Card>
  );
}