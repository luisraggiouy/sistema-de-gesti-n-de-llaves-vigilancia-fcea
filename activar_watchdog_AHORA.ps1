# ============================================================================
# Activar Watchdog AHORA - Script Directo con Auto-Elevación
# ============================================================================
# Ejecutar como: Doble clic en el archivo
# ============================================================================

# Auto-elevarse a administrador si no lo está
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Solicitando permisos de administrador..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  ACTIVANDO WATCHDOG - SISTEMA DE LLAVES FCEA" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Creando tarea programada del watchdog..." -ForegroundColor Yellow
Write-Host ""

try {
    # Definir la acción
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\scripts\watchdog_completo.ps1"
    
    # Definir el trigger (cada 2 minutos, para siempre)
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2) -RepetitionDuration ([TimeSpan]::MaxValue)
    
    # Definir el principal (ejecutar como SYSTEM)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Definir configuración
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    # Eliminar tarea existente si existe
    $existingTask = Get-ScheduledTask -TaskName "Watchdog_PocketBase_FCEA" -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "  Eliminando tarea existente..." -ForegroundColor Gray
        Unregister-ScheduledTask -TaskName "Watchdog_PocketBase_FCEA" -Confirm:$false
    }
    
    # Crear la tarea
    Register-ScheduledTask -TaskName "Watchdog_PocketBase_FCEA" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Monitorea y reinicia PocketBase cada 2 minutos" -Force | Out-Null
    
    Write-Host "  OK Tarea creada exitosamente" -ForegroundColor Green
    Write-Host ""
    
    # Iniciar la tarea inmediatamente
    Write-Host "[2/3] Iniciando la tarea por primera vez..." -ForegroundColor Yellow
    Start-ScheduledTask -TaskName "Watchdog_PocketBase_FCEA"
    Write-Host "  OK Tarea iniciada" -ForegroundColor Green
    Write-Host ""
    
    # Verificar
    Write-Host "[3/3] Verificando estado..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    $task = Get-ScheduledTask -TaskName "Watchdog_PocketBase_FCEA"
    Write-Host "  Nombre: $($task.TaskName)" -ForegroundColor White
    Write-Host "  Estado: $($task.State)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host "  WATCHDOG ACTIVADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "El watchdog ahora:" -ForegroundColor Cyan
    Write-Host "  - Monitorea PocketBase cada 2 minutos" -ForegroundColor White
    Write-Host "  - Lo reinicia automaticamente si se cae" -ForegroundColor White
    Write-Host "  - Funciona 24/7 en segundo plano" -ForegroundColor White
    Write-Host ""
    Write-Host "NUNCA mas tendras problemas con PocketBase caido." -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor Red
    Write-Host "  ERROR AL CREAR LA TAREA" -ForegroundColor Red
    Write-Host "============================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
}

Write-Host ""
Read-Host "Presione Enter para salir"
