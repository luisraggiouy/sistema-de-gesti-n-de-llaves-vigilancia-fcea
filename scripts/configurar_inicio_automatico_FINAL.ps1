# ============================================================================
# Script para Configurar Inicio Automatico - VERSION FINAL
# Sistema de Gestion de Llaves FCEA
# ============================================================================
# Este script crea una tarea programada que inicia el sistema automaticamente
# al arrancar Windows, usando iniciar_sistema.bat con puertos correctos
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CONFIGURACION DE INICIO AUTOMATICO" -ForegroundColor Cyan
Write-Host "Sistema de Gestion de Llaves FCEA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: Este script requiere permisos de administrador." -ForegroundColor Red
    Write-Host "Por favor, ejecute como administrador." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presione cualquier tecla para salir..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Configuracion
$TaskName = "SistemaLlavesFCEA"
$ProjectRoot = "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
$ScriptPath = Join-Path $ProjectRoot "iniciar_sistema.bat"

Write-Host "[1/4] Verificando archivos..." -ForegroundColor Yellow

if (-not (Test-Path $ScriptPath)) {
    Write-Host "ERROR: No se encontro el script de inicio: $ScriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "  [OK] Script encontrado: $ScriptPath" -ForegroundColor Green
Write-Host ""

# Eliminar tarea existente si existe
Write-Host "[2/4] Eliminando tarea anterior (si existe)..." -ForegroundColor Yellow
try {
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "  [OK] Tarea anterior eliminada" -ForegroundColor Green
    } else {
        Write-Host "  [OK] No hay tarea anterior" -ForegroundColor Green
    }
} catch {
    Write-Host "  [OK] No hay tarea anterior" -ForegroundColor Green
}
Write-Host ""

# Crear la accion (ejecutar el script)
Write-Host "[3/4] Creando nueva tarea programada..." -ForegroundColor Yellow

$Action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$ScriptPath`"" -WorkingDirectory $ProjectRoot

# Crear el trigger (al iniciar sesion)
$Trigger = New-ScheduledTaskTrigger -AtLogOn

# Configurar para ejecutar con privilegios mas altos
$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest

# Configuracion adicional
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit (New-TimeSpan -Hours 0)

# Registrar la tarea
try {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Principal $Principal `
        -Settings $Settings `
        -Description "Inicia automaticamente el Sistema de Gestion de Llaves FCEA al iniciar sesion en Windows. Incluye PocketBase (puerto 8090), Frontend (puerto 8080) y Watchdog de proteccion completo." `
        -Force | Out-Null
    
    Write-Host "  [OK] Tarea creada exitosamente" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Error al crear la tarea: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Verificar que la tarea se creo correctamente
Write-Host "[4/4] Verificando configuracion..." -ForegroundColor Yellow

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($task) {
    Write-Host "  [OK] Tarea verificada correctamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "CONFIGURACION COMPLETADA EXITOSAMENTE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Detalles de la tarea:" -ForegroundColor Cyan
    Write-Host "  - Nombre: $TaskName" -ForegroundColor White
    Write-Host "  - Estado: $($task.State)" -ForegroundColor White
    Write-Host "  - Trigger: Al iniciar sesion en Windows" -ForegroundColor White
    Write-Host "  - Script: iniciar_sistema.bat" -ForegroundColor White
    Write-Host "  - PocketBase: Puerto 8090" -ForegroundColor White
    Write-Host "  - Frontend: Puerto 8080" -ForegroundColor White
    Write-Host "  - Watchdog: Proteccion completa activada" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "EL SISTEMA SE INICIARA AUTOMATICAMENTE" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Desde ahora, cada vez que:" -ForegroundColor Cyan
    Write-Host "  1. Enciendas la computadora" -ForegroundColor White
    Write-Host "  2. Inicies sesion en Windows" -ForegroundColor White
    Write-Host ""
    Write-Host "El sistema se iniciara automaticamente sin necesidad de" -ForegroundColor White
    Write-Host "hacer nada mas. Solo abre el navegador en:" -ForegroundColor White
    Write-Host "  http://localhost:8080/monitor" -ForegroundColor Green
    Write-Host ""
    Write-Host "Presione cualquier tecla para salir..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
} else {
    Write-Host "  [ERROR] Error: No se pudo verificar la tarea" -ForegroundColor Red
    exit 1
}
