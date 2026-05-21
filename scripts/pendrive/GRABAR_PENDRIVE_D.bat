@echo off
REM ============================================================
REM Grabador del pendrive instalador FCEA en D:
REM ============================================================
REM Doble click (Ejecutar como Administrador) para grabar D: con:
REM   - codigo fuente
REM   - pb_data productivo
REM   - Node.js portable
REM   - INSTALAR.bat / DESINSTALAR.bat / ACTUALIZAR_DATOS.bat
REM ============================================================

REM Verificar privilegios de administrador
net session >nul 2>&1
if errorlevel 1 (
  echo.
  echo  *** ESTE SCRIPT REQUIERE PRIVILEGIOS DE ADMINISTRADOR ***
  echo.
  echo  Cierre esta ventana y vuelva a abrirlo con click DERECHO -^>
  echo  "Ejecutar como administrador".
  echo.
  pause
  exit /b 1
)

echo.
echo ============================================================
echo  Grabando pendrive INSTALADOR FCEA en D:\
echo ============================================================
echo.

REM 0) Suspender watchdog para que no relance PocketBase mientras copiamos
echo [1/3] Suspendiendo watchdog (si existe)...
schtasks /End /TN "FCEA-Watchdog" >nul 2>&1

REM 1) Detener PocketBase para consistencia del backup
echo [2/3] Deteniendo PocketBase...
taskkill /F /IM pocketbase.exe >nul 2>&1
timeout /t 3 /nobreak >nul

REM 2) Ejecutar el grabador
echo [3/3] Ejecutando crear_pendrive.ps1 -Drive D: -Tipo instalador -Force ...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0crear_pendrive.ps1" -Drive D: -Tipo instalador -Force

echo.
echo ============================================================
echo  Verificando contenido del pendrive...
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0verificar_pendrive.ps1" -Drive D:

echo.
echo ============================================================
echo  Proceso terminado. Presione una tecla para cerrar.
echo ============================================================
pause >nul
