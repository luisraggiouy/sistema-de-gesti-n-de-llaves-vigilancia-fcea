@echo off
echo ========================================
echo INICIANDO FRONTEND - Sistema FCEA
echo ========================================
echo.

cd /d "%~dp0"

echo Iniciando servidor de desarrollo Vite...
echo Puerto: 8080
echo.

npm run dev

pause
