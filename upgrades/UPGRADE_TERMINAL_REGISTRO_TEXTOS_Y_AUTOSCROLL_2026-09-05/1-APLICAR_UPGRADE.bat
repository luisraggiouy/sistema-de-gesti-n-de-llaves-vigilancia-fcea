@echo off
REM ============================================================
REM  UPGRADE: Terminales - textos del registro (Nombre y apellido,
REM  Correo opcional), campos obligatorios en ROJO al registrarse,
REM  y auto-scroll al encabezado tras 4s de inactividad.
REM  APLICAR en LAS 3 PC (Monitor, Terminal A y Terminal B).
REM  El dist es compartido; cada PC sirve su propio dist local.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
