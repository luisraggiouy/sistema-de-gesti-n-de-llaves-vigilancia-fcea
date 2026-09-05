# UPGRADE — Llaves frecuentes: antiduplicado + consolidación (2026-09-05)

## Qué problema resuelve

El **2026-09-05**, Milton de Souza pidió **11 llaves**. Al volver a
identificarse, en **"Llaves frecuentes"** solo le aparecían **2–3**.

### Causa raíz (confirmada con diagnóstico)

Se corrió `HERRAMIENTAS_RED\DIAGNOSTICAR_LLAVES_FRECUENTES` en el Monitor y el
log confirmó el bug:

- Milton (`id=iz9kggtq8w08r67`) tenía **10 registros** en `historial_llaves`,
  todos creados en el **mismo segundo (11:06:36)** con milisegundos consecutivos.
- El frontend leía **solo el PRIMER registro** (3 llaves) cuando en total había
  **11 llaves distintas**.
- No era solo Milton: **23 usuarios de 202** tenían registros duplicados.

Es una **condición de carrera**: al pedir N llaves de una vez, la Terminal
llamaba N veces seguidas a `registrarUso()`. Como el primer registro todavía no
tenía `id` en PocketBase, cada llamada creaba un registro **nuevo** → N registros
duplicados del mismo usuario.

## Qué cambia el fix (solo frontend, NO toca datos)

1. **Al ENVIAR un pedido:** se registran **todas** las llaves seleccionadas en
   **una sola operación** contra `historial_llaves`. Se elimina la condición de
   carrera: nunca más se crean duplicados.
2. **Al LEER:** el frontend **fusiona (merge)** todos los registros del mismo
   usuario. Esto hace que los **23 usuarios ya afectados recuperen de inmediato
   todas sus llaves frecuentes**, sin tocar la base a mano.
3. **Autolimpieza:** la próxima vez que un usuario con duplicados pida una
   llave, el frontend **borra sus registros duplicados viejos** y deja uno solo
   consolidado (el más antiguo). La base se va limpiando sola, de forma segura.
4. **Más frecuentes visibles (7 → 50):** la Terminal ahora muestra hasta **50**
   llaves frecuentes (antes eran 7), ordenadas de la más usada a la menos usada.
   El historial se sigue guardando **sin límite**; este número es solo cuántas
   se muestran en pantalla. Así un usuario que usa muchas llaves distintas
   (ej. personal de servicios) las tiene todas a mano.

> Es un cambio **solo del frontend compilado (`dist`)**. No modifica la
> estructura de PocketBase, no borra datos de usuarios ni de solicitudes.

## IMPORTANTE — Aplicar en LAS 3 PC

Este upgrade toca el **`dist`**, así que va en **las 3 PC**: Monitor de
Vigilancia, Terminal A y Terminal B. Cada PC sirve su propio `dist` local
(`127.0.0.1:5173`); el puerto 8090 del Monitor es solo la API de datos, no el
frontend. Si se aplica solo en el Monitor, las Terminales A/B seguirían con el
JavaScript viejo.

## Pasos

1. Enchufá el pendrive **cable (D:)** en la PC.
2. Entrá a esta carpeta del upgrade en el pendrive.
3. Doble clic en **`1-APLICAR_UPGRADE.bat`** (pide permiso de administrador).
4. Esperá el mensaje **EXITO** y presioná ENTER.
5. **Cerrá el kiosko/navegador y volvé a abrirlo** (Ctrl+F5).
6. Repetí los pasos 1–5 en **cada una de las 3 PC**.

## Cómo probarlo (en una Terminal A o B)

1. Identificate con un usuario que hoy "pierda" frecuentes (ej. **Milton de
   Souza**). Deberían aparecer **todas** sus llaves frecuentes (hasta 7), no 2–3.
2. Pedí **varias llaves de una sola vez** (ej. 5) y enviá la solicitud.
3. Volvé a identificarte con ese usuario: **todas** las llaves recién pedidas
   deben figurar en "Llaves frecuentes".

## Rollback

Si algo saliera mal, en la MISMA PC doble clic en **`2-DESHACER_ROLLBACK.bat`**:
restaura el `dist` anterior desde el backup automático (`dist_backup_<fecha>`),
preservando `config.json`.

## Archivos fuente modificados

- `src/hooks/useHistorialLlaves.ts`
  - `cargar()`: agrupa por `usuario_id` y **mergea** los registros duplicados;
    marca los sobrantes en `duplicados[]` para limpiarlos luego.
  - `llavesFrecuentes` (useMemo): `slice(0, 50)` en vez de `slice(0, 7)` →
    muestra hasta 50 frecuentes (el historial se guarda sin límite).
  - Nueva función `registrarUsos(lugarIds[])`: registra varias llaves en **una
    sola** operación (create/update) y **borra** los duplicados viejos.
  - `registrarUso(lugarId)` queda como wrapper de `registrarUsos([lugarId])`
    (lo usa el intercambio).
  - Se usa un `useRef` (`historialRef`) para leer el estado al día dentro de
    `registrarUsos` y evitar closures viejos.
- `src/pages/TerminalUsuario.tsx`
  - `handleSubmit`: reemplaza `selectedKeys.forEach(k => registrarUso(k.id))`
    por `registrarUsos(selectedKeys.map(k => k.id))`.
