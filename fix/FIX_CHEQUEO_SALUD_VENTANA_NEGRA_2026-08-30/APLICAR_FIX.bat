@echo off
REM ============================================================
REM  FIX ventana negra Chequeo de Salud / Watchdog - FCEA
REM  Fecha: 2026-08-30
REM  Ejecutar SOLO en el Monitor de Vigilancia.
REM ============================================================
title FIX ventana negra Chequeo de Salud - FCEA
echo.
echo  Aplicando fix (oculta la consola negra del Chequeo de Salud/Watchdog)...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0APLICAR_FIX.ps1"
echo.
echo  Terminado. Presione una tecla para cerrar.
pause >nul
