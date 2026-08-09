@echo off
setlocal
set "AQUI=%~dp0"
echo ============================================================
echo   RECOLECTAR LOGS DEL ORQUESTADOR FCEA  (SOLO LECTURA)
echo ============================================================
echo   Trae al pendrive los logs con timestamps del arranque
echo   para ver donde se van los ~7-8 minutos. No modifica nada.
echo ============================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%AQUI%RECOLECTAR_LOGS_ORQUESTADOR.ps1" -OutDir "%AQUI%_RESULTADOS"
echo.
echo Listo. Revise la carpeta _RESULTADOS del pendrive y traigala de vuelta.
pause
