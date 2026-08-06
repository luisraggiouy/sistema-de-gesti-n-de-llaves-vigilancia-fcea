@echo off
REM ============================================================
REM  UPGRADE: "Foto de la marca" OPCIONAL + area de foto CUADRADA
REM  Modulo: Monitor de Vigilancia -> Registrar Objeto Olvidado
REM  APLICAR en la PC: MONITOR DE VIGILANCIA
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
