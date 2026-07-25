/**
 * formatTiempoEspera
 * -------------------------------------------------------------------------
 * Formato humano para "cuanto hace que llego esta solicitud".
 *
 * Reglas (piloto sabado 2026-07-25):
 *   - < 1 min          -> "Ahora"
 *   - 1 min            -> "Hace 1 min"
 *   - 2..59 min        -> "Hace X min"
 *   - 60 min en mas    -> "Hace Xh Ym"  (ej: "Hace 1h 05m", "Hace 5h 00m")
 *   - >= 24h           -> "Hace Xd Yh"  (ej: "Hace 2d 03h")
 *
 * Antes se mostraba "Hace 300 min" que es totalmente ilegible. Un usuario
 * tiene que hacer la cuenta mental 300 / 60 = 5h. La regla nueva pasa
 * directo a Xh Ym cuando la espera es de 1 hora o mas.
 *
 * Se evita HH:MM porque se puede confundir con la hora del reloj de pared
 * (ej: "Hace 05:00" parece "las cinco en punto"). El sufijo h/m/d elimina
 * la ambiguedad.
 *
 * Nota: acepta valores negativos (por diferencia de reloj entre terminal
 * y monitor) devolviendo "Ahora", para no mostrar "Hace -3 min" que se ve
 * como error.
 */
export function formatTiempoEspera(minutos: number): string {
  if (!Number.isFinite(minutos) || minutos < 1) return 'Ahora';
  if (minutos === 1) return 'Hace 1 min';
  if (minutos < 60) return `Hace ${minutos} min`;

  const dias = Math.floor(minutos / (60 * 24));
  const horas = Math.floor((minutos % (60 * 24)) / 60);
  const mins = minutos % 60;

  if (dias >= 1) {
    // "Hace 1d 03h" / "Hace 2d 00h"
    return `Hace ${dias}d ${horas.toString().padStart(2, '0')}h`;
  }
  // "Hace 1h 05m" / "Hace 5h 00m"
  return `Hace ${horas}h ${mins.toString().padStart(2, '0')}m`;
}

/**
 * Convierte una fecha ISO / Date al numero de minutos transcurridos hasta
 * ahora, con piso 0. Centraliza el calculo para que no se repita en cada
 * componente y para que si en el futuro hay que ajustarlo por zonas
 * horarias, se toque un solo lugar.
 */
export function minutosDesde(fecha: Date | string | number): number {
  const t = typeof fecha === 'string' || typeof fecha === 'number'
    ? new Date(fecha).getTime()
    : fecha.getTime();
  if (!Number.isFinite(t)) return 0;
  return Math.max(0, Math.floor((Date.now() - t) / 60000));
}
