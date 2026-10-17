# =============================================================
# QUITAR_FIX.ps1  (ROLLBACK del FIX HISTORIAL LENTO)
# Restaura el ULTIMO backup dist_backup_* creado por APLICAR_FIX.
# Correr en la MISMA PC donde se aplico el fix.
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'ROLLBACK FIX Historial Lento - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  ROLLBACK del FIX historial lento (restaurar dist anterior)" -ForegroundColor Yellow
Line

# ------------------------------------------------------------
# ROLLBACK REFORZADO (05/10/2026).
# PROBLEMA ANTERIOR: el rollback restauraba ciegamente el dist_backup_*
# mas nuevo por nombre. Si el fix roto se aplico 2 veces, el "mas nuevo"
# ya contenia el dist ROTO (pantalla en blanco) -> el rollback no salvaba.
# AHORA: recorre los backups del mas nuevo al mas viejo y restaura el
# PRIMERO que se vea SANO (su index.html referencia un index-*.js que
# existe en su carpeta assets). Asi no restaura un backup corrupto.
# ------------------------------------------------------------
$backups = Get-ChildItem -Path $INSTALL -Directory -Filter 'dist_backup_*' -ErrorAction SilentlyContinue |
           Sort-Object Name -Descending

if (-not $backups) {
    Write-Host "  [ERROR] No se encontro ningun dist_backup_* en $INSTALL." -ForegroundColor Red
    Write-Host "  No hay nada que restaurar." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

function Test-DistSano {
    param([string]$dir)
    $idx = Join-Path $dir 'index.html'
    if (-not (Test-Path $idx)) { return $false }
    $html = Get-Content $idx -Raw -ErrorAction SilentlyContinue
    # Buscar el nombre del bundle JS que referencia el index.html.
    $m = [regex]::Match($html, 'assets/(index-[A-Za-z0-9_-]+\.js)')
    if (-not $m.Success) { return $false }
    $js = Join-Path $dir ('assets\' + $m.Groups[1].Value)
    return (Test-Path $js)   # el JS referenciado debe existir fisicamente
}

$backup = $null
Write-Host "  Buscando el backup SANO mas reciente..." -ForegroundColor Cyan
foreach ($b in $backups) {
    if (Test-DistSano $b.FullName) {
        $backup = $b
        Write-Host "    [OK] Sano: $($b.Name)" -ForegroundColor Green
        break
    } else {
        Write-Host "    [x]  Descartado (dist incompleto/roto): $($b.Name)" -ForegroundColor DarkYellow
    }
}

if (-not $backup) {
    Write-Host "  [ERROR] Ningun dist_backup_* esta sano." -ForegroundColor Red
    Write-Host "  Usa el PENDRIVE DE RESCATE (Recuperar Sistema)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

Write-Host "  Restaurando: $($backup.FullName)" -ForegroundColor Cyan
robocopy $backup.FullName $DIST_DEST /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP | Out-Null
$rc = $LASTEXITCODE
if ($rc -ge 8) {
    Write-Host "  [ERROR] robocopy devolvio codigo $rc." -ForegroundColor Red
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

Line
Write-Host "  [OK] dist restaurado al estado previo al fix." -ForegroundColor Green
Write-Host "  Cerra y abri de nuevo el navegador/kiosko (Ctrl+F5)." -ForegroundColor Green
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
