@echo off
echo ========================================
echo INICIANDO SISTEMA DE LLAVES FCEA
echo ========================================
echo.

cd /d "%~dp0"

echo Verificando si PocketBase ya esta corriendo...
tasklist | findstr "pocketbase.exe" >nul
if %errorlevel% equ 0 (
    echo [OK] PocketBase ya esta corriendo
    goto :frontend
)

echo Iniciando servidor PocketBase...
start /min "" cmd /c "pocketbase\pocketbase.exe serve --http=127.0.0.1:8090"

timeout /t 3 /nobreak >nul

echo [OK] Servidor iniciado

:frontend
echo.
echo Iniciando interfaz web (frontend)...
start "" npm run dev

timeout /t 5 /nobreak >nul

echo Abriendo navegador...
start "" "http://localhost:8080/monitor"

echo.
echo ========================================
echo SISTEMA INICIADO CORRECTAMENTE
echo ========================================
echo.
echo El navegador se abrira automaticamente
echo Presione cualquier tecla para cerrar esta ventana...
pause >nul
