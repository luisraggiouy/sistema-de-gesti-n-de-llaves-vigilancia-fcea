# =============================================================
# BUILD_DIST.ps1  (compila el dist de este UPGRADE)  -- BLINDADO
# Fecha: 2026-10-04
#
# Genera el frontend compilado (dist) y lo deja dentro de esta
# carpeta:  <carpeta de este script>\dist
#
# -------------------------------------------------------------
#  BLINDAJE (causa raiz del incidente 2026-10-03):
#  Un BUILD_DIST anterior (de otro paquete) compilaba desde
#  E:\sistema-llaves-fcea o C:\sistema-llaves-fcea como
#  "fallback". Esas copias estaban CONGELADAS (E: = agosto,
#  C: = junio) y pisaban ~2 meses de upgrades -> regresiones.
#
#  Este script compila SIEMPRE y SOLO desde el REPOSITORIO GIT
#  (unica fuente de verdad) definido en $REPO. Si esa ruta no
#  es un repo valido (no tiene package.json + node_modules),
#  ABORTA. NUNCA cae a E: ni a C:.
# -------------------------------------------------------------
#
# Correr en la laptop de desarrollo (donde vive el repo git con
# node_modules). NO toca produccion (C:\sistema-llaves-fcea):
# solo compila y copia el dist a ESTE paquete del pendrive.
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'BUILD DIST (blindado) - UPGRADE Objetos Transicion'

# --- UNICA FUENTE DE VERDAD: el repositorio git de desarrollo. ---
# Si alguna vez se mueve el repo, ajustar SOLO esta linea.
$REPO = 'C:\Users\rep\.cline\data\workspaces\chat\gestion-llaves-vigilancia-fcea'

$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_OUT  = Join-Path $SCRIPTDIR 'dist'

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }

Line
Write-Host "  COMPILAR DIST (blindado) - UPGRADE Objetos Transicion Turno" -ForegroundColor Yellow
Write-Host "  Fuente UNICA: repo git (nunca E: ni C:)" -ForegroundColor Yellow
Line

# --- Validacion DURA del repo (sin fallback). ---
if (-not (Test-Path (Join-Path $REPO 'package.json'))) {
    Write-Host "  [ERROR] No hay package.json en el repo:" -ForegroundColor Red
    Write-Host "          $REPO" -ForegroundColor Red
    Write-Host "  Ajusta la variable `$REPO al repo git de desarrollo." -ForegroundColor Yellow
    Write-Host "  (Este script NO compila desde E: ni C: a proposito.)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
if (-not (Test-Path (Join-Path $REPO 'node_modules\.bin\vite.cmd'))) {
    Write-Host "  [ERROR] Falta node_modules en el repo (corre 'npm install'):" -ForegroundColor Red
    Write-Host "          $REPO" -ForegroundColor Red
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

Write-Host "  Repo:   $REPO" -ForegroundColor Cyan
Write-Host "  Compilando (vite build)... puede tardar unos minutos." -ForegroundColor Cyan

Push-Location $REPO
try {
    $vite = Join-Path $REPO 'node_modules\.bin\vite.cmd'
    & cmd /c "`"$vite`" build"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [ERROR] vite build devolvio codigo $LASTEXITCODE." -ForegroundColor Red
        Write-Host "  Revisa el detalle arriba." -ForegroundColor Yellow
        exit 1
    }
}
finally {
    Pop-Location
}

$DIST_SRC = Join-Path $REPO 'dist'
if (-not (Test-Path (Join-Path $DIST_SRC 'index.html'))) {
    Write-Host "  [ERROR] No se genero $DIST_SRC\index.html." -ForegroundColor Red
    exit 1
}

Write-Host "  Copiando dist compilado a este paquete ->" -ForegroundColor Cyan
Write-Host "        $DIST_OUT" -ForegroundColor Gray
# El dist que genera vite NO incluye config.json/system_health.json
# (son de runtime); aun asi los excluimos por prolijidad y coherencia
# con la Regla de Oro.
robocopy $DIST_SRC $DIST_OUT /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP | Out-Null

Line
Write-Host "  [OK] dist listo en: $DIST_OUT" -ForegroundColor Green
Write-Host "  Ahora aplica con 1-APLICAR_UPGRADE.bat en las 3 PC." -ForegroundColor Green
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
