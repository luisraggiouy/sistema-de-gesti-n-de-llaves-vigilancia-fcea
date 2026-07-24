@echo off
REM ============================================================
REM  FCEA - Reparar Conexion al Servidor
REM ------------------------------------------------------------
REM  Ejecuta scripts\lib\reparar_conexion_servidor.ps1 con
REM  ExecutionPolicy Bypass y en la ventana actual (para que el
REM  usuario vea el escaneo en vivo).
REM
REM  El .ps1 se encarga de:
REM    - Buscar el Monitor Vigilancia en la red (puerto 8090).
REM    - Confirmar que es PocketBase (no otro servicio).
REM    - Reescribir la config local para apuntar a esa IP.
REM    - Ofrecer entrada manual si el escaneo falla.
REM ============================================================

setlocal
cd /d "%~dp0\.."

set "PS1=%CD%\lib\reparar_conexion_servidor.ps1"

if not exist "%PS1%" (
  echo.
  echo [ERROR] No encontre el script principal:
  echo    %PS1%
  echo.
  echo El pendrive parece incompleto. Vuelva a grabarlo con
  echo scripts\pendrive\GRABAR_AMBOS_PENDRIVES_v31.ps1
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
exit /b %ERRORLEVEL%
