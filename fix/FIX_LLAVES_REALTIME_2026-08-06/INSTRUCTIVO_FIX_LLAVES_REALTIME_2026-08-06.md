# INSTRUCTIVO - FIX LLAVES REALTIME (2026-08-06) v2

## Qué arregla
Cuando en el **Monitor Vigilancia** (pestaña *Llaves*) se **agrega / edita / elimina** una
llave, el cambio **NO aparecía en Terminal A ni Terminal B** (ni en el listado ni en el
buscador) hasta reiniciar el navegador o la PC.

### Causa raíz
En `src/contexts/SolicitudesContext.tsx` las llaves (`lugares`) no tenían ni suscripción
realtime ni polling (los usuarios y las solicitudes sí, por eso el celular de "Brad Pitt"
se actualizaba solo). Se replicó para `lugares` **el mismo mecanismo ya probado con
usuarios**: suscripción realtime (create/update/delete) con **upsert/borrado deduplicado
por id** + **polling de respaldo cada 3s** (solo actualiza si la lista cambió).

---

## IMPORTANTE — por qué esta es la versión v2 (NO compila en la PC)
El primer intento (v1) reconstruía el frontend con `vite build` en cada PC. **Falló en el
Monitor** con este error:

```
"environmentManager" is not exported by @tanstack/query-core,
imported by @tanstack/react-query
```

Es decir: el `node_modules` de producción tiene **versiones incompatibles** de
`@tanstack/react-query` y `@tanstack/query-core`. El sistema funciona porque corre el `dist`
**ya compilado** de la instalación, pero **compilar de nuevo ahí rompe**. (El rollback
automático de la v1 dejó el Monitor **intacto**, no pasó nada.)

**Solución v2:** **no se compila en producción**. Se trae el `dist` **ya compilado desde la
laptop** (que sí incluye el fix) y se instala, **preservando** el `config.json` y el
`system_health.json` propios de cada PC. Como la configuración es 100% *runtime*
(`fetch /config.json`), un único `dist` sirve para los **3 roles**.

---

## Contenido del paquete
- `dist_nuevo\` → frontend ya compilado **con el fix** (lo que se instala).
- `APLICAR_FIX.bat` / `APLICAR_FIX.ps1` → instalador (reemplaza dist, preserva config, sin compilar).
- `SolicitudesContext.tsx` → fuente corregido (solo para actualizar el `src\` por consistencia).
- Este instructivo.

---

## Riesgo y rollback
- **No compila.** Solo reemplaza los archivos de `dist\`, **preservando** `config.json` y
  `system_health.json` de esa PC (mantiene rol/pocketbase_url).
- Antes de tocar nada hace **backup completo** de `dist\` → `dist_bak_<fecha>`.
- Si el reemplazo fallara, **rollback automático** (restaura `dist\` del backup).
- No toca PocketBase, base de datos ni scripts críticos → **cero riesgo para los datos**.

---

## PASOS (repetir en las 3 PCs)

> Orden sugerido: **Monitor primero**, después Terminal A, después Terminal B.
> Se puede hacer con el sistema andando; el frontend de esa PC se reinicia unos segundos.

1. Enchufá el **pendrive** en la PC.
2. Entrá a la carpeta del pendrive: `FIX_LLAVES_REALTIME_2026-08-06`.
3. Doble click en **`APLICAR_FIX.bat`**.
4. Aceptá el cartel de **Administrador** (UAC) → "Sí".
5. El script: verifica, respalda `dist\`, preserva tu `config.json`/`system_health.json`,
   instala el `dist` nuevo, restaura tus archivos per-PC y reinicia el frontend (5173).
6. Cuando diga **"FIX APLICADO"**, presioná ENTER para cerrar.
7. En esa PC, **cerrá y volvé a abrir el kiosko** (o `Ctrl+F5`) para cargar el `dist` nuevo.
8. **Verificá que esa PC levante normal** (que identifique usuarios, pida llaves, etc.).

> Consejo: aplicá primero en **una sola** PC (ej. Terminal A) y comprobá que abre bien
> antes de seguir con las otras dos. Así, si algo raro pasara, es en una sola máquina.

---

## CÓMO PROBAR QUE FUNCIONÓ (la prueba de fuego)
Con las 3 PCs ya actualizadas:

1. En el **Monitor** → pestaña **Llaves** → **agregá** una llave de prueba (ej. `PRUEBA SYNC`).
2. En **Terminal A** y **Terminal B**: debe **aparecer sola** en el listado y el buscador,
   **en el acto** (sin reiniciar).
3. En el **Monitor**, **editá** el nombre (ej. `PRUEBA SYNC 2`) → debe cambiar solo en A y B.
4. En el **Monitor**, **eliminá** la llave de prueba → debe desaparecer sola en A y B.

Si funciona → **avisale a Cline** ("funcionó") para integrar a scripts críticos + commit + push.

---

## Log automático (el pendrive es el "cable")
El script escribe:
`FIX_LLAVES_REALTIME_2026-08-06\_RESULTADOS\LOG_APLICAR_FIX_LLAVES_<PC>_<fecha>.log`
Traé el pendrive y Cline lo lee directo.

---

## Rollback manual (por las dudas)
En la PC afectada:
1. Borrá `C:\sistema-llaves-fcea\dist`.
2. Renombrá `C:\sistema-llaves-fcea\dist_bak_<fecha>` a `dist`.
3. Reiniciá la PC (el sistema arranca solo).
