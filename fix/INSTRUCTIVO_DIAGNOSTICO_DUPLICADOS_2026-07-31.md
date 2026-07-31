# INSTRUCTIVO — Diagnóstico de duplicados de usuarios (SOLO LECTURA)
**Fecha:** 2026-07-31
**Bug:** En Terminal A, al identificarse por teléfono, un usuario aparece
duplicado (Lionel Messi ×3) y aparece Juan Peiras sin coincidir con los dígitos.

## ⚠️ IMPORTANTE
Este diagnóstico **NO modifica nada**. Solo consulta la base (lectura) y
muestra si los duplicados son **filas reales** o **duplicación de render**.
Es seguro correrlo con el sistema funcionando.

## ¿Dónde se ejecuta?
Sirve en **cualquiera de las dos**: el **Monitor de Vigilancia** (recomendado,
es donde vive PocketBase) o la **Terminal A** (el script apunta solo al Monitor
por red, 192.168.100.10:8090). El sistema tiene que estar encendido.
> La base de datos es una sola y vive en el Monitor; la Terminal A solo la
> consulta. Por eso da igual desde cuál mirar: se ven los mismos datos.

## Pasos
1. **En la laptop de desarrollo**, copiá al pendrive (a la carpeta `fix\` del
   pendrive) estos 2 archivos que están en
   `c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\fix\`:
   - `DIAGNOSTICO_DUPLICADOS_USUARIOS_2026-07-31.bat`
   - `DIAGNOSTICO_DUPLICADOS_USUARIOS_2026-07-31.ps1`
   > OJO: los cree en el repo de la laptop, NO aparecen solos en el pendrive.
   > Hay que copiarlos a mano.
2. Enchufá el pendrive en el **Monitor de Vigilancia** (o en la Terminal A).
3. Asegurate de que el sistema esté encendido (PocketBase corriendo).
4. Doble clic en **`DIAGNOSTICO_DUPLICADOS_USUARIOS_2026-07-31.bat`**.
5. Se abre una ventana con el reporte. **Sacale una foto o copiá el texto** y
   pegámelo en la laptop de desarrollo.


## Qué me interesa de la salida
- La sección **"CELULARES CON MÁS DE UNA FILA"**: dice si hay duplicados reales.
- La sección **"DETALLE de los números del reporte"**: cuántas filas tienen
  realmente `099098765` (Messi) y `095321123` (Juan Peiras).
- La sección **"SIMULACIÓN del filtro"**: compara `includes` (código actual)
  vs `startsWith` (fix propuesto) al tipear `099098765`.

## Interpretación rápida
- Messi `099098765` con **Total filas: 3** → duplicados REALES en la base
  (el fix cubrirá limpieza de datos + código).
- Messi con **Total filas: 1** → es solo RENDER (el fix es solo de código).

## Después
Con esa salida confirmo el diagnóstico al 100% y armo el fix definitivo en
`fix/`, con su instructivo. Recién integro a los scripts críticos y hago commit
cuando me confirmes que funcionó en producción.
