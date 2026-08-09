@echo off
setlocal
title Sistema FCEA - Reparar Rol Config
:: Auto-elevar a Administrador (por si config.json tiene solo-lectura)
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Solicitando permisos de Administrador...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
set "SCRIPT=%~dp0REPARAR_ROL_CONFIG.ps1"
if not exist "%SCRIPT%" (
  echo [ERROR] No se encontro REPARAR_ROL_CONFIG.ps1 en %~dp0
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
endlocal
