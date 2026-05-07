@echo off
echo ===================================
echo INICIADOR DEL SISTEMA DE LLAVES FCEA
echo ===================================
echo.

cd /d "%~dp0"

echo [1/5] Iniciando configuracion CORS...
if not exist "pocketbase\pb_config.json" (
  echo Creando archivo de configuracion CORS...
  (
  echo {
  echo   "options": {
  echo     "http": {
  echo       "cors": {
  echo         "enabled": true,
  echo         "allowOrigin": "*",
  echo         "allowMethods": ["GET", "POST", "PUT", "PATCH", "DELETE"],
  echo         "allowHeaders": ["Content-Type", "Authorization"],
  echo         "exposeHeaders": [],
  echo         "maxAge": 86400
  echo       }
  echo     }
  echo   }
  echo }
  ) > pocketbase\pb_config.json
  echo Configuracion CORS creada.
) else (
  echo Configuracion CORS ya existe.
)

echo.
echo [2/5] Comprobando servidor PocketBase...
tasklist /FI "IMAGENAME eq pocketbase.exe" | find /i "pocketbase.exe" > nul
if %ERRORLEVEL% NEQ 0 (
  echo PocketBase no esta en ejecucion, iniciando...
  call scripts\iniciar_pocketbase.bat
) else (
  echo PocketBase ya esta en ejecucion.
)

echo.
echo [3/5] Verificando carpetas de datos...
if not exist "pocketbase\pb_data" (
  echo Creando carpeta pb_data...
  mkdir "pocketbase\pb_data"
)

echo.
echo [4/5] Iniciando WATCHDOG COMPLETO (PocketBase + Frontend)...
echo Iniciando monitor de proteccion en segundo plano...
start "WATCHDOG-COMPLETO-FCEA" /MIN powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0scripts\watchdog_completo.ps1"
timeout /t 3 /nobreak >nul
echo Watchdog completo iniciado.

echo.
echo [5/5] Esperando que el frontend este listo para abrir el navegador...
echo Esperando 20 segundos para que Vite arranque completamente...
timeout /t 20 /nobreak >nul

REM Verificar si el puerto 8080 esta activo
:check_port
netstat -ano | findstr ":8080" | findstr "LISTENING" > nul
if %ERRORLEVEL% NEQ 0 (
  echo Puerto 8080 aun no disponible, esperando 5 segundos mas...
  timeout /t 5 /nobreak >nul
  goto check_port
)

echo Puerto 8080 activo. Abriendo navegador...

REM Intentar abrir con Chrome primero, luego con el navegador predeterminado
set CHROME_PATH=
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
  set CHROME_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe
)
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
  set CHROME_PATH=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
)

if defined CHROME_PATH (
  echo Abriendo Chrome con las paginas del sistema...
  start "" "%CHROME_PATH%" --new-window "http://localhost:8080/terminal" "http://localhost:8080/monitor"
) else (
  echo Chrome no encontrado. Abriendo con navegador predeterminado...
  start "" "http://localhost:8080/terminal"
  timeout /t 2 /nobreak >nul
  start "" "http://localhost:8080/monitor"
)

echo.
echo ===================================
echo SISTEMA INICIADO CORRECTAMENTE
echo ===================================
echo.
echo WATCHDOG COMPLETO ACTIVO:
echo   - PocketBase (backend) protegido
echo   - Frontend (Vite) protegido
echo   - Reinicio automatico si se caen
echo   - Verificacion cada 2 minutos
echo.
echo El sistema esta funcionando. Acceda en:
echo   Terminal: http://localhost:8080/terminal
echo   Monitor:  http://localhost:8080/monitor
echo.
echo Informacion de depuracion:
echo - Frontend: puerto 8080
echo - Backend (PocketBase): puerto 8090
echo - Log watchdog: scripts\watchdog_completo.log
echo.
echo Para detener el sistema, cierre las ventanas de comando abiertas.
echo.
echo Presione cualquier tecla para salir de este script...
pause > nul
