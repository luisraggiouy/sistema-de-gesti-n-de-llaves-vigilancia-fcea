# =============================================================
# QUITAR_UPGRADE.ps1  (ROLLBACK)
# UPGRADE: "Lista de Llaves Colapsable (aparece al buscar)"
# Fecha: 2026-08-09
#
# QUE HACE:
#   Restaura el ULTIMO backup del dist (dist_backup_<fecha_hora>)
#   que dejo el script APLICAR_UPGRADE.ps1.
#
# NO toca PocketBase. NO borra datos.
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'ROLLBACK Lista Llaves Colapsable - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  ROLLBACK: Lista de Llaves Colapsable" -ForegroundColor Yellow
Write-Host "  PC: $env:COMPUTERNAME" -ForegroundColor Yellow
Line

if (-not (Test-Path $INSTALL)) {
    Write-Host "  [ERROR] No existe $INSTALL en esta PC." -ForegroundColor Red
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

# Buscar el backup mas reciente
$backup = Get-ChildItem -Path $INSTALL -Directory -Filter 'dist_backup_*' |
          Sort-Object Name -Descending | Select-Object -First 1

if (-not $backup) {
    Write-Host "  [ERROR] No se encontro ningun 'dist_backup_*' para restaurar." -ForegroundColor Red
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

Write-Host "  Restaurando backup (preservando config.json):" -ForegroundColor Cyan
Write-Host "        $($backup.FullName)" -ForegroundColor Gray
robocopy $backup.FullName $DIST_DEST /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP | Out-Null

$rc = $LASTEXITCODE
if ($rc -ge 8) {
    Write-Host "  [ERROR] robocopy devolvio codigo $rc. Reviso permisos." -ForegroundColor Red
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

Line
Write-Host "  [OK] dist restaurado desde el backup." -ForegroundColor Green
Write-Host "  Cerra y abri el navegador de nuevo (Ctrl+F5)." -ForegroundColor Green
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
