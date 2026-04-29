@echo off
color 1F
title Sistema de Recuperación de Datos - FCEA

echo =========================================================================
echo         SISTEMA DE RECUPERACIÓN DE DATOS - LLAVES Y VIGILANTES
echo =========================================================================
echo.
echo Este script intentará recuperar datos perdidos de manera automática 
echo desde respaldos disponibles o desde el sistema actual.
echo.
echo IMPORTANTE: El sistema debe estar detenido antes de ejecutar este script.
echo.
pause

:: Establecer ruta del sistema
set "SYSTEM_PATH=%~dp0.."
set "POCKETBASE_PATH=%SYSTEM_PATH%\pocketbase"
set "PB_DATA_PATH=%POCKETBASE_PATH%\pb_data"
set "RESPALDOS_PATH=%POCKETBASE_PATH%\respaldos"
set "RECOVERY_SCRIPT_PATH=%~dp0respaldo_recuperacion\recuperar_datos_db.ps1"

:: Verificar si existe el script PowerShell de recuperación
if not exist "%RECOVERY_SCRIPT_PATH%" (
    echo ERROR: No se encontró el script de recuperación en %RECOVERY_SCRIPT_PATH%
    echo.
    echo Por favor, asegúrese de que el script exista y ejecute este bat nuevamente.
    pause
    exit /b 1
)

echo.
echo ANÁLISIS INICIAL
echo ----------------------------------------------------------------------
echo.

:: Verificar si hay respaldos disponibles
echo Verificando respaldos...
set "RESPALDOS_ENCONTRADOS=0"

if exist "%RESPALDOS_PATH%" (
    dir /b /a:d "%RESPALDOS_PATH%" > nul 2>&1
    if not errorlevel 1 (
        echo - [ENCONTRADO] Respaldos automáticos en %RESPALDOS_PATH%
        set "RESPALDOS_ENCONTRADOS=1"
    )
)

:: Buscar respaldos en unidades externas
for %%D in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\SistemaLlavesFCEA_Respaldo" (
        echo - [ENCONTRADO] Respaldos externos en %%D:\SistemaLlavesFCEA_Respaldo
        set "RESPALDOS_ENCONTRADOS=1"
    )
)

if "%RESPALDOS_ENCONTRADOS%"=="0" (
    echo - [ADVERTENCIA] No se encontraron respaldos automáticos ni externos.
    echo   Se intentará recuperar desde datos iniciales.
)

echo.
echo OPCIONES DE RECUPERACIÓN
echo ----------------------------------------------------------------------
echo.
echo 1. Recuperación automática (recomendada)
echo    Restaurará el último respaldo disponible con todos los datos.
echo.
echo 2. Recuperación con selección manual
echo    Le permitirá seleccionar el respaldo específico a restaurar.
echo.
echo 3. Recuperación de emergencia
echo    Intentará reconstruir los datos perdidos usando datos de inicialización.
echo.
echo 4. Salir
echo.

choice /C 1234 /N /M "Seleccione una opción (1-4): "
if errorlevel 4 goto END
if errorlevel 3 goto EMERGENCIA
if errorlevel 2 goto MANUAL
if errorlevel 1 goto AUTOMATICA

:AUTOMATICA
echo.
echo INICIANDO RECUPERACIÓN AUTOMÁTICA
echo ----------------------------------------------------------------------
echo.

powershell -ExecutionPolicy Bypass -File "%RECOVERY_SCRIPT_PATH%" -RestaurarUltimoRespaldo
goto VERIFICACION

:MANUAL
echo.
echo INICIANDO RECUPERACIÓN MANUAL
echo ----------------------------------------------------------------------
echo.

powershell -ExecutionPolicy Bypass -File "%RECOVERY_SCRIPT_PATH%"
goto VERIFICACION

:EMERGENCIA
echo.
echo INICIANDO RECUPERACIÓN DE EMERGENCIA
echo ----------------------------------------------------------------------
echo.
echo ADVERTENCIA: Este es un procedimiento de último recurso.
echo.
echo Se restaurarán los DATOS REALES del sistema:
echo   - 16 vigilantes distribuidos en los tres turnos:
echo       Matutino:   Sylvia (Jefa), Claudia, Laura, Lourdes, Luis, Dahiana
echo       Vespertino: Martin (Jefe), Daniel, Nathia, Silvia, Alejandro, Caterin
echo       Nocturno:   Gustavo (Jefe), Mario, Silvana, Fernando
echo   - 161 llaves del Tablero Principal con sus ubicaciones reales
echo     (Puerta izquierda, Puerta derecha, Lateral izq/der, Fondo)
echo.
echo Si existe algún respaldo, se recomienda cancelar y usar las opciones
echo 1 o 2 en su lugar.
echo.
choice /C SN /N /M "¿Está seguro que desea continuar? (S/N): "
if errorlevel 2 goto MENU_PRINCIPAL

:: Ejecutar primero el script PowerShell para restaurar estructura
powershell -ExecutionPolicy Bypass -File "%RECOVERY_SCRIPT_PATH%"

:: Luego restaurar los datos reales (vigilantes y llaves)
echo.
echo Restaurando datos reales (vigilantes y llaves)...
if exist "%SYSTEM_PATH%\RESTAURAR_DATOS_URGENTE.bat" (
    call "%SYSTEM_PATH%\RESTAURAR_DATOS_URGENTE.bat"
) else (
    echo ADVERTENCIA: No se encontró RESTAURAR_DATOS_URGENTE.bat
    echo Ejecute manualmente desde la raíz: RESTAURAR_DATOS_URGENTE.bat
)
goto VERIFICACION

:VERIFICACION
echo.
echo VERIFICACIÓN POST-RECUPERACIÓN
echo ----------------------------------------------------------------------
echo.
echo Si la recuperación se completó exitosamente, debería poder ver
echo todos los usuarios, vigilantes y llaves en el sistema.
echo.
echo PASOS RECOMENDADOS:
echo 1. Inicie el sistema normalmente
echo 2. Verifique que los datos estén presentes
echo 3. Si faltan datos, ejecute este script nuevamente y seleccione
echo    una opción diferente
echo.
echo Si persisten los problemas, por favor contacte al soporte técnico.
echo.

:END
echo.
echo Gracias por utilizar el Sistema de Recuperación de Datos.
echo.
pause