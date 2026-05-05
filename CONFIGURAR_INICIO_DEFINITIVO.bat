@echo off
echo ========================================
echo CONFIGURACION DE INICIO AUTOMATICO
echo Sistema de Gestion de Llaves FCEA
echo ========================================
echo.
echo Seleccione el metodo de configuracion:
echo.
echo 1. METODO SIMPLE (Recomendado para usuarios)
echo    - No requiere permisos de administrador
echo    - Se inicia cuando TU usuario inicia sesion
echo    - Mas facil de configurar
echo.
echo 2. METODO AVANZADO (Recomendado para produccion)
echo    - Requiere permisos de administrador
echo    - Se inicia automaticamente al arrancar Windows
echo    - Incluye watchdog y reintentos automaticos
echo.
echo 3. Cancelar
echo.
set /p opcion="Ingrese su opcion (1, 2 o 3): "

if "%opcion%"=="1" goto metodo_simple
if "%opcion%"=="2" goto metodo_avanzado
if "%opcion%"=="3" goto cancelar
echo Opcion invalida
pause
exit /b 1

:metodo_simple
echo.
echo ========================================
echo CONFIGURANDO METODO SIMPLE
echo ========================================
echo.

cd /d "%~dp0"

:: Agregar al registro de inicio de Windows (no requiere admin)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SistemaLlavesFCEA" /t REG_SZ /d "\"%~dp0INICIAR_SISTEMA_AHORA.bat\"" /f

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo CONFIGURACION EXITOSA
    echo ========================================
    echo.
    echo El sistema se iniciara automaticamente cuando inicies sesion
    echo.
    echo NOTA: El sistema se iniciara cuando TU USUARIO inicie sesion
    echo.
) else (
    echo.
    echo ========================================
    echo ERROR EN LA CONFIGURACION
    echo ========================================
    echo.
)
goto fin

:metodo_avanzado
echo.
echo ========================================
echo CONFIGURANDO METODO AVANZADO
echo ========================================
echo.
echo IMPORTANTE: Este metodo requiere permisos de ADMINISTRADOR
echo.
pause

cd /d "%~dp0"

powershell -ExecutionPolicy Bypass -File "scripts\crear_tarea_inicio_mejorado.ps1"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo CONFIGURACION EXITOSA
    echo ========================================
    echo.
    echo El sistema se iniciara automaticamente al arrancar Windows
    echo Incluye watchdog para monitoreo y reintentos automaticos
    echo.
) else (
    echo.
    echo ========================================
    echo ERROR EN LA CONFIGURACION
    echo ========================================
    echo.
    echo Por favor, ejecute este archivo como ADMINISTRADOR
    echo Click derecho -^> Ejecutar como administrador
    echo.
)
goto fin

:cancelar
echo.
echo Configuracion cancelada
goto fin

:fin
echo.
echo Presione cualquier tecla para continuar...
pause >nul
