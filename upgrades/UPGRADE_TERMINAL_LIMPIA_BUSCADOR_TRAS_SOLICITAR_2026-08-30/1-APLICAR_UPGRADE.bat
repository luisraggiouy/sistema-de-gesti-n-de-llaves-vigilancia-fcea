@echo off
REM ============================================================
REM  UPGRADE: La Terminal limpia el buscador de llaves tras
REM  SOLICITAR (antes quedaba el texto tecleado, ej. "rendi", y la
REM  lista desplegada; habia que apretar F5).
REM  APLICAR en LAS 3 PC (Monitor, Terminal A y Terminal B). Cada PC
REM  sirve su propio dist local; si se aplica solo en el Monitor, las
REM  Terminales A/B siguen con el JavaScript viejo.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
