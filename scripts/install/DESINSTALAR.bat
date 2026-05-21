@echo off
REM ============================================================
REM  Sistema de Gestion de Llaves FCEA v2.0
REM  Desinstalador limpio (reversible respecto a los datos)
REM ============================================================
REM
REM  Que hace:
REM    1) Detiene PocketBase y servicios/tareas relacionados.
REM    2) Cierra el puerto 8090 en el firewall de Windows.
REM    3) Quita las tareas programadas de mantenimiento.
REM    4) Mueve pb_data + pb_backups a C:\backup_fcea_<fecha>\
REM       (los datos NO se borran; quedan disponibles).
REM    5) Elimina la carpeta de instalacion.
REM
REM  Uso:
REM    Doble click en DESINSTALAR.bat (requiere Administrador)
REM
REM  Carpetas que asume:
REM    INSTALL_DIR = C:\sistema-llaves-fcea
REM  Si su instalacion esta en otra ruta, edite la variable
REM  INSTALL_DIR mas abajo antes de ejecutar.
REM ============================================================

setlocal EnableDelayedExpansion

REM ------------------------------------------------------------
REM  Verificar privilegios de administrador
REM ------------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
  echo.
  echo [ERROR] Este desinstalador requiere privilegios de Administrador.
  echo Haga click derecho sobre DESINSTALAR.bat y elija "Ejecutar como administrador".
  echo.
  pause
  exit /b 1
)

REM ------------------------------------------------------------
REM  Parametros
REM ------------------------------------------------------------
set INSTALL_DIR=C:\sistema-llaves-fcea
set STAMP=%date:~6,4%-%date:~3,2%-%date:~0,2%_%time:~0,2%-%time:~3,2%
set STAMP=%STAMP: =0%
set BACKUP_DIR=C:\backup_fcea_%STAMP%
set LOG=%BACKUP_DIR%\desinstalacion.log

echo.
echo ============================================================
echo  DESINSTALADOR - Sistema de Gestion de Llaves FCEA v2.0
echo ============================================================
echo.
echo  Carpeta de instalacion : %INSTALL_DIR%
echo  Backup de datos        : %BACKUP_DIR%
echo.
echo  Esta accion va a:
echo    - Detener PocketBase.
echo    - Quitar las tareas programadas de mantenimiento.
echo    - Cerrar el puerto 8090 en el firewall.
echo    - Mover pb_data y pb_backups a %BACKUP_DIR%
echo      (los datos NO se borran; quedan respaldados).
echo    - Borrar la carpeta de instalacion.
echo.
echo ============================================================
set /p CONFIRM="Confirma la desinstalacion? Escriba SI para continuar: "
if /i not "%CONFIRM%"=="SI" (
  echo Cancelado por el usuario.
  pause
  exit /b 0
)

REM ------------------------------------------------------------
REM  Crear carpeta de backup
REM ------------------------------------------------------------
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
echo === Desinstalacion FCEA - %date% %time% === > "%LOG%"

REM ------------------------------------------------------------
REM  1) Detener PocketBase
REM ------------------------------------------------------------
echo.
echo [1/6] Deteniendo PocketBase...
taskkill /F /IM pocketbase.exe >nul 2>&1
if errorlevel 1 (
  echo       PocketBase no estaba ejecutandose. >> "%LOG%"
) else (
  echo       PocketBase detenido. >> "%LOG%"
)

REM ------------------------------------------------------------
REM  2) Quitar tareas programadas (mantenimiento, backup, watchdog)
REM ------------------------------------------------------------
echo.
echo [2/6] Quitando tareas programadas de mantenimiento...
for %%T in (
  "FCEA-Backup-Semanal"
  "FCEA-Watchdog-PocketBase"
  "FCEA-Chequeo-Salud"
  "FCEA-Mantenimiento-Diario"
  "FCEA-Inicio-Automatico"
) do (
  schtasks /Delete /TN %%~T /F >nul 2>&1
  if not errorlevel 1 echo       Tarea %%~T eliminada. >> "%LOG%"
)

REM ------------------------------------------------------------
REM  3) Cerrar el puerto 8090 en el firewall
REM ------------------------------------------------------------
echo.
echo [3/6] Cerrando puerto 8090 en el firewall...
netsh advfirewall firewall delete rule name="FCEA-PocketBase-8090" >nul 2>&1
echo       Regla FCEA-PocketBase-8090 eliminada (si existia). >> "%LOG%"

REM ------------------------------------------------------------
REM  4) Respaldar pb_data y pb_backups
REM ------------------------------------------------------------
echo.
echo [4/6] Respaldando pb_data y pb_backups en %BACKUP_DIR%...
if exist "%INSTALL_DIR%\pocketbase\pb_data" (
  robocopy "%INSTALL_DIR%\pocketbase\pb_data" "%BACKUP_DIR%\pb_data" /MIR /NFL /NDL /NJH /NJS /NP >nul
  echo       pb_data respaldado. >> "%LOG%"
) else (
  echo       pb_data no encontrado, se omite. >> "%LOG%"
)

if exist "%INSTALL_DIR%\pocketbase\pb_backups" (
  robocopy "%INSTALL_DIR%\pocketbase\pb_backups" "%BACKUP_DIR%\pb_backups" /MIR /NFL /NDL /NJH /NJS /NP >nul
  echo       pb_backups respaldado. >> "%LOG%"
) else (
  echo       pb_backups no encontrado, se omite. >> "%LOG%"
)

REM Conservar tambien la configuracion actual (public/config.json) por si se reinstala
if exist "%INSTALL_DIR%\public\config.json" (
  copy /Y "%INSTALL_DIR%\public\config.json" "%BACKUP_DIR%\config.json" >nul
  echo       config.json respaldado. >> "%LOG%"
)

REM ------------------------------------------------------------
REM  5) Eliminar carpeta de instalacion
REM ------------------------------------------------------------
echo.
echo [5/6] Eliminando carpeta de instalacion %INSTALL_DIR% ...
if exist "%INSTALL_DIR%" (
  rmdir /S /Q "%INSTALL_DIR%"
  if exist "%INSTALL_DIR%" (
    echo       [ADVERTENCIA] Algunos archivos no pudieron eliminarse. >> "%LOG%"
    echo       Es posible que haya archivos en uso. Cierre los programas y reintente.
  ) else (
    echo       Carpeta eliminada. >> "%LOG%"
  )
) else (
  echo       Carpeta no encontrada en %INSTALL_DIR%, se omite. >> "%LOG%"
)

REM ------------------------------------------------------------
REM  6) Quitar accesos directos del escritorio (si existen)
REM ------------------------------------------------------------
echo.
echo [6/6] Quitando accesos directos del escritorio publico...
if exist "%PUBLIC%\Desktop\Sistema Llaves FCEA.lnk" del /F /Q "%PUBLIC%\Desktop\Sistema Llaves FCEA.lnk"
if exist "%PUBLIC%\Desktop\FCEA Monitor.lnk"        del /F /Q "%PUBLIC%\Desktop\FCEA Monitor.lnk"
if exist "%PUBLIC%\Desktop\FCEA Terminal.lnk"       del /F /Q "%PUBLIC%\Desktop\FCEA Terminal.lnk"
echo       Accesos directos eliminados (si existian). >> "%LOG%"

echo.
echo  ============================================================
echo   [OK] EL SISTEMA SE HA DESINSTALADO COMPLETAMENTE CON EXITO
echo  ============================================================
echo.
echo   Resumen de lo realizado:
echo     - Carpeta C:\sistema-llaves-fcea ........ ELIMINADA
echo     - PocketBase ............................ DETENIDO
echo     - Tareas programadas FCEA-* ............. ELIMINADAS
echo     - Regla firewall puerto 8090 ............ ELIMINADA
echo     - Accesos directos del escritorio ....... ELIMINADOS
echo.
echo   Sus datos NO se borraron, estan respaldados en:
echo     %BACKUP_DIR%
echo.
echo   Log detallado de la desinstalacion:
echo     %LOG%
echo.
echo   ------------------------------------------------------------
echo   COMO REINSTALAR MAS ADELANTE
echo   ------------------------------------------------------------
echo   1) Ejecute INSTALAR_SISTEMA.bat desde el pendrive.
echo   2) El instalador detectara el backup automaticamente y
echo      restaurara TODOS los datos (llaves, usuarios, vigilantes,
echo      autorizaciones, objetos olvidados, historial).
echo.
echo   Si NO desea conservar los datos respaldados, borre a mano
echo   la carpeta:
echo     %BACKUP_DIR%
echo.
echo  ============================================================
echo.
echo  Presione cualquier tecla para cerrar esta ventana.
pause >nul
endlocal
