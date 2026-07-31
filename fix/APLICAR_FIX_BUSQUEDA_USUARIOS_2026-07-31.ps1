# ============================================================================
# APLICAR_FIX_BUSQUEDA_USUARIOS  -  2026-07-31
# Sistema de Gestion de Llaves FCEA
# ============================================================================
# QUE ARREGLA:
#   Bug en la busqueda de usuarios por telefono (Terminal A / B):
#     - Un mismo usuario aparecia duplicado (x2 / x3) en el listado.
#     - Aparecia un usuario que NO coincidia con los digitos tipeados.
#   Ambos eran un problema de RENDER del frontend (keys duplicadas de React),
#   NO habia datos duplicados en la base (confirmado con el diagnostico
#   DIAGNOSTICO_DUPLICADOS_USUARIOS_2026-07-31).
#
# QUE HACE ESTE SCRIPT:
#   Reemplaza el frontend compilado (index.html + carpeta assets\) de la
#   instalacion por la version corregida que viene en el pendrive, SIN tocar
#   config.json ni system_health.json (que son propios de cada PC).
#   Hace un backup antes, por si hay que volver atras (rollback).
#
# NO toca PocketBase. NO toca la base de datos. NO borra usuarios.
#
# DONDE EJECUTAR:
#   En cada PC donde se use la identificacion por telefono: TERMINAL A y
#   TERMINAL B (y opcionalmente el MONITOR). Se puede correr en las 3.
# ============================================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'APLICAR FIX BUSQUEDA USUARIOS - FCEA'

function Line($c='='){ Write-Host ($c * 66) -ForegroundColor Yellow }
function Header($t){ Line; Write-Host "  $t" -ForegroundColor Yellow; Line }

Header "APLICAR FIX BUSQUEDA USUARIOS (frontend) - $env:COMPUTERNAME"

# --- Rutas -------------------------------------------------------------------
$AQUI    = Split-Path -Parent $MyInvocation.MyCommand.Path
$ORIGEN  = Join-Path $AQUI 'dist_nuevo'          # payload en el pendrive
$INSTALL = 'C:\sistema-llaves-fcea'
$DEST    = Join-Path $INSTALL 'dist'
$stamp   = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$BACKUP  = Join-Path $INSTALL ("backup_fix_busqueda_" + $stamp)

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
Write-Host "  ROLLBACK (si algo sale mal): copia de vuelta el contenido de" -ForegroundColor Yellow
Write-Host ("    {0}" -f $BACKUP) -ForegroundColor Yellow
Write-Host "    sobre $DEST" -ForegroundColor Yellow
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
