# FIX — Clicks lentos / doble-marcado por latencia en el Monitor
**Fecha:** 2026-10-03

Este paquete trae **un solo cambio** (fix), separado e independiente. Tiene su
propio `dist` y su propio rollback, para poder aplicarlo y probarlo solo.

## Qué arregla
En **Solicitudes pendientes** y **Llaves en uso**, al tocar el nombre del
vigilante para **entregar** o **recibir** una llave:

- **Antes:** la tarjeta tardaba 1-2 s en desaparecer y a veces **reaparecía**
  (reflotaba). El vigilante, al dudar, volvía a clickear y el **segundo click
  caía sobre OTRA llave**, marcándola por error. Lo mismo al tocar el nombre en
  las llaves en uso (devolución).
- **Ahora:** la tarjeta **sale de la lista al instante y NO reaparece**. Un
  segundo click no marca otra llave.

## Causa raíz (encontrada el 2026-10-03)
Las **solicitudes NO usan realtime**: el Monitor las refresca por **polling cada
3 segundos** (`SolicitudesContext`). En la LAN de facultad la escritura a
PocketBase tarda 1-2 s. Si un poll caía en esa ventana, traía la solicitud
**todavía con el estado viejo** y **pisaba** el cambio optimista → la tarjeta
**reflotaba**. (Por eso el intento anterior "3 en 1" del 26/09 no alcanzó: el
update optimista existía, pero el poll lo volvía a pisar.)

## Cómo lo soluciona
1. **Cambios "en vuelo":** al entregar/devolver/intercambiar, se marca esa
   solicitud y el poll de 3 s **no la refloten** hasta que el servidor confirme
   el nuevo estado (o venza un timeout de seguridad de 15 s).
2. **El poll ya no reemplaza la lista si no cambió nada** (evita el re-render que
   soltaba el candado anti-doble-click y causaba parpadeo).
3. Se mantiene el **candado anti-doble-click** por tarjeta (ya existía).

> Nota: este paquete **solo** trae el fix de clicks/latencia. Los otros dos
> cambios que venían en el viejo "3 en 1" (transición de turno en Objetos
> Olvidados y horario restringido 22:20) van **por separado**, cada uno en su
> propio paquete, para probarlos de a uno.

---

## ⚠️ IMPORTANTE: aplicar en LAS 3 PC
Este paquete reemplaza el **frontend (`dist`)**. Cada PC (Monitor, Terminal A y
Terminal B) sirve su propio `dist` desde su disco. **Hay que ejecutarlo una vez
en cada una de las 3 PC** y reabrir el kiosko. Si se aplica solo en el Monitor,
las Terminales quedarían con el código viejo.

---

## Pasos (repetir en Monitor, Terminal A y Terminal B)
1. Enchufar el pendrive en la PC.
2. Entrar a la carpeta: `FIX\FIX_CLICKS_LATENCIA_MONITOR_2026-10-03`
3. Click **DERECHO** en **`1-APLICAR_FIX.bat`** → **"Ejecutar como
   administrador"** → aceptar el UAC (**Sí**).
4. Esperar el mensaje **"EXITO. Fix aplicado en esta PC"**.
5. Cerrar el navegador/kiosko y volver a abrirlo (Ctrl+F5 si hiciera falta).

## Cómo probar (en el Monitor)
1. Pedir una llave desde una Terminal (aparece en "Solicitudes pendientes").
2. En el Monitor, tocar el nombre de un vigilante para **entregar**.
   → La tarjeta debe **desaparecer al instante y NO volver a aparecer**.
3. Hacer lo mismo con **recibir** (devolución) en "Llaves en uso".
4. Probar tocar **dos veces rápido** el nombre: no debe marcarse otra llave.

## Si algo sale mal (rollback)
- Click DERECHO en **`2-DESHACER_ROLLBACK.bat`** → "Ejecutar como
  administrador". Restaura el `dist` anterior (backup automático
  `dist_backup_<fecha_hora>`).

## Notas técnicas (para integración posterior)
- **No** toca PocketBase, **no** borra datos, **no** cambia `config.json`
  (`robocopy ... /XF config.json system_health.json`).
- Archivo de código modificado:
  - `src/contexts/SolicitudesContext.tsx` → cambios "en vuelo"
    (`cambiosEnVueloRef`) + `cargarSolicitudes` respeta el estado optimista y no
    reemplaza la lista si no cambió (`mismaListaSolicitudes`) + `solicitudesRef`.
- El candado anti-doble-click de `PendingRequestCard.tsx` y `KeyInUseCard.tsx`
  ya venía del intento anterior y se conserva.
- El paquete incluye el `dist` recompilado (`vite build`, EXIT=0).
