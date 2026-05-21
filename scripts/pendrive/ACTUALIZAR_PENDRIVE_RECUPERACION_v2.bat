@echo off
rem ============================================================================
rem  ACTUALIZAR_PENDRIVE_RECUPERACION_v2.bat
rem  ---------------------------------------------------------------------------
rem  Companion para correr el .ps1 con doble click sin pedir admin
rem  (no hace falta admin para escribir en el pendrive del usuario).
rem ============================================================================
setlocal
title FCEA - Actualizar Pendrive Recuperacion (v2)
color 0A

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1"

if not exist "%PS1%" (
    echo.
    echo [ERROR] No se encuentra: %PS1%
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
echo.
pause
endlocal
