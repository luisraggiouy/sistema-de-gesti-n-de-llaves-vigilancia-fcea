# =============================================================
# APLICAR_FIX.ps1
# FIX: "Autorizaciones mostraban las fechas UN DIA ANTES"
#      Monitor de Vigilancia / Terminales (Agenda / Autorizaciones)
# Fecha: 2026-08-30
#
# QUE HACE:
#   1) Verifica que exista la instalacion oficial y el dist nuevo.
#   2) Respalda el dist actual  ->  dist_backup_<fecha_hora>
#   3) Copia el dist NUEVO (de esta carpeta) sobre la instalacion,
#      PRESERVANDO config.json y system_health.json.
#
# NO toca PocketBase. NO borra datos. NO instala nada nuevo.
# Solo reemplaza el frontend compilado (dist).
#
# PROBLEMA CORREGIDO:
#   Al crear una autorizacion, la "fecha de autorizacion", "vigente
#   desde" y "vigente hasta" se mostraban corridas UN DIA ANTES.
#   Causa: la fecha (YYYY-MM-DD) se interpretaba como medianoche UTC
#   y al mostrarla en hora de Uruguay (UTC-3) caia en el dia anterior.
#   Las fechas SE GUARDABAN BIEN; era solo un error de visualizacion.
#
# IMPORTANTE: ESTE FIX TOCA EL FRONTEND (dist).
#   -> Aplicar en LAS 3 PC: Monitor de Vigilancia, Terminal A y Terminal B.
#   -> Ejecutar este mismo script UNA VEZ en cada PC y reabrir el kiosko.
#
# ROLLBACK: restaurar la carpeta dist_backup_<fecha_hora> creada en C:\sistema-llaves-fcea.
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'FIX Autorizaciones Fecha Un Dia Antes - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  FIX: Autorizaciones mostraban fechas UN DIA ANTES" -ForegroundColor Yellow
Write-Host "  PC: $env:COMPUTERNAME   Fecha: $STAMP" -ForegroundColor Yellow
Write-Host "  (Aplicar en LAS 3 PC: Monitor, Terminal A y Terminal B)" -ForegroundColor Yellow
Line

# 1) Verificaciones
if (-not (Test-Path $INSTALL)) {
    Write-Host "  [ERROR] No existe $INSTALL en esta PC." -ForegroundColor Red
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
if (-not (Test-Path (Join-Path $DIST_SRC 'index.html'))) {
    Write-Host "  [ERROR] No se encuentra el dist nuevo junto a este script:" -ForegroundColor Red
    Write-Host "          $DIST_SRC\index.html" -ForegroundColor Red
    Write-Host "  Grabaste la carpeta completa del fix en el pendrive?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

# 2) Backup del dist actual
if (Test-Path $DIST_DEST) {
    Write-Host "  [1/2] Respaldando dist actual ->" -ForegroundColor Cyan
    Write-Host "        $BACKUP" -ForegroundColor Gray
    robocopy $DIST_DEST $BACKUP /E /NFL /NDL /NJH /NJS /NP | Out-Null
    Write-Host "        [OK] Backup creado." -ForegroundColor Green
} else {
    Write-Host "  [1/2] No habia dist previo. Sigo igual." -ForegroundColor Yellow
}

# 3) Copiar dist nuevo (mirror) PRESERVANDO config.json y system_health.json
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
Write-Host "  EXITO. Fix aplicado en esta PC ($env:COMPUTERNAME)." -ForegroundColor Green
Write-Host "  Cerra el navegador/kiosko y volvelo a abrir (Ctrl+F5 si hace falta)." -ForegroundColor Green
Write-Host "  Verifica: crea una autorizacion con el calendario; la fecha de" -ForegroundColor Green
Write-Host "  autorizacion y la vigencia deben quedar EXACTAS (no un dia antes)." -ForegroundColor Green
Write-Host "  RECORDA: aplicar tambien en las OTRAS PC (Monitor, Terminal A y B)." -ForegroundColor Yellow
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
