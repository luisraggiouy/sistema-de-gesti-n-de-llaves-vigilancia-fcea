@echo off
REM ============================================================
REM  Sistema de Gestion de Llaves FCEA - RECUPERADOR SIMPLE
REM ============================================================
REM  Doble click para reparar una instalacion existente sin
REM  perder los datos productivos (llaves, usuarios, historial).
REM
REM  Se pedira automaticamente permiso de administrador (UAC).
REM
REM  Que hace este recuperador:
REM    - Detiene y reinicia PocketBase de manera limpia.
REM    - Verifica integridad de data.db.
REM    - Reinstala frontend si esta danado.
REM    - Repara tareas programadas y accesos directos.
REM    - Solo si data.db esta IRRECUPERABLE, restaura desde el
REM      snapshot del pendrive (con backup previo automatico).
REM
REM  Los datos productivos viven en:
REM    C:\ProgramData\FCEA-Sistema-Llaves\pb_data
REM ============================================================

setlocal EnableDelayedExpansion
title Sistema FCEA - Recuperador

REM ------------------------------------------------------------
REM  Auto-elevacion a Administrador (UAC)
REM  Usamos cmd /k para que la ventana elevada NO se cierre por
REM  si misma al terminar; asi el usuario puede leer el resultado.
REM ------------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
  echo.
  echo  Solicitando permisos de Administrador...
  echo  Aparecera una ventana de "Control de cuentas de usuario";
  echo  haga click en SI para continuar.
  echo.
  echo  Se abrira una nueva ventana negra: NO la cierre hasta
  echo  ver el mensaje final de recuperacion.
  echo.
  powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/k', '\"%~f0\"' -Verb RunAs"
  exit /b
)

REM A partir de aqui ya somos Administrador.
set "PENDRIVE_ROOT=%~dp0"
if "%PENDRIVE_ROOT:~-1%"=="\" set "PENDRIVE_ROOT=%PENDRIVE_ROOT:~0,-1%"

cls
echo.
echo  ============================================================
echo                  Sistema de Gestion de Llaves
echo                Facultad de Ciencias Economicas
echo                   RECUPERADOR - UDELAR v3.1
echo  ============================================================
echo.
echo   Este proceso repara la instalacion existente SIN borrar
echo   los datos productivos.
echo.
echo   Solo se restaura desde el pendrive si data.db esta
echo   irrecuperable, y en ese caso se hace backup previo.
echo.
echo  ============================================================
echo.

REM ------------------------------------------------------------
REM  Llamar al recuperador interno del pendrive
REM ------------------------------------------------------------
set "RECUP_INTERNO=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\recovery\RECUPERAR_v2.bat"
set "RECUP_LEGACY=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\recovery\RECUPERAR.bat"

if exist "%RECUP_INTERNO%" (
  call "%RECUP_INTERNO%"
  set "RECUP_EXIT=!ERRORLEVEL!"
) else if exist "%RECUP_LEGACY%" (
  echo  [AVISO] Usando script legado RECUPERAR.bat
  call "%RECUP_LEGACY%"
  set "RECUP_EXIT=!ERRORLEVEL!"
) else (
  echo  [ERROR] No se encontro el recuperador interno en el pendrive.
  echo          Rutas esperadas:
  echo          %RECUP_INTERNO%
  echo          %RECUP_LEGACY%
  echo.
  echo  Es posible que este pendrive este danado o sea de otra version.
  echo.
  echo  Presione una tecla para cerrar esta ventana.
  pause >nul
  exit /b 1
)

REM ------------------------------------------------------------
REM  Mensaje final del launcher (red de seguridad por si el
REM  recuperador interno cerro antes de su propio pause).
REM ------------------------------------------------------------
echo.
echo  ============================================================
if "!RECUP_EXIT!"=="0" (
  echo   [LISTO] Proceso de recuperacion finalizado.
) else (
  echo   [AVISO] El recuperador termino con codigo !RECUP_EXIT!.
  echo           Revise los mensajes anteriores para detalles.
)
echo  ============================================================
echo.
echo  Puede cerrar esta ventana cuando termine de leer.
echo  Presione cualquier tecla para salir...
pause >nul

endlocal
exit /b
