# INSTRUCTIVO — Diagnóstico de sincronización de LLAVES
**Herramienta:** `DIAGNOSTICAR_LLAVES_SYNC.bat` (+ `.ps1`)
**Versión:** v2 ROBUSTO — actualizado 2026-08-06
**Riesgo:** CERO. Es **solo lectura**: no modifica base de datos, ni configuración, ni servicios. Se puede correr con el sistema funcionando y atendiendo gente.

---

## ¿Por qué una v2?
En el intento anterior **no quedó ningún log en el pendrive**. Causa: el `.bat` no tenía `pause` y la única pausa estaba dentro del `.ps1`; si PowerShell no arrancaba (política de ejecución / antivirus), la ventana **parpadeaba y se cerraba sin dejar nada**.

La v2 garantiza que **siempre** quede evidencia en el pendrive:
- El `.bat` hace `pause` **siempre** → la ventana **nunca** se cierra sola.
- Toda la salida se redirige a un archivo `_WRAP_LLAVES_SYNC_<PC>.txt` en el pendrive → aunque PowerShell explote, el error queda escrito.
- Verifica que exista `powershell.exe` y lo reporta.
- Además genera el log lindo `LOG_LLAVES_SYNC_<PC>_<fecha>.log`.

---

## Pasos (repetir en las 3 PCs, en este orden)
1. Enchufá el pendrive en la PC.
2. Entrá al pendrive → carpeta **`_pendrive_tools`**.
3. **Doble click** en **`DIAGNOSTICAR_LLAVES_SYNC.bat`**.
4. Esperá unos segundos. Vas a ver en pantalla la salida del diagnóstico.
5. Cuando diga **"Presione una tecla para continuar . . ."**, apretá una tecla para cerrar.
6. Repetí en la siguiente PC.

**Orden sugerido:** Monitor Vigilancia → Terminal A → Terminal B.

> No importa si alguna terminal muestra errores de conexión: igual queda el log. Justamente eso es lo que necesito leer.

---

## ¿Qué queda en el pendrive?
En `_pendrive_tools\_RESULTADOS\` van a quedar, por cada PC:
- `LOG_LLAVES_SYNC_<NOMBRE-PC>_<fecha>.log`  ← log principal
- `_WRAP_LLAVES_SYNC_<NOMBRE-PC>.txt`        ← red de seguridad (por si PowerShell falla)

Al terminar las 3 PCs deberías ver **6 archivos** (3 `.log` + 3 `_WRAP`).

---

## Después
Traé el pendrive a la laptop de desarrollo. **Cline lee los archivos directamente** desde `D:\_pendrive_tools\_RESULTADOS\` — no hace falta que copies/pegues ni saques fotos.

Con esos datos, Cline escribe el **fix definitivo** (sincronización en vivo de llaves en Terminal A/B, mismo mecanismo ya probado con usuarios) y lo prueba en la laptop **antes** de que lo apliques en producción.
