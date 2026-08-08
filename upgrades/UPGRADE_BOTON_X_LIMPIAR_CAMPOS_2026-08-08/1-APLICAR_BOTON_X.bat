@echo off
REM ============================================================
REM  UPGRADE: "Boton X para borrar todo el texto de un campo"
REM  Modulos: Gestion de Llaves + Objetos Olvidados (devolucion)
REM  APLICAR en la PC: MONITOR DE VIGILANCIA
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_UPGRADE.ps1\"'"
