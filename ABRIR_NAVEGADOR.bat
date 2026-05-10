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
tasklist /FI "IMAGENAME eq pocketbase.exe" 2>nul | find /i "pocketbase.exe" > nul
if %ERRORLEVEL% NEQ 0 (
    echo  [!] PocketBase NO esta corriendo. Iniciandolo...
    start "PocketBase-FCEA" /MIN "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase\pocketbase.exe" serve --http=127.0.0.1:8090
    timeout /t 4 /nobreak >nul
    echo  [OK] PocketBase iniciado.
) else (
    echo  [OK] PocketBase ya esta corriendo.
)

REM Verificar si el frontend esta corriendo en el puerto 8080
netstat -ano 2>nul | findstr ":8080" | findstr "LISTENING" > nul
if %ERRORLEVEL% NEQ 0 (
    echo  [!] Frontend NO esta corriendo. Iniciandolo...
    start "Frontend-FCEA" cmd /k "cd /d C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea && npm run dev -- --port 8080 --host"
    echo  [*] Esperando que el frontend arranque (30 segundos max)...
    set /a intentos=0
    :esperar_frontend
    set /a intentos+=1
    if %intentos% GTR 6 (
        echo  [!] Abriendo navegador de todas formas...
        goto abrir
    )
    netstat -ano 2>nul | findstr ":8080" | findstr "LISTENING" > nul
    if %ERRORLEVEL% NEQ 0 (
        echo     Esperando... %intentos%/6
        timeout /t 5 /nobreak >nul
        goto esperar_frontend
    )
    echo  [OK] Frontend listo.
) else (
    echo  [OK] Frontend ya esta corriendo en puerto 8080.
)

:abrir
echo.
echo  Abriendo navegador en 2 segundos...
timeout /t 2 /nobreak >nul

REM Abrir con el navegador predeterminado (funciona con Edge, Chrome, cualquiera)
start "" "http://localhost:8080/monitor"
timeout /t 2 /nobreak >nul
start "" "http://localhost:8080/terminal"

echo.
echo ===================================
echo  LISTO
echo ===================================
echo.
echo  Monitor:  http://localhost:8080/monitor
echo  Terminal: http://localhost:8080/terminal
echo.
echo  Si el navegador muestra error, espere 15 segundos
echo  y presione F5 para recargar.
echo.
pause
