# ============================================================================
# CONFIGURADOR DE INICIO AUTOMÁTICO
# Sistema de Gestión de Llaves FCEA
# ============================================================================
# Este script configura el sistema para que se inicie AUTOMÁTICAMENTE
# al arrancar Windows, sin intervención manual
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "CONFIGURANDO INICIO AUTOMÁTICO DEL SISTEMA" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: Este script requiere permisos de administrador." -ForegroundColor Red
    Write-Host "Por favor, ejecute PowerShell como Administrador y vuelva a intentar." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presione cualquier tecla para salir..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Configuración
$TaskName = "SistemaLlavesFCEA_AutoInicio"
$ProjectRoot = "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
$ScriptPath = Join-Path $ProjectRoot "iniciar_sistema.bat"
$WatchdogScript = Join-Path $ProjectRoot "scripts\watchdog_completo.ps1"

Write-Host "[1/4] Eliminando tarea anterior si existe..." -ForegroundColor Yellow
try {
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "  ✓ Tarea anterior eliminada" -ForegroundColor Green
    } else {
        Write-Host "  ✓ No hay tarea anterior" -ForegroundColor Green
    }
} catch {
    Write-Host "  ✓ No hay tarea anterior" -ForegroundColor Green
}

Write-Host ""
Write-Host "[2/4] Creando nueva tarea programada..." -ForegroundColor Yellow

# Crear acción: ejecutar el watchdog directamente
$Action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$WatchdogScript`""

# Crear trigger: al inicio del sistema con retraso de 30 segundos
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Trigger.Delay = "PT30S"  # 30 segundos de retraso

# Configuración de la tarea
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit (New-TimeSpan -Days 365)

# Crear principal (ejecutar con máximos privilegios)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Registrar la tarea
try {
    Register-ScheduledTask -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Settings $Settings `
        -Principal $Principal `
        -Description "Inicia automáticamente el Sistema de Gestión de Llaves FCEA al arrancar Windows. Incluye watchdog para reinicio automático." `
        -Force | Out-Null
    
    Write-Host "  ✓ Tarea programada creada exitosamente" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Error al crear la tarea: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/4] Configurando opciones adicionales..." -ForegroundColor Yellow

# Configurar para que se ejecute incluso si el usuario no está conectado
try {
    $task = Get-ScheduledTask -TaskName $TaskName
    $task.Settings.MultipleInstances = "IgnoreNew"  # No iniciar múltiples instancias
    $task | Set-ScheduledTask | Out-Null
    Write-Host "  ✓ Opciones configuradas" -ForegroundColor Green
} catch {
    Write-Host "  ! Advertencia: No se pudieron configurar todas las opciones" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[4/4] Verificando configuración..." -ForegroundColor Yellow

$verifyTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($verifyTask) {
    Write-Host "  ✓ Tarea verificada correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "INICIO AUTOMÁTICO CONFIGURADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "DETALLES DE LA CONFIGURACIÓN:" -ForegroundColor Cyan
    Write-Host "  • Nombre de tarea: $TaskName" -ForegroundColor White
    Write-Host "  • Se ejecuta: Al iniciar Windows" -ForegroundColor White
    Write-Host "  • Retraso: 30 segundos" -ForegroundColor White
    Write-Host "  • Usuario: SYSTEM (máximos privilegios)" -ForegroundColor White
    Write-Host "  • Reintentos: 3 veces si falla" -ForegroundColor White
    Write-Host "  • Watchdog: Activo (reinicio automático)" -ForegroundColor White
    Write-Host ""
    Write-Host "IMPORTANTE:" -ForegroundColor Yellow
    Write-Host "  ✓ El sistema se iniciará AUTOMÁTICAMENTE al arrancar Windows" -ForegroundColor Green
    Write-Host "  ✓ Si se cae, se reiniciará AUTOMÁTICAMENTE cada 2 minutos" -ForegroundColor Green
    Write-Host "  ✓ NO requiere intervención manual" -ForegroundColor Green
    Write-Host ""
    Write-Host "Para verificar el estado de la tarea:" -ForegroundColor Cyan
    Write-Host "  Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host ""
    Write-Host "Para iniciar la tarea manualmente ahora:" -ForegroundColor Cyan
    Write-Host "  Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "  ✗ Error: No se pudo verificar la tarea" -ForegroundColor Red
    exit 1
}

Write-Host "Presione cualquier tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
