@echo off
echo ===================================================
echo ACTUALIZANDO TAREA DE INICIO AUTOMATICO
echo Sistema de Gestion de Llaves FCEA
echo ===================================================
echo.
echo Este script requiere permisos de administrador.
echo Se solicitara elevacion de permisos...
echo.

REM Verificar si ya somos administrador
net session >nul 2>&1
if %errorlevel% == 0 (
    goto :run_as_admin
)

REM Relanzar como administrador
echo Solicitando permisos de administrador...
powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:run_as_admin
echo [OK] Ejecutando con permisos de administrador
echo.
echo Actualizando tarea programada con delay de 30 segundos...
powershell -ExecutionPolicy Bypass -File "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\actualizar_tarea_30s.ps1"

echo.
echo ===================================================
echo TAREA ACTUALIZADA CORRECTAMENTE
echo ===================================================
echo.
echo La tarea SistemaLlavesFCEA ahora tiene:
echo   - Delay de 30 segundos al iniciar sesion
echo   - Abre Chrome con Terminal y Monitor
echo   - Watchdog mejorado (no mata node si puerto 8080 activo)
echo.
pause
