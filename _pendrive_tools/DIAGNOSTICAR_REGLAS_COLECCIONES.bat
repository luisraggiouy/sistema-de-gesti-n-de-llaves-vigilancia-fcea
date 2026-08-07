@echo off
REM ============================================================
REM  DIAGNOSTICO (SOLO LECTURA) de las reglas de acceso de las
REM  colecciones de PocketBase. EJECUTAR en el MONITOR de Vigilancia.
REM  No modifica nada. Deja un .log en <unidad>:\_RESULTADOS.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0DIAGNOSTICAR_REGLAS_COLECCIONES.ps1"
