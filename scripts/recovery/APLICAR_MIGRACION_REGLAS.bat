@echo off
REM ============================================================================
REM APLICAR_MIGRACION_REGLAS.bat
REM ----------------------------------------------------------------------------
REM Aplica la migracion "1779500000_force_open_rules.js" que reabre las reglas
REM de las colecciones que el frontend usa (vigilante, solicitudes, etc).
REM
REM Necesario porque en algunas instalaciones el pb_data quedo con las reglas
REM en NULL (=solo admins) a pesar de que la migracion original las setea a "".
REM Sintoma: modal "Agregar vigilante" devuelve 400.
REM
REM Este script NO usa el CLI de admin, NO cambia passwords, NO toca la DB
REM directamente. Solo:
REM   1) Copia el archivo de migracion nuevo al pb_migrations de la instalacion
REM      productiva.
REM   2) Mata TODAS las instancias de pocketbase.exe (por si hay una zombie).
REM   3) Espera 5 seg a que se libere el puerto 8090.
REM   4) Arranca PocketBase de nuevo -> al arrancar aplica la migracion.
REM   5) Espera 5 seg y consulta la API para verificar que responde.
REM
REM USO: doble clic. Idempotente: se puede correr varias veces sin problemas.
REM ============================================================================

setlocal EnableDelayedExpansion

set "INSTALL_DIR=C:\sistema-llaves-fcea"
set "PB_EXE=%INSTALL_DIR%\pocketbase\pocketbase.exe"
set "MIGRATIONS_DIR=%INSTALL_DIR%\pocketbase\pb_migrations"
set "START_BAT=%INSTALL_DIR%\pocketbase\start-server.bat"
set "MIGRATION_FILE=1779500000_force_open_rules.js"

REM Este .bat esta pensado para ejecutarse desde el pendrive (E:\...). El
REM archivo de migracion nueva viaja al lado del .bat en el mismo directorio,
REM para que sea autoportable (podemos grabar el pendrive con esos 2 archivos
REM y correrlo sin depender del repo).
set "SCRIPT_DIR=%~dp0"
set "SOURCE_MIGRATION=%SCRIPT_DIR%%MIGRATION_FILE%"

echo.
echo ============================================================================
echo  APLICAR MIGRACION - Reabrir reglas de PocketBase
echo ============================================================================
echo.
echo  Instalacion  : %INSTALL_DIR%
echo  Migraciones  : %MIGRATIONS_DIR%
echo  Archivo nuevo: %MIGRATION_FILE%
echo.
echo  IMPORTANTE: durante ~10 segundos las terminales A y B NO van a poder
echo              registrar entregas / devoluciones. Ejecutar cuando no haya
echo              actividad.
echo.
pause

echo.
echo == Paso 1: verificar que existe la instalacion productiva ==

if not exist "%PB_EXE%" (
  echo    [ERROR] No se encontro %PB_EXE%
  echo            Este script asume la instalacion estandar en C:\sistema-llaves-fcea.
  echo            Abortando.
  pause
  exit /b 1
)
echo    OK - PocketBase esta en %PB_EXE%

if not exist "%MIGRATIONS_DIR%" (
  echo    [ERROR] No existe %MIGRATIONS_DIR%. Abortando.
  pause
  exit /b 1
)
echo    OK - Carpeta de migraciones existe.

echo.
echo == Paso 2: copiar la migracion nueva ==

if not exist "%SOURCE_MIGRATION%" (
  echo    [ERROR] No se encontro el archivo de migracion en:
  echo            %SOURCE_MIGRATION%
  echo            Este .bat debe estar en la misma carpeta que %MIGRATION_FILE%.
  pause
  exit /b 1
)

copy /Y "%SOURCE_MIGRATION%" "%MIGRATIONS_DIR%\%MIGRATION_FILE%" >nul
if errorlevel 1 (
  echo    [ERROR] Fallo al copiar la migracion. Verificar permisos.
  pause
  exit /b 1
)
echo    OK - Migracion copiada a %MIGRATIONS_DIR%\%MIGRATION_FILE%

echo.
echo == Paso 3: detener TODAS las instancias de pocketbase.exe ==

REM taskkill /F /IM mata todas las instancias sin importar de que ruta vengan.
REM Redirigimos error a nul porque si no hay ninguna corriendo tira error y
REM no queremos que eso aborte el script.
taskkill /F /IM pocketbase.exe >nul 2>&1
if errorlevel 1 (
  echo    Nota: no habia procesos pocketbase.exe corriendo. Continuamos.
) else (
  echo    OK - pocketbase.exe detenido.
)

echo.
echo == Paso 4: esperar 5 segundos a que se libere el puerto 8090 ==
timeout /t 5 /nobreak >nul
echo    OK.

echo.
echo == Paso 5: arrancar PocketBase (aplica la migracion en el startup) ==

if not exist "%START_BAT%" (
  echo    [ERROR] No existe %START_BAT%. Abortando.
  pause
  exit /b 1
)

REM Lanzamos el server en una ventana NUEVA para que quede corriendo despues
REM de que este .bat termine. El titulo "PocketBase" es el mismo que usa el
REM start-server.bat original, asi que se comporta igual que arrancarlo a mano.
start "PocketBase" /D "%INSTALL_DIR%\pocketbase" "%START_BAT%"
echo    OK - PocketBase lanzado en ventana nueva.

echo.
echo == Paso 6: esperar 6 segundos y verificar que responde ==
timeout /t 6 /nobreak >nul

REM curl viene con Windows 10+. Consultamos el health endpoint (no requiere auth)
curl -s -o nul -w "    HTTP %%{http_code} desde /api/health\n" http://127.0.0.1:8090/api/health
if errorlevel 1 (
  echo    [ADVERTENCIA] No se pudo consultar la API. Revisar la ventana de PocketBase.
) else (
  echo    OK - PocketBase esta respondiendo.
)

echo.
echo == Paso 7: verificar que la migracion se aplico (reglas de vigilante) ==

REM Consultamos la coleccion vigilante como usuario anonimo. Si las reglas
REM estan abiertas, devuelve 200 con la lista (aunque este vacia). Si siguen
REM cerradas, devuelve 400 o 403.
curl -s -o nul -w "    HTTP %%{http_code} desde /api/collections/vigilante/records\n" http://127.0.0.1:8090/api/collections/vigilante/records

echo.
echo ============================================================================
echo  LISTO. Ahora en el navegador del monitor:
echo    1) Recargar la pagina (F5 o Ctrl+R).
echo    2) Abrir el modal "Gestion de vigilantes".
echo    3) Intentar agregar un vigilante nuevo.
echo.
echo  Si el paso 7 mostro HTTP 200, el bug esta arreglado.
echo  Si mostro 400/403, la migracion no se aplico -> avisar y revisar la
echo  ventana de PocketBase para ver el log de arranque.
echo ============================================================================
echo.
pause
endlocal
