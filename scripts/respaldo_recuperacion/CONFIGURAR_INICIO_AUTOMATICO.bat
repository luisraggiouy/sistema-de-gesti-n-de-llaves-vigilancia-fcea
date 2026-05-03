@echo off
REM ============================================================================
REM CONFIGURADOR DE INICIO AUTOMÁTICO - Sistema de Llaves FCEA
REM ============================================================================
REM Este script configura el sistema para iniciarse automáticamente al arrancar
REM Windows, sin intervención manual. REQUIERE PERMISOS DE ADMINISTRADOR.
REM ============================================================================

echo.
echo ============================================
echo CONFIGURADOR DE INICIO AUTOMATICO
echo Sistema de Gestion de Llaves FCEA
echo ============================================
echo.
echo Este script configurara el sistema para que se inicie
echo AUTOMATICAMENTE al arrancar Windows.
echo.
echo IMPORTANTE: Requiere permisos de administrador.
echo.
echo Presione cualquier tecla para continuar...
pause > nul

REM Verificar permisos de administrador
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo.
    echo ERROR: Este script requiere permisos de administrador.
    echo.
    echo Por favor:
    echo 1. Haga clic derecho en este archivo
    echo 2. Seleccione "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

echo.
echo Ejecutando configuracion...
echo.

REM Ejecutar el script de PowerShell con permisos de administrador
powershell.exe -ExecutionPolicy Bypass -File "%~dp0scripts\crear_tarea_inicio.ps1"

if %errorLevel% EQU 0 (
    echo.
    echo ============================================
    echo CONFIGURACION COMPLETADA EXITOSAMENTE
    echo ============================================
    echo.
) else (
    echo.
    echo ============================================
    echo ERROR EN LA CONFIGURACION
    echo ============================================
    echo.
    echo Por favor revise los mensajes de error anteriores.
    echo.
)

echo Presione cualquier tecla para salir...
pause > nul
