# ============================================================================
# Script de Verificación de Salud del Sistema
# Sistema de Gestión de Llaves FCEA
# ============================================================================
# Este script verifica el estado de salud del sistema y genera un archivo JSON
# con alertas que serán mostradas en el Monitor de Vigilancia
# ============================================================================

$ErrorActionPreference = "Continue"

# Obtener rutas
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptPath)
$LogFile = Join-Path $ScriptPath "logs\health_check.log"
$HealthStatusFile = Join-Path $ProjectRoot "public\system_health.json"
$BackupsDir = Join-Path $ProjectRoot "pocketbase\pb_backups"
$MaintenanceLog = Join-Path $ScriptPath "logs\maintenance.log"
$DatabaseFile = Join-Path $ProjectRoot "pocketbase\pb_data\data.db"

# Función para escribir en el log
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
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
    }
}

Write-Log "=== Inicio de verificación de salud del sistema ==="

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
            title = "Espacio en disco crítico"
            message = "Solo queda $FreeSpacePercent% de espacio libre ($FreeSpaceGB GB). Acción inmediata requerida."
            action = "Liberar espacio eliminando backups antiguos o archivos temporales"
            icon = "alert-circle"
        }
        $HealthStatus.overallStatus = "critical"
        Write-Log "CRÍTICO: Espacio en disco muy bajo" "ERROR"
    }
    elseif ($FreeSpacePercent -lt 20) {
        $HealthStatus.alerts += @{
            level = "warning"
            title = "Espacio en disco bajo"
            message = "Queda $FreeSpacePercent% de espacio libre ($FreeSpaceGB GB). Considere liberar espacio pronto."
            action = "Revisar y limpiar backups antiguos"
            icon = "alert-triangle"
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
# 2. VERIFICAR ÚLTIMO BACKUP
# ============================================================================
Write-Log "Verificando último backup..."

try {
    if (Test-Path $BackupsDir) {
        $LatestBackup = Get-ChildItem -Path $BackupsDir -Filter "backup_full_*.zip" -ErrorAction SilentlyContinue | 
                        Sort-Object LastWriteTime -Descending | 
                        Select-Object -First 1
        
        if ($LatestBackup) {
            $DaysSinceBackup = [math]::Round((New-TimeSpan -Start $LatestBackup.LastWriteTime -End (Get-Date)).TotalDays, 1)
            $HealthStatus.metrics.lastBackupDaysAgo = $DaysSinceBackup
            
            Write-Log "Último backup: hace $DaysSinceBackup días ($($LatestBackup.LastWriteTime))"
            
            if ($DaysSinceBackup -gt 14) {
                $HealthStatus.alerts += @{
                    level = "critical"
                    title = "Backup desactualizado"
                    message = "El último backup fue hace $DaysSinceBackup días. Sistema de backups puede estar fallando."
                    action = "Verificar tarea programada de mantenimiento y ejecutar backup manual"
                    icon = "database"
                }
                $HealthStatus.overallStatus = "critical"
                Write-Log "CRÍTICO: Backup muy desactualizado" "ERROR"
            }
            elseif ($DaysSinceBackup -gt 8) {
                $HealthStatus.alerts += @{
                    level = "warning"
                    title = "Backup atrasado"
                    message = "El último backup fue hace $DaysSinceBackup días. Debería ejecutarse semanalmente."
                    action = "Verificar que la tarea programada esté activa"
                    icon = "database"
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
                action = "Ejecutar inmediatamente: scripts\configurar_mantenimiento_automatico.ps1"
                icon = "database"
            }
            $HealthStatus.overallStatus = "critical"
            Write-Log "CRÍTICO: No hay backups" "ERROR"
        }
    } else {
        Write-Log "Directorio de backups no existe" "WARNING"
    }
} catch {
    Write-Log "Error al verificar backups: $($_.Exception.Message)" "ERROR"
}

# ============================================================================
# 3. VERIFICAR TAMAÑO DE BASE DE DATOS
# ============================================================================
Write-Log "Verificando tamaño de base de datos..."

try {
    if (Test-Path $DatabaseFile) {
        $DbSizeMB = [math]::Round((Get-Item $DatabaseFile).Length / 1MB, 2)
        $HealthStatus.metrics.databaseSizeMB = $DbSizeMB
        
        Write-Log "Tamaño de base de datos: $DbSizeMB MB"
        
        if ($DbSizeMB -gt 500) {
            $HealthStatus.alerts += @{
                level = "warning"
                title = "Base de datos grande"
                message = "La base de datos tiene $DbSizeMB MB. Considere archivar datos históricos."
                action = "Ejecutar mantenimiento anual: archivar datos antiguos"
                icon = "hard-drive"
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
                action = "Revisar archivo: pocketbase\maintenance\logs\maintenance.log"
                icon = "file-text"
            }
            if ($HealthStatus.overallStatus -eq "healthy") {
                $HealthStatus.overallStatus = "warning"
            }
            Write-Log "ADVERTENCIA: $ErrorCount errores encontrados en logs" "WARNING"
        }
        
        # Verificar última ejecución de mantenimiento
        $LastMaintenanceLine = Get-Content $MaintenanceLog -Tail 50 -ErrorAction SilentlyContinue | 
                               Select-String -Pattern "=== Inicio del mantenimiento" | 
                               Select-Object -Last 1
        
        if ($LastMaintenanceLine) {
            # Extraer fecha del log (formato: [2026-04-13 08:00:01])
            if ($LastMaintenanceLine -match '\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]') {
                $LastMaintenanceDate = [DateTime]::ParseExact($Matches[1], "yyyy-MM-dd HH:mm:ss", $null)
                $DaysSinceMaintenance = [math]::Round((New-TimeSpan -Start $LastMaintenanceDate -End (Get-Date)).TotalDays, 1)
                $HealthStatus.metrics.lastMaintenanceDaysAgo = $DaysSinceMaintenance
                
                Write-Log "Último mantenimiento: hace $DaysSinceMaintenance días"
            }
        }
    }
} catch {
    Write-Log "Error al verificar logs: $($_.Exception.Message)" "ERROR"
}

# ============================================================================
# 5. VERIFICAR ACTUALIZACIÓN DE PENDRIVE DE RECUPERACIÓN
# ============================================================================
Write-Log "Verificando actualización de pendrive..."

try {
    # Buscar archivo marcador de última actualización
    $PendriveMarkerFile = Join-Path $ProjectRoot "pocketbase\maintenance\last_pendrive_update.txt"
    
    if (Test-Path $PendriveMarkerFile) {
        $LastUpdateDate = Get-Content $PendriveMarkerFile -ErrorAction SilentlyContinue
        if ($LastUpdateDate) {
            try {
                $LastUpdate = [DateTime]::Parse($LastUpdateDate)
                $DaysSinceUpdate = [math]::Round((New-TimeSpan -Start $LastUpdate -End (Get-Date)).TotalDays, 0)
                $HealthStatus.metrics.pendriveDaysOutdated = $DaysSinceUpdate
                
                Write-Log "Pendrive actualizado hace: $DaysSinceUpdate días"
                
                if ($DaysSinceUpdate -gt 90) {
                    $HealthStatus.alerts += @{
                        level = "warning"
                        title = "Pendrive de recuperación desactualizado"
                        message = "El pendrive no se actualiza hace $DaysSinceUpdate días. Actualice mensualmente."
                        action = "Ejecutar: scripts\preparar_pendrive_recuperacion.bat"
                        icon = "usb"
                    }
                    if ($HealthStatus.overallStatus -eq "healthy") {
                        $HealthStatus.overallStatus = "warning"
                    }
                    Write-Log "ADVERTENCIA: Pendrive desactualizado" "WARNING"
                }
            } catch {
                Write-Log "Error al parsear fecha de actualización de pendrive" "WARNING"
            }
        }
    } else {
        Write-Log "No hay registro de actualización de pendrive" "INFO"
    }
} catch {
    Write-Log "Error al verificar pendrive: $($_.Exception.Message)" "ERROR"
}

# ============================================================================
# 6. VERIFICAR SERVICIOS CRÍTICOS
# ============================================================================
Write-Log "Verificando servicios críticos..."

try {
    # Verificar si PocketBase está corriendo
    $PocketBaseProcess = Get-Process -Name "pocketbase" -ErrorAction SilentlyContinue
    
    if (-not $PocketBaseProcess) {
        $HealthStatus.alerts += @{
            level = "critical"
            title = "PocketBase no está ejecutándose"
            message = "El servicio de base de datos no está activo. El sistema no funcionará."
            action = "Reiniciar el sistema ejecutando: iniciar_sistema.bat"
            icon = "x-circle"
        }
        $HealthStatus.overallStatus = "critical"
        Write-Log "CRÍTICO: PocketBase no está corriendo" "ERROR"
    } else {
        Write-Log "PocketBase está ejecutándose correctamente"
    }
} catch {
    Write-Log "Error al verificar servicios: $($_.Exception.Message)" "ERROR"
}

# ============================================================================
# 7. GENERAR ARCHIVO JSON DE ESTADO
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
    Write-Log "Estado general: $($HealthStatus.overallStatus)"
    Write-Log "Alertas generadas: $($HealthStatus.alerts.Count)"
} catch {
    Write-Log "Error al generar archivo de estado: $($_.Exception.Message)" "ERROR"
}

Write-Log "=== Verificación de salud completada ==="

# Retornar código de salida según el estado
if ($HealthStatus.overallStatus -eq "critical") {
    exit 2
} elseif ($HealthStatus.overallStatus -eq "warning") {
    exit 1
} else {
    exit 0
}
