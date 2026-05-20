@echo off
REM Restaurar pb_data desde el backup del pendrive (carpeta hermana backup_pb_data\)
setlocal

REM El pendrive raiz es la carpeta padre de este script (scripts\)
set PENDRIVE_ROOT=%~dp0..
set BACKUP=%PENDRIVE_ROOT%\backup_pb_data

if not exist "%BACKUP%" (
  echo [ERROR] No se encontro el backup en %BACKUP%
  echo Este pendrive parece no contener un respaldo.
  exit /b 1
)

echo.
echo Pendrive root  : %PENDRIVE_ROOT%
echo Backup en      : %BACKUP%
echo.
echo Ingrese la ruta a la instalacion del sistema (donde esta pocketbase\):
set /p REPO_DEST="(ej. C:\sistema-llaves-fcea): "

if not exist "%REPO_DEST%\pocketbase" (
  echo [ERROR] No se encuentra pocketbase\ en %REPO_DEST%
  exit /b 1
)

REM Respaldo de seguridad antes de pisar pb_data
set STAMP=%DATE:/=-%_%TIME::=-%
set STAMP=%STAMP: =0%
set SAFE=%REPO_DEST%\respaldo_pre_restauracion\%STAMP%
echo.
echo Creando respaldo de seguridad en %SAFE% ...
mkdir "%SAFE%" 2>nul
if exist "%REPO_DEST%\pocketbase\pb_data" (
  xcopy "%REPO_DEST%\pocketbase\pb_data" "%SAFE%\pb_data\" /E /I /Q /Y >nul
  echo OK - pb_data actual respaldado.
)

echo.
echo Restaurando backup desde %BACKUP% ...
xcopy "%BACKUP%" "%REPO_DEST%\pocketbase\pb_data\" /E /I /Q /Y
if errorlevel 1 (
  echo [ERROR] Fallo la restauracion.
  exit /b 1
)

echo.
echo [OK] Base restaurada. Reinicie PocketBase para que tome el cambio.
endlocal
