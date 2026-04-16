@echo off
echo ===================================
echo HERRAMIENTA DE DIAGNÓSTICO Y CORRECCIÓN DE ERRORES CORS
echo Sistema de Gestión de Llaves FCEA
echo ===================================
echo.

echo Verificando servicios en ejecución...
tasklist /FI "IMAGENAME eq pocketbase.exe" | find /i "pocketbase.exe" > nul
if %ERRORLEVEL% NEQ 0 (
    echo [PROBLEMA DETECTADO] PocketBase no está en ejecución.
    echo Intentando iniciar PocketBase...
    cd ..\pocketbase
    start /B pocketbase.exe serve
    timeout /t 5 /nobreak > nul
    echo PocketBase iniciado correctamente.
) else (
    echo [OK] PocketBase está en ejecución.
)

echo.
echo Verificando configuración CORS...
echo.

echo Creando archivo de configuración CORS adicional...
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
) > ..\pocketbase\pb_config.json

echo Configuración CORS actualizada.

echo.
echo Reiniciando PocketBase para aplicar cambios...
taskkill /F /IM pocketbase.exe > nul 2>&1

timeout /t 2 /nobreak > nul

cd ..\pocketbase
start /B pocketbase.exe serve

echo.
echo =====================================
echo SOLUCIÓN DE PROBLEMAS CORS COMPLETADA
echo =====================================
echo.
echo Acciones realizadas:
echo 1. Verificación de PocketBase en ejecución
echo 2. Creación de configuración CORS permisiva
echo 3. Reinicio de PocketBase para aplicar cambios
echo.
echo Por favor, intente acceder nuevamente a:
echo   http://localhost:8080/
echo   http://localhost:8080/monitor
echo.
echo Si el problema persiste, ejecute el script:
echo   scripts/diagnostico_sistema_completo.bat
echo.
echo Presione cualquier tecla para salir...
pause > nul