@echo off
REM ============================================================
REM  DIAGNOSTICAR_ARRANQUE.bat  (MONITOR VIGILANCIA) - SOLO LECTURA
REM  Caza el origen del "PocketBase arranca pero no escribe" tras reboot.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0DIAGNOSTICAR_ARRANQUE.ps1"
