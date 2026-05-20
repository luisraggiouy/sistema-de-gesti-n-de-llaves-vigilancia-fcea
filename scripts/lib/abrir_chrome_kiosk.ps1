# ============================================================================
# scripts\lib\abrir_chrome_kiosk.ps1
# ----------------------------------------------------------------------------
# Funciones reusables para abrir Google Chrome en cada uno de los monitores
# fisicos, en modo kiosk (pantalla completa, sin barras), apuntando a las
# distintas vistas del sistema (/monitor, /terminal, /dashboard).
#
# Uso:
#     . "$PSScriptRoot\lib\abrir_chrome_kiosk.ps1"
#     Open-SistemaEnMonitores -Config $instalConfig -BaseUrl "http://localhost:8080"
#
# La idea es que cada Chrome use un --user-data-dir distinto (uno por
# monitor) para que sean ventanas totalmente independientes y sus cookies/
# sesiones no se mezclen.
# ============================================================================

# ----------------------------------------------------------------------------
# Find-ChromeExecutable
# ----------------------------------------------------------------------------
function Find-ChromeExecutable {
    [CmdletBinding()]
    param()

    $candidatos = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
    foreach ($c in $candidatos) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    return $null
}

# ----------------------------------------------------------------------------
# Wait-FrontendReady
# ----------------------------------------------------------------------------
# Espera (con timeout) hasta que el frontend conteste 200 en BaseUrl.
# Devuelve $true si llego a quedar listo, $false si timeout.
# ----------------------------------------------------------------------------
function Wait-FrontendReady {
    [CmdletBinding()]
    param(
        [string]$BaseUrl   = "http://localhost:8080",
        [int]   $TimeoutSec = 120
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    Write-Host "  Esperando que el frontend este listo en $BaseUrl " -NoNewline -ForegroundColor Cyan
    while ((Get-Date) -lt $deadline) {
        try {
            $r = Invoke-WebRequest -Uri $BaseUrl -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
            if ($r.StatusCode -eq 200) {
                Write-Host " [OK]" -ForegroundColor Green
                return $true
            }
        } catch {}
        Write-Host "." -NoNewline -ForegroundColor DarkCyan
        Start-Sleep -Seconds 2
    }
    Write-Host " [TIMEOUT]" -ForegroundColor Yellow
    return $false
}

# ----------------------------------------------------------------------------
# Open-ChromeEnMonitor
# ----------------------------------------------------------------------------
# Abre UNA ventana de Chrome en kiosk dirigida a una URL, posicionada en
# coordenadas X,Y exactas (la posicion del monitor destino).
# ----------------------------------------------------------------------------
function Open-ChromeEnMonitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string]$ChromeExe,
        [Parameter(Mandatory=$true)] [string]$Url,
        [Parameter(Mandatory=$true)] [int]   $X,
        [Parameter(Mandatory=$true)] [int]   $Y,
        [Parameter(Mandatory=$true)] [int]   $Ancho,
        [Parameter(Mandatory=$true)] [int]   $Alto,
        [Parameter(Mandatory=$true)] [string]$ProfileDir,
        [switch]$Kiosk
    )

    if (-not (Test-Path $ProfileDir)) {
        New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    }

    # NO usar $args (variable automatica de PowerShell). Usamos $chromeArgs.
    $chromeArgs = @(
        "--user-data-dir=`"$ProfileDir`"",
        "--no-first-run",
        "--no-default-browser-check",
        "--disable-features=TranslateUI",
        "--disable-session-crashed-bubble",
        "--disable-infobars",
        "--window-position=$X,$Y",
        "--window-size=$Ancho,$Alto"
    )
    if ($Kiosk) { $chromeArgs += "--kiosk" }
    $chromeArgs += $Url

    Start-Process -FilePath $ChromeExe -ArgumentList $chromeArgs -WindowStyle Normal | Out-Null
}

# ----------------------------------------------------------------------------
# Open-SistemaEnMonitores
# ----------------------------------------------------------------------------
# Abre el sistema completo segun el install_config:
#   - Modo desarrollo  -> 1 sola ventana en monitor primario, no-kiosk,
#                         apuntando a la pagina raiz que muestra los botones
#                         para alternar entre Monitor / Terminal / Dashboard.
#   - Modo produccion  -> Una ventana kiosk por cada entrada del array
#                         monitores.asignacion del config.
# ----------------------------------------------------------------------------
function Open-SistemaEnMonitores {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] $Config,
        [string]$BaseUrl    = "http://localhost:8080",
        [string]$ProfilesDir = "$env:LOCALAPPDATA\SistemaLlavesFCEA\chrome_profiles"
    )

    $chrome = Find-ChromeExecutable
    if (-not $chrome) {
        Write-Warning "No se encontro Google Chrome instalado. Abriendo en navegador predeterminado."
        Start-Process $BaseUrl
        return
    }

    if (-not (Test-Path $ProfilesDir)) {
        New-Item -ItemType Directory -Path $ProfilesDir -Force | Out-Null
    }

    if ($Config.modo -eq 'desarrollo' -or $Config.hardware -eq 'desarrollo') {
        # Una sola ventana en modo dev.
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        $primary = [System.Windows.Forms.Screen]::PrimaryScreen
        Open-ChromeEnMonitor -ChromeExe $chrome -Url $BaseUrl `
            -X $primary.Bounds.X -Y $primary.Bounds.Y `
            -Ancho $primary.Bounds.Width -Alto $primary.Bounds.Height `
            -ProfileDir (Join-Path $ProfilesDir "dev")
        return
    }

    # Modo produccion -> abrir una ventana kiosk por monitor asignado.
    if (-not $Config.monitores -or -not $Config.monitores.asignacion) {
        Write-Warning "El config no tiene monitores.asignacion. Abriendo solo /monitor."
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        $p = [System.Windows.Forms.Screen]::PrimaryScreen
        Open-ChromeEnMonitor -ChromeExe $chrome -Url "$BaseUrl/monitor" `
            -X $p.Bounds.X -Y $p.Bounds.Y `
            -Ancho $p.Bounds.Width -Alto $p.Bounds.Height `
            -ProfileDir (Join-Path $ProfilesDir "monitor") -Kiosk
        return
    }

    foreach ($asig in $Config.monitores.asignacion) {
        $url = "$BaseUrl$($asig.url)"
        $profileDir = Join-Path $ProfilesDir ("monitor_" + $asig.indice + "_" + $asig.rol)
        Write-Host ("  Abriendo monitor #{0} ({1}) -> {2}" -f $asig.indice, $asig.rol, $url) -ForegroundColor Cyan
        Open-ChromeEnMonitor -ChromeExe $chrome -Url $url `
            -X $asig.x -Y $asig.y `
            -Ancho $asig.ancho -Alto $asig.alto `
            -ProfileDir $profileDir -Kiosk
        Start-Sleep -Milliseconds 800   # damos un respiro a Chrome entre lanzamientos
    }
}

# ----------------------------------------------------------------------------
# Stop-ChromeKioskInstancias
# ----------------------------------------------------------------------------
# Cierra todas las instancias de Chrome lanzadas por nuestros perfiles.
# Util para reinicios automaticos por watchdog.
# ----------------------------------------------------------------------------
function Stop-ChromeKioskInstancias {
    [CmdletBinding()]
    param(
        [string]$ProfilesDir = "$env:LOCALAPPDATA\SistemaLlavesFCEA\chrome_profiles"
    )
    try {
        $procs = Get-CimInstance Win32_Process -Filter "Name='chrome.exe'" -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            if ($p.CommandLine -and $p.CommandLine -match [regex]::Escape($ProfilesDir)) {
                Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}
}
