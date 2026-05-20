@echo off
REM ============================================================================
REM Activar Protección Anti-Caídas - Sistema de Llaves FCEA
REM ============================================================================
title Activar Protección
color 0A

echo.
echo ============================================================================
echo       ACTIVAR PROTECCION ANTI-CAIDAS - SISTEMA DE LLAVES FCEA
echo ============================================================================
echo.

REM Verificar permisos de administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Requiere permisos de administrador
    echo.
    echo Por favor:
    echo  1. Cierre esta ventana
    echo  2. Haga clic derecho en ACTIVAR_PROTECCION.bat
    echo  3. Seleccione "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

echo Creando tarea programada del watchdog...
echo.

REM Crear la tarea usando el script watchdog_completo.ps1
powershell.exe -ExecutionPolicy Bypass -Command ^
"$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -WindowStyle Hidden -File C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\scripts\watchdog_completo.ps1'; ^
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2) -RepetitionDuration ([TimeSpan]::MaxValue); ^
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest; ^
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable; ^
$existingTask = Get-ScheduledTask -TaskName 'Watchdog PocketBase FCEA' -ErrorAction SilentlyContinue; ^
if ($existingTask) { Unregister-ScheduledTask -TaskName 'Watchdog PocketBase FCEA' -Confirm:$false }; ^
Register-ScheduledTask -TaskName 'Watchdog PocketBase FCEA' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Monitorea y reinicia PocketBase cada 2 minutos' | Out-Null; ^
Write-Host 'Tarea creada exitosamente' -ForegroundColor Green"

if %ERRORLEVEL% equ 0 (
    echo.
    echo Iniciando la tarea...
    powershell.exe -Command "Start-ScheduledTask -TaskName 'Watchdog PocketBase FCEA'"
    
    echo.
    echo ============================================================================
    echo  PROTECCION ACTIVADA EXITOSAMENTE
    echo ============================================================================
    echo.
    echo  El watchdog ahora:
    echo   - Monitorea PocketBase cada 2 minutos
    echo   - Lo reinicia automaticamente si se cae
    echo   - Funciona 24/7 en segundo plano
    echo.
    echo  Para verificar, abra el Programador de tareas y busque:
    echo  "Watchdog PocketBase FCEA"
    echo.
    echo  NUNCA mas tendras problemas con PocketBase caido.
    echo.
) else (
    echo.
    echo ============================================================================
    echo  ERROR AL CREAR LA TAREA
    echo ============================================================================
    echo.
    echo  Consulte el error arriba.
    echo.
)

pause
