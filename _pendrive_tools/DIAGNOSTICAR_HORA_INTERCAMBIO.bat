@echo off
REM ============================================================
REM  DIAGNOSTICO (SOLO LECTURA): hora de entrega / intercambio
REM  Escribe un .log en el pendrive (_RESULTADOS).
REM  EJECUTAR en la PC: MONITOR DE VIGILANCIA
REM  No modifica datos: solo lee de PocketBase y muestra la hora.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0DIAGNOSTICAR_HORA_INTERCAMBIO.ps1"
