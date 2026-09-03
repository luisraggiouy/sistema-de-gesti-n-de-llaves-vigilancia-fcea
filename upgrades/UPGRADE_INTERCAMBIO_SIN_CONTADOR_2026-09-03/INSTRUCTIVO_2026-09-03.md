# UPGRADE — Intercambio sin cuenta regresiva (Terminal vuelve limpia)
**Fecha:** 2026-09-03

## Problema

Cuando un usuario confirmaba un **intercambio de llave** en la Terminal (A o B):
- Aparecía una **pantalla de éxito con una cuenta regresiva de 5-6 segundos**
  ("¡Intercambio Confirmado!") antes de volver al inicio.
- Habíamos decidido que eso NO se viera (que solo quedara el aviso breve, como en
  la solicitud normal) y que la Terminal volviera al instante a su estado limpio.
- Además, si algo se trababa en ese flujo, la Terminal **no volvía a su estado
  "limpio"** (quedaba el usuario logueado / la lista desplegada) hasta apretar F5.

La solicitud normal ya se había corregido el 2026-08-30, pero el **intercambio**
había quedado con la pantalla vieja de cuenta regresiva.

## Qué cambia con este upgrade

- Al confirmar un intercambio, **ya no aparece la cuenta regresiva**. Sale un
  **aviso breve** (toast) "Intercambio confirmado" y la Terminal vuelve
  **INMEDIATAMENTE al inicio limpio**: cierra la sesión del usuario, limpia las
  llaves seleccionadas y repliega la lista, lista para el próximo usuario, **sin
  necesidad de F5**.
- Mismo criterio y comportamiento que la solicitud normal.

## IMPORTANTE — Aplicar en LAS 3 PC

Este upgrade reemplaza el **frontend compilado (`dist`)**, y cada PC sirve su
propio `dist` local en `127.0.0.1:5173`. Por eso hay que aplicarlo en **las 3 PC**:
**Monitor de Vigilancia, Terminal A y Terminal B**. Si se aplica solo en el
Monitor, las Terminales A/B seguirán con el JavaScript viejo y el cambio "no
aparece".

## Pasos (repetir en cada una de las 3 PC)

1. Enchufá el pendrive en la PC.
2. Entrá a la carpeta `UPGRADES\UPGRADE_INTERCAMBIO_SIN_CONTADOR_2026-09-03`.
3. Doble clic en **`1-APLICAR_UPGRADE.bat`** (pedirá permisos de administrador).
4. Esperá a que diga **EXITO** y presioná ENTER para cerrar.
5. Cerrá el navegador/kiosko y volvé a abrirlo (o `Ctrl+F5`).

## Cómo probarlo (en Terminal A o B)

1. Identificate.
2. Elegí una llave que esté **EN USO** y tocá **"Intercambio"**.
3. Confirmá el intercambio.
4. **Verificá:** ya **no** aparece la cuenta regresiva de 5s. Sale un aviso breve
   y la Terminal vuelve **sola** al inicio limpio (pide identificarse de nuevo y
   la lista de llaves queda replegada), **sin apretar F5**.

## Rollback

Si algo sale mal, en la MISMA PC ejecutá **`2-DESHACER_ROLLBACK.bat`**: restaura
el último backup del `dist` (`dist_backup_<fecha_hora>`). No toca PocketBase ni
borra datos.

## Archivos técnicos modificados (desarrollo)

- **Modificado:** `src/pages/TerminalUsuario.tsx`
  - `handleExchangeConfirm` ahora, tras un intercambio exitoso, muestra el toast y
    llama a `handleNewRequest()` (reset inmediato de la Terminal) en vez de
    `setStep('exchange-success')`.
  - Eliminados: el step `'exchange-success'`, el estado `exchangeDone`, la función
    `handleExchangeFinish`, el render de la pantalla de éxito y el import.
- **Eliminado:** `src/components/terminal/ExchangeSuccess.tsx` (quedó sin uso).
