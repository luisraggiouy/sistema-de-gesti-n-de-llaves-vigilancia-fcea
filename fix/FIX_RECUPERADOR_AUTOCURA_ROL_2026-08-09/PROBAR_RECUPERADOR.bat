@echo off
setlocal
title Probar Recuperador Reforzado - Sistema FCEA
REM ============================================================
REM  1) Ejecuta la copia INSTALADA del recuperador (ya reforzada
REM     por APLICAR_FIX.bat) -> es la misma que usa INICIAR.bat.
REM  2) Al terminar, vuelca el rol y la URL FINALES de los 3
REM     config.json a un .log en el pendrive (_RESULTADOS), para
REM     dejar EVIDENCIA de que la autocura de rol funciono.
REM ============================================================
set "PS1=C:\sistema-llaves-fcea\scripts\lib\reparar_conexion_servidor.ps1"
if not exist "%PS1%" (
  echo.
  echo [ERROR] No existe:
  echo    %PS1%
  echo  Aplica primero APLICAR_FIX.bat, o esta PC no tiene el sistema instalado.
  echo.
  pause
  exit /b 1
)

set "OUTDIR=%~dp0_RESULTADOS"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo.
echo  [1/2] Ejecutando el Recuperador INSTALADO (version reforzada)...
echo        Va a buscar el Monitor y reescribir la config (IP + autocura de rol).
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"

echo.
echo  [2/2] Guardando evidencia del estado FINAL de la config...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$outDir='%OUTDIR%';" ^
  "$stamp=Get-Date -Format 'yyyy-MM-dd_HHmm';" ^
  "$log=Join-Path $outDir ('LOG_PROBAR_RECUPERADOR_{0}_{1}.log' -f $env:COMPUTERNAME,$stamp);" ^
  "$L=@();" ^
  "$L+='=== PRUEBA RECUPERADOR REFORZADO ===';" ^
  "$L+=('PC        : ' + $env:COMPUTERNAME);" ^
  "$L+=('Fecha/Hora: ' + (Get-Date));" ^
  "$L+='';" ^
  "$paths=@('C:\sistema-llaves-fcea\public\config.json','C:\sistema-llaves-fcea\dist\config.json','C:\sistema-llaves-fcea\config\install_config.json');" ^
  "foreach($p in $paths){ if(Test-Path $p){ try{ $c=Get-Content $p -Raw | ConvertFrom-Json; $L+=('--- ' + $p); $L+=('    rol          : ' + $c.rol); $L+=('    pocketbase_url: ' + $c.pocketbase_url); if($c.red){ $L+=('    red.ip_servidor: ' + $c.red.ip_servidor) } }catch{ $L+=('--- ' + $p + '  [ERROR leyendo JSON]') } } else { $L+=('--- ' + $p + '  [NO EXISTE]') }; $L+='' }" ^
  "$L | Set-Content -Path $log -Encoding UTF8;" ^
  "Write-Host '';" ^
  "Write-Host ('  Evidencia guardada en: ' + $log) -ForegroundColor Green;" ^
  "Write-Host '';" ^
  "Get-Content $log | Write-Host"

echo.
echo  LISTO. Trae el pendrive a la laptop; el .log esta en:
echo    %OUTDIR%
echo.
pause
endlocal
