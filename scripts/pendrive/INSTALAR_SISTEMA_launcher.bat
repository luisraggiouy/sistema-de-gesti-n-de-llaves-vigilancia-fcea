@echo off
REM ============================================================
REM  Sistema de Gestion de Llaves FCEA - LANZADOR DEL PENDRIVE
REM ============================================================
REM
REM  SOLO 2 OPCIONES DE INSTALACION:
REM
REM    [1] DESARROLLO EN 1 SOLA PC
REM        Instala todo (servidor + monitor + terminales) en
REM        una unica PC. Ideal para pruebas, demos y la PC del
REM        desarrollador.
REM
REM    [2] PRODUCCION EN 3 PCs (autodeteccion de rol y hardware)
REM        Esta PC se detecta automaticamente como:
REM          - servidor + monitor de vigilancia, o
REM          - terminal-A / terminal-B / dashboard.
REM        El hardware (tactil vs tradicional) tambien se
REM        detecta automaticamente. No pregunta nada.
REM
REM  Al terminar la instalacion, se abre Chrome automaticamente
REM  con el monitor o la terminal correspondiente, con TODOS los
REM  datos del pendrive ya cargados (llaves, usuarios, vigilantes,
REM  autorizaciones, objetos olvidados, historial, etc.).
REM ============================================================

setlocal EnableDelayedExpansion
title Sistema FCEA - Instalador

REM ------------------------------------------------------------
REM  PASO 1: Auto-elevacion a Administrador (UAC)
REM ------------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
  echo.
  echo  Solicitando permisos de Administrador...
  echo  Aparecera una ventana de "Control de cuentas de usuario";
  echo  haga click en SI para continuar.
  echo.
  echo  Se abrira una nueva ventana negra elevada. NO la cierre
  echo  hasta ver el mensaje final del instalador.
  echo.
  REM  IMPORTANTE: lanzamos "cmd.exe /k" en vez del .bat directo.
  REM  Motivos:
  REM    1) Si el .bat tiene cualquier error temprano (ruta con
  REM       espacios, tildes o caracteres especiales; parser CMD
  REM       fallando; etc.) la ventana NO se cierra al instante
  REM       y el usuario puede leer el error.
  REM    2) Lanzar el .bat "pelado" con Start-Process -FilePath
  REM       '%~f0' fallaba silenciosamente cuando la ruta del
  REM       pendrive tenia espacios (ej: "E:\INSTALAR SISTEMA.bat"),
  REM       produciendo el sintoma: "pantalla negra, UAC, se cerro
  REM       sin hacer nada".
  powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/k', '\"%~f0\"' -Verb RunAs"
  exit /b
)

REM Asegurar que el directorio actual sea la carpeta del .bat
REM y no C:\Windows\System32 (default tras Start-Process RunAs).
pushd "%~dp0" 2>nul

set "PENDRIVE_ROOT=%~dp0"
if "%PENDRIVE_ROOT:~-1%"=="\" set "PENDRIVE_ROOT=%PENDRIVE_ROOT:~0,-1%"

set "INSTALL_DIR=C:\sistema-llaves-fcea"

REM ------------------------------------------------------------
REM  Encabezado
REM ------------------------------------------------------------
cls
echo.
echo  ============================================================
echo                  Sistema de Gestion de Llaves
echo                Facultad de Ciencias Economicas
echo                       UDELAR - v2.2
echo  ============================================================
echo.

REM ------------------------------------------------------------
REM  PASO 2: Detectar si hay un sistema VALIDO previamente instalado
REM
REM  Una instalacion se considera "valida y completa" si tiene:
REM    - pocketbase\pocketbase.exe     (binario del servidor)
REM    - pocketbase\pb_data\data.db    (base de datos)
REM    - public\config.json o dist\index.html (frontend instalado)
REM
REM  Si encontramos SOLO la carpeta pero faltan archivos clave,
REM  asumimos que es un residuo de una desinstalacion incompleta
REM  y la borramos en silencio antes de seguir, en lugar de
REM  confundir al usuario con un menu de "reinstalar/actualizar".
REM ------------------------------------------------------------
REM  (v5.1) La base productiva puede estar en:
REM    a) C:\ProgramData\FCEA-Sistema-Llaves\pb_data\data.db  (produccion)
REM    b) %INSTALL_DIR%\pocketbase\pb_data\data.db            (legacy/dev)
set "SISTEMA_VALIDO=0"
if exist "%INSTALL_DIR%\pocketbase\pocketbase.exe" (
  if exist "C:\ProgramData\FCEA-Sistema-Llaves\pb_data\data.db" (
    set "SISTEMA_VALIDO=1"
  )
  if exist "%INSTALL_DIR%\pocketbase\pb_data\data.db" (
    set "SISTEMA_VALIDO=1"
  )
)

if "!SISTEMA_VALIDO!"=="1" (
  echo  Se detecto un sistema YA INSTALADO en:
  echo    %INSTALL_DIR%
  echo.
  echo  Que desea hacer?
  echo.
  echo    [1] ACTUALIZAR SOLO DATOS ^(base de datos^)
  echo        Refresca UNICAMENTE pb_data\ ^(usuarios, llaves,
  echo        historial^). NO actualiza codigo ni scripts ni
  echo        la interfaz. Elija esta opcion SOLO si el sistema
  echo        ya esta funcionando bien y solo quiere cargar
  echo        datos nuevos.
  echo        Si vino a aplicar un UPDATE del sistema
  echo        ^(cambios de UI, scripts, kiosk, etc.^),
  echo        ELIJA [2] REINSTALAR DESDE CERO.
  echo.
  echo    [2] REINSTALAR DESDE CERO ^(recomendado para updates^)
  echo        Vuelve a copiar todo el sistema ^(codigo + scripts +
  echo        interfaz + datos^). Los datos actuales se respaldan
  echo        automaticamente en C:\backup_fcea_pre_reinstalacion_*.
  echo.
  echo    [3] CANCELAR
  echo.
  echo  ============================================================
  set /p OPCION_INI="Opcion [1/2/3]: "
  if "!OPCION_INI!"=="1" goto ACTUALIZAR_DATOS
  if "!OPCION_INI!"=="2" goto MENU_PRINCIPAL
  if "!OPCION_INI!"=="3" goto CANCELAR
  echo Opcion invalida. Cancelando.
  goto CANCELAR
)

REM Si existe la carpeta pero NO es un sistema valido, es residuo.
REM Limpiamos antes de continuar para que el instalador interno no
REM se confunda y para no mostrar el menu de "reinstalar/actualizar".
if exist "%INSTALL_DIR%" (
  echo  Se detectaron archivos residuales en %INSTALL_DIR%
  echo  ^(instalacion incompleta o desinstalacion previa con archivos
  echo  en uso^). Limpiando antes de continuar...
  echo.
  taskkill /F /IM pocketbase.exe >nul 2>&1
  REM Matar node.exe y chrome.exe del sistema FCEA por si quedaron handles
  powershell -NoProfile -Command ^
    "Get-CimInstance Win32_Process -Filter \"Name='node.exe'\" | Where-Object { $_.CommandLine -match 'sistema-llaves-fcea' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1
  powershell -NoProfile -Command ^
    "Get-CimInstance Win32_Process -Filter \"Name='chrome.exe'\" | Where-Object { $_.CommandLine -match '127\.0\.0\.1:(5173|4173|8090)' -or $_.CommandLine -match 'sistema-llaves-fcea' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1
  timeout /t 3 /nobreak >nul

  REM Limpiar tareas programadas residuales (asi el chequeo de salud
  REM no se dispara antes de tiempo en la instalacion nueva).
  for %%T in (
    "FCEA-Backup-Semanal" "FCEA-Backup-Diario" "FCEA-Watchdog-PocketBase"
    "FCEA-Watchdog" "FCEA-Chequeo-Salud" "FCEA-Mantenimiento-Diario"
    "FCEA-Inicio-Automatico" "FCEA-Sistema-Llaves-AutoStart"
  ) do (
    schtasks /Delete /TN %%~T /F >nul 2>&1
  )

  for /L %%i in (1,1,3) do (
    if exist "%INSTALL_DIR%" (
      attrib -R -S -H "%INSTALL_DIR%\*.*" /S /D >nul 2>&1
      rmdir /S /Q "%INSTALL_DIR%" 2>nul
      if exist "%INSTALL_DIR%" timeout /t 2 /nobreak >nul
    )
  )
  if exist "%INSTALL_DIR%" (
    echo  [ERROR] No se pudo limpiar la carpeta residual %INSTALL_DIR%
    echo          Cierre TODAS las ventanas del sistema FCEA y reinicie
    echo          la PC. Luego vuelva a ejecutar este instalador.
    echo.
    pause
    exit /b 2
  )
  echo  Residuos limpiados. Continuando con instalacion limpia...
  echo.
)

REM ============================================================
REM  PASO 3: MENU PRINCIPAL - SOLO 2 OPCIONES
REM ============================================================
:MENU_PRINCIPAL
cls
echo.
echo  ============================================================
echo   ELIJA EL TIPO DE INSTALACION
echo  ============================================================
echo.
echo    [1] DESARROLLO EN 1 SOLA PC
echo        Instala todo el sistema en esta unica PC:
echo          - PocketBase ^(servidor de datos^)
echo          - Monitor de Vigilancia
echo          - Terminal de Usuario
echo          - Dashboard de reportes
echo        Boton en la UI para alternar entre vistas.
echo        Ideal para pruebas, demos y el desarrollador.
echo.
echo    [2] PRODUCCION EN 3 PCs ^(autodeteccion^)
echo        Instalacion en una de las 3 PCs reales:
echo          - El ROL ^(servidor/terminal-A/terminal-B/dashboard^)
echo            se detecta automaticamente por hostname / IP.
echo          - El HARDWARE ^(tactil vs tradicional^) se detecta
echo            automaticamente por los drivers de Windows.
echo        No pregunta nada mas: ejecute en cada PC del puesto.
echo.
echo    [3] SALIR
echo.
echo  ============================================================
set /p MODO="Seleccione [1/2/3]: "

if "%MODO%"=="1" goto MODO_DESARROLLO
if "%MODO%"=="2" goto MODO_PRODUCCION
if "%MODO%"=="3" goto CANCELAR

echo Opcion invalida. Cancelando.
goto CANCELAR

REM ============================================================
REM  OPCION 1: DESARROLLO EN 1 SOLA PC
REM ============================================================
:MODO_DESARROLLO
set "FCEA_MODO=desarrollo"
set "FCEA_ROL=monitor"
set "FCEA_HW=desarrollo"
set "FCEA_IP_SERVIDOR=127.0.0.1"
echo.
echo  [Modo elegido] DESARROLLO en 1 sola PC.
echo  - Rol     : %FCEA_ROL%  ^(todo junto^)
echo  - Hardware: %FCEA_HW%
echo.
goto CONFIRMAR_E_INSTALAR

REM ============================================================
REM  OPCION 2: PRODUCCION CON AUTODETECCION DE ROL Y HARDWARE
REM ============================================================
:MODO_PRODUCCION
set "FCEA_MODO=produccion"

echo.
echo  ============================================================
echo   AUTODETECCION DE ROL Y HARDWARE
echo  ============================================================
echo.
echo  Detectando hostname, red e interfaces de hardware...
echo.

REM Llamar al detector PowerShell que devuelve "rol|hardware|ip_servidor"
set "DETECTOR=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\lib\autodetectar_rol.ps1"
if not exist "%DETECTOR%" (
  echo  [ERROR] No se encontro el detector automatico en:
  echo    %DETECTOR%
  echo.
  pause
  goto CANCELAR
)

for /f "delims=" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%DETECTOR%"') do set "AUTODETEC=%%i"

REM Formato esperado: rol|hardware|ip_servidor
for /f "tokens=1,2,3 delims=|" %%a in ("!AUTODETEC!") do (
  set "FCEA_ROL=%%a"
  set "FCEA_HW=%%b"
  set "FCEA_IP_SERVIDOR=%%c"
)

if "!FCEA_ROL!"=="" (
  echo  [ERROR] La autodeteccion no devolvio un rol valido.
  echo          Salida del detector: !AUTODETEC!
  echo.
  pause
  goto CANCELAR
)

echo  Resultado de la autodeteccion:
echo    Rol      : !FCEA_ROL!
echo    Hardware : !FCEA_HW!
echo    Servidor : !FCEA_IP_SERVIDOR!
echo    Hostname : %COMPUTERNAME%
echo.

goto CONFIRMAR_E_INSTALAR

REM ============================================================
REM  CONFIRMAR E INSTALAR
REM ============================================================
:CONFIRMAR_E_INSTALAR
echo.
echo  ============================================================
echo   RESUMEN DE LA INSTALACION
echo  ============================================================
echo   Modo           : !FCEA_MODO!
echo   Rol            : !FCEA_ROL!
echo   Hardware       : !FCEA_HW!
echo   IP servidor    : !FCEA_IP_SERVIDOR!
echo   Carpeta destino: %INSTALL_DIR%
echo  ============================================================
echo.
echo  Pasos que se ejecutaran ^(sin mas preguntas^):
echo    [1/5] Copiar sistema desde pendrive ^(con barra de progreso^)
echo    [2/5] Copiar Node.js portable
echo    [3/5] Configurar PocketBase y firewall
echo    [4/5] Restaurar TODOS los datos del pendrive
echo          ^(llaves, vigilantes, usuarios, autorizaciones,
echo           objetos olvidados, historial^)
echo    [5/5] Abrir Chrome automaticamente con el sistema corriendo
echo.
echo  Tiempo estimado: 5 a 15 minutos.
echo.
set /p CONFIRMAR="Continuar? [S/N]: "
if /i not "%CONFIRMAR%"=="S" goto CANCELAR

REM ------------------------------------------------------------
REM  Si ya existia instalacion previa, respaldarla
REM ------------------------------------------------------------
if exist "%INSTALL_DIR%" (
  set STAMP=%date:~6,4%-%date:~3,2%-%date:~0,2%_%time:~0,2%-%time:~3,2%
  set STAMP=!STAMP: =0!
  set "PRE_BACKUP=C:\backup_fcea_pre_reinstalacion_!STAMP!"
  echo.
  echo Respaldando instalacion previa en !PRE_BACKUP! ...
  mkdir "!PRE_BACKUP!" >nul 2>&1
  if exist "%INSTALL_DIR%\pocketbase\pb_data" (
    robocopy "%INSTALL_DIR%\pocketbase\pb_data" "!PRE_BACKUP!\pb_data" /MIR /NFL /NDL /NJH /NJS /NP >nul
  )
  if exist "%INSTALL_DIR%\public\config.json" (
    copy /Y "%INSTALL_DIR%\public\config.json" "!PRE_BACKUP!\config.json" >nul
  )
  taskkill /F /IM pocketbase.exe >nul 2>&1
  timeout /t 2 /nobreak >nul
  echo Eliminando carpeta previa...
  rmdir /S /Q "%INSTALL_DIR%"
)

REM ------------------------------------------------------------
REM  PASO 4: COPIAR EL SISTEMA CON BARRA DE PROGRESO
REM ------------------------------------------------------------
echo.
echo  ============================================================
echo   [1/5] COPIANDO SISTEMA DESDE EL PENDRIVE
echo  ============================================================

set "LIB_COPIAR=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\lib\copiar_con_progreso.ps1"
if exist "!LIB_COPIAR!" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "!LIB_COPIAR!" ^
    -Origen "%PENDRIVE_ROOT%\sistema-llaves-fcea" ^
    -Destino "%INSTALL_DIR%" ^
    -Etiqueta "Copiando sistema (codigo + datos + binarios)"
) else (
  echo [AVISO] copiar_con_progreso.ps1 no encontrado. Usando robocopy.
  robocopy "%PENDRIVE_ROOT%\sistema-llaves-fcea" "%INSTALL_DIR%" /MIR /NJH /NJS
)

REM ------------------------------------------------------------
REM  PASO 5: COPIAR NODE.JS PORTABLE
REM ------------------------------------------------------------
echo.
echo  ============================================================
echo   [2/5] COPIANDO NODE.JS PORTABLE
echo  ============================================================
if exist "%PENDRIVE_ROOT%\node-portable\node\node.exe" (
  if exist "!LIB_COPIAR!" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!LIB_COPIAR!" ^
      -Origen "%PENDRIVE_ROOT%\node-portable" ^
      -Destino "%INSTALL_DIR%\node-portable" ^
      -Etiqueta "Copiando Node.js portable"
  ) else (
    robocopy "%PENDRIVE_ROOT%\node-portable" "%INSTALL_DIR%\node-portable" /MIR /NJH /NJS
  )
) else (
  echo [AVISO] El pendrive no contiene Node.js portable.
  echo         Si la PC no tiene Node.js, los pasos siguientes fallaran.
)

REM ------------------------------------------------------------
REM  PASO 6: EJECUTAR EL INSTALADOR INTERNO (sin preguntar nada)
REM ------------------------------------------------------------
echo.
echo  ============================================================
echo   [3/5] CONFIGURANDO POCKETBASE Y FRONTEND
echo   [4/5] RESTAURANDO TODOS LOS DATOS DEL PENDRIVE
echo  ============================================================
echo.

REM Marcar que la restauracion debe hacerse SIN preguntar
set "FCEA_RESTAURAR_AUTO=1"

REM IMPORTANTE: pasarle al INSTALAR.bat interno la ruta REAL del
REM pendrive. Sin esto, el interno recibe "cd" a C:\sistema-llaves-fcea
REM y su heuristica %~dp0..\..\.. le da C:\ (no el pendrive), lo que
REM hace que no encuentre Node.js portable ni pb_data del pendrive.
set "FCEA_PENDRIVE_ROOT=%PENDRIVE_ROOT%"

cd /d "%INSTALL_DIR%"
call scripts\install\INSTALAR.bat

if errorlevel 1 (
  echo.
  echo  [ERROR] La instalacion fallo. Revise los mensajes anteriores.
  echo.
  pause
  exit /b 1
)

REM ------------------------------------------------------------
REM  IMPORTANTE: tras "call INSTALAR.bat" las variables FCEA_*
REM  se perdieron por el "endlocal" del instalador interno.
REM  Releemos los valores reales desde public\config.json para
REM  mostrar el resumen final correcto.
REM ------------------------------------------------------------
set "FINAL_ROL=desconocido"
set "FINAL_MODO=desconocido"
set "FINAL_HW=desconocido"
if exist "%INSTALL_DIR%\public\config.json" (
  for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-Content '%INSTALL_DIR%\public\config.json' -Raw | ConvertFrom-Json).rol"') do set "FINAL_ROL=%%i"
  for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-Content '%INSTALL_DIR%\public\config.json' -Raw | ConvertFrom-Json).modo"') do set "FINAL_MODO=%%i"
  for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-Content '%INSTALL_DIR%\public\config.json' -Raw | ConvertFrom-Json).hardware"') do set "FINAL_HW=%%i"
)

REM ------------------------------------------------------------
REM  PASO 7: ABRIR CHROME AUTOMATICAMENTE CON EL SISTEMA
REM ------------------------------------------------------------
echo.
echo  ============================================================
echo   [5/5] INICIANDO EL SISTEMA Y ABRIENDO CHROME
echo  ============================================================
echo.
echo   Lanzando INICIAR.bat con modo automatico:
echo   arranca PocketBase + frontend + Chrome con el monitor /
echo   terminal segun el rol detectado ^(!FINAL_ROL!^).
echo.

REM Lanzar INICIAR.bat en una ventana NORMAL (no minimizada) la
REM primera vez para que el usuario vea el progreso. El parametro
REM "/auto" hace que se cierre solo a los 10 segundos.
start "FCEA - Iniciando Sistema" cmd /c "%INSTALL_DIR%\scripts\install\INICIAR.bat /auto"

REM Dar tiempo a que Chrome se levante visible al usuario
echo   Esperando 10 segundos a que el sistema termine de arrancar...
timeout /t 10 /nobreak >nul

REM ------------------------------------------------------------
REM  PASO 8: CONFIGURAR INICIO AUTOMATICO (sin intervencion del usuario)
REM
REM  Crea la tarea programada de Windows "FCEA-Sistema-Llaves-AutoStart"
REM  para que INICIAR.bat se ejecute automaticamente al iniciar sesion.
REM  Ya corremos con permisos de Administrador (UAC del inicio de este
REM  launcher), asi que se registra sin pedir nada mas.
REM  El script es idempotente: si la tarea ya existe la reemplaza.
REM ------------------------------------------------------------
echo.
echo  ============================================================
echo   [6/6] CONFIGURANDO INICIO AUTOMATICO DEL SISTEMA
echo  ============================================================
echo   El sistema arrancara solo cada vez que se prenda esta PC.
echo.
set "AUTOINIT_SCRIPT=%INSTALL_DIR%\scripts\install\CONFIGURAR_INICIO_AUTOMATICO.ps1"
if exist "%AUTOINIT_SCRIPT%" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%AUTOINIT_SCRIPT%"
  if errorlevel 1 (
    echo   [AVISO] La configuracion de inicio automatico fallo.
    echo           El sistema fue instalado pero NO arrancara solo al prender la PC.
    echo           Podes correr manualmente:
    echo             powershell -ExecutionPolicy Bypass -File "%AUTOINIT_SCRIPT%"
  ) else (
    echo   [OK] Inicio automatico configurado.
  )
) else (
  echo   [AVISO] No se encontro %AUTOINIT_SCRIPT%
  echo           El sistema fue instalado pero NO arrancara solo al prender la PC.
)

echo.
echo  ============================================================
echo   [OK] INSTALACION COMPLETADA Y SISTEMA CORRIENDO
echo  ============================================================
echo.
echo   Modo     : !FINAL_MODO!
echo   Rol      : !FINAL_ROL!
echo   Hardware : !FINAL_HW!
echo   Carpeta  : %INSTALL_DIR%
echo.
echo   El sistema deberia estar abierto en Chrome ahora mismo.
echo.
echo   Si Chrome NO se abrio automaticamente, ejecute a mano:
echo     %INSTALL_DIR%\scripts\install\INICIAR.bat
echo.
echo   Para que arranque solo cuando se prenda la PC:
echo     powershell -ExecutionPolicy Bypass -File ^
echo       "%INSTALL_DIR%\scripts\install\CONFIGURAR_INICIO_AUTOMATICO.ps1"
echo.
echo  ============================================================
echo.
echo  Presione cualquier tecla para cerrar este instalador.
echo  ^(El sistema seguira corriendo en otras ventanas.^)
echo.
pause >nul
exit /b 0

REM ============================================================
REM  RUTA: ACTUALIZAR SOLO DATOS (no toca el codigo)
REM ============================================================
:ACTUALIZAR_DATOS
echo.
echo  ============================================================
echo   ACTUALIZANDO DATOS DEL SISTEMA
echo  ============================================================
echo.

echo [1/4] Suspendiendo watchdog ^(si esta activo^)...
schtasks /End /TN "FCEA-Watchdog-PocketBase" >nul 2>&1
schtasks /End /TN "FCEA-Watchdog" >nul 2>&1

echo [2/4] Deteniendo PocketBase...
taskkill /F /IM pocketbase.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo [3/4] Respaldando datos actuales en C:\backup_fcea_pre_actualizacion_*...
set STAMP=%date:~6,4%-%date:~3,2%-%date:~0,2%_%time:~0,2%-%time:~3,2%
set STAMP=%STAMP: =0%
set "PRE_BACKUP=C:\backup_fcea_pre_actualizacion_%STAMP%"
mkdir "%PRE_BACKUP%" >nul 2>&1
if exist "%INSTALL_DIR%\pocketbase\pb_data" (
  robocopy "%INSTALL_DIR%\pocketbase\pb_data" "%PRE_BACKUP%\pb_data" /MIR /NFL /NDL /NJH /NJS /NP >nul
  echo       Backup pre-actualizacion guardado en %PRE_BACKUP%
)

echo [4/4] Copiando datos del pendrive con progreso...
set "PENDRIVE_PBDATA=%PENDRIVE_ROOT%\sistema-llaves-fcea\pocketbase\pb_data"
set "PENDRIVE_PBBACKUPS=%PENDRIVE_ROOT%\sistema-llaves-fcea\pocketbase\pb_backups"
if not exist "%PENDRIVE_PBDATA%\data.db" (
  echo.
  echo  [ERROR] El pendrive no contiene datos productivos.
  echo          No se pudo actualizar. Verifique el pendrive.
  echo.
  pause
  exit /b 1
)

set "LIB_COPIAR=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\lib\copiar_con_progreso.ps1"
if exist "!LIB_COPIAR!" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "!LIB_COPIAR!" ^
    -Origen "!PENDRIVE_PBDATA!" ^
    -Destino "%INSTALL_DIR%\pocketbase\pb_data" ^
    -Etiqueta "Copiando pb_data (datos productivos)"
) else (
  robocopy "!PENDRIVE_PBDATA!" "%INSTALL_DIR%\pocketbase\pb_data" /MIR /NJH /NJS
)

if exist "!PENDRIVE_PBBACKUPS!" (
  if exist "!LIB_COPIAR!" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!LIB_COPIAR!" ^
      -Origen "!PENDRIVE_PBBACKUPS!" ^
      -Destino "%INSTALL_DIR%\pocketbase\pb_backups" ^
      -Etiqueta "Copiando pb_backups (historicos)"
  ) else (
    robocopy "!PENDRIVE_PBBACKUPS!" "%INSTALL_DIR%\pocketbase\pb_backups" /MIR /NJH /NJS
  )
)

echo.
echo  ============================================================
echo   [OK] DATOS ACTUALIZADOS CORRECTAMENTE
echo  ============================================================
echo   Backup previo en : %PRE_BACKUP%
echo   Reiniciando el sistema con los nuevos datos...
echo  ============================================================
echo.

schtasks /Run /TN "FCEA-Watchdog-PocketBase" >nul 2>&1
schtasks /Run /TN "FCEA-Watchdog" >nul 2>&1

REM Relanzar el sistema automaticamente
start "FCEA - Sistema" /MIN cmd /c "%INSTALL_DIR%\scripts\install\INICIAR.bat"

echo  Presione una tecla para cerrar...
pause >nul
exit /b 0

REM ============================================================
:CANCELAR
echo.
echo  Operacion cancelada por el usuario.
echo.
pause >nul
exit /b 0

endlocal
