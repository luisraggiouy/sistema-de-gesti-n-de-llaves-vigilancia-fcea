# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE: "Llaves frecuentes - antiduplicado + consolidacion"
#   Problema (caso Milton de Souza, 2026-09-05):
#     Un usuario pedia MUCHAS llaves de una vez (11) y luego, al
#     identificarse de nuevo, solo veia 3 en "Llaves frecuentes".
#   Causa (confirmada con diagnostico):
#     Al pedir N llaves, la Terminal llamaba N veces seguidas a
#     registrarUso(). Como el 1er registro aun no tenia id, cada
#     llamada creaba un registro NUEVO en historial_llaves ->
#     N registros DUPLICADOS del mismo usuario (condicion de
#     carrera). El frontend leia SOLO el primero (parcial) y el
#     usuario "perdia" llaves frecuentes. Afectaba a 23 usuarios.
#   Fix (frontend, sin tocar la estructura de datos):
#     1) Al ENVIAR el pedido, se registran TODAS las llaves en UNA
#        sola operacion (adios condicion de carrera).
#     2) Al LEER, el frontend MERGEA todos los registros del mismo
#        usuario -> los 23 usuarios ya afectados recuperan sus
#        frecuentes SIN tocar la base manualmente.
#     3) La proxima vez que ese usuario pida una llave, se BORRAN
#        automaticamente sus registros duplicados viejos, dejando
#        uno solo consolidado.
# Fecha: 2026-09-05
#
# QUE HACE ESTE SCRIPT:
#   1) Verifica que exista la instalacion oficial y el dist nuevo.
#   2) Respalda el dist actual  ->  dist_backup_<fecha_hora>
#   3) Copia el dist NUEVO (de esta carpeta) sobre la instalacion,
#      PRESERVANDO config.json y system_health.json.
#
# NO toca PocketBase. NO borra datos. NO instala nada nuevo.
# Solo reemplaza el frontend compilado (dist). La limpieza de
# duplicados la hace el propio frontend, de forma segura, cuando
# cada usuario vuelve a pedir una llave.
#
# ESTE UPGRADE VA EN: LAS 3 PC (Monitor, Terminal A y Terminal B).
#   Cada PC sirve su PROPIO dist local en 127.0.0.1:5173. El 8090
#   del Monitor es SOLO la API de PocketBase (datos), NO el
#   frontend. Por eso un cambio de 'dist' hay que copiarlo en las
#   3 PC; si se aplica solo en el Monitor, las Terminales A/B
#   siguen con el JavaScript viejo. Ejecutar este mismo script una
#   vez en cada PC.
#
# ROLLBACK: usar 2-DESHACER_ROLLBACK.bat (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Llaves frecuentes antiduplicado - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE: Llaves frecuentes - antiduplicado + consolidacion" -ForegroundColor Yellow
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
Write-Host "  RECORDA: hay que ejecutar este script en LAS 3 PC (Monitor," -ForegroundColor Yellow
Write-Host "  Terminal A y Terminal B). Si falta alguna, esa seguira con el JS viejo." -ForegroundColor Yellow
Write-Host "  En esta PC: cerra el navegador/kiosko y volvelo a abrir (Ctrl+F5)." -ForegroundColor Green
Write-Host ""
Write-Host "  COMO PROBARLO (en una Terminal A o B):" -ForegroundColor Green
Write-Host "   1) Identificate con un usuario que hoy 'pierda' frecuentes" -ForegroundColor Green
Write-Host "      (ej. Milton de Souza). Deberian aparecer TODAS sus llaves" -ForegroundColor Green
Write-Host "      frecuentes (ahora hasta 50, antes solo 7), no solo 2-3." -ForegroundColor Green
Write-Host "   2) Pedi VARIAS llaves de una sola vez (ej. 5) y enviala." -ForegroundColor Green
Write-Host "   3) Volve a identificarte con ese usuario: TODAS las llaves" -ForegroundColor Green
Write-Host "      recien pedidas deben figurar en 'Llaves frecuentes'." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
