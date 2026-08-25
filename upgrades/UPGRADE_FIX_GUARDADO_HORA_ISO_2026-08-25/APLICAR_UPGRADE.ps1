# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE (FIX): "Guardado de hora de entrega/devolucion en formato ISO"
# Fecha: 2026-08-25
#
# CORRIGE LA CAUSA DE FONDO del "marcaba 5 horas" tras un F5:
#   El campo hora_entrega/hora_devolucion es TEXTO en la base. Al
#   registrar una entrega/intercambio/devolucion se guardaba un
#   objeto Date "crudo", que quedaba en un formato ambiguo. Al
#   recargar (F5) se releia mal y aparecia un desfase de zona
#   horaria (el contador saltaba a ~5 horas y activaba la alerta /
#   el mensaje de WhatsApp antes de tiempo).
#
#   Ahora las fechas se guardan SIEMPRE como ISO string, que se
#   relee sin ambiguedad. Complementa los fixes previos (lectura
#   normalizada + reinicio del contador en intercambios).
#
# QUE HACE EL SCRIPT:
#   1) Verifica que exista la instalacion oficial y el dist nuevo.
#   2) Respalda el dist actual  ->  dist_backup_<fecha_hora>
#   3) Copia el dist NUEVO (de esta carpeta) sobre la instalacion,
#      PRESERVANDO config.json y system_health.json.
#
# NO toca PocketBase. NO borra datos. Solo reemplaza el frontend (dist).
#
# NOTA: las solicitudes que YA quedaron mal guardadas antes de este
# fix seguiran mostrando su hora torcida. Toda entrega/intercambio/
# devolucion NUEVA queda bien. Para corregir una vieja: devolverla y
# volver a entregarla.
#
# ESTE UPGRADE VA EN: Monitor de Vigilancia (que hace de servidor).
# ROLLBACK: usar 2-DESHACER_ROLLBACK.bat (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Fix Guardado Hora ISO - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE (FIX): guardado de hora en formato ISO" -ForegroundColor Yellow
Write-Host "  PC: $env:COMPUTERNAME   Fecha: $STAMP" -ForegroundColor Yellow
Write-Host "  (Aplicar en el MONITOR DE VIGILANCIA)" -ForegroundColor Yellow
Line

if (-not (Test-Path $INSTALL)) {
    Write-Host "  [ERROR] No existe $INSTALL en esta PC." -ForegroundColor Red
    Write-Host "  Este upgrade va en la PC del Monitor de Vigilancia." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
if (-not (Test-Path (Join-Path $DIST_SRC 'index.html'))) {
    Write-Host "  [ERROR] No se encuentra el dist nuevo junto a este script:" -ForegroundColor Red
    Write-Host "          $DIST_SRC\index.html" -ForegroundColor Red
    Write-Host "  Grabaste la carpeta completa del upgrade en el pendrive?" -ForegroundColor Yellow
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
Write-Host "  EXITO. Upgrade aplicado." -ForegroundColor Green
Write-Host "  Cerra el navegador/kiosko y volvelo a abrir (Ctrl+F5 si hace falta)." -ForegroundColor Green
Write-Host "  COMO PROBARLO:" -ForegroundColor Green
Write-Host "   - Hace un intercambio y luego apreta F5: el tiempo en uso debe" -ForegroundColor Green
Write-Host "     seguir mostrando pocos minutos (NO saltar a horas)." -ForegroundColor Green
Write-Host "   - La alerta/WhatsApp solo debe aparecer al superar el tiempo real." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
