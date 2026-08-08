@echo off
REM ============================================================
REM  ROLLBACK del UPGRADE: "Boton X para borrar todo el texto"
REM  Restaura el ultimo backup del dist.
REM  EJECUTAR en la PC: MONITOR DE VIGILANCIA
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0QUITAR_UPGRADE.ps1\"'"
