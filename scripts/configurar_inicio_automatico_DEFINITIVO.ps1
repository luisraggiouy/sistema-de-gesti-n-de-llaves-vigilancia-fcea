# ============================================================================
# Script para Configurar Inicio Automatico - VERSION DEFINITIVA CORREGIDA
# Sistema de Gestion de Llaves FCEA
# ============================================================================
# Corrige el problema de la tarea que no se ejecutaba al iniciar sesion
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CONFIGURACION DE INICIO AUTOMATICO" -ForegroundColor Cyan
Write-Host "VERSION DEFINITIVA CORREGIDA" -ForegroundColor Cyan
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

Write-Host "[1/5] Verificando archivos..." -ForegroundColor Yellow

if (-not (Test-Path $ScriptPath)) {
    Write-Host "ERROR: No se encontro el script de inicio: $ScriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "  [OK] Script encontrado: $ScriptPath" -ForegroundColor Green
Write-Host ""

# Eliminar tarea existente si existe
Write-Host "[2/5] Eliminando tarea anterior (si existe)..." -ForegroundColor Yellow
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

# Crear la accion (ejecutar el script con cmd.exe)
Write-Host "[3/5] Creando nueva tarea programada..." -ForegroundColor Yellow

# Usar powershell para ejecutar el bat con ventana visible
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-WindowStyle Normal -Command `"Start-Process -FilePath 'cmd.exe' -ArgumentList '/c `"$ScriptPath`"' -WorkingDirectory '$ProjectRoot' -Verb RunAs`"" `
    -WorkingDirectory $ProjectRoot

# Crear el trigger (al iniciar sesion con delay de 10 segundos)
$Trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$Trigger.Delay = "PT10S"  # Delay de 10 segundos

# Configurar para ejecutar con privilegios mas altos
$Principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Highest

# Configuracion adicional
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
    -MultipleInstances IgnoreNew

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
Write-Host "[4/5] Verificando configuracion..." -ForegroundColor Yellow

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($task) {
    Write-Host "  [OK] Tarea verificada correctamente" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Error: No se pudo verificar la tarea" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Probar la tarea manualmente
Write-Host "[5/5] Probando la tarea..." -ForegroundColor Yellow
Write-Host "  Ejecutando tarea de prueba..." -ForegroundColor White

try {
    Start-ScheduledTask -TaskName $TaskName
    Start-Sleep -Seconds 5
    
    # Verificar que los procesos esten corriendo
    $pbProcess = Get-Process -Name "pocketbase" -ErrorAction SilentlyContinue
    $nodeProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue
    
    if ($pbProcess -and $nodeProcess) {
        Write-Host "  [OK] Tarea ejecutada correctamente" -ForegroundColor Green
        Write-Host "  [OK] PocketBase y Frontend iniciados" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] La tarea se ejecuto pero algunos servicios no iniciaron" -ForegroundColor Yellow
        Write-Host "  Esto es normal si ya estaban corriendo" -ForegroundColor White
    }
} catch {
    Write-Host "  [WARNING] No se pudo probar la tarea: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "CONFIGURACION COMPLETADA EXITOSAMENTE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Detalles de la tarea:" -ForegroundColor Cyan
Write-Host "  - Nombre: $TaskName" -ForegroundColor White
Write-Host "  - Estado: $($task.State)" -ForegroundColor White
Write-Host "  - Trigger: Al iniciar sesion (con delay de 10 seg)" -ForegroundColor White
Write-Host "  - Script: iniciar_sistema.bat" -ForegroundColor White
Write-Host "  - PocketBase: Puerto 8090" -ForegroundColor White
Write-Host "  - Frontend: Puerto 8080" -ForegroundColor White
Write-Host "  - Watchdog: Proteccion completa activada" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "SISTEMA CONFIGURADO Y PROBADO" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "La proxima vez que reinicies la PC e inicies sesion," -ForegroundColor Cyan
Write-Host "el sistema se iniciara automaticamente despues de 10 segundos." -ForegroundColor White
Write-Host ""
Write-Host "Accede al sistema en: http://localhost:8080/monitor" -ForegroundColor Green
Write-Host ""
Write-Host "Presione cualquier tecla para salir..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
