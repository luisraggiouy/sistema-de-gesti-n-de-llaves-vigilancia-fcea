# FIX — Historial lento al abrir/cerrar (scroll infinito)
**Fecha:** 2026-10-15

Paquete con **un solo cambio** (fix), separado e independiente. Trae su propio
`dist` ya compilado y verificado, y su propio rollback.

## Qué arregla
Al tocar **Historial** (Buscador Histórico de Llaves) en el Monitor:

- **Antes:** el diálogo tardaba ~3 segundos en **abrir** y otro tanto en
  **cerrar**, porque pintaba TODAS las tarjetas del historial de golpe (miles).
- **Ahora:** abre y cierra al instante. Se muestran ~40 registros y, al **bajar
  el scroll**, se cargan los siguientes automáticamente (scroll infinito). La
  **búsqueda** y los **filtros por fecha** siguen operando sobre el **total**
  (no solo lo visible), y el contador "X de Y registros" muestra el total real.
- Al llegar al final, el cartel "Cargando más registros…" **desaparece** (no
  queda clavado).

## Validación hecha en desarrollo
- Type-check `tsc --noEmit`: OK.
- `vite build`: OK (bundle `index-PQC5a49I.js`).
- App compilada abierta y probada: renderiza, Historial abre/cierra y scrollea.

---

## ⚠️ IMPORTANTE: aplicar en LAS 3 PC
Reemplaza el **frontend (`dist`)**. Cada PC (Monitor, Terminal A y Terminal B)
sirve su propio `dist`. **Ejecutar una vez en cada una de las 3 PC** y recargar
el kiosko con **Ctrl+F5** (no hace falta cerrar el navegador).

**Sugerencia de orden (seguridad):** aplicarlo PRIMERO en una Terminal (A o B)
y verificar que esa Terminal arranca normal; luego la otra Terminal; y por
ÚLTIMO el Monitor, donde además se prueba el Historial.

## Pasos (en cada PC)
1. Enchufar el pendrive.
2. Entrar a: `FIX\FIX_HISTORIAL_LENTO_SCROLL_INFINITO_2026-10-15`
3. Click **DERECHO** en **`1-APLICAR_FIX.bat`** → **"Ejecutar como
   administrador"** → aceptar el UAC (**Sí**).
4. Esperar **"EXITO. Fix aplicado en esta PC"**.
5. En el kiosko, recargar con **Ctrl+F5**.

## Cómo probar (en el Monitor)
1. Tocar **Historial**: abre al instante.
2. Bajar el scroll hasta el final: cargan más solos y, al llegar al último, el
   cartel "Cargando más registros…" desaparece.
3. Cerrar: cierra al instante.
4. Buscar o filtrar por fecha: el contador "X de Y registros" muestra el total.

## Si algo sale mal (rollback)
Click DERECHO en **`2-DESHACER_ROLLBACK.bat`** → "Ejecutar como administrador".
Restaura el último `dist_backup_*` **sano** (valida que no esté corrupto antes
de restaurar). Si ninguno estuviera sano, usar el pendrive de RESCATE.

## Notas técnicas (para integración posterior)
- **No** toca PocketBase, **no** borra datos, **no** cambia `config.json`
  (`robocopy … /XF config.json system_health.json`).
- Archivos de código modificados:
  - `src/hooks/useBusquedaHistorial.ts` → render por tandas (`TANDA_HISTORIAL=40`,
    `visibles`, `historialVisible`, `hayMas`, `cargarMas`, `totalFiltrado`).
  - `src/components/monitor/KeyHistorySearch.tsx` → `IntersectionObserver` con el
    contenedor scrolleable como `root` + respaldo `onScroll`; contador usa
    `totalFiltrado`; texto "Cargando más registros…".
