@echo off
echo ================================================
echo HERRAMIENTA DE DIAGNÓSTICO COMPLETO DEL SISTEMA
echo Sistema de Gestión de Llaves FCEA
echo Versión 1.0
echo ================================================
echo.
echo Ejecutando diagnóstico completo...
echo Hora de inicio: %TIME%
echo.

REM Crear directorio para informes si no existe
if not exist ".\diagnostico" mkdir ".\diagnostico"
set "informe=.\diagnostico\informe_diagnostico_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "informe=%informe: =0%"

echo =================== INICIO DIAGNÓSTICO =================== > "%informe%"
echo Fecha: %DATE% >> "%informe%"
echo Hora: %TIME% >> "%informe%"
echo. >> "%informe%"

echo 1. VERIFICANDO SERVICIOS Y PROCESOS
echo ------------------------------------ >> "%informe%"
echo 1. VERIFICANDO SERVICIOS Y PROCESOS >> "%informe%"
echo. >> "%informe%"

REM Verificar PocketBase
echo [*] Estado de PocketBase: >> "%informe%"
tasklist /FI "IMAGENAME eq pocketbase.exe" | find /i "pocketbase.exe" > nul
if %ERRORLEVEL% NEQ 0 (
    echo     [PROBLEMA] PocketBase no está en ejecución >> "%informe%"
    echo [PROBLEMA] PocketBase no está en ejecución.
    
    echo     [ACCIÓN] Intentando iniciar PocketBase... >> "%informe%"
    echo Intentando iniciar PocketBase...
    
    cd ..\pocketbase
    start /B pocketbase.exe serve
    timeout /t 5 /nobreak > nul
    cd ..\scripts
    
    tasklist /FI "IMAGENAME eq pocketbase.exe" | find /i "pocketbase.exe" > nul
    if %ERRORLEVEL% EQU 0 (
        echo     [RESUELTO] PocketBase iniciado correctamente >> "%informe%"
        echo PocketBase iniciado correctamente.
    ) else (
        echo     [ERROR CRÍTICO] No se pudo iniciar PocketBase >> "%informe%"
        echo [ERROR CRÍTICO] No se pudo iniciar PocketBase.
    )
) else (
    echo     [OK] PocketBase está en ejecución >> "%informe%"
    echo [OK] PocketBase está en ejecución.
)
echo. >> "%informe%"

REM Verificar otros procesos relevantes
echo [*] Otros procesos relevantes: >> "%informe%"
echo Verificando otros procesos relevantes...
tasklist /FI "IMAGENAME eq node.exe" >> "%informe%" 2>&1

echo. >> "%informe%"
echo.

echo 2. VERIFICANDO CONEXIONES DE RED
echo -------------------------------- >> "%informe%"
echo 2. VERIFICANDO CONEXIONES DE RED >> "%informe%"
echo. >> "%informe%"

REM Verificar puerto 8080 (PocketBase)
echo [*] Puerto 8080 (PocketBase): >> "%informe%"
netstat -ano | find ":8090" > nul
if %ERRORLEVEL% NEQ 0 (
    echo     [PROBLEMA] Puerto 8090 no está en uso >> "%informe%"
    echo [PROBLEMA] Puerto 8090 no está en uso.
) else (
    echo     [OK] Puerto 8090 está en uso >> "%informe%"
    echo [OK] Puerto 8090 está en uso.
)

REM Verificar puerto 5173/3000 (Servidor de desarrollo)
echo [*] Puerto de desarrollo (5173/3000): >> "%informe%"
netstat -ano | find ":5173" > nul
set dev_port_status=%ERRORLEVEL%
if %dev_port_status% NEQ 0 (
    netstat -ano | find ":3000" > nul
    set dev_port_status=%ERRORLEVEL%
)

if %dev_port_status% NEQ 0 (
    echo     [PROBLEMA] Puerto de desarrollo no está en uso >> "%informe%"
    echo [PROBLEMA] Puerto de desarrollo no está en uso.
    echo     [ACCIÓN] Puede ser necesario reiniciar el servidor de desarrollo: "npm run dev" >> "%informe%"
    echo Puede ser necesario reiniciar el servidor de desarrollo: "npm run dev"
) else (
    echo     [OK] Puerto de desarrollo está en uso >> "%informe%"
    echo [OK] Puerto de desarrollo está en uso.
)
echo. >> "%informe%"
echo.

echo 3. VERIFICANDO SISTEMA DE ARCHIVOS
echo ---------------------------------- >> "%informe%"
echo 3. VERIFICANDO SISTEMA DE ARCHIVOS >> "%informe%"
echo. >> "%informe%"

REM Verificar existencia de archivos clave
echo [*] Archivos clave del sistema: >> "%informe%"
echo Verificando archivos clave del sistema...

set "archivos_esenciales=..\index.html ..\src\main.tsx ..\pocketbase\pocketbase.exe"
set "archivos_faltantes="
set hay_faltantes=false

for %%f in (%archivos_esenciales%) do (
    if not exist "%%f" (
        echo     [PROBLEMA] Archivo no encontrado: %%f >> "%informe%"
        echo [PROBLEMA] Archivo no encontrado: %%f
        set hay_faltantes=true
        set "archivos_faltantes=!archivos_faltantes! %%f"
    ) else (
        echo     [OK] Archivo encontrado: %%f >> "%informe%"
    )
)

if "%hay_faltantes%"=="true" (
    echo [PROBLEMA] Faltan archivos esenciales del sistema.
) else (
    echo [OK] Todos los archivos esenciales están presentes.
)
echo. >> "%informe%"

REM Verificar permisos de escritura en directorios críticos
echo [*] Permisos de escritura en directorios críticos: >> "%informe%"
echo Verificando permisos de escritura...

set "directorios_criticos=..\pocketbase\pb_data ..\public"
set "test_file=test_write_permission.tmp"

for %%d in (%directorios_criticos%) do (
    echo     Probando directorio: %%d >> "%informe%"
    
    if not exist "%%d" (
        echo     [ERROR] Directorio no existe: %%d >> "%informe%"
        echo [ERROR] Directorio no existe: %%d
    ) else (
        type nul > "%%d\%test_file%" 2>nul
        if exist "%%d\%test_file%" (
            del "%%d\%test_file%" >nul 2>&1
            echo     [OK] Permiso de escritura en %%d >> "%informe%"
        ) else (
            echo     [PROBLEMA] Sin permiso de escritura en %%d >> "%informe%"
            echo [PROBLEMA] Sin permiso de escritura en %%d.
        )
    )
)
echo. >> "%informe%"
echo.

echo 4. VERIFICANDO CONFIGURACIÓN CORS
echo --------------------------------- >> "%informe%"
echo 4. VERIFICANDO CONFIGURACIÓN CORS >> "%informe%"
echo. >> "%informe%"

REM Verificar configuración CORS
echo [*] Archivo de configuración CORS: >> "%informe%"
if not exist "..\pocketbase\pb_config.json" (
    echo     [PROBLEMA] Archivo de configuración CORS no encontrado >> "%informe%"
    echo [PROBLEMA] Archivo de configuración CORS no encontrado.
    echo     [ACCIÓN] Ejecutando corrección de CORS... >> "%informe%"
    echo Ejecutando corrección de CORS...
    
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
    
    echo     [ACCIÓN] Reiniciando PocketBase para aplicar cambios... >> "%informe%"
    echo Reiniciando PocketBase para aplicar cambios...
    
    taskkill /F /IM pocketbase.exe > nul 2>&1
    timeout /t 2 /nobreak > nul
    cd ..\pocketbase
    start /B pocketbase.exe serve
    cd ..\scripts
    timeout /t 5 /nobreak > nul
    
    echo     [RESUELTO] Configuración CORS aplicada y PocketBase reiniciado >> "%informe%"
    echo [RESUELTO] Configuración CORS aplicada y PocketBase reiniciado.
) else (
    echo     [OK] Archivo de configuración CORS encontrado >> "%informe%"
    echo [OK] Archivo de configuración CORS encontrado.
    
    REM Verificar contenido de la configuración CORS
    type ..\pocketbase\pb_config.json | find "cors" > nul
    if %ERRORLEVEL% NEQ 0 (
        echo     [PROBLEMA] Configuración CORS no válida >> "%informe%"
        echo [PROBLEMA] Configuración CORS no válida.
        echo     [ACCIÓN] Ejecutando corrección de CORS... >> "%informe%"
        echo Ejecutando corrección de CORS...
        
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
        
        echo     [ACCIÓN] Reiniciando PocketBase para aplicar cambios... >> "%informe%"
        echo Reiniciando PocketBase para aplicar cambios...
        
        taskkill /F /IM pocketbase.exe > nul 2>&1
        timeout /t 2 /nobreak > nul
        cd ..\pocketbase
        start /B pocketbase.exe serve
        cd ..\scripts
        timeout /t 5 /nobreak > nul
        
        echo     [RESUELTO] Configuración CORS actualizada y PocketBase reiniciado >> "%informe%"
        echo [RESUELTO] Configuración CORS actualizada y PocketBase reiniciado.
    ) else (
        echo     [OK] Configuración CORS válida >> "%informe%"
        echo [OK] Configuración CORS válida.
    )
)
echo. >> "%informe%"
echo.

echo 5. VERIFICANDO BASE DE DATOS
echo ---------------------------- >> "%informe%"
echo 5. VERIFICANDO BASE DE DATOS >> "%informe%"
echo. >> "%informe%"

REM Verificar archivo de base de datos
if exist "..\pocketbase\pb_data\data.db" (
    echo [*] Archivo de base de datos: >> "%informe%"
    echo     [OK] Archivo de base de datos encontrado >> "%informe%"
    echo [OK] Archivo de base de datos encontrado.
    
    REM Verificar tamaño de la base de datos
    for %%A in ("..\pocketbase\pb_data\data.db") do set db_size=%%~zA
    echo     [INFO] Tamaño de la base de datos: !db_size! bytes >> "%informe%"
    echo [INFO] Tamaño de la base de datos: !db_size! bytes.
    
    REM Verificar si el tamaño es anormalmente pequeño
    if !db_size! LSS 10000 (
        echo     [ADVERTENCIA] El archivo de base de datos es anormalmente pequeño >> "%informe%"
        echo [ADVERTENCIA] El archivo de base de datos es anormalmente pequeño.
    )
) else (
    echo [*] Archivo de base de datos: >> "%informe%"
    echo     [PROBLEMA CRÍTICO] Archivo de base de datos no encontrado >> "%informe%"
    echo [PROBLEMA CRÍTICO] Archivo de base de datos no encontrado.
    echo     [ACCIÓN RECOMENDADA] Restaurar desde una copia de seguridad >> "%informe%"
    echo [ACCIÓN RECOMENDADA] Restaurar desde una copia de seguridad.
)
echo. >> "%informe%"
echo.

echo 6. PRUEBA DE CONECTIVIDAD A SERVICIOS
echo ------------------------------------- >> "%informe%"
echo 6. PRUEBA DE CONECTIVIDAD A SERVICIOS >> "%informe%"
echo. >> "%informe%"

REM Intentar acceder a endpoints críticos
echo [*] Prueba de conectividad a endpoints críticos: >> "%informe%"
echo Realizando pruebas de conectividad...

for %%u in ("http://localhost:8090" "http://localhost:8090/api/") do (
    echo     Probando conexión a: %%u >> "%informe%"
    curl -s -o nul -w "%%{http_code}" %%u > temp_status.txt 2>nul
    set /p status=<temp_status.txt
    del temp_status.txt
    
    if "!status!"=="200" (
        echo     [OK] Conexión exitosa a %%u (HTTP 200) >> "%informe%"
        echo [OK] Conexión exitosa a %%u.
    ) else (
        echo     [PROBLEMA] Fallo de conexión a %%u (HTTP !status!) >> "%informe%"
        echo [PROBLEMA] Fallo de conexión a %%u (HTTP !status!).
        echo     [ACCIÓN] Puede ser necesario reiniciar PocketBase >> "%informe%"
    )
)
echo. >> "%informe%"
echo.

echo 7. RECOMENDACIONES Y RESUMEN
echo ---------------------------- >> "%informe%"
echo 7. RECOMENDACIONES Y RESUMEN >> "%informe%"
echo. >> "%informe%"

REM Contar problemas encontrados
type "%informe%" | find /c "[PROBLEMA]" > temp_count.txt
set /p problema_count=<temp_count.txt
del temp_count.txt

type "%informe%" | find /c "[RESUELTO]" > temp_count.txt
set /p resuelto_count=<temp_count.txt
del temp_count.txt

type "%informe%" | find /c "[OK]" > temp_count.txt
set /p ok_count=<temp_count.txt
del temp_count.txt

echo [*] Resumen del diagnóstico: >> "%informe%"
echo     - Componentes correctos: !ok_count! >> "%informe%"
echo     - Problemas detectados: !problema_count! >> "%informe%"
echo     - Problemas resueltos: !resuelto_count! >> "%informe%"
echo. >> "%informe%"

echo [*] Resumen del diagnóstico:
echo     - Componentes correctos: !ok_count!
echo     - Problemas detectados: !problema_count!
echo     - Problemas resueltos: !resuelto_count!
echo.

if !problema_count! GTR !resuelto_count! (
    set /a pendientes=!problema_count!-!resuelto_count!
    
    echo [*] Recomendaciones finales: >> "%informe%"
    echo     - Se encontraron !pendientes! problemas sin resolver >> "%informe%"
    echo     - Revise el informe de diagnóstico completo para más detalles >> "%informe%"
    echo     - Considere contactar al soporte técnico si los problemas persisten >> "%informe%"
    
    echo [*] Recomendaciones finales:
    echo     - Se encontraron !pendientes! problemas sin resolver
    echo     - Revise el informe de diagnóstico completo para más detalles
    echo     - Considere contactar al soporte técnico si los problemas persisten
) else (
    echo [*] Recomendaciones finales: >> "%informe%"
    echo     - Todos los problemas detectados fueron resueltos automáticamente >> "%informe%"
    echo     - El sistema debería funcionar correctamente ahora >> "%informe%"
    
    echo [*] Recomendaciones finales:
    echo     - Todos los problemas detectados fueron resueltos automáticamente
    echo     - El sistema debería funcionar correctamente ahora
    
    if !problema_count! GTR 0 (
        echo     - Se recomienda reiniciar cualquier navegador que estuviera usando el sistema >> "%informe%"
        echo     - Se recomienda reiniciar cualquier navegador que estuviera usando el sistema
    )
)
echo. >> "%informe%"
echo.

echo =================== FIN DIAGNÓSTICO =================== >> "%informe%"

echo Diagnóstico completado.
echo Hora de finalización: %TIME%
echo.
echo Se ha guardado un informe detallado en:
echo %informe%
echo.
echo Presione cualquier tecla para salir...
pause > nul