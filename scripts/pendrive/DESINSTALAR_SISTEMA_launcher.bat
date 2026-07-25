@echo off
REM ============================================================
REM  Sistema de Gestion de Llaves FCEA - DESINSTALADOR v5.2
REM ============================================================
REM  Doble click para desinstalar el sistema. Se pedira automaticamente
REM  permiso de administrador (UAC).
REM
REM  v5.2 (fix critico):
REM   - Estructura PLANA con GOTO en lugar de "if anidado (...)"
REM     El parser de cmd.exe rompia con "No se esperaba . en este
REM     momento" al combinar:
REM        - if /i "!VAR!"=="..." (
REM        -   if exist "...\data.db" (   <-- el punto rompia
REM   - Se detecta rol con "for /f" FUERA de bloques con parentesis.
REM   - Log en %TEMP%\fcea_desinstalar.log para diagnostico.
REM ============================================================

REM  NO usamos EnableDelayedExpansion. Todo con %VAR% directas.
setlocal
title Sistema FCEA - Desinstalador v5.2

set "LOGFILE=%TEMP%\fcea_desinstalar.log"
echo === FCEA Desinstalador v5.2 - %date% %time% === > "%LOGFILE%"

REM ------------------------------------------------------------
REM  Auto-elevacion a Administrador (UAC)
REM ------------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 goto NEED_ELEV
goto ADMIN_OK

:NEED_ELEV
echo.
echo  Solicitando permisos de Administrador...
echo  Aparecera una ventana de "Control de cuentas de usuario";
echo  haga click en SI para continuar.
echo.
powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/k', '\"%~f0\"' -Verb RunAs"
exit /b

:ADMIN_OK
pushd "%~dp0" 2>nul

set "PENDRIVE_ROOT=%~dp0"
if "%PENDRIVE_ROOT:~-1%"=="\" set "PENDRIVE_ROOT=%PENDRIVE_ROOT:~0,-1%"

set "INSTALL_DIR=C:\sistema-llaves-fcea"
set "PROGDATA_DIR=C:\ProgramData\FCEA-Sistema-Llaves"
set "CONFIG_FILE=%INSTALL_DIR%\public\config.json"
set "PROGDATA_DB=%PROGDATA_DIR%\pb_data\data.db"

echo PENDRIVE_ROOT=%PENDRIVE_ROOT% >> "%LOGFILE%"
echo INSTALL_DIR=%INSTALL_DIR% >> "%LOGFILE%"
echo PROGDATA_DIR=%PROGDATA_DIR% >> "%LOGFILE%"

cls
echo.
echo  ============================================================
echo                  Sistema de Gestion de Llaves
echo                Facultad de Ciencias Economicas
echo                  DESINSTALADOR - UDELAR v5.2
echo  ============================================================
echo.

REM ------------------------------------------------------------
REM  PASO 1: Detectar rol de esta PC (leyendo config.json)
REM
REM  IMPORTANTE: hacer esto FUERA de cualquier bloque de parentesis
REM  para no chocar con el bug del parser de cmd.exe.
REM ------------------------------------------------------------
set "ROL_ACTUAL="
if not exist "%CONFIG_FILE%" goto ROL_DONE

REM  Leer el rol via PowerShell y volcarlo a un archivo temporal
set "ROL_TMP=%TEMP%\fcea_rol_%RANDOM%.txt"
powershell -NoProfile -Command "try { $c = Get-Content '%CONFIG_FILE%' -Raw | ConvertFrom-Json; Set-Content -Path '%ROL_TMP%' -Value $c.rol -NoNewline } catch { Set-Content -Path '%ROL_TMP%' -Value '' -NoNewline }"

if not exist "%ROL_TMP%" goto ROL_DONE
set /p ROL_ACTUAL=<"%ROL_TMP%"
del /q "%ROL_TMP%" 2>nul

:ROL_DONE
if "%ROL_ACTUAL%"=="" set "ROL_ACTUAL=desconocido"
echo   Rol detectado en esta PC: %ROL_ACTUAL%
echo   [log] ROL_ACTUAL=%ROL_ACTUAL% >> "%LOGFILE%"
echo.

REM ------------------------------------------------------------
REM  PASO 2: Si es Monitor, refrescar semilla ANTES de desinstalar
REM  Se hace 100% con GOTO / labels, sin if anidados.
REM ------------------------------------------------------------
if /i not "%ROL_ACTUAL%"=="monitor" goto SKIP_SEMILLA

REM Verificar si hay base productiva sin usar parentesis anidados
if not exist "%PROGDATA_DB%" goto NO_PRODDATA

echo  ============================================================
echo   PASO 1/2 : GUARDANDO DATOS ACTUALES EN EL PENDRIVE
echo  ============================================================
echo.
echo   Esta PC es el Monitor Vigilancia y contiene la base
echo   productiva. Antes de desinstalar, se copiaran los datos
echo   actuales al pendrive, para poder reinstalar en el futuro
echo   sin perder llaves ni historial.
echo.
echo   Se le puede preguntar S/N al script. Responda S.
echo.

set "SEED_SCRIPT=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\pendrive\actualizar_semilla.ps1"
if not exist "%SEED_SCRIPT%" goto SEED_MISSING

REM ------------------------------------------------------------
REM  v5.3 (piloto sabado 2026-07-25): antes de copiar data.db al
REM  pendrive debemos DETENER PocketBase limpio. Si estaba corriendo
REM  (por la tarea programada FCEA-Sistema-Llaves-AutoStart), tenia
REM  lock exclusivo de SQLite y la copia del .db-wal quedaba
REM  inconsistente (semilla corrupta). Usamos el helper
REM  kill_pocketbase_zombis.ps1 que ademas mata la instancia elevada
REM  que taskkill /F no puede matar.
REM ------------------------------------------------------------
set "LIB_KILL_PB=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\lib\kill_pocketbase_zombis.ps1"
if exist "%LIB_KILL_PB%" (
    echo   [i] Deteniendo PocketBase antes de copiar la semilla...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%LIB_KILL_PB%" >>"%LOGFILE%" 2>&1
    echo   [log] kill_pocketbase_zombis ejecutado >> "%LOGFILE%"
) else (
    echo   [WARN] No se encontro kill_pocketbase_zombis.ps1 - la semilla puede quedar inconsistente si PocketBase esta corriendo.
    echo   [log] kill_pocketbase_zombis.ps1 no encontrado >> "%LOGFILE%"
    taskkill /F /IM pocketbase.exe >>"%LOGFILE%" 2>&1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%SEED_SCRIPT%" -PendriveRoot "%PENDRIVE_ROOT%"
set "SEED_EXIT=%ERRORLEVEL%"
echo   [log] SEED_EXIT=%SEED_EXIT% >> "%LOGFILE%"
if not "%SEED_EXIT%"=="0" goto SEED_FAILED
goto SEMILLA_OK

:SEED_MISSING
echo   [AVISO] No se encontro actualizar_semilla.ps1 en el pendrive.
echo   Se salta el refresco de semilla y se continua con la desinstalacion.
echo   [log] actualizar_semilla.ps1 no encontrado >> "%LOGFILE%"
echo.
timeout /t 3 /nobreak >nul
goto SEMILLA_OK

:SEED_FAILED
echo.
echo  [ADVERTENCIA] La grabacion de la semilla termino con codigo %SEED_EXIT%.
echo                El pendrive puede haber quedado desactualizado.
echo.
set /p SEGUIR="Continuar con la desinstalacion de todos modos? [S/N]: "
if /i not "%SEGUIR%"=="S" goto USER_CANCELED
goto SEMILLA_OK

:NO_PRODDATA
echo   No hay base productiva en esta PC ^(%PROGDATA_DIR%\pb_data^).
echo   Se salta el refresco de semilla del pendrive.
echo   [log] No hay data.db en ProgramData >> "%LOGFILE%"
echo.
goto SEMILLA_OK

:SKIP_SEMILLA
echo   Rol distinto de "monitor": no se refresca semilla del pendrive.
echo   ^(La semilla solo se genera desde el Monitor Vigilancia.^)
echo.
goto SEMILLA_OK

:SEMILLA_OK

REM ------------------------------------------------------------
REM  PASO 3: Llamar al desinstalador interno del pendrive
REM ------------------------------------------------------------
echo  ============================================================
echo   PASO 2/2 : DESINSTALANDO SISTEMA
echo  ============================================================
echo.

set "DESINST_INTERNO=%PENDRIVE_ROOT%\sistema-llaves-fcea\scripts\install\DESINSTALAR.bat"

if not exist "%DESINST_INTERNO%" goto NO_INTERNO
call "%DESINST_INTERNO%"
set "DESINST_EXIT=%ERRORLEVEL%"
echo   [log] DESINST_EXIT=%DESINST_EXIT% >> "%LOGFILE%"
goto FINAL

:NO_INTERNO
echo  [ERROR] No se encontro el desinstalador interno en el pendrive.
echo          Ruta esperada:
echo          %DESINST_INTERNO%
echo.
echo  Este pendrive esta danado o es de una version incompatible.
echo   [log] Desinstalador interno no encontrado >> "%LOGFILE%"
echo.
pause >nul
exit /b 1

:USER_CANCELED
echo.
echo  Desinstalacion cancelada por el usuario.
echo   [log] Cancelacion manual del usuario >> "%LOGFILE%"
pause
exit /b 3

:FINAL
echo.
echo  ============================================================
if "%DESINST_EXIT%"=="0" goto FINAL_OK
echo   [AVISO] El desinstalador interno termino con codigo %DESINST_EXIT%.
echo           Revise los mensajes anteriores para detalles.
goto FINAL_END

:FINAL_OK
echo   [LISTO] Desinstalacion finalizada.
echo.
if /i not "%ROL_ACTUAL%"=="monitor" goto FINAL_END
echo   Los datos productivos siguen disponibles en:
echo     - El pendrive ^(semilla actualizada hoy^)
echo     - C:\backup_fcea_*\ ^(respaldo del desinstalador interno^)
echo.
echo   Para reinstalar en el futuro, ejecute INSTALAR SISTEMA.bat
echo   desde el pendrive: la semilla incluira los datos actuales.

:FINAL_END
echo  ============================================================
echo.
echo  Log de esta ejecucion:
echo    %LOGFILE%
echo.
echo  Puede cerrar esta ventana cuando termine de leer.
echo  Presione cualquier tecla para salir...
pause >nul

endlocal
exit /b
