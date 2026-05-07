@echo off
echo ===================================================
echo REINICIANDO FRONTEND - Sistema de Llaves FCEA
echo ===================================================
echo.

REM Verificar si ya somos administrador
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Solicitando permisos de administrador...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo [OK] Ejecutando con permisos de administrador
echo.
echo [1/3] Deteniendo proceso node.exe (frontend Vite)...
taskkill /F /IM node.exe /T >nul 2>&1
echo [OK] Proceso detenido
echo.

echo [2/3] Esperando 3 segundos...
timeout /t 3 /nobreak >nul

echo [3/3] Iniciando frontend nuevamente...
cd /d "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
start "Frontend FCEA" /MIN cmd /c "npm run dev"

echo.
echo Esperando que el servidor arranque (15 segundos)...
timeout /t 15 /nobreak >nul

echo.
echo ===================================================
echo FRONTEND REINICIADO - Abriendo Chrome...
echo ===================================================
echo.

REM Abrir Chrome con las dos pestanas
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --new-window "http://localhost:8080/terminal" "http://localhost:8080/monitor" 2>nul
if %ERRORLEVEL% NEQ 0 (
    start "" "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --new-window "http://localhost:8080/terminal" "http://localhost:8080/monitor" 2>nul
)

echo Listo. El sistema deberia estar funcionando en Chrome.
echo.
pause
