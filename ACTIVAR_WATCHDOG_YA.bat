@echo off
REM ============================================================================
REM ACTIVAR WATCHDOG - VERSION FINAL QUE SI FUNCIONA
REM ============================================================================
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

echo [1/2] Creando tarea programada...
echo.

REM Crear la tarea (comando corto que ejecuta watchdog_simple.ps1)
schtasks /Create /TN "Watchdog_PocketBase_FCEA" /TR "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\watchdog_simple.ps1" /SC MINUTE /MO 2 /RU SYSTEM /RL HIGHEST /F

if %ERRORLEVEL% equ 0 (
    echo   OK Tarea creada exitosamente
    echo.
    
    echo [2/2] Verificando...
    echo.
    schtasks /Query /TN "Watchdog_PocketBase_FCEA"
    echo.
    
    echo ============================================================================
    echo  WATCHDOG ACTIVADO EXITOSAMENTE
    echo ============================================================================
    echo.
    echo  El watchdog ahora monitorea PocketBase cada 2 minutos.
    echo  Si PocketBase se cae, lo reinicia automaticamente.
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
