@echo off
setlocal
title Sistema FCEA - Matar PocketBase Zombie
:: Auto-elevar a Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Solicitando permisos de Administrador...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
set "SCRIPT=%~dp0MATAR_POCKETBASE_ZOMBIE.ps1"
if not exist "%SCRIPT%" (
  echo [ERROR] No se encontro MATAR_POCKETBASE_ZOMBIE.ps1 en %~dp0
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
endlocal
