@echo off
REM ============================================================
REM  ROLLBACK del UPGRADE: Nuevo edificio "Aulario"
REM  Restaura el dist anterior (ultimo backup dist_backup_*)
REM  Ejecutar en la MISMA PC donde se aplico el upgrade
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0QUITAR_UPGRADE.ps1\"'"
