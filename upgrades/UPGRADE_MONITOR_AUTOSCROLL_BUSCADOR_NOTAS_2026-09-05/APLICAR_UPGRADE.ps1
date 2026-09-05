# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE: "Monitor: autoscroll 8s + buscador a la izquierda + notas en 1 renglon"
#   3 cambios de UI (frontend compilado / dist):
#     1) Monitor de Vigilancia: el AUTOSCROLL que vuelve al encabezado
#        ahora se activa a los 8 SEGUNDOS de inactividad (antes 4 s).
#     2) Monitor "Llaves en Uso": la caja de texto del BUSCADOR queda
#        alineada a la IZQUIERDA, en la misma linea que el titulo
#        "Llaves en Uso" y a la derecha del badge (antes iba pegada al
#        borde derecho con ml-auto).
#     3) Tarjetas "Llave en Uso": el campo NOTAS pasa a UN SOLO RENGLON
#        (icono + "Notas" + campo en la misma linea) para ahorrar espacio
#        vertical y scrollear menos cuando hay muchas llaves en uso.
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
#   Aunque los cambios se ven en el Monitor, el 'dist' es compartido y
#   cada PC sirve su PROPIO dist local en 127.0.0.1:5173 (ver
#   abrir_llaves_kiosk.bat). Para mantener las 3 PC identicas y que una
#   reinstalacion/recuperacion no revierta nada, ejecutar este mismo
#   script una vez en CADA PC.
#
# ROLLBACK: usar QUITAR_UPGRADE.ps1 (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Autoscroll+Buscador+Notas - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE: Autoscroll 8s + Buscador izquierda + Notas 1 renglon" -ForegroundColor Yellow
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
Write-Host "   1) Scrollea hacia abajo y deja de tocar: ahora tarda 8 seg (antes 4)" -ForegroundColor Green
Write-Host "      en volver solo al encabezado." -ForegroundColor Green
Write-Host "   2) Con al menos 1 llave en uso, el buscador aparece a la IZQUIERDA," -ForegroundColor Green
Write-Host "      junto al titulo 'Llaves en Uso' y a la derecha del badge." -ForegroundColor Green
Write-Host "   3) En cada tarjeta de llave en uso, el campo Notas ocupa UN renglon" -ForegroundColor Green
Write-Host "      (icono + 'Notas' + campo en la misma linea)." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
