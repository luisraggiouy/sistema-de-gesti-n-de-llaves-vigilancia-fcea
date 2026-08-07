@echo off
REM ============================================================
REM  UPGRADE: Nuevo edificio "Aulario" en Gestion de Llaves
REM  Modulo: Monitor de Vigilancia -> pestana Llaves -> Agregar / Modificar
REM  APLICAR en la PC: MONITOR DE VIGILANCIA
REM  (Opcional tambien en TERMINAL A y TERMINAL B para el filtro)
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
