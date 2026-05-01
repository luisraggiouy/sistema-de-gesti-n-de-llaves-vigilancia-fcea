@echo off
REM ============================================================================
REM Script para Iniciar PocketBase - Sistema de Gestión de Llaves FCEA
REM ============================================================================
REM Este script inicia PocketBase de forma robusta y verifica que arranque
REM ============================================================================

cd /d "%~dp0..\pocketbase"

echo Iniciando PocketBase...
echo Directorio: %CD%
echo.

REM Verificar que el ejecutable existe
if not exist "pocketbase.exe" (
    echo ERROR: No se encontro pocketbase.exe
    echo Ruta esperada: %CD%\pocketbase.exe
    pause
    exit /b 1
)

REM Iniciar PocketBase
start "PocketBase Server - Sistema Llaves FCEA" /MIN pocketbase.exe serve

echo PocketBase iniciado en segundo plano.
echo Puerto: 8090
echo.
echo Esperando 5 segundos para verificar...
timeout /t 5 /nobreak > nul

REM Verificar que está corriendo
tasklist /FI "IMAGENAME eq pocketbase.exe" | find /i "pocketbase.exe" > nul
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===================================
    echo PocketBase iniciado correctamente
    echo ===================================
    echo.
) else (
    echo.
    echo ===================================
    echo ERROR: PocketBase no pudo iniciarse
    echo ===================================
    echo.
    echo Verifique:
    echo 1. Que el puerto 8090 no este ocupado
    echo 2. Que tenga permisos de administrador
    echo 3. Que el antivirus no este bloqueando
    echo.
)

exit /b 0
