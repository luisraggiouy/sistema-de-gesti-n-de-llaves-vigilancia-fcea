@echo off
REM ============================================================
REM  UPGRADE: Empresas desde 06:00 + Intendencia 24 hs
REM   - EMPRESA (ej. Cooperativa El Progreso): puede solicitar
REM     llaves desde las 06:00 (franja 06:00-06:59).
REM   - Personal TAS de "Intendencia": exento 24 hs (como
REM     Servicios Generales y Vigilancia).
REM  APLICAR en LAS 3 PC (Monitor, Terminal A y Terminal B). Cada PC
REM  sirve su propio dist local; si se aplica solo en el Monitor, las
REM  Terminales A/B siguen con el JavaScript viejo.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
