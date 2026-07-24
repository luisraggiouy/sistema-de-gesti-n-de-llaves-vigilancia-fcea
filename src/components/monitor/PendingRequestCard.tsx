import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SolicitudLlave } from '@/types/solicitud';
import { Vigilante } from '@/data/fceaData';
import { formatearUbicacion, getColorTipoLugar } from '@/data/fceaData';
import { Key, MapPin, User, Phone, Clock, CheckCircle, Building2, AlertTriangle } from 'lucide-react';

/**
 * PendingRequestCard — tarjeta que muestra una solicitud pendiente
 * en el Monitor Vigilancia.
 *
 * v2.6 (P8 - piloto FCEA jueves 2026-07-23):
 * Se agrego alerta visual cuando la solicitud lleva demasiado tiempo
 * sin ser entregada. Umbrales (fijos por ahora, no configurables desde
 * la UI — se decide asi para no complicar el jueves; se puede mover a
 * la tabla `configuracion` de PocketBase mas adelante):
 *
 *   - < 5 minutos  : gris (normal, "acaba de llegar")
 *   - 5 - 15 min   : amarillo (aviso, se esta tardando)
 *   - > 15 min     : rojo + icono AlertTriangle (alerta, revisar)
 *
 * Nota: no hay 1h 30m aca — ese timer es para las llaves EN USO (ver
 * KeyInUseCard) que ya usa configuracion.tiempoAlertaMinutos. Aca es
 * para SOLICITUDES que estan pidiendo la llave y todavia no se
 * entregaron. Son dos alertas distintas.
 *
 * El texto "Hace X min" y el color se recalculan automaticamente en
 * cada re-render del padre (MonitorVigilancia hace setTick cada 1s).
 */

const UMBRAL_AVISO_MIN = 5;   // amarillo
const UMBRAL_ALERTA_MIN = 15; // rojo

interface PendingRequestCardProps {
  solicitud: SolicitudLlave;
  vigilantes: Vigilante[];
  vigilantesAnteriores?: Vigilante[];
  onEntregar: (vigilante: string) => void;
}

export function PendingRequestCard({ solicitud, vigilantes, vigilantesAnteriores = [], onEntregar }: PendingRequestCardProps) {
  const colorTipo = getColorTipoLugar(solicitud.lugar.tipo);

  const minutosEspera = Math.max(
    0,
    Math.floor((Date.now() - new Date(solicitud.horaSolicitud).getTime()) / 60000),
  );

  const tiempoDesdeCreacion = () => {
    if (minutosEspera < 1) return 'Ahora';
    if (minutosEspera === 1) return 'Hace 1 min';
    return `Hace ${minutosEspera} min`;
  };

  // Nivel de urgencia por tiempo de espera
  const nivelUrgencia: 'normal' | 'aviso' | 'alerta' =
    minutosEspera >= UMBRAL_ALERTA_MIN ? 'alerta'
    : minutosEspera >= UMBRAL_AVISO_MIN ? 'aviso'
    : 'normal';

  // Clases visuales por nivel de urgencia
  const cardBorderClass =
    nivelUrgencia === 'alerta' ? 'border-destructive border-2 shadow-[0_0_0_1px_hsl(var(--destructive)/0.3)]'
    : nivelUrgencia === 'aviso' ? 'border-warning border-2'
    : '';

  const clockColorClass =
    nivelUrgencia === 'alerta' ? 'text-destructive font-bold'
    : nivelUrgencia === 'aviso' ? 'text-warning font-semibold'
    : 'text-muted-foreground';

  const infoExtra = solicitud.usuario.departamento
    ? solicitud.usuario.departamento
    : solicitud.usuario.nombreEmpresa
    ? solicitud.usuario.nombreEmpresa
    : null;

  return (
    <Card className={`p-4 hover:shadow-md transition-shadow ${cardBorderClass}`}>
      <div className="flex flex-col lg:flex-row lg:items-center gap-4">
        {/* Info del lugar */}
        <div className="flex items-start gap-3 flex-1">
          <div className={`p-3 rounded-xl ${colorTipo}`}>
            <Key className="w-6 h-6 text-white" />
          </div>
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-1">
              <h3 className="font-semibold text-lg">{solicitud.lugar.nombre}</h3>
              <Badge variant="secondary" className="text-xs">{solicitud.lugar.tipo}</Badge>
              {nivelUrgencia === 'alerta' && (
                <Badge variant="destructive" className="text-xs gap-1">
                  <AlertTriangle className="w-3 h-3" />
                  Demora
                </Badge>
              )}
            </div>
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <MapPin className="w-4 h-4" />
              <span className="font-mono">{formatearUbicacion(solicitud.lugar.ubicacion)}</span>
            </div>
          </div>
        </div>

        {/* Info del usuario */}
        <div className="flex flex-wrap items-center gap-3 text-base">
          <div className="flex items-center gap-2">
            <User className="w-5 h-5 text-muted-foreground" />
            <span className="font-medium">{solicitud.usuario.nombre}</span>
            <Badge variant="outline" className="text-sm">{solicitud.usuario.tipo}</Badge>
            {infoExtra && (
              <Badge variant="secondary" className="text-sm flex items-center gap-1">
                <Building2 className="w-3.5 h-3.5" />
                {infoExtra}
              </Badge>
            )}
          </div>
          <div className="flex items-center gap-2 text-muted-foreground">
            <Phone className="w-5 h-5" />
            <span className="font-mono text-xl font-medium">{solicitud.usuario.celular}</span>
          </div>
          <div className={`flex items-center gap-2 ${clockColorClass}`}>
            <Clock className="w-5 h-5" />
            <span>{tiempoDesdeCreacion()}</span>
          </div>
        </div>
      </div>

      {/* Botones de vigilantes */}
      <div className="mt-4 pt-4 border-t">
        <p className="text-sm font-medium text-muted-foreground mb-2">Entregar llave:</p>
        <div className="flex flex-wrap gap-2">
          {vigilantes.map(v => (
            <Button key={v.id} variant={v.esJefe ? 'default' : 'outline'} size="sm" className="gap-2" onClick={() => onEntregar(v.nombre)}>
              {v.esJefe && <CheckCircle className="w-3 h-3" />}
              {v.nombre}
            </Button>
          ))}
          {vigilantesAnteriores.length > 0 && (
            <>
              <div className="w-px h-6 bg-border mx-1" />
              {vigilantesAnteriores.map(v => (
                <Button key={v.id} variant="ghost" size="sm" className="gap-2 text-muted-foreground hover:bg-muted/50" onClick={() => onEntregar(v.nombre)}>
                  {v.nombre}<span className="text-xs">(turno ant.)</span>
                </Button>
              ))}
            </>
          )}
        </div>
      </div>
    </Card>
  );
}
