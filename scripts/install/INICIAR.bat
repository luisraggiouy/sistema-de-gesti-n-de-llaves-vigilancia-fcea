@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM  Sistema de Gestion de Llaves FCEA v2.5
REM  Lanzador inteligente por rol y hardware
REM ============================================================
REM
REM  Lee public\config.json y arranca:
REM    - rol=monitor      -> PocketBase + frontend + Chrome con MONITOR
REM    - rol=terminal-a   -> Chrome apuntando al servidor en /terminal?id=A
REM    - rol=terminal-b   -> Chrome apuntando al servidor en /terminal?id=B
REM    - rol=dashboard    -> Chrome apuntando al servidor en /dashboard
REM
REM  Si hardware="tactil"        -> Chrome en --kiosk fullscreen
REM  Si hardware="tradicional"   -> Chrome --start-fullscreen
REM  Si hardware="desarrollo"    -> Chrome --start-maximized
REM
REM  v2.5: toda la logica de Chrome esta en
REM        scripts\lib\lanzar_navegador.ps1 (PowerShell limpio,
REM        sin ^ multilinea de CMD que rompian el quoting).
REM ============================================================

cd /d "%~dp0\..\.."

REM ------------------------------------------------------------
REM  Validar existencia de public\config.json
REM ------------------------------------------------------------
if not exist "public\config.json" (
  echo.
  echo  ============================================================
  echo   [ERROR] No existe public\config.json
  echo  ============================================================
  echo   Ejecute primero el INSTALADOR del pendrive
  echo   ^(INSTALAR_SISTEMA.bat^) o scripts\install\INSTALAR.bat
  echo.
  pause
  exit /b 1
)

REM ------------------------------------------------------------
REM  Validar que existe el script PowerShell de navegador
REM ------------------------------------------------------------
if not exist "scripts\lib\lanzar_navegador.ps1" (
  echo.
  echo  [AVISO] Falta scripts\lib\lanzar_navegador.ps1
  echo          Se intentara abrir el navegador con configuracion minima al final.
  echo.
)

REM ------------------------------------------------------------
REM  Leer rol, modo, hardware y pocketbase_url del config.json
REM ------------------------------------------------------------
set "ROL="
set "MODO="
set "HW="
set "PB_URL="

for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-Content public\config.json -Raw | ConvertFrom-Json).rol"') do set "ROL=%%i"
for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-Content public\config.json -Raw | ConvertFrom-Json).modo"') do set "MODO=%%i"
for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-Content public\config.json -Raw | ConvertFrom-Json).hardware"') do set "HW=%%i"
for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-Content public\config.json -Raw | ConvertFrom-Json).pocketbase_url"') do set "PB_URL=%%i"

if "%ROL%"==""  set "ROL=monitor"
if "%MODO%"=="" set "MODO=desarrollo"
if "%HW%"==""   set "HW=tradicional"
if "%PB_URL%"=="" set "PB_URL=http://127.0.0.1:8090"

echo.
echo  ============================================================
echo   Iniciando Sistema FCEA v2.5
echo  ============================================================
echo   - Modo      : %MODO%
echo   - Rol       : %ROL%
echo   - Hardware  : %HW%
echo   - PocketBase: %PB_URL%
echo  ============================================================
echo.

REM ------------------------------------------------------------
REM  1) Si soy el servidor (monitor), arrancar PocketBase
REM ------------------------------------------------------------
if /i "%ROL%"=="monitor" (
  echo [1/3] Arrancando servidor PocketBase...
  tasklist /FI "IMAGENAME eq pocketbase.exe" | find /I "pocketbase.exe" >nul
  if errorlevel 1 (
    REM Lanzar PocketBase con el wrapper auto-relanzador run_pocketbase.bat
    REM (incluye watchdog interno: si cae, se reinicia solo).
    REM Lanzado DESACOPLADO via WMI Win32_Process.Create.
    if exist "scripts\lib\run_pocketbase.bat" (
      if exist "scripts\lib\start_detached.ps1" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\lib\start_detached.ps1" -CommandLine "cmd /c scripts\lib\run_pocketbase.bat" -WorkingDirectory "%CD%"
      ) else (
        start "FCEA - PocketBase Server" /MIN cmd /c "scripts\lib\run_pocketbase.bat"
      )
      timeout /t 3 /nobreak >nul
      echo       PocketBase iniciado en puerto 8090.
    ) else if exist "pocketbase\start-server.bat" (
      start "FCEA - PocketBase Server" /MIN cmd /c "pocketbase\start-server.bat"
      timeout /t 3 /nobreak >nul
      echo       PocketBase iniciado en puerto 8090 ^(modo legacy^).
    ) else (
      echo       [AVISO] No se encontro run_pocketbase.bat ni start-server.bat.
    )
  ) else (
    echo       PocketBase ya esta corriendo. OK.
  )
) else (
  echo [1/3] No soy servidor ^(rol=%ROL%^). Verificando conectividad a %PB_URL%...
  powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri '%PB_URL%/api/health' -TimeoutSec 3 -UseBasicParsing; if ($r.StatusCode -eq 200) { Write-Host '       Servidor PocketBase OK.' } } catch { Write-Host '       [AVISO] No se pudo conectar al servidor. Verifique red y firewall.' }"
)

REM ------------------------------------------------------------
REM  2) Servir el frontend (dist\) en :5173
REM ------------------------------------------------------------
echo [2/3] Sirviendo frontend en http://127.0.0.1:5173 ...
if not exist "dist\index.html" (
  echo.
  echo  ============================================================
  echo   [ERROR] No existe dist\index.html
  echo  ============================================================
  echo   Ejecute el INSTALADOR o, dentro de la carpeta del sistema:
  echo     npm install
  echo     npm run build
  echo.
  pause
  exit /b 1
)

REM Verificar si ya hay un servidor estatico en 5173
netstat -ano | findstr /R /C:":5173 .*LISTENING" >nul
if errorlevel 1 (
  REM Servir el frontend DESACOPLADO usando WMI Win32_Process.Create
  REM (scripts\lib\start_detached.ps1).  Es la unica forma de que el
  REM proceso sobreviva al cierre del shell padre en Windows
  REM (las terminales integradas de VS Code/Cline imponen un Job Object
  REM que mata todos los descendientes; WMI lanza el proceso a traves
  REM de wmiprvse.exe, que esta fuera del Job, asi que sobrevive).
  REM
  REM Preferimos 'vite preview' (instalado en node_modules) porque es
  REM el servidor oficial que recomienda Vite, esta battle-tested y no
  REM requiere conexion a Internet.  Fallback: serve_dist.cjs (Node nativo).
  if not exist "scripts\lib\start_detached.ps1" (
    echo       [ERROR] Falta scripts\lib\start_detached.ps1
    echo               Sin este archivo el servidor moriria al cerrar la ventana.
  )

  REM Usamos el wrapper run_frontend.bat que tiene watchdog interno
  REM (loop que relanza el servidor si cae por cualquier motivo).
  REM Lanzado DESACOPLADO via WMI Win32_Process.Create para sobrevivir
  REM al cierre del shell padre.
  if exist "scripts\lib\run_frontend.bat" (
    echo       Lanzando run_frontend.bat ^(con watchdog interno^)...
    if exist "scripts\lib\start_detached.ps1" (
      powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\lib\start_detached.ps1" -CommandLine "cmd /c scripts\lib\run_frontend.bat" -WorkingDirectory "%CD%"
    ) else (
      start "FCEA - Frontend" /MIN cmd /c "scripts\lib\run_frontend.bat"
    )
  ) else (
    echo       [AVISO] No se encontro run_frontend.bat. Usando fallback...
    start "FCEA - Frontend" /MIN cmd /c "node node_modules\vite\bin\vite.js preview --port 5173 --host --strictPort"
  )

  REM Esperar activamente a que el puerto 5173 quede LISTENING.
  REM Maximo ~20 segundos (20 reintentos de 1s).
  echo       Esperando a que el servidor responda en 5173...
  set "FRONT_OK="
  for /L %%N in (1,1,20) do (
    if not defined FRONT_OK (
      timeout /t 1 /nobreak >nul
      netstat -ano | findstr /R /C:":5173 .*LISTENING" >nul && set "FRONT_OK=1"
    )
  )
  if defined FRONT_OK (
    echo       Frontend respondiendo en 5173. OK.
  ) else (
    echo       [AVISO] El frontend no respondio en 5173 despues de 20s.
    echo               Reintentando una vez en primer plano para ver errores...
    echo               ^(Cierre la ventana con Ctrl+C cuando quiera detener^)
    if exist "scripts\lib\serve_dist.cjs" (
      start "FCEA - Frontend (debug)" cmd /k "node scripts\lib\serve_dist.cjs 5173 dist"
    )
  )
) else (
  echo       Frontend ya esta sirviendo en 5173. OK.
)

REM ------------------------------------------------------------
REM  3) Lanzar navegador (todo en PowerShell aparte)
REM ------------------------------------------------------------
echo [3/3] Abriendo navegador para rol=%ROL% hardware=%HW% modo=%MODO%...

if exist "scripts\lib\lanzar_navegador.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\lib\lanzar_navegador.ps1" -Rol "%ROL%" -Modo "%MODO%" -Hardware "%HW%"
  if errorlevel 1 (
    echo.
    echo  [AVISO] El lanzador PowerShell devolvio error.
    echo          Abriendo URL con el navegador por defecto del sistema...
    start "" "http://127.0.0.1:5173/"
  )
) else (
  echo       Usando fallback ^(navegador por defecto del sistema^)...
  start "" "http://127.0.0.1:5173/"
)

echo.
echo  ============================================================
echo   Sistema iniciado correctamente.
echo  ============================================================
echo   - PocketBase   : %PB_URL% ^(solo en servidor^)
echo   - Frontend     : http://127.0.0.1:5173
echo   - Rol activo   : %ROL%
echo   - Modo         : %MODO%
echo   - Hardware     : %HW%
echo.
echo   Si el navegador no se abrio, abralo manualmente en:
echo     http://127.0.0.1:5173/
echo.
echo   Cierre esta ventana solo cuando quiera detener todo.
echo   ^(PocketBase y el frontend siguen en ventanas minimizadas^).
echo  ============================================================
echo.

REM Si fui lanzado desde el launcher del pendrive (start /MIN),
REM nos cerramos automaticamente despues de unos segundos.
REM Si fui lanzado a mano por el usuario, esperamos confirmacion.
if /i "%1"=="/auto" (
  timeout /t 10 /nobreak >nul
) else (
  echo Presione cualquier tecla para cerrar esta ventana...
  pause >nul
)
