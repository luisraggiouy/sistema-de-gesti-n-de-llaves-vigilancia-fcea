@echo off
REM ========================================
REM CONFIGURACION AUTOMATICA DE INICIO
REM Sistema de Gestion de Llaves FCEA
REM ========================================
REM Este script se ejecuta automaticamente
REM durante la instalacion del sistema
REM ========================================

cd /d "%~dp0..\.."

echo.
echo [PASO 5/5] Configurando inicio automatico...
echo.

REM Usar el metodo simple que SIEMPRE funciona (no requiere admin)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SistemaLlavesFCEA" /t REG_SZ /d "%~dp0..\..\INICIAR_SISTEMA_AHORA.bat" /f >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] Inicio automatico configurado correctamente
    echo.
    echo El sistema se iniciara automaticamente cuando inicies sesion en Windows
) else (
    echo [ADVERTENCIA] No se pudo configurar el inicio automatico
    echo Puedes configurarlo manualmente despues ejecutando:
    echo CONFIGURAR_INICIO_DEFINITIVO.bat
)

echo.
timeout /t 2 /nobreak >nul
