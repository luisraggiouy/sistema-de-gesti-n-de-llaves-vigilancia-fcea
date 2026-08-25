# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE: "Terminal - evitar pedidos duplicados + intercambio en frecuentes"
# Fecha: 2026-08-25
#
# QUE MEJORA (en la Terminal de Usuario):
#   1) EVITA DUPLICADOS: si una llave ya fue solicitada por otra persona
#      y todavia no se entrego, ahora aparece marcada "Ya solicitada,
#      esperando entrega" y NO se puede volver a pedir. Antes se veia
#      como "Disponible" y se generaba un segundo pedido de la misma llave.
#   2) INTERCAMBIO EN FRECUENTES: en "Tus llaves frecuentes", una llave
#      que esta EN USO ahora muestra quien la tiene y el boton
#      "Intercambiar", igual que en el buscador. Antes desaparecia.
#   El buscador y las frecuentes quedan coherentes (misma info y acciones).
#
# QUE HACE EL SCRIPT:
#   1) Verifica que exista la instalacion oficial y el dist nuevo.
#   2) Respalda el dist actual  ->  dist_backup_<fecha_hora>
#   3) Copia el dist NUEVO sobre la instalacion, PRESERVANDO config.json
#      y system_health.json.
#
# NO toca PocketBase. NO borra datos. Solo reemplaza el frontend (dist).
#
# ESTE UPGRADE VA EN: TERMINAL A y TERMINAL B (las dos).
#   (Tambien puede aplicarse en el Monitor sin problema: es el mismo dist,
#    pero lo importante son las dos Terminales, que es donde se pide.)
#
# ROLLBACK: usar 2-DESHACER_ROLLBACK.bat (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Terminal Antiduplicado + Intercambio - FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE: Terminal - evitar duplicados + intercambio en frecuentes" -ForegroundColor Yellow
Write-Host "  PC: $env:COMPUTERNAME   Fecha: $STAMP" -ForegroundColor Yellow
Write-Host "  (Aplicar en TERMINAL A y TERMINAL B)" -ForegroundColor Yellow
Line

if (-not (Test-Path $INSTALL)) {
    Write-Host "  [ERROR] No existe $INSTALL en esta PC." -ForegroundColor Red
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
if (-not (Test-Path (Join-Path $DIST_SRC 'index.html'))) {
    Write-Host "  [ERROR] No se encuentra el dist nuevo junto a este script:" -ForegroundColor Red
    Write-Host "          $DIST_SRC\index.html" -ForegroundColor Red
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
    Write-Host "  [1/2] No habia dist previo. Sigo igual." -ForegroundColor Yellow
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
Write-Host "  EXITO. Upgrade aplicado en esta Terminal." -ForegroundColor Green
Write-Host "  RECORDA aplicarlo TAMBIEN en la otra Terminal." -ForegroundColor Yellow
Write-Host "  Cerra el navegador/kiosko y volvelo a abrir (Ctrl+F5 si hace falta)." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
