# Cómo recuperar datos borrados por error

**Sistema de Gestión de Llaves FCEA — v2.8 (2026-07-23)**

Esta guía explica qué hacer si alguien borró por error una llave, un
contacto de la agenda, una autorización o un vigilante desde la
interfaz del Monitor, incluso a pesar del modal "CONFIRMAR" que se
introdujo en la versión 2.8.

> Regla de oro: **no cundir**, respirar hondo, seguir los pasos abajo.
> Si el backup diario corrió al menos una vez, los datos están.

---

## 1. Antes de empezar: ¿qué se puede perder y qué NO?

### Datos que viven en la base de datos (`pb_data\data.db`)

Son los que se pueden borrar por error desde la interfaz. Están
respaldados por el backup diario:

- **Llaves / lugares** (colección `lugares`).
- **Contactos de la agenda** (colección `usuarios_registrados`).
- **Autorizaciones** (colección `autorizaciones`, tab "Autorizaciones"
  del modal Agenda).
- **Vigilantes** (colección `vigilantes`).
- **Solicitudes históricas** (no se borran manualmente desde la UI, se
  auto-archivan; también están respaldadas).

### Datos que NO se pierden desde la interfaz

- Configuración de rol (`public\config.json`).
- Scripts, .bat, .ps1: viven en el repo, no en la base.
- Semilla de instalación en el pendrive.

---

## 2. Verificar que el backup automático está andando

En la PC servidor (rol = monitor), abrir PowerShell **como
Administrador** y correr:

```powershell
Get-ScheduledTask -TaskName "FCEA-Backup-Diario" |
  Format-List TaskName, State, LastRunTime, NextRunTime, LastTaskResult
```

Salida esperada:

- `State: Ready`
- `LastRunTime` debería mostrar el día anterior (o hace pocas horas).
- `LastTaskResult: 0` (éxito) o algún valor ≠ 267014 (267014 = "no
  corrió todavía", es normal recién instalado).

Si dice que la tarea **no existe**, hay que reinstalarla ejecutando
el script que las registra a todas (watchdog + backup + chequeo de
salud):

```powershell
cd <ruta-del-repo>\scripts\maintenance
PowerShell -ExecutionPolicy Bypass -File CONFIGURAR_MANTENIMIENTO.ps1
```

Después, para forzar un backup manual y verificar que funciona:

```powershell
Start-ScheduledTask -TaskName "FCEA-Backup-Diario"
# Esperar ~30 segundos y revisar la carpeta backups\:
Get-ChildItem <ruta-del-repo>\backups\*.zip |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 3 Name, LastWriteTime, Length
```

También hay un log en:

```
<ruta-del-repo>\pocketbase\maintenance\logs\backup.log
```

---

## 3. Localizar el ZIP del último backup previo al borrado

Los backups viven en:

```
<ruta-del-repo>\backups\
```

Nombre del archivo: `YYYY-MM-DD_HH-mm-ss.zip`.

Por ejemplo, si el borrado por error fue **hoy a las 14:32**, hay que
buscar el ZIP más reciente cuya hora sea anterior a las 14:32. Muy
probablemente sea el de las 03:00 AM de hoy o de ayer.

```powershell
Get-ChildItem C:\<ruta-del-repo>\backups\*.zip |
  Sort-Object LastWriteTime -Descending |
  Select-Object Name, LastWriteTime
```

Retención por defecto: **14 días**. Si el borrado se descubre más
tarde, revisar la carpeta `backups\` antes de que se limpie el archivo
correspondiente.

> **Tip:** si sabés que hay riesgo de que alguien haya borrado algo,
> **copiá inmediatamente el ZIP más reciente a un pendrive o carpeta
> aparte** antes de seguir. Así, aunque la retención de 14 días borre
> el ZIP dentro de dos semanas, vos ya tenés una copia congelada.

---

## 4. Restaurar la base (opción "cañón": todo o nada)

Esta opción restaura **toda** la base tal cual estaba al momento del
backup. **Pierde todo lo que se cargó después de ese backup** (por
ejemplo, solicitudes de llaves que se registraron entre las 03:00 AM y
el momento del incidente).

Solo hacer esto si el borrado por error es **crítico** y no hay
manera de reconstruirlo cargándolo a mano.

Pasos (en la PC servidor, rol=monitor):

1. **Frenar PocketBase.** Cerrar la ventana donde corre `pocketbase.exe`,
   o desde PowerShell:
   ```powershell
   Get-Process pocketbase -ErrorAction SilentlyContinue | Stop-Process -Force
   ```
2. **Ubicar el `pb_data\` activo.** Puede estar en:
   - `<ruta-del-repo>\pocketbase\pb_data\` (instalación portable), o
   - `C:\ProgramData\FCEA-Sistema-Llaves\pb_data\` (instalación productiva).

   Para saber cuál está activo, mirar cuál contiene `data.db` con
   timestamp reciente.
3. **Renombrar el `pb_data\` actual como respaldo temporal**, por si
   algo sale mal:
   ```powershell
   Rename-Item "<ruta-a-pb_data>" "pb_data_ANTES_DE_RESTAURAR_$(Get-Date -Format yyyyMMdd_HHmmss)"
   ```
4. **Extraer el ZIP del backup** al lugar donde estaba `pb_data\`:
   ```powershell
   Expand-Archive -Path "<ruta-del-repo>\backups\<YYYY-MM-DD_HH-mm-ss>.zip" `
                  -DestinationPath "<ruta-donde-va-pb_data>\pb_data"
   ```
   Es importante que el resultado sea una carpeta llamada exactamente
   `pb_data` (con `data.db` adentro, no un `pb_data\pb_data\`).
5. **Reiniciar PocketBase** (o directamente reiniciar el sistema
   corriendo `INICIAR.bat`).
6. Verificar en la UI que los datos borrados volvieron.
7. Si todo bien, después de unas horas se puede borrar la carpeta
   `pb_data_ANTES_DE_RESTAURAR_*`.

---

## 5. Restaurar SOLO los datos borrados (opción quirúrgica)

Si el borrado por error es puntual (una llave, un contacto, unos
pocos registros) y **no** querés perder lo que se cargó después del
backup, la opción es abrir el `data.db` del ZIP con un editor SQLite
y copiar solo los registros faltantes.

1. Extraer el ZIP en una carpeta aparte (por ejemplo
   `C:\temp\backup_YYYY-MM-DD\`).
2. Abrir `data.db` de esa carpeta con [DB Browser for SQLite](https://sqlitebrowser.org/)
   (gratuito).
3. Ir a la tabla relevante:
   - Llaves borradas → `lugares`
   - Contactos → `usuarios_registrados`
   - Autorizaciones → `autorizaciones`
   - Vigilantes → `vigilantes`
4. Buscar el registro por nombre. Anotar todos los campos.
5. Volver a la UI del Monitor (base viva) y **cargar el registro a
   mano** con los mismos valores. Nota: el `id` va a ser distinto
   (PocketBase genera uno nuevo), pero eso no importa para la
   operativa: lo que importa es que el nombre, edificio, tipo, etc.,
   estén iguales.

Esta opción es más laboriosa pero **no pierde ningún dato** cargado
después del backup.

---

## 6. Prevención — buenas prácticas

- El modal "CONFIRMAR" de v2.8 ya obliga a tipear la palabra completa
  antes de borrar; alerta a la persona de que está haciendo algo
  irreversible. No lo esquiven "por costumbre".
- **Guardar copia externa periódica.** Cada 1–2 semanas, copiar el
  ZIP más reciente de `backups\` a un pendrive dedicado y guardarlo
  bajo llave. Así, aunque falle el disco del servidor, los datos
  están.
- **Archivado anual.** Al fin de cada año lectivo, hacer un backup
  manual y copiarlo a un pendrive de archivo permanente, etiquetado
  con la fecha. Estos NO deben pisarse con el tiempo.
- **No apagar la PC servidor a las 03:00 AM.** Si la PC está apagada
  a esa hora, el backup no corre. La tarea tiene
  `StartWhenAvailable=true` así que corre igual apenas se enciende,
  pero mejor no depender de eso.

---

## 7. Preguntas frecuentes

**¿El backup pisa el `data.db` en vivo?**
No. `backup_automatico.ps1` usa `robocopy /MIR` a una carpeta destino
distinta y después la comprime. La base productiva no se toca.

**¿Puedo restaurar un backup en una PC terminal?**
No. El backup solo tiene sentido en la PC servidor (rol=monitor). Las
terminales no tienen `pb_data\`; se conectan a la del servidor por red.

**¿Hasta cuándo vive un backup?**
14 días por defecto. Se controla con el parámetro `-RetencionDias` de
`backup_automatico.ps1`. Si querés más días, editar el script o pasar
el parámetro al invocarlo desde la Tarea Programada.

**¿Y si borré algo hace más de 14 días?**
Solo se recupera si alguien guardó una copia externa (ver §6). Por
eso la práctica de copia a pendrive quincenal es clave.

**¿La eliminación queda registrada en algún log?**
El `data.db` de PocketBase mantiene el registro histórico de las
operaciones de creación (fecha `created`). El **borrado** en cambio
elimina el registro definitivamente; la única traza es que "algo dejó
de estar". Por eso el modal de v2.8 exige tipear "CONFIRMAR": para
que sea muy difícil borrar sin darse cuenta.
