@echo off
REM ============================================================
REM  APLICAR_UPGRADE.bat  -  Instala el Splash de Arranque FCEA
REM  Ejecutar en el MONITOR VIGILANCIA (doble clic).
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0APLICAR_UPGRADE.ps1"
