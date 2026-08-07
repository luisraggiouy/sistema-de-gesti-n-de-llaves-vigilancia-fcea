@echo off
REM ============================================================
REM  FIX: agregar campo 'notas' a la coleccion 'solicitudes'
REM  EJECUTAR en la PC: MONITOR DE VIGILANCIA (es el servidor)
REM  En caliente, SIN reiniciar PocketBase. Deja un .log en el pendrive.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0APLICAR_FIX.ps1"
