# ============================================================================
# MARCAR_MANTENIMIENTO_ANUAL.ps1
# Sistema de Gestion de Llaves FCEA
# ============================================================================
# Registra la fecha de HOY como ultima ejecucion del mantenimiento anual
# (vacuum SQLite + archivado historico + verificacion de integridad +
# Windows Update). Esto silencia las alertas amarilla/roja "Mantenimiento
# anual pendiente / vencido" del indicador de salud del Monitor de Vigilancia
# por aproximadamente un ano.
#
# Cuando ejecutarlo:
#   - Despues de completar el procedimiento descrito en
#     docs/guia_mantenimiento_paso_a_paso.md § 5.
#
# Como ejecutarlo:
#   1. Abrir PowerShell como administrador en C:\sistema-llaves-fcea
#   2. .\scripts\maintenance\MARCAR_MANTENIMIENTO_ANUAL.ps1
#
# El script tambien fuerza una re-evaluacion del check de salud para que
# el cambio se vea inmediatamente en pantalla.
# ============================================================================

$ErrorActionPreference = "Continue"

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptPath)
$MarkerFile  = Join-Path $ProjectRoot "pocketbase\maintenance\last_annual_maintenance.txt"
$HealthCheck = Join-Path $ProjectRoot "pocketbase\maintenance\check_system_health.ps1"

# Asegurar que existe el directorio
$MarkerDir = Split-Path -Parent $MarkerFile
if (-not (Test-Path $MarkerDir)) {
    New-Item -ItemType Directory -Path $MarkerDir -Force | Out-Null
}

$Today = Get-Date -Format "yyyy-MM-dd"
Set-Content -Path $MarkerFile -Value $Today -Encoding UTF8

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host " [OK] Mantenimiento anual registrado: $Today" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host " Marcador escrito en:" -ForegroundColor Cyan
Write-Host "   $MarkerFile" -ForegroundColor Gray
Write-Host ""
Write-Host " El indicador de salud del Monitor de Vigilancia ya no" -ForegroundColor Cyan
Write-Host " mostrara la alerta 'Mantenimiento anual pendiente' por" -ForegroundColor Cyan
Write-Host " aproximadamente un ano." -ForegroundColor Cyan
Write-Host ""

# Re-ejecutar el check de salud para refrescar el JSON
if (Test-Path $HealthCheck) {
    Write-Host " Refrescando estado de salud..." -ForegroundColor Cyan
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $HealthCheck | Out-Null
    Write-Host " [OK] system_health.json actualizado." -ForegroundColor Green
    Write-Host ""
}

Write-Host " Recuerde planificar el proximo mantenimiento anual en 12 meses." -ForegroundColor Yellow
Write-Host ""
