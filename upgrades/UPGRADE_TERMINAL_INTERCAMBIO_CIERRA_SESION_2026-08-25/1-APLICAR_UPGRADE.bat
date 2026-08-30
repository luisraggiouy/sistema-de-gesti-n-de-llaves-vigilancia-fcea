@echo off
REM ============================================================
REM  UPGRADE: Intercambio de llave cierra la sesion y limpia
REM  la Terminal (evita que quede el usuario logueado y la lista
REM  desplegada).
REM  CORRECCION 2026-08-30: APLICAR en LAS 3 PC (Monitor,
REM  Terminal A y Terminal B). Cada PC sirve su propio dist
REM  local; si se aplica solo en el Monitor, las Terminales A/B
REM  siguen con el JavaScript viejo.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
