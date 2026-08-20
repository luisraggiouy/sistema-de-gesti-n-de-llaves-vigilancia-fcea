# FIX — El Monitor del Sistema seguía pidiendo la vieja "semilla"

**Fecha:** 2026-08-16
**PC objetivo:** MONITOR VIGILANCIA (+ pendrive de RESCATE enchufado)

---

## Qué pasaba

El **Monitor del Sistema** mostraba una advertencia del tipo
*"Nunca se grabó la semilla del pendrive"* aunque vos ejecutabas
correctamente **ACTUALIZAR DATOS.bat** desde el pendrive de rescate.

**Causa (dos partes):**

1. El chequeo de salud (`check_system_health.ps1`) revisa el resguardo portable
   leyendo el archivo interno
   `C:\ProgramData\FCEA-Sistema-Llaves\pb_data\_SEMILLA_INFO.txt`.
   Ese archivo lo escribía el **script viejo** (`actualizar_semilla.ps1`).
   El nuevo **ACTUALIZAR DATOS** hacía el backup bien, pero **no dejaba ese
   marcador**, así que el Monitor nunca se enteraba y seguía avisando.

2. **Además** (esto es lo que hacía que la advertencia SIGUIERA apareciendo aun
   después del primer intento de fix): el Monitor no lee el estado en vivo, sino
   un archivo `system_health.json` que **sólo se regenera cada 30 minutos o al
   iniciar sesión** (tarea `FCEA-Chequeo-Salud`). Aunque ya se escribiera el
   marcador, el `.json` que ve la pantalla seguía siendo el viejo (con la alerta
   adentro), por eso mostraba el texto antiguo *"Nunca se grabó la semilla"*.

---

## Qué corrige este fix

1. **`ACTUALIZAR_DATOS_RESCATE.ps1`** (pendrive de rescate): al terminar el
   backup ahora **(a)** escribe el marcador `_SEMILLA_INFO.txt` en
   `C:\ProgramData\FCEA-Sistema-Llaves\pb_data\`, y **(b)** vuelve a correr el
   chequeo de salud (`check_system_health.ps1`) para **regenerar
   `system_health.json` en el acto**. Con esto la advertencia desaparece apenas
   se corre "ACTUALIZAR DATOS" (basta recargar la página del Monitor con **F5**),
   sin esperar los 30 minutos de la tarea programada.
2. **`check_system_health.ps1`** (Monitor): los textos que decían "semilla"
   y `ACTUALIZAR_SEMILLA_PENDRIVE.bat` ahora dicen **"resguardo de datos"** y
   **`ACTUALIZAR DATOS.bat`** (sólo cosmético; para cuando la alerta reaparezca
   a los 45/90 días muestre el nombre correcto).

> No toca datos, ni `config.json`, ni servicios. Downtime = 0.

---

## Pasos (en el MONITOR VIGILANCIA)

> El pendrive de RESCATE (E:) **ya tiene** el `ACTUALIZAR_DATOS_RESCATE.ps1`
> corregido (escribe el marcador **y** regenera el `system_health.json`). Por eso
> la forma más simple es la **Opción A**, que sólo necesita el pendrive de rescate.
> **No hace falta tener los dos pendrives enchufados a la vez.**

### Opción A — recomendada (sólo pendrive de RESCATE)

1. Enchufá en el Monitor **sólo el pendrive de RESCATE** (el de las autoridades,
   con `ACTUALIZAR DATOS.bat`).
2. Ejecutá una vez **`ACTUALIZAR DATOS.bat`**. Esperá el "LISTO".
   - Al final del script vas a ver: *"Refrescando el Monitor del Sistema..."* y
     *"Monitor del Sistema actualizado. La advertencia debe desaparecer."*
3. En la app, andá al **Monitor del Sistema** y recargá la página con **F5**
   (o cerrá y abrí de nuevo el cartel). **La advertencia debe desaparecer.**

### Opción B — completa (también arregla el texto cosmético del Monitor)

Sólo si además querés dejar corregidos los textos "semilla" que aparecerían si la
alerta reaparece a los 45/90 días. Requiere el pendrive cable D:.

1. Enchufá el **pendrive cable (D:)** con este fix.
2. Entrá a la carpeta `FIX_MONITOR_ADVERTENCIA_SEMILLA_2026-08-16`.
3. Doble clic en **`FIX_ADVERTENCIA_SEMILLA_MONITOR.bat`**.
   - Actualiza `check_system_health.ps1` en `C:\sistema-llaves-fcea`.
   - Actualiza `ACTUALIZAR_DATOS_RESCATE.ps1` en el pendrive de rescate (si está
     enchufado).
4. Sacá el D:, enchufá el pendrive de RESCATE y hacé la **Opción A**.

---

## Cómo sé que funcionó

- Aparece en pantalla del `.bat`:
  *"Marcador de resguardo actualizado para el Monitor del Sistema."*
- Existe el archivo:
  `C:\ProgramData\FCEA-Sistema-Llaves\pb_data\_SEMILLA_INFO.txt`
  con una línea `last_seed_written_at:` con la fecha/hora de hoy.
- El Monitor del Sistema ya no muestra la advertencia de "semilla".

---

## Si algo sale mal (rollback)

El fix sólo reemplaza dos `.ps1`. Para volver atrás, restaurá esos dos archivos
desde el repo/pendrive anterior. No se tocaron datos.
