import { useState, useEffect, useRef } from 'react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Textarea } from '@/components/ui/textarea';
import { SolicitudLlave, AccionUndo } from '@/types/solicitud';
import { Vigilante } from '@/data/fceaData';
import { formatearUbicacion, getColorTipoLugar } from '@/data/fceaData';
import { Key, MapPin, Clock, Undo2, ArrowRightLeft, StickyNote, Check, Copy, MessageCircle } from 'lucide-react';
import { KeyExchangeModal } from './KeyExchangeModal';

interface KeyInUseCardProps {
  solicitud: SolicitudLlave;
  undoAction?: AccionUndo;
  vigilantes: Vigilante[];
  vigilantesAnteriores?: Vigilante[];
  tiempoAlertaMinutos: number;
  mensajeWhatsApp: string;
  onDevolver: (vigilante: string) => void;
  onUndo: () => void;
  onIntercambiar: (vigilante: string, nuevoUsuario: { nombre: string; celular: string; tipo: string }) => void;
  onNotasChange: (notas: string) => void;
}

export function KeyInUseCard({
  solicitud, undoAction, vigilantes, vigilantesAnteriores = [],
  tiempoAlertaMinutos, mensajeWhatsApp, onDevolver, onUndo, onIntercambiar, onNotasChange
}: KeyInUseCardProps) {
  const [tiempoRestanteUndo, setTiempoRestanteUndo] = useState<number>(0);
  const [tiempoEnUso, setTiempoEnUso] = useState<number>(0);
  const [exchangeModalOpen, setExchangeModalOpen] = useState(false);
  const [notasLocal, setNotasLocal] = useState(solicitud.notas || '');
  const [notasFocused, setNotasFocused] = useState(false);
  const [mostrarMensaje, setMostrarMensaje] = useState(false);
  const [whatsappEnviado, setWhatsappEnviado] = useState(false);
  const [mensajeCopiado, setMensajeCopiado] = useState(false);
  const inicializadoRef = useRef(false);

  useEffect(() => {
    if (!inicializadoRef.current && solicitud.notas !== undefined) {
      setNotasLocal(solicitud.notas || '');
      inicializadoRef.current = true;
    }
  }, [solicitud.notas]);

  useEffect(() => {
    if (!notasFocused) setNotasLocal(solicitud.notas || '');
  }, [solicitud.id]);

  useEffect(() => {
    if (!undoAction) { setTiempoRestanteUndo(0); return; }
    const updateTimer = () => {
      const remaining = Math.max(0, undoAction.expiresAt.getTime() - Date.now());
      setTiempoRestanteUndo(Math.ceil(remaining / 1000));
    };
    updateTimer();
    const interval = setInterval(updateTimer, 1000);
    return () => clearInterval(interval);
  }, [undoAction]);

  // Timer para tiempo en uso — usa string de fecha directamente para evitar problemas de referencia
  useEffect(() => {
    const horaEntregaStr = solicitud.horaEntrega
      ? (solicitud.horaEntrega instanceof Date
          ? solicitud.horaEntrega.toISOString()
          : String(solicitud.horaEntrega))
      : null;

    if (!horaEntregaStr) {
      setTiempoEnUso(0);
      return;
    }

    const horaEntregaMs = new Date(horaEntregaStr).getTime();

    const update = () => {
      const diff = Math.floor((Date.now() - horaEntregaMs) / 1000);
      setTiempoEnUso(Math.max(0, diff));
    };

    update();
    const interval = setInterval(update, 1000);
    return () => clearInterval(interval);
  }, [solicitud.id]); // Usar solicitud.id como dependencia, más estable

  const formatTiempoUndo = (s: number) => `${Math.floor(s / 60)}:${(s % 60).toString().padStart(2, '0')}`;
  const formatTiempoEnUso = (s: number) => {
    const h = Math.floor(s / 3600);
    const m = Math.floor((s % 3600) / 60);
    return h > 0 ? `${h}h ${m}m` : `${m}m`;
  };

  const tiempoEnUsoMinutos = tiempoEnUso / 60;
  const tiposConAlerta = ['Salón', 'Salón Híbrido'];
  const aplicaAlerta = !solicitud.lugar.tipo || tiposConAlerta.includes(solicitud.lugar.tipo);
  const estaEnAlerta = aplicaAlerta && tiempoEnUsoMinutos >= tiempoAlertaMinutos;
  const colorTipo = getColorTipoLugar(solicitud.lugar.tipo);

  const mensajeTexto = mensajeWhatsApp.replace('{{LLAVE}}', solicitud.lugar.nombre);

  const handleCopiarMensaje = () => {
    navigator.clipboard.writeText(mensajeTexto);
    setMensajeCopiado(true);
    setTimeout(() => setMensajeCopiado(false), 2000);
  };

  if (undoAction && tiempoRestanteUndo > 0) {
    return (
      <Card className="p-4 border-2 border-warning bg-warning/5 relative overflow-hidden">
        <div className="absolute top-0 left-0 h-1 bg-warning transition-all" style={{ width: `${(tiempoRestanteUndo / 120) * 100}%` }} />
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={`p-2 rounded-lg ${colorTipo}`}><Key className="w-5 h-5 text-white" /></div>
            <div>
              <p className="font-semibold">{solicitud.lugar.nombre}</p>
              <p className="text-sm text-muted-foreground">Entregada por {undoAction.vigilante}</p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <div className="text-right">
              <p className="text-lg font-mono font-bold text-warning">{formatTiempoUndo(tiempoRestanteUndo)}</p>
              <p className="text-xs text-muted-foreground">para deshacer</p>
            </div>
            <Button variant="outline" className="gap-2 border-warning text-warning hover:bg-warning hover:text-warning-foreground" onClick={onUndo}>
              <Undo2 className="w-4 h-4" />Deshacer
            </Button>
          </div>
        </div>
      </Card>
    );
  }

  return (
    <Card className={`p-4 ${estaEnAlerta ? 'bg-destructive/5 border-destructive/30' : 'bg-rose-50 border-rose-200'}`}>
      <div className="flex flex-col lg:flex-row lg:items-center gap-4">
        <div className="flex items-start gap-3 flex-1">
          <div className={`p-3 rounded-xl ${colorTipo}`}><Key className="w-6 h-6 text-white" /></div>
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-1 flex-wrap">
              <h3 className="font-semibold text-lg">{solicitud.lugar.nombre}</h3>
              <Badge className="bg-success text-success-foreground text-xs">En uso</Badge>
              {solicitud.esIntercambio && (
                <Badge variant="outline" className="text-xs border-primary/30 text-primary">
                  <ArrowRightLeft className="w-3 h-3 mr-1" />Intercambio
                </Badge>
              )}
              {estaEnAlerta && (
                <span className="relative flex h-3 w-3">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-destructive opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-3 w-3 bg-destructive"></span>
                </span>
              )}
            </div>
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <MapPin className="w-4 h-4" />
              <span className="font-mono">{formatearUbicacion(solicitud.lugar.ubicacion)}</span>
            </div>
            <div className="mt-1 space-y-1">
              {/* Solo mostrar como intercambio cuando esIntercambio=true */}
              {solicitud.esIntercambio ? (
                <div className="text-sm space-y-0.5 bg-primary/5 border border-primary/20 rounded-md px-2 py-1.5">
                  <p className="text-xs font-semibold text-primary uppercase tracking-wide mb-1">Intercambio de llave</p>
                  <p className="leading-tight">
                    <span className="text-muted-foreground">Entregó: </span>
                    <span className="font-medium">{solicitud.usuarioAnterior?.nombre ?? solicitud.entregadoPor}</span>
                    {solicitud.usuarioAnterior && (
                      <>
                        <span className="text-muted-foreground ml-1">· {solicitud.usuarioAnterior.tipo}</span>
                        {solicitud.usuarioAnterior.tipo === 'Personal TAS' && solicitud.usuarioAnterior.departamento && (
                          <span className="text-muted-foreground ml-1">· Depto: <span className="font-medium text-foreground">{solicitud.usuarioAnterior.departamento}</span></span>
                        )}
                        {solicitud.usuarioAnterior.tipo === 'Empresa' && solicitud.usuarioAnterior.nombreEmpresa && (
                          <span className="text-muted-foreground ml-1">· <span className="font-medium text-foreground">{solicitud.usuarioAnterior.nombreEmpresa}</span></span>
                        )}
                      </>
                    )}
                  </p>
                  <p className="leading-tight">
                    <span className="text-muted-foreground">Recibió: </span>
                    <span className="font-medium">{solicitud.usuario.nombre}</span>
                    <span className="text-muted-foreground ml-1">· {solicitud.usuario.tipo}</span>
                    {solicitud.usuario.tipo === 'Personal TAS' && solicitud.usuario.departamento && (
                      <span className="text-muted-foreground ml-1">· Depto: <span className="font-medium text-foreground">{solicitud.usuario.departamento}</span></span>
                    )}
                    {solicitud.usuario.tipo === 'Empresa' && solicitud.usuario.nombreEmpresa && (
                      <span className="text-muted-foreground ml-1">· <span className="font-medium text-foreground">{solicitud.usuario.nombreEmpresa}</span></span>
                    )}
                  </p>
                </div>
              ) : (
                <>
                  <p className="text-base leading-tight">
                    <span>Entregada por </span>
                    <span className="font-medium">{solicitud.entregadoPor}</span>
                    {solicitud.terminal && (
                      <span className="text-sm ml-1">· Terminal: <span className="font-medium">{solicitud.terminal}</span></span>
                    )}
                  </p>
                  <p className="text-base leading-tight">
                    <span>A cargo de </span>
                    <span className="font-medium">{solicitud.usuario.nombre}</span>
                    <span className="text-sm ml-1">· {solicitud.usuario.tipo}</span>
                    {solicitud.usuario.tipo === 'Personal TAS' && solicitud.usuario.departamento && (
                      <span className="text-sm ml-1">· Depto: <span className="font-medium">{solicitud.usuario.departamento}</span></span>
                    )}
                    {solicitud.usuario.tipo === 'Empresa' && solicitud.usuario.nombreEmpresa && (
                      <span className="text-sm ml-1">· <span className="font-medium">{solicitud.usuario.nombreEmpresa}</span></span>
                    )}
                  </p>
                </>
              )}
            </div>
          </div>
        </div>

        <div className={`flex items-center gap-2 px-3 py-2 rounded-lg ${estaEnAlerta ? 'bg-destructive/10' : 'bg-muted/50'}`}>
          <Clock className={`w-4 h-4 ${estaEnAlerta ? 'text-destructive' : 'text-muted-foreground'}`} />
          <div>
            <p className={`text-sm font-medium ${estaEnAlerta ? 'text-destructive' : ''}`}>
              En uso hace {formatTiempoEnUso(tiempoEnUso)}
            </p>
            {estaEnAlerta && <p className="text-xs text-destructive">Tiempo excedido</p>}
          </div>
        </div>
      </div>

      {/* Panel WhatsApp offline */}
      {estaEnAlerta && (
        <div className="mt-4 flex justify-end">
          <div className={`rounded-xl border-2 overflow-hidden transition-all max-w-md ${whatsappEnviado ? 'border-green-700 bg-green-700' : 'border-green-500 bg-green-500'}`}>
            <div className="p-2">
              <div className="flex items-center gap-2 mb-2">
                <MessageCircle className="w-5 h-5 text-white flex-shrink-0" />
                <div>
                  <p className="text-white font-bold text-sm">{solicitud.usuario.nombre}</p>
                  <p className="text-green-100 text-xl font-mono font-bold">{solicitud.usuario.celular}</p>
                </div>
              </div>
              
              <div className="flex items-center justify-between">
                <Button size="sm" variant="ghost" className="text-white hover:bg-green-600 text-sm h-9 px-4" onClick={() => setMostrarMensaje(!mostrarMensaje)}>
                  {mostrarMensaje ? 'Ocultar' : 'Ver mensaje sugerido'}
                </Button>
                
                {!whatsappEnviado ? (
                <Button size="sm" className="bg-white text-green-700 hover:bg-green-50 font-semibold text-xs h-12 px-4 flex flex-col" onClick={() => setWhatsappEnviado(true)}>
                  <div className="flex items-center">
                    <Check className="w-4 h-4 mr-1" />Confirmo envío
                  </div>
                  <div>desde cel. vigilancia</div>
                </Button>
                ) : (
                  <div className="text-center w-full">
                    <span className="text-white text-xs font-semibold flex flex-col items-center justify-center">
                      <span className="flex items-center"><Check className="w-3 h-3 mr-1" /> Confirmado envío desde</span>
                      <span>celular de vigilancia</span>
                    </span>
                  </div>
                )}
              </div>
            </div>
            {mostrarMensaje && (
              <div className="px-2 pb-2">
                <div className="bg-white/20 rounded-lg p-2 text-white text-xs">{mensajeTexto}</div>
                <Button size="sm" variant="ghost" className="mt-1 text-white hover:bg-green-600 gap-1 text-xs h-8 px-3" onClick={handleCopiarMensaje}>
                  {mensajeCopiado ? <><Check className="w-4 h-4" /> Copiado</> : <><Copy className="w-4 h-4" /> Copiar</>}
                </Button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Devolución — sin botón Intercambiar */}
      <div className="mt-4 pt-4 border-t border-success/20">
        <p className="text-sm font-medium text-muted-foreground mb-2">Registrar devolución:</p>
        <div className="flex flex-wrap gap-2">
          {vigilantes.map(v => (
            <Button key={v.id} variant="outline" size="sm" className="gap-2 border-success/30 hover:bg-success/10 h-10 px-4" onClick={() => onDevolver(v.nombre)}>
              {v.esJefe && <span className="w-2 h-2 rounded-full bg-primary" />}
              {v.nombre}
            </Button>
          ))}
          {vigilantesAnteriores.length > 0 && (
            <>
              <div className="w-px h-6 bg-border mx-1" />
              {vigilantesAnteriores.map(v => (
                <Button key={v.id} variant="ghost" size="sm" className="gap-2 text-muted-foreground hover:bg-muted/50 h-10 px-4" onClick={() => onDevolver(v.nombre)}>
                  {v.nombre}<span className="text-xs">(turno ant.)</span>
                </Button>
              ))}
            </>
          )}
        </div>
      </div>

      {/* Notas */}
      <div className="mt-3 pt-3 border-t border-rose-200">
        <div className="flex items-center gap-2 mb-1">
          <StickyNote className="w-3.5 h-3.5 text-muted-foreground" />
          <span className="text-xs font-medium text-muted-foreground">Notas</span>
        </div>
        <Textarea
          placeholder="Anotar particularidades..."
          value={notasLocal}
          onChange={(e) => { setNotasFocused(true); setNotasLocal(e.target.value); }}
          onFocus={() => setNotasFocused(true)}
          onBlur={() => { setNotasFocused(false); onNotasChange(notasLocal); }}
          className="min-h-[40px] h-10 text-sm resize-none bg-white/50"
          rows={1}
        />
      </div>

      <KeyExchangeModal
        open={exchangeModalOpen}
        onOpenChange={setExchangeModalOpen}
        solicitud={solicitud}
        vigilantes={vigilantes}
        vigilantesAnteriores={vigilantesAnteriores}
        onConfirmar={onIntercambiar}
      />
    </Card>
  );
}