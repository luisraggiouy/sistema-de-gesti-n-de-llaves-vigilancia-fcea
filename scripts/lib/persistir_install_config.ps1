# ============================================================================
# persistir_install_config.ps1
# ----------------------------------------------------------------------------
# Wrapper invocable desde INSTALAR.bat (modo -File) que:
#   1) Detecta hardware (monitores, webcams, impresoras, audio)
#   2) Arma install_config.json
#   3) Lo escribe en C:\sistema-llaves-fcea\config\
#   4) Intenta sincronizarlo a PocketBase (best-effort, no falla si PB no esta)
#
# Se llama asi desde el .bat (sin "^" de continuacion de linea):
#   powershell -NoProfile -ExecutionPolicy Bypass -File "%LIB_PERSIST%" -Modo "produccion" -Hardware "tactil"
# ============================================================================

param(
    [Parameter(Mandatory=$true)][string]$Modo,
    [Parameter(Mandatory=$true)][string]$Hardware,
    [string]$Version = '2.1.0'
)

$ErrorActionPreference = 'Continue'

# Resolver rutas a las dos librerias hermanas
$here       = Split-Path -Parent $MyInvocation.MyCommand.Path
$libDetect  = Join-Path $here 'detectar_hardware.ps1'
$libCfgIo   = Join-Path $here 'install_config_io.ps1'

if (-not (Test-Path $libDetect)) {
    Write-Host "[AVISO] No se encontro detectar_hardware.ps1 ($libDetect). Omito install_config.json." -ForegroundColor Yellow
    exit 0
}
if (-not (Test-Path $libCfgIo)) {
    Write-Host "[AVISO] No se encontro install_config_io.ps1 ($libCfgIo). Omito install_config.json." -ForegroundColor Yellow
    exit 0
}

try {
    . $libDetect
    . $libCfgIo

    $snap = Get-HardwareSnapshot
    $cfg  = New-InstallConfig -Modo $Modo -Hardware $Hardware -Version $Version -HardwareSnapshot $snap

    # Marcar fecha de instalacion ISO 8601 si todavia no existe.
    # check_system_health.ps1 lo usa para no alarmar con "No hay backups"
    # durante los primeros 7 dias post-instalacion.
    if ($cfg -is [hashtable]) {
        if (-not $cfg.ContainsKey('installed_at')) {
            $cfg['installed_at'] = (Get-Date).ToString('o')
        }
    } else {
        if (-not ($cfg.PSObject.Properties.Name -contains 'installed_at')) {
            $cfg | Add-Member -NotePropertyName 'installed_at' -NotePropertyValue ((Get-Date).ToString('o')) -Force
        }
    }

    $ok = Write-InstallConfig -Config $cfg

    if ($ok) {
        Write-Host "[OK] install_config.json escrito en C:\sistema-llaves-fcea\config\" -ForegroundColor Green
    } else {
        Write-Host "[AVISO] No se pudo escribir install_config.json (no critico)." -ForegroundColor Yellow
    }

    # Sincronizar a PocketBase si esta corriendo. No imprime errores rojos
    # si PB no responde; simplemente lo omite.
    Sync-InstallConfigToPocketBase -Config $cfg | Out-Null

    exit 0
}
catch {
    Write-Host "[AVISO] persistir_install_config: $($_.Exception.Message)" -ForegroundColor Yellow
    exit 0  # nunca fallamos: este paso es decorativo / informativo
}
