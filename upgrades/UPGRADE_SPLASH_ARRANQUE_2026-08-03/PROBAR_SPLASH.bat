@echo off
REM ============================================================
REM  PROBAR_SPLASH.bat  -  Muestra el cartel de espera AHORA
REM  (para verlo antes de instalarlo). NO instala nada.
REM  Como en esta PC de prueba no hay PocketBase en 8090, el
REM  cartel girara indefinidamente: cerralo con la tecla ESC.
REM ============================================================
cd /d "%~dp0"
echo.
echo  Mostrando el cartel de espera de prueba...
echo  (Cerralo con ESC cuando quieras)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0splash_arranque.ps1" -MaxSeconds 120
