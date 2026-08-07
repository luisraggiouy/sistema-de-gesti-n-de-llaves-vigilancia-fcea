# UPGRADE: Nuevo edificio "Aulario" en Gestión de Llaves
**Fecha:** 2026-08-07
**PC objetivo:** Monitor de Vigilancia (imprescindible). Opcional: Terminal A y Terminal B.
**Tipo:** Reemplazo de frontend (dist). NO toca PocketBase ni datos.

---

## ¿Qué cambia?

En el **Monitor de Vigilancia**, pestaña **Llaves → Gestión de Llaves**, el
desplegable **"Seleccionar edificio"** ahora ofrece **tres** opciones:

- Central
- EIP
- **Aulario**  ← NUEVO (aparece debajo de EIP)

El nuevo edificio funciona tanto en la pestaña **Agregar** como en **Modificar**.
También queda disponible en el filtro por edificio de las Terminales A/B (por eso
es opcional aplicarlo también ahí).

> Nota técnica: el listado de edificios es una fuente única compartida por todas
> las interfaces, así que "Aulario" se propaga automáticamente a Agregar, Modificar
> y a los filtros de búsqueda. El campo `edificio` de cada llave es texto libre,
> por lo que las llaves ya existentes (Central / EIP) no se ven afectadas.

---

## Pasos para aplicar (Monitor de Vigilancia)

1. Enchufá el pendrive en la PC del **Monitor de Vigilancia**.
2. Entrá a la carpeta `UPGRADE_EDIFICIO_AULARIO_2026-08-07`.
3. Doble clic en **`1-APLICAR_AULARIO.bat`**.
   - Aceptá el aviso de Windows (pide permisos de administrador).
4. Esperá el mensaje verde **"EXITO. Upgrade aplicado."** y presioná ENTER.
5. **Cerrá el navegador/kiosko y volvé a abrirlo** (si hace falta, Ctrl+F5 para
   refrescar sin caché).
6. Andá a **Llaves → Gestión de Llaves**:
   - En **Agregar**, abrí "Seleccionar edificio" → debe aparecer **Aulario**.
   - En **Modificar**, buscá una llave, abrí "Seleccionar edificio" → **Aulario**.

## (Opcional) Terminal A y Terminal B

Solo si querés que el **filtro por edificio** de las terminales también muestre
"Aulario". Las llaves se crean desde el Monitor, así que este paso no es
obligatorio. Repetí los pasos 1–5 en cada terminal.

---

## Si algo sale mal (ROLLBACK)

En la misma PC donde aplicaste el upgrade, doble clic en
**`2-DESHACER_AULARIO_ROLLBACK.bat`**. Restaura el `dist` anterior (el backup
`dist_backup_<fecha_hora>` que se creó automáticamente al aplicar).

---

## Confirmación

Cuando verifiques que en el Monitor aparece **Aulario** en Agregar y Modificar,
avisame acá en la laptop de desarrollo: **"El upgrade Aulario funcionó"**, y ahí
lo integro definitivamente (commit con timestamp + push a GitHub).
