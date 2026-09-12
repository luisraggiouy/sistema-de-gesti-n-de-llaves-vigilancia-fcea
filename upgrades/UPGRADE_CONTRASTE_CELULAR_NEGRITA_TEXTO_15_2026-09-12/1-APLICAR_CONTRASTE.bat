@echo off
REM ============================================================
REM  UPGRADE: "Contraste cajas + 'celular' negrita + textos +15%"
REM  Modulo: Terminal de usuario (pantalla de identificacion)
REM  APLICAR en LAS 3 PC: MONITOR, TERMINAL A y TERMINAL B
REM  (ejecutar una vez en cada una y reabrir el kiosko)
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
