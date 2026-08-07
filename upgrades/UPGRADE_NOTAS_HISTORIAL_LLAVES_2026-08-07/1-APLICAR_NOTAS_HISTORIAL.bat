@echo off
REM ============================================================
REM  UPGRADE: "Notas en el Buscador Historico de Llaves"
REM  Modulo: Monitor de Vigilancia -> Buscador Historico de Llaves
REM  APLICAR en la PC: MONITOR DE VIGILANCIA
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
