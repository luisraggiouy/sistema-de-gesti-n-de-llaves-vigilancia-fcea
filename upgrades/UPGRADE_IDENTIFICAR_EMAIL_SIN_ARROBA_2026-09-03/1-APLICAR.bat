@echo off
REM ============================================================
REM  UPGRADE: "Identificarse con el email SIN escribir la @"
REM  Modulo: Terminales de usuario (buscador de identificacion)
REM  APLICAR en LAS 3 PC: Monitor, Terminal A y Terminal B
REM  (ejecutar este mismo .bat una vez en cada PC)
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
