@echo off
REM ============================================================
REM  FIX CLICKS / LATENCIA en el Monitor (2026-10-03)
REM  Lanzador con auto-elevacion a Administrador.
REM  APLICAR EN LAS 3 PC: Monitor, Terminal A y Terminal B.
REM ============================================================
net session >nul 2>&1
if errorlevel 1 (
  echo  Solicitando permisos de Administrador...
  powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/k','\"%~f0\"' -Verb RunAs"
  exit /b
)
pushd "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0APLICAR_FIX.ps1"
