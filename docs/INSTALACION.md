# Guía de instalación – Sistema de Gestión de Llaves FCEA v2.0

Esta guía describe cómo desplegar el sistema en **producción de 3 PCs** y en
**modo desarrollo** (1 PC). Para el resumen de la arquitectura ver
[`ARQUITECTURA.md`](./ARQUITECTURA.md).

---

## 0. Requisitos previos en cada PC

- Windows 10 / 11
- [Node.js LTS](https://nodejs.org/) instalado (versión ≥ 18)
- [Google Chrome](https://www.google.com/chrome/) (recomendado para modo kiosk)
- Privilegios de administrador (para abrir el puerto 8090 en el firewall)
- `pocketbase.exe` en `pocketbase\` del repo
  ([descargar PocketBase](https://pocketbase.io/docs/))

---

## 1. Preparar la red local (solo modos 2/3/4)

1. Conectar las 3 mini-PCs al switch de 5 puertos vía cable Ethernet.
2. Asignar IPs estáticas a cada PC. Recomendado:
   - Cabina/Servidor: `192.168.50.10`
   - Terminal-A: `192.168.50.11`
   - Terminal-B: `192.168.50.12`
   - (Dashboard opcional): `192.168.50.13`
3. Subred común: `192.168.50.0/24`, máscara `255.255.255.0`.
4. **Sin gateway / sin DNS** (red cerrada). Si se necesita acceso a Internet
   para actualizaciones, conectar el switch a un router externo y dejar el
   gateway apuntando ahí.
5. Verificar conectividad cruzada con `ping` entre las 3 PCs antes de seguir.

---

## 2. Instalación desde pendrive

### 2.1. Generar el pendrive instalador DRP (una vez, desde la PC productiva)
```powershell
.\scripts\pendrive\crear_pendrive.ps1 -Drive E: -Tipo instalador
```
Esto deja en el pendrive un paquete **autónomo de recuperación ante
desastres**:
- `sistema-llaves-fcea\` → código fuente + **`pb_data\` con TODOS los datos** + `pb_backups\`
- `node-portable\`       → Node.js LTS portable (~30 MB, sin necesidad de internet)
- `INSTALAR.bat`         → lanzador raíz (restaura datos automáticamente)
- `DESINSTALAR.bat`      → desinstalador limpio
- `ACTUALIZAR_DATOS.bat` → refresco semanal de datos
- `ULTIMO_BACKUP.txt`    → metadatos del backup incluido
- `autorun.inf`, `LEEME.txt`

> Ver [`plan_recuperacion_desastres.md`](./plan_recuperacion_desastres.md)
> para el procedimiento de uso del pendrive ante incendio/robo/falla total.

### 2.2. Instalar en cada PC
En **cada** PC (cabina + 2 terminales) hacer lo siguiente:

1. Conectar el pendrive.
2. Doble click en `INSTALAR.bat` (o el sistema lo lanza por autorun).
3. Elegir el **modo** (1 a 4) – ver [`ARQUITECTURA.md`](./ARQUITECTURA.md#3-modos-de-configuración-disponibles).
4. Si elige modos 2/3/4: indicar el **rol** de la PC (`S` cabina, `A` terminal-a,
   `B` terminal-b, `D` dashboard).
5. Si es una terminal: ingresar la **IP de la cabina/servidor**.
6. El instalador:
   - Escribe `public/config.json` con los valores correspondientes.
   - Ejecuta `npm install` + `npm run build`.
   - Si es la cabina: abre el puerto 8090 en el firewall.

---

## 3. Configurar mantenimiento (solo en la cabina)

Después de instalar la PC de la cabina:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install\CONFIGURAR_INICIO_AUTOMATICO.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\maintenance\CONFIGURAR_MANTENIMIENTO.ps1
```

Esto registra 3 tareas programadas:
| Tarea                       | Cuándo corre        | Qué hace                                         |
|-----------------------------|---------------------|--------------------------------------------------|
| `FCEA-Sistema-Llaves-AutoStart` | Al iniciar sesión   | Lanza `INICIAR.bat` (PocketBase + frontend + Chrome kiosk) |
| `FCEA-Watchdog`             | Al iniciar sesión   | Vigila PocketBase y lo relanza si cae           |
| `FCEA-Backup-Diario`        | Todos los días 03:00| Comprime `pb_data\` a `backups\YYYY-MM-DD_HH-mm-ss.zip` |

> Las terminales solo necesitan `FCEA-Sistema-Llaves-AutoStart`; no instalan
> watchdog ni backup (los scripts se autoexcluyen al detectar `rol != monitor`).

### 3.1. Qué se elimina y qué NO se elimina con el mantenimiento automático

La retención por defecto del backup es de **14 días**. **Lo único que se borra
automáticamente** son los **archivos ZIP de la carpeta `backups\`** con más de
14 días de antigüedad (para que la carpeta no crezca indefinidamente).

**Lo que NO se borra nunca con el mantenimiento automático:**

- ❌ La base de datos productiva (`pocketbase\pb_data\data.db` y archivos asociados)
- ❌ El historial de solicitudes, entregas, devoluciones e intercambios de llaves
- ❌ Los registros de autorizaciones de acceso
- ❌ Los objetos olvidados y sus fotos
- ❌ Los usuarios registrados, vigilantes y catálogo de llaves
- ❌ Las anotaciones de la agenda diaria
- ❌ Los logs de operación de PocketBase

Los ZIPs son únicamente **copias de seguridad** del estado de `pb_data\` en un
momento dado; al eliminar los más viejos sólo se libera espacio en disco, los
datos productivos permanecen intactos. Para retención de largo plazo (años) se
usa el archivado anual a pendrive permanente (ver
[`guia_mantenimiento_paso_a_paso.md`](./guia_mantenimiento_paso_a_paso.md) § 5.1).

---

## 4. Verificar la instalación

Desde cualquier PC de la red:
```bat
:: Confirmar que PocketBase responde
curl http://192.168.50.10:8090/api/health
```
Respuesta esperada: `{"code":200,"message":"API is healthy."}`

Desde las terminales, abrir Chrome y ver que el frontend carga (debería ir solo
en modo kiosk al iniciar sesión).

---

## 5. Generar pendrive de recuperación

Una vez que la cabina ya tiene datos productivos:
```powershell
.\scripts\pendrive\crear_pendrive.ps1 -Drive F: -Tipo recuperacion -PbDataPath C:\sistema-llaves-fcea\pocketbase\pb_data
```

Este pendrive contiene:
- `backup_pb_data\` con la base actual.
- `scripts\` con `RECUPERAR.bat`, diagnóstico, reparar PocketBase, restaurar
  backup, verificar red, reinstalar frontend.
- `DESINSTALAR.bat` en la raíz (mismo desinstalador que el pendrive instalador).

**Guardarlo en un lugar seguro y regenerarlo periódicamente.**

---

## 6. Generar pendrive de código fuente (custodia / continuidad)

Este tercer pendrive es independiente y está destinado a custodia
institucional. Contiene el repositorio completo (incluyendo `.git`),
un ZIP comprimido y un hash SHA256 para verificación de integridad.

```powershell
.\scripts\pendrive\crear_pendrive.ps1 -Drive G: -Tipo codigo-fuente
```

Contenido:
- `sistema-llaves-fcea\` → repositorio completo con historial Git.
- `sistema-llaves-fcea_codigo-fuente.zip` → archivo comprimido.
- `SHA256.txt` → hash y commit asociado.
- `LEEME.txt` → instrucciones para levantar el código en otra PC.

**No es un pendrive de instalación.** Para instalar el sistema use el
pendrive de tipo `instalador`.

---

## 7. Desinstalación

A partir de v2.0, los pendrives **Instalador** y **Recuperación**
incluyen un desinstalador limpio en la raíz: `DESINSTALAR.bat`.

### 7.1. Procedimiento recomendado (con pendrive)

1. Conectar cualquiera de los dos pendrives (Instalador o Recuperación).
2. Botón derecho sobre `DESINSTALAR.bat` → **Ejecutar como administrador**.
3. Confirmar escribiendo `SI`.

El desinstalador:

- Detiene `pocketbase.exe`.
- Elimina las tareas programadas `FCEA-*` (backup, watchdog, autostart, etc.).
- Borra la regla de firewall `FCEA-PocketBase-8090`.
- **Respalda automáticamente** `pb_data\`, `pb_backups\` y `config.json`
  en `C:\backup_fcea_<fecha>\`, junto a un `desinstalacion.log`.
- Elimina la carpeta de instalación `C:\sistema-llaves-fcea\`.
- Quita los accesos directos del escritorio público.

Los datos productivos quedan disponibles en `C:\backup_fcea_<fecha>\`
por si se desea reinstalar más adelante: basta copiar `pb_data\` a la
carpeta de la nueva instalación antes de iniciarla.

### 7.2. Desinstalación manual (fallback sin pendrive)

```bat
:: Eliminar tareas programadas
schtasks /Delete /TN "FCEA-Sistema-Llaves-AutoStart" /F
schtasks /Delete /TN "FCEA-Watchdog"                /F
schtasks /Delete /TN "FCEA-Backup-Diario"           /F

:: Cerrar regla de firewall (solo en la cabina)
netsh advfirewall firewall delete rule name="FCEA-PocketBase-8090"

:: Borrar la carpeta del repo cuando esté seguro
rmdir /S /Q C:\sistema-llaves-fcea
```

---

## 8. Validación del esquema de pendrives

Ver `docs/checklist_prueba_pendrives.md` para el plan de pruebas
completo (generación, instalación, recuperación, desinstalación y
restauración de datos).
