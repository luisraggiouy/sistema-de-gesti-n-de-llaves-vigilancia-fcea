@echo off
REM ============================================================
REM  Sistema FCEA - Abrir Llaves en modo KIOSK   (fix 2026-07-31)
REM ------------------------------------------------------------
REM  Uso: doble click en el icono del escritorio
REM       "abrir llaves FCEA modo kiosk".
REM
REM  Que hace (version corregida):
REM   1) Lee rol y hardware del config.json.
REM   2) SE ASEGURA de que el frontend LOCAL este arriba en
REM      127.0.0.1:5173 (cada PC sirve su propio dist). Si no
REM      responde, lo arranca con run_frontend.bat (desacoplado)
REM      y espera hasta 20s.
REM   3) Abre el navegador en modo kiosk apuntando SIEMPRE al
REM      frontend LOCAL http://127.0.0.1:5173.
REM
REM  BUG FIX (2026-07-31):
REM    La version v2.8 leia pocketbase_url, sondeaba el 8090 del
REM    Monitor y abria el navegador ahi. Pero el 8090 del Monitor
REM    es SOLO-API (PocketBase) y devuelve {"code":404,"message":
REM    "Not Found."} para rutas SPA como /terminal?id=B. Los DATOS
REM    ya viajan al Monitor por dentro de la app (pocketbase_url).
REM    El navegador debe cargar SIEMPRE el frontend LOCAL 5173.
REM    Probado con exito en Terminal B (2026-07-31).
REM ============================================================

setlocal EnableDelayedExpansion
title Abrir Llaves FCEA - modo kiosk

set "INSTALL_DIR=C:\sistema-llaves-fcea"
set "CFG=%INSTALL_DIR%\dist\config.json"
if not exist "%CFG%" set "CFG=%INSTALL_DIR%\public\config.json"

if not exist "%CFG%" (
  echo.
  echo   [ERROR] No se encontro el config.json del sistema.
  echo           Ruta buscada: %CFG%
  echo.
  echo   Verifique que el sistema este instalado en:
  echo     %INSTALL_DIR%
  echo.
  pause
  exit /b 1
)

REM ------------------------------------------------------------
REM Leer rol y hardware del config.json.
REM ------------------------------------------------------------
set "ROL="
set "HW="
for /f "usebackq delims=" %%r in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content '%CFG%' -Raw | ConvertFrom-Json).rol"`) do set "ROL=%%r"
for /f "usebackq delims=" %%h in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content '%CFG%' -Raw | ConvertFrom-Json).hardware"`) do set "HW=%%h"

if not defined ROL set "ROL=monitor"
if not defined HW  set "HW=tradicional"

REM ------------------------------------------------------------
REM El frontend es SIEMPRE local. Puerto fijo 5173.
REM ------------------------------------------------------------
set "BASE_URL=http://127.0.0.1:5173"

REM ------------------------------------------------------------
REM Asegurar que el frontend LOCAL (5173) este escuchando.
REM Si no, arrancarlo desacoplado con run_frontend.bat.
REM ------------------------------------------------------------
call :TEST_5173
if "!PORT_UP!"=="0" (
  echo   [INFO] El frontend local 5173 no responde. Arrancandolo...
  set "RUNFE=%INSTALL_DIR%\scripts\lib\run_frontend.bat"
  set "STARTDET=%INSTALL_DIR%\scripts\lib\start_detached.ps1"
  if exist "!STARTDET!" if exist "!RUNFE!" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!STARTDET!" -Target "!RUNFE!" >nul 2>&1
  ) else (
    if exist "!RUNFE!" start "" /min cmd /c "!RUNFE!"
  )
  echo   [INFO] Esperando a que 5173 responda...
  for /l %%N in (1,1,20) do (
    timeout /t 1 /nobreak >nul
    call :TEST_5173
    if "!PORT_UP!"=="1" goto :FE_ARRIBA
    <nul set /p "=."
  )
  echo.
  echo   [AVISO] 5173 aun no responde. Se abrira igual; refresque si ve error.
)
:FE_ARRIBA

echo.
echo  ============================================================
echo   Abriendo Llaves FCEA en modo KIOSK
echo  ============================================================
echo   Rol      : %ROL%
echo   Hardware : %HW%
echo   Servidor : %BASE_URL%   (frontend LOCAL)
echo.
echo   Para salir del kiosk: Alt+F4 (o Ctrl+F4)
echo  ============================================================
echo.

REM Cerrar instancia previa del navegador del sistema (mismo perfil).
taskkill /F /IM msedge.exe /FI "WINDOWTITLE eq *Llaves*" >nul 2>&1
taskkill /F /IM chrome.exe /FI "WINDOWTITLE eq *Llaves*" >nul 2>&1

set "LANZADOR=%INSTALL_DIR%\scripts\lib\lanzar_navegador.ps1"
if not exist "%LANZADOR%" (
  echo   [ERROR] No se encontro %LANZADOR%
  echo           El sistema puede estar mal instalado.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%LANZADOR%" -Rol "%ROL%" -Modo produccion -Hardware "%HW%" -BaseUrl "%BASE_URL%"
set "EXIT=%ERRORLEVEL%"

if not "%EXIT%"=="0" (
  echo.
  echo   [AVISO] lanzar_navegador.ps1 devolvio codigo %EXIT%
  echo           Verifique que Edge o Chrome esten instalados.
  echo.
  pause
)

endlocal
exit /b 0

REM ============================================================
REM  Subrutina: TEST_5173 -> setea PORT_UP=1 si 127.0.0.1:5173
REM  esta escuchando, 0 si no.
REM ============================================================
:TEST_5173
set "PORT_UP=0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=New-Object Net.Sockets.TcpClient; try { $r=$c.BeginConnect('127.0.0.1',5173,$null,$null); if ($r.AsyncWaitHandle.WaitOne(500)) { $c.EndConnect($r); exit 0 } else { exit 1 } } catch { exit 1 } finally { $c.Close() }" >nul 2>&1
if !ERRORLEVEL! EQU 0 set "PORT_UP=1"
goto :eof
