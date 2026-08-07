@echo off
REM ============================================================
REM  UPGRADE: "Texto descriptivo en 'Identificarse'"
REM  Modulo: Terminal A y Terminal B -> pantalla de solicitud de llave
REM  APLICAR en las PC: TERMINAL A y TERMINAL B (repetir en cada una)
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
