@echo off
REM ============================================================================
REM ACTIVAR WATCHDOG COMPLETO - Protege PocketBase Y Frontend
REM Sistema de Gestión de Llaves FCEA
REM ============================================================================
REM Este script activa el watchdog que monitorea AMBOS procesos críticos
REM ============================================================================

echo.
echo ========================================
echo   WATCHDOG COMPLETO - FCEA
echo   Protege: PocketBase + Frontend
echo ========================================
echo.

REM Matar watchdog anterior si existe
echo [1/3] Deteniendo watchdog anterior...
taskkill /F /FI "WINDOWTITLE eq WATCHDOG*" >nul 2>&1
timeout /t 2 /nobreak >nul

REM Iniciar watchdog completo en ventana oculta
echo [2/3] Iniciando watchdog completo...
start "WATCHDOG-COMPLETO-FCEA" /MIN powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0scripts\watchdog_completo.ps1"

REM Esperar y verificar
timeout /t 3 /nobreak >nul

echo [3/3] Verificando...
tasklist /FI "WINDOWTITLE eq WATCHDOG*" | find /I "powershell" >nul
if %ERRORLEVEL% EQU 0 (
    echo.
    echo [OK] Watchdog completo activado correctamente
    echo.
    echo Monitoreando:
    echo   - PocketBase ^(backend^)
    echo   - Frontend Vite ^(puerto 8080^)
    echo.
    echo Verificacion cada 2 minutos
    echo Log: scripts\watchdog_completo.log
    echo.
) else (
    echo.
    echo [ERROR] No se pudo activar el watchdog
    echo Intente ejecutar como Administrador
    echo.
    pause
    exit /b 1
)

echo Presione cualquier tecla para cerrar...
pause >nul
