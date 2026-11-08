# FIX BACKUP + PURGA DE LOGS — Instructivo (v3 · 2026-11-07) — TODO EN UNO

## La causa REAL del disco lleno (confirmada con tus logs)
No eran las fotos ni los pedidos. Era **`logs.db` = 3.6 GB**: la base de LOGS
internos de PocketBase (auditoría de cada petición HTTP), que crecía sin límite
porque PocketBase tenía `logs.maxDays = 0` (nunca borra).

- `data.db` (tus datos reales: llaves, 6000 pedidos, objetos y **las fotos
  embebidas**) = solo **17 MB**. ✅ Intacto, no se toca.
- `logs.db` + backups internos de logs = **~4 GB** de basura de auditoría.
- Además había **~24 carpetas de backup crudas = 81 GB** (compresión que fallaba).

## Qué hace el script (UN SOLO doble-clic, de corrido)
1. **Libera ~77 GB:** comprime la carpeta de backup más reciente a `.zip` y borra
   las demás carpetas crudas.
2. **Frena los logs:** configura `logs.maxDays = 7` en PocketBase (vía API). Desde
   ahora PocketBase borra solo los logs de más de 7 días.
3. **Purga el logs.db actual (3.6 GB):** detiene PocketBase ~10 seg, borra
   `logs.db` + `-wal` + `-shm` + backups internos de logs, y lo reinicia.
   PocketBase recrea `logs.db` vacío. **No toca `data.db`.**
4. **Instala el backup diario LIVIANO:** de ahora en más el backup copia **solo
   `data.db`** (~17 MB → `.zip` de ~6 MB). 14 días = ~85 MB. **El disco aguanta
   años.** Ya no copia `logs.db` ni los 4.5 GB de antes.
5. **Corre un backup real ahora** (~6 MB) y verifica que deja un `.zip`.

> Si PocketBase no estuviera respondiendo al momento de correrlo, los pasos 2 y 3
> se saltan solos (con aviso) y el resto igual se hace; se reintentan luego.

## Pasos (en el MONITOR, pendrive cable E: enchufado)
1. Abrí `E:\FIX\FIX_BACKUP_COMPRESION_2026-11-06\`.
2. **Doble clic en `REPARAR_BACKUP_TODO.bat`**.
3. Aceptá el cartel de **administrador** (UAC).
4. Escribí **SI** + ENTER.
5. Esperá el **RESUMEN FINAL** (unos segundos; si purga logs, ~1 min). ENTER para cerrar.

### Cómo sabés que funcionó (RESUMEN FINAL en pantalla)
- `Disco C: libre final` → salta de ~3 GB a **~80+ GB**.
- `.zip de backup presentes = 1` (o más), y **pesa pocos MB** (no GB).
- `carpetas crudas = 0`.
- En el log, el paso 3 dice `PocketBase volvio a responder. logs.db regenerado vacio`.

Y en el **Monitor de Salud** (hasta 30 min en refrescar): las 2 alertas rojas pasan
a verde. **Eso es la consecuencia de que el sistema quedó sano de verdad.**

### Mañana (confirmación final del fix permanente)
Mañana a las 03:00 el backup automático correrá solo con el script liviano: debe
aparecer un `.zip` nuevo de pocos MB en `C:\sistema-llaves-fcea\backups\`. Si está,
el problema quedó resuelto para siempre (no solo arreglado a mano hoy).

## Qué me traés a la laptop
El `.log` `LOG_REPARAR_BACKUP_...` de `_RESULTADOS\`. Con eso confirmo y recién ahí
hago commit + integro a los scripts críticos (Instalar/Recuperar/etc.).

## Rollback
El script de backup anterior quedó como
`C:\sistema-llaves-fcea\scripts\maintenance\backup_automatico.ps1.backup_<fecha>`.
Los logs borrados son auditoría interna (no datos del negocio); PocketBase los
regenera vacíos. `data.db` nunca se tocó.
