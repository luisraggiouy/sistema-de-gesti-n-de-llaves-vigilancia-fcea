@echo off
REM Configura logs.maxDays=7 en PocketBase (robusto, con reintentos).
REM Correr en el MONITOR, con PocketBase prendido. Se auto-eleva a admin.
cd /d "%~dp0"
net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0CONFIGURAR_MAXDAYS.ps1"
