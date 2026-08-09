@echo off
setlocal
title Sistema FCEA - Diagnostico Forense (solo lectura)
:: Auto-elevar a Administrador (solo lectura, pero algunos datos requieren admin)
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Solicitando permisos de Administrador...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
set "SCRIPT=%~dp0DIAGNOSTICO_FORENSE.ps1"
if not exist "%SCRIPT%" (
  echo [ERROR] No se encontro DIAGNOSTICO_FORENSE.ps1 en %~dp0
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
endlocal
