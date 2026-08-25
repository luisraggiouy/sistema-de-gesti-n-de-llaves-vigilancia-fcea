@echo off
REM ============================================================
REM  UPGRADE (FIX): guardado de hora de entrega/devolucion en ISO
REM  (corrige el "marcaba 5 horas" tras F5 luego de un intercambio)
REM  APLICAR en la PC: MONITOR DE VIGILANCIA
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
