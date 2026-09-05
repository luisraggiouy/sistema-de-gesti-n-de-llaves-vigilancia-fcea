# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE: "Buscador en 'Llaves en Uso' del Monitor de Vigilancia"
#   Monitor de Vigilancia: siempre que haya al menos 1 llave en uso,
#   aparece un BUSCADOR al lado del titulo "Llaves en Uso" que filtra
#   en vivo por NOMBRE de la llave Y por NOMBRE de la persona (mismo
#   criterio que el buscador de las Terminales: sin acentos, primero
#   los que empiezan con el texto). Ademas ahora "Llaves en Uso" se
#   ordena por HORA DE ENTREGA descendente (la ultima entregada queda
#   arriba). Asi el vigilante no tiene que scrollear entre 20+ tarjetas.
#   El contador del titulo pasa a mostrar "X de Y en uso" cuando se
#   esta filtrando.
# Fecha: 2026-09-05
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
# ESTE UPGRADE VA EN: LAS 3 PC (Monitor, Terminal A y Terminal B).
#   Aunque el cambio se ve solo en el Monitor, el 'dist' es compartido y
#   cada PC sirve su PROPIO dist local en 127.0.0.1:5173 (ver
#   abrir_llaves_kiosk.bat). Para mantener las 3 PC identicas y que una
#   reinstalacion/recuperacion no revierta nada, ejecutar este mismo
#   script una vez en CADA PC.
#
# ROLLBACK: usar QUITAR_UPGRADE.ps1 (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Buscador Llaves en Uso - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE: Buscador en 'Llaves en Uso' (Monitor de Vigilancia)" -ForegroundColor Yellow
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
Write-Host "  EXITO. Upgrade aplicado en esta PC ($env:COMPUTERNAME)." -ForegroundColor Green
Write-Host "  RECORDA: ejecutar este script en LAS 3 PC (Monitor, Terminal A y B)." -ForegroundColor Yellow
Write-Host "  En esta PC: cerra el navegador/kiosko y volvelo a abrir (Ctrl+F5)." -ForegroundColor Green
Write-Host "  COMO PROBARLO (en el Monitor de Vigilancia):" -ForegroundColor Green
Write-Host "   1) Con al menos 1 llave en uso ya aparece el buscador junto al titulo." -ForegroundColor Green
Write-Host "   2) Al lado del titulo 'Llaves en Uso' escribi un salon o una persona." -ForegroundColor Green
Write-Host "   3) La lista se filtra en vivo y el contador muestra 'X de Y en uso'." -ForegroundColor Green
Write-Host "   4) La 'X' del campo limpia la busqueda de un click." -ForegroundColor Green
Write-Host "   5) La ultima llave entregada queda arriba de la lista." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
