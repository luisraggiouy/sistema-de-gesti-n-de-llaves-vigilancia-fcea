@echo off
REM ============================================================
REM  APLICAR_FIX.bat  -  FIX AUTORIZACIONES: ESPACIO EN BLANCO (2026-08-06)
REM  Lanzador que auto-eleva a Administrador y ejecuta el .ps1
REM  (necesita permisos para escribir en C:\sistema-llaves-fcea).
REM  NO compila: instala el dist ya compilado desde el pendrive.
REM ============================================================
setlocal
cd /d "%~dp0"

REM --- Auto-elevacion a Administrador ---
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Solicitando permisos de Administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo ============================================================
echo   APLICAR FIX AUTORIZACIONES (espacio en blanco) - %COMPUTERNAME%
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0APLICAR_FIX.ps1"

endlocal
