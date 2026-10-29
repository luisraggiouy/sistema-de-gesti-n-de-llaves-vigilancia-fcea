# UPGRADE — Transición de turno en Objetos Olvidados
**Fecha:** 2026-10-03

Paquete **individual e independiente** (un solo cambio), con su propio `dist` y
su propio rollback.

## Qué cambia
En **Objetos Olvidados** (al **registrar** un objeto y al **devolver** un
objeto), el desplegable para elegir el vigilante mostraba **solo el turno
actual**. Ahora usa la **misma lógica de transición de turno** que la
entrega/devolución de llaves:

- Durante la **ventana de transición** (30 min configurable + la ventana fija de
  las 05:50) el desplegable muestra **también** los vigilantes del **turno
  anterior**.
- Fuera de la transición, muestra solo el turno actual (como antes).

Esto es útil cuando el vigilante entrante registra/devuelve un objeto pero el
movimiento lo hizo el saliente, o viceversa, en el cambio de turno.

---

## ⚠️ IMPORTANTE: aplicar en LAS 3 PC
Reemplaza el **frontend (`dist`)**. Hay que ejecutarlo una vez en **cada una de
las 3 PC** (Monitor, Terminal A y Terminal B) y reabrir el kiosko.

## Pasos (repetir en Monitor, Terminal A y Terminal B)
1. Enchufar el pendrive en la PC.
2. Entrar a: `upgrades\UPGRADE_OBJETOS_TRANSICION_TURNO_2026-10-03`
3. Click **DERECHO** en **`1-APLICAR_UPGRADE.bat`** → **"Ejecutar como
   administrador"** → aceptar el UAC (**Sí**).
4. Esperar **"EXITO. Upgrade aplicado en esta PC"**.
5. Cerrar el navegador/kiosko y volver a abrirlo (Ctrl+F5 si hiciera falta).

## Cómo probar (en el Monitor)
1. Durante la transición de turno (o bajando a 1-2 min el valor configurable de
   transición para la prueba), abrir **Objetos Olvidados**.
2. En **registrar objeto** y en **devolver objeto**, el desplegable de vigilante
   debe mostrar **ambos turnos** (actual + anterior).
3. Fuera de la transición, debe mostrar **solo el turno actual**.

## Si algo sale mal (rollback)
- Click DERECHO en **`2-DESHACER_ROLLBACK.bat`** → "Ejecutar como
  administrador". Restaura el `dist` anterior.

## Notas técnicas (para integración posterior)
- **No** toca PocketBase, **no** borra datos, **no** cambia `config.json`.
- Archivo de código modificado:
  - `src/pages/MonitorVigilancia.tsx` → nueva lista `vigilantesObjetos`
    (combina `vigilantesActuales` + `vigilantesAnteriores`, deduplicada por
    nombre) usada en `ObjetosOlvidadosModal` y `RegistroObjetoModal`.
- El paquete incluye el `dist` recompilado (`vite build`, EXIT=0).
