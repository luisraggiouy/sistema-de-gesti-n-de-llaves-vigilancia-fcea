# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE (FIX v2): "Bloqueo nocturno de botones del Monitor"
#   - Corrige el tooltip "funcionalidad no disponible" (ahora SI se ve
#     al pasar el mouse sobre los botones grises).
#   - Corrige el desbloqueo: a las 06:00 los botones se reactivan de
#     forma precisa (alineado al reloj), sin recargar la pantalla.
# Fecha: 2026-08-25
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
# ESTE UPGRADE VA EN: Monitor de Vigilancia (que hace de servidor).
#
# ROLLBACK: usar 2-DESHACER_ROLLBACK.bat (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Fix Tooltip Bloqueo Nocturno - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE (FIX v2): tooltip + desbloqueo preciso a las 06:00" -ForegroundColor Yellow
Write-Host "  PC: $env:COMPUTERNAME   Fecha: $STAMP" -ForegroundColor Yellow
Write-Host "  (Aplicar en el MONITOR DE VIGILANCIA)" -ForegroundColor Yellow
Line

# 1) Verificaciones
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
#    IMPORTANTE: se EXCLUYEN config.json y system_health.json para NO pisar
#    la configuracion de red / runtime que ya tiene esta PC en produccion.
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
Write-Host "  COMO PROBARLO (de noche, 22:00 a 06:00):" -ForegroundColor Green
Write-Host "   - Los botones grises muestran 'funcionalidad no disponible' al" -ForegroundColor Green
Write-Host "     pasar el mouse por encima." -ForegroundColor Green
Write-Host "   - A las 06:00 en punto se reactivan solos (dentro del primer minuto)." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
