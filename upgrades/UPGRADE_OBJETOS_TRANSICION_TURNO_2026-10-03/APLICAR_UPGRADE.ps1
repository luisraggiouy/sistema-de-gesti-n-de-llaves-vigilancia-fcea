# =============================================================
# APLICAR_UPGRADE.ps1  (OBJETOS OLVIDADOS - TRANSICION DE TURNO)
# Fecha: 2026-10-03
#
# QUE CAMBIA:
#   En "Objetos Olvidados" (registrar objeto y devolver objeto), el
#   desplegable de vigilante mostraba SOLO el turno actual. Ahora usa la
#   MISMA logica de transicion de turno que la entrega/devolucion de
#   llaves: durante la ventana de transicion (30 min configurable + la
#   ventana fija de las 05:50) aparecen TAMBIEN los vigilantes del turno
#   anterior.
#
# NO toca PocketBase. NO borra datos. NO instala nada nuevo.
# Solo reemplaza el frontend compilado (dist).
#
# ============================================================
#   IMPORTANTISIMO: APLICAR EN LAS 3 PC
#   (Monitor de Vigilancia, Terminal A y Terminal B)
#   Ejecutar este mismo script UNA vez en cada PC y reabrir el kiosko.
#   El frontend NO se sirve centralizado: cada PC corre su propio
#   'vite preview' sobre el dist de su PROPIO disco.
# ============================================================
#
# ROLLBACK: usar 2-DESHACER_ROLLBACK.bat (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Objetos Transicion Turno - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE Objetos Olvidados: transicion de turno en vigilante" -ForegroundColor Yellow
Write-Host "  PC: $env:COMPUTERNAME   Fecha: $STAMP" -ForegroundColor Yellow
Write-Host "  APLICAR EN LAS 3 PC (Monitor, Terminal A y Terminal B)" -ForegroundColor Yellow
Line

if (-not (Test-Path $INSTALL)) {
    Write-Host "  [ERROR] No existe $INSTALL en esta PC." -ForegroundColor Red
    Write-Host "  Este paquete va en las 3 PC (Monitor, Terminal A y Terminal B)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
if (-not (Test-Path (Join-Path $DIST_SRC 'index.html'))) {
    Write-Host "  [ERROR] No se encuentra el dist nuevo junto a este script:" -ForegroundColor Red
    Write-Host "          $DIST_SRC\index.html" -ForegroundColor Red
    Write-Host "  Grabaste la carpeta COMPLETA del paquete en el pendrive?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

if (Test-Path $DIST_DEST) {
    Write-Host "  [1/2] Respaldando dist actual ->" -ForegroundColor Cyan
    Write-Host "        $BACKUP" -ForegroundColor Gray
    robocopy $DIST_DEST $BACKUP /E /NFL /NDL /NJH /NJS /NP | Out-Null
    Write-Host "        [OK] Backup creado." -ForegroundColor Green
} else {
    Write-Host "  [1/2] No habia dist previo (instalacion nueva?). Sigo igual." -ForegroundColor Yellow
}

# Regla de oro: EXCLUIR config.json y system_health.json para NO pisar
# la config de red/runtime de esta PC.
Write-Host "  [2/2] Copiando frontend nuevo (preservando config.json) ->" -ForegroundColor Cyan
Write-Host "        $DIST_DEST" -ForegroundColor Gray
robocopy $DIST_SRC $DIST_DEST /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP | Out-Null

$rc = $LASTEXITCODE
if ($rc -ge 8) {
    Write-Host "        [ERROR] robocopy devolvio codigo $rc. Reviso permisos." -ForegroundColor Red
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
Write-Host "        [OK] Frontend actualizado." -ForegroundColor Green

Line
Write-Host "  EXITO. Upgrade aplicado en esta PC ($env:COMPUTERNAME)." -ForegroundColor Green
Write-Host "  Cerra el navegador/kiosko y volvelo a abrir (Ctrl+F5 si hace falta)." -ForegroundColor Green
Write-Host "  QUE PROBAR: abrir Objetos Olvidados durante la transicion de turno;" -ForegroundColor Green
Write-Host "   el desplegable de vigilante debe mostrar ambos turnos. Fuera de la" -ForegroundColor Green
Write-Host "   transicion, solo el turno actual." -ForegroundColor Green
Write-Host "  ACORDATE: aplicar TAMBIEN en Terminal A y Terminal B." -ForegroundColor Yellow
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
