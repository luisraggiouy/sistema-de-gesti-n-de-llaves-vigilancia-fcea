@echo off
REM ============================================================
REM  Sistema de Gestion de Llaves FCEA v2.1
REM  Instalador unificado con deteccion de hardware
REM ============================================================
REM
REM  Modos de instalacion:
REM    1) Desarrollo / Demo (1 PC con monitor + terminal alternables)
REM    2) Economica         (3 PCs con teclado + mouse + monitor LCD)
REM    3) Mixta             (cabina tactil + 2 terminales con teclado/mouse)
REM    4) Ideal             (3 PCs con monitores tactiles)
REM
REM  Novedades v2.1:
REM    - Detecta y guarda el tipo de hardware ("tactil" / "tradicional" /
REM      "desarrollo") usando scripts/lib/detectar_hardware.ps1
REM    - Persiste install_config.json en C:\sistema-llaves-fcea\config\
REM    - Sincroniza la configuracion con PocketBase (coleccion sistema_config)
REM    - El frontend usa el campo "hardware" para mostrar/ocultar el boton
REM      Dashboard (oculto en kiosks tactiles, visible en PCs tradicionales)
REM
REM  Caracteristicas DRP existentes:
REM    - Detecta y usa Node.js portable del pendrive si no hay Node.js
REM      instalado en el sistema.
REM    - Restaura automaticamente pb_data y pb_backups si vienen en el
REM      pendrive (escenario de recuperacion ante desastres).
REM ============================================================

setlocal EnableDelayedExpansion
cd /d "%~dp0\..\.."

REM Guardar la ruta del pendrive (raiz del lanzador externo)
set "PENDRIVE_ROOT=%~dp0..\..\.."
if exist "%PENDRIVE_ROOT%\LEEME.txt" (
  set "DESDE_PENDRIVE=1"
) else (
  set "DESDE_PENDRIVE=0"
)

REM Localizar las librerias compartidas para invocarlas desde PowerShell
set "REPO_ROOT=%~dp0..\.."
set "LIB_DETECT=%REPO_ROOT%\scripts\lib\detectar_hardware.ps1"
set "LIB_CFGIO=%REPO_ROOT%\scripts\lib\install_config_io.ps1"
set "LIB_PERSIST=%REPO_ROOT%\scripts\lib\persistir_install_config.ps1"

echo.
echo ============================================================
echo  INSTALADOR DRP - Sistema de Gestion de Llaves FCEA v2.1
echo ============================================================
echo.

REM ----- Verificar Node.js: si no esta instalado, usar el portable del pendrive -----
where npm >nul 2>nul
if errorlevel 1 (
  echo [INFO] Node.js no encontrado en el sistema.
  if exist "%PENDRIVE_ROOT%\node-portable\node\node.exe" (
    echo        Usando Node.js portable del pendrive.
    set "PATH=%PENDRIVE_ROOT%\node-portable\node;%PATH%"
  ) else (
    echo [ERROR] Node.js no esta instalado y el pendrive no contiene
    echo         Node.js portable.
    echo         Instale Node.js LTS desde https://nodejs.org y vuelva a ejecutar.
    echo.
    pause
    exit /b 1
  )
)

REM Verificar que npm ahora si responde
where npm >nul 2>nul
if errorlevel 1 (
  echo [ERROR] npm sigue sin estar disponible despues de configurar el PATH.
  pause
  exit /b 1
)

REM ----- Si las variables FCEA_MODO/FCEA_ROL ya vienen seteadas
REM       (caso: el lanzador del pendrive ya pregunto), saltamos
REM       directo al modo correspondiente sin volver a preguntar.
if defined FCEA_MODO (
  echo  [Lanzador] Usando configuracion ya elegida: modo=%FCEA_MODO% rol=%FCEA_ROL% hw=%FCEA_HW%
  if /i "%FCEA_MODO%"=="desarrollo" goto MODO_DESARROLLO_AUTO
  if /i "%FCEA_MODO%"=="produccion" goto MODO_PRODUCCION_AUTO
)

echo.
echo  Modos de instalacion disponibles:
echo.
echo    [1] DESARROLLO / DEMO (1 PC con todo)
echo    [2] PRODUCCION (3 PCs con autodeteccion de rol y hardware)
echo.
echo ============================================================
set /p MODO="Seleccione modo [1-2]: "

if "%MODO%"=="1" goto MODO_DESARROLLO
if "%MODO%"=="2" goto MODO_PRODUCCION_MANUAL
echo Opcion invalida. Abortando.
exit /b 1

REM ============================================================
REM  MODO_PRODUCCION_MANUAL: invocado cuando se ejecuta INSTALAR.bat
REM  directamente (no desde el launcher del pendrive). Llama al
REM  autodetector y luego cae en MODO_PRODUCCION_AUTO.
REM ============================================================
:MODO_PRODUCCION_MANUAL
echo.
echo === MODO PRODUCCION seleccionado ===
echo.
echo  Detectando rol y hardware automaticamente...
set "DETECTOR=%REPO_ROOT%\scripts\lib\autodetectar_rol.ps1"
if exist "%DETECTOR%" (
  for /f "delims=" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%DETECTOR%"') do set "AUTODETEC=%%i"
  for /f "tokens=1,2,3 delims=|" %%a in ("!AUTODETEC!") do (
    set "FCEA_ROL=%%a"
    set "FCEA_HW=%%b"
    set "FCEA_IP_SERVIDOR=%%c"
  )
  set "FCEA_MODO=produccion"
  echo  Autodeteccion: rol=!FCEA_ROL!  hw=!FCEA_HW!  servidor=!FCEA_IP_SERVIDOR!
)
goto MODO_PRODUCCION_AUTO

REM ============================================================
REM  MODO_DESARROLLO_AUTO: invocado por el lanzador del pendrive
REM ============================================================
:MODO_DESARROLLO_AUTO
set "MODO=1"
goto MODO_DESARROLLO

REM ============================================================
REM  MODO_PRODUCCION_AUTO: invocado por el lanzador del pendrive
REM  Decide modo 2/3/4 a partir de FCEA_HW.
REM ============================================================
:MODO_PRODUCCION_AUTO
if /i "%FCEA_HW%"=="tactil"      set "MODO=4"
if /i "%FCEA_HW%"=="tradicional" set "MODO=2"
if not defined MODO set "MODO=2"
set "ROL_AUTO=1"
if /i "%FCEA_ROL%"=="monitor"    set "ROL=S"
if /i "%FCEA_ROL%"=="terminal-a" set "ROL=A"
if /i "%FCEA_ROL%"=="terminal-b" set "ROL=B"
if /i "%FCEA_ROL%"=="dashboard"  set "ROL=D"
if defined FCEA_IP_SERVIDOR ( set "IP_SERVIDOR=%FCEA_IP_SERVIDOR%" ) else ( set "IP_SERVIDOR=127.0.0.1" )
if "%MODO%"=="2" goto MODO_ECONOMICA_AUTO
if "%MODO%"=="3" goto MODO_MIXTA_AUTO
if "%MODO%"=="4" goto MODO_IDEAL_AUTO
goto MODO_ECONOMICA_AUTO

:MODO_ECONOMICA_AUTO
set FORZAR_TECLADO=false
set "MODO_HW_DEFAULT=tradicional"
goto SELECCIONAR_ROL

:MODO_MIXTA_AUTO
set FORZAR_TECLADO=auto
set "MODO_HW_DEFAULT=mixto"
goto SELECCIONAR_ROL

:MODO_IDEAL_AUTO
set FORZAR_TECLADO=auto
set "MODO_HW_DEFAULT=tactil"
goto SELECCIONAR_ROL

REM ============================================================
REM  MODO 1: DESARROLLO / DEMO (1 PC)
REM ============================================================
:MODO_DESARROLLO
echo.
echo === MODO DESARROLLO seleccionado ===
echo.
set "HW_TIPO=desarrollo"
call :ESCRIBIR_CONFIG "desarrollo" "monitor" "127.0.0.1" "127.0.0.1" "127.0.0.1" "false" "%HW_TIPO%"
call :PERSISTIR_INSTALL_CONFIG "desarrollo" "%HW_TIPO%"
call :INSTALAR_DEPENDENCIAS
call :CONFIGURAR_SERVIDOR_LOCAL
call :RESTAURAR_DATOS_PENDRIVE
echo.
echo  Modo desarrollo instalado.
echo  - PocketBase en  : http://127.0.0.1:8090
echo  - Frontend en    : http://127.0.0.1:5173 ^(npm run dev^)
echo                     o http://127.0.0.1:4173 ^(npm run preview^)
echo.
echo  En la UI veras un boton para alternar Monitor / Terminal
echo  y el boton "Dashboard" visible (hardware="desarrollo").
goto FIN

REM ============================================================
REM  MODO 2, 3, 4: PRODUCCION (3 PCs)
REM ============================================================
:MODO_ECONOMICA
echo.
echo === MODO PRODUCCION ECONOMICA seleccionado ===
set FORZAR_TECLADO=false
set "MODO_HW_DEFAULT=tradicional"
goto SELECCIONAR_ROL

:MODO_MIXTA
echo.
echo === MODO PRODUCCION MIXTA seleccionado ===
REM En este modo solo la cabina tiene tactil. Cada PC define su propio
REM teclado_virtual_forzado segun sea cabina o terminal.
set FORZAR_TECLADO=auto
set "MODO_HW_DEFAULT=mixto"
goto SELECCIONAR_ROL

:MODO_IDEAL
echo.
echo === MODO PRODUCCION IDEAL seleccionado ===
REM En las 3 PCs se asume monitor tactil; no se fuerza nada,
REM la deteccion automatica con pointer:coarse lo activa solo.
set FORZAR_TECLADO=auto
set "MODO_HW_DEFAULT=tactil"
goto SELECCIONAR_ROL

:SELECCIONAR_ROL
REM Si ROL_AUTO esta seteado por el lanzador, saltar las preguntas
if defined ROL_AUTO goto ROL_YA_DEFINIDO

echo.
echo  Esta PC sera:
echo    [S] SERVIDOR + MONITOR DE VIGILANCIA (cabina, 16 GB RAM)
echo    [A] TERMINAL-A (puesto usuarios A)
echo    [B] TERMINAL-B (puesto usuarios B)
echo    [D] DASHBOARD  (opcional, PC de reportes)
echo.
set /p ROL="Rol [S/A/B/D]: "

set IP_SERVIDOR=127.0.0.1
if /i not "%ROL%"=="S" (
  set /p IP_SERVIDOR="IP de la PC SERVIDOR en la red (ej. 192.168.50.10): "
)

:ROL_YA_DEFINIDO

REM Resolver rol_id y url_pb segun la respuesta
if /i "%ROL%"=="S" (
  set ROL_ID=monitor
  set PB_URL=http://127.0.0.1:8090
) else if /i "%ROL%"=="A" (
  set ROL_ID=terminal-a
  set PB_URL=http://!IP_SERVIDOR!:8090
) else if /i "%ROL%"=="B" (
  set ROL_ID=terminal-b
  set PB_URL=http://!IP_SERVIDOR!:8090
) else if /i "%ROL%"=="D" (
  set ROL_ID=dashboard
  set PB_URL=http://!IP_SERVIDOR!:8090
) else (
  echo Rol invalido. Abortando.
  exit /b 1
)

REM ----- Determinar HARDWARE de esta PC --------------------------------------
REM   - Modo 2 (Economica)     : todas tradicional
REM   - Modo 3 (Mixta)         : cabina = tactil, terminales = tradicional,
REM                              dashboard = tradicional
REM   - Modo 4 (Ideal)         : todas tactil (excepto dashboard que es tradicional
REM                              porque suele ser una PC aparte de reportes)
set "HW_TIPO=tradicional"
if "%MODO%"=="2" set "HW_TIPO=tradicional"
if "%MODO%"=="3" (
  if /i "%ROL%"=="S" ( set "HW_TIPO=tactil" ) else ( set "HW_TIPO=tradicional" )
)
if "%MODO%"=="4" (
  if /i "%ROL%"=="D" ( set "HW_TIPO=tradicional" ) else ( set "HW_TIPO=tactil" )
)

REM Si el lanzador ya nos dio el hardware via FCEA_HW, lo respetamos
REM y no volvemos a preguntar.
if defined FCEA_HW (
  set "HW_TIPO=%FCEA_HW%"
  echo  Hardware fijado por el lanzador: !HW_TIPO!
) else (
  echo.
  echo  Hardware detectado para este rol: !HW_TIPO!
  echo.
  echo    [Enter] Aceptar el detectado (!HW_TIPO!)
  echo    [T]     Forzar TACTIL       (kiosk pantalla completa)
  echo    [R]     Forzar TRADICIONAL  (mouse+teclado)
  echo.
  set "HW_OVERRIDE="
  set /p HW_OVERRIDE="Confirmar hardware (Enter/T/R): "
  if /i "!HW_OVERRIDE!"=="T" set "HW_TIPO=tactil"
  if /i "!HW_OVERRIDE!"=="R" set "HW_TIPO=tradicional"
)

REM Modo mixto/ideal con cabina tactil -> teclado virtual forzado
set TECLADO_FORZADO=false
if /i "!HW_TIPO!"=="tactil" set TECLADO_FORZADO=true

call :ESCRIBIR_CONFIG_PROD "!ROL_ID!" "!PB_URL!" "!IP_SERVIDOR!" "!TECLADO_FORZADO!" "!HW_TIPO!"
call :PERSISTIR_INSTALL_CONFIG "produccion" "!HW_TIPO!"

if /i "%ROL%"=="S" (
  call :INSTALAR_DEPENDENCIAS
  call :CONFIGURAR_SERVIDOR_LOCAL
  call :RESTAURAR_DATOS_PENDRIVE
  call :CONFIGURAR_MANTENIMIENTO_AUTO
  call :CONFIGURAR_INICIO_AUTO
  echo.
  echo  Servidor instalado correctamente.
  echo  - PocketBase escucha en: http://0.0.0.0:8090
  echo  - Hardware configurado : !HW_TIPO!
  echo  - Las terminales A/B deben usar: http://%COMPUTERNAME%:8090
  echo  - Anote la IP local de esta PC para configurar las terminales.
  echo  - Watchdog + Backup + Chequeo de salud: tareas programadas activas.
  echo  - Inicio automatico al login: configurado.
) else (
  call :INSTALAR_DEPENDENCIAS
  call :CONFIGURAR_INICIO_AUTO
  echo.
  echo  Terminal !ROL_ID! instalada correctamente.
  echo  - Apuntando a PocketBase: !PB_URL!
  echo  - Hardware configurado : !HW_TIPO!
  echo  - Verifique conectividad con: ping !IP_SERVIDOR!
  echo  - Inicio automatico al login: configurado.
)

goto FIN

REM ============================================================
REM  SUBRUTINAS
REM ============================================================

:ESCRIBIR_CONFIG
REM Args: %1=modo %2=rol %3=ip_servidor %4=ip_term_a %5=ip_term_b %6=teclado_forzado %7=hardware
echo Escribiendo public\config.json (modo=%~1, rol=%~2, hw=%~7)...
(
  echo {
  echo   "version": "2.1.0",
  echo   "modo": "%~1",
  echo   "rol": "%~2",
  echo   "hardware": "%~7",
  echo   "pocketbase_url": "http://%~3:8090",
  echo   "red": {
  echo     "ip_servidor": "%~3",
  echo     "ip_terminal_a": "%~4",
  echo     "ip_terminal_b": "%~5"
  echo   },
  echo   "ui": {
  echo     "teclado_virtual_forzado": %~6,
  echo     "tema": "claro"
  echo   }
  echo }
) > public\config.json
REM Si modo es desarrollo, pocketbase_url debe ser 127.0.0.1
if "%~1"=="desarrollo" (
  powershell -Command "(Get-Content public\config.json) -replace 'http://%~3:8090', 'http://127.0.0.1:8090' | Set-Content public\config.json"
)
goto :eof

:ESCRIBIR_CONFIG_PROD
REM Args: %1=rol %2=pb_url %3=ip_servidor %4=teclado_forzado %5=hardware
echo Escribiendo public\config.json (rol=%~1, pb=%~2, hw=%~5)...
(
  echo {
  echo   "version": "2.1.0",
  echo   "modo": "produccion",
  echo   "rol": "%~1",
  echo   "hardware": "%~5",
  echo   "pocketbase_url": "%~2",
  echo   "red": {
  echo     "ip_servidor": "%~3",
  echo     "ip_terminal_a": "%~3",
  echo     "ip_terminal_b": "%~3"
  echo   },
  echo   "ui": {
  echo     "teclado_virtual_forzado": %~4,
  echo     "tema": "claro"
  echo   }
  echo }
) > public\config.json
goto :eof

:PERSISTIR_INSTALL_CONFIG
REM Args: %1=modo %2=hardware
REM Crea install_config.json en C:\sistema-llaves-fcea\config\ con un
REM snapshot completo del hardware (monitores, webcams, impresoras...) y
REM lo sincroniza con PocketBase si esta corriendo.
echo.
echo Detectando hardware y guardando install_config.json ...
if not exist "%LIB_PERSIST%" (
  echo [AVISO] No se encontro %LIB_PERSIST%. Omito install_config.json.
  goto :eof
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%LIB_PERSIST%" -Modo "%~1" -Hardware "%~2"
goto :eof

:INSTALAR_DEPENDENCIAS
echo.
echo Instalando dependencias de Node.js (puede tardar)...
call npm install --no-audit --no-fund
if errorlevel 1 (
  echo [ERROR] Fallo npm install.
  exit /b 1
)
echo.
echo Construyendo frontend (npm run build)...
call npm run build
if errorlevel 1 (
  echo [ADVERTENCIA] El build fallo. Puede ejecutar el sistema en modo dev con: npm run dev
)
goto :eof

:CONFIGURAR_SERVIDOR_LOCAL
echo.
echo Verificando carpeta pocketbase\ ...
if not exist pocketbase\pocketbase.exe (
  echo [ERROR] pocketbase\pocketbase.exe no encontrado.
  echo Descargue PocketBase desde https://pocketbase.io y copielo a la carpeta pocketbase\
  exit /b 1
)
echo OK - PocketBase encontrado.
echo.
echo Abriendo puerto 8090 en el firewall de Windows...
netsh advfirewall firewall delete rule name="FCEA-PocketBase-8090" >nul 2>nul
netsh advfirewall firewall add rule name="FCEA-PocketBase-8090" dir=in action=allow protocol=TCP localport=8090 >nul
if errorlevel 1 (
  echo [ADVERTENCIA] No se pudo abrir el puerto 8090. Ejecute como administrador o abralo manualmente.
) else (
  echo OK - Puerto 8090 abierto en el firewall.
)
goto :eof

REM ============================================================
REM  RESTAURAR_DATOS_PENDRIVE
REM  Detecta si el pendrive trae pb_data productivo y, en ese
REM  caso, lo restaura sobre la nueva instalacion.
REM ============================================================
:RESTAURAR_DATOS_PENDRIVE
echo.
echo ============================================================
echo  Verificando datos productivos en el pendrive...
echo ============================================================

set "PENDRIVE_PBDATA=%PENDRIVE_ROOT%\sistema-llaves-fcea\pocketbase\pb_data"
set "PENDRIVE_PBBACKUPS=%PENDRIVE_ROOT%\sistema-llaves-fcea\pocketbase\pb_backups"

if not exist "%PENDRIVE_PBDATA%\data.db" (
  echo No se detectaron datos productivos en el pendrive.
  echo La instalacion arrancara con base de datos vacia.
  goto :eof
)

echo.
echo  ============================================================
echo   *** SE DETECTARON DATOS PRODUCTIVOS EN EL PENDRIVE ***
echo  ============================================================
if exist "%PENDRIVE_ROOT%\ULTIMO_BACKUP.txt" (
  echo.
  type "%PENDRIVE_ROOT%\ULTIMO_BACKUP.txt"
)
echo.
echo  Estos datos contienen TODOS los registros del sistema:
echo    - Llaves / salones / oficinas
echo    - Vigilantes con horarios y licencias
echo    - Usuarios solicitantes y registrados
echo    - Llaves frecuentes de cada usuario
echo    - Historial completo de movimientos
echo    - Autorizaciones (pendientes y aprobadas)
echo    - Objetos olvidados
echo    - Configuracion del sistema
echo    - Archivos adjuntos (fotos, etc.)
echo  ============================================================
echo.

REM Si el lanzador del pendrive seteo FCEA_RESTAURAR_AUTO=1, restaurar
REM sin preguntar (instalacion 100%% desatendida).
if defined FCEA_RESTAURAR_AUTO (
  echo  [Modo automatico] Restaurando datos sin pedir confirmacion...
  set "RESTAURAR=S"
) else (
  set /p RESTAURAR="Restaurar TODOS los datos del pendrive? [S/N] (default: S): "
  if "!RESTAURAR!"=="" set RESTAURAR=S
)

if /i not "!RESTAURAR!"=="S" (
  echo.
  echo  [OMITIDO] Los datos NO se restauraron. El sistema arrancara
  echo            con base de datos vacia.
  echo            Puede restaurar manualmente mas tarde copiando:
  echo              %PENDRIVE_PBDATA% -^> pocketbase\pb_data\
  goto :eof
)

echo.
echo Restaurando pb_data productivo...
if exist pocketbase\pb_data (
  REM Hacer un backup de la base vacia recien creada por si acaso
  if not exist pocketbase\pb_data.vacio_inicial (
    move pocketbase\pb_data pocketbase\pb_data.vacio_inicial >nul 2>&1
  ) else (
    rmdir /S /Q pocketbase\pb_data
  )
)
mkdir pocketbase\pb_data
robocopy "%PENDRIVE_PBDATA%" "pocketbase\pb_data" /MIR /NFL /NDL /NJH /NJS /NP >nul

if exist "%PENDRIVE_PBBACKUPS%" (
  echo Restaurando pb_backups historicos...
  if not exist pocketbase\pb_backups mkdir pocketbase\pb_backups
  robocopy "%PENDRIVE_PBBACKUPS%" "pocketbase\pb_backups" /MIR /NFL /NDL /NJH /NJS /NP >nul
)

echo.
echo  ============================================================
echo   [OK] DATOS PRODUCTIVOS RESTAURADOS CORRECTAMENTE
echo  ============================================================
echo   Al iniciar el sistema vera todos los registros que tenia
echo   al momento del ultimo backup del pendrive.
echo.
echo   Movimientos posteriores al backup deberan recargarse
echo   manualmente desde el cuaderno fisico de respaldo.
echo  ============================================================
goto :eof

REM ============================================================
REM  CONFIGURAR_MANTENIMIENTO_AUTO
REM  Registra las tareas programadas FCEA-Watchdog,
REM  FCEA-Backup-Diario y FCEA-Chequeo-Salud. Solo se ejecuta
REM  cuando el rol es 'monitor' (la propia tarea ya valida eso).
REM ============================================================
:CONFIGURAR_MANTENIMIENTO_AUTO
echo.
echo Configurando tareas de mantenimiento (watchdog, backup, chequeo de salud)...
set "CFG_MAINT=%REPO_ROOT%\scripts\maintenance\CONFIGURAR_MANTENIMIENTO.ps1"
if not exist "%CFG_MAINT%" (
  echo [AVISO] No se encontro %CFG_MAINT%. Omito.
  goto :eof
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%CFG_MAINT%"
if errorlevel 1 (
  echo [ADVERTENCIA] No se pudieron registrar todas las tareas de mantenimiento.
  echo               Ejecute manualmente como Administrador:
  echo                 powershell -ExecutionPolicy Bypass -File "%CFG_MAINT%"
)
goto :eof

REM ============================================================
REM  CONFIGURAR_INICIO_AUTO
REM  Registra la tarea FCEA-Sistema-Llaves-AutoStart que arranca
REM  INICIAR.bat al iniciar sesion del usuario. Aplica a todos
REM  los roles (servidor, terminales y dashboard).
REM ============================================================
:CONFIGURAR_INICIO_AUTO
echo.
echo Configurando inicio automatico al login de Windows...
set "CFG_AUTO=%REPO_ROOT%\scripts\install\CONFIGURAR_INICIO_AUTOMATICO.ps1"
if not exist "%CFG_AUTO%" (
  echo [AVISO] No se encontro %CFG_AUTO%. Omito.
  goto :eof
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%CFG_AUTO%"
if errorlevel 1 (
  echo [ADVERTENCIA] No se pudo registrar el inicio automatico.
  echo               Ejecute manualmente como Administrador:
  echo                 powershell -ExecutionPolicy Bypass -File "%CFG_AUTO%"
)
goto :eof

:FIN
echo.
echo ============================================================
echo  Instalacion finalizada.
echo  Lea docs\INSTALACION.md para los siguientes pasos.
echo ============================================================
echo.
REM Si venimos del lanzador del pendrive, no bloqueamos con pause
REM porque el launcher se encarga de mostrar el resumen final.
if not defined FCEA_RESTAURAR_AUTO (
  pause
)
endlocal
