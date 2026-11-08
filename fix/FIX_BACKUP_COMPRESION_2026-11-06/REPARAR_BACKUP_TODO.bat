@echo off
REM ============================================================
REM  REPARAR BACKUP - TODO EN UNO  (FCEA)
REM  Correr en el MONITOR. Se auto-eleva a administrador.
REM  Hace: limpiar 81 GB de backups crudos + instalar fix +
REM        backup real inmediato + verificar. Log al pendrive.
REM ============================================================
cd /d "%~dp0"

REM --- auto-elevacion a administrador ---
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Solicitando permisos de administrador...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo ============================================================
echo  REPARAR BACKUP - TODO EN UNO
echo  Esto va a:
echo    1) Comprimir el backup mas reciente a .zip y BORRAR las
echo       demas carpetas crudas (libera ~77 GB). NO toca pb_data.
echo    2) Instalar el backup corregido.
echo    3) Correr un backup real y verificar.
echo ============================================================
set /p RESP="Escribi SI y ENTER para continuar: "
if /i not "%RESP%"=="SI" goto :cancel

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0REPARAR_BACKUP_TODO.ps1"
goto :eof

:cancel
echo Cancelado. No se toco nada.
pause
