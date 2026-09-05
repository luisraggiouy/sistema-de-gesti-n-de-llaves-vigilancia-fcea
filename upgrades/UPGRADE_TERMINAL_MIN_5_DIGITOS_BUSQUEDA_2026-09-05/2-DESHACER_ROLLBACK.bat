@echo off
REM ============================================================
REM  ROLLBACK del UPGRADE: lista por celular al 5to digito (2026-09-05)
REM  Restaura el ultimo backup del dist.
REM  Ejecutar en la MISMA PC donde se aplico el upgrade.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0QUITAR_UPGRADE.ps1\"'"
