@echo off
color 1F
title RESTAURACION URGENTE DE DATOS REALES - SISTEMA DE LLAVES FCEA

echo =========================================================================
echo    RESTAURACION URGENTE DE DATOS REALES - SISTEMA DE LLAVES FCEA
echo =========================================================================
echo.
echo Este script restaurara INMEDIATAMENTE los siguientes datos REALES:
echo.
echo   VIGILANTES POR TURNO (16 en total):
echo     - Matutino:   Sylvia (Jefa), Claudia, Laura, Lourdes, Luis, Dahiana
echo     - Vespertino: Martin (Jefe), Daniel, Nathia, Silvia, Alejandro, Caterin
echo     - Nocturno:   Gustavo (Jefe), Mario, Silvana, Fernando
echo.
echo   LLAVES (161 en total) con sus ubicaciones reales en el tablero:
echo     - Tablero Principal - Puerta izquierda (50 llaves)
echo     - Tablero Principal - Puerta derecha   (36 llaves)
echo     - Tablero Principal - Lateral izquierdo ( 4 llaves)
echo     - Tablero Principal - Lateral derecho   ( 6 llaves)
echo     - Tablero Principal - Fondo            (65 llaves)
echo.
echo   NOTA: NO se restauran usuarios registrados con datos inventados.
echo         Los usuarios reales se cargan progresivamente al usar el sistema.
echo.
echo IMPORTANTE: Asegurese que el sistema este funcionando (PocketBase iniciado)
echo             antes de ejecutar este script.
echo.
echo =========================================================================
echo.

set "SYSTEM_PATH=%~dp0"
cd /d "%SYSTEM_PATH%"

echo INICIANDO VERIFICACIONES PREVIAS...
echo.

:: Verificar si Node.js esta instalado
node --version > nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js no esta instalado o no se encuentra en el PATH.
    echo Por favor, instale Node.js desde https://nodejs.org/ e intentelo de nuevo.
    pause
    exit /b 1
)

:: Verificar si PocketBase esta en ejecucion
echo Verificando si PocketBase esta en ejecucion...
curl -s http://localhost:8090/api/health > nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ADVERTENCIA: PocketBase parece no estar en ejecucion.
    echo.
    choice /C SN /N /M "Desea iniciar PocketBase antes de continuar? (S/N): "
    if errorlevel 2 (
        echo Continuando sin iniciar PocketBase. Esto puede causar errores.
    ) else (
        echo.
        echo Iniciando PocketBase...
        start "" "%SYSTEM_PATH%\pocketbase\pocketbase.exe" serve
        echo Esperando 5 segundos para que PocketBase inicie...
        ping -n 6 127.0.0.1 > nul
    )
)

:: Verificar/Instalar dependencias
echo Verificando dependencias...
if not exist "node_modules\pocketbase" (
    echo Instalando modulo de PocketBase...
    npm install pocketbase --no-fund --no-audit
    if %errorlevel% neq 0 (
        echo ERROR: No se pudo instalar el modulo pocketbase.
        pause
        exit /b 1
    )
)

echo.
echo =========================================================================
echo EJECUTANDO SCRIPT DE RESTAURACION DE DATOS REALES...
echo =========================================================================
echo.

:: Ejecutar el script de restauracion
node restaurar_datos_inmediatamente.cjs

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Ha ocurrido un problema durante la restauracion.
    echo Por favor, contacte al soporte tecnico.
) else (
    echo.
    echo =========================================================================
    echo LA RESTAURACION DE DATOS REALES HA SIDO COMPLETADA
    echo =========================================================================
    echo.
    echo 1. Actualice la pagina del navegador para ver los datos restaurados.
    echo 2. Verifique que los 16 vigilantes y 161 llaves aparezcan correctamente.
    echo 3. Si necesita hacer una restauracion mas completa desde respaldos,
    echo    use el script: scripts\recuperar_llaves_vigilantes.bat
)

echo.
pause
