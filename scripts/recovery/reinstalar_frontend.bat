@echo off
REM Reinstalar dependencias y reconstruir frontend
setlocal

echo === Reinstalando frontend ===
set /p REPO_DEST="Ruta de la instalacion: "
if not exist "%REPO_DEST%\package.json" (
  echo [ERROR] No es un repo valido: %REPO_DEST%
  exit /b 1
)

cd /d "%REPO_DEST%"
echo Limpiando node_modules y dist...
rmdir /s /q node_modules 2>nul
rmdir /s /q dist 2>nul

echo npm install...
call npm install --no-audit --no-fund
if errorlevel 1 (
  echo [ERROR] Fallo npm install.
  exit /b 1
)

echo npm run build...
call npm run build
if errorlevel 1 (
  echo [ERROR] Fallo el build.
  exit /b 1
)

echo [OK] Frontend reinstalado.
endlocal
