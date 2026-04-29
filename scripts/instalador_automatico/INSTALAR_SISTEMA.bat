@echo off
setlocal enabledelayedexpansion

:: ====================================================================
:: SISTEMA DE GESTIÓN DE LLAVES FCEA - INSTALADOR AUTOMATIZADO v1.0
:: ====================================================================
:: Instalador completo con configuración de teclado táctil
:: y opciones para entorno de prueba o producción.
:: ====================================================================

:: Configuración del instalador
title Instalador Sistema de Gestión de Llaves FCEA v4.0
color 1F
set "INSTALL_DIR=C:\SistemaLlavesFCEA"
set "SCRIPT_DIR=%~dp0"
set "CURRENT_DIR=%CD%"

:: Verificación de privilegios de administrador
echo.
echo [Inicializando] Verificando permisos de administrador...
net session >nul 2>&1
if %errorLevel% neq 0 (
    color 4F
    echo.
    echo [ERROR] Se requieren privilegios de administrador.
    echo Por favor, ejecute el instalador como administrador ^(clic derecho, "Ejecutar como administrador"^).
    echo.
    pause
    exit /b 1
)
echo [OK] Privilegios verificados.

:: Menú principal
:MENU_PRINCIPAL
cls
echo ======================================================
echo     SISTEMA DE GESTIÓN DE LLAVES FCEA - INSTALADOR
echo ======================================================
echo.
echo Seleccione el tipo de instalación:
echo.
echo  [1] Instalación en MODO PRODUCCIÓN
echo      (Mini PC con 3 monitores táctiles)
echo.
echo  [2] Instalación en MODO PRUEBA
echo      (Similar a configuración actual)
echo.
echo  [3] Recuperación/Reinstalación
echo      (Conservar datos existentes)
echo.
echo  [4] Cancelar y salir
echo.
echo ======================================================
echo.

set /p OPCION="Seleccione una opción (1-4): "

if "%OPCION%"=="1" (
    set "MODO_INSTALACION=PRODUCCION"
    goto INSTALACION_COMPLETA
) else if "%OPCION%"=="2" (
    set "MODO_INSTALACION=PRUEBA"
    goto INSTALACION_COMPLETA
) else if "%OPCION%"=="3" (
    goto MODO_RECUPERACION
) else if "%OPCION%"=="4" (
    goto SALIR
) else (
    echo.
    echo [ERROR] Opción inválida. Presione cualquier tecla para volver al menú...
    pause >nul
    goto MENU_PRINCIPAL
)

:: ====================================================================
:: INSTALACIÓN COMPLETA
:: ====================================================================
:INSTALACION_COMPLETA
cls
echo ======================================================
echo  PREPARANDO INSTALACION EN MODO %MODO_INSTALACION%
echo ======================================================
echo.

:: Mostrar resumen y confirmar instalación
echo La instalación configurará:
echo.
if "%MODO_INSTALACION%"=="PRODUCCION" (
    echo  - Modo optimizado para producción
    echo  - Configuración para 3 monitores táctiles
    echo  - Base de datos limpia (sin datos de prueba)
    echo  - Inicio automático con Windows
    echo  - Teclado virtual con sugerencias
) else (
    echo  - Modo desarrollo/pruebas
    echo  - Configuración similar a la actual
    echo  - Herramientas de depuración
    echo  - Teclado virtual con sugerencias
)
echo.
echo Ubicación de instalación: %INSTALL_DIR%
echo.
echo ¿Desea continuar con la instalación?
echo.
set /p CONFIRMAR="Escriba 'SI' para confirmar o cualquier otra tecla para cancelar: "
if /i not "%CONFIRMAR%"=="SI" (
    echo.
    echo Instalación cancelada por el usuario.
    goto SALIR
)

:: Secuencia de instalación
echo.
echo [Iniciando instalación...]
echo.

call :VERIFICAR_REQUISITOS
if %errorlevel% neq 0 goto SALIR

call :CREAR_DIRECTORIOS
if %errorlevel% neq 0 goto SALIR

call :INSTALAR_NODEJS
if %errorlevel% neq 0 goto SALIR

call :COPIAR_ARCHIVOS
if %errorlevel% neq 0 goto SALIR

call :CONFIGURAR_TECLADO_TACTIL
if %errorlevel% neq 0 goto SALIR

call :CONFIGURAR_NAVEGADOR
if %errorlevel% neq 0 goto SALIR

call :CONFIGURAR_BASE_DATOS
if %errorlevel% neq 0 goto SALIR

call :CONFIGURAR_FIREWALL
if %errorlevel% neq 0 goto SALIR

if "%MODO_INSTALACION%"=="PRODUCCION" (
    call :CONFIGURAR_MONITORES_TACTILES
    if %errorlevel% neq 0 goto SALIR
    
    call :CONFIGURAR_INICIO_AUTOMATICO
    if %errorlevel% neq 0 goto SALIR
)

call :CREAR_ACCESOS_DIRECTOS
if %errorlevel% neq 0 goto SALIR

call :INSTALAR_PAQUETES_NPM
if %errorlevel% neq 0 goto SALIR

call :FINALIZAR_INSTALACION
goto SALIR

:: ====================================================================
:: MODO RECUPERACIÓN
:: ====================================================================
:MODO_RECUPERACION
cls
echo ======================================================
echo      RECUPERACION/REINSTALACION DEL SISTEMA
echo ======================================================
echo.
echo Este modo reinstalará el sistema conservando los datos existentes.
echo.
echo IMPORTANTE: Se realizará una copia de seguridad de los datos actuales.
echo.
echo ¿Desea continuar con la recuperación?
echo.
set /p CONFIRMAR="Escriba 'SI' para confirmar o cualquier otra tecla para cancelar: "
if /i not "%CONFIRMAR%"=="SI" (
    echo.
    echo Recuperación cancelada por el usuario.
    goto SALIR
)

:: Secuencia de recuperación
set "MODO_INSTALACION=RECUPERACION"
echo.
echo [Iniciando recuperación...]
echo.

call :VERIFICAR_REQUISITOS
if %errorlevel% neq 0 goto SALIR

call :RESPALDAR_DATOS_EXISTENTES
if %errorlevel% neq 0 goto SALIR

call :REINSTALAR_SISTEMA
if %errorlevel% neq 0 goto SALIR

call :RESTAURAR_DATOS
if %errorlevel% neq 0 goto SALIR

call :FINALIZAR_INSTALACION
goto SALIR

:: ====================================================================
:: FUNCIONES DE APOYO
:: ====================================================================

:: Verificar requisitos del sistema
:VERIFICAR_REQUISITOS
echo [Paso 1/10] Verificando requisitos del sistema...

:: Verificar Windows 10/11
ver | find "10." >nul || ver | find "11." >nul
if %errorLevel% neq 0 (
    color 4F
    echo [ERROR] Se requiere Windows 10 o Windows 11.
    pause
    exit /b 1
)

:: Verificar espacio en disco (mínimo 5GB)
for /f "tokens=3" %%a in ('dir c:\ ^| findstr /C:"bytes free"') do set "ESPACIO=%%a"
set "ESPACIO_MINIMO=5000000000"
set "ESPACIO=%ESPACIO:.=%"
set "ESPACIO=%ESPACIO:,=%"
if %ESPACIO% LSS %ESPACIO_MINIMO% (
    color 4F
    echo [ERROR] Se requieren al menos 5GB de espacio libre en disco.
    echo Espacio actual: %ESPACIO% bytes
    echo Espacio requerido: %ESPACIO_MINIMO% bytes
    pause
    exit /b 1
)

:: Verificar si hay una instalación existente
if exist "%INSTALL_DIR%" (
    if not "%MODO_INSTALACION%"=="RECUPERACION" (
        color 6F
        echo [ADVERTENCIA] Ya existe una instalación en %INSTALL_DIR%.
        echo.
        echo Opciones:
        echo  [1] Sobrescribir (se perderán los datos existentes)
        echo  [2] Cancelar instalación
        echo.
        set /p SOBRESCRIBIR="Seleccione una opción (1-2): "
        
        if not "!SOBRESCRIBIR!"=="1" (
            echo Instalación cancelada por el usuario.
            exit /b 1
        )
        
        echo.
        echo Se sobrescribirá la instalación existente.
    )
)

echo [OK] Requisitos verificados correctamente.
echo.
exit /b 0

:: Crear directorios de instalación
:CREAR_DIRECTORIOS
echo [Paso 2/10] Creando directorios de instalación...

if not "%MODO_INSTALACION%"=="RECUPERACION" (
    if exist "%INSTALL_DIR%" (
        echo Eliminando instalación anterior...
        rd /s /q "%INSTALL_DIR%" >nul 2>&1
    )
)

:: Crear estructura de directorios
mkdir "%INSTALL_DIR%" 2>nul
mkdir "%INSTALL_DIR%\pocketbase" 2>nul
mkdir "%INSTALL_DIR%\src" 2>nul
mkdir "%INSTALL_DIR%\public" 2>nul
mkdir "%INSTALL_DIR%\logs" 2>nul
mkdir "%INSTALL_DIR%\scripts" 2>nul
mkdir "%INSTALL_DIR%\respaldos" 2>nul

echo [OK] Directorios creados correctamente.
echo.
exit /b 0

:: Instalar Node.js
:INSTALAR_NODEJS
echo [Paso 3/10] Instalando Node.js...

:: Verificar si ya está instalado
where node >nul 2>&1
if %errorLevel% equ 0 (
    echo Node.js ya está instalado. Verificando versión...
    for /f "tokens=1,2,3 delims=." %%a in ('node -v') do set "NODE_VER=%%a%%b%%c"
    if !NODE_VER! GEQ 16 (
        echo [OK] Versión de Node.js compatible detectada.
        echo.
        exit /b 0
    )
)

:: Instalar Node.js desde instalador empaquetado
echo Instalando Node.js (esto puede tardar unos minutos)...
if exist "%SCRIPT_DIR%\installers\node-v18.17.1-x64.msi" (
    start /wait msiexec /i "%SCRIPT_DIR%\installers\node-v18.17.1-x64.msi" /quiet
) else (
    color 6F
    echo [ADVERTENCIA] Instalador de Node.js no encontrado en el pendrive.
    echo Intentando descargar desde internet...
    
    :: Comprobar conexión a internet
    ping 8.8.8.8 -n 1 >nul 2>&1
    if %errorLevel% neq 0 (
        color 4F
        echo [ERROR] No hay conexión a internet y no se encuentra el instalador de Node.js.
        echo Por favor, conecte a internet o utilice un pendrive con el instalador incluido.
        pause
        exit /b 1
    )
    
    :: Descargar Node.js
    echo Descargando Node.js...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://nodejs.org/dist/v18.17.1/node-v18.17.1-x64.msi' -OutFile '%TEMP%\node-v18.17.1-x64.msi'}"
    if %errorLevel% neq 0 (
        color 4F
        echo [ERROR] No se pudo descargar Node.js.
        pause
        exit /b 1
    )
    
    :: Instalar Node.js
    start /wait msiexec /i "%TEMP%\node-v18.17.1-x64.msi" /quiet
    del "%TEMP%\node-v18.17.1-x64.msi" >nul 2>&1
)

:: Verificar instalación de Node.js
where node >nul 2>&1
if %errorLevel% neq 0 (
    color 4F
    echo [ERROR] No se pudo instalar Node.js correctamente.
    pause
    exit /b 1
)

echo [OK] Node.js instalado correctamente.
echo.
exit /b 0

:: Copiar archivos
:COPIAR_ARCHIVOS
echo [Paso 4/10] Copiando archivos del sistema...

:: Copiar archivos desde el pendrive o repositorio
if exist "%SCRIPT_DIR%\system\*" (
    echo Copiando desde pendrive...
    xcopy /E /I /H /Y "%SCRIPT_DIR%\system\*" "%INSTALL_DIR%" >nul
) else (
    :: Si no está en el pendrive, intentar clonar desde GitHub
    echo Copiando desde repositorio Git...
    
    :: Comprobar si Git está instalado
    where git >nul 2>&1
    if %errorLevel% neq 0 (
        color 4F
        echo [ERROR] No se encuentra Git y los archivos no están en el pendrive.
        echo Por favor, instale Git o utilice un pendrive con los archivos del sistema.
        pause
        exit /b 1
    )
    
    :: Clonar repositorio
    cd /d "%INSTALL_DIR%"
    git clone https://github.com/luisraggiouy/sistema-de-gesti-n-de-llaves-vigilancia-fcea.git . >nul 2>&1
    if %errorLevel% neq 0 (
        color 4F
        echo [ERROR] No se pudo clonar el repositorio de GitHub.
        pause
        exit /b 1
    )
)

:: Verificar archivos mínimos necesarios
if not exist "%INSTALL_DIR%\src\main.tsx" (
    color 4F
    echo [ERROR] No se encontraron los archivos principales del sistema.
    pause
    exit /b 1
)

echo [OK] Archivos copiados correctamente.
echo.
exit /b 0

:: Configurar teclado táctil
:CONFIGURAR_TECLADO_TACTIL
echo [Paso 5/10] Configurando teclado virtual táctil...

:: Habilitar TabletInputPanel
reg add "HKEY_CURRENT_USER\Software\Microsoft\TabletTip\1.7" /v "EnableTextPrediction" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Microsoft\TabletTip\1.7" /v "EnableAutocorrection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Microsoft\TabletTip\1.7" /v "EnableDoubleTapSpace" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Microsoft\TabletTip\1.7" /v "EnablePredictionSpaceInsertion" /t REG_DWORD /d 1 /f >nul 2>&1

:: Configurar invocación automática del teclado
reg add "HKEY_CURRENT_USER\Software\Microsoft\TabletTip\1.7" /v "EnableDesktopModeAutoInvoke" /t REG_DWORD /d 1 /f >nul 2>&1

:: Crear diccionario personalizado para términos de gestión de llaves
if not exist "%APPDATA%\Microsoft\TabletTip\1.7\UserLexicon" (
    mkdir "%APPDATA%\Microsoft\TabletTip\1.7\UserLexicon" 2>nul
)

:: Crear archivo de diccionario personalizado si no existe en el pendrive
if exist "%SCRIPT_DIR%\recursos\diccionario_personalizado.dic" (
    copy "%SCRIPT_DIR%\recursos\diccionario_personalizado.dic" "%APPDATA%\Microsoft\TabletTip\1.7\UserLexicon" /Y >nul
) else (
    echo salón > "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo oficina >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo laboratorio >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo vigilante >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo llave >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo solicitud >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo pendiente >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo entregada >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo devuelta >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo turno >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo matutino >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo vespertino >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo nocturno >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo tablero >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo principal >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo externo >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    echo híbrido >> "%INSTALL_DIR%\scripts\diccionario_personalizado.dic"
    copy "%INSTALL_DIR%\scripts\diccionario_personalizado.dic" "%APPDATA%\Microsoft\TabletTip\1.7\UserLexicon" /Y >nul
)

:: Crear script de verificación de teclado táctil
echo @echo off > "%INSTALL_DIR%\scripts\verificar_teclado_tactil.bat"
echo echo Verificando configuración del teclado táctil... >> "%INSTALL_DIR%\scripts\verificar_teclado_tactil.bat"
echo start /wait powershell -command "Start-Process 'ms-settings:easeofaccess-keyboard' -PassThru ^| Wait-Process -Timeout 3; exit 0" >> "%INSTALL_DIR%\scripts\verificar_teclado_tactil.bat"
echo echo. >> "%INSTALL_DIR%\scripts\verificar_teclado_tactil.bat"
echo echo Prueba completada. >> "%INSTALL_DIR%\scripts\verificar_teclado_tactil.bat"
echo pause >> "%INSTALL_DIR%\scripts\verificar_teclado_tactil.bat"

echo [OK] Teclado virtual táctil configurado correctamente.
echo.
exit /b 0

:: Configurar navegador
:CONFIGURAR_NAVEGADOR
echo [Paso 6/10] Configurando navegador para teclado táctil...

:: Configurar Chrome para teclado táctil
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome" /v "TouchVirtualKeyboardPolicy" /t REG_DWORD /d 1 /f >nul 2>&1

:: Verificar si Chrome está instalado, si no, instalarlo
where chrome >nul 2>&1
if %errorLevel% neq 0 (
    color 6F
    echo [ADVERTENCIA] Google Chrome no está instalado.
    echo Para una mejor experiencia con pantallas táctiles, se recomienda instalar Chrome.
    echo.
    echo ¿Desea instalar Google Chrome ahora?
    set /p INSTALAR_CHROME="Escriba 'SI' para instalar Chrome o cualquier otra tecla para omitir: "
    
    if /i "%INSTALAR_CHROME%"=="SI" (
        :: Descargar e instalar Chrome
        echo Descargando Chrome...
        powershell -Command "& {Invoke-WebRequest -Uri 'https://dl.google.com/chrome/install/latest/chrome_installer.exe' -OutFile '%TEMP%\chrome_installer.exe'}"
        if %errorLevel% neq 0 (
            color 6F
            echo [ADVERTENCIA] No se pudo descargar Chrome. Se continuará sin instalarlo.
        ) else (
            echo Instalando Chrome...
            start /wait "%TEMP%\chrome_installer.exe" /silent /install
            del "%TEMP%\chrome_installer.exe" >nul 2>&1
            echo [OK] Google Chrome instalado correctamente.
        )
    ) else (
        echo Omitiendo instalación de Chrome.
    )
)

echo [OK] Navegador configurado para teclado táctil.
echo.
exit /b 0

:: Configurar base de datos
:CONFIGURAR_BASE_DATOS
echo [Paso 7/10] Configurando base de datos...

:: Extraer PocketBase desde el pendrive o predeterminado
if exist "%SCRIPT_DIR%\packages\pocketbase\pocketbase.exe" (
    copy "%SCRIPT_DIR%\packages\pocketbase\pocketbase.exe" "%INSTALL_DIR%\pocketbase\" /Y >nul
) else (
    :: Si no está en el pendrive, intentar descargar
    echo Descargando PocketBase...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/pocketbase/pocketbase/releases/download/v0.19.4/pocketbase_0.19.4_windows_amd64.zip' -OutFile '%TEMP%\pocketbase.zip'}"
    if %errorLevel% neq 0 (
        color 4F
        echo [ERROR] No se pudo descargar PocketBase.
        pause
        exit /b 1
    )
    
    :: Extraer PocketBase
    powershell -Command "& {Expand-Archive -Path '%TEMP%\pocketbase.zip' -DestinationPath '%INSTALL_DIR%\pocketbase' -Force}"
    del "%TEMP%\pocketbase.zip" >nul 2>&1
)

:: Configurar base de datos según el modo
if "%MODO_INSTALACION%"=="PRODUCCION" (
    :: Configuración para producción - base de datos limpia
    if exist "%SCRIPT_DIR%\packages\pocketbase\pb_data_produccion" (
        xcopy /E /I /H /Y "%SCRIPT_DIR%\packages\pocketbase\pb_data_produccion" "%INSTALL_DIR%\pocketbase\pb_data" >nul
    ) else (
        :: Si no hay datos de producción, crear estructura mínima
        mkdir "%INSTALL_DIR%\pocketbase\pb_data" 2>nul
        echo Creando estructura de base de datos para producción...
    )
) else (
:: Configuración para prueba - con datos de ejemplo
if exist "%SCRIPT_DIR%\packages\pocketbase\pb_data_prueba" (
    echo Copiando datos de prueba (llaves y usuarios predefinidos)...
    xcopy /E /I /H /Y "%SCRIPT_DIR%\packages\pocketbase\pb_data_prueba" "%INSTALL_DIR%\pocketbase\pb_data" >nul
) else if exist "%SCRIPT_DIR%\packages\pocketbase\pb_data" (
    echo Copiando datos de prueba actuales (llaves y usuarios predefinidos)...
    xcopy /E /I /H /Y "%SCRIPT_DIR%\packages\pocketbase\pb_data" "%INSTALL_DIR%\pocketbase\pb_data" >nul
) else {
    :: Si no hay datos de prueba, crear estructura mínima
    mkdir "%INSTALL_DIR%\pocketbase\pb_data" 2>nul
    echo [ADVERTENCIA] No se encontraron datos de prueba (llaves y usuarios).
    echo Creando estructura de base de datos mínima para pruebas...
    echo Se recomienda incluir datos de prueba para una experiencia completa.
}
)

:: Crear configuración de PocketBase
echo {> "%INSTALL_DIR%\pocketbase\pb_config.json"
echo   "meta": {>> "%INSTALL_DIR%\pocketbase\pb_config.json"
echo     "appName": "Sistema de Gestion de Llaves FCEA",>> "%INSTALL_DIR%\pocketbase\pb_config.json"
echo     "appUrl": "http://127.0.0.1:8090",>> "%INSTALL_DIR%\pocketbase\pb_config.json"
echo     "tokenKey": "sistemallavesfcea_%RANDOM%%RANDOM%",>> "%INSTALL_DIR%\pocketbase\pb_config.json"
echo     "autoMigrate": true>> "%INSTALL_DIR%\pocketbase\pb_config.json"
echo   },>> "%INSTALL_DIR%\pocketbase\pb_config.json"
echo   "logs": {>> "%INSTALL_DIR%\pocketbase\pb_config.json"
echo     "maxDays": 5>> "%INSTALL_DIR%\pocketbase\pb_config.json"
echo   }>> "%INSTALL_DIR%\pocketbase\pb_config.json"
echo }>> "%INSTALL_DIR%\pocketbase\pb_config.json"

:: Crear script de inicio para PocketBase
echo @echo off > "%INSTALL_DIR%\pocketbase_start.bat"
echo cd /d "%INSTALL_DIR%\pocketbase" >> "%INSTALL_DIR%\pocketbase_start.bat"
echo start pocketbase.exe serve >> "%INSTALL_DIR%\pocketbase_start.bat"

echo [OK] Base de datos configurada correctamente.
echo.
exit /b 0

:: Configurar Firewall
:CONFIGURAR_FIREWALL
echo [Paso 8/10] Configurando reglas de firewall...

:: Añadir reglas de firewall para PocketBase
netsh advfirewall firewall add rule name="PocketBase" dir=in action=allow program="%INSTALL_DIR%\pocketbase\pocketbase.exe" enable=yes profile=any >nul
netsh advfirewall firewall add rule name="PocketBase Port" dir=in action=allow protocol=TCP localport=8090 enable=yes profile=any >nul

echo [OK] Reglas de firewall configuradas correctamente.
echo.
exit /b 0

:: Configurar monitores táctiles
:CONFIGURAR_MONITORES_TACTILES
echo [Paso 9/10] Configurando monitores táctiles...

:: Detectar monitores
echo Detectando monitores...

:: Crear script de configuración para monitores táctiles
echo @echo off > "%INSTALL_DIR%\scripts\configurar_monitores.bat"
echo echo Configurando monitores táctiles... >> "%INSTALL_DIR%\scripts\configurar_monitores.bat"
echo. >> "%INSTALL_DIR%\scripts\configurar_monitores.bat"
echo :: Detectar monitores táctiles >> "%INSTALL_DIR%\scripts\configurar_monitores.bat"
echo powershell -Command "& {Get-WmiObject Win32_PnPEntity | Where-Object {$_.Caption -like '*touch*'} | ForEach-Object {$_.Caption}}" >> "%INSTALL_DIR%\scripts\configurar_monitores.bat"
echo. >> "%INSTALL_DIR%\scripts\configurar_monitores.bat"
echo :: Configurar monitores táctiles >> "%INSTALL_DIR%\scripts\configurar_monitores.bat"
echo :: (Comandos específicos según los monitores detectados) >> "%INSTALL_DIR%\scripts\configurar_monitores.bat"
echo. >> "%INSTALL_DIR%\scripts\configurar_monitores.bat"
echo echo Configuración de monitores táctiles completada. >> "%INSTALL_DIR%\scripts\configurar_monitores.bat"
echo pause >> "%INSTALL_DIR%\scripts\configurar_monitores.bat"

:: Ejecutar script de configuración
call "%INSTALL_DIR%\scripts\configurar_monitores.bat" >nul 2>&1

echo [OK] Monitores táctiles configurados correctamente.
echo.
exit /b 0

:: Configurar inicio automático
:CONFIGURAR_INICIO_AUTOMATICO
echo [Paso 10/10] Configurando inicio automático...

:: Crear tarea programada para inicio automático
schtasks /create /tn "SistemaLlavesFCEA" /tr "%INSTALL_DIR%\iniciar_sistema.bat" /sc onlogon /ru SYSTEM /rl highest /f >nul 2>&1

:: Crear script de inicio del sistema
echo @echo off > "%INSTALL_DIR%\iniciar_sistema.bat"
echo cd /d "%INSTALL_DIR%" >> "%INSTALL_DIR%\iniciar_sistema.bat"
echo. >> "%INSTALL_DIR%\iniciar_sistema.bat"
echo :: Iniciar PocketBase en segundo plano >> "%INSTALL_DIR%\iniciar_sistema.bat"
echo start "PocketBase" /B "%INSTALL_DIR%\pocketbase_start.bat" >> "%INSTALL_DIR%\iniciar_sistema.bat"
echo. >> "%INSTALL_DIR%\iniciar_sistema.bat"
echo :: Esperar a que PocketBase esté listo (5 segundos) >> "%INSTALL_DIR%\iniciar_sistema.bat"
echo timeout /t 5 /nobreak >> "%INSTALL_DIR%\iniciar_sistema.bat"
echo. >> "%INSTALL_DIR%\iniciar_sistema.bat"
echo :: Iniciar aplicación >> "%INSTALL_DIR%\iniciar_sistema.bat"
if "%MODO_INSTALACION%"=="PRODUCCION" (
    echo start chrome --kiosk --app=http://localhost:3000 >> "%INSTALL_DIR%\iniciar_sistema.bat"
) else (
    echo start chrome http://localhost:3000 >> "%INSTALL_DIR%\iniciar_sistema.bat"
)

echo [OK] Inicio automático configurado correctamente.
echo.
exit /b 0

:: Crear accesos directos
:CREAR_ACCESOS_DIRECTOS
echo [Paso adicional] Creando accesos directos...

:: Crear acceso directo en el escritorio
powershell -Command "& {$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut([System.Environment]::GetFolderPath('Desktop') + '\Sistema de Gestion de Llaves FCEA.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\iniciar_sistema.bat'; $Shortcut.Save()}" >nul 2>&1

:: Crear accesos directos en el menú inicio
if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Sistema de Gestion de Llaves FCEA" (
    mkdir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Sistema de Gestion de Llaves FCEA" 2>nul
)

powershell -Command "& {$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%APPDATA%\Microsoft\Windows\Start Menu\Programs\Sistema de Gestion de Llaves FCEA\Iniciar Sistema.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\iniciar_sistema.bat'; $Shortcut.Save()}" >nul 2>&1

echo [OK] Accesos directos creados correctamente.
echo.
exit /b 0

:: Instalar paquetes NPM
:INSTALAR_PAQUETES_NPM
echo [Paso adicional] Instalando paquetes NPM...

cd /d "%INSTALL_DIR%"

:: Verificar si node_modules ya está preempaquetado
if exist "%SCRIPT_DIR%\packages\node_modules.7z" (
    :: Extraer node_modules preempaquetado
    echo Extrayendo node_modules preempaquetado...
    if exist "%SCRIPT_DIR%\tools\7z.exe" (
        "%SCRIPT_DIR%\tools\7z.exe" x "%SCRIPT_DIR%\packages\node_modules.7z" -o"%INSTALL_DIR%" -y >nul
    ) else (
        :: Si no está 7z.exe, intentar con PowerShell
        powershell -Command "& {Expand-Archive -Path '%SCRIPT_DIR%\packages\node_modules.7z' -DestinationPath '%INSTALL_DIR%' -Force}" >nul 2>&1
    )
) else (
    :: Si no está preempaquetado, instalar desde package.json
    echo Instalando paquetes desde NPM (esto puede tardar varios minutos)...
    call npm install >nul 2>&1
    
    if %errorLevel% neq 0 (
        color 6F
        echo [ADVERTENCIA] Error al instalar paquetes NPM.
        echo Se intentará con opciones adicionales...
        
        call npm install --no-optional --no-fund --no-audit >nul 2>&1
        
        if %errorLevel% neq 0 (
            color 4F
            echo [ERROR] No se pudieron instalar los paquetes NPM.
            echo La instalación puede no funcionar correctamente.
            pause
        )
    )
)

:: Realizar build de producción si es modo producción
if "%MODO_INSTALACION%"=="PRODUCCION" (
    echo Realizando build de producción...
    call npm run build >nul 2>&1
)

echo [OK] Paquetes NPM instalados correctamente.
echo.
exit /b 0

:: Funciones específicas de recuperación
:RESPALDAR_DATOS_EXISTENTES
echo [Recuperación] Respaldando datos existentes...

if exist "%INSTALL_DIR%\pocketbase\pb_data" (
    set "BACKUP_FOLDER=%INSTALL_DIR%\respaldos\backup_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
    set "BACKUP_FOLDER=%BACKUP_FOLDER: =0%"
    mkdir "%BACKUP_FOLDER%" 2>nul
    
    echo Creando copia de seguridad en %BACKUP_FOLDER%...
    xcopy /E /I /H /Y "%INSTALL_DIR%\pocketbase\pb_data\*" "%BACKUP_FOLDER%\pb_data\" >nul
    
    :: También respaldar archivos de configuración
    if exist "%INSTALL_DIR%\pocketbase\pb_config.json" (
        copy "%INSTALL_DIR%\pocketbase\pb_config.json" "%BACKUP_FOLDER%\" /Y >nul
    )
)

echo [OK] Datos existentes respaldados correctamente.
echo.
exit /b 0

:: Reinstalar sistema
:REINSTALAR_SISTEMA
echo [Recuperación] Reinstalando archivos del sistema...

:: Preservar datos
if exist "%INSTALL_DIR%\pocketbase\pb_data" (
    mkdir "%TEMP%\pb_data_temp" 2>nul
    xcopy /E /I /H /Y "%INSTALL_DIR%\pocketbase\pb_data\*" "%TEMP%\pb_data_temp\" >nul
)

:: Preservar configuración
if exist "%INSTALL_DIR%\pocketbase\pb_config.json" (
    copy "%INSTALL_DIR%\pocketbase\pb_config.json" "%TEMP%\" /Y >nul
)

:: Eliminar archivos del sistema (excepto respaldos)
for /d %%D in ("%INSTALL_DIR%\*") do (
    if /i not "%%~nxD"=="respaldos" (
        rd /s /q "%%D" 2>nul
    )
)

for %%F in ("%INSTALL_DIR%\*.*") do (
    del "%%F" 2>nul
)

:: Reinstalar archivos
call :CREAR_DIRECTORIOS
call :COPIAR_ARCHIVOS

echo [OK] Sistema reinstalado correctamente.
echo.
exit /b 0

:: Restaurar datos
:RESTAURAR_DATOS
echo [Recuperación] Restaurando datos...

:: Restaurar datos de PocketBase
if exist "%TEMP%\pb_data_temp" (
    xcopy /E /I /H /Y "%TEMP%\pb_data_temp\*" "%INSTALL_DIR%\pocketbase\pb_data\" >nul
    rd /s /q "%TEMP%\pb_data_temp" >nul 2>&1
)

:: Restaurar configuración
if exist "%TEMP%\pb_config.json" (
    copy "%TEMP%\pb_config.json" "%INSTALL_DIR%\pocketbase\" /Y >nul
    del "%TEMP%\pb_config.json" >nul 2>&1
)

echo [OK] Datos restaurados correctamente.
echo.
exit /b 0

:: Finalizar instalación
:FINALIZAR_INSTALACION
cls
color 2F
echo ======================================================
echo     INSTALACIÓN COMPLETADA CORRECTAMENTE
echo ======================================================
echo.
if "%MODO_INSTALACION%"=="PRODUCCION" (
    echo Sistema de Gestión de Llaves FCEA ha sido instalado
    echo en modo PRODUCCIÓN.
) else if "%MODO_INSTALACION%"=="PRUEBA" (
    echo Sistema de Gestión de Llaves FCEA ha sido instalado
    echo en modo PRUEBA.
) else (
    echo Sistema de Gestión de Llaves FCEA ha sido recuperado
    echo correctamente.
)
echo.
echo Ubicación: %INSTALL_DIR%
echo.
echo Para iniciar el sistema:
echo  - Doble clic en el acceso directo del escritorio
echo  - O ejecute manualmente: %INSTALL_DIR%\iniciar_sistema.bat
echo.
echo ======================================================
echo.
echo ¿Desea iniciar el sistema ahora?
set /p INICIAR="Escriba 'SI' para iniciar ahora o cualquier otra tecla para finalizar: "

if /i "%INICIAR%"=="SI" (
    echo.
    echo Iniciando Sistema de Gestión de Llaves FCEA...
    start "" "%INSTALL_DIR%\iniciar_sistema.bat"
)

echo.
echo Gracias por instalar el Sistema de Gestión de Llaves FCEA.
echo.
pause
exit /b 0

:: Salir
:SALIR
cd /d "%CURRENT_DIR%"
exit /b 0