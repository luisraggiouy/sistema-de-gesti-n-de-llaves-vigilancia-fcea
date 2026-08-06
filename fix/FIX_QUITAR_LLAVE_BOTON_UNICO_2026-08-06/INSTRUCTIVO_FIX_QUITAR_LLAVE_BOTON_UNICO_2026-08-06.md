# INSTRUCTIVO - FIX QUITAR LLAVE / BOTON UNICO (2026-08-06)

## Qué arregla
En el **Monitor Vigilancia** → pestaña **Llaves** → sub-pestaña **Quitar**, al seleccionar
una llave aparecían **DOS botones rojos a la vez**:
- un banner inline con **"⚠️ ¿Está seguro...? / Sí, eliminar"**, y
- el botón **"Quitar Llave"** del pie del cuadro.

Era confuso: no se sabía cuál accionar. **Ahora queda UN SOLO botón "Quitar Llave"** que abre
directamente el modal de **confirmación de acción sensible** (que ya trae el aviso de
*Atención*, la nota de *permiso de jefaturas* y el aviso de *registro de la acción*).

También se **mejoró el texto de advertencia** del modal:
> "Esta acción es permanente y NO se puede deshacer: la llave será eliminada del sistema por
> completo, ya no aparecerá en el tablero ni se podrá solicitar desde la terminal. Está por
> modificar datos del sistema que requieren permisos especiales. De continuar con esta acción,
> quedará registro de los cambios que realiza."

> No cambia la lógica de borrado: sigue habiendo confirmación explícita antes de eliminar.

---

## Por qué NO se compila en producción
El `node_modules` de producción tiene versiones incompatibles de `@tanstack/react-query` vs
`@tanstack/query-core` y **un build nuevo en la PC rompe**. Por eso este fix trae el `dist`
**ya compilado desde la laptop** (con el fix) y lo instala, **preservando** el `config.json` y
el `system_health.json` propios de cada PC. La configuración es 100% *runtime*
(`fetch /config.json`), así que **un único `dist` sirve para los 3 roles**.

---

## Contenido del paquete
- `dist_nuevo\` → frontend ya compilado **con el fix** (lo que se instala).
- `APLICAR_FIX.bat` / `APLICAR_FIX.ps1` → instalador (reemplaza dist, preserva config, sin compilar).
- `KeyManagementModal.tsx` → fuente corregido (solo para actualizar el `src\` por consistencia).
- Este instructivo.

---

## Riesgo y rollback
- **No compila.** Solo reemplaza los archivos de `dist\`, **preservando** `config.json` y
  `system_health.json` de esa PC (mantiene rol/pocketbase_url).
- Antes de tocar nada hace **backup completo** de `dist\` → `dist_bak_<fecha>`.
- Si el reemplazo fallara, **rollback automático** (restaura `dist\` del backup).
- No toca PocketBase, base de datos ni scripts críticos → **cero riesgo para los datos**.

---

## PASOS (en el Monitor y, si querés, en Terminal A y B)

> El botón "Quitar Llave" solo se usa en el **Monitor** (gestión de llaves). Igual conviene
> dejar el mismo `dist` en las 3 PCs para que todas queden idénticas. Orden sugerido:
> **Monitor primero**, después Terminal A, después Terminal B.

1. Enchufá el **pendrive** en la PC.
2. Entrá a la carpeta del pendrive: `FIX_QUITAR_LLAVE_BOTON_UNICO_2026-08-06`.
3. Doble click en **`APLICAR_FIX.bat`**.
4. Aceptá el cartel de **Administrador** (UAC) → "Sí".
5. El script: verifica, respalda `dist\`, preserva tu `config.json`/`system_health.json`,
   instala el `dist` nuevo, restaura tus archivos per-PC y reinicia el frontend (5173).
6. Cuando diga **"FIX APLICADO"**, presioná ENTER para cerrar.
7. En esa PC, **cerrá y volvé a abrir el kiosko** (o `Ctrl+F5`) para cargar el `dist` nuevo.
8. **Verificá que esa PC levante normal** (que identifique usuarios, pida llaves, etc.).

---

## CÓMO PROBAR QUE FUNCIONÓ
En el **Monitor**:

1. Andá a la pestaña **Llaves** → sub-pestaña **Quitar**.
2. **Seleccioná** una llave de la lista.
3. Debe verse **UN SOLO botón rojo "Quitar Llave"** en el pie (ya **no** aparece el banner
   con el segundo botón "Sí, eliminar").
4. Tocá **"Quitar Llave"** → debe abrirse el **modal de confirmación sensible** con el título
   *Atención*, la nota de *permiso de jefaturas* y el **texto nuevo** de advertencia.
5. Con **"Cancelar"** no pasa nada; con el botón rojo del modal se elimina la llave (probá con
   una llave de prueba si querés, y luego volvé a crearla).

Si funciona → **avisale a Cline** ("funcionó") para integrar a scripts críticos + commit + push.

---

## Log automático (el pendrive es el "cable")
El script escribe:
`FIX_QUITAR_LLAVE_BOTON_UNICO_2026-08-06\_RESULTADOS\LOG_APLICAR_FIX_QUITAR_LLAVE_<PC>_<fecha>.log`
Traé el pendrive y Cline lo lee directo.

---

## Rollback manual (por las dudas)
En la PC afectada:
1. Borrá `C:\sistema-llaves-fcea\dist`.
2. Renombrá `C:\sistema-llaves-fcea\dist_bak_<fecha>` a `dist`.
3. Reiniciá la PC (el sistema arranca solo).
