@echo off
title Actualizar Pendrive de Recuperacion - FCEA
color 0E

echo =====================================================
echo   ACTUALIZAR PENDRIVE DE RECUPERACION
echo   Sistema de Gestion de Llaves FCEA
echo =====================================================
echo.
echo  Este script copia los scripts CORREGIDOS al pendrive
echo  de recuperacion (soluciona el bug del cierre inmediato).
echo.
echo  Conecte el pendrive de recuperacion y presione cualquier tecla...
echo.
pause > nul

echo.
set /p USB_LETTER="Ingrese la letra del pendrive (ej: E, F, G, D): "
set "USB_DRIVE=%USB_LETTER%:"

if not exist "%USB_DRIVE%\" (
    echo.
    echo  ERROR: No se encontro la unidad %USB_DRIVE%
    echo  Verifique que el pendrive este conectado.
    pause
    exit /b 1
)

REM Detectar si es el pendrive correcto
set "RECOVERY_DIR=%USB_DRIVE%\RECUPERACION_SISTEMA_LLAVES_FCEA"
if not exist "%RECOVERY_DIR%" (
    echo.
    echo  AVISO: No se encontro la carpeta RECUPERACION_SISTEMA_LLAVES_FCEA en %USB_DRIVE%
    echo  Puede que sea un pendrive diferente o que aun no fue preparado.
    echo.
    set /p CONTINUAR="Desea continuar de todas formas? (S/N): "
    if /i not "%CONTINUAR%"=="S" (
        echo  Operacion cancelada.
        pause
        exit /b 0
    )
    mkdir "%RECOVERY_DIR%" 2>nul
    mkdir "%RECOVERY_DIR%\sistema" 2>nul
    mkdir "%RECOVERY_DIR%\respaldos_db" 2>nul
    mkdir "%RECOVERY_DIR%\instaladores" 2>nul
)

echo.
echo  [1/5] Copiando scripts corregidos al pendrive...

REM Copiar iniciar_sistema.bat corregido
copy /Y "iniciar_sistema.bat" "%RECOVERY_DIR%\sistema\" >nul 2>&1
echo     [OK] iniciar_sistema.bat copiado.

REM Copiar ABRIR_NAVEGADOR.bat (nuevo - para cuando se cierran los navegadores)
copy /Y "ABRIR_NAVEGADOR.bat" "%RECOVERY_DIR%\sistema\" >nul 2>&1
echo     [OK] ABRIR_NAVEGADOR.bat copiado.

REM Copiar RECUPERAR_SISTEMA.bat corregido
copy /Y "scripts\respaldo_recuperacion\RECUPERAR_SISTEMA.bat" "%RECOVERY_DIR%\sistema\scripts\respaldo_recuperacion\" >nul 2>&1
echo     [OK] RECUPERAR_SISTEMA.bat corregido copiado.

REM Copiar recuperar_datos_db.ps1 (el script que faltaba)
copy /Y "scripts\respaldo_recuperacion\recuperar_datos_db.ps1" "%RECOVERY_DIR%\sistema\scripts\respaldo_recuperacion\" >nul 2>&1
echo     [OK] recuperar_datos_db.ps1 copiado.

echo.
echo  [2/5] Regenerando RESTAURAR_SISTEMA.bat con ruta correcta...

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
echo set "SISTEMA_DIR=C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
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
) > "%RECOVERY_DIR%\RESTAURAR_SISTEMA.bat"

echo     [OK] RESTAURAR_SISTEMA.bat regenerado con ruta correcta.

echo.
echo  [3/5] Actualizando base de datos en el pendrive...
if exist "pocketbase\pb_data" (
    xcopy "pocketbase\pb_data" "%RECOVERY_DIR%\respaldos_db\pb_data_ultimo\" /E /I /Q /Y
    echo     [OK] Base de datos actualizada.
) else (
    echo     [!] No se encontro base de datos local.
)

echo.
echo  [4/5] Copiando ABRIR_NAVEGADOR.bat a la raiz del pendrive...
copy /Y "ABRIR_NAVEGADOR.bat" "%RECOVERY_DIR%\" >nul 2>&1
echo     [OK] ABRIR_NAVEGADOR.bat en raiz del pendrive.

echo.
echo  [5/5] Verificando archivos criticos en el pendrive...
set ERRORES=0

if exist "%RECOVERY_DIR%\RESTAURAR_SISTEMA.bat" (
    echo     [OK] RESTAURAR_SISTEMA.bat
) else (
    echo     [!!] FALTA: RESTAURAR_SISTEMA.bat
    set /a ERRORES+=1
)

if exist "%RECOVERY_DIR%\sistema\iniciar_sistema.bat" (
    echo     [OK] sistema\iniciar_sistema.bat
) else (
    echo     [!!] FALTA: sistema\iniciar_sistema.bat
    set /a ERRORES+=1
)

if exist "%RECOVERY_DIR%\sistema\scripts\respaldo_recuperacion\recuperar_datos_db.ps1" (
    echo     [OK] scripts\respaldo_recuperacion\recuperar_datos_db.ps1
) else (
    echo     [!!] FALTA: scripts\respaldo_recuperacion\recuperar_datos_db.ps1
    set /a ERRORES+=1
)

echo.
if %ERRORES% EQU 0 (
    echo =====================================================
    echo   PENDRIVE ACTUALIZADO CORRECTAMENTE
    echo =====================================================
    echo.
    echo  Bugs corregidos en este pendrive:
    echo    [FIX] RESTAURAR_SISTEMA.bat ahora usa la ruta correcta
    echo          C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea
    echo    [FIX] RECUPERAR_SISTEMA.bat ahora llama al script correcto
    echo          recuperar_datos_db.ps1 ^(antes llamaba a uno inexistente^)
    echo    [NEW] ABRIR_NAVEGADOR.bat - para reabrir el sistema cuando
    echo          se cierran los navegadores sin detener el sistema
    echo.
) else (
    echo  ADVERTENCIA: %ERRORES% archivo^(s^) no se copiaron correctamente.
    echo  Verifique el pendrive manualmente.
    echo.
)

pause
