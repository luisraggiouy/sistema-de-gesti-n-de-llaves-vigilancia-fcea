@echo off
REM Launcher para CAZAR_POCKETBASE_ZOMBIE.ps1 (requiere admin para taskkill)
setlocal
set "PS1=%~dp0CAZAR_POCKETBASE_ZOMBIE.ps1"
if not exist "%PS1%" (
  echo [ERROR] No se encuentra %PS1%
  pause
  exit /b 1
)

REM Elevar a admin si no lo esta (para poder matar procesos)
net session >nul 2>&1
if %errorlevel% NEQ 0 (
  echo Solicitando permisos de administrador...
  powershell -NoProfile -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
  exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
endlocal
