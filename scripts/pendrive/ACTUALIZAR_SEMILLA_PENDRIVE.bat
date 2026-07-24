@echo off
REM ============================================================
REM  Sistema FCEA - ACTUALIZAR SEMILLA DEL PENDRIVE
REM ============================================================
REM  Refresca los datos-semilla del pendrive con la base productiva
REM  actual del Monitor Vigilancia. Ejecutar en el Monitor
REM  Vigilancia con el pendrive enchufado.
REM
REM  SOLO copia datos hacia el pendrive. Nunca borra ni modifica
REM  la base productiva C:\ProgramData\FCEA-Sistema-Llaves\pb_data\
REM ============================================================

setlocal EnableDelayedExpansion
title Sistema FCEA - Actualizar Semilla del Pendrive

REM --- Elevacion UAC ---
net session >nul 2>&1
if errorlevel 1 (
  echo.
  echo  Solicitando permisos de Administrador...
  echo  Aparecera una ventana de Control de Cuentas de Usuario;
  echo  haga click en SI para continuar.
  echo.
  powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/k', '\"%~f0\"' -Verb RunAs"
  exit /b
)

pushd "%~dp0" 2>nul
set "PENDRIVE_ROOT=%~dp0"
if "%PENDRIVE_ROOT:~-1%"=="\" set "PENDRIVE_ROOT=%PENDRIVE_ROOT:~0,-1%"

cls
echo.
echo  ============================================================
echo               Sistema de Gestion de Llaves FCEA
echo           ACTUALIZAR SEMILLA DEL PENDRIVE (backup portable)
echo  ============================================================
echo.
echo   Este proceso copia la base de datos productiva actual
echo   del Monitor Vigilancia al pendrive. El pendrive queda
echo   con la foto mas reciente de:
echo.
echo     - Todas las llaves (150 + las que se agregaron despues)
echo     - Todos los usuarios registrados
echo     - Vigilantes, turnos, autorizaciones
echo     - Objetos hallados
echo     - Historial de entregas/devoluciones
echo.
echo   IMPORTANTE:
echo     - Ejecutar SOLO en la PC Monitor Vigilancia.
echo     - El pendrive debe ser el pendrive del sistema FCEA.
echo     - PocketBase se detendra 5 segundos y se reanudara solo.
echo     - Duracion aproximada: 30 a 60 segundos.
echo.
echo  ============================================================
echo.
set /p "OP=Continuar? [S/N]: "
if /i not "%OP%"=="S" (
  echo.
  echo  Operacion cancelada por el usuario.
  echo.
  pause
  exit /b 0
)

set "PS_SCRIPT=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\pendrive\actualizar_semilla.ps1"
if not exist "%PS_SCRIPT%" (
  echo.
  echo  [ERROR] No se encontro el script:
  echo          %PS_SCRIPT%
  echo.
  echo  El pendrive no contiene la version 5.1 o superior del sistema.
  echo  Actualice el pendrive con el instalador mas reciente.
  echo.
  pause
  exit /b 1
)

echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -PendriveRoot "%PENDRIVE_ROOT%"
set "PS_EXIT=%ERRORLEVEL%"

echo.
if not "%PS_EXIT%"=="0" (
  echo  ============================================================
  echo  [ERROR] La actualizacion fallo con codigo %PS_EXIT%
  echo  ============================================================
  echo.
  echo  Revise el mensaje de error mas arriba y consulte
  echo  PLAYBOOK_MANTENIMIENTO.md
  echo.
  pause
  exit /b %PS_EXIT%
)

echo  ============================================================
echo  [LISTO] Pendrive actualizado.
echo  ============================================================
echo.
echo  Ya puede desenchufar el pendrive con seguridad.
echo  Guardelo en un lugar seguro (caja fuerte / cajon con llave).
echo.
pause
exit /b 0
