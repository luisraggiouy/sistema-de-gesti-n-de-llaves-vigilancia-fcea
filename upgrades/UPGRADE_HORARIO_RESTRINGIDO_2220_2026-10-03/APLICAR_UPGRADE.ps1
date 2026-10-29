# =============================================================
# APLICAR_UPGRADE.ps1  (HORARIO RESTRINGIDO NOCTURNO -> 22:20)
# Fecha: 2026-10-03
#
# QUE CAMBIA:
#   Los botones restringidos de noche en el Monitor (Objetos, Agenda,
#   Configuracion, Vigilantes, Llaves, Dashboard) ahora se bloquean
#   desde las 22:20 (antes 22:00). Se le achican 20 minutos al INICIO;
#   el fin (06:00) queda IGUAL.
#
#   Ventana nocturna resultante: 22:20 -> 06:00.
#     - 22:00 a 22:19  -> HABILITADO (antes estaba bloqueado)
#     - 22:20 a 05:59  -> BLOQUEADO
#     - 06:00 en adelante -> HABILITADO (sin cambios)
#
# NO toca PocketBase. NO borra datos. NO instala nada nuevo.
# Solo reemplaza el frontend compilado (dist).
#
# ============================================================
#   IMPORTANTISIMO: APLICAR EN LAS 3 PC
#   (Monitor de Vigilancia, Terminal A y Terminal B)
#   Ejecutar este mismo script UNA vez en cada PC y reabrir el kiosko.
# ============================================================
#
# ROLLBACK: usar 2-DESHACER_ROLLBACK.bat (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Horario Restringido 22:20 - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE Horario restringido nocturno: ahora 22:20 a 06:00" -ForegroundColor Yellow
Write-Host "  PC: $env:COMPUTERNAME   Fecha: $STAMP" -ForegroundColor Yellow
Write-Host "  APLICAR EN LAS 3 PC (Monitor, Terminal A y Terminal B)" -ForegroundColor Yellow
Line

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

if (Test-Path $DIST_DEST) {
    Write-Host "  [1/2] Respaldando dist actual ->" -ForegroundColor Cyan
    Write-Host "        $BACKUP" -ForegroundColor Gray
    robocopy $DIST_DEST $BACKUP /E /NFL /NDL /NJH /NJS /NP | Out-Null
    Write-Host "        [OK] Backup creado." -ForegroundColor Green
} else {
    Write-Host "  [1/2] No habia dist previo (instalacion nueva?). Sigo igual." -ForegroundColor Yellow
}

# Regla de oro: EXCLUIR config.json y system_health.json.
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
Write-Host "  En el kiosko, recarga con Ctrl+F5 (como siempre). NO hace falta" -ForegroundColor Green
Write-Host "  cerrar el navegador." -ForegroundColor Green

# --- Verificacion automatica: confirmar que el dist copiado trae la logica
#     22:20 (r===22) y NO la vieja 22:00. Esto detecta en el acto si se copio
#     un dist equivocado (la causa del fallo del 03/10/2026). ---
$jsDest = Get-ChildItem (Join-Path $DIST_DEST 'assets') -Filter 'index-*.js' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($jsDest) {
    $tiene2220 = Select-String -Path $jsDest.FullName -Pattern 'r===22' -Quiet
    if ($tiene2220) {
        Write-Host "  [VERIFICADO] El dist en disco tiene la logica 22:20 (correcto)." -ForegroundColor Green
    } else {
        Write-Host "  [ALERTA] El dist en disco NO tiene la logica 22:20 (bloquearia 22:00)." -ForegroundColor Red
        Write-Host "           Avisale a Luis: el dist copiado no es el correcto." -ForegroundColor Red
    }
} else {
    Write-Host "  [AVISO] No pude ubicar el index-*.js para verificar. Revisa el dist." -ForegroundColor Yellow
}

Write-Host "  QUE PROBAR: a las 22:00-22:19 los botones restringidos siguen" -ForegroundColor Green
Write-Host "   HABILITADOS; a partir de las 22:20 quedan BLOQUEADOS (hasta 06:00)." -ForegroundColor Green
Write-Host "  ACORDATE: aplicar TAMBIEN en Terminal A y Terminal B." -ForegroundColor Yellow
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
