# ============================================================
#  FIX - El Monitor del Sistema seguia pidiendo la vieja "semilla"
#  ------------------------------------------------------------
#  Corrige dos archivos:
#   1) En el MONITOR (C:\sistema-llaves-fcea):
#        pocketbase\maintenance\check_system_health.ps1
#      -> textos "semilla" -> "ACTUALIZAR DATOS" (cosmetico).
#   2) En el PENDRIVE DE RESCATE (donde vive este fix o E:):
#        sistema-llaves-fcea\scripts\pendrive\ACTUALIZAR_DATOS_RESCATE.ps1
#      -> ahora escribe el marcador _SEMILLA_INFO.txt en
#         C:\ProgramData\FCEA-Sistema-Llaves\pb_data\ para que el
#         Monitor "vea" el resguardo y la advertencia desaparezca.
#
#  Correr en el MONITOR VIGILANCIA, como Administrador, desde el
#  pendrive "cable" (D:). NO toca datos ni config.json.
# ============================================================
$ErrorActionPreference = 'Stop'
function Ok($m)   { Write-Host $m -ForegroundColor Green }
function Info($m) { Write-Host $m -ForegroundColor Cyan }
function Warn($m) { Write-Host $m -ForegroundColor Yellow }

$here = $PSScriptRoot

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  FIX - Advertencia 'semilla' en el Monitor del Sistema" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Info ("  PC: " + $env:COMPUTERNAME + "   (" + (Get-Date -Format 'yyyy-MM-dd HH:mm') + ")")
Write-Host ""

# --- 1) Actualizar check_system_health.ps1 en la instalacion del Monitor ---
$installDir = 'C:\sistema-llaves-fcea'
$destHealth = Join-Path $installDir 'pocketbase\maintenance\check_system_health.ps1'
$srcHealth  = Join-Path $here 'check_system_health.ps1'

if (-not (Test-Path $installDir)) {
    Warn "[1/2] No existe $installDir en esta PC."
    Warn "      Este paso solo aplica al MONITOR VIGILANCIA. Se omite."
} elseif (-not (Test-Path $srcHealth)) {
    throw "No se encontro $srcHealth en el fix."
} else {
    Copy-Item $srcHealth $destHealth -Force
    Ok  "[1/2] check_system_health.ps1 actualizado en el Monitor."
    Ok  "      -> $destHealth"
}

# --- 2) Actualizar ACTUALIZAR_DATOS_RESCATE.ps1 en el PENDRIVE DE RESCATE ---
# El pendrive de rescate puede estar en cualquier letra. Buscamos donde exista
# el archivo objetivo. Como el fix trae la version corregida, la copiamos.
Write-Host ""
Info "[2/2] Actualizando el script del pendrive de RESCATE..."
$srcRescate = Join-Path $here 'ACTUALIZAR_DATOS_RESCATE.ps1'
if (-not (Test-Path $srcRescate)) { throw "No se encontro $srcRescate en el fix." }

$destinos = @()
foreach ($letra in 'D','E','F','G','H','I') {
    $cand = "${letra}:\sistema-llaves-fcea\scripts\pendrive\ACTUALIZAR_DATOS_RESCATE.ps1"
    if (Test-Path $cand) { $destinos += $cand }
}

if ($destinos.Count -eq 0) {
    Warn "      No se encontro ningun pendrive de RESCATE conectado con"
    Warn "      sistema-llaves-fcea\scripts\pendrive\ACTUALIZAR_DATOS_RESCATE.ps1"
    Warn "      Enchufe el pendrive de RESCATE y vuelva a correr este fix,"
    Warn "      o copie manualmente el archivo del fix a ese pendrive."
} else {
    foreach ($d in $destinos) {
        Copy-Item $srcRescate $d -Force
        Ok "      Actualizado: $d"
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Ok "  LISTO. Ahora, EN EL MONITOR, enchufe el pendrive de RESCATE"
Ok "  y ejecute 'ACTUALIZAR DATOS.bat' una vez. Luego revise el"
Ok "  Monitor del Sistema: la advertencia debe desaparecer."
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Presione ENTER para cerrar" | Out-Null
