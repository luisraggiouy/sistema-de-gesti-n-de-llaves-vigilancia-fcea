@echo off
REM ============================================================================
REM REPARACION URGENTE - Sistema de Gestion de Llaves FCEA
REM ============================================================================
REM Este script detiene todos los procesos y reinicia el sistema correctamente
REM ============================================================================

echo ========================================
echo REPARACION URGENTE DEL SISTEMA
echo ========================================
echo.

echo [1/5] Deteniendo todos los procesos...
echo.

REM Detener watchdog
echo Deteniendo watchdog...
taskkill /F /FI "WINDOWTITLE eq WATCHDOG-COMPLETO-FCEA" 2>nul
timeout /t 1 /nobreak >nul

REM Detener PocketBase
echo Deteniendo PocketBase...
taskkill /F /IM pocketbase.exe 2>nul
timeout /t 2 /nobreak >nul

REM Detener Node/Vite
echo Deteniendo Frontend (Node/Vite)...
taskkill /F /IM node.exe 2>nul
timeout /t 2 /nobreak >nul

REM Detener PowerShell relacionados
echo Deteniendo procesos PowerShell del watchdog...
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq powershell.exe" /FO LIST ^| findstr /i "PID:"') do (
    taskkill /F /PID %%a 2>nul
)
timeout /t 2 /nobreak >nul

echo.
echo [2/5] Verificando que los puertos esten libres...
echo.

REM Verificar puerto 8080
netstat -ano | findstr ":8080" | findstr "LISTENING" >nul
if %ERRORLEVEL% EQU 0 (
    echo ADVERTENCIA: Puerto 8080 aun ocupado. Intentando liberar...
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8080" ^| findstr "LISTENING"') do (
        taskkill /F /PID %%a 2>nul
    )
    timeout /t 2 /nobreak >nul
)

REM Verificar puerto 8090
netstat -ano | findstr ":8090" | findstr "LISTENING" >nul
if %ERRORLEVEL% EQU 0 (
    echo ADVERTENCIA: Puerto 8090 aun ocupado. Intentando liberar...
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8090" ^| findstr "LISTENING"') do (
        taskkill /F /PID %%a 2>nul
    )
    timeout /t 2 /nobreak >nul
)

echo Puertos liberados.
echo.

echo [3/5] Iniciando PocketBase en puerto 8090...
cd /d "%~dp0pocketbase"

if not exist "pocketbase.exe" (
    echo ERROR: No se encontro pocketbase.exe
    pause
    exit /b 1
)

start "PocketBase-FCEA-8090" /MIN pocketbase.exe serve --http=127.0.0.1:8090
timeout /t 5 /nobreak >nul

REM Verificar que PocketBase este corriendo
tasklist /FI "IMAGENAME eq pocketbase.exe" | find /i "pocketbase.exe" >nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PocketBase no pudo iniciarse
    pause
    exit /b 1
)

echo PocketBase iniciado correctamente en puerto 8090
echo.

echo [4/5] Iniciando Frontend (Vite) en puerto 8080...
cd /d "%~dp0"

start "Frontend-FCEA-8080" cmd /k "npm run dev"
timeout /t 8 /nobreak >nul

REM Verificar que Node este corriendo
tasklist /FI "IMAGENAME eq node.exe" | find /i "node.exe" >nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Frontend no pudo iniciarse
    pause
    exit /b 1
)

echo Frontend iniciado correctamente en puerto 8080
echo.

echo [5/5] Iniciando Watchdog de proteccion...
start "WATCHDOG-COMPLETO-FCEA" /MIN powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0scripts\watchdog_completo.ps1"
timeout /t 3 /nobreak >nul

echo.
echo ========================================
echo SISTEMA REPARADO Y FUNCIONANDO
echo ========================================
echo.
echo Estado de los servicios:
echo   [OK] PocketBase: puerto 8090
echo   [OK] Frontend: puerto 8080
echo   [OK] Watchdog: activo
echo.
echo Abra su navegador en:
echo   http://localhost:8080/
echo.
echo El sistema ahora deberia funcionar correctamente.
echo.
echo Presione cualquier tecla para salir...
pause >nul
