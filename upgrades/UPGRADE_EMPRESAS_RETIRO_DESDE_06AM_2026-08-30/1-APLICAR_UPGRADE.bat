@echo off
REM ============================================================
REM  UPGRADE: Empresas pueden solicitar llaves desde las 06:00
REM  (cooperativas de limpieza y similares que empiezan antes de
REM  las 7). El resto de usuarios sigue con el corte de las 07:00.
REM  APLICAR en LAS 3 PC (Monitor, Terminal A y Terminal B). Cada PC
REM  sirve su propio dist local; si se aplica solo en el Monitor, las
REM  Terminales A/B siguen con el JavaScript viejo.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
