@echo off
REM ============================================================
REM  scripts\lib\run_pocketbase.bat  (FIX RAIZ readonly 2026-08-02)
REM ------------------------------------------------------------
REM  Higiene: borra la base de LOGS descartable (logs.db) en cada
REM  arranque para que no se infle ni quede con WAL colgado.
REM  NO toca data.db.  Ruta persistente de datos:
REM    C:\ProgramData\FCEA-Sistema-Llaves\pb_data
REM ============================================================

cd /d "%~dp0\..\..\pocketbase"

if not exist "..\logs" mkdir "..\logs"

set "PB_DATA_DIR=C:\ProgramData\FCEA-Sistema-Llaves\pb_data"
if not exist "%PB_DATA_DIR%" mkdir "%PB_DATA_DIR%"

:loop
del /f /q "%PB_DATA_DIR%\logs.db"     2>nul
del /f /q "%PB_DATA_DIR%\logs.db-wal" 2>nul
del /f /q "%PB_DATA_DIR%\logs.db-shm" 2>nul

echo [%date% %time%] Iniciando pocketbase con --dir=%PB_DATA_DIR% ... >> ..\logs\pocketbase.log
pocketbase.exe serve --http=0.0.0.0:8090 --dir="%PB_DATA_DIR%" --migrationsDir=pb_migrations >> ..\logs\pocketbase.log 2>&1 < NUL
echo [%date% %time%] pocketbase termino con errorlevel %errorlevel%. Reintentando en 3s... >> ..\logs\pocketbase.log
timeout /t 3 /nobreak >nul
goto loop
