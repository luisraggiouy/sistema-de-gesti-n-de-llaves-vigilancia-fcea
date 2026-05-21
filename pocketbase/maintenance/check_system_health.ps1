# ============================================================================
# Script de Verificacion de Salud del Sistema
# Sistema de Gestion de Llaves FCEA
# ============================================================================
# Este script verifica el estado de salud del sistema y genera un archivo JSON
# con alertas que seran mostradas en el Monitor de Vigilancia.
#
# Ejecutado por la tarea programada FCEA-Chequeo-Salud:
#   - Al iniciar sesion del usuario
#   - Cada 30 minutos
#
# Genera dos copias del JSON:
#   - public/system_health.json (dev server: Vite)
#   - dist/system_health.json   (produccion: serve_dist.cjs)
# ============================================================================

$ErrorActionPreference = "Continue"

# Obtener rutas
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptPath)
$LogsDir = Join-Path $ScriptPath "logs"
$LogFile = Join-Path $LogsDir "health_check.log"
$HealthStatusFile = Join-Path $ProjectRoot "public\system_health.json"
# IMPORTANTE: el frontend en produccion se sirve desde dist/ (serve_dist.cjs).
# Vite solo copia public/ -> dist/ durante 'npm run build', por lo que despues
# de eso el archivo queda desincronizado. Escribimos en AMBAS rutas.
$HealthStatusFileDist = Join-Path $ProjectRoot "dist\system_health.json"

# Backups: la tarea FCEA-Backup-Diario escribe en "backups\" en la raiz.
# Algunas instalaciones antiguas usan pocketbase\pb_backups\. Chequeamos ambos.
$BackupsDirNew = Join-Path $ProjectRoot "backups"
$BackupsDirOld = Join-Path $ProjectRoot "pocketbase\pb_backups"
$MaintenanceLog = Join-Path $LogsDir "maintenance.log"
$DatabaseFile = Join-Path $ProjectRoot "pocketbase\pb_data\data.db"

# Marcador de mantenimiento anual hecho manualmente.
# Lo actualiza scripts/maintenance/MARCAR_MANTENIMIENTO_ANUAL.ps1 cuando
# Personal de Sistemas termina el procedimiento anual (vacuum, archivado,
# verificacion de integridad, Windows Update).
$AnnualMaintenanceMarker = Join-Path $ScriptPath "last_annual_maintenance.txt"

# Marcador de actualizacion de pendrive de recuperacion.
$PendriveMarkerFile = Join-Path $ScriptPath "last_pendrive_update.txt"

# Asegurar que el directorio de logs existe (en instalaciones nuevas no existe).
if (-not (Test-Path $LogsDir)) {
    try {
        New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
    } catch {
        # Si no se puede crear, los Write-Log fallaran silenciosamente
        # pero el resto del script SIGUE corriendo y genera el JSON.
    }
}

# Funcion para escribir en el log
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    try {
        Add-Content -Path $LogFile -Value $LogMessage -ErrorAction Stop
    } catch {
        # Sin log: no abortamos, el JSON sigue generandose.
    }
}

# Inicializar objeto de estado de salud
$HealthStatus = @{
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    overallStatus = "healthy"
    alerts = @()
    metrics = @{
        diskSpacePercent = 0
        diskSpaceFreeGB = 0
        lastBackupDaysAgo = 0
        databaseSizeMB = 0
        lastMaintenanceDaysAgo = 0
        pendriveDaysOutdated = 0
        lastAnnualMaintenanceDaysAgo = $null
        windowsUpdateDaysAgo = $null
    }
}

Write-Log "=== Inicio de verificacion de salud del sistema ==="

# ============================================================================
# 1. VERIFICAR ESPACIO EN DISCO
# ============================================================================
Write-Log "Verificando espacio en disco..."

try {
    $Drive = Get-PSDrive -Name C
    $FreeSpaceGB = [math]::Round($Drive.Free / 1GB, 2)
    $TotalSpaceGB = [math]::Round(($Drive.Free + $Drive.Used) / 1GB, 2)
    $FreeSpacePercent = [math]::Round(($Drive.Free / ($Drive.Free + $Drive.Used)) * 100, 2)

    $HealthStatus.metrics.diskSpacePercent = $FreeSpacePercent
    $HealthStatus.metrics.diskSpaceFreeGB = $FreeSpaceGB

    Write-Log "Espacio en disco: $FreeSpaceGB GB libre de $TotalSpaceGB GB ($FreeSpacePercent%)"

    if ($FreeSpacePercent -lt 10) {
        $HealthStatus.alerts += @{
            level = "critical"
            title = "Espacio en disco critico"
            message = "Solo queda $FreeSpacePercent% de espacio libre ($FreeSpaceGB GB). Accion inmediata requerida."
            action = "Liberar espacio eliminando backups antiguos o archivos temporales. Ver guia § 3.1."
            icon = "alert-circle"
            documentation = "docs/guia_mantenimiento_paso_a_paso.md"
        }
        $HealthStatus.overallStatus = "critical"
        Write-Log "CRITICO: Espacio en disco muy bajo" "ERROR"
    }
    elseif ($FreeSpacePercent -lt 20) {
        $HealthStatus.alerts += @{
            level = "warning"
            title = "Espacio en disco bajo"
            message = "Queda $FreeSpacePercent% de espacio libre ($FreeSpaceGB GB). Considere liberar espacio pronto."
            action = "Revisar y limpiar backups antiguos. Ver guia § 3.4."
            icon = "alert-triangle"
            documentation = "docs/guia_mantenimiento_paso_a_paso.md"
        }
        if ($HealthStatus.overallStatus -eq "healthy") {
            $HealthStatus.overallStatus = "warning"
        }
        Write-Log "ADVERTENCIA: Espacio en disco bajo" "WARNING"
    }
} catch {
    Write-Log "Error al verificar espacio en disco: $($_.Exception.Message)" "ERROR"
}

# ============================================================================
# 2. VERIFICAR ULTIMO BACKUP
# ============================================================================
Write-Log "Verificando ultimo backup..."

try {
    # Buscar primero en la carpeta nueva (backups/), luego en la legacy (pb_backups/).
    $LatestBackup = $null
    foreach ($dir in @($BackupsDirNew, $BackupsDirOld)) {
        if (Test-Path $dir) {
            $candidate = Get-ChildItem -Path $dir -Filter "*.zip" -ErrorAction SilentlyContinue |
                         Sort-Object LastWriteTime -Descending |
                         Select-Object -First 1
            if ($candidate -and ($null -eq $LatestBackup -or $candidate.LastWriteTime -gt $LatestBackup.LastWriteTime)) {
                $LatestBackup = $candidate
            }
        }
    }

    if ($LatestBackup) {
        $DaysSinceBackup = [math]::Round((New-TimeSpan -Start $LatestBackup.LastWriteTime -End (Get-Date)).TotalDays, 1)
        $HealthStatus.metrics.lastBackupDaysAgo = $DaysSinceBackup

        Write-Log "Ultimo backup: hace $DaysSinceBackup dias ($($LatestBackup.LastWriteTime))"

        if ($DaysSinceBackup -gt 14) {
            $HealthStatus.alerts += @{
                level = "critical"
                title = "Backup desactualizado"
                message = "El ultimo backup fue hace $DaysSinceBackup dias. La tarea programada de backup puede estar fallando."
                action = "Ejecutar backup manual: scripts\maintenance\backup_automatico.ps1 y revisar tarea FCEA-Backup-Diario. Ver guia § 3.2."
                icon = "database"
                documentation = "docs/guia_mantenimiento_paso_a_paso.md"
            }
            $HealthStatus.overallStatus = "critical"
            Write-Log "CRITICO: Backup muy desactualizado" "ERROR"
        }
        elseif ($DaysSinceBackup -gt 8) {
            $HealthStatus.alerts += @{
                level = "warning"
                title = "Backup atrasado"
                message = "El ultimo backup fue hace $DaysSinceBackup dias. Deberia ejecutarse diariamente (03:00 AM)."
                action = "Verificar que la tarea programada FCEA-Backup-Diario este activa. Ver guia § 3.5."
                icon = "database"
                documentation = "docs/guia_mantenimiento_paso_a_paso.md"
            }
            if ($HealthStatus.overallStatus -eq "healthy") {
                $HealthStatus.overallStatus = "warning"
            }
            Write-Log "ADVERTENCIA: Backup atrasado" "WARNING"
        }
    } else {
        $HealthStatus.alerts += @{
            level = "critical"
            title = "No hay backups"
            message = "No se encontraron backups del sistema. Datos en riesgo."
            action = "Ejecutar como administrador: scripts\maintenance\CONFIGURAR_MANTENIMIENTO.ps1 y luego un backup manual."
            icon = "database"
            documentation = "docs/guia_mantenimiento_paso_a_paso.md"
        }
        $HealthStatus.overallStatus = "critical"
        Write-Log "CRITICO: No hay backups" "ERROR"
    }
} catch {
    Write-Log "Error al verificar backups: $($_.Exception.Message)" "ERROR"
}

# ============================================================================
# 3. VERIFICAR TAMANO DE BASE DE DATOS
# ============================================================================
Write-Log "Verificando tamano de base de datos..."

try {
    if (Test-Path $DatabaseFile) {
        $DbSizeMB = [math]::Round((Get-Item $DatabaseFile).Length / 1MB, 2)
        $HealthStatus.metrics.databaseSizeMB = $DbSizeMB

        Write-Log "Tamano de base de datos: $DbSizeMB MB"

        if ($DbSizeMB -gt 500) {
            $HealthStatus.alerts += @{
                level = "warning"
                title = "Base de datos grande"
                message = "La base de datos tiene $DbSizeMB MB. Considere archivar datos historicos."
                action = "Ejecutar mantenimiento anual: archivar datos antiguos. Ver guia § 5."
                icon = "hard-drive"
                documentation = "docs/guia_mantenimiento_paso_a_paso.md"
            }
            if ($HealthStatus.overallStatus -eq "healthy") {
                $HealthStatus.overallStatus = "warning"
            }
            Write-Log "ADVERTENCIA: Base de datos grande" "WARNING"
        }
    }
} catch {
    Write-Log "Error al verificar base de datos: $($_.Exception.Message)" "ERROR"
}

# ============================================================================
# 4. VERIFICAR ERRORES EN LOGS DE MANTENIMIENTO
# ============================================================================
Write-Log "Verificando logs de mantenimiento..."

try {
    if (Test-Path $MaintenanceLog) {
        $RecentErrors = Get-Content $MaintenanceLog -Tail 100 -ErrorAction SilentlyContinue |
                        Select-String -Pattern "\[ERROR\]" |
                        Select-Object -Last 5

        if ($RecentErrors) {
            $ErrorCount = $RecentErrors.Count
            $HealthStatus.alerts += @{
                level = "warning"
                title = "Errores en mantenimiento"
                message = "Se encontraron $ErrorCount errores recientes en los logs de mantenimiento."
                action = "Revisar archivo: pocketbase\maintenance\logs\maintenance.log. Ver guia § 3.8."
                icon = "file-text"
                documentation = "docs/guia_mantenimiento_paso_a_paso.md"
            }
            if ($HealthStatus.overallStatus -eq "healthy") {
                $HealthStatus.overallStatus = "warning"
            }
            Write-Log "ADVERTENCIA: $ErrorCount errores encontrados en logs" "WARNING"
        }

        # Verificar ultima ejecucion de mantenimiento
        $LastMaintenanceLine = Get-Content $MaintenanceLog -Tail 50 -ErrorAction SilentlyContinue |
                               Select-String -Pattern "=== Inicio del mantenimiento" |
                               Select-Object -Last 1

        if ($LastMaintenanceLine) {
            # Extraer fecha del log (formato: [2026-04-13 08:00:01])
            if ($LastMaintenanceLine -match '\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]') {
                $LastMaintenanceDate = [DateTime]::ParseExact($Matches[1], "yyyy-MM-dd HH:mm:ss", $null)
                $DaysSinceMaintenance = [math]::Round((New-TimeSpan -Start $LastMaintenanceDate -End (Get-Date)).TotalDays, 1)
                $HealthStatus.metrics.lastMaintenanceDaysAgo = $DaysSinceMaintenance

                Write-Log "Ultimo mantenimiento: hace $DaysSinceMaintenance dias"
            }
        }
    }
} catch {
    Write-Log "Error al verificar logs: $($_.Exception.Message)" "ERROR"
}

# ============================================================================
# 5. VERIFICAR ACTUALIZACION DE PENDRIVE DE RECUPERACION
# ============================================================================
Write-Log "Verificando actualizacion de pendrive..."

try {
    if (Test-Path $PendriveMarkerFile) {
        $LastUpdateDate = Get-Content $PendriveMarkerFile -ErrorAction SilentlyContinue
        if ($LastUpdateDate) {
            try {
                $LastUpdate = [DateTime]::Parse($LastUpdateDate)
                $DaysSinceUpdate = [math]::Round((New-TimeSpan -Start $LastUpdate -End (Get-Date)).TotalDays, 0)
                $HealthStatus.metrics.pendriveDaysOutdated = $DaysSinceUpdate

                Write-Log "Pendrive actualizado hace: $DaysSinceUpdate dias"

                if ($DaysSinceUpdate -gt 90) {
                    $HealthStatus.alerts += @{
                        level = "warning"
                        title = "Pendrive de recuperacion desactualizado"
                        message = "El pendrive no se actualiza hace $DaysSinceUpdate dias. Recomendado: actualizar trimestralmente."
                        action = "Ejecutar: scripts\pendrive\crear_pendrive.ps1 -Drive D: -Tipo instalador (cambiar D: por la letra real). Ver guia § 3.7."
                        icon = "usb"
                        documentation = "docs/guia_mantenimiento_paso_a_paso.md"
                    }
                    if ($HealthStatus.overallStatus -eq "healthy") {
                        $HealthStatus.overallStatus = "warning"
                    }
                    Write-Log "ADVERTENCIA: Pendrive desactualizado" "WARNING"
                }
            } catch {
                Write-Log "Error al parsear fecha de actualizacion de pendrive" "WARNING"
            }
        }
    } else {
        Write-Log "No hay registro de actualizacion de pendrive" "INFO"
    }
} catch {
    Write-Log "Error al verificar pendrive: $($_.Exception.Message)" "ERROR"
}

# ============================================================================
# 6. VERIFICAR SERVICIOS CRITICOS
# ============================================================================
Write-Log "Verificando servicios criticos..."

try {
    # Verificar si PocketBase esta corriendo
    $PocketBaseProcess = Get-Process -Name "pocketbase" -ErrorAction SilentlyContinue

    if (-not $PocketBaseProcess) {
        $HealthStatus.alerts += @{
            level = "critical"
            title = "PocketBase no esta ejecutandose"
            message = "El servicio de base de datos no esta activo. El sistema no funcionara."
            action = "Ejecutar: pocketbase\start-server.bat. Si el problema persiste, ver guia § 3.3."
            icon = "x-circle"
            documentation = "docs/guia_mantenimiento_paso_a_paso.md"
        }
        $HealthStatus.overallStatus = "critical"
        Write-Log "CRITICO: PocketBase no esta corriendo" "ERROR"
    } else {
        Write-Log "PocketBase esta ejecutandose correctamente"
    }
} catch {
    Write-Log "Error al verificar servicios: $($_.Exception.Message)" "ERROR"
}

# ============================================================================
# 7. VERIFICAR MANTENIMIENTO ANUAL (vacuum + archivado + integridad)
# ============================================================================
# El mantenimiento anual NO se puede automatizar de forma segura:
# - VACUUM en SQLite requiere detener PocketBase (interrumpe el servicio).
# - El archivado historico requiere decision humana sobre que conservar.
# - Windows Update reinicia el equipo.
# Por eso esta tarea queda en manos de Personal de Sistemas, y la salud
# del sistema nos avisa cuando es momento de hacerla.
# ============================================================================
Write-Log "Verificando mantenimiento anual..."

try {
    if (Test-Path $AnnualMaintenanceMarker) {
        $rawDate = (Get-Content $AnnualMaintenanceMarker -ErrorAction SilentlyContinue | Select-Object -First 1).Trim()
        if ($rawDate) {
            try {
                $LastAnnual = [DateTime]::Parse($rawDate)
                $DaysSinceAnnual = [math]::Round((New-TimeSpan -Start $LastAnnual -End (Get-Date)).TotalDays, 0)
                $HealthStatus.metrics.lastAnnualMaintenanceDaysAgo = $DaysSinceAnnual

                Write-Log "Ultimo mantenimiento anual: hace $DaysSinceAnnual dias"

                if ($DaysSinceAnnual -gt 400) {
                    $HealthStatus.alerts += @{
                        level = "critical"
                        title = "Mantenimiento anual vencido"
                        message = "Hace $DaysSinceAnnual dias que no se realiza el mantenimiento anual (vacuum SQLite + archivado historico + Windows Update)."
                        action = "Coordinar con Personal de Sistemas para ejecutar el procedimiento anual y luego correr: scripts\maintenance\MARCAR_MANTENIMIENTO_ANUAL.ps1. Ver guia § 5."
                        icon = "calendar-x"
                        documentation = "docs/guia_mantenimiento_paso_a_paso.md"
                    }
                    $HealthStatus.overallStatus = "critical"
                    Write-Log "CRITICO: Mantenimiento anual vencido" "ERROR"
                }
                elseif ($DaysSinceAnnual -gt 365) {
                    $HealthStatus.alerts += @{
                        level = "warning"
                        title = "Mantenimiento anual pendiente"
                        message = "Hace $DaysSinceAnnual dias que no se realiza el mantenimiento anual. Es momento de planificarlo."
                        action = "Programar con Personal de Sistemas: vacuum SQLite, archivado historico, verificacion de integridad y Windows Update. Ver guia § 5."
                        icon = "calendar-clock"
                        documentation = "docs/guia_mantenimiento_paso_a_paso.md"
                    }
                    if ($HealthStatus.overallStatus -eq "healthy") {
                        $HealthStatus.overallStatus = "warning"
                    }
                    Write-Log "ADVERTENCIA: Mantenimiento anual pendiente" "WARNING"
                }
            } catch {
                Write-Log "Error al parsear fecha de mantenimiento anual: $($_.Exception.Message)" "WARNING"
            }
        }
    } else {
        # No hay marcador. Si la instalacion es nueva no queremos asustar
        # con una alerta roja inmediatamente; usamos la fecha del archivo de
        # la base de datos como aproximacion de "edad de la instalacion".
        if (Test-Path $DatabaseFile) {
            $InstallAge = [math]::Round((New-TimeSpan -Start (Get-Item $DatabaseFile).CreationTime -End (Get-Date)).TotalDays, 0)
            $HealthStatus.metrics.lastAnnualMaintenanceDaysAgo = $InstallAge

            Write-Log "Sin marcador de mantenimiento anual. Edad de la instalacion: $InstallAge dias"

            if ($InstallAge -gt 365) {
                $HealthStatus.alerts += @{
                    level = "warning"
                    title = "Mantenimiento anual nunca registrado"
                    message = "La instalacion tiene $InstallAge dias y no hay registro de mantenimiento anual."
                    action = "Coordinar con Personal de Sistemas y luego ejecutar: scripts\maintenance\MARCAR_MANTENIMIENTO_ANUAL.ps1. Ver guia § 5."
                    icon = "calendar-clock"
                    documentation = "docs/guia_mantenimiento_paso_a_paso.md"
                }
                if ($HealthStatus.overallStatus -eq "healthy") {
                    $HealthStatus.overallStatus = "warning"
                }
                Write-Log "ADVERTENCIA: Mantenimiento anual nunca registrado" "WARNING"
            }
        } else {
            Write-Log "Sin marcador de mantenimiento anual y sin base de datos. Skipping." "INFO"
        }
    }
} catch {
    Write-Log "Error al verificar mantenimiento anual: $($_.Exception.Message)" "ERROR"
}

# ============================================================================
# 8. VERIFICAR ACTUALIZACIONES DE WINDOWS
# ============================================================================
# Avisa si hace > 180 dias que no se instala ninguna actualizacion de Windows.
# Esto cubre el caso de equipos olvidados con Windows Update desactivado.
# Get-HotFix puede ser lento o requerir permisos; envolvemos en try / silent.
# ============================================================================
Write-Log "Verificando actualizaciones de Windows..."

try {
    $LatestHotfix = Get-HotFix -ErrorAction SilentlyContinue |
                    Where-Object { $_.InstalledOn -ne $null } |
                    Sort-Object InstalledOn -Descending |
                    Select-Object -First 1

    if ($LatestHotfix) {
        $DaysSinceWU = [math]::Round((New-TimeSpan -Start $LatestHotfix.InstalledOn -End (Get-Date)).TotalDays, 0)
        $HealthStatus.metrics.windowsUpdateDaysAgo = $DaysSinceWU

        Write-Log "Ultima actualizacion de Windows: hace $DaysSinceWU dias ($($LatestHotfix.HotFixID))"

        if ($DaysSinceWU -gt 365) {
            $HealthStatus.alerts += @{
                level = "warning"
                title = "Windows Update muy desactualizado"
                message = "Hace $DaysSinceWU dias que no se instalan actualizaciones de Windows. Riesgo de seguridad."
                action = "Ejecutar Windows Update. Reiniciar al terminar. El sistema arranca solo. Ver guia § 5.3."
                icon = "shield-alert"
                documentation = "docs/guia_mantenimiento_paso_a_paso.md"
            }
            if ($HealthStatus.overallStatus -eq "healthy") {
                $HealthStatus.overallStatus = "warning"
            }
            Write-Log "ADVERTENCIA: Windows Update muy desactualizado" "WARNING"
        }
        elseif ($DaysSinceWU -gt 180) {
            $HealthStatus.alerts += @{
                level = "warning"
                title = "Windows Update pendiente"
                message = "Hace $DaysSinceWU dias que no se instalan actualizaciones de Windows."
                action = "Ejecutar Windows Update en un momento de baja actividad. Ver guia § 5.3."
                icon = "shield"
                documentation = "docs/guia_mantenimiento_paso_a_paso.md"
            }
            if ($HealthStatus.overallStatus -eq "healthy") {
                $HealthStatus.overallStatus = "warning"
            }
            Write-Log "ADVERTENCIA: Windows Update pendiente" "WARNING"
        }
    } else {
        Write-Log "Get-HotFix no devolvio resultados (puede requerir permisos)" "INFO"
    }
} catch {
    Write-Log "Error al verificar Windows Update: $($_.Exception.Message)" "ERROR"
}

# ============================================================================
# 9. GENERAR ARCHIVO JSON DE ESTADO
# ============================================================================
Write-Log "Generando archivo de estado..."

try {
    # Convertir a JSON y guardar
    $JsonContent = $HealthStatus | ConvertTo-Json -Depth 10

    # Asegurar que el directorio public existe
    $PublicDir = Split-Path -Parent $HealthStatusFile
    if (-not (Test-Path $PublicDir)) {
        New-Item -ItemType Directory -Path $PublicDir -Force | Out-Null
    }

    Set-Content -Path $HealthStatusFile -Value $JsonContent -Encoding UTF8
    Write-Log "Archivo de estado generado: $HealthStatusFile"

    # Tambien escribir en dist/ si existe (build de produccion).
    # serve_dist.cjs sirve desde dist/, no desde public/, asi que esta
    # copia es CRITICA para que el Monitor de Vigilancia vea el JSON.
    $DistDir = Split-Path -Parent $HealthStatusFileDist
    if (Test-Path $DistDir) {
        try {
            Set-Content -Path $HealthStatusFileDist -Value $JsonContent -Encoding UTF8
            Write-Log "Archivo de estado tambien copiado a: $HealthStatusFileDist"
        } catch {
            Write-Log "No se pudo escribir en dist/: $($_.Exception.Message)" "WARNING"
        }
    } else {
        Write-Log "dist/ no existe, se omite copia a build. (Solo el modo dev usa public/)"
    }

    Write-Log "Estado general: $($HealthStatus.overallStatus)"
    Write-Log "Alertas generadas: $($HealthStatus.alerts.Count)"
} catch {
    Write-Log "Error al generar archivo de estado: $($_.Exception.Message)" "ERROR"
}

Write-Log "=== Verificacion de salud completada ==="

# Retornar codigo de salida segun el estado
if ($HealthStatus.overallStatus -eq "critical") {
    exit 2
} elseif ($HealthStatus.overallStatus -eq "warning") {
    exit 1
} else {
    exit 0
}
