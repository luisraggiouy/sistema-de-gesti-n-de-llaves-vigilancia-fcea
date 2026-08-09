@echo off
REM ============================================================
REM  REVERTIR FIX ARRANQUE LENTO ORQUESTADOR - 2026-08-09
REM  Restaura el backup mas reciente de iniciar_pocketbase.ps1
REM ============================================================
echo.
echo ==== ROLLBACK FIX ARRANQUE LENTO - MONITOR ====
echo.
pause
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$t='C:\sistema-llaves-fcea\scripts\lib\iniciar_pocketbase.ps1';" ^
  "$b=Get-ChildItem (Split-Path $t) -Filter 'iniciar_pocketbase.ps1.bak_*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1;" ^
  "if(-not $b){Write-Host '[ERROR] No hay backup .bak_ para restaurar.'; exit 1}" ^
  "Copy-Item $b.FullName $t -Force;" ^
  "Write-Host ('[OK] Restaurado desde: ' + $b.FullName);" ^
  "Write-Host 'El orquestador volvio al estado previo al fix. Reinicie el Monitor.'"
echo.
pause
