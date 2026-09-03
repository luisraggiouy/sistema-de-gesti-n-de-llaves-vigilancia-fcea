@echo off
REM ============================================================
REM  ROLLBACK del UPGRADE: Empresas desde 06:00 + Intendencia 24 hs
REM  Restaura el ultimo backup del dist.
REM  Ejecutar en la MISMA PC donde se aplico el upgrade.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0QUITAR_UPGRADE.ps1\"'"
