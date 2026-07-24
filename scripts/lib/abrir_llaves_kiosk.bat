@echo off
REM ============================================================
REM  Sistema FCEA - Abrir Llaves en modo KIOSK
REM ------------------------------------------------------------
REM  Uso: doble click en el icono del escritorio
REM       "abrir llaves FCEA modo kiosk".
REM
REM  Que hace:
REM   1) Lee C:\sistema-llaves-fcea\public\config.json para saber
REM      el rol (monitor / terminal-a / terminal-b / dashboard),
REM      el hardware (tactil / tradicional) y la URL base del
REM      servidor (pocketbase_url o red.ip_servidor).
REM   2) Detecta que puerto tiene el frontend arriba (8090 si
REM      PocketBase esta sirviendo el dist\, 5173 si es Vite dev).
REM   3) Llama a scripts\lib\lanzar_navegador.ps1 con esos valores
REM      y modo=produccion, que abre Edge/Chrome en modo --kiosk.
REM
REM  Sirve cuando el vigilante sale del kiosk (Alt+F4) para hacer
REM  algo en Windows y despues quiere volver al sistema sin
REM  reiniciar la PC. Tambien sirve para las Terminales A/B en
REM  el escenario "monitor comun + teclado + mouse" (sin touch).
REM
REM  BUG FIX (v2.8, 2026-07-23):
REM    Antes este .bat NO pasaba -BaseUrl a lanzar_navegador.ps1,
REM    y el default de lanzar_navegador.ps1 era http://127.0.0.1:5173.
REM    Eso funcionaba en el Monitor (donde 127.0.0.1 SI es el
REM    servidor) pero en las Terminales A/B abria una URL de
REM    localhost inexistente y salia ERR_CONNECTION_REFUSED.
REM    Ahora leemos la IP del servidor del config.json y armamos
REM    la URL correcta para cada PC.
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

REM Leer rol, hardware, IP servidor y URL base con PowerShell.
REM Devolvemos strings vacios para los que falten en el JSON.
set "ROL="
set "HW="
set "PB_URL="
set "IP_SRV="
for /f "usebackq delims=" %%r in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content '%CFG%' -Raw | ConvertFrom-Json).rol"`) do set "ROL=%%r"
for /f "usebackq delims=" %%h in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content '%CFG%' -Raw | ConvertFrom-Json).hardware"`) do set "HW=%%h"
for /f "usebackq delims=" %%p in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content '%CFG%' -Raw | ConvertFrom-Json).pocketbase_url"`) do set "PB_URL=%%p"
for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content '%CFG%' -Raw | ConvertFrom-Json).red.ip_servidor"`) do set "IP_SRV=%%i"

if not defined ROL set "ROL=monitor"
if not defined HW  set "HW=tradicional"

REM ------------------------------------------------------------
REM  Resolver BASE_URL (IP + puerto del frontend) leyendo config.
REM
REM  Estrategia:
REM   a) Si tenemos pocketbase_url, extraemos el host y ese es
REM      el servidor. Probamos primero puerto 8090 (dist/ servido
REM      por PocketBase) y luego 5173 (Vite dev).
REM   b) Si no hay pocketbase_url pero si ip_servidor, usamos
REM      esa IP y probamos 8090, 5173 en ese orden.
REM   c) Si NADA se puede leer del config, caemos al historico
REM      127.0.0.1:5173 (comportamiento previo, para no romper
REM      el rol=monitor de instalaciones viejas).
REM ------------------------------------------------------------
set "HOST="

if defined PB_URL (
  REM Extraer host y port del pocketbase_url (ej. http://192.168.1.10:8090).
  for /f "usebackq delims=" %%u in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $u=[Uri]'%PB_URL%'; $u.Host } catch { '' }"`) do set "HOST=%%u"
)

if not defined HOST if defined IP_SRV set "HOST=%IP_SRV%"

if not defined HOST set "HOST=127.0.0.1"

REM Probar puertos en orden: 8090 (PB sirviendo dist), 5173 (Vite dev).
REM Usamos powershell para hacer un TCP test rapido con timeout corto.
set "PORT="
for %%P in (8090 5173) do (
  if not defined PORT (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$c = New-Object Net.Sockets.TcpClient; try { $r = $c.BeginConnect('%HOST%', %%P, $null, $null); if ($r.AsyncWaitHandle.WaitOne(500)) { $c.EndConnect($r); exit 0 } else { exit 1 } } catch { exit 1 } finally { $c.Close() }" >nul 2>&1
    if !ERRORLEVEL! EQU 0 set "PORT=%%P"
  )
)

if not defined PORT (
  REM Ningun puerto respondio. Igual seguimos - puede ser que el
  REM servidor aun no este arriba; lanzar_navegador va a mostrar
  REM la pagina de error y el usuario puede refrescar.
  echo   [AVISO] No responde ni 8090 ni 5173 en %HOST%. Se usara 8090 por defecto.
  set "PORT=8090"
)

set "BASE_URL=http://%HOST%:%PORT%"

echo.
echo  ============================================================
echo   Abriendo Llaves FCEA en modo KIOSK
echo  ============================================================
echo   Rol      : %ROL%
echo   Hardware : %HW%
echo   Servidor : %BASE_URL%
echo.
echo   Para salir del kiosk: Alt+F4 (o Ctrl+F4)
echo  ============================================================
echo.

REM Asegurarnos de que no queda una instancia previa del navegador
REM del sistema (mismo perfil dedicado) - de lo contrario Chrome/Edge
REM reutiliza la ventana existente y NO entra en kiosk.
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
