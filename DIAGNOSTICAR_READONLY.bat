@echo off
REM ============================================================
REM  DIAGNOSTICAR_READONLY - SOLO LECTURA (no modifica el sistema)
REM  Ejecutar en el MONITOR DE VIGILANCIA. Deja un TXT al lado
REM  de este .bat (en el pendrive) con la evidencia del readonly.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0DIAGNOSTICAR_READONLY.ps1\"'"
