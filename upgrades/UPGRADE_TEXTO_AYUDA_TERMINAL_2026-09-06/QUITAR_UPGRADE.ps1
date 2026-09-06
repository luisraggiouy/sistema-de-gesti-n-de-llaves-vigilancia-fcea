# =============================================================
# QUITAR_UPGRADE.ps1  (ROLLBACK)
# Restaura el ULTIMO backup dist_backup_* creado por APLICAR_UPGRADE.
# Upgrade: "Texto de ayuda en pantalla de identificacion" (2026-09-06)
# Terminal A / Terminal B
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'ROLLBACK Texto Ayuda Terminal - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  ROLLBACK del upgrade (restaurar dist anterior)" -ForegroundColor Yellow
Line

$backup = Get-ChildItem -Path $INSTALL -Directory -Filter 'dist_backup_*' -ErrorAction SilentlyContinue |
          Sort-Object Name -Descending | Select-Object -First 1

if (-not $backup) {
    Write-Host "  [ERROR] No se encontro ningun dist_backup_* en $INSTALL." -ForegroundColor Red
    Write-Host "  No hay nada que restaurar." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

Write-Host "  Restaurando: $($backup.FullName)" -ForegroundColor Cyan
robocopy $backup.FullName $DIST_DEST /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
$rc = $LASTEXITCODE
if ($rc -ge 8) {
    Write-Host "  [ERROR] robocopy devolvio codigo $rc." -ForegroundColor Red
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

Line
Write-Host "  [OK] dist restaurado al estado previo al upgrade." -ForegroundColor Green
Write-Host "  Cerra y abri de nuevo el navegador/kiosko (Ctrl+F5)." -ForegroundColor Green
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
