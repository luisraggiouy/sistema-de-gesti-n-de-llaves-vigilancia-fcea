@echo off
REM ============================================================================
REM Activar Watchdog - Sistema de Llaves FCEA
REM ============================================================================
REM Este script activa el watchdog para que PocketBase NUNCA se caiga
REM ============================================================================

title Activar Watchdog - Sistema Llaves FCEA
color 0A

echo.
echo ============================================================================
echo.
echo          ACTIVAR WATCHDOG - SISTEMA DE LLAVES FCEA
echo.
echo ============================================================================
echo.
echo  Este script activara el watchdog que:
echo.
echo   [*] Monitorea PocketBase cada 2 minutos
echo   [*] Lo reinicia automaticamente si se cae
echo   [*] Garantiza disponibilidad 24/7
echo   [*] Funciona en desarrollo Y produccion
echo.
echo  Duracion: 1-2 minutos
echo.
echo ============================================================================
echo.
echo  IMPORTANTE: Este script requiere permisos de ADMINISTRADOR
echo.
echo ============================================================================
echo.
pause

REM Verificar si se está ejecutando como administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ============================================================================
    echo  ERROR: Este script requiere permisos de administrador
    echo ============================================================================
    echo.
    echo  Por favor:
    echo   1. Cierre esta ventana
    echo   2. Haga clic derecho en ACTIVAR_WATCHDOG.bat
    echo   3. Seleccione "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

REM Ejecutar el configurador
echo.
echo Activando watchdog...
echo.

cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0scripts\configurar_mantenimiento_automatico.ps1"

if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================================================
    echo  Watchdog activado exitosamente
    echo ============================================================================
    echo.
    echo  El watchdog ahora:
    echo   - Se ejecuta cada 2 minutos automaticamente
    echo   - Reinicia PocketBase si se cae
    echo   - Funciona 24/7 en segundo plano
    echo.
    echo  NUNCA mas tendras que iniciar PocketBase manualmente.
    echo.
) else (
    echo.
    echo ============================================================================
    echo  Hubo un error al activar el watchdog
    echo ============================================================================
    echo.
)

pause
