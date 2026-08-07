@echo off
REM ============================================================
REM  ROLLBACK del UPGRADE: "Notas en el Buscador Historico de Llaves"
REM  Restaura el dist anterior (dist_backup_<fecha_hora>)
REM  EJECUTAR en la PC: MONITOR DE VIGILANCIA
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0QUITAR_UPGRADE.ps1\"'"
