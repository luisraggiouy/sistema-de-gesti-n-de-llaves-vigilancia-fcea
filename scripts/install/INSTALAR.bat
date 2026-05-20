@echo off
REM ============================================================
REM  Sistema de Gestion de Llaves FCEA v2.0
REM  Instalador unificado (4 modos)
REM ============================================================
REM
REM  Opciones de configuracion:
REM    1) Desarrollo / Demo (1 PC con monitor + terminal alternables)
REM    2) Economica         (3 PCs con teclado + mouse + monitor LCD)
REM    3) Mixta             (cabina tactil + 2 terminales con teclado/mouse)
REM    4) Ideal             (3 PCs con monitores tactiles)
REM
REM  Roles posibles dentro de los modos multi-PC:
REM    - SERVIDOR/MONITOR (cabina de vigilancia, 16 GB RAM)
REM    - TERMINAL-A       (puesto de usuarios A)
REM    - TERMINAL-B       (puesto de usuarios B)
REM    - DASHBOARD        (opcional, PC adicional para reportes)
REM ============================================================

setlocal EnableDelayedExpansion
cd /d "%~dp0\..\.."

echo.
echo ============================================================
echo  INSTALADOR - Sistema de Gestion de Llaves FCEA v2.0
echo ============================================================
echo.
echo  Modos de instalacion disponibles:
echo.
echo    [1] DESARROLLO / DEMO
echo        Una sola PC. Boton para alternar entre vista Monitor
echo        de Vigilancia y Terminal de Usuario. Util para demos
echo        y pruebas en una unica computadora.
echo.
echo    [2] PRODUCCION ECONOMICA (3 PCs)
echo        3 mini PCs conectadas por switch de red local.
echo        Todas con teclado + mouse + monitor LCD comun.
echo        - PC 1: cabina (servidor + monitor)
echo        - PC 2: terminal-A (puesto usuarios A)
echo        - PC 3: terminal-B (puesto usuarios B)
echo.
echo    [3] PRODUCCION MIXTA (3 PCs)
echo        Igual que la opcion 2, pero la PC de cabina tiene
echo        monitor TACTIL. Las 2 terminales siguen con teclado/mouse.
echo.
echo    [4] PRODUCCION IDEAL (3 PCs con monitor tactil)
echo        Las 3 PCs usan monitor tactil como unica interfaz.
echo        Sin teclado ni mouse fisicos: todo por pantalla tactil
echo        + teclado virtual con prediccion.
echo.
echo ============================================================
set /p MODO="Seleccione modo [1-4]: "

if "%MODO%"=="1" goto MODO_DESARROLLO
if "%MODO%"=="2" goto MODO_ECONOMICA
if "%MODO%"=="3" goto MODO_MIXTA
if "%MODO%"=="4" goto MODO_IDEAL
echo Opcion invalida. Abortando.
exit /b 1

REM ============================================================
REM  MODO 1: DESARROLLO / DEMO (1 PC)
REM ============================================================
:MODO_DESARROLLO
echo.
echo === MODO DESARROLLO seleccionado ===
echo.
call :ESCRIBIR_CONFIG "desarrollo" "monitor" "127.0.0.1" "127.0.0.1" "127.0.0.1" "false"
call :INSTALAR_DEPENDENCIAS
call :CONFIGURAR_SERVIDOR_LOCAL
echo.
echo  Modo desarrollo instalado.
echo  - PocketBase en  : http://127.0.0.1:8090
echo  - Frontend en    : http://127.0.0.1:5173 ^(npm run dev^)
echo                     o http://127.0.0.1:4173 ^(npm run preview^)
echo.
echo  En la UI veras un boton para alternar Monitor / Terminal.
goto FIN

REM ============================================================
REM  MODO 2, 3, 4: PRODUCCION (3 PCs)
REM ============================================================
:MODO_ECONOMICA
echo.
echo === MODO PRODUCCION ECONOMICA seleccionado ===
set FORZAR_TECLADO=false
goto SELECCIONAR_ROL

:MODO_MIXTA
echo.
echo === MODO PRODUCCION MIXTA seleccionado ===
REM En este modo solo la cabina tiene tactil. Cada PC define su propio
REM teclado_virtual_forzado segun sea cabina o terminal.
set FORZAR_TECLADO=auto
goto SELECCIONAR_ROL

:MODO_IDEAL
echo.
echo === MODO PRODUCCION IDEAL seleccionado ===
REM En las 3 PCs se asume monitor tactil; no se fuerza nada,
REM la deteccion automatica con pointer:coarse lo activa solo.
set FORZAR_TECLADO=auto
goto SELECCIONAR_ROL

:SELECCIONAR_ROL
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

REM Por modo mixto: solo si es S forzamos teclado virtual.
REM Por modo ideal: ninguno forzado, deteccion automatica.
REM Por modo economica: ninguno forzado (sin tactil).
set TECLADO_FORZADO=false
if "%FORZAR_TECLADO%"=="auto" if "%ROL_ID%"=="monitor" (
  REM Modo mixto + cabina = tactil
  if "%MODO%"=="3" set TECLADO_FORZADO=true
)

call :ESCRIBIR_CONFIG_PROD "!ROL_ID!" "!PB_URL!" "!IP_SERVIDOR!" "!TECLADO_FORZADO!"

if /i "%ROL%"=="S" (
  call :INSTALAR_DEPENDENCIAS
  call :CONFIGURAR_SERVIDOR_LOCAL
  echo.
  echo  Servidor instalado correctamente.
  echo  - PocketBase escucha en: http://0.0.0.0:8090
  echo  - Las terminales A/B deben usar: http://%COMPUTERNAME%:8090
  echo  - Anote la IP local de esta PC para configurar las terminales.
) else (
  call :INSTALAR_DEPENDENCIAS
  echo.
  echo  Terminal !ROL_ID! instalada correctamente.
  echo  - Apuntando a PocketBase: !PB_URL!
  echo  - Verifique conectividad con: ping !IP_SERVIDOR!
)

goto FIN

REM ============================================================
REM  SUBRUTINAS
REM ============================================================

:ESCRIBIR_CONFIG
REM Args: %1=modo %2=rol %3=ip_servidor %4=ip_term_a %5=ip_term_b %6=teclado_forzado
echo Escribiendo public\config.json (modo=%~1, rol=%~2)...
(
  echo {
  echo   "version": "2.0.0",
  echo   "modo": "%~1",
  echo   "rol": "%~2",
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
REM Args: %1=rol %2=pb_url %3=ip_servidor %4=teclado_forzado
echo Escribiendo public\config.json (rol=%~1, pb=%~2)...
(
  echo {
  echo   "version": "2.0.0",
  echo   "modo": "produccion",
  echo   "rol": "%~1",
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

:INSTALAR_DEPENDENCIAS
echo.
echo Instalando dependencias de Node.js (puede tardar)...
where npm >nul 2>nul
if errorlevel 1 (
  echo [ERROR] npm no encontrado. Instale Node.js LTS desde https://nodejs.org
  exit /b 1
)
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

:FIN
echo.
echo ============================================================
echo  Instalacion finalizada.
echo  Lea docs\INSTALACION.md para los siguientes pasos.
echo ============================================================
echo.
pause
endlocal
