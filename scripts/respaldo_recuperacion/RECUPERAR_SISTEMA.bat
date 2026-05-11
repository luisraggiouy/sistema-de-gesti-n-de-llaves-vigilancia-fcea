@echo off
title RESTAURACION SISTEMA LLAVES FCEA
color 0A

echo =====================================================
echo   RESTAURACION COMPLETA DEL SISTEMA DE LLAVES FCEA
echo =====================================================
echo.
echo Este proceso restaurara el sistema completo en esta
echo computadora, incluyendo todos los datos historicos.
echo.
echo Presione cualquier tecla para continuar...
pause > nul

REM Detectar la unidad del pendrive automaticamente
set "USB_DRIVE=%~d0"
set "RECOVERY_DIR=%USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA"
set "SISTEMA_DIR=C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"

echo.
echo Pendrive detectado en: %USB_DRIVE%
echo Carpeta de recuperacion: %RECOVERY_DIR%
echo Carpeta destino: %SISTEMA_DIR%
echo.

echo [1/7] Verificando archivos de recuperacion...
if not exist "%RECOVERY_DIR%\sistema" (
    echo.
    echo ERROR: No se encontro la carpeta "%RECOVERY_DIR%\sistema"
    echo Verifique que el pendrive sea el correcto.
    echo.
    pause
    exit /b 1
)
echo     OK - Archivos encontrados.

echo.
echo [2/7] Verificando Node.js...
node --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo     Node.js NO esta instalado.
    if exist "%RECOVERY_DIR%\instaladores\node-setup.msi" (
        echo     Instalando Node.js desde el pendrive...
        start /wait msiexec /i "%RECOVERY_DIR%\instaladores\node-setup.msi" /passive
        echo     Node.js instalado. Reinicie este script.
        pause
        exit /b 0
    ) else (
        echo     ERROR: Descargue Node.js de https://nodejs.org/ e instalelo.
        pause
        exit /b 1
    )
) else (
    for /f "tokens=*" %%v in ('node --version 2^>nul') do echo     OK - Node.js %%v instalado
)

echo.
echo [3/7] Respaldando datos existentes (si los hay)...
if exist "%SISTEMA_DIR%\pocketbase\pb_data\data.db" (
    echo     Respaldando base de datos existente...
    mkdir "%SISTEMA_DIR%\respaldo_pre_restauracion" 2>nul
    xcopy "%SISTEMA_DIR%\pocketbase\pb_data" "%SISTEMA_DIR%\respaldo_pre_restauracion\pb_data\" /E /I /Q /Y
    echo     OK - Respaldo guardado.
) else (
    echo     No se encontro instalacion previa (normal en primera instalacion).
)

echo.
echo [4/7] Copiando archivos del sistema desde el pendrive...
echo     (esto puede tardar 1-3 minutos)
if not exist "%SISTEMA_DIR%" mkdir "%SISTEMA_DIR%"
xcopy "%RECOVERY_DIR%\sistema" "%SISTEMA_DIR%" /E /I /Q /Y
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR en la copia de archivos. Codigo: %ERRORLEVEL%
    pause
    exit /b 1
)
echo     OK - Archivos del sistema copiados.

echo.
echo [5/7] Restaurando base de datos mas reciente...
if exist "%RECOVERY_DIR%\respaldos_db\pb_data_ultimo\data.db" (
    echo     Restaurando datos historicos desde el pendrive...
    if not exist "%SISTEMA_DIR%\pocketbase\pb_data" mkdir "%SISTEMA_DIR%\pocketbase\pb_data"
    xcopy "%RECOVERY_DIR%\respaldos_db\pb_data_ultimo" "%SISTEMA_DIR%\pocketbase\pb_data\" /E /I /Q /Y
    echo     OK - Datos historicos restaurados.
) else (
    echo     ADVERTENCIA: No se encontraron datos historicos en el pendrive.
)

echo.
echo [6/7] Iniciando el sistema...
echo.

REM Iniciar PocketBase solo si NO esta corriendo
echo     Verificando PocketBase...
tasklist /FI "IMAGENAME eq pocketbase.exe" 2>nul | find /i "pocketbase.exe" > nul
if %ERRORLEVEL% NEQ 0 (
    echo     Iniciando PocketBase (backend en puerto 8090)...
    start "PocketBase-FCEA" /MIN "%SISTEMA_DIR%\pocketbase\pocketbase.exe" serve --http=127.0.0.1:8090
    timeout /t 4 /nobreak >nul
    echo     OK - PocketBase iniciado.
) else (
    echo     OK - PocketBase ya estaba corriendo.
)

REM Verificar si Vite ya esta corriendo en 8080
netstat -ano 2>nul | findstr ":8080" | findstr "LISTENING" > nul
if %ERRORLEVEL% NEQ 0 (
    echo     Iniciando frontend Vite (puerto 8080)...
    start "Frontend-FCEA" cmd /k "cd /d %SISTEMA_DIR% && npm run dev -- --port 8080 --host"
    echo.
    echo     Esperando que el frontend arranque (max 60 segundos)...
    set /a intentos=0
    :esperar
    set /a intentos+=1
    if %intentos% GTR 12 (
        echo     Tiempo de espera agotado. Continuando de todas formas...
        goto abrir_navegador
    )
    netstat -ano 2>nul | findstr ":8080" | findstr "LISTENING" > nul
    if %ERRORLEVEL% NEQ 0 (
        echo     Esperando Vite... intento %intentos%/12
        timeout /t 5 /nobreak >nul
        goto esperar
    )
    echo     OK - Frontend listo en puerto 8080.
) else (
    echo     OK - Frontend ya estaba corriendo en puerto 8080.
)

:abrir_navegador
echo.
echo [7/7] Abriendo Chrome con el sistema...
timeout /t 2 /nobreak >nul

if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    echo     Abriendo Monitor en Chrome...
    start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --new-window "http://localhost:8080/monitor"
    timeout /t 2 /nobreak >nul
    echo     Abriendo Terminal en Chrome...
    start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" "http://localhost:8080/terminal"
) else if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --new-window "http://localhost:8080/monitor"
    timeout /t 2 /nobreak >nul
    start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" "http://localhost:8080/terminal"
) else (
    start "" "http://localhost:8080/monitor"
    timeout /t 2 /nobreak >nul
    start "" "http://localhost:8080/terminal"
)

echo.
echo =====================================================
echo   RESTAURACION COMPLETADA EXITOSAMENTE
echo =====================================================
echo.
echo El sistema esta funcionando en:
echo   Monitor:  http://localhost:8080/monitor
echo   Terminal: http://localhost:8080/terminal
echo.
echo IMPORTANTE: No cierre la ventana negra "Frontend-FCEA"
echo Si la cierra, el sistema dejara de funcionar.
echo.
echo Para volver a abrir el navegador en el futuro:
echo   Ejecute ABRIR_NAVEGADOR.bat desde:
echo   C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\
echo.
echo Presione cualquier tecla para cerrar esta ventana...
pause > nul
