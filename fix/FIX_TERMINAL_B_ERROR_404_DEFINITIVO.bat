@echo off
chcp 65001 >nul
title Terminal B Error 404 - SOLUCION DEFINITIVA

echo =============================================================
echo  FIX: Terminal B Error 404 DEFINITIVO (ULTRA SIMPLE)
echo =============================================================
echo  Fecha: 30/07/2026 11:30
echo  Problema: Scripts PowerShell se cierran con "Ejecutar con PowerShell"
echo  Solucion: Script .bat que CREA config.json y mantiene ventana abierta
echo =============================================================
echo.

echo PASO 1: Verificando archivos...

REM Verificar que estamos en el directorio correcto
if not exist "public" (
    echo ERROR: No se encuentra la carpeta 'public'
    echo Ubicacion: %CD%
    echo Presione cualquier tecla para salir...
    pause >nul
    exit /b 1
)

echo ✓ Carpeta 'public' encontrada

REM Crear el archivo config.json con la configuración exacta que funciona en Terminal A
echo PASO 2: Creando public/config.json...

echo { > "public\config.json"
echo     "$schema":  "./config.schema.json", >> "public\config.json"
echo     "version":  "2.1.0", >> "public\config.json"
echo     "modo":  "produccion", >> "public\config.json"
echo     "rol":  "terminal-b", >> "public\config.json"
echo     "hardware":  "tradicional", >> "public\config.json"
echo     "pocketbase_url":  "http://127.0.0.1:8090", >> "public\config.json"
echo     "red":  { >> "public\config.json"
echo                 "ip_servidor":  "127.0.0.1", >> "public\config.json"
echo                 "ip_terminal_a":  "127.0.0.1", >> "public\config.json"
echo                 "ip_terminal_b":  "127.0.0.1" >> "public\config.json"
echo             }, >> "public\config.json"
echo     "ui":  { >> "public\config.json"
echo                "teclado_virtual_forzado":  false, >> "public\config.json"
echo                "tema":  "claro" >> "public\config.json"
echo            }, >> "public\config.json"
echo     "_notas":  [ >> "public\config.json"
echo                    "CREADO POR FIX DEFINITIVO - Terminal B configurada igual que Terminal A", >> "public\config.json"
echo                    "pero con rol=terminal-b. Si Terminal A funciona, esta tambien debe funcionar." >> "public\config.json"
echo                ] >> "public\config.json"
echo } >> "public\config.json"

echo ✓ Archivo config.json creado

echo PASO 3: Verificando contenido...
if exist "public\config.json" (
    echo ✓ public/config.json existe
    echo.
    echo Contenido:
    type "public\config.json"
    echo.
) else (
    echo ✗ ERROR: No se pudo crear public/config.json
    echo.
)

echo PASO 4: Iniciando Terminal B...
echo.
echo Abriendo navegador en Terminal B...
echo URL: http://127.0.0.1:5173/terminal?id=B
echo.

REM Abrir el navegador directamente con la URL de Terminal B
start "" "http://127.0.0.1:5173/terminal?id=B"

echo =============================================================
echo  SOLUCION APLICADA
echo =============================================================
echo  ✓ config.json creado con configuracion identica a Terminal A
echo  ✓ Navegador abierto en Terminal B  
echo  ✓ Si Terminal A funciona, Terminal B ahora tambien debe funcionar
echo.
echo  RESULTADO ESPERADO: Terminal B debe mostrar la pantalla de solicitud
echo  de llaves igual que Terminal A, sin error 404.
echo.
echo  Si sigue fallando, el problema no es el config.json sino algo mas.
echo =============================================================
echo.
echo Presione cualquier tecla para salir...
pause >nul