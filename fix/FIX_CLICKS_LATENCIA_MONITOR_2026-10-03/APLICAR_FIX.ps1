# =============================================================
# APLICAR_FIX.ps1  (FIX CLICKS / LATENCIA - MONITOR)
# Fecha: 2026-10-03
#
# PROBLEMA QUE ARREGLA:
#   En el Monitor, al tocar el nombre del vigilante para ENTREGAR o
#   RECIBIR una llave, la tarjeta tardaba 1-2s en desaparecer y a veces
#   "reflotaba" (reaparecia). El vigilante, dudando, volvia a clickear y
#   el 2do click caia sobre OTRA llave, marcandola por error.
#
# CAUSA RAIZ (encontrada 2026-10-03):
#   Las 'solicitudes' NO usan realtime: el Monitor las refresca por
#   POLLING cada 3s. En la LAN de facultad la escritura a PocketBase
#   tarda 1-2s; si un poll caia en esa ventana, traia la solicitud
#   TODAVIA con el estado viejo y PISABA el cambio optimista -> la
#   tarjeta reaparecia.
#
# SOLUCION:
#   1) "Cambios en vuelo": cuando se entrega/devuelve/intercambia, se
#      marca la solicitud y el poll NO la refloten hasta que el servidor
#      confirme el nuevo estado (o venza un timeout de seguridad de 15s).
#   2) El poll ya no reemplaza la lista si no cambio nada (evita
#      re-render que soltaba el candado anti-doble-click y parpadeo).
#   3) Se mantiene el candado anti-doble-click por tarjeta (ya existia).
#
# NO toca PocketBase. NO borra datos. NO instala nada nuevo.
# Solo reemplaza el frontend compilado (dist).
#
# ============================================================
#   IMPORTANTISIMO: APLICAR EN LAS 3 PC
#   (Monitor de Vigilancia, Terminal A y Terminal B)
#   Ejecutar este mismo script UNA vez en cada PC y reabrir el kiosko.
#   El frontend NO se sirve centralizado: cada PC corre su propio
#   'vite preview' sobre el dist de su PROPIO disco. Si se aplica solo
#   en el Monitor, las Terminales quedarian con el codigo viejo.
# ============================================================
#
# ROLLBACK: usar 2-DESHACER_ROLLBACK.bat (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'FIX CLICKS/LATENCIA Monitor - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  FIX CLICKS / LATENCIA en el Monitor (reflote por polling)" -ForegroundColor Yellow
Write-Host "  PC: $env:COMPUTERNAME   Fecha: $STAMP" -ForegroundColor Yellow
Write-Host "  APLICAR EN LAS 3 PC (Monitor, Terminal A y Terminal B)" -ForegroundColor Yellow
Line

# 1) Verificaciones
if (-not (Test-Path $INSTALL)) {
    Write-Host "  [ERROR] No existe $INSTALL en esta PC." -ForegroundColor Red
    Write-Host "  Este paquete va en las 3 PC (Monitor, Terminal A y Terminal B)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
if (-not (Test-Path (Join-Path $DIST_SRC 'index.html'))) {
    Write-Host "  [ERROR] No se encuentra el dist nuevo junto a este script:" -ForegroundColor Red
    Write-Host "          $DIST_SRC\index.html" -ForegroundColor Red
    Write-Host "  Grabaste la carpeta COMPLETA del paquete en el pendrive?" -ForegroundColor Yellow
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

# 3) Copiar dist nuevo (mirror). Regla de oro: EXCLUIR config.json y
#    system_health.json para NO pisar la config de red/runtime de esta PC.
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
Write-Host "  EXITO. Fix aplicado en esta PC ($env:COMPUTERNAME)." -ForegroundColor Green
Write-Host "  Cerra el navegador/kiosko y volvelo a abrir (Ctrl+F5 si hace falta)." -ForegroundColor Green
Write-Host "  QUE PROBAR (en el Monitor de Vigilancia):" -ForegroundColor Green
Write-Host "   - Entregar/recibir una llave: la tarjeta sale de la lista al" -ForegroundColor Green
Write-Host "     instante y NO reaparece/reflota. Un 2do click no marca otra." -ForegroundColor Green
Write-Host "  ACORDATE: aplicar TAMBIEN en Terminal A y Terminal B." -ForegroundColor Yellow
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
