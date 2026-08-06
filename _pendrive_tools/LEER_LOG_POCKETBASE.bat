@echo off
REM ============================================================
REM  LEER_LOG_POCKETBASE.bat  (MONITOR VIGILANCIA) - SOLO LECTURA
REM  Muestra el error real de PocketBase en el arranque.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0LEER_LOG_POCKETBASE.ps1"
