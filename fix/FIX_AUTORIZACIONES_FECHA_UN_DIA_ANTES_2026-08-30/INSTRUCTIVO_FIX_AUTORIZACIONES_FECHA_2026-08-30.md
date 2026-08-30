# FIX — Autorizaciones mostraban las fechas UN DÍA ANTES (2026-08-30)

## Qué problema resuelve
Al crear una autorización en **Agenda / Autorizaciones**, la **fecha de
autorización**, el **vigente desde** y el **vigente hasta** aparecían corridos
**un día antes** del que se marcaba en el calendario (ej.: marcabas 30/8 y
mostraba 29/8; vigencia desde 3/9 mostraba 2/9).

**Importante:** las fechas **se guardaban bien**. Era solo un error de
**visualización**: la fecha (YYYY-MM-DD) se interpretaba como medianoche UTC y
al mostrarla en la hora de Uruguay (UTC-3) caía en el día anterior. El fix
ancla la fecha al mediodía antes de formatearla, igual que ya lo hacía la
pestaña Historial.

## Alcance: este fix toca el FRONTEND (dist)
Por lo tanto DEBE aplicarse en **LAS 3 PC**:
- **Monitor de Vigilancia**
- **Terminal A**
- **Terminal B**

Cada PC sirve su propio `dist`, así que si se aplica solo en una, las demás
siguen mostrando la fecha vieja.

## Pasos (repetir EN CADA UNA de las 3 PC)
1. Enchufá el pendrive en la PC.
2. Entrá a la carpeta `FIX\FIX_AUTORIZACIONES_FECHA_UN_DIA_ANTES_2026-08-30`.
3. Doble clic en **`APLICAR_FIX.bat`**.
4. Esperá el mensaje **"EXITO. Fix aplicado"** y presioná ENTER.
5. Cerrá el navegador/kiosko y volvelo a abrir (Ctrl+F5 si hace falta).

## Cómo verificar que funcionó
1. En **Agenda / Autorizaciones → Nueva**, elegí una fecha con el calendario
   (por ejemplo hoy).
2. Guardá y buscá la autorización.
3. La **fecha de autorización** y la **vigencia (desde — hasta)** deben mostrar
   **exactamente** las fechas que marcaste, sin correrse un día.

## Rollback
El script crea un backup `dist_backup_<fecha_hora>` dentro de
`C:\sistema-llaves-fcea`. Para volver atrás, restaurá esa carpeta como `dist`.

## Nota para el desarrollador (Luis me avisa que funcionó)
Cuando confirmes que anduvo en las 3 PC:
- Commit con timestamp + push a GitHub.
- Regrabar el **dist MAESTRO** del pendrive:
  `robocopy <repo>\dist D:\sistema-llaves-fcea\dist /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP`
  y verificar rc=0 + hashes idénticos de index.html y del bundle JS.
