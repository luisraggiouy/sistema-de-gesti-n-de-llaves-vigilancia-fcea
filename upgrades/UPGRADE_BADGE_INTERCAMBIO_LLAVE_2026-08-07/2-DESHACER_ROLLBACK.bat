@echo off
REM ============================================================
REM  ROLLBACK del UPGRADE: "Cartel 'Intercambio de llave'"
REM  Restaura el ultimo backup del dist en el Monitor de Vigilancia.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0QUITAR_UPGRADE.ps1\"'"
