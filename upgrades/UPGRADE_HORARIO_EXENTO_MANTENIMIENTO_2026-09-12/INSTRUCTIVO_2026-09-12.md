# UPGRADE — Horario: Mantenimiento exento 24 hs (2026-09-12)

## Qué hace
Agrega el departamento/sección **Mantenimiento** a la lista de **Personal TAS
exento TOTAL del horario restringido**. Es decir, el Personal TAS de
Mantenimiento puede **solicitar llaves a cualquier hora (24 hs)**, igual que
Servicios Generales, Vigilancia, Intendencia y Electrotecnia.

- El resto de los usuarios (Docentes, Alumnos, Empresas y demás Personal TAS)
  mantiene el corte de las **07:00** y el **bloqueo nocturno** (23:00 en
  adelante y antes de las 06:00).
- La franja especial **06:00–06:59 para Empresas** queda igual que antes.
- Es un cambio SOLO de **frontend (dist)**. No toca PocketBase ni datos.

## IMPORTANTE — Aplicar en LAS 3 PC
Este upgrade cambia el **frontend compilado (`dist`)**. Cada PC (Monitor,
Terminal A y Terminal B) sirve su **propio `dist` local** en
`127.0.0.1:5173`. Por eso hay que **ejecutar el mismo script una vez en cada
una de las 3 PC**. Si se aplica solo en el Monitor, las Terminales A/B seguirán
con el JavaScript viejo y el cambio "no aparece".

## Pasos (repetir en Monitor, Terminal A y Terminal B)
1. Enchufá el pendrive.
2. Abrí la carpeta
   `UPGRADES\UPGRADE_HORARIO_EXENTO_MANTENIMIENTO_2026-09-12`.
3. Doble clic en **`1-APLICAR_UPGRADE.bat`** (pedirá permisos de
   administrador → Sí).
4. Esperá el mensaje **EXITO** y presioná ENTER para cerrar.
5. Cerrá el navegador/kiosko y volvé a abrirlo (o Ctrl+F5).

## Cómo probarlo (en Terminal A o B)
- **A)** Identificate como **Personal TAS con departamento "Mantenimiento"**,
  elegí una llave y enviá, incluso en horario restringido (antes de las 7:00 o
  después de las 23:00). → Debe **dejar enviar SIN banner rojo**.
- **B)** Un usuario común (ej. Docente) a las 06:30 debe seguir **BLOQUEADO**
  (banner rojo). El bloqueo nocturno se mantiene para todos los demás.

## Rollback
Si algo sale mal, ejecutá **`2-DESHACER_ROLLBACK.bat`** en la misma PC:
restaura el último `dist_backup_*` que dejó el script al aplicar.
