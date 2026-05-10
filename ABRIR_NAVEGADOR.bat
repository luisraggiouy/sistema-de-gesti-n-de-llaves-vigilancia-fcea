@echo off
title Abrir Sistema de Llaves FCEA
color 0B

echo ===================================
echo  ABRIR SISTEMA DE LLAVES FCEA
echo ===================================
echo.
echo  Verificando que el sistema este corriendo...
echo.

REM Verificar si PocketBase esta corriendo
tasklist /FI "IMAGENAME eq pocketbase.exe" | find /i "pocketbase.exe" > nul
if %ERRORLEVEL% NEQ 0 (
    echo  [!] PocketBase NO esta corriendo. Iniciandolo...
    start "PocketBase-FCEA" /MIN cmd /c "cd /d C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase && pocketbase.exe serve --http=127.0.0.1:8090"
    timeout /t 4 /nobreak >nul
    echo  [OK] PocketBase iniciado.
) else (
    echo  [OK] PocketBase ya esta corriendo.
)

REM Verificar si el frontend esta corriendo en el puerto 8080
netstat -ano | findstr ":8080" | findstr "LISTENING" > nul
if %ERRORLEVEL% NEQ 0 (
    echo  [!] Frontend NO esta corriendo. Iniciandolo...
    start "Frontend-FCEA" /MIN cmd /c "cd /d C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea && npm run dev -- --port 8080 --host 2>&1"
    echo  [*] Esperando que el frontend arranque...
    set /a intentos=0
    :esperar_frontend
    set /a intentos+=1
    if %intentos% GTR 12 (
        echo  [!] El frontend tarda mas de lo esperado. Abriendo navegador de todas formas...
        goto abrir
    )
    netstat -ano | findstr ":8080" | findstr "LISTENING" > nul
    if %ERRORLEVEL% NEQ 0 (
        echo     Esperando... intento %intentos%/12
        timeout /t 5 /nobreak >nul
        goto esperar_frontend
    )
    echo  [OK] Frontend listo.
) else (
    echo  [OK] Frontend ya esta corriendo en puerto 8080.
)

:abrir
echo.
echo  Abriendo navegador...
timeout /t 1 /nobreak >nul

REM Buscar Chrome primero
set CHROME_PATH=
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    set CHROME_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe
)
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    set CHROME_PATH=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
)

REM Buscar Edge como alternativa
set EDGE_PATH=
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    set EDGE_PATH=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe
)
if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" (
    set EDGE_PATH=C:\Program Files\Microsoft\Edge\Application\msedge.exe
)

if defined CHROME_PATH (
    echo  Abriendo en Chrome...
    start "" "%CHROME_PATH%" --new-window "http://localhost:8080/monitor"
    timeout /t 2 /nobreak >nul
    start "" "%CHROME_PATH%" "http://localhost:8080/terminal"
) else if defined EDGE_PATH (
    echo  Chrome no encontrado. Abriendo en Edge...
    start "" "%EDGE_PATH%" --new-window "http://localhost:8080/monitor"
    timeout /t 2 /nobreak >nul
    start "" "%EDGE_PATH%" "http://localhost:8080/terminal"
) else (
    echo  Abriendo con navegador predeterminado...
    start "" "http://localhost:8080/monitor"
    timeout /t 2 /nobreak >nul
    start "" "http://localhost:8080/terminal"
)

echo.
echo ===================================
echo  LISTO
echo ===================================
echo.
echo  Monitor:  http://localhost:8080/monitor
echo  Terminal: http://localhost:8080/terminal
echo.
echo  Si el navegador muestra error, espere 10 segundos
echo  y recargue la pagina (F5).
echo.
timeout /t 5 /nobreak >nul
