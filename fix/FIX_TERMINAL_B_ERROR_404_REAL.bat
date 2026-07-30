@echo off
chcp 65001 >nul
title SOLUCION REAL Terminal B Error 404

echo ================================================================
echo  FIX TERMINAL B ERROR 404 - SOLUCION REAL
echo ================================================================
echo  Fecha: 30/07/2026 12:12
echo  PROBLEMA REAL IDENTIFICADO: Sistema no usa URL params (?id=A/B)
echo  SOLUCION REAL: Verificar servidor dev + PocketBase + config.json
echo ================================================================
echo.

echo ANALISIS DEL PROBLEMA REAL:
echo ----------------------------
echo ✓ El sistema NO lee parametros ?id=A/B de la URL
echo ✓ Terminal A y B van ambas a /terminal (mismo componente React)
echo ✓ La diferenciacion A/B se hace por config.json con "rol"
echo ✓ Error 404 indica que servidor de desarrollo no responde
echo.

echo PASO 1: Verificando si servidor dev esta corriendo...
echo.

REM Verificar si el puerto 5173 (Vite dev server) está en uso
netstat -an | find ":5173" >nul 2>&1
if errorlevel 1 (
    echo ✗ PROBLEMA ENCONTRADO: Servidor de desarrollo NO esta corriendo
    echo.
    echo SOLUCION: Ir al Monitor vigilancia y ejecutar:
    echo    cd C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea
    echo    npm run dev
    echo.
    echo El servidor debe arrancar y mostrar: "Local: http://localhost:5173/"
    echo.
    goto :diagnostico_adicional
) else (
    echo ✓ Puerto 5173 en uso - Servidor dev parece estar corriendo
)

echo.
echo PASO 2: Verificando PocketBase...
netstat -an | find ":8090" >nul 2>&1
if errorlevel 1 (
    echo ✗ PROBLEMA: PocketBase NO esta corriendo en puerto 8090
    echo SOLUCION: Iniciar PocketBase desde Monitor vigilancia
) else (
    echo ✓ PocketBase corriendo en puerto 8090
)

echo.
echo PASO 3: Verificando/Creando config.json para Terminal B...

if not exist "public\config.json" (
    echo ! Creando config.json desde cero...
    echo { > "public\config.json"
    echo     "$schema": "./config.schema.json", >> "public\config.json"
    echo     "version": "2.1.0", >> "public\config.json"
    echo     "modo": "produccion", >> "public\config.json"
    echo     "rol": "terminal-b", >> "public\config.json"
    echo     "hardware": "tradicional", >> "public\config.json"
    echo     "pocketbase_url": "http://127.0.0.1:8090", >> "public\config.json"
    echo     "red": { >> "public\config.json"
    echo         "ip_servidor": "127.0.0.1", >> "public\config.json"
    echo         "ip_terminal_a": "127.0.0.1", >> "public\config.json"
    echo         "ip_terminal_b": "127.0.0.1" >> "public\config.json"
    echo     }, >> "public\config.json"
    echo     "ui": { >> "public\config.json"
    echo         "teclado_virtual_forzado": false, >> "public\config.json"
    echo         "tema": "claro" >> "public\config.json"
    echo     } >> "public\config.json"
    echo } >> "public\config.json"
    echo ✓ config.json creado para Terminal B
) else (
    echo ! config.json existe, verificando rol...
    findstr "terminal-b" "public\config.json" >nul 2>&1
    if errorlevel 1 (
        echo ! Cambiando rol a terminal-b...
        powershell -Command "(Get-Content 'public\config.json') -replace '\"rol\":\s*\"[^\"]*\"', '\"rol\": \"terminal-b\"' | Set-Content 'public\config.json'"
        echo ✓ Rol cambiado a terminal-b
    ) else (
        echo ✓ config.json ya tiene rol terminal-b
    )
)

:diagnostico_adicional
echo.
echo PASO 4: Diagnostico completo...
echo.
echo Contenido actual de config.json:
echo ---------------------------------
if exist "public\config.json" (
    type "public\config.json"
) else (
    echo ERROR: config.json no existe
)

echo.
echo PASO 5: Probando conectividad...
echo.
echo Intentando acceder a Terminal B via navegador...
start "" "http://127.0.0.1:5173/terminal"

echo.
echo ================================================================
echo  DIAGNOSTICO COMPLETO - RESULTADO
echo ================================================================
echo.
echo SI TERMINAL B SIGUE CON ERROR 404 DESPUES DE ESTE FIX:
echo.
echo 1. VERIFICAR: El Monitor vigilancia tiene servidor dev corriendo
echo    Comando: npm run dev
echo    Debe mostrar: "Local: http://localhost:5173/"
echo.
echo 2. VERIFICAR: PocketBase esta corriendo
echo    Debe responder en: http://127.0.0.1:8090/_/
echo.
echo 3. VERIFICAR: config.json tiene "rol": "terminal-b"
echo.
echo 4. VERIFICAR: No hay firewall bloqueando puerto 5173
echo.
echo SI TODO ESTA CORRECTO Y SIGUE FALLANDO:
echo El problema es mas profundo (red, DNS, proxy, etc.)
echo ================================================================
echo.
echo Presione cualquier tecla para salir...
pause >nul