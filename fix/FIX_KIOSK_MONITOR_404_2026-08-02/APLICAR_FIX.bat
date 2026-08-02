@echo off
REM ============================================================
REM  FIX KIOSK 404 (Monitor) - Launcher 2026-08-02
REM  Doble click aqui. Se auto-eleva (UAC) y aplica el fix.
REM ============================================================
title FIX KIOSK 404 (Monitor) - FCEA

REM --- Auto-elevacion a Administrador ---
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo   Solicitando permisos de Administrador...
  powershell -NoProfile -Command "Start-Process -Verb RunAs -FilePath '%~f0'"
  exit /b
)

cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0APLICAR_FIX.ps1"

echo.
echo   Presione una tecla para cerrar...
pause >nul
