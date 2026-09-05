@echo off
REM ============================================================
REM  UPGRADE: Buscador en "Llaves en Uso" del Monitor de Vigilancia.
REM  Aparece un campo al lado del titulo para filtrar por nombre de
REM  llave y de persona cuando hay muchas llaves en uso. Ademas la
REM  lista se ordena con la ultima llave entregada arriba.
REM  APLICAR en LAS 3 PC (Monitor, Terminal A y Terminal B). El dist
REM  es compartido; cada PC sirve su propio dist local.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
