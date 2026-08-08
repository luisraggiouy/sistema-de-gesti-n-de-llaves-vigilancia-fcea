# =============================================================
# QUITAR_UPGRADE.ps1  (ROLLBACK del frontend)
# UPGRADE: "Cartel 'Intercambio de llave' en Llaves en Uso"
# Fecha: 2026-08-07
#
# QUE HACE:
#   Restaura el ULTIMO backup del dist (dist_backup_<fecha_hora>)
#   que dejo el script APLICAR_UPGRADE.ps1.
#
# NO toca PocketBase. NO borra datos.
# NOTA: los campos que se agregaron a 'solicitudes' (es_intercambio y
#   usuario_anterior_*) NO se quitan: son inofensivos y no molestan aunque
#   se vuelva al dist viejo. Si hiciera falta quitarlos, avisar a Cline.
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'ROLLBACK Cartel Intercambio de Llave - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  ROLLBACK: Cartel 'Intercambio de llave' en Llaves en Uso" -ForegroundColor Yellow
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
