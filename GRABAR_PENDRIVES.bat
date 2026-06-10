@echo off
REM ============================================================
REM  Grabador de pendrives FCEA v3.1
REM  Doble-click o "Ejecutar como administrador".
REM  Solo este BAT esta en la raiz para que sea facil de encontrar.
REM ============================================================
setlocal

REM Re-lanzar con UAC si no soy admin
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo Solicitando privilegios de administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\pendrive\GRABAR_AMBOS_PENDRIVES_v31.ps1" %*

endlocal
