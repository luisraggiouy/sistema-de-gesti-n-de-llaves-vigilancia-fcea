# UPGRADE — Intercambio de llave cierra la sesión y limpia la Terminal
**Fecha:** 2026-08-25   ·   **Corregido:** 2026-08-30
**Aplicar en:** LAS 3 PC → MONITOR DE VIGILANCIA, TERMINAL A y TERMINAL B
**Se prueba en:** TERMINAL B (y también en Terminal A)

> ⚠️ **IMPORTANTE (corrección 2026-08-30):** este upgrade toca el **frontend
> (`dist`)**. Cada PC sirve **su propio `dist` local** en `127.0.0.1:5173`
> (ver `abrir_llaves_kiosk.bat`). El puerto `8090` del Monitor es **solo la API
> de PocketBase** (los datos), NO el frontend. Por eso un upgrade de `dist`
> **hay que aplicarlo en las 3 PC**, no solo en el Monitor. Si se aplica solo en
> el Monitor, las Terminales A y B siguen usando el JavaScript viejo (fue el
> motivo por el que "seguía quedando logueado indefinidamente").

---

## Qué problema arregla

En la Terminal, cuando un profesor buscaba una llave que estaba **En uso** y hacía
un **intercambio**, pasaban dos cosas malas:

1. **Quedaba logueado indefinidamente.** La Terminal no cerraba la sesión del
   profesor tras el intercambio. Si llegaba otro profesor, podía usar por error
   la sesión del anterior.
2. **La lista de llaves quedaba desplegada** y no se replegaba salvo que se
   hiciera **F5**.

Con este upgrade, al confirmar el intercambio aparece una pantalla
**"¡Intercambio Confirmado!"** con una cuenta regresiva. Al terminar (o al tocar
"Volver al inicio ahora"), la Terminal:

- **Cierra la sesión** del profesor (vuelve a pedir identificarse).
- **Limpia la lista de llaves** (queda replegada, sin necesidad de F5).
- Queda **limpia** para el próximo usuario.

> Nota: el flujo de **solicitud normal** ya hacía esto; ahora el **intercambio**
> se comporta igual.

---

## Por qué se aplica en las 3 PC (corrección 2026-08-30)

El frontend compilado (`dist`) NO se sirve de forma centralizada desde el
Monitor: **cada PC corre su propio `vite preview` en `127.0.0.1:5173`** y sirve
el `dist` que tiene en **su propio disco** (`C:\sistema-llaves-fcea\dist`). Lo
único que viaja al Monitor por red es la **API de datos de PocketBase**
(puerto `8090`). Por eso, para que el cambio de intercambio llegue a los
usuarios, hay que copiar el `dist` nuevo en **las 3 PC**.

---

## Pasos (repetir en las 3 PC: Monitor, Terminal A y Terminal B)

Hacé esto **una vez en cada PC**:

1. Enchufá el pendrive en la PC.
2. Abrí la carpeta:
   `UPGRADES\UPGRADE_TERMINAL_INTERCAMBIO_CIERRA_SESION_2026-08-25`
3. Doble clic en **`1-APLICAR_UPGRADE.bat`** (pedirá permisos de administrador → Sí).
4. Esperá el mensaje **"EXITO. Upgrade aplicado."** y presioná ENTER para cerrar.
   - El script hace un **backup** automático del `dist` actual en
     `C:\sistema-llaves-fcea\dist_backup_<fecha_hora>`.
   - **Preserva** `config.json` y `system_health.json` (no toca la red).
5. En esa PC, cerrá el navegador/kiosko y volvé a abrirlo (o `Ctrl+F5`) para
   que tome el `dist` nuevo.

> Orden sugerido: Monitor → Terminal A → Terminal B. El paquete `dist` es el
> mismo para las tres; el `config.json` propio de cada PC no se toca.

## Cómo probarlo (en la Terminal B)

1. Cerrá y volvé a abrir el navegador/kiosko de la **Terminal B** (o `Ctrl+F5`).
2. Identificate como **Profesor 1** y pedí una llave. En el **Monitor**, entregá
   esa llave → queda **"En uso"**.
3. En la **Terminal B**, identificate como **Profesor 2**, buscá esa misma llave
   (aparece "En uso" con el botón **"Intercambiar llave"**), tocá **Intercambiar**,
   marcá el check de responsabilidad y **Confirmar Intercambio**.
4. **Verificá:** aparece **"¡Intercambio Confirmado!"** con cuenta regresiva y,
   al terminar, la Terminal **cierra la sesión** (vuelve a pedir identificarse) y
   **la lista de llaves queda limpia SIN F5**.

---

## Rollback (si algo sale mal)

Doble clic en **`2-DESHACER_ROLLBACK.bat`** (como administrador). Restaura el
último `dist_backup_*` y deja la Terminal como estaba antes del upgrade.

---

## Detalle técnico (para el repo)

- **Nuevo:** `src/components/terminal/ExchangeSuccess.tsx` (pantalla de éxito del
  intercambio con cuenta regresiva).
- **Modificado:** `src/pages/TerminalUsuario.tsx`
  - Nuevo step `'exchange-success'` y estado `exchangeDone`.
  - `handleExchangeConfirm` pasa a ese step al confirmar con éxito.
  - Nuevo `handleExchangeFinish`: limpia `currentUser`, `selectedKeys` y vuelve a
    `main` (al cambiar de step, `KeySearch` se desmonta y se remonta limpio →
    la lista queda replegada sin F5).
