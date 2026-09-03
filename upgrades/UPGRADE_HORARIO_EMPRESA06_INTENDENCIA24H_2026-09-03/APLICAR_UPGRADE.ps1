# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE: "Horario - Empresas desde 06:00 + Intendencia 24 hs"
# Fecha: 2026-09-03
#
# QUE CAMBIA (Terminal de Usuario A/B):
#   1) Los usuarios de tipo EMPRESA (ej. cooperativa "El Progreso")
#      pueden solicitar llaves desde las 06:00 (franja 06:00-06:59),
#      una hora antes que el resto. (Se re-confirma / re-compila la
#      logica que ya existia para que quede efectiva en el dist.)
#   2) Se agrega una nueva categoria exenta TOTAL (24 hs): Personal TAS
#      del departamento/seccion "Intendencia" (4 personas). Antes solo
#      estaban exentos 24 hs Servicios Generales y Vigilancia.
#
#   El resto de los usuarios sigue con el corte de las 07:00 y el
#   bloqueo nocturno (23:00 en adelante y antes de las 06:00) sigue
#   vigente para todos, empresas incluidas.
#
# QUE HACE ESTE SCRIPT:
#   1) Verifica que exista la instalacion oficial y el dist nuevo.
#   2) Respalda el dist actual  ->  dist_backup_<fecha_hora>
#   3) Copia el dist NUEVO (de esta carpeta) sobre la instalacion,
#      PRESERVANDO config.json y system_health.json.
#
# NO toca PocketBase. NO borra datos. Solo reemplaza el frontend (dist).
#
# ESTE UPGRADE VA EN: LAS 3 PC (Monitor, Terminal A y Terminal B).
#   Cada PC sirve su PROPIO dist local en 127.0.0.1:5173. El 8090 del
#   Monitor es SOLO la API de PocketBase (datos), NO el frontend. Si se
#   aplica solo en el Monitor, las Terminales A/B siguen con el JS viejo.
#   Ejecutar este mismo script una vez en cada PC.
#
# ROLLBACK: usar QUITAR_UPGRADE.ps1 (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Horario Empresa06 + Intendencia24h - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE: Empresas desde 06:00 + Intendencia 24 hs" -ForegroundColor Yellow
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
#    para NO pisar la configuracion de red / runtime de esta PC.
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
Write-Host "  COMO PROBARLO (Terminal A o B):" -ForegroundColor Green
Write-Host "   A) EMPRESA entre 06:00 y 06:59: identificate como usuario tipo" -ForegroundColor Green
Write-Host "      EMPRESA (ej. Cooperativa El Progreso), elegi llave y envia." -ForegroundColor Green
Write-Host "      -> Debe dejarte enviar (SIN banner rojo)." -ForegroundColor Green
Write-Host "   B) INTENDENCIA a cualquier hora (incluso de madrugada):" -ForegroundColor Green
Write-Host "      Personal TAS con departamento 'Intendencia' -> debe dejar enviar." -ForegroundColor Green
Write-Host "   C) Un usuario comun a las 06:30 debe seguir BLOQUEADO (banner rojo)." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
