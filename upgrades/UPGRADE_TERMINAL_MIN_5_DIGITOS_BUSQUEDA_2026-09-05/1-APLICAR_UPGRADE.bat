@echo off
REM ============================================================
REM  UPGRADE: la lista de usuarios por CELULAR recien aparece a
REM  partir del 5to digito (anti-suplantacion de identidad).
REM  Busqueda por email sigue igual (desde 2 caracteres).
REM  APLICAR en LAS 3 PC (Monitor, Terminal A y Terminal B).
REM  El dist es compartido; cada PC sirve su propio dist local.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
