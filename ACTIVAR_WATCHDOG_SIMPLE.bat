@echo off
REM Activar Watchdog Simple - Sin dependencias
title Activar Watchdog
color 0A

echo.
echo ============================================================================
echo          ACTIVANDO WATCHDOG - SISTEMA DE LLAVES FCEA
echo ============================================================================
echo.

REM Verificar permisos de administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Requiere permisos de administrador
    echo.
    echo Haga clic derecho en este archivo y seleccione "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

echo [1/3] Creando tarea de watchdog...
echo.

REM Crear la tarea del watchdog directamente
powershell.exe -ExecutionPolicy Bypass -Command "$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -WindowStyle Hidden -Command \"cd C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase; if (-not (Get-Process pocketbase -ErrorAction SilentlyContinue)) { Start-Process -FilePath .\pocketbase.exe -ArgumentList serve -WindowStyle Hidden }\"'; $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2) -RepetitionDuration ([TimeSpan]::MaxValue); $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest; $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable; $task = Get-ScheduledTask -TaskName 'Watchdog PocketBase Sistema Llaves FCEA' -ErrorAction SilentlyContinue; if ($task) { Unregister-ScheduledTask -TaskName 'Watchdog PocketBase Sistema Llaves FCEA' -Confirm:$false }; Register-ScheduledTask -TaskName 'Watchdog PocketBase Sistema Llaves FCEA' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Monitorea y reinicia PocketBase cada 2 minutos' | Out-Null; Write-Host '  OK Tarea creada exitosamente' -ForegroundColor Green"

if %ERRORLEVEL% equ 0 (
    echo.
    echo [2/3] Iniciando la tarea por primera vez...
    powershell.exe -Command "Start-ScheduledTask -TaskName 'Watchdog PocketBase Sistema Llaves FCEA'"
    
    echo.
    echo [3/3] Verificando...
    powershell.exe -Command "Get-ScheduledTask -TaskName 'Watchdog PocketBase Sistema Llaves FCEA' | Select-Object TaskName, State"
    
    echo.
    echo ============================================================================
    echo  WATCHDOG ACTIVADO EXITOSAMENTE
    echo ============================================================================
    echo.
    echo  El watchdog ahora:
    echo   - Se ejecuta cada 2 minutos automaticamente
    echo   - Reinicia PocketBase si se cae
    echo   - Funciona 24/7 en segundo plano
    echo.
    echo  NUNCA mas tendras problemas con PocketBase.
    echo.
) else (
    echo.
    echo ============================================================================
    echo  ERROR AL CREAR LA TAREA
    echo ============================================================================
    echo.
)

pause
