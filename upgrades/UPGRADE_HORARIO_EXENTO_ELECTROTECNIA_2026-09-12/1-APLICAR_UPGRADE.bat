@echo off
REM ============================================================
REM  UPGRADE: Electrotecnia exento 24 hs
REM   - Personal TAS de "Electrotecnia": exento 24 hs (como
REM     Servicios Generales, Vigilancia e Intendencia). Puede
REM     solicitar llaves a cualquier hora, sin banner rojo.
REM  APLICAR en LAS 3 PC (Monitor, Terminal A y Terminal B). Cada PC
REM  sirve su propio dist local; si se aplica solo en el Monitor, las
REM  Terminales A/B siguen con el JavaScript viejo.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
