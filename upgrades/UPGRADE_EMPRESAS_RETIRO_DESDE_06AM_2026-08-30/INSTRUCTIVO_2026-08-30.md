# UPGRADE — Empresas pueden solicitar llaves desde las 06:00
**Fecha:** 2026-08-30

## Qué problema resuelve
Hay empresas (por ejemplo cooperativas de limpieza) que empiezan a
trabajar **antes de las 7:00**. Con la restricción horaria vigente, la
Terminal bloqueaba **a todos** los usuarios antes de las 07:00, así que
esas personas no podían registrar el retiro de la llave y se la llevaban
**sin registrar** (pasó ayer con alguien que fue a las 6:10).

## Qué cambia exactamente
- Los usuarios de **tipo "Empresa"** ahora pueden **solicitar llaves desde
  las 06:00** (franja **06:00 a 06:59**).
- **El resto de los usuarios** (Docentes, Alumnos, Personal TAS general)
  **NO cambia**: siguen bloqueados antes de las 07:00.
- **Vigilancia y Servicios Generales** siguen exentos a cualquier hora
  (como antes).
- El **bloqueo nocturno sigue vigente para todos**, empresas incluidas:
  no se puede solicitar **antes de las 06:00** ni **desde las 23:00**.
- El **Monitor de Vigilancia** no tiene candado horario (sin cambios).

## MUY IMPORTANTE — Aplicar en LAS 3 PC
Este upgrade cambia el **frontend compilado (`dist`)**. Cada PC sirve su
propio `dist` local en `127.0.0.1:5173`. Por eso hay que ejecutar el
script **una vez en cada una de las 3 PC**:
1. **Monitor de Vigilancia**
2. **Terminal A**
3. **Terminal B**

Si se aplica solo en el Monitor, las Terminales A/B seguirán con el
JavaScript viejo y el cambio "no aparecerá".

## Pasos (repetir en cada PC)
1. Enchufar el pendrive.
2. Abrir la carpeta `UPGRADES\UPGRADE_EMPRESAS_RETIRO_DESDE_06AM_2026-08-30`.
3. Doble clic en **`1-APLICAR_UPGRADE.bat`** (pide permiso de
   administrador → aceptar).
4. Esperar el mensaje **EXITO** y presionar ENTER.
5. **Cerrar el kiosko/navegador y volver a abrirlo** (o `Ctrl+F5`).

## Cómo probarlo (Terminal A o B, entre las 06:00 y 06:59)
> Si no es esa franja horaria, se puede probar cambiando temporalmente la
> hora del sistema a, por ejemplo, las 06:15, y devolviéndola después.
1. Identificarse como un usuario de **tipo Empresa**.
2. Elegir una llave y enviar la solicitud → **debe dejar enviar**, sin el
   banner rojo de "Horario restringido".
3. Repetir con un usuario **NO-empresa** a esa misma hora → debe seguir
   **bloqueado** (banner rojo + aviso "Horario no permitido").

## Rollback (si algo sale mal)
Ejecutar **`2-DESHACER_ROLLBACK.bat`** en la misma PC. Restaura el último
`dist_backup_*` que dejó el script. No toca PocketBase ni datos.
