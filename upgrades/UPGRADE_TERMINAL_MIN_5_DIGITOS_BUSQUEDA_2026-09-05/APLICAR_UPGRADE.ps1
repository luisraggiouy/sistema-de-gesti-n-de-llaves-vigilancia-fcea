# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE: "Terminales - la lista de usuarios por celular recien
#           aparece a partir del 5to digito (anti-suplantacion)"
# Fecha: 2026-09-05
#
# QUE CAMBIA (todo en el frontend / dist):
#   Al identificarse por NUMERO DE CELULAR en las Terminales de
#   Usuario (A y B) y en el buscador de usuarios, la lista de
#   coincidencias YA NO se despliega con 1 o 2 digitos. Antes, al
#   tipear "0" aparecian TODOS los celulares que empiezan con 0, y
#   con "09" todos los "09..." -> se veia practicamente la lista
#   completa de usuarios (riesgo de suplantacion de identidad).
#   Ahora la lista recien aparece al tipear el 5to DIGITO, cuando el
#   numero ya quedo bien acotado. Se conserva la rapidez pero se gana
#   seguridad.
#   La busqueda por EMAIL sigue igual (a partir de 2 caracteres),
#   porque no expone la lista completa.
#
# ESTE UPGRADE VA EN: LAS 3 PC (Monitor, Terminal A y Terminal B).
#   El 'dist' es compartido y cada PC sirve su PROPIO dist local en
#   127.0.0.1:5173. Ejecutar este mismo script una vez en CADA PC.
#
# NO toca PocketBase. NO borra datos. Solo reemplaza el dist.
# ROLLBACK: usar QUITAR_UPGRADE.ps1 (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Busqueda min 5 digitos - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE: Lista por celular recien al 5to digito (anti-suplantacion)" -ForegroundColor Yellow
Write-Host "  PC: $env:COMPUTERNAME   Fecha: $STAMP" -ForegroundColor Yellow
Write-Host "  (Aplicar en LAS 3 PC: Monitor, Terminal A y Terminal B)" -ForegroundColor Yellow
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
Write-Host "  EXITO. Upgrade aplicado en esta PC ($env:COMPUTERNAME)." -ForegroundColor Green
Write-Host "  RECORDA: ejecutar este script en LAS 3 PC (Monitor, Terminal A y B)." -ForegroundColor Yellow
Write-Host "  En esta PC: cerra el navegador/kiosko y volvelo a abrir (Ctrl+F5)." -ForegroundColor Green
Write-Host "  COMO PROBARLO (en una Terminal de Usuario, A o B):" -ForegroundColor Green
Write-Host "   1) En 'Identificarse', tipea 1 solo digito (ej. '0'): NO debe" -ForegroundColor Green
Write-Host "      aparecer ninguna lista de usuarios." -ForegroundColor Green
Write-Host "   2) Segui tipeando hasta el 5to digito: recien ahi aparece la lista" -ForegroundColor Green
Write-Host "      de coincidencias (ya acotada)." -ForegroundColor Green
Write-Host "   3) Por email sigue funcionando desde 2 caracteres." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
