@echo off
REM ============================================================
REM  scripts\lib\run_frontend.bat
REM  Wrapper que lanza el servidor frontend de Vite preview con
REM  salida redirigida a archivos.  Se invoca via Task Scheduler
REM  (schtasks) o directamente.
REM ============================================================

cd /d "%~dp0\..\.."

if not exist "logs" mkdir "logs"

REM Loop forever: si el servidor cae, lo relanzamos.
:loop
echo [%date% %time%] Iniciando vite preview... >> logs\frontend.log
node "node_modules\vite\bin\vite.js" preview --port 5173 --host --strictPort >> logs\frontend.log 2>&1 < NUL
echo [%date% %time%] vite preview termino con errorlevel %errorlevel%. Reintentando en 3s... >> logs\frontend.log
timeout /t 3 /nobreak >nul
goto loop
