# =============================================================
# QUITAR_UPGRADE.ps1  (ROLLBACK)
# UPGRADE: "Realtime de Solicitudes (fix latencia ~2s al pedir llave)"
# Fecha: 2026-11-05
#
# QUE HACE:
#   Restaura el ULTIMO backup del dist (dist_backup_<fecha_hora>) que dejo
#   el script APLICAR_UPGRADE.ps1, preservando config.json y system_health.json.
#
# BLINDAJE (leccion del incidente del fix de scroll):
#   - Antes de restaurar, VERIFICA que el backup elegido tenga index.html.
#     Si el mas reciente estuviera incompleto, prueba con el anterior.
#   - Despues de restaurar, VERIFICA que el dist quedo con index.html.
#   - Deja mensaje claro de Ctrl+F5 (el navegador puede cachear el bundle).
#
# NO toca PocketBase. NO borra datos.
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'ROLLBACK Realtime Solicitudes - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }
function Pausa {
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine()
}

Line
Write-Host "  ROLLBACK: Realtime de Solicitudes" -ForegroundColor Yellow
Write-Host "  PC: $env:COMPUTERNAME" -ForegroundColor Yellow
Line

if (-not (Test-Path $INSTALL)) {
    Write-Host "  [ERROR] No existe $INSTALL en esta PC." -ForegroundColor Red
    Pausa; exit 1
}

# Buscar backups (mas reciente primero) y elegir el primero que tenga index.html.
$backups = Get-ChildItem -Path $INSTALL -Directory -Filter 'dist_backup_*' |
           Sort-Object Name -Descending

if (-not $backups -or $backups.Count -eq 0) {
    Write-Host "  [ERROR] No se encontro ningun 'dist_backup_*' para restaurar." -ForegroundColor Red
    Write-Host "  (El APLICAR_UPGRADE crea uno antes de tocar nada; si no hay," -ForegroundColor Yellow
    Write-Host "   usa el pendrive de RECUPERACION como ultimo recurso.)" -ForegroundColor Yellow
    Pausa; exit 1
}

$backup = $null
foreach ($b in $backups) {
    if (Test-Path (Join-Path $b.FullName 'index.html')) { $backup = $b; break }
}

if (-not $backup) {
    Write-Host "  [ERROR] Hay backups pero ninguno tiene index.html (incompletos)." -ForegroundColor Red
    Write-Host "  Usa el pendrive de RECUPERACION como ultimo recurso." -ForegroundColor Yellow
    Pausa; exit 1
}

Write-Host "  Restaurando backup (preservando config.json):" -ForegroundColor Cyan
Write-Host "        $($backup.FullName)" -ForegroundColor Gray
robocopy $backup.FullName $DIST_DEST /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP | Out-Null
$rc = $LASTEXITCODE
if ($rc -ge 8) {
    Write-Host "  [ERROR] robocopy devolvio codigo $rc. Reviso permisos." -ForegroundColor Red
    Pausa; exit 1
}
if (-not (Test-Path (Join-Path $DIST_DEST 'index.html'))) {
    Write-Host "  [ERROR] Tras restaurar, no hay index.html en el dist." -ForegroundColor Red
    Pausa; exit 1
}

Line
Write-Host "  [OK] dist restaurado desde el backup y verificado." -ForegroundColor Green
Write-Host "  Cerra y abri el navegador de nuevo (Ctrl+F5 para limpiar cache)." -ForegroundColor Green
Line
Pausa
