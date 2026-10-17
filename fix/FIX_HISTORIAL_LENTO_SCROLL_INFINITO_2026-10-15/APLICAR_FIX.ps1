# =============================================================
# APLICAR_FIX.ps1  (FIX HISTORIAL LENTO - scroll infinito)
# Fecha: 2026-10-15
#
# PROBLEMA QUE ARREGLA:
#   Al abrir "Buscador Historico de Llaves" (boton Historial) el dialogo
#   tardaba ~3 segundos en abrir y otro tanto en cerrar. No es un limite
#   del historial (es "infinito", crece con el uso): con 2659+ registros
#   el componente pintaba TODAS las tarjetas de golpe en el DOM, y montar
#   / desmontar ese arbol enorme es lo que trababa el abrir y el cerrar.
#   El problema iba a empeorar mes a mes al crecer el historial.
#
# CAUSA RAIZ:
#   src/components/monitor/KeyHistorySearch.tsx hacia historial.map(...)
#   sobre TODA la lista derivada de solicitudes (useBusquedaHistorial.ts).
#
# SOLUCION (solo frontend, scroll infinito):
#   Se pintan ~40 tarjetas por tanda y se van sumando a medida que el
#   usuario baja el scroll (IntersectionObserver). La BUSQUEDA y los
#   FILTROS por fecha siguen operando sobre el TOTAL (2659+), solo se
#   limita cuanto se dibuja a la vez. El contador "X de Y registros"
#   sigue mostrando el total real.
#
# NO toca PocketBase. NO borra datos. NO cambia config.json.
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
$Host.UI.RawUI.WindowTitle = 'FIX HISTORIAL LENTO (scroll infinito) - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  FIX HISTORIAL LENTO en el Buscador Historico (scroll infinito)" -ForegroundColor Yellow
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
    Write-Host "  (El dist se compila con BUILD_DIST.ps1; ver INSTRUCTIVO.)" -ForegroundColor Yellow
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
Write-Host "   - Abrir 'Historial': debe abrir y cerrar al INSTANTE." -ForegroundColor Green
Write-Host "   - Bajar el scroll: se van cargando mas registros solos." -ForegroundColor Green
Write-Host "   - Buscar/filtrar por fecha: el contador muestra el total real." -ForegroundColor Green
Write-Host "  ACORDATE: aplicar TAMBIEN en Terminal A y Terminal B." -ForegroundColor Yellow
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
