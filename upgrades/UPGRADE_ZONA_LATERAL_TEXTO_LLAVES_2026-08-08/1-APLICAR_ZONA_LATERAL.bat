@echo off
REM ============================================================
REM  UPGRADE: "Zona del tablero - aclaracion en Laterales"
REM  Modulo: Monitor de Vigilancia -> Gestion de Llaves (Agregar/Modificar)
REM  APLICAR en la PC: MONITOR DE VIGILANCIA
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
