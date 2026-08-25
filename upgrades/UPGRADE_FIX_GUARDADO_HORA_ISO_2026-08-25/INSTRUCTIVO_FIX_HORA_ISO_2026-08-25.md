# UPGRADE (FIX): Guardado de hora en formato ISO

**Fecha:** 2026-08-25
**Aplicar en:** PC del **Monitor de Vigilancia** (la de la cabina, servidor).
**NO** hay que hacer nada en Terminal A ni Terminal B.

---

## ¿Qué corrige?

Es la **corrección de fondo** del problema "marcaba 5 horas" que reaparecía al
apretar **F5** después de un intercambio.

**Causa:** el campo de hora se guarda como texto en la base. Al registrar una
entrega, intercambio o devolución, se estaba guardando la fecha en un formato
ambiguo. Cuando se recargaba la pantalla (F5), esa fecha se leía mal y el
contador de "tiempo en uso" saltaba a unas 5 horas, activando antes de tiempo la
alerta y el botón del mensaje de WhatsApp.

**Ahora:** las fechas se guardan siempre en formato estándar (ISO), que se relee
sin ambigüedad. Este fix se suma a los dos anteriores (lectura normalizada y
reinicio del contador en intercambios) y ataca la raíz del problema.

---

## Pasos para aplicarlo

1. Enchufá el pendrive en la **PC del Monitor de Vigilancia**.
2. Entrá a la carpeta:
   `UPGRADES\UPGRADE_FIX_GUARDADO_HORA_ISO_2026-08-25`
3. Hacé **doble clic** en **`1-APLICAR_FIX_HORA_ISO.bat`**.
4. Si Windows pide permisos de administrador, aceptá (**Sí**).
5. Esperá a que diga **"EXITO. Upgrade aplicado."** y presioná ENTER.
6. **Cerrá el navegador/kiosko y volvé a abrirlo** (`Ctrl+F5` si hace falta).

---

## Cómo comprobar que funcionó

1. Hacé un **intercambio** de una llave que esté en uso.
2. El contador de "tiempo en uso" debe reiniciarse a pocos minutos.
3. Apretá **F5** (recargar): el tiempo debe **seguir mostrando pocos minutos**,
   NO saltar a horas. La alerta / botón de WhatsApp solo debe aparecer cuando de
   verdad se supere el tiempo configurado.

**Importante:** las solicitudes que YA habían quedado mal guardadas antes de este
fix pueden seguir mostrando su hora torcida (el dato viejo ya está en la base).
Toda operación NUEVA queda bien. Para arreglar una vieja: devolvela y volvé a
entregarla.

---

## Si algo sale mal (volver atrás)

Doble clic en **`2-DESHACER_ROLLBACK.bat`** (aceptá permisos de admin).
Restaura el frontend anterior desde el backup automático. No toca datos.

---

## Notas técnicas (para Luis / desarrollo)

- Solo cambia el frontend (`dist`). No toca PocketBase, no borra datos.
- Preserva `config.json` y `system_health.json` (`robocopy ... /XF ...`).
- Deja backup automático `dist_backup_<fecha_hora>` en `C:\sistema-llaves-fcea`.
- Archivo fuente modificado: `src/contexts/SolicitudesContext.tsx`
  - `actualizarSolicitud`: `hora_entrega` / `hora_devolucion` -> `.toISOString()`.
  - `intercambiarPorLugar`: `hora_entrega: new Date().toISOString()`.
- Complementa: fix de lectura (`.replace(' ','T')` en `cargarSolicitudes`) y fix
  del contador (`horaEntregaStr` en `KeyInUseCard.tsx`).
