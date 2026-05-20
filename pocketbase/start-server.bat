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

setlocal
cd /d "%~dp0"

echo.
echo ============================================================
echo  Sistema de Gestion de Llaves FCEA v2.0
echo  Servidor PocketBase (rol: monitor + servidor)
echo ============================================================
echo.
echo  Escuchando en: http://0.0.0.0:8090
echo  Admin panel  : http://127.0.0.1:8090/_/
echo.
echo  Las terminales remotas deben apuntar a:
echo    http://%COMPUTERNAME%:8090   o
echo    http://[IP-DE-ESTA-PC]:8090
echo.
echo  Para detener el servidor: cerrar esta ventana o Ctrl+C
echo ============================================================
echo.

REM --http=0.0.0.0:8090  → escucha en todas las interfaces
REM --dir=pb_data        → carpeta de datos (relativo al .exe)
REM --migrationsDir=pb_migrations → carpeta de migraciones
pocketbase.exe serve --http=0.0.0.0:8090 --dir=pb_data --migrationsDir=pb_migrations

if errorlevel 1 (
  echo.
  echo [ERROR] PocketBase termino con codigo de error %errorlevel%.
  echo Revisa los logs en pb_data\logs.db
  pause
)

endlocal
