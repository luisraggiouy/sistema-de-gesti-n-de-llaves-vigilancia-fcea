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

set "USB_DRIVE=%~d0"
set "RECOVERY_DIR=%USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA"
set "SISTEMA_DIR=C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"

echo.
echo [1/7] Verificando archivos de recuperacion...
if not exist "%RECOVERY_DIR%\sistema" (
    echo ERROR: No se encontraron los archivos del sistema en el pendrive.
    echo Verifique que el pendrive sea el correcto.
    pause
    exit /b 1
)
echo     Archivos encontrados correctamente.

echo.
echo [2/7] Verificando Node.js...
node --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo     Node.js NO esta instalado en esta computadora.
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
    echo     Node.js ya esta instalado.
)

echo.
echo [3/7] Respaldando datos existentes (si los hay)...
if exist "%SISTEMA_DIR%\pocketbase\pb_data\data.db" (
    echo     Respaldando base de datos existente...
    mkdir "%SISTEMA_DIR%\respaldo_pre_restauracion" 2>nul
    xcopy "%SISTEMA_DIR%\pocketbase\pb_data" "%SISTEMA_DIR%\respaldo_pre_restauracion\pb_data\" /E /I /Q /Y
    echo     Respaldo guardado.
) else (
    echo     No se encontro instalacion previa.
)

echo.
echo [4/7] Copiando archivos del sistema...
echo     (esto puede tardar unos minutos)
if not exist "%SISTEMA_DIR%" mkdir "%SISTEMA_DIR%"
xcopy "%RECOVERY_DIR%\sistema" "%SISTEMA_DIR%" /E /I /Q /Y
echo     Archivos del sistema copiados.

echo.
echo [5/7] Restaurando base de datos mas reciente...
if exist "%RECOVERY_DIR%\respaldos_db\pb_data_ultimo\data.db" (
    echo     Restaurando datos historicos desde el pendrive...
    if not exist "%SISTEMA_DIR%\pocketbase\pb_data" mkdir "%SISTEMA_DIR%\pocketbase\pb_data"
    xcopy "%RECOVERY_DIR%\respaldos_db\pb_data_ultimo" "%SISTEMA_DIR%\pocketbase\pb_data\" /E /I /Q /Y
    echo     Datos historicos restaurados.
) else (
    echo     ADVERTENCIA: No se encontraron datos historicos.
)

echo.
echo [6/7] Instalando dependencias del frontend...
cd /d "%SISTEMA_DIR%"
if not exist "node_modules" (
    echo     Instalando dependencias (npm install)...
    echo     Esto puede tardar 2-5 minutos la primera vez...
    npm install --prefer-offline --no-audit --no-fund
    if %ERRORLEVEL% NEQ 0 (
        echo     npm install fallo. Usando build pre-compilado...
        goto usar_dist
    )
    echo     Dependencias instaladas.
) else (
    echo     Dependencias ya instaladas.
)

echo.
echo [7/7] Iniciando el sistema...
goto iniciar_sistema

:usar_dist
echo.
echo [7/7] Iniciando sistema con build pre-compilado (dist)...
if not exist "%SISTEMA_DIR%\dist\index.html" (
    echo ERROR CRITICO: No se encontro el build del sistema.
    pause
    exit /b 1
)

REM Iniciar PocketBase - SIN cmd /c para que no se cierre
echo     Iniciando PocketBase (backend)...
tasklist /FI "IMAGENAME eq pocketbase.exe" 2>nul | find /i "pocketbase.exe" > nul
if %ERRORLEVEL% NEQ 0 (
    start "PocketBase-FCEA" /MIN "%SISTEMA_DIR%\pocketbase\pocketbase.exe" serve --http=127.0.0.1:8090
    timeout /t 4 /nobreak >nul
)

REM Servir el dist con npx serve - cmd /k mantiene la ventana abierta
echo     Iniciando servidor web (puerto 8080)...
start "Frontend-FCEA" cmd /k "npx serve %SISTEMA_DIR%\dist -l 8080 -s"
timeout /t 6 /nobreak >nul
goto abrir_navegador

:iniciar_sistema
REM Configurar CORS de PocketBase
if not exist "pocketbase\pb_config.json" (
    (
    echo {
    echo   "options": {
    echo     "http": {
    echo       "cors": {
    echo         "enabled": true,
    echo         "allowOrigin": "*"
    echo       }
    echo     }
    echo   }
    echo }
    ) > pocketbase\pb_config.json
)

REM Iniciar PocketBase - SIN cmd /c para que no se cierre
echo     Iniciando PocketBase (backend)...
tasklist /FI "IMAGENAME eq pocketbase.exe" 2>nul | find /i "pocketbase.exe" > nul
if %ERRORLEVEL% NEQ 0 (
    start "PocketBase-FCEA" /MIN "%SISTEMA_DIR%\pocketbase\pocketbase.exe" serve --http=127.0.0.1:8090
    timeout /t 4 /nobreak >nul
)

REM Iniciar Frontend con Vite - cmd /k mantiene la ventana abierta
echo     Iniciando frontend (Vite dev server)...
start "Frontend-FCEA" cmd /k "cd /d %SISTEMA_DIR% && npm run dev -- --port 8080 --host"

echo     Esperando que el frontend arranque...
set /a intentos=0
:esperar
set /a intentos+=1
if %intentos% GTR 12 goto abrir_navegador
netstat -ano 2>nul | findstr ":8080" | findstr "LISTENING" > nul
if %ERRORLEVEL% NEQ 0 (
    echo     Esperando... intento %intentos%/12
    timeout /t 5 /nobreak >nul
    goto esperar
)

:abrir_navegador
echo.
echo     Abriendo Chrome...
timeout /t 2 /nobreak >nul

if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --new-window "http://localhost:8080/monitor"
    timeout /t 2 /nobreak >nul
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
pause
