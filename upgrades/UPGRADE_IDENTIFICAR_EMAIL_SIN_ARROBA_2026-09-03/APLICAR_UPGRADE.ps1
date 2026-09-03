# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE: "Identificarse con el email SIN tener que escribir la @"
#          Terminales de usuario (A y B) + Monitor
# Fecha: 2026-09-03
#
# QUE HACE:
#   1) Verifica que exista la instalacion oficial y el dist nuevo.
#   2) Respalda el dist actual  ->  dist_backup_<fecha_hora>
#   3) Copia el dist NUEVO (de esta carpeta) sobre la instalacion,
#      EXCLUYENDO config.json y system_health.json (no pisa la
#      configuracion de red propia de cada PC).
#
# NO toca PocketBase. NO borra datos. NO instala nada nuevo.
# Solo reemplaza el frontend compilado (dist).
#
# PROBLEMA QUE RESUELVE:
#   Los usuarios registrados SOLO con email (sin celular) no podian
#   identificarse en la terminal si escribian la parte del correo
#   antes de la "@" (ej. "katana941"): el sistema lo tomaba como
#   "busqueda por nombre" y lo bloqueaba. Ahora, si el texto no es
#   un celular, se busca por la PARTE LOCAL del email (antes de la
#   "@") por prefijo. Seguir tipeando el email completo con "@"
#   tambien funciona. La busqueda por NOMBRE de persona sigue
#   bloqueada (seguridad: se compara solo contra el email).
#
# ESTE UPGRADE VA EN: LAS 3 PC (Monitor, Terminal A y Terminal B).
#   El frontend NO es centralizado: cada PC sirve su propio dist.
#   Ejecutar este mismo script UNA vez en cada PC y reabrir el kiosko.
#
# ROLLBACK: usar 2-DESHACER_ROLLBACK.bat (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Identificar por Email sin @ - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE: Identificarse con el email SIN escribir la @" -ForegroundColor Yellow
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

# 3) Copiar dist nuevo (mirror). Se EXCLUYEN config.json y system_health.json
#    para NO pisar la configuracion de red/runtime propia de esta PC.
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
Write-Host "  RECORDA: aplicarlo tambien en las OTRAS 2 PC." -ForegroundColor Yellow
Write-Host "  Cerra el navegador/kiosko y volvelo a abrir (Ctrl+F5 si hace falta)." -ForegroundColor Green
Write-Host "  Prueba: en la terminal, escribi la parte del email antes de la @" -ForegroundColor Green
Write-Host "  (ej. 'katana941') y debe aparecer el usuario para seleccionarlo." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
