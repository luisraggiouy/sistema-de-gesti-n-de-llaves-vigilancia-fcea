@echo off
title Abrir Sistema de Llaves FCEA
color 0B

echo ===================================
echo  ABRIR SISTEMA DE LLAVES FCEA
echo ===================================
echo.

set "SISTEMA_DIR=C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"

REM Verificar si PocketBase esta corriendo
echo  Verificando PocketBase...
tasklist /FI "IMAGENAME eq pocketbase.exe" 2>nul | find /i "pocketbase.exe" > nul
if %ERRORLEVEL% NEQ 0 (
    echo  [!] PocketBase NO esta corriendo. Iniciandolo...
    start "PocketBase-FCEA" /MIN "%SISTEMA_DIR%\pocketbase\pocketbase.exe" serve --http=127.0.0.1:8090
    timeout /t 4 /nobreak >nul
    echo  [OK] PocketBase iniciado.
) else (
    echo  [OK] PocketBase ya esta corriendo.
)

REM Verificar si el frontend esta corriendo en el puerto 8080
echo  Verificando Frontend...
netstat -ano 2>nul | findstr ":8080" | findstr "LISTENING" > nul
if %ERRORLEVEL% NEQ 0 (
    echo  [!] Frontend NO esta corriendo. Iniciandolo...
    start "Frontend-FCEA" cmd /k "cd /d %SISTEMA_DIR% && npm run dev -- --port 8080 --host"
    echo  [*] Esperando que el frontend arranque...
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
echo  Abriendo el sistema en el navegador...
timeout /t 2 /nobreak >nul

REM Usar explorer.exe para abrir URLs - funciona siempre, incluso como administrador
explorer.exe "http://localhost:8080/monitor"
timeout /t 3 /nobreak >nul
explorer.exe "http://localhost:8080/terminal"

echo.
echo ===================================
echo  LISTO
echo ===================================
echo.
echo  Monitor:  http://localhost:8080/monitor
echo  Terminal: http://localhost:8080/terminal
echo.
echo  IMPORTANTE: No cierre la ventana negra "Frontend-FCEA"
echo  Si la cierra, el sistema dejara de funcionar.
echo.
echo  Si el navegador muestra error, espere 15 segundos
echo  y presione F5 para recargar.
echo.
pause
