# INSTRUCTIVO - ARRANCAR_FRONTEND (Terminal B no levanta / error 404)
**Fecha/hora:** 2026-07-31 11:10
**Herramienta:** `HERRAMIENTAS_RED\ARRANCAR_FRONTEND.bat` (+ `.ps1`)
**PC objetivo:** Terminal B (PC3, FCEA-TERMINAL-B, IP 192.168.100.12)

---

## Diagnostico confirmado
- El Monitor (192.168.100.10:8090) responde OK: la RED y PocketBase estan bien.
- El problema es LOCAL de Terminal B: **el servidor de frontend en el puerto 5173 NO esta corriendo**.
- Prueba que lo confirmo: abrir Edge en `http://127.0.0.1:5173/terminal?id=B`
  -> **ERR_CONNECTION_REFUSED** ("127.0.0.1 rechazo la conexion").
- Por eso el kiosko termina en **404**: al no haber 5173 local, el lanzador
  redirige el navegador al 8090 del Monitor, que es solo-API y no sirve la app.

Todo el rastreo previo alrededor del puerto 8090 (PocketBase) fue una pista falsa:
en una Terminal es NORMAL que nadie escuche en 8090 local.

---

## Que hace esta herramienta
1. Diagnostica que piezas tiene la instalacion de Terminal B:
   `dist\index.html`, `node` (portable o PATH), `node_modules\vite`,
   `serve_dist.cjs`, `run_frontend.bat`.
2. Arranca el frontend en 5173 con el mejor metodo disponible. Si NO hay node,
   usa un mini servidor embebido en PowerShell (para probar que la app carga).
3. Reporta EXITO o dice exactamente que FALTA (para decidir si alcanza con
   arrancar o hay que reinstalar/actualizar la Terminal).

**No instala nada, no toca PocketBase, no borra datos.**

---

## Pasos en Terminal B
1. Enchufar el pendrive en Terminal B.
2. Entrar a la carpeta `HERRAMIENTAS_RED` del pendrive.
3. Doble click en **`ARRANCAR_FRONTEND.bat`**.
4. Aceptar el cartel de permisos de administrador (UAC).
5. Leer la seccion **[1] Diagnostico** (sacale una foto): dice que hay y que falta.
6. La herramienta intenta arrancar el frontend. Segun el resultado:
   - Si dice **"EXITO - Frontend arriba en http://127.0.0.1:5173"**:
     abri el kiosko (icono del escritorio) o Edge en:
     `http://127.0.0.1:5173/terminal?id=B` y confirma que carga la Terminal B.
   - Si entro al **fallback embebido**: DEJA ESA VENTANA ABIERTA y abri Edge en
     `http://127.0.0.1:5173/terminal?id=B`. Si carga, el frontend esta sano y el
     problema es solo que el arranque automatico no levanta el 5173.
7. Sacale una foto a la seccion **[5] RESUMEN** del final.

---

## Que me tenes que decir (dev laptop)
- Foto de **[1] Diagnostico** y de **[5] RESUMEN**.
- Si con la herramienta corriendo, `http://127.0.0.1:5173/terminal?id=B`
  **carga la Terminal B** o no.

Con eso defino el **fix definitivo**:
- Si faltaba `node-portable` / `node_modules` / `dist` -> reinstalar/actualizar
  Terminal B con el pendrive (y lo integro a los scripts criticos).
- Si estaba todo pero el 5173 no arrancaba solo -> ajuste del arranque
  automatico + del lanzador.

> Nada se comitea ni se integra hasta que me confirmes que funciono en Terminal B.
