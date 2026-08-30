# UPGRADE — Terminal sin cuenta regresiva + Eliminar solicitud en Monitor
**Fecha:** 2026-08-30

## Qué resuelve

Antes, al pedir una llave en las Terminales:
- Aparecía una **cuenta regresiva de 5 segundos** con un botón "Cancelar Pedido"
  que **no funcionaba de verdad**: solo limpiaba la pantalla de la Terminal, pero
  la solicitud ya había viajado al Monitor y quedaba igual.
- Si el vigilante usaba "Deshacer" en el Monitor, la solicitud **no se cancelaba**:
  volvía al listado de pendientes y quedaba ahí indefinidamente, sin saber qué hacer.

Con este upgrade:

1. **Terminal (A/B):** se eliminó la cuenta regresiva de 5s y el botón "Cancelar Pedido".
   Al confirmar el pedido, sale un **aviso breve** y la Terminal vuelve **de inmediato al
   inicio limpio**, lista para que se identifique el próximo usuario.
2. **Monitor:** la ventana para **"Deshacer"** una entrega baja de **2 minutos a 1 minuto**.
3. **Monitor:** nuevo botón rojo **"Eliminar solicitud"** (papelera) en cada solicitud
   **pendiente**. Con confirmación, **borra por completo** el pedido equivocado, así la
   persona puede volver a solicitar la llave correcta desde la Terminal.

---

## MUY IMPORTANTE — Aplicar en LAS 3 PC

Este upgrade reemplaza el **frontend compilado (`dist`)**. Cada PC (Monitor, Terminal A
y Terminal B) sirve su **propio `dist` local** en `127.0.0.1:5173`. Por eso hay que
ejecutar el mismo script **una vez en cada una de las 3 PC**. Si se aplica solo en el
Monitor, las Terminales A y B seguirán mostrando la versión vieja.

---

## Pasos (repetir en las 3 PC)

1. Enchufá el pendrive en la PC.
2. Entrá a la carpeta
   `UPGRADES\UPGRADE_TERMINAL_SIN_CONTADOR_Y_ELIMINAR_SOLICITUD_2026-08-30`.
3. Doble clic en **`1-APLICAR_UPGRADE.bat`** y aceptá el pedido de permisos (UAC).
4. Esperá el mensaje **"EXITO. Upgrade aplicado en esta PC"** y presioná ENTER.
5. Cerrá el navegador/kiosko y volvé a abrirlo (o `Ctrl+F5`).
6. Repetí en las otras dos PC.

## Cómo probarlo

**Terminal (A o B):**
- Identificate y pedí una llave → Confirmar.
- Ya **no** aparece la cuenta regresiva de 5s: sale un aviso corto y la Terminal
  vuelve sola al inicio, lista para otro usuario.

**Monitor:**
- En una solicitud **pendiente** aparece el botón rojo **"Eliminar solicitud"**.
  Al tocarlo pide confirmación y borra el pedido por completo (desaparece del listado).
- Tras **entregar** una llave, el botón **"Deshacer"** ahora dura **1 minuto** (antes 2).

---

## Rollback (si algo sale mal)

En la MISMA PC donde aplicaste el upgrade, ejecutá **`2-DESHACER_ROLLBACK.bat`**
(como admin). Restaura el último `dist_backup_<fecha_hora>` que se creó al aplicar.

## Notas técnicas
- NO toca PocketBase. NO borra datos. Solo reemplaza el `dist`.
- El `robocopy` preserva SIEMPRE `config.json` y `system_health.json`
  (`/XF config.json system_health.json`), por lo que **no pisa** la configuración de
  red propia de cada PC.
- Archivos de código modificados (referencia interna):
  - `src/pages/TerminalUsuario.tsx` (quita paso 'success' / vuelve al inicio al enviar)
  - `src/components/terminal/RequestSuccess.tsx` (ELIMINADO)
  - `src/contexts/SolicitudesContext.tsx` y `src/hooks/useSolicitudes.ts` (UNDO 1 min)
  - `src/pages/MonitorVigilancia.tsx` (handler + diálogo eliminar solicitud)
  - `src/components/monitor/PendingRequestCard.tsx` (botón "Eliminar solicitud")
