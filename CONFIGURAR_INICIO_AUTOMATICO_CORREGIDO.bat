@echo off
REM ============================================================================
REM Configurar Inicio Automático - VERSIÓN CORREGIDA
REM Sistema de Gestión de Llaves FCEA
REM ============================================================================
REM Este script configura el inicio automático del sistema con los puertos
REM correctos (PocketBase en 8090, Frontend en 8080)
REM ============================================================================

echo.
echo ========================================
echo CONFIGURACION DE INICIO AUTOMATICO
echo Version Corregida con Puertos Correctos
echo ========================================
echo.
echo Este script configurara el sistema para que se inicie
echo automaticamente al encender Windows.
echo.
echo IMPORTANTE: Requiere permisos de administrador
echo.
pause

REM Ejecutar el script de PowerShell como administrador
powershell.exe -ExecutionPolicy Bypass -File "%~dp0scripts\crear_tarea_inicio_CORREGIDA.ps1"

echo.
echo Presione cualquier tecla para salir...
pause >nul
