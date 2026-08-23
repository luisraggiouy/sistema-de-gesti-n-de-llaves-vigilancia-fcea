# UPGRADE: Bloqueo nocturno de botones del Monitor (22:00 – 06:00)

**Fecha:** 2026-08-23
**Aplicar en:** PC del **Monitor de Vigilancia** (la de la cabina, que hace de servidor).
**NO** hay que hacer nada en Terminal A ni Terminal B.

---

## ¿Qué hace este upgrade?

Durante el turno nocturno (**de 22:00 a 06:00**), en el Monitor de Vigilancia
quedan **deshabilitados (grises)** los siguientes botones:

- Objetos
- Agenda / Autorizaciones
- Configuración
- Vigilantes
- Llaves
- Dashboard

Al pasar el mouse por encima muestran el mensaje: **"funcionalidad no disponible"**.

Lo que **SÍ sigue funcionando de noche**:

- El botón **Historial** (es solo lectura, no se puede romper nada).
- Toda la operativa principal: ver solicitudes pendientes, **entregar** y
  **devolver** llaves, sonidos, reconexión, etc.

Fuera de ese horario (**de 06:00 a 22:00**) **todos** los botones vuelven a
estar disponibles automáticamente. El cambio ocurre solo, sin necesidad de
recargar la pantalla.

### Protección de seguridad incluida
Si algún día el reloj de la PC quedara con una fecha absurda (por ejemplo,
año 2010, síntoma típico de que se agotó la pila de la placa madre tras un
corte de luz), la restricción **NO se aplica** y todos los botones quedan
disponibles. Así un reloj desconfigurado nunca bloquea los botones de día.

---

## Pasos para aplicarlo

1. Enchufá el pendrive en la **PC del Monitor de Vigilancia**.
2. Entrá a la carpeta:
   `UPGRADES\UPGRADE_BLOQUEO_NOCTURNO_BOTONES_MONITOR_2026-08-23`
3. Hacé **doble clic** en **`1-APLICAR_BLOQUEO_NOCTURNO.bat`**.
4. Si Windows pide permisos de administrador, aceptá (**Sí**).
5. Esperá a que diga **"EXITO. Upgrade aplicado."** y presioná ENTER para cerrar.
6. **Cerrá el navegador/kiosko y volvé a abrirlo** (si hace falta, `Ctrl+F5`
   para forzar recarga).

---

## Cómo comprobar que funcionó

- **Si estás probando entre las 22:00 y las 06:00:** los botones Objetos,
  Agenda, Configuración, Vigilantes, Llaves y Dashboard aparecen **grises**
  y no se pueden clickear. Historial sí funciona.
- **Si estás probando entre las 06:00 y las 22:00:** todos los botones
  funcionan normal (para ver el bloqueo tendrías que esperar a la noche, o
  se puede validar cambiando temporalmente la hora de Windows — no recomendado
  en producción).

---

## Si algo sale mal (volver atrás)

Hacé doble clic en **`2-DESHACER_ROLLBACK.bat`** (aceptá permisos de admin).
Restaura el frontend anterior desde el backup automático que dejó el upgrade.
No toca PocketBase ni los datos.

---

## Notas técnicas (para Luis / desarrollo)

- Este upgrade **solo cambia el frontend** (carpeta `dist`). No toca PocketBase,
  no borra datos, no instala nada.
- El script preserva `config.json` y `system_health.json` (regla de oro:
  `robocopy ... /XF config.json system_health.json`).
- Deja un backup automático `dist_backup_<fecha_hora>` en `C:\sistema-llaves-fcea`.
- Para **reactivar** algún botón de noche en el futuro: en el código fuente,
  archivo `src/utils/horarioRestringido.ts`, quitar el nombre del botón de la
  lista `BOTONES_BLOQUEADOS_DE_NOCHE`, recompilar y volver a empaquetar.
