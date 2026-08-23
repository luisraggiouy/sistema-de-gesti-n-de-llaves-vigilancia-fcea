/**
 * Restriccion de botones del Monitor durante el turno nocturno (22:00 a 06:00).
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
 * Indica si en este momento rige la restriccion nocturna (22:00 a 06:00).
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
  return hora >= 22 || hora < 6;
}