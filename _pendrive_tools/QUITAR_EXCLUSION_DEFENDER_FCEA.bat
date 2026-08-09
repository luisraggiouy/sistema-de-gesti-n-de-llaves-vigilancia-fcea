@echo off
REM ============================================================
REM  QUITAR_EXCLUSION_DEFENDER_FCEA.bat  (ROLLBACK)
REM  Quita las exclusiones de Defender que agrego
REM  EXCLUIR_DEFENDER_FCEA.bat. Deja Defender como estaba antes.
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
echo  Quitando exclusiones de Defender de FCEA (rollback)...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0EXCLUIR_DEFENDER_FCEA.ps1" -Quitar -OutDir "%OUTDIR%"
