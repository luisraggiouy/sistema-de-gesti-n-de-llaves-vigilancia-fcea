@echo off
REM ============================================================
REM  UPGRADE (FIX v2): tooltip + desbloqueo preciso a las 06:00
REM  del bloqueo nocturno de botones.
REM  APLICAR en la PC: MONITOR DE VIGILANCIA
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
