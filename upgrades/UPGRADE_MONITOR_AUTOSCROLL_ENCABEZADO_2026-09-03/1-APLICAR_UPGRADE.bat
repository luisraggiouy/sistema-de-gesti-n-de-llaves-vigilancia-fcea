@echo off
REM ============================================================
REM  UPGRADE: El Monitor de Vigilancia vuelve solo al encabezado
REM  tras 4 segundos de inactividad (para tener siempre a la vista
REM  las "Solicitudes pendientes").
REM  APLICAR en LAS 3 PC (Monitor, Terminal A y Terminal B). El dist
REM  es compartido; cada PC sirve su propio dist local.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
