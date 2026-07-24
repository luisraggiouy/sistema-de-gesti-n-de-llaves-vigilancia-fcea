/**
 * Logger global de errores en memoria.
 *
 * En las terminales tactiles instaladas como kiosk, la organizacion
 * puede tener bloqueado el uso de DevTools (F12). Sin acceso a la
 * consola del navegador es imposible diagnosticar errores de red /
 * PocketBase / permisos.
 *
 * Este modulo captura los errores mas relevantes en un buffer
 * en-memoria (max 40) y los expone a la UI via `DiagnosticoModal`.
 *
 * Uso:
 *   import { registrarError, obtenerErrores } from '@/lib/errorLog';
 *   try { ... } catch (e) { registrarError('registro-usuario', e); }
 */

export interface EntradaError {
  timestamp: string;
  contexto: string;
  mensaje: string;
  detalleJson?: string;
}

const MAX_ENTRADAS = 40;
let buffer: EntradaError[] = [];
const listeners: Set<() => void> = new Set();

/**
 * Extrae la parte util de un error de PocketBase / fetch / Error nativo.
 * PocketBase devuelve objetos con { status, message, data }.
 */
function normalizar(e: unknown): { mensaje: string; detalleJson?: string } {
  if (e == null) return { mensaje: 'Error desconocido (null/undefined)' };

  // PocketBase ClientResponseError: tiene .status, .message, .data
  const anyE = e as {
    status?: number;
    message?: string;
    data?: unknown;
    name?: string;
    stack?: string;
    url?: string;
  };

  const partes: string[] = [];
  if (typeof anyE.status === 'number') partes.push(`HTTP ${anyE.status}`);
  if (anyE.name && anyE.name !== 'Error') partes.push(anyE.name);
  if (anyE.message) partes.push(anyE.message);
  if (anyE.url) partes.push(`(${anyE.url})`);

  let detalleJson: string | undefined;
  try {
    // Sanitizamos: solo campos serializables razonables.
    const snapshot = {
      status: anyE.status,
      message: anyE.message,
      name: anyE.name,
      url: anyE.url,
      data: anyE.data,
    };
    detalleJson = JSON.stringify(snapshot, null, 2);
  } catch {
    detalleJson = String(e);
  }

  const mensaje = partes.length > 0 ? partes.join(' — ') : String(e);
  return { mensaje, detalleJson };
}

export function registrarError(contexto: string, error: unknown): void {
  const { mensaje, detalleJson } = normalizar(error);
  const entrada: EntradaError = {
    timestamp: new Date().toISOString(),
    contexto,
    mensaje,
    detalleJson,
  };
  buffer = [entrada, ...buffer].slice(0, MAX_ENTRADAS);
  // Mantener el console.error tambien: si algun dia hay DevTools, mejor.
  // eslint-disable-next-line no-console
  console.error(`[${contexto}]`, error);
  listeners.forEach((cb) => {
    try { cb(); } catch { /* ignorar */ }
  });
}

export function obtenerErrores(): EntradaError[] {
  return [...buffer];
}

export function limpiarErrores(): void {
  buffer = [];
  listeners.forEach((cb) => {
    try { cb(); } catch { /* ignorar */ }
  });
}

/**
 * Suscribe un callback que se dispara cada vez que se registra o
 * limpia un error. Devuelve la funcion para desuscribirse.
 */
export function suscribirErrores(cb: () => void): () => void {
  listeners.add(cb);
  return () => { listeners.delete(cb); };
}

/**
 * Hook de conveniencia opcional para instalar los listeners globales
 * de errores no capturados en window. Se llama una vez en el bootstrap
 * de la app (main.tsx).
 */
export function instalarListenersGlobales(): void {
  if (typeof window === 'undefined') return;

  window.addEventListener('error', (ev) => {
    registrarError('window.error', ev.error ?? ev.message);
  });

  window.addEventListener('unhandledrejection', (ev) => {
    registrarError('unhandledrejection', ev.reason);
  });
}
