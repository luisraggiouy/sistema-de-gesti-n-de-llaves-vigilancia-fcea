@echo off
REM ============================================================
REM  FIX RAIZ readonly - PERMISOS NTFS de data.db (2026-08-02)
REM  Ejecutar en el MONITOR DE VIGILANCIA.
REM ============================================================
cd /d "%~dp0"
echo.
echo   Aplicando FIX DE RAIZ readonly (permisos de data.db)...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0APLICAR_FIX.ps1\"'"
