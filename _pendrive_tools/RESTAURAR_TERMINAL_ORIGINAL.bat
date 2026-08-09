@echo off
setlocal
title Sistema FCEA - Restaurar Terminal (Opcion B)
:: Auto-elevar a Administrador (si la UAC esta blindada, pedira la clave actual UNA vez)
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Solicitando permisos de Administrador...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
set "SCRIPT=%~dp0RESTAURAR_TERMINAL_ORIGINAL.ps1"
if not exist "%SCRIPT%" (
  echo [ERROR] No se encontro RESTAURAR_TERMINAL_ORIGINAL.ps1 en %~dp0
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
endlocal
