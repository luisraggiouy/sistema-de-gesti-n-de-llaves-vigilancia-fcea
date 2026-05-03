@echo off
REM ============================================================================
REM Instalador Automático - Sistema de Gestión de Llaves FCEA
REM ============================================================================
REM Este script inicia el instalador automático con interfaz gráfica
REM ============================================================================

title Instalador Sistema Llaves FCEA
color 0A

echo.
echo ============================================================================
echo.
echo            INSTALADOR AUTOMATICO - SISTEMA DE LLAVES FCEA
echo.
echo ============================================================================
echo.
echo  Este instalador configurara automaticamente TODO el sistema:
echo.
echo   [*] Instalacion de Node.js
echo   [*] Copia del sistema
echo   [*] Instalacion de dependencias
echo   [*] Configuracion de base de datos
echo   [*] Configuracion de hardware (tactil o tradicional)
echo   [*] Configuracion de modo kiosk (produccion)
echo   [*] Configuracion de mantenimiento automatizado
echo   [*] Configuracion de watchdog anti-caidas
echo   [*] Configuracion de INICIO AUTOMATICO al arrancar Windows
echo   [*] Verificacion final del sistema
echo.
echo  Duracion estimada: 10-15 minutos
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
    echo   2. Haga clic derecho en INSTALAR_SISTEMA.bat
    echo   3. Seleccione "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

REM Ejecutar el instalador PowerShell
echo.
echo Iniciando instalador automatico...
echo.

cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0..\instalar_automatico.ps1"

if %ERRORLEVEL% equ 0 (
    echo.
    echo ============================================================================
    echo  Instalacion completada exitosamente
    echo ============================================================================
    echo.
) else (
    echo.
    echo ============================================================================
    echo  Hubo un error durante la instalacion
    echo ============================================================================
    echo.
    echo  Consulte el log en: %TEMP%\instalacion_llaves_fcea.log
    echo.
)

pause
