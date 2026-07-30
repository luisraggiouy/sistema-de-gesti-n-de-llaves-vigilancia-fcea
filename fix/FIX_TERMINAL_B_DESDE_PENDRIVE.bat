@echo off
chcp 65001 >nul
title TERMINAL B - FIX DEFINITIVO PENDRIVE

echo ================================================================
echo  TERMINAL B - FIX ERROR 404 DESDE PENDRIVE
echo ================================================================
echo  Fecha: 30/07/2026 12:44
echo  PROBLEMA REAL: Servidor dev no esta corriendo en Terminal B
echo  SOLUCION: Iniciar servidor dev + PocketBase + config.json
echo ================================================================
echo.

REM Rutas absolutas para Terminal B
set "SISTEMA_DIR=C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
set "CONFIG_FILE=%SISTEMA_DIR%\public\config.json"

echo PROBLEMA IDENTIFICADO DESDE LAS FOTOS:
echo -------------------------------------
echo ✗ ERR_CONNECTION_REFUSED en http://127.0.0.1:5173/terminal
echo ✗ Servidor dev NO esta corriendo en Terminal B
echo ✗ PocketBase NO esta corriendo en puerto 8090
echo ✗ Script anterior intentaba rutas relativas desde pendrive
echo.

echo SOLUCION TERMINAL B:
echo -------------------
echo 1. Verificar si directorio sistema existe
echo 2. Crear/corregir config.json con rutas absolutas  
echo 3. Iniciar servidor dev desde Terminal B
echo 4. Iniciar PocketBase desde Terminal B
echo.

echo PASO 1: Verificando directorio sistema...
if not exist "%SISTEMA_DIR%" (
    echo ✗ ERROR: Directorio %SISTEMA_DIR% NO existe
    echo.
    echo SOLUCION: Terminal B debe tener el codigo fuente instalado
    echo Copie todo el sistema desde laptop desarrollo o Monitor vigilancia
    echo.
    goto :error_final
)
echo ✓ Directorio sistema encontrado: %SISTEMA_DIR%

echo.
echo PASO 2: Creando config.json para Terminal B...
if not exist "%SISTEMA_DIR%\public" (
    echo ! Creando carpeta public...
    mkdir "%SISTEMA_DIR%\public"
)

echo { > "%CONFIG_FILE%"
echo     "$schema": "./config.schema.json", >> "%CONFIG_FILE%"
echo     "version": "2.1.0", >> "%CONFIG_FILE%"
echo     "modo": "produccion", >> "%CONFIG_FILE%"
echo     "rol": "terminal-b", >> "%CONFIG_FILE%"
echo     "hardware": "tradicional", >> "%CONFIG_FILE%"
echo     "pocketbase_url": "http://127.0.0.1:8090", >> "%CONFIG_FILE%"
echo     "red": { >> "%CONFIG_FILE%"
echo         "ip_servidor": "127.0.0.1", >> "%CONFIG_FILE%"
echo         "ip_terminal_a": "127.0.0.1", >> "%CONFIG_FILE%"
echo         "ip_terminal_b": "127.0.0.1" >> "%CONFIG_FILE%"
echo     }, >> "%CONFIG_FILE%"
echo     "ui": { >> "%CONFIG_FILE%"
echo         "teclado_virtual_forzado": false, >> "%CONFIG_FILE%"
echo         "tema": "claro" >> "%CONFIG_FILE%"
echo     } >> "%CONFIG_FILE%"
echo } >> "%CONFIG_FILE%"

if exist "%CONFIG_FILE%" (
    echo ✓ config.json creado en: %CONFIG_FILE%
) else (
    echo ✗ ERROR: No se pudo crear config.json
    goto :error_final
)

echo.
echo PASO 3: Verificando si PocketBase existe...
if not exist "%SISTEMA_DIR%\pocketbase\pocketbase.exe" (
    echo ✗ ERROR: PocketBase no encontrado en %SISTEMA_DIR%\pocketbase\
    echo.
    echo SOLUCION: Copiar pocketbase.exe desde laptop desarrollo
    goto :error_final
)
echo ✓ PocketBase encontrado

echo.
echo PASO 4: Iniciando servicios en Terminal B...
echo.
echo ! IMPORTANTE: Abrir 2 ventanas CMD adicionales para:
echo.
echo VENTANA 1 - PocketBase:
echo   cd %SISTEMA_DIR%\pocketbase
echo   pocketbase.exe serve --http=127.0.0.1:8090
echo.
echo VENTANA 2 - Servidor dev:
echo   cd %SISTEMA_DIR%
echo   npm run dev
echo.
echo Después de que ambos servicios estén corriendo:
echo   http://127.0.0.1:5173/terminal debe funcionar
echo.

echo PASO 5: Intentando abrir Terminal B...
timeout /t 3 >nul
start "" "http://127.0.0.1:5173/terminal"
echo.

echo ================================================================
echo  INSTRUCCIONES FINALES TERMINAL B
echo ================================================================
echo.
echo 1. config.json creado con rol terminal-b ✓
echo 2. DEBE iniciar PocketBase en ventana separada:
echo    cd %SISTEMA_DIR%\pocketbase
echo    pocketbase.exe serve --http=127.0.0.1:8090
echo.
echo 3. DEBE iniciar servidor dev en ventana separada:
echo    cd %SISTEMA_DIR%
echo    npm run dev
echo.
echo 4. Después navegar a: http://127.0.0.1:5173/terminal
echo.
echo SI NO TIENE INSTALADO EL CODIGO FUENTE:
echo Copear todo desde laptop desarrollo o Monitor vigilancia
echo.
echo ================================================================
goto :final

:error_final
echo.
echo ================================================================
echo  ERROR: Terminal B no tiene el sistema instalado correctamente
echo ================================================================
echo.
echo SOLUCION: Instalar sistema completo en Terminal B
echo 1. Copiar desde laptop desarrollo: TODO el directorio 
echo    sistema-de-gesti-n-de-llaves-vigilancia-fcea
echo 2. Instalar Node.js en Terminal B
echo 3. npm install en el directorio copiado
echo 4. Ejecutar este script nuevamente
echo ================================================================

:final
echo.
echo Presione cualquier tecla para salir...
pause >nul