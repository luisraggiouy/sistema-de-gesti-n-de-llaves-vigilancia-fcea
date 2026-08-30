@echo off
REM Lanzador del fix "Autorizaciones fecha un dia antes" (2026-08-30)
REM Ejecuta el .ps1 que esta al lado, sorteando la politica de ejecucion.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0APLICAR_FIX.ps1"
