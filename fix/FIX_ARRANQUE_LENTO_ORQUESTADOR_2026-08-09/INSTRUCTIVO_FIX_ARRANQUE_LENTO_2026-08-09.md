# INSTRUCTIVO - FIX ARRANQUE LENTO DEL MONITOR (~8 min -> segundos)
**Fecha:** 2026-08-09
**PC donde se aplica:** SOLO el **MONITOR DE VIGILANCIA** (es el que corre PocketBase)
**Riesgo:** MUY BAJO. Hace backup, valida sintaxis y hace rollback solo si algo sale mal. No toca la base, ni el WAL, ni config.json.

---

## Causa raiz (confirmada con logs y timestamps del 2026-08-09)

El orquestador `scripts\lib\iniciar_pocketbase.ps1` (funcion `Ensure-Owner`) llama al lanzador
`scripts\lib\start_detached.ps1` con el parametro **`-Target`**, que **NO EXISTE** en ese script
(solo acepta `-CommandLine` y `-WorkingDirectory`).

Consecuencia:
- La llamada falla (el error se oculta con `2>$null`), asi que **run_pocketbase.bat NUNCA se lanza
  desde el orquestador**.
- Los **3 reintentos** del orquestador se agotan (cada uno espera 45s el `/api/health` que nunca
  responde) => se pierden **~7-8 minutos** con la pantalla "congelada".
- Termina en `[ERROR] Tras 3 intentos...` y **recien ahi** el **fallback propio de `INICIAR.bat`**
  arranca PocketBase (que levanta en **segundos**).

Prueba en el log: en el arranque de las 06:46, PocketBase recien aparecio en `pocketbase.log`
a las **06:54:08**, justo despues del `[ERROR]` (06:54:07).

## Que hace el fix

Cambia UNA sola linea en `iniciar_pocketbase.ps1`:

- **Antes:** `... -File $startDet -Target $runBat 2>$null | Out-Null`
- **Despues:** `... -File $startDet -CommandLine "cmd /c $runBat" -WorkingDirectory $repoRoot 2>$null | Out-Null`

Es exactamente el mismo patron que ya usa `INICIAR.bat` (el que SI funciona). Con esto, el
**primer intento** arranca PocketBase de verdad y el `/api/health` responde en segundos.

## Por que es seguro

- Hace **backup** de `iniciar_pocketbase.ps1` antes de tocar nada (`.bak_<fecha_hora>`).
- Valida la **sintaxis** del archivo parcheado; si hubiera cualquier problema, **restaura el backup solo**.
- No toca PocketBase, ni la base de datos, ni el WAL, ni `config.json`, ni la arquitectura de reintentos.
- Si el fix no diera el resultado esperado, **degrada al comportamiento de hoy** (lento pero arranca),
  porque el fallback de `INICIAR.bat` sigue intacto.
- Rollback en 1 clic con `REVERTIR_FIX.bat`.

---

## PASOS (en el MONITOR)

1. Enchufar el pendrive en el **Monitor de Vigilancia**.
2. Entrar a la carpeta `FIX\FIX_ARRANQUE_LENTO_ORQUESTADOR_2026-08-09`.
3. Doble clic en **`APLICAR_FIX.bat`** (si Windows pide permiso, aceptar).
4. Leer el mensaje final:
   - `[EXITO] Fix aplicado y sintaxis OK.` => todo bien, seguir al paso 5.
   - `[ADVERTENCIA] No encontre la linea original...` => avisarme (el archivo tenia otra version); no cambio nada.
   - `[OK] El fix YA estaba aplicado` => no hay nada que hacer.
5. **REINICIAR el Monitor** y cronometrar el arranque.
   - Esperado: PocketBase disponible en **segundos** (no ~8 min).
6. Verificar que el sistema abre normal (terminales con usuarios y llaves, monitor con datos).

## Si algo saliera mal

- Ejecutar **`REVERTIR_FIX.bat`** (restaura el backup mas reciente) y reiniciar el Monitor.
- El sistema vuelve exactamente a como estaba antes del fix.

## Que traer de vuelta a la laptop de desarrollo

- El archivo `LOG_APLICAR_FIX_*.log` que queda en esta misma carpeta del pendrive.
- Decirme cuanto tardo el arranque despues del fix.
  - Si funciono bien => recien ahi integro el cambio al codigo fuente del repo y hago el commit con timestamp.
