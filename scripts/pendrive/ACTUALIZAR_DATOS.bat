@echo off
REM ============================================================
REM  Sistema de Gestion de Llaves FCEA v2.0
REM  ACTUALIZAR_DATOS.bat - Refresco semanal del pendrive instalador
REM ============================================================
REM
REM  Este script copia el pb_data actual de la PC al pendrive,
REM  sin tocar el codigo fuente ni Node.js portable. Tiempo
REM  estimado: 30 segundos.
REM
REM  USO RECOMENDADO: cada lunes, despues del backup automatico.
REM ============================================================

setlocal EnableDelayedExpansion

echo.
echo ============================================================
echo  ACTUALIZAR DATOS - Pendrive Instalador FCEA
echo ============================================================
echo.

REM ----- Detectar letra del pendrive (donde esta este script) -----
set "DRIVE=%~d0"
echo Pendrive detectado en: %DRIVE%

REM ----- Verificar que el pendrive sea instalador -----
if not exist "%DRIVE%\sistema-llaves-fcea\pocketbase" (
  echo.
  echo [ERROR] Este pendrive no es un instalador FCEA valido.
  echo         No se encontro sistema-llaves-fcea\pocketbase\
  echo.
  pause
  exit /b 1
)

REM ----- Verificar privilegios de administrador -----
net session >nul 2>&1
if errorlevel 1 (
  echo [ADVERTENCIA] No se esta ejecutando como administrador.
  echo                Puede que no se pueda detener PocketBase.
  echo                Click derecho -^> "Ejecutar como administrador" recomendado.
  echo.
  timeout /t 3 >nul
)

REM ----- Buscar la instalacion productiva en C: -----
set "FUENTE_PB_DATA="
if exist "C:\sistema-llaves-fcea\pocketbase\pb_data\data.db" (
  set "FUENTE_PB_DATA=C:\sistema-llaves-fcea\pocketbase\pb_data"
)
if exist "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase\pb_data\data.db" (
  set "FUENTE_PB_DATA=C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase\pb_data"
)

if "%FUENTE_PB_DATA%"=="" (
  echo.
  echo [ERROR] No se encontro una instalacion FCEA productiva en esta PC.
  echo         Rutas buscadas:
  echo           C:\sistema-llaves-fcea\pocketbase\pb_data
  echo           C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase\pb_data
  echo.
  echo Si la instalacion esta en otra ruta, edite manualmente este script
  echo o ejecute desde PowerShell:
  echo   .\scripts\pendrive\crear_pendrive.ps1 -Drive %DRIVE% -Tipo actualizar-datos -PbDataPath ^<ruta^>
  echo.
  pause
  exit /b 1
)

echo Fuente de datos detectada: %FUENTE_PB_DATA%
echo.

REM ----- Llamar al script PowerShell que hace el trabajo real -----
set "PS_SCRIPT=%DRIVE%\sistema-llaves-fcea\scripts\pendrive\crear_pendrive.ps1"
if not exist "%PS_SCRIPT%" (
  echo [ERROR] No se encontro %PS_SCRIPT%
  pause
  exit /b 1
)

echo Iniciando refresco de datos...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -Drive "%DRIVE%" -Tipo actualizar-datos -PbDataPath "%FUENTE_PB_DATA%"

if errorlevel 1 (
  echo.
  echo [ERROR] La actualizacion fallo. Revise los mensajes anteriores.
  pause
  exit /b 1
)

echo.
echo ============================================================
echo  Actualizacion completada exitosamente.
echo  Verifique la fecha en ULTIMO_BACKUP.txt del pendrive.
echo ============================================================
echo.
pause
endlocal
