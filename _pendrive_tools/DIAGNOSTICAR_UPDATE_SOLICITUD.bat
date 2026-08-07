@echo off
REM ============================================================
REM  DIAGNOSTICO: reproduce el update de una solicitud (como la app)
REM  para ver el error EXACTO del servidor. EJECUTAR en el MONITOR.
REM  Es idempotente (reenvia los mismos valores). Deja .log en _RESULTADOS.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0DIAGNOSTICAR_UPDATE_SOLICITUD.ps1"
