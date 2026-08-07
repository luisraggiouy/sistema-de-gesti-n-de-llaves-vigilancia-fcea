# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE: "Texto descriptivo en 'Identificarse'"
#          Terminal A y Terminal B (pantalla de solicitud de llaves)
# Fecha: 2026-08-07
#
# QUE HACE:
#   1) Verifica que exista la instalacion oficial y el dist nuevo.
#   2) Respalda el dist actual  ->  dist_backup_<fecha_hora>
#   3) Copia el dist NUEVO (de esta carpeta) sobre la instalacion.
#
# NO toca PocketBase. NO borra datos. NO instala nada nuevo.
# Solo reemplaza el frontend compilado (dist).
#
# NOVEDAD: el titulo "Identificarse" ahora muestra al lado, en letra
# un poco mas chica pero legible, el texto:
#   "con su numero de celular o e-mail"
# para que los usuarios no ingresen su nombre.
#
# ESTE UPGRADE VA EN: Terminal A y Terminal B (repetir en cada una).
#
# ROLLBACK: usar 2-DESHACER_TEXTO_IDENTIFICARSE_ROLLBACK.bat (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Texto Identificarse - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE: Texto descriptivo en 'Identificarse'" -ForegroundColor Yellow
Write-Host "  PC: $env:COMPUTERNAME   Fecha: $STAMP" -ForegroundColor Yellow
Write-Host "  (Aplicar en Terminal A y Terminal B)" -ForegroundColor Yellow
Line

# 1) Verificaciones
if (-not (Test-Path $INSTALL)) {
    Write-Host "  [ERROR] No existe $INSTALL en esta PC." -ForegroundColor Red
    Write-Host "  Este upgrade va en las PC de Terminal A y Terminal B." -ForegroundColor Yellow
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

# 2) Backup del dist actual
if (Test-Path $DIST_DEST) {
    Write-Host "  [1/2] Respaldando dist actual ->" -ForegroundColor Cyan
    Write-Host "        $BACKUP" -ForegroundColor Gray
    robocopy $DIST_DEST $BACKUP /E /NFL /NDL /NJH /NJS /NP | Out-Null
    Write-Host "        [OK] Backup creado." -ForegroundColor Green
} else {
    Write-Host "  [1/2] No habia dist previo (instalacion nueva?). Sigo igual." -ForegroundColor Yellow
}

# 3) Copiar dist nuevo (mirror para eliminar assets viejos con hash distinto)
Write-Host "  [2/2] Copiando frontend nuevo ->" -ForegroundColor Cyan
Write-Host "        $DIST_DEST" -ForegroundColor Gray
robocopy $DIST_SRC $DIST_DEST /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
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
Write-Host "  En la pantalla de solicitud de llave, arriba de la caja de texto," -ForegroundColor Green
Write-Host "  debe decir: 'Identificarse con su numero de celular o e-mail'." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
