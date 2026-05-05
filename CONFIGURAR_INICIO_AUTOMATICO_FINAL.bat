@echo off
echo ============================================
echo CONFIGURACION DE INICIO AUTOMATICO - FINAL
echo Sistema de Gestion de Llaves FCEA
echo ============================================
echo.
echo Este script corrige el problema de inicio automatico
echo y configura la tarea para que funcione correctamente.
echo.
echo Presione cualquier tecla para continuar...
pause > nul

powershell.exe -ExecutionPolicy Bypass -File "%~dp0scripts\configurar_inicio_automatico_DEFINITIVO.ps1"
