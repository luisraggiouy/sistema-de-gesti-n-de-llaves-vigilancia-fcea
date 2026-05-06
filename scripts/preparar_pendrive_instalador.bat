@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================================================
:: Script: Preparar Pendrive Instalador
:: Propósito: Crear un pendrive de instalación automática del sistema
:: Versión: 1.0
:: ============================================================================

title Preparación de Pendrive Instalador - Sistema de Llaves FCEA

color 0A
echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║                                                                    ║
echo ║     PREPARACIÓN DE PENDRIVE INSTALADOR                             ║
echo ║     Sistema de Gestión de Llaves - FCEA                            ║
echo ║                                                                    ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.

:: Verificar que se ejecuta como administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    color 0C
    echo [ERROR] Este script debe ejecutarse como Administrador
    echo.
    echo Clic derecho en el archivo ^> "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

:: Detectar letra del pendrive
echo [1/8] Detectando pendrive conectado...
echo.
echo Pendrives disponibles:
echo.

set DRIVE_COUNT=0
for %%d in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist %%d:\ (
        vol %%d: 2>nul | find "INSTALADOR" >nul
        if !errorLevel! equ 0 (
            set PENDRIVE=%%d:
            set /a DRIVE_COUNT+=1
            echo   [X] %%d: - INSTALADOR_LLAVES_FCEA ^(Detectado^)
        ) else (
            echo   [ ] %%d: - Otro dispositivo
        )
    )
)

echo.
if %DRIVE_COUNT% equ 0 (
    color 0E
    echo [ADVERTENCIA] No se detectó un pendrive con nombre "INSTALADOR_LLAVES_FCEA"
    echo.
    echo Por favor:
    echo 1. Conecte un pendrive de 16 GB mínimo
    echo 2. Formatéelo como FAT32 o NTFS
    echo 3. Nómbrelo: INSTALADOR_LLAVES_FCEA
    echo 4. Vuelva a ejecutar este script
    echo.
    pause
    exit /b 1
)

if %DRIVE_COUNT% gtr 1 (
    color 0E
    echo [ADVERTENCIA] Se detectaron múltiples pendrives con el nombre correcto
    echo Por favor, deje conectado solo el pendrive que desea preparar
    echo.
    pause
    exit /b 1
)

echo [OK] Pendrive detectado en %PENDRIVE%
echo.
pause

:: Verificar espacio disponible
echo [2/8] Verificando espacio disponible en el pendrive...
for /f "tokens=3" %%a in ('dir %PENDRIVE% ^| find "bytes free"') do set FREE_SPACE=%%a
echo Espacio libre: %FREE_SPACE% bytes
echo.

:: Limpiar pendrive
echo [3/8] Limpiando contenido anterior del pendrive...
if exist "%PENDRIVE%\sistema" (
    echo Eliminando carpeta sistema anterior...
    rd /s /q "%PENDRIVE%\sistema" 2>nul
)
if exist "%PENDRIVE%\scripts" (
    echo Eliminando carpeta scripts anterior...
    rd /s /q "%PENDRIVE%\scripts" 2>nul
)
if exist "%PENDRIVE%\docs" (
    echo Eliminando carpeta docs anterior...
    rd /s /q "%PENDRIVE%\docs" 2>nul
)
if exist "%PENDRIVE%\instaladores" (
    echo Eliminando carpeta instaladores anterior...
    rd /s /q "%PENDRIVE%\instaladores" 2>nul
)
echo [OK] Pendrive limpiado
echo.

:: Crear estructura de carpetas
echo [4/8] Creando estructura de carpetas...
mkdir "%PENDRIVE%\sistema" 2>nul
mkdir "%PENDRIVE%\scripts" 2>nul
mkdir "%PENDRIVE%\docs" 2>nul
mkdir "%PENDRIVE%\instaladores" 2>nul
echo [OK] Estructura creada
echo.

:: Copiar sistema completo
echo [5/8] Copiando sistema completo al pendrive...
echo Esto puede tardar 5-10 minutos dependiendo de la velocidad del pendrive...
echo.

xcopy /E /I /Y /Q "%~dp0..\src" "%PENDRIVE%\sistema\src\" >nul
xcopy /E /I /Y /Q "%~dp0..\pocketbase" "%PENDRIVE%\sistema\pocketbase\" >nul
xcopy /E /I /Y /Q "%~dp0..\public" "%PENDRIVE%\sistema\public\" >nul
xcopy /E /I /Y /Q "%~dp0..\scripts" "%PENDRIVE%\sistema\scripts\" >nul

copy /Y "%~dp0..\package.json" "%PENDRIVE%\sistema\" >nul
copy /Y "%~dp0..\package-lock.json" "%PENDRIVE%\sistema\" >nul
copy /Y "%~dp0..\tsconfig.json" "%PENDRIVE%\sistema\" >nul
copy /Y "%~dp0..\tsconfig.app.json" "%PENDRIVE%\sistema\" >nul
copy /Y "%~dp0..\tsconfig.node.json" "%PENDRIVE%\sistema\" >nul
copy /Y "%~dp0..\vite.config.ts" "%PENDRIVE%\sistema\" >nul
copy /Y "%~dp0..\index.html" "%PENDRIVE%\sistema\" >nul
copy /Y "%~dp0..\tailwind.config.ts" "%PENDRIVE%\sistema\" >nul
copy /Y "%~dp0..\postcss.config.js" "%PENDRIVE%\sistema\" >nul
copy /Y "%~dp0..\components.json" "%PENDRIVE%\sistema\" >nul
copy /Y "%~dp0..\README.md" "%PENDRIVE%\sistema\" >nul
copy /Y "%~dp0..\iniciar_sistema.bat" "%PENDRIVE%\sistema\" >nul
copy /Y "%~dp0..\.env.example" "%PENDRIVE%\sistema\" >nul

echo [OK] Sistema copiado
echo.

:: Copiar scripts de instalación
echo [6/8] Copiando scripts de instalación...
copy /Y "%~dp0instalar_automatico.ps1" "%PENDRIVE%\scripts\" >nul 2>&1
copy /Y "%~dp0configurar_pantallas.ps1" "%PENDRIVE%\scripts\" >nul 2>&1
copy /Y "%~dp0configurar_kiosk.ps1" "%PENDRIVE%\scripts\" >nul 2>&1
copy /Y "%~dp0configurar_mantenimiento.ps1" "%PENDRIVE%\scripts\" >nul 2>&1
echo [OK] Scripts copiados
echo.

:: Copiar documentación
echo [7/8] Copiando documentación...
xcopy /E /I /Y /Q "%~dp0..\docs" "%PENDRIVE%\docs\" >nul
echo [OK] Documentación copiada
echo.

:: Crear script principal de instalación
echo [8/8] Creando script principal de instalación...
(
echo @echo off
echo chcp 65001 ^>nul
echo title Instalador Automático - Sistema de Llaves FCEA
echo.
echo echo ╔════════════════════════════════════════════════════════════════════╗
echo echo ║                                                                    ║
echo echo ║     INSTALADOR AUTOMÁTICO - SISTEMA DE LLAVES FCEA                 ║
echo echo ║                                                                    ║
echo echo ╚════════════════════════════════════════════════════════════════════╝
echo echo.
echo echo Iniciando instalación...
echo echo.
echo.
echo :: Verificar administrador
echo net session ^>nul 2^>^&1
echo if %%errorLevel%% neq 0 ^(
echo     echo [ERROR] Debe ejecutar como Administrador
echo     pause
echo     exit /b 1
echo ^)
echo.
echo :: Ejecutar instalador PowerShell
echo powershell.exe -ExecutionPolicy Bypass -File "%%~dp0scripts\instalar_automatico.ps1"
echo.
echo pause
) > "%PENDRIVE%\INSTALAR_SISTEMA.bat"

echo [OK] Script principal creado
echo.

:: Resumen final
color 0A
echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║                                                                    ║
echo ║     ✅ PENDRIVE INSTALADOR PREPARADO EXITOSAMENTE                  ║
echo ║                                                                    ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.
echo Ubicación: %PENDRIVE%
echo.
echo ⚠️  PASOS FINALES IMPORTANTES:
echo.
echo 1. Descargar Node.js:
echo    - Ir a: https://nodejs.org/
echo    - Descargar "Windows Installer (.msi)" - versión LTS
echo    - Guardar como: %PENDRIVE%\instaladores\node-setup.msi
echo.
echo 2. Etiquetar el pendrive físicamente:
echo    "INSTALADOR SISTEMA LLAVES FCEA"
echo    "Versión 5.1 - Mayo 2026"
echo    "NO BORRAR - SOLO LECTURA"
echo.
echo 3. Guardar el pendrive en lugar seguro
echo.
echo 4. Para usar: Conectar pendrive y ejecutar INSTALAR_SISTEMA.bat
echo.
echo.
pause
