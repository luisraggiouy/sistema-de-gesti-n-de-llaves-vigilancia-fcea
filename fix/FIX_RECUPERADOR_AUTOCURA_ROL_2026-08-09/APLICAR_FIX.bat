@echo off
setlocal
title FIX Recuperador Autocura Rol - Sistema FCEA
:: Auto-elevar a Administrador (necesario para escribir en C:\sistema-llaves-fcea)
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Solicitando permisos de Administrador...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
set "SCRIPT=%~dp0APLICAR_FIX.ps1"
if not exist "%SCRIPT%" (
  echo [ERROR] No se encontro APLICAR_FIX.ps1 en %~dp0
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
endlocal
