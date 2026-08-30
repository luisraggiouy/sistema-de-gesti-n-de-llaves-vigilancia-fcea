# FIX — Ventana negra del Chequeo de Salud / Watchdog (2026-08-30)

## Qué problema resuelve
Cada tanto, en el **Monitor de Vigilancia**, aparecía por ~2 segundos una
**pantalla/consola negra** que se abría y se cerraba sola. No era un error: era
la tarea programada de Windows que regenera el estado de salud del sistema.

- La culpable principal es **`FCEA-Chequeo-Salud`** (corre al iniciar sesión y
  **cada 30 minutos**). Ejecutaba `powershell.exe` en modo interactivo, por eso
  se veía la ventana.
- También se ajusta **`FCEA-Watchdog`** (que vigila PocketBase), por el mismo
  motivo.

## Qué hace el fix
Vuelve a registrar esas dos tareas para que lancen **exactamente el mismo
script** pero a través de un pequeño wrapper `run_hidden.vbs`, que ejecuta
PowerShell con **ventana oculta**. No cambia ninguna lógica ni ningún dato:
solo **desaparece el parpadeo**.

- Copia `run_hidden.vbs` a `C:\sistema-llaves-fcea\scripts\lib\`.
- Re-registra `FCEA-Chequeo-Salud` y `FCEA-Watchdog` con acción oculta.

## Dónde se aplica
**SOLO en el Monitor de Vigilancia** (la PC de la cabina, rol `monitor`).
Las Terminales A y B **no** corren estas tareas, así que ahí no hay que hacer
nada (el script lo detecta y no toca nada si no es el monitor).

> Este fix NO toca el `dist` (frontend). No hay que aplicarlo en las 3 PC:
> va únicamente en el Monitor.

## Pasos
1. Enchufar el pendrive en el **Monitor de Vigilancia**.
2. Entrar a la carpeta `FIX\FIX_CHEQUEO_SALUD_VENTANA_NEGRA_2026-08-30\`.
3. Clic derecho sobre **`APLICAR_FIX.bat`** → **Ejecutar como administrador**.
   (Ejecutar como admin asegura poder re-registrar las tareas programadas.)
4. Leer la salida: debe decir
   `Tarea 'FCEA-Chequeo-Salud' re-registrada (ahora corre OCULTA ...)` y lo mismo
   para `FCEA-Watchdog`.
5. Cerrar la ventana.

## Cómo verificar que quedó bien
- Esperar unos minutos (o forzar la ejecución) y confirmar que **ya NO aparece**
  la consola negra.
- Forzar una corrida sin ventana y verificar que el JSON de salud se actualiza:
  ```powershell
  Start-ScheduledTask -TaskName 'FCEA-Chequeo-Salud'
  Get-Item C:\sistema-llaves-fcea\public\system_health.json | Select LastWriteTime
  ```
  La fecha/hora de modificación debe ser la actual y **no** debe verse ninguna
  ventana.
- El Monitor de Vigilancia debe seguir mostrando el estado de salud normal.

## Reversión (rollback)
Si hiciera falta volver atrás, basta con re-correr en el Monitor el script
oficial de mantenimiento, que reconstruye las tareas en su forma original:
```
C:\sistema-llaves-fcea\scripts\maintenance\CONFIGURAR_MANTENIMIENTO.ps1
```
