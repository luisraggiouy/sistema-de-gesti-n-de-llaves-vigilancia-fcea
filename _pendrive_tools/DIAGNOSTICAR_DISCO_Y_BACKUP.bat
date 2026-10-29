@echo off
REM ============================================================
REM  DIAGNOSTICO DISCO Y BACKUP (solo lectura) - FCEA
REM  Correr en el MONITOR (PC servidor). No modifica nada.
REM  Deja un log DIAGNOSTICO_DISCO_<fecha>.txt en esta carpeta
REM  del pendrive para traerlo a la laptop.
REM ============================================================
net session >nul 2>&1
if errorlevel 1 (
  echo  Solicitando permisos de Administrador...
  powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/k','\"%~f0\"' -Verb RunAs"
  exit /b
)
pushd "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0DIAGNOSTICO_DISCO_Y_BACKUP.ps1"
