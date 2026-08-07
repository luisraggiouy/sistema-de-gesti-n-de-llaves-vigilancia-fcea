@echo off
REM ============================================================
REM  DIAGNOSTICO (SOLO LECTURA): campo 'notas' en 'solicitudes'
REM  EJECUTAR en la PC: MONITOR DE VIGILANCIA (es el servidor PocketBase)
REM  Deja un .log en el pendrive: _RESULTADOS\LOG_CAMPO_NOTAS_*.log
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0DIAGNOSTICAR_CAMPO_NOTAS.ps1"
