# UPGRADE: El Monitor vuelve solo al encabezado tras 4s de inactividad

**Fecha:** 2026-09-03
**PC objetivo:** LAS 3 PC (Monitor de Vigilancia, Terminal A y Terminal B)

---

## Qué hace

En el **Monitor de Vigilancia**, cuando el vigilante baja con el scroll para
mirar "Llaves en uso" o "Llaves devueltas" y **deja de tocar mouse/teclado**,
a los **4 segundos** la pantalla vuelve **suavemente arriba del todo**, donde
están las **"Solicitudes pendientes"**. Así siempre quedan a la vista sin
tener que subir a mano.

### Salvaguardas (para no molestar mientras se trabaja)
- **NO** auto-scrollea si hay un panel/modal abierto (Objetos, Agenda,
  Historial, Configuración, Vigilantes, Llaves, Diagnóstico o el cartel de
  confirmar eliminación de solicitud). Se reanuda al cerrarlo.
- **NO** auto-scrollea si el Monitor está **sin conexión** (para no tapar el
  botón "Reconectar").
- Cualquier movimiento de mouse, tecla, rueda, scroll o toque **reinicia** el
  contador de 4 segundos.

---

## Por qué se aplica en las 3 PC

El frontend (`dist`) **no** se sirve centralizado: cada PC corre su propio
`vite preview` en `127.0.0.1:5173` sirviendo el `dist` de su **propio disco**.
Aunque este cambio se ve solo en el Monitor, se aplica en las 3 PC para
mantenerlas idénticas y que una futura instalación/recuperación no revierta
nada.

---

## Pasos (repetir en CADA una de las 3 PC)

1. Enchufá el pendrive.
2. Entrá a la carpeta
   `upgrades\UPGRADE_MONITOR_AUTOSCROLL_ENCABEZADO_2026-09-03`.
3. Doble clic en **`1-APLICAR_UPGRADE.bat`** (pedirá permisos de administrador).
4. Cuando diga **EXITO**, cerrá el navegador/kiosko y volvé a abrirlo (Ctrl+F5).

---

## Cómo probarlo (en el Monitor)

1. Bajá con la rueda del mouse hasta "Llaves en uso" / "Llaves devueltas".
2. Soltá el mouse y no toques nada.
3. A los **4 segundos** la pantalla debe volver sola arriba del todo, dejando
   a la vista las "Solicitudes pendientes".
4. Abrí un panel (ej. Historial): mientras esté abierto **NO** debe auto-subir.

---

## Rollback (si algo sale mal)

Doble clic en **`2-DESHACER_ROLLBACK.bat`** en la misma PC. Restaura el último
`dist_backup_<fecha_hora>`.

---

## Notas técnicas

- Archivo modificado: `src/pages/MonitorVigilancia.tsx` (nuevo `useEffect` con
  temporizador de 4s + listeners de actividad; depende de `isConnected` y de si
  hay algún modal abierto).
- El script `robocopy` del `dist` **excluye** `config.json` y
  `system_health.json` (regla de oro: nunca pisar la config de red per-PC).
- No toca PocketBase ni los datos.
