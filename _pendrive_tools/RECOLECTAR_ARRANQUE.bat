@echo off
REM ============================================================
REM  RECOLECTAR_ARRANQUE.bat  (SOLO LECTURA)
REM  Lanza RECOLECTAR_ARRANQUE.ps1 para copiar al pendrive los
REM  scripts de arranque reales de esta PC. No modifica nada.
REM ============================================================
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RECOLECTAR_ARRANQUE.ps1"
echo.
pause
