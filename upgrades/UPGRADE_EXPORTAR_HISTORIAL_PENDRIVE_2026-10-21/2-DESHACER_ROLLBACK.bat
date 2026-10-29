@echo off
REM ============================================================
REM  ROLLBACK Upgrade Exportar Informe Visor Offline (2026-10-21)
REM  Restaura el ultimo dist_backup_* SANO. Correr en la MISMA PC.
REM ============================================================
net session >nul 2>&1
if errorlevel 1 (
  echo  Solicitando permisos de Administrador...
  powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/k','\"%~f0\"' -Verb RunAs"
  exit /b
)
pushd "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0QUITAR_UPGRADE.ps1"
