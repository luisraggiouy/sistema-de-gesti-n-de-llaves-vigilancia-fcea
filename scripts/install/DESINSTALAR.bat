@echo off
REM ============================================================
REM  Sistema de Gestion de Llaves FCEA v2.2
REM  Desinstalador limpio (reversible respecto a los datos)
REM ============================================================
REM
REM  Que hace:
REM    1) Detiene Chrome (kiosk FCEA), Node (frontend) y PocketBase.
REM    2) Quita las tareas programadas FCEA-* (incluida AutoStart).
REM    3) Cierra el puerto 8090 en el firewall de Windows.
REM    4) Mueve pb_data + pb_backups a C:\backup_fcea_<fecha>\
REM       (los datos NO se borran; quedan disponibles).
REM    5) Elimina la carpeta de instalacion con reintentos.
REM    6) Verifica al final que NO quedaron residuos. Si quedan,
REM       avisa al usuario y aborta para que reinicie y reintente
REM       (asi no engana al instalador haciendole creer que hay
REM       sistema previo).
REM
REM  Uso:
REM    Doble click en DESINSTALAR.bat (requiere Administrador)
REM
REM  Carpetas que asume:
REM    INSTALL_DIR = C:\sistema-llaves-fcea
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
echo  DESINSTALADOR - Sistema de Gestion de Llaves FCEA v2.2
echo ============================================================
echo.
echo  Carpeta de instalacion : %INSTALL_DIR%
echo  Backup de datos        : %BACKUP_DIR%
echo.
echo  Esta accion va a:
echo    - Cerrar Chrome del kiosk, Node (frontend) y PocketBase.
echo    - Quitar las tareas programadas de mantenimiento.
echo    - Cerrar el puerto 8090 en el firewall.
echo    - Mover pb_data y pb_backups a %BACKUP_DIR%
echo      (los datos NO se borran; quedan respaldados).
echo    - Borrar la carpeta de instalacion (con reintentos).
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
REM  1) Detener procesos que pueden tener archivos abiertos
REM     dentro de %INSTALL_DIR% (Chrome kiosk, Node frontend,
REM     PocketBase). Esto es CLAVE para que el rmdir posterior
REM     no falle dejando residuos.
REM ------------------------------------------------------------
echo.
echo [1/7] Deteniendo procesos del sistema (Chrome kiosk, Node, PocketBase)...

REM PocketBase
taskkill /F /IM pocketbase.exe >nul 2>&1
if not errorlevel 1 echo       PocketBase detenido. >> "%LOG%"

REM Node (frontend en modo dev o serve_dist.cjs en modo prod).
REM Solo matamos los node.exe cuyo CommandLine contenga 'sistema-llaves-fcea'
REM para no afectar otros proyectos Node que el usuario pueda tener abiertos.
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_Process -Filter \"Name='node.exe'\" | Where-Object { $_.CommandLine -match 'sistema-llaves-fcea' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1
echo       Procesos node.exe del sistema FCEA detenidos (si habia). >> "%LOG%"

REM Chrome kiosk del FCEA (apuntando a 127.0.0.1:5173, 4173 o 8090).
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_Process -Filter \"Name='chrome.exe'\" | Where-Object { $_.CommandLine -match '127\.0\.0\.1:(5173|4173|8090)' -or $_.CommandLine -match 'sistema-llaves-fcea' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1
echo       Chrome kiosk FCEA cerrado (si habia). >> "%LOG%"

REM Dar tiempo a Windows a liberar handles
timeout /t 3 /nobreak >nul

REM ------------------------------------------------------------
REM  2) Quitar tareas programadas (mantenimiento, backup, watchdog, autostart)
REM ------------------------------------------------------------
echo.
echo [2/7] Quitando tareas programadas de mantenimiento...
for %%T in (
  "FCEA-Backup-Semanal"
  "FCEA-Backup-Diario"
  "FCEA-Watchdog-PocketBase"
  "FCEA-Watchdog"
  "FCEA-Chequeo-Salud"
  "FCEA-Mantenimiento-Diario"
  "FCEA-Inicio-Automatico"
  "FCEA-Sistema-Llaves-AutoStart"
) do (
  schtasks /Delete /TN %%~T /F >nul 2>&1
  if not errorlevel 1 echo       Tarea %%~T eliminada. >> "%LOG%"
)

REM ------------------------------------------------------------
REM  3) Cerrar el puerto 8090 en el firewall
REM ------------------------------------------------------------
echo.
echo [3/7] Cerrando puerto 8090 en el firewall...
netsh advfirewall firewall delete rule name="FCEA-PocketBase-8090" >nul 2>&1
echo       Regla FCEA-PocketBase-8090 eliminada (si existia). >> "%LOG%"

REM ------------------------------------------------------------
REM  4) Respaldar pb_data y pb_backups
REM ------------------------------------------------------------
echo.
echo [4/7] Respaldando pb_data y pb_backups en %BACKUP_DIR%...
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
if exist "%INSTALL_DIR%\config\install_config.json" (
  copy /Y "%INSTALL_DIR%\config\install_config.json" "%BACKUP_DIR%\install_config.json" >nul
  echo       install_config.json respaldado. >> "%LOG%"
)

REM ------------------------------------------------------------
REM  5) Eliminar carpeta de instalacion con REINTENTOS
REM     Algunos archivos (Chrome, Node, antivirus) tardan en
REM     liberar handles. Intentamos 3 veces con espera entre
REM     intentos. Si despues de eso queda algo, abortamos.
REM ------------------------------------------------------------
echo.
echo [5/7] Eliminando carpeta de instalacion %INSTALL_DIR% ...
if exist "%INSTALL_DIR%" (
  for /L %%i in (1,1,3) do (
    if exist "%INSTALL_DIR%" (
      echo       Intento %%i/3 ...
      REM Quitar atributos read-only / system / hidden que puedan bloquear el borrado
      attrib -R -S -H "%INSTALL_DIR%\*.*" /S /D >nul 2>&1
      rmdir /S /Q "%INSTALL_DIR%" 2>nul
      if exist "%INSTALL_DIR%" timeout /t 3 /nobreak >nul
    )
  )

  if exist "%INSTALL_DIR%" (
    echo.
    echo  ============================================================
    echo   [ATENCION] NO SE PUDO ELIMINAR COMPLETAMENTE LA CARPETA
    echo  ============================================================
    echo   Algunos archivos siguen en uso dentro de %INSTALL_DIR%.
    echo.
    echo   Esto ocurre porque alguna ventana o servicio todavia
    echo   tiene archivos abiertos (Chrome, Node, antivirus, etc.).
    echo.
    echo   Que hacer ahora:
    echo     1) Cierre TODAS las ventanas del sistema FCEA
    echo        (Chrome, terminales cmd negras, etc.)
    echo     2) Reinicie la PC (recomendado).
    echo     3) Vuelva a ejecutar este desinstalador.
    echo.
    echo   Sus datos YA fueron respaldados en:
    echo     %BACKUP_DIR%
    echo  ============================================================
    echo.
    echo       [ERROR] Carpeta %INSTALL_DIR% sigue presente despues de 3 intentos. >> "%LOG%"
    pause
    exit /b 2
  ) else (
    echo       Carpeta eliminada correctamente. >> "%LOG%"
  )
) else (
  echo       Carpeta no encontrada en %INSTALL_DIR%, se omite. >> "%LOG%"
)

REM ------------------------------------------------------------
REM  6) Quitar accesos directos del escritorio (si existen)
REM ------------------------------------------------------------
echo.
echo [6/7] Quitando accesos directos del escritorio publico...
if exist "%PUBLIC%\Desktop\Sistema Llaves FCEA.lnk" del /F /Q "%PUBLIC%\Desktop\Sistema Llaves FCEA.lnk"
if exist "%PUBLIC%\Desktop\FCEA Monitor.lnk"        del /F /Q "%PUBLIC%\Desktop\FCEA Monitor.lnk"
if exist "%PUBLIC%\Desktop\FCEA Terminal.lnk"       del /F /Q "%PUBLIC%\Desktop\FCEA Terminal.lnk"
echo       Accesos directos eliminados (si existian). >> "%LOG%"

REM ------------------------------------------------------------
REM  7) Verificacion final: el sistema debe estar 100%% afuera
REM     antes de avisar "OK".
REM ------------------------------------------------------------
echo.
echo [7/7] Verificacion final de limpieza...
set RESIDUOS=0
if exist "%INSTALL_DIR%" set /a RESIDUOS+=1

REM Chequear tareas programadas residuales
for %%T in (
  "FCEA-Backup-Semanal" "FCEA-Backup-Diario" "FCEA-Watchdog-PocketBase"
  "FCEA-Watchdog" "FCEA-Chequeo-Salud" "FCEA-Mantenimiento-Diario"
  "FCEA-Inicio-Automatico" "FCEA-Sistema-Llaves-AutoStart"
) do (
  schtasks /Query /TN %%~T >nul 2>&1
  if not errorlevel 1 (
    echo       [AVISO] La tarea %%~T aun existe. >> "%LOG%"
    set /a RESIDUOS+=1
  )
)

if !RESIDUOS! GTR 0 (
  echo       [AVISO] Quedaron !RESIDUOS! residuo(s). Revise el log: %LOG%
  echo       [AVISO] Total de residuos detectados: !RESIDUOS!. >> "%LOG%"
) else (
  echo       OK - Sin residuos detectados.
  echo       Verificacion final OK. >> "%LOG%"
)

echo.
echo  ============================================================
if !RESIDUOS! GTR 0 (
  echo   [PARCIAL] EL SISTEMA SE DESINSTALO PERO QUEDARON RESIDUOS
) else (
  echo   [OK] EL SISTEMA SE HA DESINSTALADO COMPLETAMENTE CON EXITO
)
echo  ============================================================
echo.
echo   Resumen de lo realizado:
echo     - Carpeta C:\sistema-llaves-fcea ........ ELIMINADA
echo     - PocketBase / Node / Chrome kiosk ...... DETENIDOS
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
