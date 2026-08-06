@echo off
REM ============================================================
REM  DIAGNOSTICAR_LLAVES_SYNC.bat   (v2 ROBUSTO - 2026-08-06)
REM  Lanzador del diagnostico de sincronizacion de LLAVES.
REM
REM  SOLO LECTURA: no modifica NADA del sistema. Se puede correr
REM  con el sistema funcionando y atendiendo gente.
REM
REM  GARANTIAS (v2):
REM   - Deja el log SI o SI en el pendrive, en _RESULTADOS.
REM   - NUNCA se cierra solo: siempre hace PAUSE al final.
REM   - Redirige toda la salida a un _WRAP_...txt en el pendrive,
REM     asi aunque PowerShell falle (politica/antivirus) queda el
REM     error escrito para que Cline lo lea desde la laptop.
REM
REM  USO: doble click en cada PC (Monitor, Terminal A, Terminal B).
REM ============================================================
setlocal EnableExtensions
cd /d "%~dp0"
title DIAGNOSTICAR LLAVES SYNC - Sistema FCEA

set "TOOLDIR=%~dp0"
set "RESDIR=%TOOLDIR%_RESULTADOS"
if not exist "%RESDIR%" mkdir "%RESDIR%" 2>nul

set "WRAP=%RESDIR%\_WRAP_LLAVES_SYNC_%COMPUTERNAME%.txt"

echo.
echo   ============================================================
echo    DIAGNOSTICO DE SINCRONIZACION DE LLAVES  (SOLO LECTURA)
echo    PC: %COMPUTERNAME%
echo   ============================================================
echo.
echo   Los resultados se guardaran en el PENDRIVE, en:
echo     %RESDIR%
echo.

REM --- Marcador inicial: garantiza que quede algo aunque PS falle ---
> "%WRAP%" echo ===== ARRANQUE WRAPPER %DATE% %TIME% - PC %COMPUTERNAME% =====
>> "%WRAP%" echo Carpeta herramienta: %TOOLDIR%

REM --- Verificar que exista powershell.exe ---
where powershell >nul 2>&1
if errorlevel 1 (
  >> "%WRAP%" echo [ERROR] No se encontro powershell.exe en el PATH de esta PC.
  echo   [ERROR] No se encontro powershell.exe en esta PC.
  echo   Se guardo un WRAP con el error en:
  echo     %WRAP%
  echo.
  pause
  endlocal
  exit /b 1
)

echo   Ejecutando... ^(puede tardar unos segundos^)
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%TOOLDIR%DIAGNOSTICAR_LLAVES_SYNC.ps1" -PendriveDir "%TOOLDIR%" >> "%WRAP%" 2>&1
set "PSEXIT=%ERRORLEVEL%"

echo   ---------- SALIDA DEL DIAGNOSTICO ----------
type "%WRAP%"
echo.
echo   --------------------------------------------
echo   Codigo de salida PowerShell: %PSEXIT%
echo.
echo   ^>^>^> Archivos generados en: %RESDIR%
dir /b "%RESDIR%"
echo.
echo   Trae el pendrive a la laptop de desarrollo.
echo   Cline leera estos archivos directamente.
echo.
pause
endlocal
