@echo off
REM ============================================================
REM Sistema de Gestion de Llaves FCEA - Servidor PocketBase
REM ============================================================
REM Arranca PocketBase escuchando en TODAS las interfaces de red
REM (0.0.0.0:8090) para que las 2 terminales de usuarios puedan
REM conectarse desde otras PCs por la red local cerrada.
REM
REM Esta PC (cabina de vigilancia) actua como SERVIDOR ademas
REM de monitor. Las terminales A y B le apuntan via config.json.
REM ============================================================
REM
REM  FIX 2026-07-24:
REM    --dir apunta a la carpeta PERSISTENTE en ProgramData.
REM    Antes usaba ruta relativa "pb_data" que caia dentro de
REM    C:\sistema-llaves-fcea\pocketbase\ (carpeta que se borra
REM    en cada reinstalacion). Los datos productivos quedaban
REM    atrapados alli y se perdian.
REM ============================================================

setlocal
cd /d "%~dp0"

set "PB_DATA_DIR=C:\ProgramData\FCEA-Sistema-Llaves\pb_data"
if not exist "%PB_DATA_DIR%" mkdir "%PB_DATA_DIR%"

echo.
echo ============================================================
echo  Sistema de Gestion de Llaves FCEA v2.0
echo  Servidor PocketBase (rol: monitor + servidor)
echo ============================================================
echo.
echo  Escuchando en: http://0.0.0.0:8090
echo  Admin panel  : http://127.0.0.1:8090/_/
echo  Datos en     : %PB_DATA_DIR%
echo.
echo  Las terminales remotas deben apuntar a:
echo    http://%COMPUTERNAME%:8090   o
echo    http://[IP-DE-ESTA-PC]:8090
echo.
echo  Para detener el servidor: cerrar esta ventana o Ctrl+C
echo ============================================================
echo.

REM --http=0.0.0.0:8090            -> escucha en todas las interfaces
REM --dir="C:\ProgramData\..."     -> carpeta PERSISTENTE (fuera de la instalacion)
REM --migrationsDir=pb_migrations  -> carpeta de migraciones (dentro de la instalacion, OK)
pocketbase.exe serve --http=0.0.0.0:8090 --dir="%PB_DATA_DIR%" --migrationsDir=pb_migrations

if errorlevel 1 (
  echo.
  echo [ERROR] PocketBase termino con codigo de error %errorlevel%.
  echo Revise los logs en %PB_DATA_DIR%\logs.db
  pause
)

endlocal
