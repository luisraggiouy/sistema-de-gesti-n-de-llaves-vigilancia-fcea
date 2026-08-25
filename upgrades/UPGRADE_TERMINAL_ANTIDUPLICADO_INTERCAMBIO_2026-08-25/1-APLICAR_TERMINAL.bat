@echo off
REM ============================================================
REM  UPGRADE: Terminal - evitar duplicados + intercambio frecuentes
REM  APLICAR en la PC: TERMINAL A y TERMINAL B (las dos)
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
