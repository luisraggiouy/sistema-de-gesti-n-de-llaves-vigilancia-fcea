@echo off
REM ============================================================
REM  Sistema de Gestion de Llaves FCEA v2.0
REM  Menu principal de RECUPERACION
REM ============================================================
setlocal

:MENU
cls
echo.
echo ============================================================
echo  RECUPERACION - Sistema de Llaves FCEA v2.0
echo ============================================================
echo.
echo  [1] Diagnostico del sistema
echo  [2] Restaurar base de datos desde backup del pendrive
echo  [3] Reparar PocketBase (puerto + firewall + servicio)
echo  [4] Reinstalar frontend (npm install + build)
echo  [5] Verificar conectividad de red (ping terminales/servidor)
echo  [0] Salir
echo.
set /p OP="Opcion: "

if "%OP%"=="1" call "%~dp0diagnostico.bat"
if "%OP%"=="2" call "%~dp0restaurar_backup.bat"
if "%OP%"=="3" call "%~dp0reparar_pocketbase.bat"
if "%OP%"=="4" call "%~dp0reinstalar_frontend.bat"
if "%OP%"=="5" call "%~dp0verificar_red.bat"
if "%OP%"=="0" goto FIN

pause
goto MENU

:FIN
echo Bye.
endlocal
