@echo off
REM ============================================================
REM  ROLLBACK del UPGRADE: "Identificarse con el email SIN escribir la @"
REM  Restaura el dist anterior (dist_backup_<fecha_hora>)
REM  EJECUTAR en la PC donde se quiera revertir
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0QUITAR_UPGRADE.ps1\"'"
