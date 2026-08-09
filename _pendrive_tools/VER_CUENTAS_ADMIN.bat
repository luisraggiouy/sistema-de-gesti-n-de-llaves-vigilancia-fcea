@echo off
setlocal EnableDelayedExpansion
title Sistema FCEA - Ver cuentas y administradores (solo lectura)
:: NO pide permisos de admin. Solo lee y guarda un log en el pendrive.

set "OUTDIR=%~dp0_RESULTADOS"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
set "LOG=%OUTDIR%\LOG_CUENTAS_%COMPUTERNAME%.log"

echo ============================================================ > "%LOG%"
echo  VER CUENTAS Y ADMINISTRADORES  - %COMPUTERNAME% >> "%LOG%"
echo  Fecha: %DATE% %TIME% >> "%LOG%"
echo  Usuario actual: %USERNAME% >> "%LOG%"
echo ============================================================ >> "%LOG%"
echo. >> "%LOG%"

echo ----- whoami ----- >> "%LOG%"
whoami >> "%LOG%" 2>&1
echo. >> "%LOG%"

echo ----- whoami /groups (busca 'Administradores' / S-1-5-32-544) ----- >> "%LOG%"
whoami /groups >> "%LOG%" 2>&1
echo. >> "%LOG%"

echo ----- Miembros del grupo Administradores (ES) ----- >> "%LOG%"
net localgroup Administradores >> "%LOG%" 2>&1
echo. >> "%LOG%"

echo ----- Miembros del grupo Administrators (EN) ----- >> "%LOG%"
net localgroup Administrators >> "%LOG%" 2>&1
echo. >> "%LOG%"

echo ----- Todas las cuentas locales ----- >> "%LOG%"
net user >> "%LOG%" 2>&1
echo. >> "%LOG%"

echo ----- Detalle de la cuenta actual (%USERNAME%) ----- >> "%LOG%"
net user "%USERNAME%" >> "%LOG%" 2>&1
echo. >> "%LOG%"

echo. 
echo ============================================================
echo  LISTO. Se guardo el resultado en:
echo    %LOG%
echo  Trae ese archivo a la laptop para que Cline lo lea.
echo ============================================================
echo.
pause
endlocal
