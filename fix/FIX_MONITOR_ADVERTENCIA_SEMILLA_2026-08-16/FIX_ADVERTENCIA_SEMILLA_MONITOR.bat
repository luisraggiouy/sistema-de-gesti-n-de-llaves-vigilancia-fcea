@echo off
REM ============================================================
REM  FIX - Advertencia 'semilla' en el Monitor del Sistema
REM  Lanzador. La logica esta en APLICAR_FIX.ps1
REM  Correr en el MONITOR VIGILANCIA (clic derecho no hace falta;
REM  el .ps1 no toca servicios). Con el pendrive de RESCATE tambien
REM  enchufado, actualiza los dos archivos de una.
REM ============================================================
title FCEA - Fix advertencia semilla del Monitor
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\FIX_ADVERTENCIA_SEMILLA_MONITOR.ps1"
exit /b %ERRORLEVEL%
