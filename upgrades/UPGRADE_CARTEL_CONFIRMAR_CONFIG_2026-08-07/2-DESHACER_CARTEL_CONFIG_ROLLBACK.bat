@echo off
REM ============================================================
REM  ROLLBACK del upgrade "Cartel de advertencia al confirmar Configuracion"
REM  Restaura el ultimo dist_backup_* creado al aplicar el upgrade.
REM  Usar SOLO si el upgrade dio problemas. PC: MONITOR DE VIGILANCIA
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0QUITAR_UPGRADE.ps1\"'"
