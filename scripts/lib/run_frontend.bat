@echo off
REM ============================================================
REM  scripts\lib\run_frontend.bat
REM  Wrapper que lanza el servidor frontend de Vite preview con
REM  salida redirigida a archivos.  Se invoca via Task Scheduler
REM  (schtasks) o directamente.
REM ============================================================

cd /d "%~dp0\..\.."

REM ------------------------------------------------------------
REM  Asegurar que 'node' este en el PATH.
REM  En un piloto offline sin Node.js instalado, esperamos
REM  encontrarlo en:
REM    1) C:\sistema-llaves-fcea\node-portable\node\node.exe
REM       (copiado desde el pendrive durante la instalacion)
REM    2) FCEA_PENDRIVE_ROOT\node-portable\node\node.exe
REM       (solo si el pendrive sigue enchufado)
REM    3) node.exe en el PATH del sistema
REM ------------------------------------------------------------
set "NODE_LOCAL=%~dp0..\..\node-portable\node"
if exist "%NODE_LOCAL%\node.exe" (
  set "PATH=%NODE_LOCAL%;%PATH%"
) else (
  if defined FCEA_PENDRIVE_ROOT (
    if exist "%FCEA_PENDRIVE_ROOT%\node-portable\node\node.exe" (
      set "PATH=%FCEA_PENDRIVE_ROOT%\node-portable\node;%PATH%"
    )
  )
)

if not exist "logs" mkdir "logs"

REM Verificar que 'node' responde antes de entrar al loop.
where node >nul 2>nul
if errorlevel 1 (
  echo [%date% %time%] [ERROR] node.exe no encontrado en el PATH ni en node-portable\. >> logs\frontend.log
  echo [%date% %time%]         Revisar que C:\sistema-llaves-fcea\node-portable\node\node.exe exista. >> logs\frontend.log
  echo.
  echo  [ERROR] node.exe no encontrado.
  echo          Se esperaba en: %NODE_LOCAL%\node.exe
  echo          Solucion: copiar la carpeta node-portable\ del pendrive a
  echo                    C:\sistema-llaves-fcea\node-portable\
  echo.
  pause
  exit /b 1
)

REM Loop forever: si el servidor cae, lo relanzamos.
:loop
echo [%date% %time%] Iniciando vite preview... >> logs\frontend.log
node "node_modules\vite\bin\vite.js" preview --port 5173 --host --strictPort >> logs\frontend.log 2>&1 < NUL
echo [%date% %time%] vite preview termino con errorlevel %errorlevel%. Reintentando en 3s... >> logs\frontend.log
timeout /t 3 /nobreak >nul
goto loop
