import { useCallback, useEffect, useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { getRuntimeConfig } from '@/lib/runtimeConfig';
import { obtenerErrores, limpiarErrores, suscribirErrores, type EntradaError } from '@/lib/errorLog';
import { Copy, RefreshCcw, Trash2, X, ActivitySquare } from 'lucide-react';
import pb from '@/lib/pocketbase';

/**
 * Modal de diagnostico para terminales tactiles (donde DevTools esta
 * bloqueado por la organizacion).
 *
 * ACCESOS:
 *   1. Teclado: `Ctrl + Shift + D` (queda igual, sirve al tecnico
 *      que enchufa un teclado USB en la Terminal para depurar).
 *   2. Boton discreto en el header del Monitor Vigilancia (icono
 *      ActivitySquare pequenio, junto a los demas botones). Ver
 *      MonitorHeader.tsx.
 *
 * NOTA v2.6 (jueves FCEA): se REMOVIO el gesto de "5 toques rapidos"
 * porque en el pilotaje del 21-jul-2026 se disparaba solo cada tanto
 * en las Terminales tactiles (probable: rebote del digitalizador
 * resistivo generando pointerdown repetidos), abriendo el modal en
 * medio del flujo de usuario. En su lugar, para operar la Terminal
 * sin teclado, se puede pasar la Terminal al Monitor via Alt+F4 y
 * abrir el diagnostico desde alli con el boton discreto.
 *
 * PROPS opcionales para control externo (usado por MonitorHeader):
 *   - open / onOpenChange: si se pasan, el modal es controlado.
 *     Si se omiten, el modal es 100% auto-controlado (Ctrl+Shift+D).
 *
 * MUESTRA:
 *   - Config runtime (rol, hardware, url PocketBase)
 *   - Ping/health de PocketBase
 *   - Ultimos 40 errores capturados por el logger global
 *   - Boton "Copiar diagnostico" (JSON portapapeles)
 *   - Boton "Reintentar ping"
 *   - Boton "Limpiar errores"
 *   - Boton "Cerrar"
 */

interface PingResult {
  ok: boolean;
  status?: number;
  ms?: number;
  message?: string;
}

interface DiagnosticoModalProps {
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
}

export function DiagnosticoModal({ open: openProp, onOpenChange }: DiagnosticoModalProps = {}) {
  const [openInternal, setOpenInternal] = useState(false);
  const isControlled = openProp !== undefined;
  const open = isControlled ? !!openProp : openInternal;
  const setOpen = (v: boolean | ((prev: boolean) => boolean)) => {
    const next = typeof v === 'function' ? (v as (p: boolean) => boolean)(open) : v;
    if (isControlled) {
      onOpenChange?.(next);
    } else {
      setOpenInternal(next);
    }
  };
  const [errores, setErrores] = useState<EntradaError[]>([]);
  const [ping, setPing] = useState<PingResult | null>(null);
  const [pingLoading, setPingLoading] = useState(false);

  const config = (() => {
    try { return getRuntimeConfig(); } catch { return null; }
  })();

  const pocketbaseUrl = (config?.pocketbase_url as string) ?? pb.baseUrl ?? '(desconocido)';

  const refrescarErrores = useCallback(() => {
    setErrores(obtenerErrores());
  }, []);

  const doPing = useCallback(async () => {
    setPingLoading(true);
    const t0 = performance.now();
    try {
      // /api/health es endpoint publico de PocketBase, no requiere auth.
      const resp = await fetch(`${pocketbaseUrl.replace(/\/$/, '')}/api/health`, {
        method: 'GET',
        cache: 'no-store',
      });
      const ms = Math.round(performance.now() - t0);
      setPing({ ok: resp.ok, status: resp.status, ms });
    } catch (e) {
      const ms = Math.round(performance.now() - t0);
      setPing({ ok: false, ms, message: e instanceof Error ? e.message : String(e) });
    } finally {
      setPingLoading(false);
    }
  }, [pocketbaseUrl]);

  // Al abrir el modal: refrescar errores + hacer ping
  useEffect(() => {
    if (!open) return;
    refrescarErrores();
    void doPing();
  }, [open, refrescarErrores, doPing]);

  // Suscribirse a cambios en el buffer de errores mientras esta abierto
  useEffect(() => {
    if (!open) return;
    return suscribirErrores(refrescarErrores);
  }, [open, refrescarErrores]);

  // Atajo de teclado Ctrl+Shift+D
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.ctrlKey && e.shiftKey && (e.key === 'D' || e.key === 'd')) {
        e.preventDefault();
        setOpen((v) => !v);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  // v2.6: se REMOVIO el gesto "5 toques rapidos" que abria el modal
  // porque en las Terminales tactiles resistivas del piloto FCEA se
  // disparaba solo (rebote del digitalizador). El modal ahora se abre
  // exclusivamente con Ctrl+Shift+D o desde el boton discreto del
  // header del Monitor Vigilancia.

  const copiarDiagnostico = async () => {
    const payload = {
      timestamp: new Date().toISOString(),
      userAgent: navigator.userAgent,
      href: window.location.href,
      config: {
        rol: (config as { rol?: string } | null)?.rol,
        hardware: (config as { hardware?: string } | null)?.hardware,
        pocketbase_url: pocketbaseUrl,
      },
      ping,
      errores,
    };
    const txt = JSON.stringify(payload, null, 2);
    try {
      await navigator.clipboard.writeText(txt);
      alert('Diagnostico copiado al portapapeles.');
    } catch {
      // Fallback: mostrar en un prompt para copiar manualmente
      window.prompt('Copie manualmente (Ctrl+C):', txt);
    }
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent className="w-[95vw] max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <ActivitySquare className="w-5 h-5" />
            Diagnóstico del sistema
          </DialogTitle>
          <DialogDescription>
            Panel de diagnóstico para técnicos. Se abre con Ctrl+Shift+D o desde el botón de diagnóstico del Monitor Vigilancia.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 text-sm">
          {/* Configuracion */}
          <section className="rounded-md border p-3">
            <h3 className="font-semibold mb-2">Configuración runtime</h3>
            <dl className="grid grid-cols-[max-content_1fr] gap-x-4 gap-y-1">
              <dt className="text-muted-foreground">Rol:</dt>
              <dd className="font-mono">{(config as { rol?: string } | null)?.rol ?? '(sin definir)'}</dd>
              <dt className="text-muted-foreground">Hardware:</dt>
              <dd className="font-mono">{(config as { hardware?: string } | null)?.hardware ?? '(sin definir)'}</dd>
              <dt className="text-muted-foreground">PocketBase URL:</dt>
              <dd className="font-mono break-all">{pocketbaseUrl}</dd>
              <dt className="text-muted-foreground">User Agent:</dt>
              <dd className="font-mono break-all text-xs">{navigator.userAgent}</dd>
            </dl>
          </section>

          {/* Ping */}
          <section className="rounded-md border p-3">
            <div className="flex items-center justify-between mb-2">
              <h3 className="font-semibold">Conectividad con PocketBase</h3>
              <Button size="sm" variant="outline" onClick={doPing} disabled={pingLoading} className="gap-1">
                <RefreshCcw className={`w-4 h-4 ${pingLoading ? 'animate-spin' : ''}`} />
                Reintentar
              </Button>
            </div>
            {ping == null ? (
              <p className="text-muted-foreground">Ejecutando ping...</p>
            ) : ping.ok ? (
              <p className="text-success">
                ✓ OK — HTTP {ping.status} — {ping.ms} ms
              </p>
            ) : (
              <div>
                <p className="text-destructive font-medium">
                  ✗ FALLO {ping.status ? `— HTTP ${ping.status}` : ''} — {ping.ms} ms
                </p>
                {ping.message && (
                  <p className="text-xs text-destructive mt-1 font-mono break-all">
                    {ping.message}
                  </p>
                )}
                <p className="text-xs text-muted-foreground mt-2">
                  Posibles causas: el servidor (Monitor Vigilancia) no está encendido, PocketBase no está corriendo, o la URL está mal configurada en <code>public/config.json</code>.
                </p>
              </div>
            )}
          </section>

          {/* Errores */}
          <section className="rounded-md border p-3">
            <div className="flex items-center justify-between mb-2">
              <h3 className="font-semibold">Últimos errores ({errores.length})</h3>
              <Button
                size="sm"
                variant="outline"
                onClick={() => { limpiarErrores(); refrescarErrores(); }}
                className="gap-1"
              >
                <Trash2 className="w-4 h-4" /> Limpiar
              </Button>
            </div>
            {errores.length === 0 ? (
              <p className="text-muted-foreground">Sin errores registrados.</p>
            ) : (
              <ul className="space-y-2 max-h-64 overflow-y-auto">
                {errores.map((e, i) => (
                  <li key={i} className="rounded bg-destructive/10 border border-destructive/30 p-2">
                    <div className="flex justify-between items-baseline gap-2">
                      <span className="font-mono text-xs text-muted-foreground">
                        {new Date(e.timestamp).toLocaleTimeString()}
                      </span>
                      <span className="text-xs font-semibold text-destructive">[{e.contexto}]</span>
                    </div>
                    <div className="font-mono text-xs break-all mt-1">{e.mensaje}</div>
                    {e.detalleJson && e.detalleJson !== '{}' && (
                      <details className="mt-1">
                        <summary className="text-xs text-muted-foreground cursor-pointer">Ver detalle</summary>
                        <pre className="text-[10px] mt-1 whitespace-pre-wrap break-all bg-background/50 p-1 rounded">
                          {e.detalleJson}
                        </pre>
                      </details>
                    )}
                  </li>
                ))}
              </ul>
            )}
          </section>
        </div>

        <div className="flex flex-wrap gap-2 justify-end pt-2 border-t">
          <Button variant="outline" onClick={copiarDiagnostico} className="gap-1">
            <Copy className="w-4 h-4" /> Copiar diagnóstico
          </Button>
          <Button onClick={() => setOpen(false)} className="gap-1">
            <X className="w-4 h-4" /> Cerrar
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
