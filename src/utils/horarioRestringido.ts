/**
 * Restriccion de botones del Monitor durante el turno nocturno (22:20 a 06:00).
 *
 * Upgrade 2026-09-26: la restriccion ahora ARRANCA a las 22:20 (antes 22:00).
 * Se le "achican" 20 minutos al inicio para dar margen al cambio de turno; el
 * fin (06:00) queda igual. Ver esHorarioRestringido() mas abajo.
 *
 * Upgrade 2026-08-20: de noche la dinamica es distinta y, por desconocimiento,
 * se podrian borrar datos clave. Por eso se DESHABILITAN los botones que
 * permiten modificar datos (Objetos, Agenda/Autorizaciones, Configuracion,
 * Vigilantes, Llaves y Dashboard). Queda activo "Historial" (solo lectura) y
 * toda la operativa principal de entrega/devolucion de llaves.
 *
 * Para REACTIVAR un boton en el futuro, quitarlo de BOTONES_BLOQUEADOS_DE_NOCHE.
 */
export const BOTONES_BLOQUEADOS_DE_NOCHE = [
  'objetos',
  'agenda',
  'configuracion',
  'vigilantes',
  'llaves',
  'dashboard',
] as const;

/**
 * Indica si en este momento rige la restriccion nocturna (22:20 a 06:00).
 *
 * Upgrade 2026-09-26: el inicio pasa de 22:00 a 22:20 (se contemplan los
 * minutos cuando la hora es 22). El fin (06:00) NO cambia. Es decir:
 *   - hora == 22 y minutos >= 20  -> restringido (22:20 a 22:59)
 *   - hora == 23                  -> restringido (toda la hora)
 *   - hora <  6                   -> restringido (00:00 a 05:59)  [sin cambios]
 *   - resto                       -> NO restringido
 *
 * Proteccion anti-reloj-roto: si la fecha del sistema es absurda (anio < 2025,
 * sintoma tipico de pila de BIOS agotada tras un corte de luz), NO se aplica
 * la restriccion y se deja todo habilitado (modo seguro). Asi un reloj
 * desconfigurado nunca bloquea los botones en pleno dia.
 */
export function esHorarioRestringido(fecha: Date = new Date()): boolean {
  const anio = fecha.getFullYear();
  if (anio < 2025) return false; // reloj roto -> no restringir
  const hora = fecha.getHours();
  const minutos = fecha.getMinutes();
  if (hora < 6) return true;              // 00:00 - 05:59  (fin sin cambios)
  if (hora === 22) return minutos >= 20;  // 22:20 - 22:59  (nuevo inicio)
  if (hora >= 23) return true;            // 23:00 - 23:59
  return false;                            // 06:00 - 22:19  -> habilitado
}