# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE: "Terminales - textos del registro, campos obligatorios en
#           rojo y auto-scroll al encabezado tras 4s de inactividad"
# Fecha: 2026-09-05
#
# QUE CAMBIA (todo en el frontend / dist):
#   1) AUTO-SCROLL: las Terminales de Usuario (A y B) vuelven solas
#      al encabezado (identificacion / busqueda de usuario) tras 4
#      SEGUNDOS de inactividad. No actua con un modal abierto (Registro
#      o Intercambio) ni sin conexion. Mismo criterio que el Monitor.
#   2) TEXTOS del formulario de Registro de Usuario:
#        - "Nombre completo"     -> "Nombre y apellido"
#        - "Correo electronico"  -> "Correo electronico (si ya ingreso
#          su celular este campo es OPCIONAL)"
#        - Bajo la linea "Complete sus datos una unica vez..." se agrega
#          la leyenda: "Los campos marcados con * son obligatorios."
#   3) VALIDACION VISUAL: al pulsar "Registrarse" con campos obligatorios
#      sin completar, ademas de dejar el boton atenuado/inactivo, se
#      resaltan en ROJO (borde + texto de ayuda) los campos que faltan.
#
# ESTE UPGRADE VA EN: LAS 3 PC (Monitor, Terminal A y Terminal B).
#   El 'dist' es compartido y cada PC sirve su PROPIO dist local en
#   127.0.0.1:5173. Ejecutar este mismo script una vez en CADA PC.
#
# NO toca PocketBase. NO borra datos. Solo reemplaza el dist.
# ROLLBACK: usar QUITAR_UPGRADE.ps1 (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Terminal Registro + Auto-scroll - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE: Terminal - textos registro + campos rojos + auto-scroll" -ForegroundColor Yellow
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
Write-Host "   1) Abri 'Primera vez? Registrarse'." -ForegroundColor Green
Write-Host "   2) Debe decir 'Nombre y apellido' y 'Correo electronico (si ya" -ForegroundColor Green
Write-Host "      ingreso su celular este campo es OPCIONAL)'." -ForegroundColor Green
Write-Host "   3) Debajo de 'Complete sus datos...' se ve la leyenda del *." -ForegroundColor Green
Write-Host "   4) Con campos vacios, tocar 'Registrarse': los que faltan en ROJO." -ForegroundColor Green
Write-Host "   5) Cerra el modal, baja con la rueda y solta el mouse: a los 4s" -ForegroundColor Green
Write-Host "      la pantalla vuelve sola arriba (identificacion)." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
