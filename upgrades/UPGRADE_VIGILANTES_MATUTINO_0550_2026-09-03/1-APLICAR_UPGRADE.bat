@echo off
REM ============================================================
REM  UPGRADE: Vigilantes del Matutino visibles desde las 05:50
REM  (Monitor: entre 05:50 y 05:59 aparecen tambien los del
REM   turno Matutino, ademas de los del Nocturno.)
REM  APLICAR en LAS 3 PC (Monitor, Terminal A y Terminal B).
REM  Cada PC sirve su propio dist local; si se aplica solo en el
REM  Monitor, las Terminales A/B siguen con el JavaScript viejo.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
