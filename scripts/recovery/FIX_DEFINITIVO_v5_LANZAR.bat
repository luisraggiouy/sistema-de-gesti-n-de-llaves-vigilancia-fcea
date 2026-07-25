@echo off
REM ============================================================================
REM FIX_DEFINITIVO_v5_LANZAR.bat
REM ----------------------------------------------------------------------------
REM Este .bat pide elevacion UAC y lanza FIX_DEFINITIVO_v5.ps1 con permisos
REM de administrador (necesario para matar el pocketbase.exe zombi lanzado
REM por la tarea programada elevada, y para deshabilitar/rehabilitar la
REM propia tarea).
REM
REM USO: doble clic. Windows va a mostrar el prompt UAC azul preguntando si
REM permitis que esta app haga cambios. Aceptar. La ventana negra que aparece
REM despues es el .ps1 corriendo elevado.
REM
REM Requiere que 1779500000_force_open_rules.js este en la misma carpeta.
REM ============================================================================

setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%FIX_DEFINITIVO_v5.ps1"

if not exist "%PS_SCRIPT%" (
  echo ERROR: no se encontro %PS_SCRIPT%
  echo Este .bat debe estar en la misma carpeta que FIX_DEFINITIVO_v5.ps1
  pause
  exit /b 1
)

echo.
echo ============================================================================
echo  Lanzando FIX_DEFINITIVO_v5.ps1 con permisos de administrador...
echo  Windows va a preguntar (UAC). Acepta con Si.
echo ============================================================================
echo.

REM PowerShell.exe -Command con Start-Process -Verb RunAs dispara UAC.
REM -ExecutionPolicy Bypass permite correr el .ps1 aunque la politica sea
REM Restricted (kioskos con GPO). El -NoExit deja la ventana abierta al
REM terminar para que puedas leer el resultado.
powershell.exe -NoProfile -Command "Start-Process powershell.exe -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-File','\"%PS_SCRIPT%\"' -Verb RunAs"

echo.
echo Si aceptaste UAC, la ventana elevada esta trabajando en paralelo.
echo Esta ventana ya podes cerrarla.
echo.
pause
endlocal
