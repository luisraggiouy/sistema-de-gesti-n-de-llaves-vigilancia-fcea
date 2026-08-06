@echo off
REM ============================================================
REM  DIAGNOSTICAR_INSTANCIA_POCKETBASE_V2.bat
REM  VERSION 2 (2026-08-02): log path real + prueba de escritura
REM  AUTENTICADA como admin (elimina la ambiguedad del 400).
REM  Wrapper que solicita elevacion admin y lanza el .ps1 V2.
REM ============================================================
setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%DIAGNOSTICAR_INSTANCIA_POCKETBASE_V2.ps1"

REM Verificar admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Solicitando privilegios de administrador...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
