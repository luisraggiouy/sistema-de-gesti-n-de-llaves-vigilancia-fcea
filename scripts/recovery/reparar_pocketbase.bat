@echo off
REM Reparar configuracion de PocketBase (firewall + puerto)
setlocal

echo.
echo === Reparando PocketBase ===
echo.

set /p REPO_DEST="Ruta de la instalacion (ej. C:\sistema-llaves-fcea): "
if not exist "%REPO_DEST%\pocketbase\pocketbase.exe" (
  echo [ERROR] pocketbase.exe no encontrado en %REPO_DEST%\pocketbase
  exit /b 1
)

echo Cerrando procesos de pocketbase.exe...
taskkill /IM pocketbase.exe /F >nul 2>nul

echo Limpiando regla de firewall previa...
netsh advfirewall firewall delete rule name="FCEA-PocketBase-8090" >nul 2>nul

echo Creando regla de firewall nueva...
netsh advfirewall firewall add rule name="FCEA-PocketBase-8090" dir=in action=allow protocol=TCP localport=8090 >nul
if errorlevel 1 (
  echo [AVISO] No se pudo crear la regla. Ejecute esta utilidad como administrador.
)

echo Iniciando PocketBase...
cd /d "%REPO_DEST%\pocketbase"
start "FCEA - PocketBase" /MIN cmd /c start-server.bat

echo.
echo [OK] PocketBase relanzado.
endlocal
