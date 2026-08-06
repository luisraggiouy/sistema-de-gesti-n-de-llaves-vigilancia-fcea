@echo off
REM ============================================================
REM  QUITAR_UPGRADE.bat  -  ROLLBACK del Splash de Arranque FCEA
REM  Borra el acceso directo de Inicio y la carpeta splash.
REM  Deja el arranque EXACTAMENTE como estaba antes.
REM ============================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'FCEA_Splash_Arranque.lnk';" ^
  "if (Test-Path $lnk) { Remove-Item $lnk -Force; Write-Host '  [OK] Quitado acceso directo de Inicio.' -ForegroundColor Green } else { Write-Host '  (no habia acceso directo)' };" ^
  "$d = 'C:\sistema-llaves-fcea\scripts\lib\splash';" ^
  "if (Test-Path $d) { Remove-Item $d -Recurse -Force; Write-Host '  [OK] Quitada carpeta splash.' -ForegroundColor Green } else { Write-Host '  (no habia carpeta splash)' };" ^
  "Write-Host ''; Write-Host 'Rollback completo: el arranque quedo como antes.' -ForegroundColor Cyan"
echo.
pause
