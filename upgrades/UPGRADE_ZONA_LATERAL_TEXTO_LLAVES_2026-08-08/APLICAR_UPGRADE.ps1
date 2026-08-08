# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE: "Zona del tablero: aclaracion en Laterales (Gestion de Llaves)"
#          Monitor de Vigilancia -> Pestana Llaves (Agregar / Modificar)
# Fecha: 2026-08-08
#
# QUE HACE:
#   1) Verifica que exista la instalacion oficial y el dist nuevo.
#   2) Respalda el dist actual  ->  dist_backup_<fecha_hora>
#   3) Copia el dist NUEVO (de esta carpeta) sobre la instalacion.
#
# NO toca PocketBase. NO borra datos. NO instala nada nuevo.
# Solo reemplaza el frontend compilado (dist).
#
# NOVEDAD (solo texto, no cambia datos):
#   En Gestion de Llaves (Agregar y Modificar), el desplegable
#   "Zona del tablero" ahora aclara para los laterales:
#     - "Lateral izquierdo (espacio pequeno; no tiene numero de fila,
#        ni letra de columna)"
#     - "Lateral derecho (espacio pequeno; no tiene numero de fila,
#        ni letra de columna)"
#   El valor guardado sigue siendo el mismo ("Lateral izquierdo" /
#   "Lateral derecho"); solo cambia el texto que se ve.
#
#   Recordatorio de comportamiento (ya existente y correcto):
#   al elegir un lateral NO se piden fila ni columna; para el resto de
#   zonas (Fondo, Puerta izquierda/derecha) SI se pueden asignar fila y
#   columna, y varias llaves pueden compartir la misma coordenada (p.ej. B4).
#
# ESTE UPGRADE VA EN: Monitor de Vigilancia (que hace de servidor).
#
# ROLLBACK: usar 2-DESHACER_ZONA_LATERAL_ROLLBACK.bat (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Zona Lateral Texto Llaves - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE: Zona del tablero - aclaracion en Laterales" -ForegroundColor Yellow
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
Write-Host "  Abri Gestion de Llaves -> pestana Modificar (o Agregar) y abri el" -ForegroundColor Green
Write-Host "  desplegable 'Zona del tablero': los laterales ahora muestran la" -ForegroundColor Green
Write-Host "  aclaracion (espacio pequeno; no tiene numero de fila, ni letra de columna)." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
