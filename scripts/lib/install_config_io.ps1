# ============================================================================
# scripts\lib\install_config_io.ps1
# ----------------------------------------------------------------------------
# Funciones de E/S del archivo install_config.json y de su replica en la
# coleccion sistema_config de PocketBase. Estas son las UNICAS funciones que
# deberian leer / escribir esa configuracion. El instalador, el recuperador
# y los scripts de mantenimiento las usan.
#
# Uso:
#     . "$PSScriptRoot\lib\install_config_io.ps1"
#     $cfg = New-InstallConfig -Modo 'produccion' -Hardware 'tradicional' -Deteccion $det
#     Save-InstallConfigLocal -Config $cfg
#     Save-InstallConfigPocketBase -Config $cfg
#     $cfg2 = Read-InstallConfigLocal
#     $cfg3 = Read-InstallConfigPocketBase
# ============================================================================

# Constantes
$script:INSTALL_CONFIG_VERSION   = "1.0"
# Rutas posibles donde puede vivir el sistema. Las recorremos en orden y la
# primera que exista es la que ganamos. Si no existe ninguna se usa la
# primera de la lista para crear el directorio.
$script:INSTALL_BASE_PATHS = @(
    "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea",
    "C:\sistema-llaves-fcea"
)
$script:POCKETBASE_BASE_URL      = "http://127.0.0.1:8090"
$script:POCKETBASE_COLLECTION    = "sistema_config"
# PocketBase v0.22 acepta IDs custom solo si tienen exactamente 15 chars
# alfanumericos. "installcfg00001" -> 15 chars.
$script:POCKETBASE_RECORD_ID     = "installcfg00001"

# ----------------------------------------------------------------------------
# Get-InstallBasePath
# ----------------------------------------------------------------------------
# Resuelve dinamicamente cual es la ruta del sistema instalado. Si ninguna
# existe (instalacion limpia) devuelve la primera de la lista.
# ----------------------------------------------------------------------------
function Get-InstallBasePath {
    [CmdletBinding()]
    param()
    foreach ($p in $script:INSTALL_BASE_PATHS) {
        if (Test-Path (Join-Path $p "package.json")) { return $p }
    }
    return $script:INSTALL_BASE_PATHS[0]
}

function Get-InstallConfigDir  { Join-Path (Get-InstallBasePath) "config" }
function Get-InstallConfigFile { Join-Path (Get-InstallConfigDir) "install_config.json" }

# ----------------------------------------------------------------------------
# New-InstallConfig
# ----------------------------------------------------------------------------
# Construye el objeto de configuracion a partir de modo + hardware + el
# resultado de Get-DeteccionHardwareCompleta.
#
# Reglas de asignacion de monitores en modo produccion:
#   - Monitor #1 = vigilancia (con webcam, kiosk, abre /monitor)
#   - Monitor #2 = terminal_a (kiosk, abre /terminal)
#   - Monitor #3 = terminal_b (kiosk, abre /terminal)
#
# Si hay menos de 3 monitores, el instalador lo reporta pero igual genera
# las asignaciones que se puedan, dejando un warning en el campo "notas".
# ----------------------------------------------------------------------------
function New-InstallConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('produccion','desarrollo')]
        [string]$Modo,

        [Parameter(Mandatory=$true)]
        [ValidateSet('tactil','tradicional','desarrollo')]
        [string]$Hardware,

        [Parameter(Mandatory=$true)]
        $Deteccion,

        [string]$Notas = ""
    )

    # Construir asignacion de monitores
    $asignacion = @()
    $rolesProduccion = @(
        @{ rol='vigilancia'; url='/monitor';  webcam=$true  },
        @{ rol='terminal_a'; url='/terminal'; webcam=$false },
        @{ rol='terminal_b'; url='/terminal'; webcam=$false }
    )

    if ($Hardware -eq 'desarrollo' -or $Modo -eq 'desarrollo') {
        # Modo dev: una sola "asignacion virtual" apuntando a la raiz para
        # que el frontend muestre sus botones de alternancia.
        $primario = $Deteccion.monitores | Where-Object { $_.primary } | Select-Object -First 1
        if (-not $primario) { $primario = $Deteccion.monitores | Select-Object -First 1 }
        if ($primario) {
            $asignacion += [PSCustomObject]@{
                indice = 1
                rol    = 'desarrollo'
                url    = '/'
                kiosk  = $false
                webcam = $true
                x      = $primario.x
                y      = $primario.y
                ancho  = $primario.ancho
                alto   = $primario.alto
            }
        }
    } else {
        # Modo produccion (tactil o tradicional)
        $i = 0
        foreach ($m in $Deteccion.monitores) {
            if ($i -ge $rolesProduccion.Count) { break }
            $rol = $rolesProduccion[$i]
            $asignacion += [PSCustomObject]@{
                indice = $m.indice
                rol    = $rol.rol
                url    = $rol.url
                kiosk  = $true
                webcam = $rol.webcam
                x      = $m.x
                y      = $m.y
                ancho  = $m.ancho
                alto   = $m.alto
            }
            $i++
        }
    }

    return [PSCustomObject]@{
        version           = $script:INSTALL_CONFIG_VERSION
        modo              = $Modo
        hardware          = $Hardware
        fecha_instalacion = (Get-Date).ToString('o')
        pc_identifier     = $Deteccion.pc_identifier
        monitores         = [PSCustomObject]@{
            cantidad   = $Deteccion.cantidad_monitores
            asignacion = $asignacion
        }
        dispositivos      = [PSCustomObject]@{
            webcams           = $Deteccion.webcams
            cantidad_webcams  = $Deteccion.cantidad_webcams
            teclados_fisicos  = $Deteccion.cantidad_teclados_fisicos
            mouses_fisicos    = $Deteccion.cantidad_mouses_fisicos
            soporta_tactil    = $Deteccion.soporta_tactil
        }
        notas             = $Notas
    }
}

# ----------------------------------------------------------------------------
# Save-InstallConfigLocal
# ----------------------------------------------------------------------------
function Save-InstallConfigLocal {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)] $Config)

    $dir  = Get-InstallConfigDir
    $file = Get-InstallConfigFile
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $json = $Config | ConvertTo-Json -Depth 8
    # IMPORTANTE: escribimos UTF-8 SIN BOM. El frontend va a leer el JSON
    # con fetch() y JSON.parse falla si hay BOM (\uFEFF) al inicio.
    # Set-Content -Encoding UTF8 en Windows PowerShell 5 escribe CON BOM,
    # asi que usamos [System.IO.File]::WriteAllText con un encoding sin BOM.
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($file, $json, $utf8NoBom)
    return $file
}

# ----------------------------------------------------------------------------
# Read-InstallConfigLocal
# ----------------------------------------------------------------------------
# Devuelve el objeto $null si no existe o si esta corrupto.
# ----------------------------------------------------------------------------
function Read-InstallConfigLocal {
    [CmdletBinding()]
    param()

    # Buscamos en TODAS las rutas posibles (por compatibilidad con
    # instalaciones viejas en otra ruta).
    foreach ($base in $script:INSTALL_BASE_PATHS) {
        $f = Join-Path $base "config\install_config.json"
        if (Test-Path $f) {
            try {
                $raw = Get-Content -Path $f -Raw -Encoding UTF8
                return ($raw | ConvertFrom-Json)
            } catch {
                Write-Warning "install_config.json corrupto en $f : $_"
            }
        }
    }
    return $null
}

# ----------------------------------------------------------------------------
# Save-InstallConfigPocketBase
# ----------------------------------------------------------------------------
# Hace UPSERT en la coleccion sistema_config. Si PocketBase no esta corriendo
# silenciosamente devuelve $false (no es critico, el JSON local manda).
# ----------------------------------------------------------------------------
function Save-InstallConfigPocketBase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] $Config,
        [string]$BaseUrl = $script:POCKETBASE_BASE_URL
    )

    $url = "$BaseUrl/api/collections/$($script:POCKETBASE_COLLECTION)/records"
    $body = @{
        id                = $script:POCKETBASE_RECORD_ID
        modo              = $Config.modo
        hardware          = $Config.hardware
        monitores_json    = ($Config.monitores    | ConvertTo-Json -Depth 6 -Compress)
        dispositivos_json = ($Config.dispositivos | ConvertTo-Json -Depth 6 -Compress)
        version           = $Config.version
        fecha_instalacion = $Config.fecha_instalacion
        pc_identifier     = $Config.pc_identifier
        notas             = $Config.notas
    } | ConvertTo-Json -Depth 8

    # Intentar PATCH (si existe). Si 404, hacer POST (crear).
    try {
        $patchUrl = "$url/$($script:POCKETBASE_RECORD_ID)"
        $null = Invoke-RestMethod -Method Patch -Uri $patchUrl -Body $body `
                  -ContentType "application/json" -TimeoutSec 5 -ErrorAction Stop
        return $true
    } catch {
        # No existia o error -> intentar crear
        try {
            $null = Invoke-RestMethod -Method Post -Uri $url -Body $body `
                      -ContentType "application/json" -TimeoutSec 5 -ErrorAction Stop
            return $true
        } catch {
            Write-Warning "No se pudo guardar install_config en PocketBase: $_"
            return $false
        }
    }
}

# ----------------------------------------------------------------------------
# Read-InstallConfigPocketBase
# ----------------------------------------------------------------------------
function Read-InstallConfigPocketBase {
    [CmdletBinding()]
    param([string]$BaseUrl = $script:POCKETBASE_BASE_URL)

    try {
        $url = "$BaseUrl/api/collections/$($script:POCKETBASE_COLLECTION)/records/$($script:POCKETBASE_RECORD_ID)"
        $r = Invoke-RestMethod -Method Get -Uri $url -TimeoutSec 5 -ErrorAction Stop

        # Reconstruir el objeto al mismo formato que Read-InstallConfigLocal
        $monit = if ($r.monitores_json)    { $r.monitores_json    | ConvertFrom-Json } else { $null }
        $devs  = if ($r.dispositivos_json) { $r.dispositivos_json | ConvertFrom-Json } else { $null }

        return [PSCustomObject]@{
            version           = $r.version
            modo              = $r.modo
            hardware          = $r.hardware
            fecha_instalacion = $r.fecha_instalacion
            pc_identifier     = $r.pc_identifier
            monitores         = $monit
            dispositivos      = $devs
            notas             = $r.notas
        }
    } catch {
        return $null
    }
}

# ----------------------------------------------------------------------------
# Get-InstallConfigSmart
# ----------------------------------------------------------------------------
# Estrategia de lectura inteligente para el RECUPERADOR:
#   1) Intenta leer el JSON local.
#   2) Si no existe, intenta leer de PocketBase (si esta corriendo).
#   3) Si tampoco hay, devuelve $null.
# ----------------------------------------------------------------------------
function Get-InstallConfigSmart {
    [CmdletBinding()]
    param([string]$BaseUrl = $script:POCKETBASE_BASE_URL)

    $cfg = Read-InstallConfigLocal
    if ($cfg) { return [PSCustomObject]@{ origen='local'; config=$cfg } }

    $cfg = Read-InstallConfigPocketBase -BaseUrl $BaseUrl
    if ($cfg) { return [PSCustomObject]@{ origen='pocketbase'; config=$cfg } }

    return $null
}

# ----------------------------------------------------------------------------
# Show-InstallConfigResumen
# ----------------------------------------------------------------------------
function Show-InstallConfigResumen {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)] $Config)

    Write-Host ""
    Write-Host "  Configuracion del sistema:" -ForegroundColor Cyan
    Write-Host "  --------------------------" -ForegroundColor DarkCyan
    Write-Host ("    Modo            : {0}" -f $Config.modo)              -ForegroundColor White
    Write-Host ("    Hardware        : {0}" -f $Config.hardware)          -ForegroundColor White
    Write-Host ("    Fecha instalac. : {0}" -f $Config.fecha_instalacion) -ForegroundColor Gray
    Write-Host ("    PC              : {0}" -f $Config.pc_identifier)     -ForegroundColor Gray
    if ($Config.monitores -and $Config.monitores.asignacion) {
        Write-Host ("    Monitores ({0}):" -f $Config.monitores.cantidad) -ForegroundColor White
        foreach ($a in $Config.monitores.asignacion) {
            Write-Host ("      #{0} -> {1}  ({2}, {3}x{4})" -f `
                $a.indice, $a.rol, $a.url, $a.ancho, $a.alto) -ForegroundColor Gray
        }
    }
    if ($Config.notas) {
        Write-Host ("    Notas: {0}" -f $Config.notas) -ForegroundColor Yellow
    }
    Write-Host ""
}
