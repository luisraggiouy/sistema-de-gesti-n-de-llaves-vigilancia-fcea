@echo off
REM ============================================================
REM  ROLLBACK del FIX HISTORIAL LENTO (2026-10-03)
REM  Restaura el dist anterior. Correr en la MISMA PC donde se aplico.
REM ============================================================
net session >nul 2>&1
if errorlevel 1 (
  echo  Solicitando permisos de Administrador...
  powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/k','\"%~f0\"' -Verb RunAs"
  exit /b
)
pushd "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0QUITAR_FIX.ps1"
