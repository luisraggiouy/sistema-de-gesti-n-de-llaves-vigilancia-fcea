import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SolicitudLlave } from '@/types/solicitud';
import { Vigilante } from '@/data/fceaData';
import { formatearUbicacion, getColorTipoLugar } from '@/data/fceaData';
import { Key, MapPin, User, Phone, Clock, CheckCircle, Building2 } from 'lucide-react';
import { formatearDuracion, VENTANA_AHORA_SEG } from '@/utils/tiempoEspera';


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
 * El texto del contador y el color se recalculan automaticamente en
 * cada re-render del padre (MonitorVigilancia hace setTick cada 1s).
 *
 * v4.5 (fix 2026-07-31 — contador "Hace 300 min" al llegar el pedido):
 *   - ANTES: el contador se anclaba a `horaSolicitud`, timestamp generado
 *     por la Terminal. Si la Terminal y el Monitor tenian configuracion de
 *     zona horaria distinta (aunque el reloj de pared se viera igual), el
 *     epoch absoluto difria en horas -> aparecia "Hace 300 min" apenas
 *     llegaba el pedido.
 *   - AHORA: se ancla a `horaCreacionServidor` (campo `created` que genera
 *     PocketBase, que corre EN el Monitor). Asi ambos extremos de la resta
 *     usan el MISMO reloj (el del Monitor) y nunca hay desfase entre PCs.
 *
 * v4.6 (upgrade 2026-07-31 — formato de reloj y borde permanente):
 *   - Formato escalonado (helper compartido `tiempoEspera.ts`):
 *       < 10 s  -> "Ahora"
 *       < 1 min -> "Hace menos de 1 minuto"
 *       < 1 h   -> "Hace X minutos"
 *       >= 1 h  -> "Hace HH:MM:SS"
 *   - Se QUITARON los colores de urgencia por tiempo (gris/amarillo/rojo).
 *     En su lugar, TODA solicitud pendiente lleva un CONTORNO ROJO FIRME
 *     (rojo firme, no alarmante) mientras no se entregue, para que se vea
 *     de lejos (vigilante a 2+ m) y no se confunda con "llaves en uso".
 *   - El contador se recalcula en cada re-render (MonitorVigilancia hace
 *     setTick cada 1s).
 */

interface PendingRequestCardProps {
  solicitud: SolicitudLlave;
  vigilantes: Vigilante[];
  vigilantesAnteriores?: Vigilante[];
  onEntregar: (vigilante: string) => void;
}

export function PendingRequestCard({ solicitud, vigilantes, vigilantesAnteriores = [], onEntregar }: PendingRequestCardProps) {
  const colorTipo = getColorTipoLugar(solicitud.lugar.tipo);

  // Ancla del contador: preferimos `horaCreacionServidor` (campo `created` de
  // PocketBase, generado por el server que corre EN el Monitor) para que la
  // resta use el MISMO reloj que el Date.now() del Monitor y no haya desfase
  // entre PCs. Si por algun motivo no viniera (registro viejo / offline), caemos
  // a `horaSolicitud`.
  const referencia = solicitud.horaCreacionServidor ?? solicitud.horaSolicitud;

  // Segundos transcurridos (clamp a 0 para no mostrar negativos ante micro-skew).
  const segundosEspera = Math.max(
    0,
    Math.floor((Date.now() - new Date(referencia).getTime()) / 1000),
  );

  const tiempoDesdeCreacion = () => {
    // Primeros 10 segundos: "Ahora" (sin numero). Tambien absorbe el pequeño
    // retardo entre que PocketBase inserta y el poll del Monitor lo levanta.
    if (segundosEspera < VENTANA_AHORA_SEG) return 'Ahora';
    return `Hace ${formatearDuracion(segundosEspera)}`;
  };

  // Contorno rojo FIRME permanente mientras la solicitud siga pendiente (no se
  // haya entregado). Objetivo: que el listado de PEDIDOS llame la atencion desde
  // 2+ metros y no se confunda con el listado de "llaves en uso". Se usa un rojo
  // solido pero no "destructive" intenso, para no generar sensacion de alarma.
  const cardBorderClass = 'border-red-500 border-2';
  const clockColorClass = 'text-red-600 font-semibold';

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
