# ============================================================================
# Libreria: install_config_io.ps1
# ----------------------------------------------------------------------------
# Lectura, escritura y sincronizacion del archivo install_config.json que
# describe como esta configurada esta PC concretamente (modo, hardware,
# monitores, dispositivos). La fuente de verdad es:
#   1) C:\sistema-llaves-fcea\config\install_config.json (local, rapido)
#   2) Coleccion sistema_config en PocketBase (respaldo, se sincroniza)
#
# Uso:
#   . "$PSScriptRoot\..\lib\install_config_io.ps1"
#   $cfg = Read-InstallConfig
#   if (-not $cfg) { $cfg = Restore-InstallConfigFromPocketBase -PbUrl "http://localhost:8090" }
# ============================================================================

$script:DEFAULT_CONFIG_PATH = "C:\sistema-llaves-fcea\config\install_config.json"
$script:DEFAULT_PB_URL      = "http://localhost:8090"
$script:PB_COLLECTION       = "sistema_config"
$script:PB_RECORD_ID_HINT   = "install_config"

function Get-DefaultInstallConfigPath {
    return $script:DEFAULT_CONFIG_PATH
}

function Read-InstallConfig {
    param([string]$Path = $script:DEFAULT_CONFIG_PATH)
    if (-not (Test-Path $Path)) { return $null }
    try {
        $raw = Get-Content -Path $Path -Raw -Encoding UTF8
        return ($raw | ConvertFrom-Json)
    } catch {
        Write-Host "[AVISO] install_config.json existe pero no se pudo parsear: $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}

function Write-InstallConfig {
    param(
        [Parameter(Mandatory=$true)][PSObject]$Config,
        [string]$Path = $script:DEFAULT_CONFIG_PATH
    )
    try {
        $dir = Split-Path -Parent $Path
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $json = $Config | ConvertTo-Json -Depth 10
        $json | Out-File -FilePath $Path -Encoding UTF8 -Force
        return $true
    } catch {
        Write-Host "[ERROR] No se pudo escribir install_config: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function New-InstallConfig {
    param(
        [ValidateSet('produccion','desarrollo')][string]$Modo = 'produccion',
        [ValidateSet('tactil','tradicional','desarrollo')][string]$Hardware = 'tradicional',
        [string]$Version = '1.0.0',
        [PSObject]$HardwareSnapshot = $null,
        [string]$Notas = ''
    )
    $cfg = [PSCustomObject]@{
        modo               = $Modo
        hardware           = $Hardware
        version            = $Version
        fecha_instalacion  = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        pc_identifier      = "$env:COMPUTERNAME / $env:USERNAME"
        monitores          = if ($HardwareSnapshot) { $HardwareSnapshot.monitores } else { @() }
        dispositivos       = if ($HardwareSnapshot) {
                                [PSCustomObject]@{
                                    webcams    = $HardwareSnapshot.webcams
                                    impresoras = $HardwareSnapshot.impresoras
                                    audio      = $HardwareSnapshot.audio
                                }
                             } else {
                                [PSCustomObject]@{ webcams = @(); impresoras = @(); audio = @() }
                             }
        notas              = $Notas
    }
    return $cfg
}

# ----------------------------------------------------------------------------
# Sincronizacion con PocketBase (best-effort, NO rompe si PB esta caido)
# ----------------------------------------------------------------------------

function Test-PocketBaseAlive {
    param([string]$PbUrl = $script:DEFAULT_PB_URL)
    try {
        $r = Invoke-WebRequest -Uri "$PbUrl/api/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        return ($r.StatusCode -eq 200)
    } catch { return $false }
}

function Sync-InstallConfigToPocketBase {
    param(
        [Parameter(Mandatory=$true)][PSObject]$Config,
        [string]$PbUrl = $script:DEFAULT_PB_URL
    )
    if (-not (Test-PocketBaseAlive -PbUrl $PbUrl)) {
        Write-Host "[INFO] PocketBase no responde, salto sincronizacion." -ForegroundColor DarkGray
        return $false
    }
    try {
        $listUrl = "$PbUrl/api/collections/$($script:PB_COLLECTION)/records?perPage=1"
        $existing = Invoke-RestMethod -Uri $listUrl -Method GET -TimeoutSec 5 -ErrorAction Stop

        $body = @{
            modo               = $Config.modo
            hardware           = $Config.hardware
            monitores_json     = ($Config.monitores | ConvertTo-Json -Depth 6 -Compress)
            dispositivos_json  = ($Config.dispositivos | ConvertTo-Json -Depth 6 -Compress)
            version            = $Config.version
            fecha_instalacion  = $Config.fecha_instalacion
            pc_identifier      = $Config.pc_identifier
            notas              = $Config.notas
        } | ConvertTo-Json -Depth 6

        if ($existing.totalItems -gt 0) {
            $recId = $existing.items[0].id
            $patchUrl = "$PbUrl/api/collections/$($script:PB_COLLECTION)/records/$recId"
            Invoke-RestMethod -Uri $patchUrl -Method PATCH -Body $body -ContentType "application/json" -TimeoutSec 5 -ErrorAction Stop | Out-Null
        } else {
            $postUrl = "$PbUrl/api/collections/$($script:PB_COLLECTION)/records"
            Invoke-RestMethod -Uri $postUrl -Method POST -Body $body -ContentType "application/json" -TimeoutSec 5 -ErrorAction Stop | Out-Null
        }
        return $true
    } catch {
        Write-Host "[AVISO] Fallo sincronizando a PocketBase: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

function Restore-InstallConfigFromPocketBase {
    param([string]$PbUrl = $script:DEFAULT_PB_URL)
    if (-not (Test-PocketBaseAlive -PbUrl $PbUrl)) { return $null }
    try {
        $listUrl = "$PbUrl/api/collections/$($script:PB_COLLECTION)/records?perPage=1&sort=-updated"
        $r = Invoke-RestMethod -Uri $listUrl -Method GET -TimeoutSec 5 -ErrorAction Stop
        if ($r.totalItems -lt 1) { return $null }
        $rec = $r.items[0]
        $monitores    = if ($rec.monitores_json)    { $rec.monitores_json    | ConvertFrom-Json } else { @() }
        $dispositivos = if ($rec.dispositivos_json) { $rec.dispositivos_json | ConvertFrom-Json } else { [PSCustomObject]@{ webcams=@(); impresoras=@(); audio=@() } }
        return [PSCustomObject]@{
            modo               = $rec.modo
            hardware           = $rec.hardware
            version            = $rec.version
            fecha_instalacion  = $rec.fecha_instalacion
            pc_identifier      = $rec.pc_identifier
            monitores          = $monitores
            dispositivos       = $dispositivos
            notas              = $rec.notas
        }
    } catch {
        Write-Host "[AVISO] No se pudo restaurar desde PB: $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}

# ----------------------------------------------------------------------------
# Tambien escribimos una copia en public/install_config.json del frontend
# para que la SPA pueda leerlo via fetch sin tocar PB.
# ----------------------------------------------------------------------------

function Publish-InstallConfigForFrontend {
    param(
        [Parameter(Mandatory=$true)][PSObject]$Config,
        [string]$FrontendDir = "C:\sistema-llaves-fcea\frontend\dist"
    )
    try {
        if (-not (Test-Path $FrontendDir)) { return $false }
        $target = Join-Path $FrontendDir "install_config.json"
        $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $target -Encoding UTF8 -Force
        return $true
    } catch {
        Write-Host "[AVISO] No se pudo publicar install_config para el frontend: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}
