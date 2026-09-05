@echo off
REM ============================================================
REM  UPGRADE: Monitor de Vigilancia - 3 cambios de UI:
REM   1) Autoscroll al encabezado ahora a los 8 seg (antes 4).
REM   2) Buscador de "Llaves en Uso" alineado a la IZQUIERDA,
REM      junto al titulo y a la derecha del badge.
REM   3) Campo Notas de las tarjetas en UN SOLO RENGLON.
REM  APLICAR en LAS 3 PC (Monitor, Terminal A y Terminal B). El dist
REM  es compartido; cada PC sirve su propio dist local.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
