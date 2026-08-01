# INSTRUCTIVO — FIX Monitor: contador de tiempo + formato + borde rojo
**Fecha:** 2026-07-31
**Dónde se ve el cambio:** MONITOR VIGILANCIA (recomendado aplicarlo también en Terminal A y B)
**Riesgo:** BAJO — solo reemplaza el frontend compilado. No toca PocketBase, ni la base de datos, ni `config.json`.

---

## ¿Qué resuelve / mejora?

1. **FIX contador "Hace 300 min":** al llegar un pedido nuevo, el contador ya **no** aparece con un número grande. Arranca correctamente porque ahora se ancla al reloj del **propio Monitor** (campo `created` de PocketBase), no al de la Terminal.

2. **Formato de reloj escalonado** (tanto en pedidos pendientes como en llaves en uso):
   - **Menos de 10 s** → "Ahora" (o "Recién entregada" en llaves en uso)
   - **Menos de 1 minuto** → "Hace menos de 1 minuto"
   - **Menos de 1 hora** → "Hace X minutos"
   - **1 hora o más** → "Hace HH:MM:SS"

3. **Alerta visual nueva:** las tarjetas de **pedidos pendientes** ahora tienen un **contorno rojo firme** permanente (mientras no se entregue la llave), para que se distingan de un vistazo de las "llaves en uso". Se quitaron los colores viejos de urgencia por minutos (gris/amarillo/rojo) del pedido.

---

## PASO A PASO (en la PC del MONITOR VIGILANCIA)

1. Enchufá el pendrive.
2. Abrí la carpeta `fix\FIX_MONITOR_TIEMPO_Y_BORDE_2026-07-31` del pendrive.
3. **Doble clic** en **`APLICAR_FIX_MONITOR_TIEMPO_Y_BORDE.bat`**.
   - Si Windows pregunta, elegí "Sí"/"Ejecutar de todas formas".
4. El script hace solo:
   - Un **backup** del frontend actual (en `C:\sistema-llaves-fcea\backup_fix_monitor_tiempo_borde_<fecha_hora>`).
   - Reemplaza `index.html` + `assets\` por la versión corregida.
   - **No toca** `config.json` ni `system_health.json`.
5. Cuando diga "FIX APLICADO", presioná ENTER para cerrar.
6. **Recargá el frontend:** cerrá el kiosko (Alt+F4) y volvé a abrirlo, **o reiniciá la PC**.

---

## CÓMO VERIFICAR QUE FUNCIONÓ

1. Desde la **Terminal A o B**, pedí una llave.
2. En el **Monitor**, la tarjeta del pedido debe:
   - Tener **contorno rojo firme**.
   - Mostrar **"Ahora"** los primeros ~10 segundos.
   - Luego **"Hace menos de 1 minuto"**, después **"Hace X minutos"**.
3. Entregá la llave. En "llaves en uso" debe decir **"Recién entregada"** y luego **"En uso hace X minutos"**.
4. La alerta de WhatsApp para salones (cuando se pasa del tiempo configurado) sigue funcionando igual.

Si todo esto se ve bien → **avisame acá en la laptop** y recién ahí hago el commit + integro a los scripts críticos.

---

## ROLLBACK (si algo sale mal)

1. Andá a `C:\sistema-llaves-fcea\`.
2. Buscá la carpeta `backup_fix_monitor_tiempo_borde_<fecha_hora>` más reciente.
3. Copiá su `index.html` y su carpeta `assets\` de vuelta sobre `C:\sistema-llaves-fcea\dist\` (sobrescribiendo).
4. Recargá el kiosko / reiniciá.

---

## Archivos de código modificados (referencia interna)
- `src/utils/tiempoEspera.ts` (NUEVO — helper de formato compartido)
- `src/components/monitor/PendingRequestCard.tsx`
- `src/components/monitor/KeyInUseCard.tsx`
- (del fix anterior, ya incluidos) `src/types/solicitud.ts`, `src/contexts/SolicitudesContext.tsx`
