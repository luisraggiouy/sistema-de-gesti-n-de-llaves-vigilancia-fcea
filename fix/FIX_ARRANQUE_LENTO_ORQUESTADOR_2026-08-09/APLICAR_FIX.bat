@echo off
REM ============================================================
REM  APLICAR FIX ARRANQUE LENTO ORQUESTADOR - 2026-08-09
REM  Ejecutar SOLO en el MONITOR DE VIGILANCIA.
REM ============================================================
echo.
echo ==== FIX ARRANQUE LENTO (orquestador) - MONITOR ====
echo.
echo Este fix corrige la llamada rota del orquestador que hacia
echo que el arranque tardara ~8 minutos. Hace BACKUP y valida solo.
echo.
pause
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0APLICAR_FIX.ps1" -OutDir "%~dp0"
echo.
echo ==== Listo. Revise el mensaje de arriba y el .log generado. ====
echo Ahora REINICIE el Monitor y mida el arranque.
echo.
pause
