@echo off
title Sistema de Llaves FCEA
color 0A

echo ===================================
echo  SISTEMA DE LLAVES FCEA
echo ===================================
echo.

cd /d "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"

echo [1/5] Configurando CORS de PocketBase...
if not exist "pocketbase\pb_config.json" (
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
)

echo [2/5] Iniciando PocketBase (backend)...
tasklist /FI "IMAGENAME eq pocketbase.exe" | find /i "pocketbase.exe" > nul
if %ERRORLEVEL% NEQ 0 (
  start "PocketBase-FCEA" /MIN cmd /c "cd /d C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase && pocketbase.exe serve --http=127.0.0.1:8090"
  timeout /t 5 /nobreak >nul
  echo PocketBase iniciado.
) else (
  echo PocketBase ya estaba corriendo.
)

echo [3/5] Iniciando Frontend (Vite)...
REM Verificar que node_modules existe
if not exist "node_modules" (
  echo ERROR: node_modules no encontrado en C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea
  echo Ejecutando npm install...
  npm install
  if %ERRORLEVEL% NEQ 0 (
    echo ERROR: npm install fallo. Verifique la instalacion de Node.js.
    pause
    exit /b 1
  )
)

REM Iniciar Vite en segundo plano
start "Frontend-FCEA" /MIN cmd /c "cd /d C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea && npm run dev -- --port 8080 --host 2>&1"

echo [4/5] Esperando que el frontend arranque (hasta 60 segundos)...
set /a intentos=0
:check_port
set /a intentos+=1
if %intentos% GTR 12 (
  echo AVISO: El frontend tarda mas de lo esperado. Abriendo navegador de todas formas...
  goto abrir_navegador
)
netstat -ano | findstr ":8080" | findstr "LISTENING" > nul
if %ERRORLEVEL% NEQ 0 (
  echo   Esperando Vite... intento %intentos%/12
  timeout /t 5 /nobreak >nul
  goto check_port
)

:abrir_navegador
echo [5/5] Abriendo navegador...
timeout /t 2 /nobreak >nul

REM Buscar Chrome
set CHROME_PATH=
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
  set CHROME_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe
)
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
  set CHROME_PATH=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
)

if defined CHROME_PATH (
  echo Abriendo Chrome...
  start "" "%CHROME_PATH%" --new-window "http://localhost:8080/monitor"
  timeout /t 2 /nobreak >nul
  start "" "%CHROME_PATH%" "http://localhost:8080/terminal"
) else (
  echo Chrome no encontrado. Abriendo con navegador predeterminado...
  start "" "http://localhost:8080/monitor"
  timeout /t 2 /nobreak >nul
  start "" "http://localhost:8080/terminal"
)

echo.
echo ===================================
echo  SISTEMA INICIADO
echo ===================================
echo.
echo  Monitor:  http://localhost:8080/monitor
echo  Terminal: http://localhost:8080/terminal
echo  Backend:  http://localhost:8090
echo.
echo  Para detener: cierre las ventanas de PocketBase y Frontend
echo.
