@echo off
echo ===================================
echo INICIADOR DEL SISTEMA DE LLAVES FCEA
echo ===================================
echo.

echo [1/4] Iniciando configuracion CORS...
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
echo [2/4] Comprobando servidor PocketBase...
tasklist /FI "IMAGENAME eq pocketbase.exe" | find /i "pocketbase.exe" > nul
if %ERRORLEVEL% NEQ 0 (
  echo PocketBase no esta en ejecucion, iniciando...
  call scripts\iniciar_pocketbase.bat
) else (
  echo PocketBase ya esta en ejecucion.
)

echo.
echo [3/4] Verificando carpetas de datos...
if not exist "pocketbase\pb_data" (
  echo Creando carpeta pb_data...
  mkdir "pocketbase\pb_data"
)

echo.
echo [4/5] Iniciando watchdog de PocketBase...
echo Iniciando monitor en segundo plano...
start "Watchdog PocketBase" powershell.exe -ExecutionPolicy Bypass -WindowStyle Minimized -File "%~dp0watchdog_loop.ps1"
echo Watchdog iniciado (ventana minimizada).

echo.
echo [5/5] Iniciando servidor de desarrollo...
echo Ejecutando npm run dev en una nueva ventana...
start "Frontend Server" cmd /c "npm run dev"

echo.
echo ===================================
echo SISTEMA INICIADO CORRECTAMENTE
echo ===================================
echo.
echo WATCHDOG ACTIVO: PocketBase se reiniciara automaticamente si se cae.
echo.
echo El sistema ahora deberia funcionar. Abra su navegador en:
echo   http://localhost:8080/
echo.
echo Informacion de depuracion:
echo - Frontend: puerto 8080
echo - Backend (PocketBase): puerto 8090
echo.
echo Para detener el sistema, cierre las ventanas de comando abiertas.
echo.
echo Presione cualquier tecla para salir de este script...
pause > nul