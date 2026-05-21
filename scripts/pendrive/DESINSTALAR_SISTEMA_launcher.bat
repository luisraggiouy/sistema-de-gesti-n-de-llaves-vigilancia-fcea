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
REM ------------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
  echo.
  echo  Solicitando permisos de Administrador...
  echo  Aparecera una ventana de "Control de cuentas de usuario";
  echo  haga click en SI para continuar.
  echo.
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
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

if exist "%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\install\DESINSTALAR.bat" (
  call "%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\install\DESINSTALAR.bat"
) else (
  echo  [ERROR] No se encontro el desinstalador interno en el pendrive.
  echo          Ruta esperada:
  echo          %PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\install\DESINSTALAR.bat
  echo.
  echo  Es posible que este pendrive este danado o sea de otra version.
  echo.
  pause
  exit /b 1
)

endlocal
