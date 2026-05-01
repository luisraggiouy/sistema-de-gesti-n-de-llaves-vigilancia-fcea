# ============================================================================
# ACTIVAR WATCHDOG - VERSION FINAL ULTRA-SIMPLE
# ============================================================================
# Este script crea una tarea que reinicia PocketBase cada 2 minutos si está caído
# ============================================================================

# Auto-elevarse a administrador
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Solicitando permisos de administrador..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  ACTIVANDO WATCHDOG - SISTEMA DE LLAVES FCEA" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"

try {
    Write-Host "[1/4] Creando script de watchdog inline..." -ForegroundColor Yellow
    
    # Crear el comando que se ejecutará cada 2 minutos
    $watchdogCommand = @'
$pocketbasePath = "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase"
$pocketbaseExe = Join-Path $pocketbasePath "pocketbase.exe"

if (-not (Test-Path $pocketbaseExe)) {
    exit 1
}

$process = Get-Process -Name "pocketbase" -ErrorAction SilentlyContinue

if (-not $process) {
    Set-Location $pocketbasePath
    Start-Process -FilePath $pocketbaseExe -ArgumentList "serve" -WindowStyle Hidden -WorkingDirectory $pocketbasePath
}
'@
    
    Write-Host "  OK Script creado" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "[2/4] Configurando tarea programada..." -ForegroundColor Yellow
    
    # Crear la acción (ejecutar el comando PowerShell)
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -Command `"$watchdogCommand`""
    
    # Crear el trigger (cada 2 minutos, para siempre)
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2) -RepetitionDuration ([TimeSpan]::MaxValue)
    
    # Crear el principal (ejecutar como SYSTEM)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Crear la configuración
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
    
    Write-Host "  OK Configuración lista" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "[3/4] Registrando tarea..." -ForegroundColor Yellow
    
    # Eliminar tarea existente si existe
    $taskName = "Watchdog_PocketBase_FCEA"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "  Eliminando tarea existente..." -ForegroundColor Gray
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    # Registrar la tarea
    $task = Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Monitorea y reinicia PocketBase cada 2 minutos si está caído"
    
    Write-Host "  OK Tarea registrada: $taskName" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "[4/4] Iniciando tarea..." -ForegroundColor Yellow
    Start-ScheduledTask -TaskName $taskName
    Start-Sleep -Seconds 2
    
    # Verificar
    $verifyTask = Get-ScheduledTask -TaskName $taskName
    Write-Host "  Nombre: $($verifyTask.TaskName)" -ForegroundColor White
    Write-Host "  Estado: $($verifyTask.State)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host "  WATCHDOG ACTIVADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "El watchdog ahora:" -ForegroundColor Cyan
    Write-Host "  - Monitorea PocketBase cada 2 minutos" -ForegroundColor White
    Write-Host "  - Lo reinicia automaticamente si esta caido" -ForegroundColor White
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
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Detalles tecnicos:" -ForegroundColor Yellow
    Write-Host $_.Exception | Format-List -Force
    Write-Host ""
}

Write-Host ""
Read-Host "Presione Enter para salir"
