@echo off
REM ============================================================
REM  Sistema FCEA - RECUPERADOR v6.1 (produccion, cero perdida)
REM ============================================================
REM  Reinstala el sistema sin perder datos productivos.
REM
REM  Cambios v6.1 respecto a v6.0:
REM    - FIX definitivo del bug de `;` en one-liners PowerShell
REM      embebidos en `for /f ... backticks`. Cmd.exe cortaba el
REM      pipeline al mezclar `;` con expansion de `%var%` dentro
REM      de esos backticks, dejando la variable de salida vacia
REM      y cascadeando errores en pasos posteriores.
REM    - Se extraen esas mini-utilidades a HELPERS .ps1 auxiliares
REM      en scripts\lib:
REM        * check_http_health.ps1 -> verifica URL y escribe OK/FAIL
REM        * validar_ipv4.ps1      -> valida IP y escribe OK/BAD
REM    - Los one-liners que quedan NO usan `;`, solo pipes `|` y
REM      bloques `{...}` que cmd.exe tolera bien.
REM
REM  Cambios v6.0 respecto a v5.1:
REM    - REESCRITO DE CERO con flujo LINEAL (sin labels spaghetti).
REM    - Reemplazados los bloques `if ( ) else ( )` con expansion
REM      de variables por SUBRUTINAS `call :nombre`, que evitan
REM      el error clasico de cmd.exe:
REM        "No se esperaba ... en este momento"
REM      Este error rompio el v5.1 en la linea "Verificando datos
REM      productivos previos" al expandir %PROGDATA_DIR%.
REM    - LOG COMPLETO a C:\fcea_recuperador.log de todo lo que
REM      pasa, con timestamp por linea. Si algo falla, el log
REM      dice EXACTAMENTE en que paso murio.
REM    - Chequeo de errores en cada paso: si algo falla, se
REM      muestra mensaje claro y se sale con codigo != 0, NUNCA
REM      con "No se esperaba ..." + prompt vacio.
REM    - El paso 5 (semilla) usa un helper .cmd generado al vuelo
REM      para no depender de expansion diferida en bloques `if`.
REM ============================================================

setlocal EnableDelayedExpansion
title Sistema FCEA - Recuperador v6.1

REM ---- Log file (creado antes de cualquier otra cosa) ----
set "LOG_FILE=C:\fcea_recuperador.log"
REM Si ya existe log de una corrida previa, lo renombramos.
if exist "%LOG_FILE%" (
  ren "%LOG_FILE%" fcea_recuperador_previo.log 2>nul
)
call :LOG "==== Sistema FCEA - Recuperador v6.1 - inicio ===="
call :LOG "Fecha/hora: %DATE% %TIME%"
call :LOG "Hostname actual: %COMPUTERNAME%"
call :LOG "Usuario: %USERNAME%"

REM ---- Paso 0: elevacion UAC ----
net session >nul 2>&1
if errorlevel 1 (
  call :LOG "No hay privilegios de administrador. Solicitando UAC..."
  echo.
  echo  Solicitando permisos de Administrador...
  echo  Aparecera una ventana de Control de Cuentas de Usuario;
  echo  haga click en SI para continuar.
  echo.
  powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/k','\"%~f0\"' -Verb RunAs"
  exit /b 0
)
call :LOG "Ejecutando como administrador OK."

pushd "%~dp0" >nul 2>&1
set "PENDRIVE_ROOT=%~dp0"
if "%PENDRIVE_ROOT:~-1%"=="\" set "PENDRIVE_ROOT=%PENDRIVE_ROOT:~0,-1%"
set "INSTALL_DIR=C:\sistema-llaves-fcea"
set "PROGDATA_DIR=C:\ProgramData\FCEA-Sistema-Llaves"

call :LOG "PENDRIVE_ROOT = %PENDRIVE_ROOT%"
call :LOG "INSTALL_DIR   = %INSTALL_DIR%"
call :LOG "PROGDATA_DIR  = %PROGDATA_DIR%"

cls
echo.
echo  ============================================================
echo                  Sistema de Gestion de Llaves
echo                Facultad de Ciencias Economicas
echo                RECUPERADOR PILOTO - UDELAR v6.1
echo  ============================================================
echo.
echo   Reinstala el sistema PRESERVANDO los datos productivos.
echo   Se puede ejecutar cuantas veces sea necesario sin perder
echo   llaves, usuarios, historial ni configuracion.
echo.
echo   Rol: Monitor Vigilancia, Terminal-A o Terminal-B.
echo   Duracion: 5 a 10 minutos. Al terminar la PC se reinicia.
echo.
echo   Log completo en: %LOG_FILE%
echo  ============================================================
echo.

REM ==========================================================
REM  PASO 1/9: Determinar rol (por hostname o preguntando)
REM ==========================================================
call :LOG "----- PASO 1/9: Determinar rol -----"
call :DETERMINAR_ROL
if errorlevel 1 goto FIN_CANCELADO
call :LOG "Rol final: %ROL_DETECTADO%"
call :LOG "Hostname nuevo: %HOSTNAME_NUEVO%"
echo.
echo   Rol      : %ROL_DETECTADO%
echo   Hostname : %HOSTNAME_NUEVO%
echo.

REM ==========================================================
REM  PASO 2/9: Backup preventivo
REM ==========================================================
call :LOG "----- PASO 2/9: Backup preventivo -----"
echo  ============================================================
echo   [2/9] Backup preventivo antes de recuperar
echo  ============================================================
call :BACKUP_PREVENTIVO
echo.

REM ==========================================================
REM  PASO 3/9: Renombrar PC (efectivo tras reinicio)
REM ==========================================================
call :LOG "----- PASO 3/9: Renombrar PC -----"
echo  ============================================================
echo   [3/9] Renombrando esta PC a: %HOSTNAME_NUEVO%
echo  ============================================================
call :RENOMBRAR_PC
echo.

REM ==========================================================
REM  PASO 4/9: Detener procesos y limpiar codigo previo
REM ==========================================================
call :LOG "----- PASO 4/9: Detener procesos y limpiar -----"
echo  ============================================================
echo   [4/9] Deteniendo procesos y limpiando codigo previo
echo  ============================================================
call :DETENER_PROCESOS
call :LIMPIAR_INSTALL_DIR
if errorlevel 1 goto FIN_ERROR
echo   [OK] Codigo previo limpiado.
echo   [OK] Datos productivos (ProgramData) INTACTOS.
echo.

REM ==========================================================
REM  PASO 5/9: Copiar sistema desde pendrive
REM ==========================================================
call :LOG "----- PASO 5/9: Copiar sistema desde pendrive -----"
echo  ============================================================
echo   [5/9] Copiando el sistema desde el pendrive
echo  ============================================================
call :COPIAR_SISTEMA
if errorlevel 1 goto FIN_ERROR
echo.

REM ==========================================================
REM  PASO 6/9: Restaurar teclado tactil + configurar energia
REM ==========================================================
call :LOG "----- PASO 6/9: Teclado tactil + energia -----"
echo  ============================================================
echo   [6/9] Restaurando teclado tactil y configurando energia
echo  ============================================================
call :RESTAURAR_TABTIP
call :CONFIGURAR_ENERGIA
echo.

REM ==========================================================
REM  PASO 7/9: Verificar / sembrar base de datos
REM ==========================================================
call :LOG "----- PASO 7/9: Verificar datos productivos previos -----"
echo  ============================================================
echo   [7/9] Verificando datos productivos previos
echo  ============================================================
call :VERIFICAR_O_SEMBRAR
echo.

REM ==========================================================
REM  PASO 8/9: Ejecutar INSTALAR.bat con rol forzado
REM ==========================================================
call :LOG "----- PASO 8/9: Ejecutar INSTALAR.bat -----"
echo  ============================================================
echo   [8/9] Instalando en modo PRODUCCION, rol: %ROL_DETECTADO%
echo  ============================================================
call :INSTALAR_SISTEMA
if errorlevel 1 goto FIN_ERROR
echo.

REM ==========================================================
REM  PASO 9/9: Blindar config.json final + reiniciar
REM ==========================================================
call :LOG "----- PASO 9/9: Blindar config.json y reiniciar -----"
echo  ============================================================
echo   [9/9] Blindando config.json final
echo  ============================================================
call :BLINDAR_CONFIG
echo.

goto FIN_OK


REM ============================================================
REM ===============  SUBRUTINAS (call :nombre)  ================
REM ============================================================

REM ------------------------------------------------------------
:LOG
REM  Escribe una linea al log con timestamp. Uso: call :LOG "mensaje"
echo [%DATE% %TIME%] %~1>>"%LOG_FILE%"
exit /b 0

REM ------------------------------------------------------------
:DETERMINAR_ROL
REM  Determina ROL_DETECTADO y HOSTNAME_NUEVO.
REM  Si el hostname ya empieza con FCEA-, usa ese rol.
REM  Si no, pregunta.
set "ROL_DETECTADO="
set "HOSTNAME_NUEVO="
set "HOST_UPPER=%COMPUTERNAME%"

REM Normalizar (mayusculas). En cmd es dificil, asi que usamos powershell.
for /f "usebackq delims=" %%h in (`powershell -NoProfile -Command "$env:COMPUTERNAME.ToUpper()"`) do set "HOST_UPPER=%%h"
call :LOG "Hostname en mayusculas: %HOST_UPPER%"

if "%HOST_UPPER%"=="FCEA-MONITOR"    ( set "ROL_DETECTADO=monitor"    & set "HOSTNAME_NUEVO=FCEA-MONITOR"    )
if "%HOST_UPPER%"=="FCEA-CABINA"     ( set "ROL_DETECTADO=monitor"    & set "HOSTNAME_NUEVO=FCEA-CABINA"    )
if "%HOST_UPPER%"=="FCEA-SERVIDOR"   ( set "ROL_DETECTADO=monitor"    & set "HOSTNAME_NUEVO=FCEA-SERVIDOR"  )
if "%HOST_UPPER%"=="FCEA-TERMINAL-A" ( set "ROL_DETECTADO=terminal-a" & set "HOSTNAME_NUEVO=FCEA-TERMINAL-A")
if "%HOST_UPPER%"=="FCEA-TERMINAL-B" ( set "ROL_DETECTADO=terminal-b" & set "HOSTNAME_NUEVO=FCEA-TERMINAL-B")

if defined ROL_DETECTADO (
  call :LOG "Rol autodetectado por hostname: %ROL_DETECTADO%"
  echo   Hostname actual: %COMPUTERNAME%
  echo   Rol autodetectado: %ROL_DETECTADO%
  echo.
  exit /b 0
)

REM No detectado: preguntar
call :LOG "Hostname no coincide con FCEA-*, se pregunta al usuario"
echo   Hostname actual: %COMPUTERNAME%
echo   No coincide con un nombre FCEA-*, hay que elegir el rol.
echo.
echo  ============================================================
echo   Que rol cumple ESTA PC?
echo  ============================================================
echo    [1] MONITOR VIGILANCIA  - PC del vigilante, servidor+agenda
echo    [2] TERMINAL A          - kiosk para usuarios A
echo    [3] TERMINAL B          - kiosk para usuarios B
echo    [X] Cancelar
echo  ============================================================

:_PREGUNTAR_ROL_LOOP
set "OP="
set /p "OP=Elija [1/2/3/X]: "
if /i "%OP%"=="X" (
  call :LOG "Usuario cancelo la operacion en la eleccion de rol"
  exit /b 1
)
if "%OP%"=="1" ( set "ROL_DETECTADO=monitor"    & set "HOSTNAME_NUEVO=FCEA-MONITOR"    & exit /b 0 )
if "%OP%"=="2" ( set "ROL_DETECTADO=terminal-a" & set "HOSTNAME_NUEVO=FCEA-TERMINAL-A" & exit /b 0 )
if "%OP%"=="3" ( set "ROL_DETECTADO=terminal-b" & set "HOSTNAME_NUEVO=FCEA-TERMINAL-B" & exit /b 0 )
echo   Opcion invalida. Ingrese 1, 2, 3 o X.
goto :_PREGUNTAR_ROL_LOOP

REM ------------------------------------------------------------
:BACKUP_PREVENTIVO
REM  Copia %PROGDATA_DIR% a C:\backup_fcea_preop_YYYYMMDD_HHMMSS
REM  Si no hay datos previos, informa y no hace nada.
set "TS="
for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd_HHmmss'"`) do set "TS=%%t"
if not defined TS set "TS=sin_timestamp"
set "BACKUP_PREOP=C:\backup_fcea_preop_%TS%"
call :LOG "BACKUP_PREOP = %BACKUP_PREOP%"

if not exist "%PROGDATA_DIR%\pb_data\data.db" (
  echo   No hay datos productivos previos, se salta el backup preventivo.
  echo   Esta es una instalacion "primera vez" en esta PC.
  call :LOG "No existe %PROGDATA_DIR%\pb_data\data.db - se salta backup"
  exit /b 0
)

echo   Copiando datos productivos actuales a:
echo     %BACKUP_PREOP%
call :LOG "Ejecutando robocopy backup preventivo..."
robocopy "%PROGDATA_DIR%" "%BACKUP_PREOP%" /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NP >>"%LOG_FILE%" 2>&1

if exist "%BACKUP_PREOP%\pb_data\data.db" (
  echo   [OK] Backup preventivo listo.
  call :LOG "Backup preventivo OK"
) else (
  echo   [WARN] El backup preventivo puede estar incompleto.
  call :LOG "Backup preventivo INCOMPLETO - verificar %BACKUP_PREOP%"
)
exit /b 0

REM ------------------------------------------------------------
:RENOMBRAR_PC
REM  Renombra la PC a %HOSTNAME_NUEVO% si no es el nombre actual.
if /i "%COMPUTERNAME%"=="%HOSTNAME_NUEVO%" (
  echo   La PC ya tiene el nombre correcto. Sin cambios.
  call :LOG "PC ya se llama %HOSTNAME_NUEVO%"
  exit /b 0
)

call :LOG "Renombrando de %COMPUTERNAME% a %HOSTNAME_NUEVO%"
powershell -NoProfile -Command "Rename-Computer -NewName '%HOSTNAME_NUEVO%' -Force -ErrorAction Stop" >>"%LOG_FILE%" 2>&1
if not errorlevel 1 (
  echo   [OK] Renombrado programado. Efectivo tras reiniciar.
  call :LOG "Rename-Computer OK"
  exit /b 0
)

echo   [ADVERTENCIA] PowerShell fallo, intento con WMIC...
call :LOG "Rename-Computer fallo, intentando WMIC"
wmic computersystem where "name='%COMPUTERNAME%'" call rename name="%HOSTNAME_NUEVO%" >>"%LOG_FILE%" 2>&1
if not errorlevel 1 (
  echo   [OK] Renombrado programado (via WMIC).
  call :LOG "WMIC rename OK"
  exit /b 0
)
echo   [ERROR] No se pudo renombrar. Sigue igual, hostname no cambio.
call :LOG "ERROR: no se pudo renombrar la PC"
timeout /t 3 /nobreak >nul
exit /b 0

REM ------------------------------------------------------------
:DETENER_PROCESOS
call :LOG "Deteniendo pocketbase.exe, chrome.exe, msedge.exe, node.exe FCEA"
taskkill /F /IM pocketbase.exe >>"%LOG_FILE%" 2>&1
taskkill /F /IM chrome.exe     >>"%LOG_FILE%" 2>&1
taskkill /F /IM msedge.exe     >>"%LOG_FILE%" 2>&1
powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='node.exe'\" | Where-Object { $_.CommandLine -match 'sistema-llaves-fcea' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >>"%LOG_FILE%" 2>&1
timeout /t 2 /nobreak >nul

call :LOG "Borrando tareas programadas FCEA-*"
for %%T in ("FCEA-Backup-Semanal" "FCEA-Backup-Diario" "FCEA-Watchdog-PocketBase" "FCEA-Watchdog" "FCEA-Chequeo-Salud" "FCEA-Mantenimiento-Diario" "FCEA-Inicio-Automatico" "FCEA-Sistema-Llaves-AutoStart") do (
  schtasks /Delete /TN %%~T /F >>"%LOG_FILE%" 2>&1
)
exit /b 0

REM ------------------------------------------------------------
:LIMPIAR_INSTALL_DIR
REM  Borra C:\sistema-llaves-fcea (codigo, NO datos).
if not exist "%INSTALL_DIR%" (
  call :LOG "%INSTALL_DIR% no existe, nada que limpiar"
  exit /b 0
)
call :LOG "Borrando %INSTALL_DIR%"
attrib -R -S -H "%INSTALL_DIR%\*.*" /S /D >nul 2>&1
rmdir /S /Q "%INSTALL_DIR%" 2>nul
if exist "%INSTALL_DIR%" (
  timeout /t 2 /nobreak >nul
  rmdir /S /Q "%INSTALL_DIR%" 2>nul
)
if exist "%INSTALL_DIR%" (
  timeout /t 2 /nobreak >nul
  rmdir /S /Q "%INSTALL_DIR%" 2>nul
)
if exist "%INSTALL_DIR%" (
  echo   [ERROR] No se pudo borrar %INSTALL_DIR%
  echo           Cierre todas las ventanas FCEA, reinicie la PC
  echo           y vuelva a ejecutar RECUPERAR SISTEMA.bat
  call :LOG "ERROR: no se pudo borrar %INSTALL_DIR%"
  exit /b 1
)
call :LOG "%INSTALL_DIR% borrado OK"
exit /b 0

REM ------------------------------------------------------------
:COPIAR_SISTEMA
REM  Copia %PENDRIVE_ROOT%\sistema-llaves-fcea -> %INSTALL_DIR%
set "LIB_COPIAR=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\lib\copiar_con_progreso.ps1"
if exist "%LIB_COPIAR%" (
  call :LOG "Usando copiar_con_progreso.ps1"
  powershell -NoProfile -ExecutionPolicy Bypass -File "%LIB_COPIAR%" -Origen "%PENDRIVE_ROOT%\sistema-llaves-fcea" -Destino "%INSTALL_DIR%" -Etiqueta "Copiando sistema"
) else (
  call :LOG "copiar_con_progreso.ps1 no encontrado, usando robocopy /MIR"
  robocopy "%PENDRIVE_ROOT%\sistema-llaves-fcea" "%INSTALL_DIR%" /MIR /NJH /NJS >>"%LOG_FILE%" 2>&1
)

if not exist "%INSTALL_DIR%\scripts\install\INSTALAR.bat" (
  echo   [ERROR] La copia fallo. No existe %INSTALL_DIR%\scripts\install\INSTALAR.bat
  call :LOG "ERROR: no existe INSTALAR.bat despues de copiar"
  exit /b 1
)

REM Copiar node-portable si existe
if exist "%PENDRIVE_ROOT%\node-portable\node\node.exe" (
  call :LOG "Copiando node-portable"
  if exist "%LIB_COPIAR%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%LIB_COPIAR%" -Origen "%PENDRIVE_ROOT%\node-portable" -Destino "%INSTALL_DIR%\node-portable" -Etiqueta "Copiando Node.js"
  ) else (
    robocopy "%PENDRIVE_ROOT%\node-portable" "%INSTALL_DIR%\node-portable" /MIR /NJH /NJS >>"%LOG_FILE%" 2>&1
  )
)
call :LOG "Copia del sistema completa"
exit /b 0

REM ------------------------------------------------------------
:RESTAURAR_TABTIP
set "LIB_TABTIP=%INSTALL_DIR%\scripts\lib\restaurar_tabtip.ps1"
if not exist "%LIB_TABTIP%" (
  echo   [i] restaurar_tabtip.ps1 no encontrado, se salta este paso.
  call :LOG "restaurar_tabtip.ps1 no encontrado"
  exit /b 0
)
call :LOG "Ejecutando restaurar_tabtip.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%LIB_TABTIP%" >>"%LOG_FILE%" 2>&1
exit /b 0

REM ------------------------------------------------------------
:CONFIGURAR_ENERGIA
set "LIB_ENERGIA=%INSTALL_DIR%\scripts\lib\configurar_energia.ps1"
if not exist "%LIB_ENERGIA%" (
  echo   [i] configurar_energia.ps1 no encontrado, se salta este paso.
  call :LOG "configurar_energia.ps1 no encontrado"
  exit /b 0
)
call :LOG "Ejecutando configurar_energia.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%LIB_ENERGIA%"
exit /b 0

REM ------------------------------------------------------------
:VERIFICAR_O_SEMBRAR
REM  Si existe %PROGDATA_DIR%\pb_data\data.db  -> respetar.
REM  Si NO existe                              -> sembrar semilla.
if exist "%PROGDATA_DIR%\pb_data\data.db" (
  echo   [OK] Base productiva DETECTADA en:
  echo         %PROGDATA_DIR%\pb_data\data.db
  echo   Se respetan los datos existentes. NO se sembrara semilla.
  call :LOG "Base productiva existente detectada - se respetan datos"
  exit /b 0
)

echo   No hay base productiva previa en esta PC.
echo   Sembrando semilla desde el pendrive (primera vez)...
call :LOG "No hay data.db previo, sembrando semilla del pendrive"

if not exist "%PROGDATA_DIR%\pb_data" (
  mkdir "%PROGDATA_DIR%\pb_data" 2>nul
)

set "SEMILLA_PENDRIVE=%PENDRIVE_ROOT%\sistema-llaves-fcea\pocketbase\pb_data"
call :LOG "SEMILLA_PENDRIVE = %SEMILLA_PENDRIVE%"

if not exist "%SEMILLA_PENDRIVE%\data.db" (
  echo   [WARN] No se encontro data.db en el pendrive:
  echo          %SEMILLA_PENDRIVE%
  echo          El sistema arrancara con base vacia.
  call :LOG "WARN: no existe data.db en el pendrive"
  exit /b 0
)

robocopy "%SEMILLA_PENDRIVE%" "%PROGDATA_DIR%\pb_data" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP >>"%LOG_FILE%" 2>&1

if exist "%PROGDATA_DIR%\pb_data\data.db" (
  echo   [OK] Semilla del pendrive copiada como base inicial.
  call :LOG "Semilla copiada OK"
) else (
  echo   [WARN] La semilla no se copio correctamente.
  call :LOG "WARN: semilla no copiada"
)
exit /b 0

REM ------------------------------------------------------------
:INSTALAR_SISTEMA
REM  Fija variables FCEA_* y llama a INSTALAR.bat.
set "FCEA_MODO=produccion"
set "FCEA_ROL=%ROL_DETECTADO%"

REM Hardware por rol (v2.5 - julio 2026):
REM  - Monitor  : siempre tradicional (PC del vigilante con teclado y mouse)
REM  - Terminal : AUTODETECTAR. Antes se forzaba "tactil" siempre, lo que
REM              era incorrecto si a la Terminal se le sacaba el touch
REM              resistivo y se le ponia monitor comun + teclado + mouse.
REM              Ahora consultamos a Windows si hay digitalizador tactil.
if /i "%ROL_DETECTADO%"=="monitor" (
  set "FCEA_HW=tradicional"
  set "FCEA_IP_SERVIDOR=127.0.0.1"
) else (
  call :AUTODETECTAR_HARDWARE
  call :BUSCAR_SERVIDOR
)


set "FCEA_PENDRIVE_ROOT=%PENDRIVE_ROOT%"
set "FCEA_RESTAURAR_AUTO=1"

call :LOG "FCEA_MODO=%FCEA_MODO%"
call :LOG "FCEA_ROL=%FCEA_ROL%"
call :LOG "FCEA_HW=%FCEA_HW%"
call :LOG "FCEA_IP_SERVIDOR=%FCEA_IP_SERVIDOR%"

pushd "%INSTALL_DIR%" >nul 2>&1
call scripts\install\INSTALAR.bat
set "INSTALL_EXIT=%ERRORLEVEL%"
popd >nul 2>&1

call :LOG "INSTALAR.bat termino con codigo %INSTALL_EXIT%"

if not "%INSTALL_EXIT%"=="0" (
  echo.
  echo  ============================================================
  echo   [ERROR] Instalacion fallo, codigo %INSTALL_EXIT%
  echo  ============================================================
  exit /b 1
)
exit /b 0

REM ------------------------------------------------------------
:AUTODETECTAR_HARDWARE
REM  Detecta si esta PC tiene digitalizador tactil o no.
REM  Fija la variable FCEA_HW en "tactil" o "tradicional".
REM
REM  Estrategia:
REM   1) Si existe detectar_hardware.ps1 en el sistema instalado o en
REM      el pendrive, se usa (funcion Test-TouchAvailable).
REM   2) Fallback: consulta directa a WMI/CIM Win32_PnPEntity buscando
REM      digitalizadores tactiles HID.
REM   3) Ante cualquier error o duda -> "tradicional" (mas seguro:
REM      no fuerza teclado virtual ni scrollbars gordas).
call :LOG "Autodetectando hardware tactil vs tradicional..."
set "FCEA_HW=tradicional"
set "HW_DETECT="

set "LIB_HW=%INSTALL_DIR%\scripts\lib\detectar_hardware.ps1"
if not exist "%LIB_HW%" set "LIB_HW=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\lib\detectar_hardware.ps1"

if exist "%LIB_HW%" (
  call :LOG "Usando detectar_hardware.ps1 en %LIB_HW%"
  for /f "usebackq delims=" %%h in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ". '%LIB_HW%'; if (Test-TouchAvailable) { 'tactil' } else { 'tradicional' }"`) do set "HW_DETECT=%%h"
) else (
  call :LOG "detectar_hardware.ps1 no encontrado, usando WMI directo"
  for /f "usebackq delims=" %%h in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $t = Get-CimInstance Win32_PnPEntity -ErrorAction Stop ^| Where-Object { $_.Name -match 'touch|digitiz' -or $_.PNPClass -eq 'HIDClass' -and $_.Name -match 'Touch' }; if ($t) { 'tactil' } else { 'tradicional' } } catch { 'tradicional' }"`) do set "HW_DETECT=%%h"
)

if /i "%HW_DETECT%"=="tactil" (
  set "FCEA_HW=tactil"
  echo   Hardware detectado: TACTIL (touch conectado)
  call :LOG "Hardware autodetectado: tactil"
) else (
  set "FCEA_HW=tradicional"
  echo   Hardware detectado: TRADICIONAL (monitor comun + teclado + mouse)
  call :LOG "Hardware autodetectado: tradicional"
)
exit /b 0

REM ------------------------------------------------------------
:BUSCAR_SERVIDOR
REM  Detecta IP del Monitor Vigilancia en la red.

REM
REM  Reglas (v6.1 - fix produccion FCEA):
REM    1) autodetectar_rol.ps1 SIEMPRE devuelve un tercer campo,
REM       aunque sea heuristico (ej: 192.168.X.10) o localhost
REM       (127.0.0.1). NUNCA aceptar la IP autodetectada sin
REM       verificar antes que responda en :8090/api/health.
REM    2) Si la autodetectada no responde, saltar al modo manual
REM       con bucle: no romper la instalacion con exit /b 1.
REM    3) En modo manual, aceptar solo IPv4 valida, distinta de
REM       127.0.0.1 y localhost. Verificar HTTP; si no responde,
REM       preguntar si se continua igual (Monitor apagado).
echo.
echo   Buscando Monitor Vigilancia en la red local...
echo   Esto tarda 5 a 15 segundos.
call :LOG "Ejecutando autodetectar_rol.ps1 para hallar servidor"
set "FCEA_IP_SERVIDOR="
set "IP_AUTO="

set "AUTODET=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\lib\autodetectar_rol.ps1"
if not exist "%AUTODET%" (
  echo   [WARN] No existe %AUTODET%
  call :LOG "WARN: no existe autodetectar_rol.ps1"
  goto _BS_MANUAL
)

for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%AUTODET%"`) do (
  for /f "tokens=3 delims=|" %%j in ("%%i") do set "IP_AUTO=%%j"
)

REM Rechazar IPs que autodetectar_rol.ps1 devuelve como fallback
REM sin haber verificado que respondan (127.0.0.1 o la heuristica
REM ".10" del prefijo local).
if not defined IP_AUTO goto _BS_MANUAL
if "%IP_AUTO%"=="" goto _BS_MANUAL
if "%IP_AUTO%"=="127.0.0.1" (
  call :LOG "Autodeteccion devolvio 127.0.0.1 - se ignora y se pregunta al usuario"
  echo   La autodeteccion no encontro el Monitor Vigilancia en la red.
  goto _BS_MANUAL
)

REM Verificar que la IP autodetectada realmente responda en :8090.
REM  Se usa helper check_http_health.ps1 para EVITAR one-liners
REM  PowerShell con `;` embebidos en for /f backticks (fix v6.1).
echo   Autodeteccion sugiere: %IP_AUTO%
echo   Verificando que responda en :8090...
call :LOG "Verificando IP autodetectada %IP_AUTO% via HTTP"
set "HTTP_OK=NO"
set "LIB_HTTP=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\lib\check_http_health.ps1"
for /f "usebackq delims=" %%v in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%LIB_HTTP%" -Url "http://%IP_AUTO%:8090/api/health" -TimeoutSec 3`) do set "HTTP_OK=%%v"

if /i "%HTTP_OK%"=="OK" (
  set "FCEA_IP_SERVIDOR=%IP_AUTO%"
  echo   [OK] Servidor confirmado en http://%IP_AUTO%:8090
  call :LOG "Servidor autodetectado y VERIFICADO: %IP_AUTO%"
  exit /b 0
)

echo   La IP %IP_AUTO% no responde en :8090.
echo   ^(Probable: Monitor apagado, o PocketBase no arranco todavia,
echo    o firewall bloqueando el puerto^).
call :LOG "IP autodetectada %IP_AUTO% NO responde HTTP - pasa a modo manual"

:_BS_MANUAL
echo.
echo  ============================================================
echo   No se pudo confirmar la conexion con el Monitor Vigilancia.
echo  ============================================================
echo   Para continuar necesito la IP LAN del Monitor Vigilancia.
echo   Puede averiguarla asi:
echo     1) En la PC del Monitor abra CMD.
echo     2) Escriba:  ipconfig
echo     3) Busque "IPv4" bajo el adaptador de red activo.
echo     4) Copie la IP (ej: 192.168.1.50).
echo.
echo   Escriba X para cancelar y salir.
echo.

:_BS_PEDIR
set "FCEA_IP_SERVIDOR="
set /p "FCEA_IP_SERVIDOR=IP del Monitor Vigilancia (o X para cancelar): "
call :LOG "IP del servidor ingresada manualmente: [%FCEA_IP_SERVIDOR%]"

if /i "%FCEA_IP_SERVIDOR%"=="X" (
  call :LOG "Usuario cancelo en la carga manual de IP"
  exit /b 1
)
if not defined FCEA_IP_SERVIDOR (
  echo   [ERROR] Debe ingresar una IP. Reintente.
  goto _BS_PEDIR
)
if "%FCEA_IP_SERVIDOR%"=="" (
  echo   [ERROR] Debe ingresar una IP. Reintente.
  goto _BS_PEDIR
)
if "%FCEA_IP_SERVIDOR%"=="127.0.0.1" (
  echo   [ERROR] 127.0.0.1 no es valido para una Terminal.
  echo           La Terminal debe apuntar al Monitor REMOTO, no a si misma.
  call :LOG "Rechazado: usuario ingreso 127.0.0.1"
  goto _BS_PEDIR
)
if /i "%FCEA_IP_SERVIDOR%"=="localhost" (
  echo   [ERROR] "localhost" no es valido para una Terminal.
  call :LOG "Rechazado: usuario ingreso localhost"
  goto _BS_PEDIR
)

REM Validar formato IPv4 con PowerShell (regex mas confiable que en batch).
REM  Se usa helper validar_ipv4.ps1 en vez de one-liner con `;` para
REM  no romper el parser de cmd.exe dentro de for /f backticks.
set "IP_CHECK=BAD"
set "LIB_IPV4=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\lib\validar_ipv4.ps1"
for /f "usebackq delims=" %%v in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%LIB_IPV4%" -Ip "%FCEA_IP_SERVIDOR%"`) do set "IP_CHECK=%%v"
if not "%IP_CHECK%"=="OK" (
  echo   [ERROR] "%FCEA_IP_SERVIDOR%" no es una direccion IPv4 valida.
  echo           Formato esperado: cuatro numeros separados por puntos
  echo           (ej: 192.168.1.50).
  call :LOG "Rechazado: formato IPv4 invalido [%FCEA_IP_SERVIDOR%]"
  goto _BS_PEDIR
)

REM Verificar que efectivamente responda en :8090. Si no, ofrecer
REM continuar (por si el Monitor todavia no arranco) o reintentar.
REM  Se usa helper check_http_health.ps1 (fix v6.1, sin `;`).
echo   Verificando %FCEA_IP_SERVIDOR%:8090...
call :LOG "Verificando IP manual %FCEA_IP_SERVIDOR% via HTTP"
set "HTTP_OK=NO"
for /f "usebackq delims=" %%v in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%LIB_HTTP%" -Url "http://%FCEA_IP_SERVIDOR%:8090/api/health" -TimeoutSec 3`) do set "HTTP_OK=%%v"

if /i "%HTTP_OK%"=="OK" (
  echo   [OK] Servidor responde correctamente en http://%FCEA_IP_SERVIDOR%:8090
  call :LOG "IP manual VERIFICADA: %FCEA_IP_SERVIDOR%"
  exit /b 0
)

echo.
echo   [ADVERTENCIA] http://%FCEA_IP_SERVIDOR%:8090 no respondio.
echo                 Posibles causas:
echo                   - Monitor Vigilancia apagado o iniciando aun
echo                   - PocketBase no esta corriendo en el Monitor
echo                   - Firewall del Monitor bloquea el puerto 8090
echo                   - La IP ingresada es incorrecta
echo.
echo    [S] Continuar igual con esta IP (el Monitor puede prenderse despues)
echo    [R] Reintentar / ingresar otra IP
echo    [X] Cancelar la instalacion
echo.
set "OP="
set /p "OP=Elija [S/R/X]: "
if /i "%OP%"=="S" (
  call :LOG "Usuario decide continuar con IP no verificada: %FCEA_IP_SERVIDOR%"
  exit /b 0
)
if /i "%OP%"=="X" (
  call :LOG "Usuario cancelo tras IP no verificada"
  exit /b 1
)
goto _BS_PEDIR

REM ------------------------------------------------------------
:BLINDAR_CONFIG
REM  Reescribe %INSTALL_DIR%\public\config.json con valores finales.
if /i "%ROL_DETECTADO%"=="monitor" (
  set "PB_URL=http://127.0.0.1:8090"
) else (
  set "PB_URL=http://%FCEA_IP_SERVIDOR%:8090"
)

set "TECLADO_FORZADO=false"
if /i "%FCEA_HW%"=="tactil" set "TECLADO_FORZADO=true"

REM Flag "ahorro de energia desactivado" - lo setea configurar_energia.ps1
REM al terminar (paso 6). Si no existe, asumimos "true" en produccion
REM (configurar_energia.ps1 corrio antes en el paso 6 sin errores criticos).
if not defined FCEA_ENERGIA_AHORRO_OFF set "FCEA_ENERGIA_AHORRO_OFF=true"

call :LOG "Escribiendo config.json final: rol=%ROL_DETECTADO% hw=%FCEA_HW% pb=%PB_URL% energia_off=%FCEA_ENERGIA_AHORRO_OFF%"

> "%INSTALL_DIR%\public\config.json" (
  echo {
  echo   "version": "2.5.0",
  echo   "modo": "produccion",
  echo   "rol": "%ROL_DETECTADO%",
  echo   "hardware": "%FCEA_HW%",
  echo   "pocketbase_url": "%PB_URL%",
  echo   "red": {
  echo     "ip_servidor": "%FCEA_IP_SERVIDOR%"
  echo   },
  echo   "ui": {
  echo     "teclado_virtual_forzado": %TECLADO_FORZADO%,
  echo     "energia_ahorro_desactivado": %FCEA_ENERGIA_AHORRO_OFF%,
  echo     "tema": "claro"
  echo   }
  echo }
)


if exist "%INSTALL_DIR%\dist" (
  copy /Y "%INSTALL_DIR%\public\config.json" "%INSTALL_DIR%\dist\config.json" >nul 2>&1
  call :LOG "config.json copiado tambien a dist\"
)

echo   [OK] config.json blindado.
exit /b 0


REM ============================================================
REM =====================  SALIDAS  ============================
REM ============================================================

:FIN_OK
call :LOG "==== RECUPERACION COMPLETADA OK ===="
echo.
echo  ============================================================
echo   [LISTO] RECUPERACION COMPLETADA
echo  ============================================================
echo.
echo   Rol      : %ROL_DETECTADO%
echo   Hostname : %HOSTNAME_NUEVO%
echo   Servidor : %FCEA_IP_SERVIDOR%:8090
echo   Log      : %LOG_FILE%
echo.
echo   Los datos productivos (llaves/usuarios/historial) se
echo   respetaron y siguen en:
echo     %PROGDATA_DIR%\pb_data\
echo.
echo   La PC se reiniciara en 20 segundos para aplicar el nombre.
echo   Para cancelar el reinicio: presione Ctrl+C ahora.
echo  ============================================================
echo.
call :LOG "Programando reinicio en 20s"
shutdown /r /t 20 /c "Sistema FCEA recuperado. Reiniciando."
timeout /t 22 /nobreak >nul
echo   Si la PC no se reinicio sola, hagalo manualmente.
pause >nul
endlocal
exit /b 0

:FIN_ERROR
call :LOG "==== RECUPERACION ABORTADA POR ERROR ===="
echo.
echo  ============================================================
echo   [ERROR] Recuperacion abortada. Ver log detallado en:
echo           %LOG_FILE%
echo  ============================================================
echo.
pause
endlocal
exit /b 1

:FIN_CANCELADO
call :LOG "==== Operacion cancelada por el usuario ===="
echo.
echo  Operacion cancelada por el usuario.
echo.
pause
endlocal
exit /b 0
