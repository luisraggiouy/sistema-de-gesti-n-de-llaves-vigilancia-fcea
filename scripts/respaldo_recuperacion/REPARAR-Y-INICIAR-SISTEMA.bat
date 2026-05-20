@echo off
REM =====================================================================
REM  REPARAR-Y-INICIAR-SISTEMA.bat   (v2 - mayo 2026, anti-cierre)
REM  Wrapper que lanza el .ps1 de reparacion. Auto-eleva a Admin.
REM  PAUSA SIEMPRE al final aunque el .ps1 truene, asi el usuario ve
REM  el error en pantalla en lugar de que la ventana cierre al segundo.
REM =====================================================================

setlocal ENABLEEXTENSIONS

title REPARAR Y INICIAR SISTEMA DE LLAVES FCEA
color 1F

REM --- Auto-elevarse a Administrador si no lo somos ---
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Solicitando permisos de administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

REM --- Cambiar al directorio del .bat (importante cuando es elevado) ---
cd /d "%~dp0"

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%lib\REPARAR-Y-INICIAR-SISTEMA.ps1"
set "LOG=%SCRIPT_DIR%ultimo_log_reparacion.txt"

echo.
echo =====================================================================
echo  REPARAR Y INICIAR SISTEMA DE LLAVES FCEA
echo =====================================================================
echo  Pendrive: %SCRIPT_DIR%
echo  Script PS1: %PS1%
echo  Log: %LOG%
echo =====================================================================
echo.

if not exist "%PS1%" (
    echo [ERROR CRITICO] No se encontro el script PowerShell:
    echo         %PS1%
    echo.
    echo Verifique que el pendrive contenga la carpeta lib\
    echo y dentro el archivo REPARAR-Y-INICIAR-SISTEMA.ps1
    echo.
    pause
    exit /b 1
)

REM --- Lanzar el .ps1 SIN -File para evitar problemas con caracteres   ---
REM --- raros en la ruta. Usamos -Command y dot-source.                  ---
REM --- Capturamos exitcode para detectar si el .ps1 trono.              ---
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { try { & '%PS1%' } catch { Write-Host ''; Write-Host '=== EXCEPCION NO CAPTURADA EN EL PS1 ===' -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Red; Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed; exit 99 } }"
set "RC=%ERRORLEVEL%"

echo.
echo =====================================================================
if "%RC%"=="0" (
    echo  El script termino normalmente.
) else (
    echo  El script termino con codigo de salida: %RC%
    echo  Revise el log: %LOG%
)
echo =====================================================================
echo.
echo Presione una tecla para cerrar esta ventana...
pause >nul

endlocal
