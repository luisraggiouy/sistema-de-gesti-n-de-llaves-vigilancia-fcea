# ============================================================================
# Script para Crear Tarea de Inicio Automatico - VERSION CORREGIDA
# Sistema de Gestion de Llaves FCEA
# ============================================================================
# Este script crea una tarea programada que inicia el sistema automaticamente
# al arrancar Windows, con los puertos correctos (PocketBase en 8090)
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
$ScriptPath = Join-Path $ProjectRoot "REPARAR_SISTEMA_URGENTE.bat"

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
        -Description "Inicia automaticamente el Sistema de Gestion de Llaves FCEA al iniciar sesion en Windows. Incluye PocketBase (puerto 8090), Frontend (puerto 8080) y Watchdog de proteccion." `
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
    Write-Host "CONFIGURACION COMPLETADA" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Detalles de la tarea:" -ForegroundColor Cyan
    Write-Host "  - Nombre: $TaskName" -ForegroundColor White
    Write-Host "  - Estado: $($task.State)" -ForegroundColor White
    Write-Host "  - Trigger: Al iniciar sesion" -ForegroundColor White
    Write-Host "  - Script: REPARAR_SISTEMA_URGENTE.bat" -ForegroundColor White
    Write-Host "  - Puertos: PocketBase (8090), Frontend (8080)" -ForegroundColor White
    Write-Host ""
    Write-Host "El sistema se iniciara automaticamente cuando:" -ForegroundColor Yellow
    Write-Host "  1. Enciendas la computadora" -ForegroundColor White
    Write-Host "  2. Inicies sesion en Windows" -ForegroundColor White
    Write-Host ""
    Write-Host "Deseas iniciar el sistema AHORA? (S/N): " -ForegroundColor Cyan -NoNewline
    $respuesta = Read-Host
    
    if ($respuesta -eq "S" -or $respuesta -eq "s") {
        Write-Host ""
        Write-Host "Iniciando sistema..." -ForegroundColor Yellow
        Start-Process -FilePath $ScriptPath -WorkingDirectory $ProjectRoot
        Start-Sleep -Seconds 3
        Write-Host "  [OK] Sistema iniciado" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Presione cualquier tecla para salir..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
} else {
    Write-Host "  [ERROR] Error: No se pudo verificar la tarea" -ForegroundColor Red
    exit 1
}
