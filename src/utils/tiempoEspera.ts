/**
 * tiempoEspera.ts — helper compartido de formato de tiempo transcurrido.
 *
 * Se usa en el Monitor Vigilancia tanto para las SOLICITUDES pendientes
 * (PendingRequestCard) como para las LLAVES EN USO (KeyInUseCard), para que
 * ambas listas muestren el tiempo con el MISMO criterio y estética.
 *
 * Regla de formato (definida con Luis el 31/07/2026):
 *   - < 10 s          -> caso "recién" (cada card decide el texto: "Ahora" /
 *                        "Recién entregada"). Ver VENTANA_AHORA_SEG.
 *   - 10 s  – < 1 min -> "menos de 1 minuto"
 *   - 1 min – < 1 h   -> "X minutos" (singular/plural correcto)
 *   - >= 1 h          -> formato HH:MM:SS (para distinguir demoras largas)
 *
 * El motivo del cambio: entre pedido y entrega la demora normal es corta, así
 * que mostrar minutos redondos es más legible que un cronómetro corriendo; y
 * recién si algo se demora más de una hora tiene sentido el detalle HH:MM:SS.
 */

/** Segundos por debajo de los cuales se considera "recién" (mostrar "Ahora"). */
export const VENTANA_AHORA_SEG = 10;

/** Formatea una cantidad de segundos como HH:MM:SS (siempre 2 dígitos). */
export function formatHHMMSS(totalSegundos: number): string {
  const h = Math.floor(totalSegundos / 3600);
  const m = Math.floor((totalSegundos % 3600) / 60);
  const s = totalSegundos % 60;
  const pad = (n: number) => n.toString().padStart(2, '0');
  return `${pad(h)}:${pad(m)}:${pad(s)}`;
}

/**
 * Devuelve SOLO la duración formateada según la regla escalonada, SIN prefijo
 * ni caso "recién" (eso lo decide cada card). Pensado para usarse cuando ya se
 * sabe que `segundos >= VENTANA_AHORA_SEG`.
 *
 *   10..59 s  -> "menos de 1 minuto"
 *   1..59 min -> "1 minuto" / "N minutos"
 *   >= 1 h    -> "HH:MM:SS"
 */
export function formatearDuracion(segundos: number): string {
  const seg = Math.max(0, Math.floor(segundos));
  if (seg >= 3600) return formatHHMMSS(seg);
  if (seg < 60) return 'menos de 1 minuto';
  const min = Math.floor(seg / 60);
  return `${min} ${min === 1 ? 'minuto' : 'minutos'}`;
}
