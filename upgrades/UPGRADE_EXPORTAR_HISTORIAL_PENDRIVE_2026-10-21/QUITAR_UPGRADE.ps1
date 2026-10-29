# =============================================================
# QUITAR_UPGRADE.ps1  (ROLLBACK - Exportar Informe Visor Offline)
# Restaura el ULTIMO backup dist_backup_* SANO. Misma PC.
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'ROLLBACK Upgrade Exportar Informe - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }
Line
Write-Host "  ROLLBACK del upgrade (restaurar dist anterior SANO)" -ForegroundColor Yellow
Line

$backups = Get-ChildItem -Path $INSTALL -Directory -Filter 'dist_backup_*' -ErrorAction SilentlyContinue |
           Sort-Object Name -Descending
if (-not $backups) {
    Write-Host "  [ERROR] No se encontro ningun dist_backup_* en $INSTALL." -ForegroundColor Red
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

function Test-DistSano {
    param([string]$dir)
    $idx = Join-Path $dir 'index.html'
    if (-not (Test-Path $idx)) { return $false }
    $html = Get-Content $idx -Raw -ErrorAction SilentlyContinue
    $m = [regex]::Match($html, 'assets/(index-[A-Za-z0-9_-]+\.js)')
    if (-not $m.Success) { return $false }
    return (Test-Path (Join-Path $dir ('assets\' + $m.Groups[1].Value)))
}

$backup = $null
Write-Host "  Buscando el backup SANO mas reciente..." -ForegroundColor Cyan
foreach ($b in $backups) {
    if (Test-DistSano $b.FullName) { $backup = $b; Write-Host "    [OK] Sano: $($b.Name)" -ForegroundColor Green; break }
    else { Write-Host "    [x]  Descartado (roto): $($b.Name)" -ForegroundColor DarkYellow }
}
if (-not $backup) {
    Write-Host "  [ERROR] Ningun dist_backup_* esta sano. Usa el pendrive de RESCATE." -ForegroundColor Red
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

Write-Host "  Restaurando: $($backup.FullName)" -ForegroundColor Cyan
robocopy $backup.FullName $DIST_DEST /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Host "  [ERROR] robocopy devolvio codigo $LASTEXITCODE." -ForegroundColor Red
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
Line
Write-Host "  [OK] dist restaurado. Recarga el kiosko con Ctrl+F5." -ForegroundColor Green
Line
Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
