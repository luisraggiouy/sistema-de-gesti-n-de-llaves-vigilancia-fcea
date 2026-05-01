@echo off
REM ============================================================================
REM ACTIVAR WATCHDOG - VERSION DEFINITIVA CON SCHTASKS
REM ============================================================================
REM Usa el comando nativo de Windows (schtasks.exe) en lugar de PowerShell
REM ============================================================================

title Activar Watchdog - Sistema Llaves FCEA
color 0A

echo.
echo ============================================================================
echo          ACTIVANDO WATCHDOG - SISTEMA DE LLAVES FCEA
echo ============================================================================
echo.

REM Verificar permisos de administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Este script requiere permisos de administrador
    echo.
    echo Por favor:
    echo  1. Cierre esta ventana
    echo  2. Haga clic derecho en ACTIVAR_WATCHDOG_DEFINITIVO.bat
    echo  3. Seleccione "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

echo [1/3] Eliminando tarea existente (si existe)...
schtasks /Delete /TN "Watchdog_PocketBase_FCEA" /F >nul 2>&1
echo   OK
echo.

echo [2/3] Creando tarea programada...
echo.

REM Crear la tarea con schtasks (comando nativo de Windows)
schtasks /Create /TN "Watchdog_PocketBase_FCEA" /TR "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -Command \"$pb='C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase'; if (Test-Path $pb\pocketbase.exe) { if (-not (Get-Process pocketbase -EA SilentlyContinue)) { cd $pb; Start-Process .\pocketbase.exe -ArgumentList 'serve' -WindowStyle Hidden } }\"" /SC MINUTE /MO 2 /RU SYSTEM /RL HIGHEST /F

if %ERRORLEVEL% equ 0 (
    echo   OK Tarea creada exitosamente
    echo.
    
    echo [3/3] Verificando...
    echo.
    schtasks /Query /TN "Watchdog_PocketBase_FCEA" /FO LIST
    echo.
    
    echo ============================================================================
    echo  WATCHDOG ACTIVADO EXITOSAMENTE
    echo ============================================================================
    echo.
    echo  El watchdog ahora:
    echo   - Monitorea PocketBase cada 2 minutos
    echo   - Lo reinicia automaticamente si esta caido
    echo   - Funciona 24/7 en segundo plano
    echo.
    echo  NUNCA mas tendras problemas con PocketBase caido.
    echo.
) else (
    echo.
    echo ============================================================================
    echo  ERROR AL CREAR LA TAREA
    echo ============================================================================
    echo.
    echo  Codigo de error: %ERRORLEVEL%
    echo.
)

pause
