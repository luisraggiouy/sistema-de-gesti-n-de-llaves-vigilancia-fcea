# UPGRADE — Empresas desde 06:00 + Intendencia 24 hs
**Fecha:** 2026-09-03

## Qué problema resuelve
1. **Empresas antes de las 7.** Hay empresas (ej. la cooperativa
   **"El Progreso"**) que empiezan a trabajar antes de las 7:00. El
   intento anterior (upgrade 2026-08-30) no llegó a funcionar en la
   prueba real. Este upgrade **re-compila y re-despliega** la lógica
   para que quede efectiva: los usuarios de **tipo Empresa** pueden
   **solicitar llaves desde las 06:00** (franja **06:00 a 06:59**).
2. **Intendencia 24 hs.** Se agrega una nueva categoría exenta **total
   (cualquier hora, las 24 hs)**: **Personal TAS** cuyo departamento /
   sección es **"Intendencia"** (son 4 personas). Antes solo estaban
   exentos 24 hs Servicios Generales y Vigilancia.

## Qué cambia exactamente
- **Empresa**: puede solicitar de **06:00 a 06:59** (una hora antes que
  el resto). El bloqueo nocturno sigue: no antes de 06:00 ni desde 23:00.
- **Personal TAS "Intendencia"**: exento **24 hs**, igual que Servicios
  Generales y Vigilancia.
- **El resto de los usuarios** (Docentes, Alumnos, Personal TAS de otras
  secciones): **sin cambios**, siguen bloqueados antes de las 07:00 y
  desde las 23:00.
- El **Monitor de Vigilancia** no tiene candado horario (sin cambios).

## MUY IMPORTANTE — Aplicar en LAS 3 PC
Este upgrade cambia el **frontend compilado (`dist`)**. Cada PC sirve su
propio `dist` local en `127.0.0.1:5173`. Hay que ejecutar el script
**una vez en cada una de las 3 PC**:
1. **Monitor de Vigilancia**
2. **Terminal A**
3. **Terminal B**

Si se aplica solo en el Monitor, las Terminales A/B seguirán con el
JavaScript viejo y el cambio "no aparecerá".

## Pasos (repetir en cada PC)
1. Enchufar el pendrive.
2. Abrir la carpeta `UPGRADES\UPGRADE_HORARIO_EMPRESA06_INTENDENCIA24H_2026-09-03`.
3. Doble clic en **`1-APLICAR_UPGRADE.bat`** (pide permiso de
   administrador → aceptar).
4. Esperar el mensaje **EXITO** y presionar ENTER.
5. **Cerrar el kiosko/navegador y volver a abrirlo** (o `Ctrl+F5`).

## Cómo probarlo (Terminal A o B)
> Se puede cambiar temporalmente la hora del sistema para probar cada
> franja, y devolverla después.
- **A) Empresa entre 06:00 y 06:59:** identificarse como un usuario de
  **tipo Empresa** (ej. Cooperativa El Progreso), elegir una llave y
  enviar → **debe dejar enviar**, sin el banner rojo.
- **B) Intendencia a cualquier hora** (incluso de madrugada): usuario
  **Personal TAS** con departamento **"Intendencia"** → **debe dejar
  enviar** a cualquier hora.
- **C) Usuario común a las 06:30:** debe seguir **bloqueado** (banner
  rojo + aviso "Horario no permitido").

## Nota sobre los 4 usuarios de Intendencia
Para que la exención 24 hs les aplique, cada uno debe estar registrado
como **Personal TAS** con el departamento/sección **"Intendencia"**
(exactamente ese texto). Si alguno está con otro tipo o con el
departamento escrito distinto, no quedará exento.

## Rollback (si algo sale mal)
Ejecutar **`2-DESHACER_ROLLBACK.bat`** en la misma PC. Restaura el último
`dist_backup_*` que dejó el script. No toca PocketBase ni datos.
