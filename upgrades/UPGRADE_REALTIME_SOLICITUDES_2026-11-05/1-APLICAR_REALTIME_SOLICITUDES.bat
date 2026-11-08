@echo off
REM ============================================================
REM  1-APLICAR_REALTIME_SOLICITUDES.bat
REM  Lanza APLICAR_UPGRADE.ps1 con permisos de administrador.
REM  UPGRADE: Realtime de Solicitudes (fix latencia ~2s) 2026-11-05
REM  Aplicar en LAS 3 PC (Monitor, Terminal A y Terminal B).
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0APLICAR_UPGRADE.ps1"
