# Script simplificado para crear tarea de inicio automático
# Debe ejecutarse con permisos de administrador

$ErrorActionPreference = "Stop"

$TaskName = "SistemaLlavesFCEA_AutoInicio"
$WatchdogScript = "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\scripts\watchdog_completo.ps1"

Write-Host "Creando tarea de inicio automático..." -ForegroundColor Cyan

# Eliminar tarea anterior si existe
try {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
} catch {}

# Crear acción
$Action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$WatchdogScript`""

# Crear trigger: al inicio del sistema
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Trigger.Delay = "PT30S"

# Configuración
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit (New-TimeSpan -Days 365)

# Principal
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Registrar tarea
Register-ScheduledTask -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Principal $Principal `
    -Description "Inicia automáticamente el Sistema de Gestión de Llaves FCEA" `
    -Force | Out-Null

Write-Host "Tarea creada exitosamente" -ForegroundColor Green
Write-Host ""
Write-Host "El sistema se iniciara automaticamente al arrancar Windows" -ForegroundColor Green
