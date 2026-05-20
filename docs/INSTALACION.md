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

### 2.1. Generar el pendrive instalador (una vez, desde una PC con el repo)
```powershell
.\scripts\pendrive\crear_pendrive.ps1 -Drive E: -Tipo instalador
```
Esto deja en el pendrive:
- `sistema-llaves-fcea\`  → código fuente del repo
- `INSTALAR.bat`          → lanzador raíz
- `autorun.inf`, `LEEME.txt`

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

**Guardarlo en un lugar seguro y regenerarlo periódicamente.**

---

## 6. Desinstalación

En la PC a desinstalar:
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
