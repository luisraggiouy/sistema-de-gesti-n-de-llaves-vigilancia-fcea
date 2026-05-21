@echo off
REM ============================================================
REM  scripts\lib\run_pocketbase.bat
REM  Wrapper que arranca PocketBase con salida redirigida a archivo
REM  y un watchdog interno: si PocketBase cae, se relanza solo.
REM ============================================================

cd /d "%~dp0\..\..\pocketbase"

if not exist "..\logs" mkdir "..\logs"

:loop
echo [%date% %time%] Iniciando pocketbase... >> ..\logs\pocketbase.log
pocketbase.exe serve --http=0.0.0.0:8090 --dir=pb_data --migrationsDir=pb_migrations >> ..\logs\pocketbase.log 2>&1 < NUL
echo [%date% %time%] pocketbase termino con errorlevel %errorlevel%. Reintentando en 3s... >> ..\logs\pocketbase.log
timeout /t 3 /nobreak >nul
goto loop
