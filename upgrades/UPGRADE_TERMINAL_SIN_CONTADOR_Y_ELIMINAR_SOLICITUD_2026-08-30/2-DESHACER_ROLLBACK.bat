@echo off
REM ============================================================
REM  ROLLBACK del UPGRADE: Terminal sin contador + Eliminar solicitud
REM  Restaura el ultimo backup del dist.
REM  EJECUTAR en la MISMA PC donde se aplico el upgrade.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0QUITAR_UPGRADE.ps1\"'"
