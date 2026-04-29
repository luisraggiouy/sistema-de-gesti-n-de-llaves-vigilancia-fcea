@echo off
echo =====================================================
echo   PREPARACION DEL PENDRIVE DE RECUPERACION
echo   Sistema de Gestion de Llaves FCEA
echo =====================================================
echo.
echo Este script prepara un pendrive con TODO lo necesario
echo para restaurar el sistema en cualquier computadora,
echo incluso si no tiene Node.js instalado.
echo.
echo REQUISITOS:
echo   - Pendrive de al menos 8 GB (recomendado 16 GB)
echo   - El pendrive debe estar conectado
echo.
echo Presione cualquier tecla para continuar...
pause > nul

echo.
echo [1/7] Seleccione la letra del pendrive (ej: E, F, G):
set /p USB_LETTER="Letra del pendrive: "
set "USB_DRIVE=%USB_LETTER%:"

if not exist "%USB_DRIVE%\" (
    echo ERROR: No se encontro la unidad %USB_DRIVE%
    echo Verifique que el pendrive este conectado.
    pause
    exit /b 1
)

echo.
echo [2/7] Creando estructura de carpetas en el pendrive...
mkdir "%USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA" 2>nul
mkdir "%USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA\instaladores" 2>nul
mkdir "%USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA\sistema" 2>nul
mkdir "%USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA\respaldos_db" 2>nul
echo     Estructura creada.

echo.
echo [3/7] Copiando codigo fuente del sistema...
echo     (esto puede tardar unos minutos)
xcopy "." "%USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA\sistema\" /E /I /Q /Y /EXCLUDE:scripts\excluir_pendrive.txt
echo     Codigo fuente copiado.

echo.
echo [4/7] Copiando node_modules (dependencias pre-instaladas)...
echo     (esto puede tardar varios minutos, son muchos archivos)
if exist "node_modules" (
    xcopy "node_modules" "%USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA\sistema\node_modules\" /E /I /Q /Y
    echo     Dependencias copiadas.
) else (
    echo     ADVERTENCIA: No se encontro node_modules.
    echo     Ejecute "npm install" primero y vuelva a correr este script.
)

echo.
echo [5/7] Copiando base de datos actual (datos historicos)...
if exist "pocketbase\pb_data" (
    xcopy "pocketbase\pb_data" "%USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA\respaldos_db\pb_data_ultimo\" /E /I /Q /Y
    echo     Base de datos copiada.
) else (
    echo     ADVERTENCIA: No se encontro base de datos.
)

echo.
echo [6/7] Verificando instalador de Node.js...
if exist "%USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA\instaladores\node-setup.msi" (
    echo     Instalador de Node.js ya existe en el pendrive.
) else (
    echo     IMPORTANTE: Debe descargar manualmente el instalador de Node.js
    echo     y copiarlo a:
    echo       %USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA\instaladores\node-setup.msi
    echo.
    echo     Descargue desde: https://nodejs.org/dist/v20.18.0/node-v20.18.0-x64.msi
    echo     (o la version LTS mas reciente)
)

echo.
echo [7/7] Creando script de restauracion automatica...

(
echo @echo off
echo echo =====================================================
echo echo   RESTAURACION COMPLETA DEL SISTEMA DE LLAVES FCEA
echo echo =====================================================
echo echo.
echo echo Este proceso restaurara el sistema completo en esta
echo echo computadora, incluyendo todos los datos historicos.
echo echo.
echo echo Presione cualquier tecla para continuar...
echo pause ^> nul
echo.
echo set "USB_DRIVE=%%~d0"
echo set "RECOVERY_DIR=%%USB_DRIVE%%\RECUPERACION_SISTEMA_LLAVES_FCEA"
echo set "SISTEMA_DIR=C:\sistema-llaves-fcea"
echo.
echo echo.
echo echo [1/6] Verificando archivos de recuperacion...
echo if not exist "%%RECOVERY_DIR%%\sistema" ^(
echo     echo ERROR: No se encontraron los archivos del sistema en el pendrive.
echo     echo Verifique que el pendrive sea el correcto.
echo     pause
echo     exit /b 1
echo ^)
echo echo     Archivos encontrados correctamente.
echo.
echo echo.
echo echo [2/6] Verificando Node.js...
echo node --version ^>nul 2^>^&1
echo if %%ERRORLEVEL%% NEQ 0 ^(
echo     echo     Node.js NO esta instalado en esta computadora.
echo     if exist "%%RECOVERY_DIR%%\instaladores\node-setup.msi" ^(
echo         echo     Instalando Node.js desde el pendrive...
echo         echo     ^(Se abrira el instalador, siga los pasos y luego vuelva aqui^)
echo         start /wait msiexec /i "%%RECOVERY_DIR%%\instaladores\node-setup.msi" /passive
echo         echo     Node.js instalado.
echo     ^) else ^(
echo         echo     ERROR: No se encontro el instalador de Node.js en el pendrive.
echo         echo     Descargue Node.js de https://nodejs.org/ e instalelo manualmente.
echo         echo     Luego vuelva a ejecutar este script.
echo         pause
echo         exit /b 1
echo     ^)
echo ^) else ^(
echo     echo     Node.js ya esta instalado.
echo ^)
echo.
echo echo.
echo echo [3/6] Respaldando datos existentes ^(si los hay^)...
echo if exist "%%SISTEMA_DIR%%\pocketbase\pb_data\data.db" ^(
echo     echo     Se encontro base de datos existente, respaldando...
echo     set "BACKUP_TIMESTAMP=%%date:~-4%%%%date:~3,2%%%%date:~0,2%%_%%time:~0,2%%%%time:~3,2%%"
echo     set "BACKUP_TIMESTAMP=%%BACKUP_TIMESTAMP: =0%%"
echo     mkdir "%%SISTEMA_DIR%%\respaldo_pre_restauracion_%%BACKUP_TIMESTAMP%%" 2^>nul
echo     xcopy "%%SISTEMA_DIR%%\pocketbase\pb_data" "%%SISTEMA_DIR%%\respaldo_pre_restauracion_%%BACKUP_TIMESTAMP%%\pb_data\" /E /I /Q
echo     echo     Respaldo guardado.
echo ^) else ^(
echo     echo     No se encontro instalacion previa.
echo ^)
echo.
echo echo.
echo echo [4/6] Copiando archivos del sistema...
echo echo     ^(esto puede tardar unos minutos^)
echo xcopy "%%RECOVERY_DIR%%\sistema" "%%SISTEMA_DIR%%" /E /I /Q /Y
echo echo     Archivos del sistema copiados.
echo.
echo echo.
echo echo [5/6] Restaurando base de datos mas reciente...
echo if exist "%%RECOVERY_DIR%%\respaldos_db\pb_data_ultimo\data.db" ^(
echo     echo     Restaurando datos historicos desde el pendrive...
echo     xcopy "%%RECOVERY_DIR%%\respaldos_db\pb_data_ultimo" "%%SISTEMA_DIR%%\pocketbase\pb_data\" /E /I /Q /Y
echo     echo     Datos historicos restaurados.
echo ^) else if exist "%%SISTEMA_DIR%%\respaldo_pre_restauracion_%%BACKUP_TIMESTAMP%%\pb_data\data.db" ^(
echo     echo     Restaurando datos desde respaldo local...
echo     xcopy "%%SISTEMA_DIR%%\respaldo_pre_restauracion_%%BACKUP_TIMESTAMP%%\pb_data" "%%SISTEMA_DIR%%\pocketbase\pb_data\" /E /I /Q /Y
echo     echo     Datos restaurados desde respaldo local.
echo ^) else ^(
echo     echo     ADVERTENCIA: No se encontraron datos historicos para restaurar.
echo     echo     El sistema se iniciara con base de datos vacia.
echo ^)
echo.
echo echo.
echo echo [6/6] Iniciando el sistema...
echo cd /d "%%SISTEMA_DIR%%"
echo call iniciar_sistema.bat
echo.
echo echo.
echo echo =====================================================
echo echo   RESTAURACION COMPLETADA EXITOSAMENTE
echo echo =====================================================
echo echo.
echo echo El sistema esta funcionando en:
echo echo   http://localhost:8080/
echo echo.
echo echo Si algo no funciona, verifique:
echo echo   1. Que Node.js se haya instalado correctamente
echo echo   2. Que PocketBase este corriendo ^(ventana negra abierta^)
echo echo   3. Que el navegador apunte a http://localhost:8080/
echo echo.
echo pause
) > "%USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA\RESTAURAR_SISTEMA.bat"

echo     Script de restauracion creado.

REM Crear archivo de exclusiones
if not exist "scripts\excluir_pendrive.txt" (
    (
        echo .git
        echo .git\
    ) > "scripts\excluir_pendrive.txt"
)

echo.
echo =====================================================
echo   PENDRIVE DE RECUPERACION PREPARADO
echo =====================================================
echo.
echo Contenido del pendrive:
echo   %USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA\
echo     ├── RESTAURAR_SISTEMA.bat    (ejecutar para restaurar)
echo     ├── sistema\                 (codigo + dependencias)
echo     ├── respaldos_db\            (base de datos actual)
echo     └── instaladores\            (instalador de Node.js)
echo.
echo IMPORTANTE - PASOS PENDIENTES:
echo   1. Copie el instalador de Node.js al pendrive:
echo      %USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA\instaladores\node-setup.msi
echo      Descargue de: https://nodejs.org/
echo.
echo   2. Etiquete el pendrive: "RECUPERACION SISTEMA LLAVES FCEA"
echo.
echo   3. Guarde el pendrive en un lugar seguro.
echo.
echo   4. ACTUALICE el pendrive cada mes ejecutando este script
echo      nuevamente para mantener los datos al dia.
echo.
pause
