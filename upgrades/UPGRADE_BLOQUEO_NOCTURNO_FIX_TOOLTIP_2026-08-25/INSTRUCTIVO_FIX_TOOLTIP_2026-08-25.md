# UPGRADE (FIX v2): Tooltip + desbloqueo preciso a las 06:00

**Fecha:** 2026-08-25
**Aplicar en:** PC del **Monitor de Vigilancia** (la de la cabina, servidor).
**NO** hay que hacer nada en Terminal A ni Terminal B.

---

## ¿Qué corrige este upgrade?

Es un ajuste sobre el bloqueo nocturno de botones que ya está funcionando.
Corrige dos detalles detectados en producción:

1. **El tooltip ahora SÍ se ve.** Antes, al pasar el mouse sobre un botón
   gris de noche, no aparecía el cartelito. Ahora muestra correctamente
   **"funcionalidad no disponible"**.
   *(Motivo técnico: un botón deshabilitado no recibe eventos del mouse, así
   que el cartelito ahora va en un contenedor que sí los recibe.)*

2. **Desbloqueo preciso a las 06:00.** Antes, el cambio de "bloqueado" a
   "disponible" podía tardar hasta 60 segundos después de las 06:00. Ahora el
   sistema chequea la hora **alineado al reloj** (cerca del segundo :00 de cada
   minuto), así a las 06:00 los botones se reactivan dentro del primer minuto,
   sin necesidad de recargar la pantalla.

**No cambia nada más:** el horario sigue siendo 22:00–06:00, los mismos 6
botones (Objetos, Agenda, Configuración, Vigilantes, Llaves, Dashboard) se
bloquean de noche, Historial y la operativa de llaves siguen siempre activos,
y se mantiene la protección anti-reloj-roto (año < 2025 → no bloquea nada).

---

## Pasos para aplicarlo

1. Enchufá el pendrive en la **PC del Monitor de Vigilancia**.
2. Entrá a la carpeta:
   `UPGRADES\UPGRADE_BLOQUEO_NOCTURNO_FIX_TOOLTIP_2026-08-25`
3. Hacé **doble clic** en **`1-APLICAR_FIX_TOOLTIP.bat`**.
4. Si Windows pide permisos de administrador, aceptá (**Sí**).
5. Esperá a que diga **"EXITO. Upgrade aplicado."** y presioná ENTER.
6. **Cerrá el navegador/kiosko y volvé a abrirlo** (`Ctrl+F5` si hace falta).

---

## Cómo comprobar que funcionó (de noche, 22:00–06:00)

- Pasá el mouse por encima de un botón gris (ej. Configuración): debe aparecer
  el cartelito **"funcionalidad no disponible"**.
- Si esperás hasta las **06:00**, los botones se reactivan solos dentro del
  primer minuto, sin tocar nada.

*(De día, entre 06:00 y 22:00, todos los botones están normales, así que el
tooltip no aparece porque no hay nada bloqueado.)*

---

## Si algo sale mal (volver atrás)

Doble clic en **`2-DESHACER_ROLLBACK.bat`** (aceptá permisos de admin).
Restaura el frontend anterior desde el backup automático. No toca datos.

---

## Notas técnicas (para Luis / desarrollo)

- Solo cambia el frontend (`dist`). No toca PocketBase, no borra datos.
- Preserva `config.json` y `system_health.json`
  (`robocopy ... /XF config.json system_health.json`).
- Deja backup automático `dist_backup_<fecha_hora>` en `C:\sistema-llaves-fcea`.
- Archivos fuente modificados:
  - `src/pages/MonitorVigilancia.tsx` (temporizador alineado + `<span title>`).
  - `src/components/monitor/MonitorHeader.tsx` (estado + temporizador + `<span title>` en Dashboard).
