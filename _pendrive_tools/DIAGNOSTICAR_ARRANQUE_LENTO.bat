@echo off
REM ============================================================
REM  DIAGNOSTICAR_ARRANQUE_LENTO.bat  (MONITOR VIGILANCIA) - SOLO LECTURA
REM  Entiende por que el arranque tarda ~10 min. NO repara nada.
REM  Guarda el .log y el codigo del arranque EN EL PENDRIVE
REM  (subcarpeta _RESULTADOS, al lado de este .bat).
REM ============================================================
cd /d "%~dp0"

set "OUTDIR=%~dp0_RESULTADOS"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo.
echo  Ejecutando diagnostico de ARRANQUE LENTO (solo lectura)...
echo  El resultado se guardara en el PENDRIVE:
echo    %OUTDIR%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0DIAGNOSTICAR_ARRANQUE_LENTO.ps1" -OutDir "%OUTDIR%"
