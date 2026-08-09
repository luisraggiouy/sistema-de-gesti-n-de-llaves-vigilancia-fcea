@echo off
REM ============================================================
REM  EXCLUIR_DEFENDER_FCEA.bat  (MONITOR VIGILANCIA)
REM  FIX del ARRANQUE LENTO: agrega la carpeta del sistema y
REM  pocketbase.exe a las exclusiones de Windows Defender para
REM  que NO se escaneen en cada arranque en frio.
REM
REM  SEGURO Y REVERSIBLE. No toca datos ni config.json.
REM  Rollback: QUITAR_EXCLUSION_DEFENDER_FCEA.bat
REM  (Pide permisos de administrador solo.)
REM ============================================================
cd /d "%~dp0"

net session >nul 2>&1
if %errorlevel% NEQ 0 (
  echo.
  echo  Solicitando permisos de administrador...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

set "OUTDIR=%~dp0_RESULTADOS"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo.
echo  Agregando exclusiones de Defender para FCEA...
echo  (el resultado queda en el PENDRIVE: %OUTDIR%)
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0EXCLUIR_DEFENDER_FCEA.ps1" -OutDir "%OUTDIR%"
