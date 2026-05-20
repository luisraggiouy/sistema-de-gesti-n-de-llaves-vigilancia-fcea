@echo off
REM =====================================================================
REM  DESINSTALAR SISTEMA DE LLAVES FCEA  (v2.1 - anti-cierre)
REM  Borra TODO rastro del sistema en el PC. Si el .ps1 truena, la
REM  ventana NO cierra al segundo: muestra el error y espera Enter.
REM =====================================================================
title DESINSTALAR SISTEMA DE LLAVES FCEA v2.1
color 1F

REM Verificar privilegios de administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Solicitando permisos de administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
set "PS1=%~dp0lib\DESINSTALAR-SISTEMA.ps1"

if not exist "%PS1%" (
    echo [ERROR CRITICO] No se encontro %PS1%
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { try { & '%PS1%' } catch { Write-Host ''; Write-Host '=== EXCEPCION NO CAPTURADA EN EL PS1 ===' -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Red; Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed; exit 99 } }"
set "RC=%ERRORLEVEL%"

echo.
echo =====================================================================
if "%RC%"=="0" (echo  El script termino normalmente.) else (echo  El script termino con codigo: %RC%)
echo =====================================================================
echo.
echo Presione una tecla para cerrar...
pause >nul
