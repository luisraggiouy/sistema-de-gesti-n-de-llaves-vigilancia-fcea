@echo off
REM ============================================================
REM  APLICAR_FIX_KIOSK  -  Fix 404 del kiosko (2026-07-31)
REM ------------------------------------------------------------
REM  Copia las versiones corregidas de:
REM    - scripts\lib\lanzar_navegador.ps1
REM    - scripts\lib\abrir_llaves_kiosk.bat
REM  dentro de C:\sistema-llaves-fcea, haciendo BACKUP con
REM  timestamp de las versiones actuales. Tambien actualiza el
REM  icono del Escritorio publico y relanza el kiosko para probar.
REM
REM  Ejecutar en: la PC afectada (Terminal B).
REM  Doble click (pedira permisos de administrador).
REM ============================================================

REM --- Auto-elevar a administrador ---
net session >nul 2>&1
if not "%errorlevel%"=="0" (
  echo Solicitando permisos de administrador...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

setlocal EnableDelayedExpansion
title APLICAR FIX KIOSK - FCEA

set "SRC=%~dp0"
set "INSTALL_DIR=C:\sistema-llaves-fcea"
set "LIB=%INSTALL_DIR%\scripts\lib"
for /f "tokens=1-3 delims=/ " %%a in ("%date%") do set "FECHA=%%c-%%b-%%a"
set "HORA=%time: =0%"
set "HORA=%HORA::=%"
set "HORA=%HORA:.=%"
set "STAMP=%FECHA%_%HORA:~0,6%"

echo.
echo  ============================================================
echo   APLICAR FIX KIOSK  (404 -> frontend local 5173)
echo  ============================================================
echo   Origen (pendrive): %SRC%
echo   Destino          : %LIB%
echo   Backup timestamp : %STAMP%
echo  ============================================================
echo.

if not exist "%LIB%" (
  echo   [ERROR] No existe %LIB%
  echo           El sistema no parece instalado en %INSTALL_DIR%.
  pause
  exit /b 1
)

REM --- Backups ---
echo [1/4] Backup de archivos actuales...
if exist "%LIB%\lanzar_navegador.ps1" copy /y "%LIB%\lanzar_navegador.ps1" "%LIB%\lanzar_navegador.ps1.bak_%STAMP%" >nul
if exist "%LIB%\abrir_llaves_kiosk.bat" copy /y "%LIB%\abrir_llaves_kiosk.bat" "%LIB%\abrir_llaves_kiosk.bat.bak_%STAMP%" >nul
echo       OK (archivos .bak_%STAMP%)

REM --- Copiar versiones corregidas ---
echo [2/4] Copiando versiones corregidas...
copy /y "%SRC%lanzar_navegador.ps1" "%LIB%\lanzar_navegador.ps1" >nul
if errorlevel 1 ( echo   [ERROR] No se pudo copiar lanzar_navegador.ps1 & pause & exit /b 1 )
copy /y "%SRC%abrir_llaves_kiosk.bat" "%LIB%\abrir_llaves_kiosk.bat" >nul
if errorlevel 1 ( echo   [ERROR] No se pudo copiar abrir_llaves_kiosk.bat & pause & exit /b 1 )
echo       OK

REM --- Actualizar icono del Escritorio publico ---
echo [3/4] Actualizando icono del escritorio...
set "DST_ICON=%PUBLIC%\Desktop\abrir llaves FCEA modo kiosk.bat"
copy /y "%SRC%abrir_llaves_kiosk.bat" "%DST_ICON%" >nul 2>&1
if exist "%DST_ICON%" (echo       OK - %DST_ICON%) else (echo       [AVISO] No se pudo actualizar el icono publico. No es critico.)

REM --- Relanzar kiosko para probar ---
echo [4/4] Relanzando el kiosko para probar...
echo.
start "" "%LIB%\abrir_llaves_kiosk.bat"

echo.
echo  ============================================================
echo   FIX APLICADO.
echo   Debe abrir el navegador en modo kiosk mostrando la
echo   Terminal (identificarse / buscar llaves), NO el 404.
echo.
echo   Si algo sale mal, los backups quedaron en:
echo     %LIB%\*.bak_%STAMP%
echo  ============================================================
echo.
pause
endlocal
exit /b 0
