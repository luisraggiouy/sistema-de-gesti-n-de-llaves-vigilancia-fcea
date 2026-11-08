# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE: "Realtime de Solicitudes (fix latencia ~2s al pedir llave)"
# Fecha: 2026-11-05
#
# QUE HACE:
#   1) Verifica que exista la instalacion oficial y el dist nuevo (con index.html).
#   2) Respalda el dist actual  ->  dist_backup_<fecha_hora>  y VERIFICA el backup.
#   3) Copia el dist NUEVO (de esta carpeta) sobre la instalacion,
#      PRESERVANDO config.json y system_health.json (no pisa la config de red).
#
# NO toca PocketBase. NO borra datos. NO instala nada nuevo.
# Solo reemplaza el frontend compilado (dist).
#
# NOVEDAD (v2 - 2026-11-06, CORRIGE el intento del 2026-11-05 que quedaba
# erratico "a veces 1s, a veces 2s, a veces instantaneo"):
#   - El 1er intento suscribia pero el useEffect dependia de cargarSolicitudes,
#     que cambia de identidad al cambiar isConnected -> React re-montaba la
#     suscripcion todo el tiempo (con unsubscribe('*') global) y se PERDIAN
#     eventos. Ademas el callback solo disparaba OTRO fetch HTTP.
#   - AHORA: la suscripcion se monta UNA sola vez (refs estables) y la fila se
#     pinta AL INSTANTE desde el propio evento SSE (e.record), con un re-fetch
#     debounced de 300ms solo como respaldo. Latencia percibida: milisegundos
#     y CONSISTENTE. El polling de 3s sigue como red de seguridad.
#
# ESTE UPGRADE TOCA EL dist (frontend): aplicar en LAS 3 PC
#   (Monitor de Vigilancia, Terminal A y Terminal B).
#   Ejecutar el mismo script una vez en cada una y reabrir el kiosko (Ctrl+F5).
#
# ROLLBACK: usar 2-DESHACER_REALTIME_SOLICITUDES_ROLLBACK.bat
#           (restaura el ultimo dist_backup_*).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Realtime Solicitudes - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }
function Pausa {
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine()
}

Line
Write-Host "  UPGRADE: Realtime de Solicitudes (fix latencia ~2s)" -ForegroundColor Yellow
Write-Host "  PC: $env:COMPUTERNAME   Fecha: $STAMP" -ForegroundColor Yellow
Write-Host "  (Aplicar en LAS 3 PC: Monitor, Terminal A y Terminal B)" -ForegroundColor Yellow
Line

# 1) Verificaciones previas
if (-not (Test-Path $INSTALL)) {
    Write-Host "  [ERROR] No existe $INSTALL en esta PC." -ForegroundColor Red
    Write-Host "  Este upgrade va en las PC del sistema (Monitor / Terminal A / B)." -ForegroundColor Yellow
    Pausa; exit 1
}
if (-not (Test-Path (Join-Path $DIST_SRC 'index.html'))) {
    Write-Host "  [ERROR] No se encuentra el dist nuevo junto a este script:" -ForegroundColor Red
    Write-Host "          $DIST_SRC\index.html" -ForegroundColor Red
    Write-Host "  Grabaste la carpeta COMPLETA del upgrade en el pendrive?" -ForegroundColor Yellow
    Pausa; exit 1
}

# 2) Backup del dist actual  + VERIFICACION de que el backup quedo usable.
#    (Blindaje: si el backup no se puede crear/verificar, ABORTAMOS y NO
#     tocamos el dist de produccion, para no quedar nunca sin red de rollback.)
if (Test-Path $DIST_DEST) {
    Write-Host "  [1/2] Respaldando dist actual ->" -ForegroundColor Cyan
    Write-Host "        $BACKUP" -ForegroundColor Gray
    robocopy $DIST_DEST $BACKUP /E /NFL /NDL /NJH /NJS /NP | Out-Null
    $rcBk = $LASTEXITCODE
    if ($rcBk -ge 8) {
        Write-Host "        [ERROR] robocopy del backup devolvio codigo $rcBk." -ForegroundColor Red
        Write-Host "        NO se aplico el upgrade (tu sistema sigue intacto)." -ForegroundColor Yellow
        Pausa; exit 1
    }
    if (-not (Test-Path (Join-Path $BACKUP 'index.html'))) {
        Write-Host "        [ERROR] El backup no contiene index.html. Abortando." -ForegroundColor Red
        Write-Host "        NO se aplico el upgrade (tu sistema sigue intacto)." -ForegroundColor Yellow
        Pausa; exit 1
    }
    Write-Host "        [OK] Backup creado y verificado (tiene index.html)." -ForegroundColor Green
} else {
    Write-Host "  [1/2] No habia dist previo (instalacion nueva?). Sigo igual." -ForegroundColor Yellow
}

# 3) Copiar dist nuevo (mirror para limpiar assets viejos con hash distinto).
#    IMPORTANTE: se EXCLUYEN config.json y system_health.json para NO pisar la
#    configuracion de red / runtime que ya tiene esta PC en produccion.
Write-Host "  [2/2] Copiando frontend nuevo (preservando config.json) ->" -ForegroundColor Cyan
Write-Host "        $DIST_DEST" -ForegroundColor Gray
robocopy $DIST_SRC $DIST_DEST /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP | Out-Null
$rc = $LASTEXITCODE
if ($rc -ge 8) {
    Write-Host "        [ERROR] robocopy devolvio codigo $rc. Reviso permisos." -ForegroundColor Red
    Write-Host "        Podes DESHACER con 2-DESHACER_REALTIME_SOLICITUDES_ROLLBACK.bat" -ForegroundColor Yellow
    Pausa; exit 1
}
if (-not (Test-Path (Join-Path $DIST_DEST 'index.html'))) {
    Write-Host "        [ERROR] Tras copiar, no hay index.html en el dist. Reviso." -ForegroundColor Red
    Write-Host "        Podes DESHACER con 2-DESHACER_REALTIME_SOLICITUDES_ROLLBACK.bat" -ForegroundColor Yellow
    Pausa; exit 1
}
Write-Host "        [OK] Frontend actualizado y verificado (index.html presente)." -ForegroundColor Green

Line
Write-Host "  EXITO. Upgrade aplicado en esta PC ($env:COMPUTERNAME)." -ForegroundColor Green
Write-Host "  1) Cerra el navegador/kiosko y volvelo a abrir." -ForegroundColor Green
Write-Host "  2) Si el cambio no se nota, forza recarga con Ctrl+F5." -ForegroundColor Green
Write-Host "  3) RECORDA aplicarlo tambien en las OTRAS 2 PC." -ForegroundColor Green
Write-Host "" 
Write-Host "  PRUEBA: desde una Terminal pedi una llave; en el Monitor debe" -ForegroundColor Green
Write-Host "          aparecer casi al instante (antes tardaba ~2s)." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Pausa
