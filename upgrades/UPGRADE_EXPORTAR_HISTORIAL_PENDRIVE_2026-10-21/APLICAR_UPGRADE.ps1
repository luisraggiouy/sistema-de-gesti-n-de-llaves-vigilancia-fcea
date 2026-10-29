# =============================================================
# APLICAR_UPGRADE.ps1  (EXPORTAR INFORME VISOR OFFLINE - Dashboard)
# Fecha: 2026-10-21
#
# QUE CAMBIA:
#   En el Dashboard, boton "Exportar a Pendrive", ahora se genera UN
#   archivo .html AUTOCONTENIDO que, al abrirlo en la PC de la autoridad
#   (sin internet ni servidor), muestra EXACTAMENTE lo mismo que el
#   Monitor: el Dashboard (KPIs, graficos, periodos hoy/mensual/semestral,
#   desempeno por vigilante, objetos) y el Buscador Historico de Llaves
#   (con filtro por rango de fechas y NOTAS). La autoridad NO elige nada
#   al grabar: filtra despues en su PC.
#
# NO toca PocketBase. NO borra datos. NO cambia config.json.
# Solo reemplaza el frontend compilado (dist).
#
# ============================================================
#   IMPORTANTISIMO: APLICAR EN LAS 3 PC
#   (Monitor, Terminal A y Terminal B). Ejecutar UNA vez en cada
#   PC y recargar el kiosko con Ctrl+F5.
# ============================================================
#
# ROLLBACK: usar 2-DESHACER_ROLLBACK.bat (restaura el ultimo backup SANO).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Exportar Informe Visor Offline - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE: Exportar Informe (visor offline) desde el Dashboard" -ForegroundColor Yellow
Write-Host "  PC: $env:COMPUTERNAME   Fecha: $STAMP" -ForegroundColor Yellow
Write-Host "  APLICAR EN LAS 3 PC (Monitor, Terminal A y Terminal B)" -ForegroundColor Yellow
Line

if (-not (Test-Path $INSTALL)) {
    Write-Host "  [ERROR] No existe $INSTALL en esta PC." -ForegroundColor Red
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
if (-not (Test-Path (Join-Path $DIST_SRC 'index.html'))) {
    Write-Host "  [ERROR] No se encuentra el dist nuevo junto a este script." -ForegroundColor Red
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

if (Test-Path $DIST_DEST) {
    Write-Host "  [1/2] Respaldando dist actual -> $BACKUP" -ForegroundColor Cyan
    robocopy $DIST_DEST $BACKUP /E /NFL /NDL /NJH /NJS /NP | Out-Null
    Write-Host "        [OK] Backup creado." -ForegroundColor Green
} else {
    Write-Host "  [1/2] No habia dist previo. Sigo igual." -ForegroundColor Yellow
}

# Regla de oro: EXCLUIR config.json y system_health.json.
Write-Host "  [2/2] Copiando frontend nuevo (preservando config.json)..." -ForegroundColor Cyan
robocopy $DIST_SRC $DIST_DEST /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP | Out-Null
$rc = $LASTEXITCODE
if ($rc -ge 8) {
    Write-Host "        [ERROR] robocopy devolvio codigo $rc." -ForegroundColor Red
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
Write-Host "        [OK] Frontend actualizado." -ForegroundColor Green

Line
Write-Host "  EXITO. Upgrade aplicado en esta PC ($env:COMPUTERNAME)." -ForegroundColor Green
Write-Host "  En el kiosko, recarga con Ctrl+F5 (no hace falta cerrar el navegador)." -ForegroundColor Green
Write-Host "  QUE PROBAR (en el Dashboard, desde la cabina):" -ForegroundColor Green
Write-Host "   - 'Exportar a Pendrive' -> contrasena -> Exportar. Se guarda un .html." -ForegroundColor Green
Write-Host "   - Abrir ese .html (doble clic): debe verse el Dashboard con graficos" -ForegroundColor Green
Write-Host "     y un boton 'Buscador Historico de Llaves' con rango de fechas y notas." -ForegroundColor Green
Write-Host "  ACORDATE: aplicar TAMBIEN en Terminal A y Terminal B." -ForegroundColor Yellow
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
