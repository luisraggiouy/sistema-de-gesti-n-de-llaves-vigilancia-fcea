@echo off
REM ============================================================
REM  ROLLBACK del UPGRADE: Autoscroll 8s + Buscador izquierda + Notas 1 renglon.
REM  Restaura el ultimo backup del dist.
REM  Ejecutar en la MISMA PC donde se aplico el upgrade.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0QUITAR_UPGRADE.ps1\"'"
