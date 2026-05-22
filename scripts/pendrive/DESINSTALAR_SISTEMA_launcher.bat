@echo off
REM ============================================================
REM  Sistema de Gestion de Llaves FCEA - DESINSTALADOR SIMPLE
REM ============================================================
REM  Doble click para desinstalar el sistema.
REM  Se pedira automaticamente permiso de administrador (UAC).
REM
REM  Los datos quedan respaldados automaticamente en:
REM    C:\backup_fcea_<fecha>\
REM ============================================================

setlocal EnableDelayedExpansion
title Sistema FCEA - Desinstalador

REM ------------------------------------------------------------
REM  Auto-elevacion a Administrador (UAC)
REM  IMPORTANTE: usamos cmd /k para que la ventana elevada NO se
REM  cierre por si misma al terminar; asi el usuario puede leer
REM  el resultado y confirmar la desinstalacion.
REM ------------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
  echo.
  echo  Solicitando permisos de Administrador...
  echo  Aparecera una ventana de "Control de cuentas de usuario";
  echo  haga click en SI para continuar.
  echo.
  echo  Se abrira una nueva ventana negra: NO la cierre hasta
  echo  ver el mensaje final de desinstalacion.
  echo.
  REM Lanzamos una nueva instancia de cmd elevada con /k (no cierra al terminar).
  REM Pasamos la ruta de este .bat como argumento entre comillas para soportar
  REM rutas con espacios.
  powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/k', '\"%~f0\"' -Verb RunAs"
  REM Esta ventana original (no elevada) se cierra sola; la elevada queda abierta.
  exit /b
)

REM A partir de aqui ya somos Administrador.
set "PENDRIVE_ROOT=%~dp0"
if "%PENDRIVE_ROOT:~-1%"=="\" set "PENDRIVE_ROOT=%PENDRIVE_ROOT:~0,-1%"

REM ------------------------------------------------------------
REM  Llamar al desinstalador interno del pendrive
REM ------------------------------------------------------------
cls
echo.
echo  ============================================================
echo                  Sistema de Gestion de Llaves
echo                Facultad de Ciencias Economicas
echo                  DESINSTALADOR - UDELAR v2.0
echo  ============================================================
echo.

set "DESINST_INTERNO=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\install\DESINSTALAR.bat"

if exist "%DESINST_INTERNO%" (
  call "%DESINST_INTERNO%"
  set "DESINST_EXIT=!ERRORLEVEL!"
) else (
  echo  [ERROR] No se encontro el desinstalador interno en el pendrive.
  echo          Ruta esperada:
  echo          %DESINST_INTERNO%
  echo.
  echo  Es posible que este pendrive este danado o sea de otra version.
  echo.
  echo  Presione una tecla para cerrar esta ventana.
  pause >nul
  exit /b 1
)

REM ------------------------------------------------------------
REM  Mensaje final del launcher (red de seguridad por si el
REM  desinstalador interno cerro algo antes de su propio pause).
REM ------------------------------------------------------------
echo.
echo  ============================================================
if "!DESINST_EXIT!"=="0" (
  echo   [LISTO] Proceso de desinstalacion finalizado.
) else (
  echo   [AVISO] El desinstalador termino con codigo !DESINST_EXIT!.
  echo           Revise los mensajes anteriores para detalles.
)
echo  ============================================================
echo.
echo  Puede cerrar esta ventana cuando termine de leer.
echo  Presione cualquier tecla para salir...
pause >nul

endlocal
exit /b
