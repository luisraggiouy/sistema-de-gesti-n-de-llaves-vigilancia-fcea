@echo off
REM ============================================================
REM  Sistema de Gestion de Llaves FCEA
REM  ACTUALIZAR DATOS - Pendrive de RESCATE (custodia jefes)
REM  ------------------------------------------------------------
REM  Version SEGURA: usa el backup interno de PocketBase por HTTP.
REM    * NO detiene el servidor.
REM    * NO corta el servicio (downtime = 0).
REM    * NO modifica los datos de produccion (solo lee un snapshot).
REM
REM  Correr en el MONITOR VIGILANCIA (con el sistema prendido).
REM  Este .bat es solo un lanzador; la logica esta en el .ps1.
REM ============================================================
title FCEA - Actualizar datos del pendrive de RESCATE (SEGURO)

REM Raiz del pendrive SIN barra final: si se pasa "D:\", el \" escapa la
REM comilla de cierre y PowerShell recibe el argumento corrupto (bug clasico).
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "PS=%ROOT%\sistema-llaves-fcea\scripts\pendrive\ACTUALIZAR_DATOS_RESCATE.ps1"

if not exist "%PS%" (

  echo.
  echo  [ERROR] No se encontro el script:
  echo          %PS%
  echo.
  echo  Asegurese de ejecutar este archivo DESDE el pendrive de RESCATE.
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS%" -PendriveRoot "%ROOT%"

set "RC=%ERRORLEVEL%"

echo.
echo ============================================================
if "%RC%"=="0" (
  echo  RESULTADO: OK  ^(codigo 0^)
) else (
  echo  RESULTADO: HUBO UN PROBLEMA  ^(codigo %RC%^)
  echo  Revise el LOG en la carpeta:  %~dp0_RESULTADOS
)
echo ============================================================
echo.
echo  Esta ventana NO se cierra sola. Cuando termine de leer,
echo  presione una tecla para cerrar.
pause >nul
exit /b %RC%


