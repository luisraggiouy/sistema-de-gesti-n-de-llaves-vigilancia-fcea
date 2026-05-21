@echo off
rem ============================================================================
rem  RECUPERAR_v2.bat  -  Launcher del recuperador inteligente
rem  ---------------------------------------------------------------------------
rem  - Pide permisos de administrador (UAC) si no los tiene.
rem  - Llama a RECUPERAR_v2.ps1 con politica Bypass.
rem  - NO muestra lineas rojas: todo se canaliza al .ps1 que las atrapa.
rem ============================================================================
setlocal
title FCEA - Recuperador del Sistema (v2)
color 0B

rem --- Pedir admin si no lo tenemos -------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permisos de administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%RECUPERAR_v2.ps1"

if not exist "%PS1%" (
    echo.
    echo [ERROR] No se encuentra RECUPERAR_v2.ps1 al lado de este .bat
    echo Ruta esperada: %PS1%
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "RC=%ERRORLEVEL%"

echo.
if "%RC%"=="0" (
    echo [OK] Recuperador finalizado.
) else (
    echo [AVISO] Recuperador termino con codigo %RC%.
)
echo.
pause
endlocal
