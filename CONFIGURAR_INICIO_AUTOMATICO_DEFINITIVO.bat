@echo off
echo ========================================
echo CONFIGURACION DE INICIO AUTOMATICO
echo Sistema de Gestion de Llaves FCEA
echo ========================================
echo.
echo IMPORTANTE: Este script debe ejecutarse como ADMINISTRADOR
echo.
pause

cd /d "%~dp0"

echo Configurando inicio automatico...
echo.

powershell -ExecutionPolicy Bypass -File "scripts\crear_tarea_inicio_CORREGIDA.ps1"

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo CONFIGURACION EXITOSA
    echo ========================================
    echo.
    echo El sistema se iniciara automaticamente al encender la PC
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

pause
