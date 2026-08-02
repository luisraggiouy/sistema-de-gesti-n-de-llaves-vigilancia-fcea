# INSTRUCTIVO — FIX KIOSK 404 en el Monitor Vigilancia
**Fecha/hora:** 2026-08-02
**PC destino:** MONITOR VIGILANCIA (el que está dentro de la cabina)

---

## ¿Qué problema arregla?

En el Monitor, al cerrar el kiosk con **Alt+F4** y volver a abrirlo con el
ícono del escritorio **"abrir llaves FCEA modo kiosk"**, el navegador mostraba:

```json
{"code":404,"message":"Not Found.","data":{}}
```

Ese texto es **PocketBase** (puerto 8090) respondiendo en su raíz. Es decir,
el ícono estaba abriendo el **8090** (que es solo la API de datos) en vez del
**frontend local** en `http://127.0.0.1:5173`.

Causa: el Monitor tenía una versión **VIEJA** del launcher/acceso directo
(anterior al fix del 31/07 que ya se probó bien en Terminal B).

## ¿Qué hace el fix?

1. Copia al Monitor las versiones **correctas** de:
   - `scripts\lib\abrir_llaves_kiosk.bat`
   - `scripts\lib\lanzar_navegador.ps1`
   (ambas fuerzan SIEMPRE el frontend local `http://127.0.0.1:5173`)
2. Rehace el acceso directo del escritorio **"abrir llaves FCEA modo kiosk"**
   para que apunte al `.bat` correcto.

> No toca datos, ni PocketBase, ni `config.json`. Es de bajo riesgo e idempotente
> (se puede correr varias veces sin problema).

---

## Pasos (en el MONITOR VIGILANCIA)

1. Enchufá el pendrive en el **Monitor Vigilancia**.
2. Abrí la carpeta del pendrive:
   `FIX\FIX_KIOSK_MONITOR_404_2026-08-02\`
3. Doble click en **`APLICAR_FIX.bat`**.
4. Aceptá el cartel de **Control de cuentas de usuario (UAC)** → *Sí*.
5. Esperá a que diga **`[LISTO] Fix aplicado.`** y cerrá la ventana.

## Cómo comprobar que funcionó

1. Si estás en el kiosk, salí con **Alt+F4**.
2. Doble click en el ícono del escritorio **"abrir llaves FCEA modo kiosk"**.
3. Debe abrir el **sistema (Monitor)** a pantalla completa — **NO** el texto
   `{"code":404,...}`.

Si ves el sistema y no el 404 → **funcionó**. Avisame acá en la laptop de
desarrollo y lo integro a los scripts críticos + commit + GitHub.

---

## Si algo sale mal (rollback)

Este fix solo reemplaza 2 archivos y el acceso directo. Si hiciera falta,
se puede volver a correr el instalador/recuperador del sistema, que regenera
esos archivos. No hay riesgo para los datos.
