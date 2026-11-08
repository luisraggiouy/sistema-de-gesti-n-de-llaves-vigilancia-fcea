# CONFIGURAR maxDays DE LOGS — Instructivo (2026-11-08)

## Por qué este mini-fix
El `REPARAR_BACKUP_TODO` del 08/11 **funcionó** (disco liberado, backup liviano,
Monitor en verde), PERO el paso que configuraba `logs.maxDays=7` **falló por timeout**
(PocketBase estaba recién reiniciando cuando se intentó). Sin ese ajuste, `logs.db`
volvería a crecer con el tiempo. Este mini-fix **solo** configura ese valor, de forma
robusta (reintentos + verificación).

## Qué hace
- Espera a que PocketBase responda (health check TCP, hasta 10 intentos).
- Se autentica como superusuario (con reintentos).
- Hace `PATCH /api/settings` con `{"logs":{"maxDays":7}}`.
- **Verifica** releyendo settings que quedó en 7.
- Deja un `.log` en `_RESULTADOS\`. NO toca datos.

## Pasos (en el MONITOR, con el sistema PRENDIDO y PocketBase corriendo)
1. Abrí `FIX\FIX_LOGS_MAXDAYS_2026-11-08\` en el pendrive cable.
2. **Doble clic en `CONFIGURAR_MAXDAYS.bat`**.
3. Aceptá admin (UAC).
4. Esperá a que diga `[VERIFICADO] settings.logs.maxDays = 7`. ENTER para cerrar.

### Cómo sabés que funcionó
En pantalla y en el `.log`: `[OK] logs.maxDays = 7 aplicado` y
`[VERIFICADO] settings.logs.maxDays = 7`.

## Qué me traés
El `.log` `LOG_MAXDAYS_...` de `_RESULTADOS\`. Con eso confirmo y cierro el tema
de raíz (logs.db ya no crece sin límite → el disco aguanta años).

## Nota
Esto es idempotente: si lo corrés dos veces no pasa nada malo, solo vuelve a dejar
maxDays=7.
