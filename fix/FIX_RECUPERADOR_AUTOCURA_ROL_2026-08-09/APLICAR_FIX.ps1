# =============================================================
# APLICAR_FIX.ps1 - FIX Recuperador Autocura de Rol (2026-08-09)
# -------------------------------------------------------------
# Reemplaza la copia INSTALADA del reparador de conexion:
#   C:\sistema-llaves-fcea\scripts\lib\reparar_conexion_servidor.ps1
# por la version reforzada que ademas de la IP, REAFIRMA el rol
# de la PC segun su nombre (terminal-a / terminal-b / dashboard).
#
# Hace backup del archivo actual antes de pisarlo.
# NO toca config.json, NO toca datos, NO reinstala nada.
# Escribe un log en el pendrive (_RESULTADOS al lado del fix).
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'APLICAR FIX Recuperador Autocura Rol'

$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$carpetaLog = Join-Path $PSScriptRoot '_RESULTADOS'
if (-not (Test-Path $carpetaLog)) { New-Item -ItemType Directory -Path $carpetaLog -Force | Out-Null }
$logPath = Join-Path $carpetaLog ("LOG_APLICAR_FIX_RECUPERADOR_{0}_{1}.log" -f $env:COMPUTERNAME, $stamp)
try { Start-Transcript -Path $logPath -Force | Out-Null } catch {}

function Line { Write-Host ('=' * 62) -ForegroundColor Yellow }
Line; Write-Host "  APLICAR FIX RECUPERADOR AUTOCURA ROL - $env:COMPUTERNAME" -ForegroundColor Yellow; Line
Write-Host "  Log: $logPath" -ForegroundColor Gray
Write-Host ""

$origen  = Join-Path $PSScriptRoot 'reparar_conexion_servidor.ps1'
$destino = 'C:\sistema-llaves-fcea\scripts\lib\reparar_conexion_servidor.ps1'

if (-not (Test-Path $origen)) {
    Write-Host "  [ERROR] No encuentro el archivo nuevo junto a este script:" -ForegroundColor Red
    Write-Host "          $origen" -ForegroundColor Red
    try { Stop-Transcript | Out-Null } catch {}
    Write-Host "`nENTER..."; [void][System.Console]::ReadLine(); exit 1
}

$dirDestino = Split-Path -Parent $destino
if (-not (Test-Path $dirDestino)) {
    Write-Host "  [ERROR] No existe la carpeta de instalacion:" -ForegroundColor Red
    Write-Host "          $dirDestino" -ForegroundColor Red
    Write-Host "          Esta PC no parece tener el sistema instalado." -ForegroundColor Red
    try { Stop-Transcript | Out-Null } catch {}
    Write-Host "`nENTER..."; [void][System.Console]::ReadLine(); exit 1
}

Write-Host "  Origen : $origen" -ForegroundColor Cyan
Write-Host "  Destino: $destino" -ForegroundColor Cyan
Write-Host ""

# Backup del archivo actual (si existe)
if (Test-Path $destino) {
    $bak = "$destino.bak_$stamp"
    try {
        (Get-Item $destino).IsReadOnly = $false
    } catch {}
    Copy-Item -Path $destino -Destination $bak -Force
    Write-Host "  [OK] Backup del actual: $bak" -ForegroundColor Green
} else {
    Write-Host "  [INFO] No habia archivo previo; se crea nuevo." -ForegroundColor Gray
}

# Copiar la version nueva
Copy-Item -Path $origen -Destination $destino -Force

# Verificar que quedo la version nueva (busca el marcador de la novedad)
$contenido = Get-Content -Path $destino -Raw
if ($contenido -match 'Get-RolPorHostname') {
    Write-Host "  [OK] Recuperador reforzado instalado correctamente." -ForegroundColor Green
} else {
    Write-Host "  [ERROR] La copia no contiene la funcion nueva. Revisa manualmente." -ForegroundColor Red
}

Line
Write-Host "  LISTO." -ForegroundColor Green
Write-Host ""
Write-Host "  COMO PROBARLO en una TERMINAL (A o B):" -ForegroundColor Cyan
Write-Host "   1. Corre HERRAMIENTAS_RED\DIAGNOSTICO_FORENSE para ver el rol actual." -ForegroundColor White
Write-Host "   2. (Opcional, para forzar la prueba) desconfigura el rol a proposito:" -ForegroundColor White
Write-Host "      corre REPARAR_ROL_CONFIG y elegi un rol EQUIVOCADO, o edita el rol." -ForegroundColor White
Write-Host "   3. Ejecuta el RECUPERAR / REPARAR CONEXION SERVIDOR como siempre." -ForegroundColor White
Write-Host "   4. Verifica que el rol quedo CORRECTO segun el nombre de la PC." -ForegroundColor White
Write-Host ""
Write-Host "  Para revertir: renombra el archivo .bak_$stamp sobre el original." -ForegroundColor Gray
try { Stop-Transcript | Out-Null } catch {}
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
