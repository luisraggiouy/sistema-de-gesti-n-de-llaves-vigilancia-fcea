# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE: "Intercambio sin cuenta regresiva (Terminal vuelve limpia)"
#   Cambio:
#   - TERMINAL (A/B): al confirmar un INTERCAMBIO de llave, YA NO aparece la
#     pantalla de exito con cuenta regresiva de 5-6s. Ahora sale un aviso breve
#     (toast) y la Terminal vuelve INMEDIATAMENTE al inicio limpio: cierra la
#     sesion del usuario, limpia las llaves seleccionadas y repliega la lista,
#     lista para el proximo usuario, SIN necesidad de F5.
#     (Mismo criterio que la solicitud normal, aplicado el 2026-08-30.)
# Fecha: 2026-09-03
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
#   Cada PC sirve su PROPIO dist local en 127.0.0.1:5173 (ver
#   abrir_llaves_kiosk.bat). El 8090 del Monitor es SOLO la API de
#   PocketBase (datos), NO el frontend. Por eso un cambio de 'dist' hay
#   que copiarlo en las 3 PC; si se aplica solo en el Monitor, las
#   Terminales A/B siguen con el JavaScript viejo.
#   Ejecutar este mismo script una vez en cada PC.
#
# ROLLBACK: usar 2-DESHACER_ROLLBACK.bat (restaura el ultimo backup).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Intercambio sin contador - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  UPGRADE: Intercambio sin cuenta regresiva (Terminal vuelve limpia)" -ForegroundColor Yellow
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
Write-Host "  COMO PROBARLO:" -ForegroundColor Green
Write-Host "   TERMINAL (A o B):" -ForegroundColor Green
Write-Host "    1) Identificate, elegi una llave que este EN USO y toca 'Intercambio'." -ForegroundColor Green
Write-Host "    2) Confirma el intercambio." -ForegroundColor Green
Write-Host "    3) YA NO debe aparecer la cuenta regresiva de 5s: sale un aviso breve" -ForegroundColor Green
Write-Host "       y la Terminal vuelve SOLA al inicio limpio (pide identificarse de" -ForegroundColor Green
Write-Host "       nuevo y la lista de llaves queda replegada), SIN apretar F5." -ForegroundColor Green
Write-Host "  Backup guardado en: $BACKUP" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
