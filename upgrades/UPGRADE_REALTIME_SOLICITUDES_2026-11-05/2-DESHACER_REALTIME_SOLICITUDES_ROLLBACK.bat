@echo off
REM ============================================================
REM  2-DESHACER_REALTIME_SOLICITUDES_ROLLBACK.bat
REM  Lanza QUITAR_UPGRADE.ps1 (restaura el ultimo dist_backup_*).
REM  UPGRADE: Realtime de Solicitudes 2026-11-05
REM  Ejecutar en la MISMA PC donde se aplico el upgrade.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0QUITAR_UPGRADE.ps1"
