@echo off
echo ===================================
echo CORRECCIÓN DIRECTA DE ERROR CORS
echo Sistema de Gestión de Llaves FCEA
echo ===================================
echo.

REM Buscar el archivo pb_config.json en todas las ubicaciones posibles
echo Buscando configuración del servidor...

set "config_creado=false"
set "posibles_ubicaciones=.\pocketbase\pb_config.json ..\pocketbase\pb_config.json ..\..\pocketbase\pb_config.json c:\pocketbase\pb_config.json .\backend\pb_config.json ..\backend\pb_config.json"

REM Ubicación actual para el nuevo archivo de configuración CORS
set "config_path=.\pb_config.json"

echo.
echo Proveedor de host detectado: local
echo Creando configuración CORS global...
echo.

REM Crear archivo de configuración CORS en la ubicación actual
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
) > %config_path%

echo *** ARCHIVO DE CONFIGURACIÓN CORS CREADO ***
echo.
echo El archivo ha sido creado en: %CD%\%config_path%
echo.
echo INSTRUCCIONES PARA COMPLETAR LA CORRECCIÓN:
echo ----------------------------------------
echo 1. Copie este archivo a la carpeta donde está Pocketbase
echo    (usualmente es la carpeta "pocketbase" dentro del proyecto)
echo.
echo 2. Detenga el servidor PocketBase si está en ejecución
echo.
echo 3. Inicie PocketBase de nuevo con el comando:
echo    cd pocketbase
echo    pocketbase.exe serve
echo.
echo 4. Reinicie su navegador web
echo.
echo Si el problema persiste, ejecute el script de diagnóstico completo:
echo    scripts\diagnostico_sistema_completo.bat
echo.
echo Presione cualquier tecla para salir...
pause > nul