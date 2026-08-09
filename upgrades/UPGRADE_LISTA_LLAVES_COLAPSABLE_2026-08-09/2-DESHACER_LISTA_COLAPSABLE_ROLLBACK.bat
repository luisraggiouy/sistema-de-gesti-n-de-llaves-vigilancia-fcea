@echo off
REM ============================================================
REM  ROLLBACK del UPGRADE: "Lista de Llaves Colapsable"
REM  Restaura el dist anterior (dist_backup_<fecha_hora>)
REM  EJECUTAR en la PC donde se aplico (TERMINAL A o TERMINAL B)
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0QUITAR_UPGRADE.ps1\"'"
