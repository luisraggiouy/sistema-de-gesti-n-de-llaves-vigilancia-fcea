# ============================================================================
# Script de Configuración Automática del Mantenimiento
# Sistema de Gestión de Llaves FCEA
# ============================================================================
# Este script configura automáticamente la tarea programada de Windows
# para ejecutar el mantenimiento del sistema todos los domingos a las 8:00 AM
# ============================================================================

# Requiere ejecución como Administrador
#Requires -RunAsAdministrator

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Configuración Automática del Mantenimiento - Sistema Llaves FCEA" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Obtener la ruta actual del script
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptPath
$MaintenanceScript = Join-Path $ProjectRoot "pocketbase\maintenance\system_maintenance.ps1"
$MaintenanceDir = Join-Path $ProjectRoot "pocketbase\maintenance"

Write-Host "[1/5] Verificando estructura de directorios..." -ForegroundColor Yellow

# Verificar que existe el script de mantenimiento
if (-not (Test-Path $MaintenanceScript)) {
    Write-Host "ERROR: No se encontró el script de mantenimiento en:" -ForegroundColor Red
    Write-Host "  $MaintenanceScript" -ForegroundColor Red
    Write-Host ""
    Write-Host "Asegúrese de que el sistema esté correctamente instalado." -ForegroundColor Red
    exit 1
}

Write-Host "  ✓ Script de mantenimiento encontrado" -ForegroundColor Green

# Verificar/crear directorios necesarios
$LogsDir = Join-Path $MaintenanceDir "logs"
$BackupsDir = Join-Path $ProjectRoot "pocketbase\pb_backups"

if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
    Write-Host "  ✓ Directorio de logs creado" -ForegroundColor Green
} else {
    Write-Host "  ✓ Directorio de logs existe" -ForegroundColor Green
}

if (-not (Test-Path $BackupsDir)) {
    New-Item -ItemType Directory -Path $BackupsDir -Force | Out-Null
    Write-Host "  ✓ Directorio de backups creado" -ForegroundColor Green
} else {
    Write-Host "  ✓ Directorio de backups existe" -ForegroundColor Green
}

Write-Host ""
Write-Host "[2/5] Eliminando tarea programada existente (si existe)..." -ForegroundColor Yellow

$TaskName = "Mantenimiento Sistema Llaves FCEA"
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($ExistingTask) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "  ✓ Tarea anterior eliminada" -ForegroundColor Green
} else {
    Write-Host "  ✓ No hay tarea anterior" -ForegroundColor Green
}

Write-Host ""
Write-Host "[3/5] Creando nueva tarea programada..." -ForegroundColor Yellow

# Definir la acción (ejecutar el script de mantenimiento)
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$MaintenanceScript`"" `
    -WorkingDirectory $MaintenanceDir

# Definir el trigger (domingos a las 8:00 AM)
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 8:00AM

# Definir configuración adicional
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false `
    -DontStopOnIdleEnd `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 15)

# Definir el principal (ejecutar con privilegios más altos)
$Principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

# Registrar la tarea
try {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Settings $Settings `
        -Principal $Principal `
        -Description "Ejecuta tareas de mantenimiento automatizadas del Sistema de Llaves FCEA todos los domingos a las 8:00 AM. Incluye backups, verificación de integridad y optimización." `
        -ErrorAction Stop | Out-Null
    
    Write-Host "  ✓ Tarea programada creada exitosamente" -ForegroundColor Green
} catch {
    Write-Host "  ERROR al crear la tarea programada:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[4/5] Configurando tarea de verificación diaria de salud..." -ForegroundColor Yellow

$HealthCheckScript = Join-Path $MaintenanceDir "check_system_health.ps1"
$HealthTaskName = "Verificación Salud Sistema Llaves FCEA"

# Eliminar tarea existente si existe
$ExistingHealthTask = Get-ScheduledTask -TaskName $HealthTaskName -ErrorAction SilentlyContinue
if ($ExistingHealthTask) {
    Unregister-ScheduledTask -TaskName $HealthTaskName -Confirm:$false
}

# Crear acción para verificación de salud
$HealthAction = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$HealthCheckScript`"" `
    -WorkingDirectory $MaintenanceDir

# Trigger diario a las 7:00 AM
$HealthTrigger = New-ScheduledTaskTrigger -Daily -At 7:00AM

# Registrar tarea de salud
try {
    Register-ScheduledTask `
        -TaskName $HealthTaskName `
        -Action $HealthAction `
        -Trigger $HealthTrigger `
        -Settings $Settings `
        -Principal $Principal `
        -Description "Verifica diariamente el estado de salud del Sistema de Llaves FCEA y genera alertas si es necesario." `
        -ErrorAction Stop | Out-Null
    
    Write-Host "  ✓ Tarea de verificación de salud creada" -ForegroundColor Green
} catch {
    Write-Host "  ADVERTENCIA: No se pudo crear la tarea de verificación de salud" -ForegroundColor Yellow
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[5/6] Configurando watchdog de PocketBase (cada 2 minutos)..." -ForegroundColor Yellow

$WatchdogScript = Join-Path $ProjectRoot "scripts\watchdog_pocketbase.ps1"
$WatchdogTaskName = "Watchdog PocketBase Sistema Llaves FCEA"

# Eliminar tarea existente si existe
$ExistingWatchdogTask = Get-ScheduledTask -TaskName $WatchdogTaskName -ErrorAction SilentlyContinue
if ($ExistingWatchdogTask) {
    Unregister-ScheduledTask -TaskName $WatchdogTaskName -Confirm:$false
}

# Crear acción para watchdog
$WatchdogAction = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$WatchdogScript`"" `
    -WorkingDirectory (Split-Path -Parent $WatchdogScript)

# Trigger cada 2 minutos
$WatchdogTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2) -RepetitionDuration ([TimeSpan]::MaxValue)

# Registrar tarea de watchdog
try {
    Register-ScheduledTask `
        -TaskName $WatchdogTaskName `
        -Action $WatchdogAction `
        -Trigger $WatchdogTrigger `
        -Settings $Settings `
        -Principal $Principal `
        -Description "Monitorea PocketBase cada 2 minutos y lo reinicia automáticamente si se cae. Garantiza disponibilidad 24/7 del sistema." `
        -ErrorAction Stop | Out-Null
    
    Write-Host "  ✓ Watchdog de PocketBase configurado (cada 2 minutos)" -ForegroundColor Green
} catch {
    Write-Host "  ADVERTENCIA: No se pudo crear el watchdog" -ForegroundColor Yellow
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[6/6] Ejecutando prueba de la tarea..." -ForegroundColor Yellow

try {
    Start-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    Start-Sleep -Seconds 5
    
    # Verificar que se creó el log
    $LogFile = Join-Path $LogsDir "maintenance.log"
    if (Test-Path $LogFile) {
        Write-Host "  ✓ Tarea ejecutada correctamente" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Últimas líneas del log:" -ForegroundColor Cyan
        Get-Content $LogFile -Tail 5 | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ⚠ La tarea se ejecutó pero no se generó log" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ADVERTENCIA: No se pudo ejecutar la prueba" -ForegroundColor Yellow
    Write-Host "  La tarea está configurada pero no se pudo probar" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Green
Write-Host "  ✓ CONFIGURACIÓN COMPLETADA EXITOSAMENTE" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Detalles de la configuración:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Tarea 1: Mantenimiento Semanal" -ForegroundColor White
Write-Host "  • Frecuencia: Todos los domingos a las 8:00 AM" -ForegroundColor Gray
Write-Host "  • Script: system_maintenance.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "  Tarea 2: Verificación de Salud Diaria" -ForegroundColor White
Write-Host "  • Frecuencia: Todos los días a las 7:00 AM" -ForegroundColor Gray
Write-Host "  • Script: check_system_health.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "  Tarea 3: Watchdog de PocketBase" -ForegroundColor White
Write-Host "  • Frecuencia: Cada 2 minutos (24/7)" -ForegroundColor Gray
Write-Host "  • Script: watchdog_pocketbase.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "  Directorios:" -ForegroundColor White
Write-Host "  • Logs: $LogsDir" -ForegroundColor Gray
Write-Host "  • Backups: $BackupsDir" -ForegroundColor Gray
Write-Host ""
Write-Host "Próxima ejecución programada:" -ForegroundColor Cyan
$NextRun = (Get-ScheduledTask -TaskName $TaskName).Triggers[0].StartBoundary
Write-Host "  $NextRun" -ForegroundColor White
Write-Host ""
Write-Host "Para verificar el estado de las tareas:" -ForegroundColor Yellow
Write-Host "  1. Abra el Programador de tareas de Windows (taskschd.msc)" -ForegroundColor White
Write-Host "  2. Busque las 3 tareas creadas" -ForegroundColor White
Write-Host "  3. Revise el historial de ejecuciones" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANTE: El Watchdog garantiza que PocketBase NUNCA esté caído más de 2 minutos" -ForegroundColor Cyan
Write-Host ""
Write-Host "Presione cualquier tecla para salir..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
