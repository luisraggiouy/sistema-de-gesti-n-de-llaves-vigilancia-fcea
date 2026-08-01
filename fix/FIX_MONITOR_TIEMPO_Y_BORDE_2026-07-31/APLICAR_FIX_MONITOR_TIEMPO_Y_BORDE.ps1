# ============================================================================
# APLICAR_FIX_MONITOR_TIEMPO_Y_BORDE  -  2026-07-31
# Sistema de Gestion de Llaves FCEA
# ============================================================================
# QUE ARREGLA / MEJORA (Monitor Vigilancia):
#
#   1) FIX contador "Hace 300 min": cuando llegaba un pedido nuevo desde
#      Terminal A / B, el contador de espera mostraba un numero grande al
#      instante en vez de arrancar en 0. Causa: se anclaba a `hora_solicitud`
#      (timestamp de la Terminal) y si la Terminal y el Monitor tenian zona
#      horaria distinta, el epoch difria en horas. AHORA se ancla al campo
#      `created` que genera PocketBase (que corre EN el Monitor) -> ambos
#      extremos de la resta usan el MISMO reloj y no hay desfase entre PCs.
#
#   2) UPGRADE formato de reloj (solicitudes pendientes Y llaves en uso):
#        < 10 s  -> "Ahora" (solicitudes) / "Recien entregada" (en uso)
#        < 1 min -> "menos de 1 minuto"
#        < 1 h   -> "X minutos"
#        >= 1 h  -> "HH:MM:SS"
#
#   3) UPGRADE alerta visual: se quitaron los colores de urgencia por tiempo
#      (gris/amarillo/rojo) del listado de pedidos. AHORA toda solicitud
#      pendiente lleva un CONTORNO ROJO FIRME (rojo, no alarmante) mientras
#      no se entregue, para que se vea de lejos (vigilante a 2+ m) y NO se
#      confunda con el listado de "llaves en uso".
#
# QUE HACE ESTE SCRIPT:
#   Reemplaza el frontend compilado (index.html + carpeta assets\) de la
#   instalacion por la version corregida que viene en el pendrive, SIN tocar
#   config.json ni system_health.json (que son propios de cada PC).
#   Hace un backup antes, por si hay que volver atras (rollback).
#
#   NO toca PocketBase. NO toca la base de datos. NO borra nada de datos.
#
# DONDE EJECUTAR:
#   Los cambios se ven en el MONITOR VIGILANCIA -> ejecutar SI o SI ahi.
#   El bundle es compartido, asi que se puede correr tambien en Terminal A y
#   Terminal B para dejar las 3 PC con el mismo frontend (recomendado).
# ============================================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'APLICAR FIX MONITOR TIEMPO Y BORDE - FCEA'

function Line($c='='){ Write-Host ($c * 66) -ForegroundColor Yellow }
function Header($t){ Line; Write-Host "  $t" -ForegroundColor Yellow; Line }

Header "APLICAR FIX MONITOR (tiempo + borde) - $env:COMPUTERNAME"

# --- Rutas -------------------------------------------------------------------
$AQUI    = Split-Path -Parent $MyInvocation.MyCommand.Path
$ORIGEN  = Join-Path $AQUI 'dist_nuevo'          # payload en el pendrive
$INSTALL = 'C:\sistema-llaves-fcea'
$DEST    = Join-Path $INSTALL 'dist'
$stamp   = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$BACKUP  = Join-Path $INSTALL ("backup_fix_monitor_tiempo_borde_" + $stamp)

# --- Validaciones ------------------------------------------------------------
if (-not (Test-Path (Join-Path $ORIGEN 'index.html'))) {
    Write-Host "  [ERROR] No encuentro el payload en:" -ForegroundColor Red
    Write-Host "          $ORIGEN\index.html" -ForegroundColor Red
    Write-Host "  Asegurate de ejecutar este .bat desde la carpeta del fix en el" -ForegroundColor Yellow
    Write-Host "  pendrive (que tiene al lado la carpeta 'dist_nuevo')." -ForegroundColor Yellow
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
if (-not (Test-Path (Join-Path $DEST 'index.html'))) {
    Write-Host "  [ERROR] No existe la instalacion en:" -ForegroundColor Red
    Write-Host "          $DEST" -ForegroundColor Red
    Write-Host "  Esta PC no parece tener el sistema instalado en la ruta estandar." -ForegroundColor Yellow
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

# --- 1) Backup ---------------------------------------------------------------
Write-Host ""
Write-Host "  [1/3] Backup de la version actual..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $BACKUP -Force | Out-Null
Copy-Item -Path (Join-Path $DEST 'index.html') -Destination $BACKUP -Force
if (Test-Path (Join-Path $DEST 'assets')) {
    Copy-Item -Path (Join-Path $DEST 'assets') -Destination $BACKUP -Recurse -Force
}
Write-Host ("        Backup guardado en: {0}" -f $BACKUP) -ForegroundColor Green

# --- 2) Limpiar bundles viejos (solo index-*.js / index-*.css) ---------------
Write-Host "  [2/3] Reemplazando frontend (sin tocar config.json)..." -ForegroundColor Cyan
$destAssets = Join-Path $DEST 'assets'
if (-not (Test-Path $destAssets)) { New-Item -ItemType Directory -Path $destAssets -Force | Out-Null }
Get-ChildItem -Path $destAssets -Filter 'index-*.js'  -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $destAssets -Filter 'index-*.css' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

# --- 3) Copiar la version nueva ---------------------------------------------
Copy-Item -Path (Join-Path $ORIGEN 'index.html') -Destination $DEST -Force
Copy-Item -Path (Join-Path $ORIGEN 'assets\*') -Destination $destAssets -Recurse -Force
Write-Host "        [OK] index.html + assets actualizados." -ForegroundColor Green
Write-Host "        [OK] config.json y system_health.json quedaron intactos." -ForegroundColor Green

# --- Resumen -----------------------------------------------------------------
Write-Host ""
Line
Write-Host "  FIX APLICADO. Ahora hay que RECARGAR el frontend:" -ForegroundColor Green
Write-Host "    - Cerra el kiosko (Alt+F4) y volve a abrirlo, o" -ForegroundColor Green
Write-Host "    - Reinicia la PC." -ForegroundColor Green
Write-Host ""
Write-Host "  COMO VERIFICAR:" -ForegroundColor Cyan
Write-Host "    Pedi una llave desde la Terminal. En el Monitor:" -ForegroundColor Cyan
Write-Host "      - La tarjeta del pedido debe tener CONTORNO ROJO firme."   -ForegroundColor Cyan
Write-Host "      - El contador dice 'Ahora' los primeros 10 s, luego"       -ForegroundColor Cyan
Write-Host "        'Hace menos de 1 minuto', luego 'Hace X minutos'."       -ForegroundColor Cyan
Write-Host "      - Al entregar, en 'llaves en uso' dice 'Recien entregada'" -ForegroundColor Cyan
Write-Host "        y luego 'En uso hace X minutos'."                        -ForegroundColor Cyan
Write-Host ""
Write-Host "  ROLLBACK (si algo sale mal): copia de vuelta el contenido de" -ForegroundColor Yellow
Write-Host ("    {0}" -f $BACKUP) -ForegroundColor Yellow
Write-Host "    sobre $DEST" -ForegroundColor Yellow
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
