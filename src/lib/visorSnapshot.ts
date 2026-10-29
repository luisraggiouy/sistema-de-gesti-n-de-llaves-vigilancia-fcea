// =============================================================
// visorSnapshot.ts  —  Modo VISOR OFFLINE (export a pendrive)
//
// Cuando la autoridad abre el informe exportado en su PC (sin
// PocketBase), el HTML carga un `snapshot.js` que define
// window.__FCEA_SNAPSHOT__ con los datos congelados y pone la ruta
// en /visor. En ese modo, los hooks de datos (SolicitudesContext,
// useVigilantes, useObjetosOlvidados) devuelven ESTE snapshot en
// vez de llamar a PocketBase.
//
// En PRODUCCION normal (Monitor/Terminales) NO existe el snapshot,
// asi que esHayVisorSnapshot() = false y TODO funciona igual que
// siempre: cero impacto en las 3 PC.
// =============================================================

export interface FceaSnapshot {
  generadoEn: string;          // ISO de cuando se exporto
  solicitudes: any[];          // registros crudos de la coleccion 'solicitudes'
  vigilantes: any[];           // registros crudos de 'vigilante'
  objetos: any[];              // registros crudos de 'objetos_olvidados'
  autorizaciones: any[];       // autorizaciones (formato de getAutorizaciones)
}

declare global {
  interface Window {
    __FCEA_SNAPSHOT__?: FceaSnapshot;
  }
}

/** True si estamos abriendo el informe exportado (modo visor offline). */
export function hayVisorSnapshot(): boolean {
  return typeof window !== 'undefined' && !!window.__FCEA_SNAPSHOT__;
}

/** Devuelve el snapshot embebido, o null si no estamos en modo visor. */
export function getVisorSnapshot(): FceaSnapshot | null {
  if (typeof window === 'undefined') return null;
  return window.__FCEA_SNAPSHOT__ ?? null;
}
