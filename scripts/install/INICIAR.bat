@echo off
REM ============================================================
REM  Sistema de Gestion de Llaves FCEA v2.0
REM  Lanzador inteligente por rol
REM ============================================================
REM
REM  Lee public\config.json y arranca:
REM    - rol=monitor      → PocketBase + frontend en kiosk Chrome
REM    - rol=terminal-a   → solo frontend en kiosk Chrome
REM    - rol=terminal-b   → solo frontend en kiosk Chrome
REM    - rol=dashboard    → solo frontend en kiosk Chrome
REM ============================================================

setlocal
cd /d "%~dp0\..\.."

if not exist public\config.json (
  echo [ERROR] public\config.json no existe. Ejecute INSTALAR.bat primero.
  pause
  exit /b 1
)

REM Leer el rol del config.json con PowerShell
for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-Content public\config.json | ConvertFrom-Json).rol"') do set ROL=%%i
for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-Content public\config.json | ConvertFrom-Json).modo"') do set MODO=%%i

echo.
echo  Iniciando Sistema FCEA v2.0
echo  - Modo : %MODO%
echo  - Rol  : %ROL%
echo.

REM 1) Si soy el servidor, arranco PocketBase en una ventana aparte
if /i "%ROL%"=="monitor" (
  echo Arrancando servidor PocketBase en ventana separada...
  start "FCEA - PocketBase Server" /MIN cmd /c pocketbase\start-server.bat

  REM Esperar 2 segundos a que PocketBase levante
  timeout /t 2 /nobreak >nul
)

REM 2) Servir el frontend (dist\) con un servidor estatico minimo en :5173
echo Sirviendo frontend en http://127.0.0.1:5173 ...
if not exist dist\ (
  echo [ERROR] No existe carpeta dist\. Ejecute INSTALAR.bat o "npm run build".
  pause
  exit /b 1
)

start "FCEA - Frontend" /MIN cmd /c npx --yes serve -s dist -l 5173

timeout /t 2 /nobreak >nul

REM 3) Abrir Chrome en modo kiosk apuntando a la URL local
echo Abriendo navegador en modo kiosk...
set CHROME_PATH="C:\Program Files\Google\Chrome\Application\chrome.exe"
if not exist %CHROME_PATH% set CHROME_PATH="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
if not exist %CHROME_PATH% (
  echo [ADVERTENCIA] Google Chrome no encontrado. Abriendo en el navegador por defecto.
  start http://127.0.0.1:5173/
  goto FIN
)

if /i "%MODO%"=="produccion" (
  REM Modo kiosk de pantalla completa, sin barra de direcciones.
  start "" %CHROME_PATH% --kiosk --noerrdialogs --disable-infobars --no-first-run --disable-features=TranslateUI --user-data-dir="%TEMP%\fcea-chrome-profile" "http://127.0.0.1:5173/"
) else (
  REM Modo desarrollo: ventana normal con devtools deshabilitado.
  start "" %CHROME_PATH% --new-window --no-first-run "http://127.0.0.1:5173/"
)

:FIN
echo.
echo Sistema iniciado. Cierre esta ventana solo cuando quiera detener todo.
echo.
endlocal
