# Guía de mantenimiento — paso a paso

> **Resumen en una línea:** el sistema **se auto‑mantiene**. Esta guía solo
> describe qué hacer cuando el indicador de salud del Monitor de Vigilancia
> muestra una alerta concreta.

Versión del sistema: **v2.0** (3 PCs en LAN, PocketBase 8090, frontend 5173).

---

## 1. Capas de mantenimiento — qué hace el sistema solo

Todo se configura UNA vez en la cabina ejecutando como administrador:

```powershell
.\scripts\maintenance\CONFIGURAR_MANTENIMIENTO.ps1
```

Esto deja registradas tres tareas programadas de Windows:

| Tarea de Windows | Cuándo corre | Qué hace |
|---|---|---|
| `FCEA-Watchdog` | Al login + cada **30 segundos** | Hace GET a `http://127.0.0.1:8090/api/health`. Si falla, mata `pocketbase.exe` colgado y relanza `pocketbase\start-server.bat` |
| `FCEA-Backup-Diario` | Todos los días **03:00 AM** | Ejecuta `scripts\maintenance\backup_automatico.ps1`, comprime `pb_data\` a `backups\YYYY-MM-DD_HH-mm-ss.zip`, retiene los últimos 14 días |
| `FCEA-Chequeo-Salud` | Al login + cada **30 minutos** | Ejecuta `pocketbase\maintenance\check_system_health.ps1` y escribe `public\system_health.json` y `dist\system_health.json` |

Las tres tareas corren solo en la **cabina (rol monitor)**. Las terminales no
necesitan ninguna.

---

## 2. Indicador de salud en el Monitor de Vigilancia

En el header del Monitor (junto al reloj) aparece un texto pequeño:

| Color | Texto | Significado |
|---|---|---|
| 🟢 | **Sistema: OK** | Todo dentro de umbrales aceptables |
| 🟡 | **Sistema: Advertencia** | Disco < 20 %, último backup > 8 días, etc. |
| 🔴 | **Sistema: Crítico** | Disco < 10 %, backup > 14 días o PocketBase caído |
| ⚪ | **Sistema: Cargando / Sin datos** | Primer chequeo aún no ejecutado (espere 1‑2 min tras instalar) |

Al hacer clic se abre un modal con el detalle de cada alerta, **acción
requerida** concreta y referencia al documento de procedimiento.

---

## 3. Respuesta a alertas (procedimientos)

> **Antes de empezar:** todas las acciones manuales se ejecutan en la
> **cabina** (PC con rol monitor) abriendo PowerShell **como administrador**
> y `cd C:\sistema-llaves-fcea`.

### 3.1. 🔴 "Espacio en disco crítico"

```powershell
# 1. Ver tamaño de los backups
Get-ChildItem backups\*.zip | Sort-Object LastWriteTime -Descending |
    Select-Object Name, @{N='MB';E={[math]::Round($_.Length/1MB,1)}}

# 2. Copiar los más antiguos a un pendrive externo (manual)
# 3. Eliminar los copiados conservando los últimos 14
Get-ChildItem backups\*.zip | Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 14 | Remove-Item

# 4. Vaciar la papelera
Clear-RecycleBin -Force
```

### 3.2. 🔴 "Backup desactualizado" (> 14 días)

```powershell
# Forzar un backup ahora
.\scripts\maintenance\backup_automatico.ps1

# Verificar que la tarea programada sigue activa
Get-ScheduledTask FCEA-Backup-Diario | Format-List TaskName,State,LastRunTime,NextRunTime

# Si la tarea no existe o está deshabilitada, re-configurar:
.\scripts\maintenance\CONFIGURAR_MANTENIMIENTO.ps1
```

### 3.3. 🔴 "PocketBase no está ejecutándose"

```powershell
# 1. Confirmar que efectivamente no corre
Get-Process pocketbase -ErrorAction SilentlyContinue

# 2. Lanzarlo manualmente
.\pocketbase\start-server.bat

# 3. Esperar 10 s y verificar que responde
curl http://127.0.0.1:8090/api/health
```

Si el problema persiste, usar el pendrive de **Recuperación** →
`RECUPERAR.bat` → opción **[3] Reparar PocketBase**.

### 3.4. 🟡 "Espacio en disco bajo" (< 20 %)

Mismo procedimiento que 3.1 pero sin urgencia: revisar al final del turno.

### 3.5. 🟡 "Backup atrasado" (> 8 días)

Mismo procedimiento que 3.2: ejecutar backup manual + verificar tarea.

### 3.6. 🟡 "Base de datos grande" (> 500 MB)

Coordinar con Personal de Sistemas un archivado anual (sección 5).

### 3.7. 🟡 "Pendrive de recuperación desactualizado" (> 90 días)

```powershell
# Generar pendrive instalador (incluye datos productivos al día)
.\scripts\pendrive\crear_pendrive.ps1 -Drive D: -Tipo instalador
```

(Cambiar `D:` por la letra real del pendrive.)

### 3.8. 🟡 "Errores en mantenimiento"

```powershell
# Ver últimos 50 errores
Select-String -Path pocketbase\maintenance\logs\maintenance.log `
    -Pattern '\[ERROR\]' | Select-Object -Last 50
```

Si no se entiende el error, archivar el log y contactar Personal de Sistemas.

---

## 4. Verificación rápida sin alertas (opcional, mensual)

Si quiere confirmar manualmente que todo está bien (no es obligatorio,
el indicador del Monitor ya lo cubre):

```powershell
# 1. PocketBase responde
curl http://127.0.0.1:8090/api/health   # esperado: {"code":200,...}

# 2. Frontend responde
curl http://127.0.0.1:5173/             # debe devolver HTML

# 3. Tareas programadas activas
Get-ScheduledTask FCEA-* | Format-Table TaskName, State, LastRunTime

# 4. Último backup
Get-ChildItem backups\*.zip | Sort LastWriteTime -Desc |
    Select -First 1 Name, LastWriteTime, @{N='MB';E={[math]::Round($_.Length/1MB,1)}}
```

---

## 5. Mantenimiento anual (manual, una vez al año)

Procedimiento para Personal de Sistemas — no requiere intervención del
personal de vigilancia.

### 5.1. Archivado de datos históricos

1. Abrir Chrome en modo normal → `http://127.0.0.1:5173/dashboard`.
2. Ingresar la contraseña de exportación (ver `credenciales_sistema.md`).
3. **Exportar Reporte → Avanzada → Año completo → todas las opciones**.
4. Volcar el ZIP a un pendrive etiquetado `ARCHIVO HISTÓRICO FCEA - <AÑO>`.
5. Guardarlo en archivo permanente.

### 5.2. Verificación de integridad de la base

```powershell
# Detener PocketBase primero
Stop-Process -Name pocketbase -Force -ErrorAction SilentlyContinue

# Verificar integridad
& pocketbase\pocketbase.exe --dir=pocketbase\pb_data --dev `
    --hooksDir=pocketbase\pb_hooks serve `
    | Select-Object -First 5   # cancelar con Ctrl+C tras "Server started"

# Alternativa con sqlite3 si está instalado:
# sqlite3 pocketbase\pb_data\data.db "PRAGMA integrity_check;"   ← debe decir "ok"
# sqlite3 pocketbase\pb_data\data.db "VACUUM;"
# sqlite3 pocketbase\pb_data\data.db "ANALYZE;"
```

### 5.3. Actualización de Windows

`⊞ → Windows Update → Buscar actualizaciones`. Instalar solo críticas y de
seguridad. Reiniciar. El sistema arranca solo gracias a
`FCEA-Sistema-Llaves-AutoStart`.

---

## 6. Cosas que **no** hacer

- ❌ No detener manualmente las tareas `FCEA-*` salvo que se documente la
  razón. El watchdog y el backup son la red de seguridad del sistema.
- ❌ No editar `pb_data\data.db` directamente con un editor de texto. Usar
  siempre la UI o el panel admin de PocketBase (`http://127.0.0.1:8090/_/`).
- ❌ No borrar `backups\` completo. Si hace falta espacio, conservar siempre
  los últimos 14 días.
- ❌ No instalar antivirus que ponga en cuarentena `pocketbase.exe` ni que
  bloquee Node.js: la cabina queda inutilizable.

---

## 7. Documentos relacionados

- [`OPERACION.md`](./OPERACION.md) — uso diario, encendido, apagado, troubleshooting.
- [`mantenimiento_resumen_ejecutivo.md`](./mantenimiento_resumen_ejecutivo.md) — visión global del esquema automatizado.
- [`plan_recuperacion_desastres.md`](./plan_recuperacion_desastres.md) — DRP completo (incendio, robo, falla total).
- [`credenciales_sistema.md`](./credenciales_sistema.md) — contraseñas y URLs administrativas.

---

*Guía actualizada: mayo 2026 — v2.0. Esta guía es la **única** referencia de
mantenimiento manual; cualquier procedimiento que aparezca en otros documentos
y contradiga a éste debe considerarse obsoleto.*
