# Script de Mantenimiento Automático para el Sistema de Gestión de Llaves FCEA
# Programado para ejecutarse los domingos a las 8:00 AM
# Versión 1.0

# Configuración
$backupDir = "..\pb_backups"
$logDir = ".\logs"
$dbPath = "..\pb_data\data.db"
$maintenanceLog = "$logDir\maintenance.log"
$maxBackups = 52  # Número máximo de backups a mantener (52 semanas = 1 año de historial)
$maxLogSize = 10MB  # Tamaño máximo del archivo de log antes de rotarlo

# Crear directorios si no existen
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Función para registrar en el log
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $maintenanceLog -Value $logMessage
    
    # Si el log es demasiado grande, rotarlo
    if ((Get-Item $maintenanceLog).Length -gt $maxLogSize) {
        $archiveLogName = "$logDir\maintenance_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        Rename-Item -Path $maintenanceLog -NewName $archiveLogName
        New-Item -ItemType File -Path $maintenanceLog -Force | Out-Null
        Write-Log "Archivo de log rotado a $archiveLogName" -Level "INFO"
    }
}

# Función para verificar espacio en disco
function Check-DiskSpace {
    $drive = (Get-Item $PSScriptRoot).PSDrive.Name
    $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$($drive):'"
    $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    $totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
    $freePercentage = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
    
    Write-Log "Espacio en disco: $freeSpaceGB GB libre de $totalSpaceGB GB ($freePercentage%)"
    
    if ($freePercentage -lt 15) {
        Write-Log "¡ALERTA! Espacio en disco bajo (menos del 15% disponible)" -Level "WARNING"
        return $false
    }
    return $true
}

# Función para respaldar la base de datos
function Backup-Database {
    param (
        [switch]$Full
    )
    
    try {
        $date = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupType = if ($Full) { "full" } else { "incremental" }
        $backupPath = "$backupDir\backup_${backupType}_$date.db"
        
        # Detener PocketBase temporalmente si está en ejecución
        $pbProcess = Get-Process "pocketbase" -ErrorAction SilentlyContinue
        $wasStopped = $false
        
        if ($pbProcess) {
            Write-Log "Deteniendo PocketBase temporalmente para el backup..."
            Stop-Process -Name "pocketbase" -Force
            $wasStopped = $true
            Start-Sleep -Seconds 2
        }
        
        # Realizar la copia de la base de datos
        Copy-Item -Path $dbPath -Destination $backupPath -Force
        
        # Reiniciar PocketBase si estaba en ejecución
        if ($wasStopped) {
            Write-Log "Reiniciando PocketBase..."
            Start-Process -FilePath "..\pocketbase.exe" -WorkingDirectory ".." -WindowStyle Hidden
        }
        
        # Comprimir el backup para ahorrar espacio
        Compress-Archive -Path $backupPath -DestinationPath "$backupPath.zip" -Force
        Remove-Item -Path $backupPath -Force
        
        Write-Log "Backup $backupType completado exitosamente: $backupPath.zip"
        return $true
    }
    catch {
        Write-Log "Error al realizar backup: $_" -Level "ERROR"
        return $false
    }
}

# Función para verificar integridad de la base de datos
function Verify-DatabaseIntegrity {
    try {
        # Asumiendo que PocketBase puede ser accedido mediante la CLI
        $tempDir = [System.IO.Path]::GetTempPath()
        $integrityCheckFile = "$tempDir\pb_integrity_check.txt"
        
        # Ruta al CLI de SQLite (puede necesitar ajustarse)
        $sqlitePath = ".\sqlite3.exe"
        if (-not (Test-Path $sqlitePath)) {
            # Descargar SQLite si no está disponible
            $sqliteUrl = "https://www.sqlite.org/2023/sqlite-tools-win32-x86-3410200.zip"
            $sqliteZip = "$tempDir\sqlite.zip"
            Invoke-WebRequest -Uri $sqliteUrl -OutFile $sqliteZip
            Expand-Archive -Path $sqliteZip -DestinationPath "$tempDir\sqlite" -Force
            $sqlitePath = "$tempDir\sqlite\sqlite3.exe"
        }
        
        # Verificar la integridad
        $result = & $sqlitePath $dbPath "PRAGMA integrity_check;" | Out-File -FilePath $integrityCheckFile
        $integrityResult = Get-Content -Path $integrityCheckFile
        
        if ($integrityResult -contains "ok") {
            Write-Log "Verificación de integridad de la base de datos: OK"
            return $true
        }
        else {
            Write-Log "¡ALERTA! Problemas de integridad detectados en la base de datos" -Level "WARNING"
            return $false
        }
    }
    catch {
        Write-Log "Error al verificar integridad de la base de datos: $_" -Level "ERROR"
        return $false
    }
}

# Función para limpiar backups antiguos
function Clean-OldBackups {
    try {
        $backups = Get-ChildItem -Path $backupDir -Filter "*.zip" | Sort-Object LastWriteTime -Descending
        
        if ($backups.Count -gt $maxBackups) {
            $backupsToRemove = $backups | Select-Object -Skip $maxBackups
            foreach ($backup in $backupsToRemove) {
                Remove-Item -Path $backup.FullName -Force
                Write-Log "Eliminado backup antiguo: $($backup.Name)"
            }
        }
        return $true
    }
    catch {
        Write-Log "Error al limpiar backups antiguos: $_" -Level "ERROR"
        return $false
    }
}

# Función para limpiar archivos temporales
function Clean-TempFiles {
    try {
        # Limpiar archivos temporales del sistema
        $tempPath = [System.IO.Path]::GetTempPath()
        $tempFiles = Get-ChildItem -Path $tempPath -Filter "pb_*" -Recurse -ErrorAction SilentlyContinue
        
        foreach ($file in $tempFiles) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
            }
            catch {
                # Ignorar errores de archivos en uso
            }
        }
        
        Write-Log "Limpieza de archivos temporales completada"
        return $true
    }
    catch {
        Write-Log "Error al limpiar archivos temporales: $_" -Level "ERROR"
        return $false
    }
}

# Función para optimizar la base de datos
function Optimize-Database {
    try {
        # Asumiendo que PocketBase puede ser accedido mediante la CLI
        $sqlitePath = ".\sqlite3.exe"
        if (Test-Path $sqlitePath) {
            # Detener PocketBase temporalmente si está en ejecución
            $pbProcess = Get-Process "pocketbase" -ErrorAction SilentlyContinue
            $wasStopped = $false
            
            if ($pbProcess) {
                Write-Log "Deteniendo PocketBase temporalmente para optimización..."
                Stop-Process -Name "pocketbase" -Force
                $wasStopped = $true
                Start-Sleep -Seconds 2
            }
            
            # Ejecutar VACUUM para optimizar el espacio
            & $sqlitePath $dbPath "VACUUM;"
            
            # Reiniciar PocketBase si estaba en ejecución
            if ($wasStopped) {
                Write-Log "Reiniciando PocketBase..."
                Start-Process -FilePath "..\pocketbase.exe" -WorkingDirectory ".." -WindowStyle Hidden
            }
            
            Write-Log "Optimización de base de datos completada"
            return $true
        }
        else {
            Write-Log "SQLite CLI no disponible para optimizar la base de datos" -Level "WARNING"
            return $false
        }
    }
    catch {
        Write-Log "Error al optimizar la base de datos: $_" -Level "ERROR"
        return $false
    }
}

# Inicio del mantenimiento
Write-Log "=== INICIO DE MANTENIMIENTO AUTOMÁTICO $(Get-Date -Format 'yyyy-MM-dd') ==="

# Obtener el día actual
$today = Get-Date
$dayOfWeek = $today.DayOfWeek
$dayOfMonth = $today.Day
$month = $today.Month

# Verificar espacio en disco (siempre)
$diskSpaceOk = Check-DiskSpace

# MANTENIMIENTO SEMANAL (cada domingo)
if ($dayOfWeek -eq "Sunday") {
    Write-Log "Ejecutando tareas de mantenimiento SEMANAL..."
    
    # Backup incremental
    Backup-Database
    
    # Limpiar backups antiguos
    Clean-OldBackups
}

# MANTENIMIENTO MENSUAL (primer domingo del mes)
if ($dayOfWeek -eq "Sunday" -and $dayOfMonth -le 7) {
    Write-Log "Ejecutando tareas de mantenimiento MENSUAL..."
    
    # Backup completo
    Backup-Database -Full
    
    # Verificar integridad
    Verify-DatabaseIntegrity
}

# MANTENIMIENTO TRIMESTRAL (primer domingo de cada trimestre)
if ($dayOfWeek -eq "Sunday" -and $dayOfMonth -le 7 -and ($month -eq 1 -or $month -eq 4 -or $month -eq 7 -or $month -eq 10)) {
    Write-Log "Ejecutando tareas de mantenimiento TRIMESTRAL..."
    
    # Limpiar archivos temporales
    Clean-TempFiles
    
    # Optimizar la base de datos
    Optimize-Database
}

# MANTENIMIENTO ANUAL (primer domingo de enero)
if ($dayOfWeek -eq "Sunday" -and $dayOfMonth -le 7 -and $month -eq 1) {
    Write-Log "Ejecutando tareas de mantenimiento ANUAL..."
    
    # Aquí podría incluirse un script de archivado de datos históricos
    # que podría desarrollarse según las necesidades específicas
    Write-Log "Recordatorio: Realizar mantenimiento manual anual (archivado de datos históricos)"
}

Write-Log "=== FIN DE MANTENIMIENTO AUTOMÁTICO $(Get-Date -Format 'yyyy-MM-dd') ==="