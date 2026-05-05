@echo off
echo ========================================
echo CONFIGURAR INICIO AUTOMATICO
echo Sistema de Llaves FCEA
echo ========================================
echo.
echo Este script configurara el sistema para que se inicie
echo automaticamente cada vez que enciendas la computadora.
echo.
echo IMPORTANTE: Se requieren permisos de administrador.
echo.
pause

cd /d "%~dp0"

echo.
echo Ejecutando configuracion...
echo.

powershell.exe -ExecutionPolicy Bypass -File "scripts\configurar_inicio_automatico_FINAL.ps1"

echo.
echo Presione cualquier tecla para salir...
pause >nul
