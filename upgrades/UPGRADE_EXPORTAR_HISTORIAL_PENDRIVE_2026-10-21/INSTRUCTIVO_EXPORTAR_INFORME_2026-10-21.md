# UPGRADE â€” Exportar Informe (visor offline) desde el Dashboard
**Fecha:** 2026-10-21

Paquete con **un solo cambio** (upgrade), separado e independiente. Trae su
propio `dist` ya compilado y verificado, y su propio rollback.

## QuÃ© hace (reemplaza al informe viejo)
En el **Dashboard â†’ "Exportar a Pendrive"**, ahora se genera **UN archivo
`.html` autocontenido**. Al abrirlo (doble clic) en la PC de la autoridad, SIN
internet ni servidor, se ve **lo MISMO que en el Monitor**:

- El **Dashboard completo**: KPIs, grÃ¡ficos, perÃ­odos (hoy / mensual /
  semestral), desempeÃ±o por **vigilante** (solo vigilantes, que son los que
  entregan y reciben) y estadÃ­sticas de objetos olvidados.
- Un botÃ³n **"Buscador HistÃ³rico de Llaves"** que abre el MISMO buscador del
  Monitor: con **filtro por rango de fechas**, buscador por texto y **notas**.

La autoridad **NO elige nada al grabar** (proceso rÃ¡pido, un clic). El filtrado
por fechas lo hace despuÃ©s, cÃ³modamente, en su propia PC dentro del visor.

## CÃ³mo es tÃ©cnicamente (para entender el archivo)
El `.html` embebe el frontend compilado + un "snapshot" de los datos congelados
al momento de exportar. No consulta PocketBase (funciona offline). Son los
MISMOS componentes del Monitor, no una copia hecha a mano.

## ðŸ› ï¸ CORRECCIÃ“N 2026-10-21 (por quÃ© antes daba "404 Page not found")
La primera versiÃ³n de este informe, al abrirla con doble clic (`file://`),
mostraba **"404 Oops! Page not found"** en vez del Dashboard. Dos causas, ya
corregidas y verificadas abriendo el `.html` con doble clic:

1. **Router bajo `file://`.** El visor arrancaba renderizando toda la app (con su
   `BrowserRouter` y su ruta comodÃ­n `*` â†’ pÃ¡gina 404). Bajo `file://` la "ruta"
   es la del archivo en el disco, no coincide con ninguna, y caÃ­a en el 404.
   **Fix:** en modo visor ahora se monta DIRECTO la vista del informe (sin ese
   router ni la ruta 404), envuelta en un `HashRouter` que sÃ­ funciona en
   `file://`.
2. **Bundle como ES module inline.** El navegador bloquea los `<script
   type="module">` embebidos cuando el archivo se abre con `file://` (polÃ­tica
   CORS). **Fix:** el bundle ahora se carga desde un `blob:` URL, que sÃ­ se
   ejecuta con doble clic.

Resultado: el `.html` se abre con doble clic y muestra el Dashboard + el buscador
histÃ³rico, sin 404.

## âš ï¸ IMPORTANTE: aplicar en LAS 3 PC
Reemplaza el **frontend (`dist`)**. Ejecutar UNA vez en cada PC (Monitor,
Terminal A y Terminal B) y recargar con **Ctrl+F5**.

> Sugerencia por prudencia: aplicar primero en una Terminal, verificar que
> arranca normal, y por Ãºltimo en el Monitor.

## Pasos (en cada PC)
1. Enchufar el pendrive.
2. Entrar a: `upgrades\UPGRADE_EXPORTAR_HISTORIAL_PENDRIVE_2026-10-21`
3. Click **DERECHO** en **`1-APLICAR_UPGRADE.bat`** â†’ **"Ejecutar como
   administrador"** â†’ **SÃ­** (UAC).
4. Esperar **"EXITO. Upgrade aplicado en esta PC"**.
5. En el kiosko, recargar con **Ctrl+F5**.

## CÃ³mo probar (en el Dashboard, desde la cabina)
1. Dashboard â†’ **"Exportar a Pendrive"** â†’ ingresar contraseÃ±a.
2. **Exportar y Guardar** â†’ se descarga/guarda un archivo `.html`.
3. Abrir ese `.html` con doble clic (en la misma PC o en otra): debe verse el
   Dashboard con grÃ¡ficos y el botÃ³n **"Buscador HistÃ³rico de Llaves"**.
4. En el buscador: probar filtro por **rango de fechas**, texto, y verificar que
   aparecen las **notas** de las llaves que las tenÃ­an.

## Si algo sale mal (rollback)
Click DERECHO en **`2-DESHACER_ROLLBACK.bat`** â†’ "Ejecutar como administrador".
Restaura el Ãºltimo `dist_backup_*` **sano**. Si ninguno estuviera sano, usar el
pendrive de RESCATE.

## ValidaciÃ³n hecha en desarrollo (regla raÃ­z #0)
- `tsc --noEmit`: EXIT 0.
- `vite build`: OK (bundle `index-BHaBeC0c.js`).
- App abierta por HTTP: index 200, ruta `/visor` 200.
- **Prueba `file://` real (la que faltÃ³ la vez anterior):** se generÃ³ un `.html`
  autocontenido con el bundle nuevo y un snapshot de ejemplo, y se abriÃ³ con
  **doble clic** en Chrome. Resultado confirmado: se ve el Dashboard (KPIs,
  "Tasa de devoluciÃ³n") y el **Buscador HistÃ³rico de Llaves** con las tarjetas y
  el filtro por fechas. **Ya NO aparece el 404.**
- NOTA: el flujo con DATOS reales de producciÃ³n (exportar desde el Monitor â†’
  abrir el html â†’ ver grÃ¡ficos poblados con datos reales) conviene probarlo
  primero en una Terminal y luego en el Monitor.

## Notas tÃ©cnicas (para integraciÃ³n posterior)
- **No** toca PocketBase, **no** borra datos, **no** cambia `config.json`.
- Archivos de cÃ³digo:
  - `src/lib/visorSnapshot.ts` (NUEVO): detecta el modo visor.
  - `src/pages/VisorInforme.tsx` (NUEVO): la vista `/visor` (Dashboard + buscador).
  - `src/App.tsx`: ruta `/visor`.
  - `src/main.tsx`: si hay snapshot, arranca en modo visor (sin PocketBase).
  - `src/hooks/useVigilantes.ts`, `src/hooks/useObjetosOlvidados.ts`,
    `src/contexts/SolicitudesContext.tsx`: leen del snapshot si existe (sin
    impacto en producciÃ³n cuando no hay snapshot).
  - `src/components/admin/AdvancedExportModal.tsx` + `src/utils/exportUtils.ts`:
    generan el `.html` autocontenido (`exportarVisorOffline`).
