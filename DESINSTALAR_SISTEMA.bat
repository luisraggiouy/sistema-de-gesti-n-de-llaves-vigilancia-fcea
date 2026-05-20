@echo off
title Desinstalador - Sistema de Llaves FCEA
color 4F

echo.
echo ====================================================================
echo   DESINSTALADOR - SISTEMA DE LLAVES FCEA
echo ====================================================================
echo.
echo  Este script eliminara COMPLETAMENTE el sistema del equipo.
echo  Incluye: archivos, base de datos, tareas programadas y registro.
echo.
echo  IMPORTANTE: Ejecutar como ADMINISTRADOR
echo.
echo ====================================================================
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo  ERROR: Se requieren permisos de Administrador.
    echo.
    echo  Por favor:
    echo    1. Cierre esta ventana
    echo    2. Haga clic derecho en DESINSTALAR_SISTEMA.bat
    echo    3. Seleccione "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0scripts\respaldo_recuperacion\lib\DESINSTALAR_SISTEMA_LIMPIO.ps1"

pause
