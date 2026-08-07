@echo off
REM ============================================================
REM  UPGRADE: "Cartel de advertencia al confirmar Configuracion"
REM  Modulo: Monitor de Vigilancia -> pestana Configuracion
REM  APLICAR en la PC: MONITOR DE VIGILANCIA
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
