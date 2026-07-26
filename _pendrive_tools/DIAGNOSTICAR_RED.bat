@echo off
setlocal
title Sistema FCEA - Diagnosticar Red
set "SCRIPT=%~dp0DIAGNOSTICAR_RED.ps1"
if not exist "%SCRIPT%" (
  echo [ERROR] No se encontro DIAGNOSTICAR_RED.ps1 en %~dp0
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
endlocal
