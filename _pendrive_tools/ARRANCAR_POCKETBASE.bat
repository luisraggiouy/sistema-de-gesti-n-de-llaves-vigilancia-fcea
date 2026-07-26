@echo off
REM Wrapper para ARRANCAR_POCKETBASE.ps1 - solicita elevacion admin
setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%ARRANCAR_POCKETBASE.ps1"

REM Verificar admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Solicitando privilegios de administrador...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
