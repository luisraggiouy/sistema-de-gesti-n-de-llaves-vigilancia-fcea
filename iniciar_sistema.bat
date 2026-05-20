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
tasklist /FI "IMAGENAME eq pocketbase.exe" 2>nul | find /i "pocketbase.exe" > nul
if %ERRORLEVEL% NEQ 0 (
  start "PocketBase-FCEA" /MIN "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase\pocketbase.exe" serve --http=127.0.0.1:8090
  timeout /t 4 /nobreak >nul
  echo PocketBase iniciado.
) else (
  echo PocketBase ya estaba corriendo.
)

echo [3/5] Iniciando Frontend (Vite)...
if not exist "node_modules" (
  echo Instalando dependencias (npm install)...
  npm install --no-audit --no-fund
  if %ERRORLEVEL% NEQ 0 (
    echo ERROR: npm install fallo.
    pause
    exit /b 1
  )
)

REM Iniciar Vite - cmd /k mantiene la ventana abierta con el proceso
start "Frontend-FCEA" cmd /k "cd /d C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea && npm run dev -- --port 8080 --host"

echo [4/5] Esperando que el frontend arranque (hasta 60 segundos)...
set /a intentos=0
:check_port
set /a intentos+=1
if %intentos% GTR 12 (
  echo AVISO: El frontend tarda mas de lo esperado. Abriendo navegador de todas formas...
  goto abrir_navegador
)
netstat -ano 2>nul | findstr ":8080" | findstr "LISTENING" > nul
if %ERRORLEVEL% NEQ 0 (
  echo   Esperando Vite... intento %intentos%/12
  timeout /t 5 /nobreak >nul
  goto check_port
)

:abrir_navegador
echo [5/5] Buscando navegador disponible...
timeout /t 2 /nobreak >nul

REM ============================================================
REM Detectar navegador disponible (Chrome, Edge, Firefox)
REM ============================================================
set "BROWSER="

if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    set "BROWSER=C:\Program Files\Google\Chrome\Application\chrome.exe"
    goto :abrir_con_browser
)
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    set "BROWSER=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    goto :abrir_con_browser
)
if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" (
    set "BROWSER=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
    goto :abrir_con_browser
)
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    set "BROWSER=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    goto :abrir_con_browser
)
if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" (
    set "BROWSER=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    goto :abrir_con_browser
)
if exist "C:\Program Files\Mozilla Firefox\firefox.exe" (
    set "BROWSER=C:\Program Files\Mozilla Firefox\firefox.exe"
    goto :abrir_con_browser
)
if exist "C:\Program Files (x86)\Mozilla Firefox\firefox.exe" (
    set "BROWSER=C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
    goto :abrir_con_browser
)

REM Usar navegador predeterminado del sistema
echo  Usando navegador predeterminado del sistema...
start "" "http://localhost:8080/monitor"
timeout /t 2 /nobreak >nul
start "" "http://localhost:8080/terminal"
goto :mostrar_fin

:abrir_con_browser
echo  Navegador: %BROWSER%
start "" "%BROWSER%" --new-window "http://localhost:8080/monitor"
timeout /t 2 /nobreak >nul
start "" "%BROWSER%" "http://localhost:8080/terminal"

:mostrar_fin
echo.
echo ===================================
echo  SISTEMA INICIADO
echo ===================================
echo.
echo  Monitor:  http://localhost:8080/monitor
echo  Terminal: http://localhost:8080/terminal
echo  Backend:  http://localhost:8090
echo.
echo  IMPORTANTE: No cierre la ventana "Frontend-FCEA"
echo  (es la ventana negra con el servidor Vite).
echo  Si la cierra, el sistema dejara de funcionar.
echo.
echo  Para volver a abrir el navegador: ejecute ABRIR_NAVEGADOR.bat
echo.
