@echo off
REM ============================================================
REM  scripts\lib\run_pocketbase.bat
REM  Wrapper que arranca PocketBase con salida redirigida a archivo
REM  y un watchdog interno: si PocketBase cae, se relanza solo.
REM ============================================================
REM
REM  IMPORTANTE (fix 2026-07-24):
REM    PocketBase SIEMPRE debe usar la carpeta persistente
REM       C:\ProgramData\FCEA-Sistema-Llaves\pb_data
REM    como directorio de datos. Antes usabamos "--dir=pb_data"
REM    (ruta relativa), lo que hacia que PocketBase escribiera en
REM    C:\sistema-llaves-fcea\pocketbase\pb_data\, una carpeta que
REM    el desinstalador borra en cada reinstalacion -> perdida de
REM    datos productivos entre reinstalaciones.
REM
REM    Ahora usamos ruta ABSOLUTA a ProgramData. Esa carpeta:
REM      - Sobrevive a reinstalar/desinstalar.
REM      - Es respaldada explicitamente por el desinstalador.
REM      - Es la fuente de "semilla al pendrive".
REM ============================================================

cd /d "%~dp0\..\..\pocketbase"

if not exist "..\logs" mkdir "..\logs"

REM Asegurar que la carpeta persistente existe (por si nunca corrio el installer)
set "PB_DATA_DIR=C:\ProgramData\FCEA-Sistema-Llaves\pb_data"
if not exist "%PB_DATA_DIR%" mkdir "%PB_DATA_DIR%"

:loop
echo [%date% %time%] Iniciando pocketbase con --dir=%PB_DATA_DIR% ... >> ..\logs\pocketbase.log
pocketbase.exe serve --http=0.0.0.0:8090 --dir="%PB_DATA_DIR%" --migrationsDir=pb_migrations >> ..\logs\pocketbase.log 2>&1 < NUL
echo [%date% %time%] pocketbase termino con errorlevel %errorlevel%. Reintentando en 3s... >> ..\logs\pocketbase.log
timeout /t 3 /nobreak >nul
goto loop
