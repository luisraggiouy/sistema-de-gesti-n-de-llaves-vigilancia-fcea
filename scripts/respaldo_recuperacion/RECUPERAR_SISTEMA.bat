@echo off
REM ============================================================================
REM Recuperador Automático - Sistema de Gestión de Llaves FCEA
REM ============================================================================
REM Este script recupera el sistema desde un respaldo
REM ============================================================================

title Recuperador Sistema Llaves FCEA
color 0E

echo.
echo ============================================================================
echo.
echo          RECUPERADOR AUTOMATICO - SISTEMA DE LLAVES FCEA
echo.
echo ============================================================================
echo.
echo  Este recuperador restaurara el sistema desde un respaldo:
echo.
echo   [*] Detener sistema actual
echo   [*] Crear respaldo de seguridad del estado actual
echo   [*] Restaurar base de datos desde respaldo
echo   [*] Restaurar archivos del sistema
echo   [*] Verificar integridad
echo   [*] Reiniciar sistema
echo.
echo  Duracion estimada: 5-10 minutos
echo.
echo ============================================================================
echo.
echo  IMPORTANTE: Este script debe ejecutarse como ADMINISTRADOR
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
    echo   2. Haga clic derecho en RECUPERAR_SISTEMA.bat
    echo   3. Seleccione "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

REM Ejecutar el recuperador PowerShell
echo.
echo Iniciando recuperador automatico...
echo.

cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0recuperar_automatico.ps1"

if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================================================
    echo  Recuperacion completada exitosamente
    echo ============================================================================
    echo.
) else (
    echo.
    echo ============================================================================
    echo  Hubo un error durante la recuperacion
    echo ============================================================================
    echo.
    echo  Consulte el log en: %TEMP%\recuperacion_llaves_fcea.log
    echo.
)

pause
