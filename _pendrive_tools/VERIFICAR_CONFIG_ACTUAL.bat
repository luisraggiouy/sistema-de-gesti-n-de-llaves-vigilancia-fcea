@echo off
REM Launcher para VERIFICAR_CONFIG_ACTUAL.ps1
setlocal
set "PS1=%~dp0VERIFICAR_CONFIG_ACTUAL.ps1"
if not exist "%PS1%" (
  echo [ERROR] No se encuentra %PS1%
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
endlocal
