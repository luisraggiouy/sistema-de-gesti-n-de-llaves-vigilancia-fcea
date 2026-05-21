# ============================================================================
# Libreria: abrir_chrome_kiosk.ps1
# ----------------------------------------------------------------------------
# Lanza Google Chrome (o Edge como fallback) en el modo apropiado segun el
# hardware detectado:
#   - tactil       -> kiosk fullscreen en un monitor especifico
#   - tradicional  -> ventana normal maximizada
#   - desarrollo   -> ventana normal pequenia (para inspeccionar)
#
# Uso:
#   . "$PSScriptRoot\..\lib\abrir_chrome_kiosk.ps1"
#   Open-AppBrowser -Url "http://localhost:8080" -Hardware "tactil" -MonitorIndex 1
# ============================================================================

function Get-ChromePath {
    $candidates = @(
        "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "${env:LocalAppData}\Google\Chrome\Application\chrome.exe"
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

function Get-EdgePath {
    $candidates = @(
        "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe",
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

function Get-BrowserPath {
    $chrome = Get-ChromePath
    if ($chrome) { return @{ path = $chrome; type = 'chrome' } }
    $edge = Get-EdgePath
    if ($edge) { return @{ path = $edge; type = 'edge' } }
    return $null
}

function Get-MonitorBounds {
    param([int]$Index = 0)
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $screens = [System.Windows.Forms.Screen]::AllScreens
        if ($Index -ge $screens.Count) { $Index = 0 }
        $s = $screens[$Index]
        return @{
            x = [int]$s.Bounds.X
            y = [int]$s.Bounds.Y
            w = [int]$s.Bounds.Width
            h = [int]$s.Bounds.Height
        }
    } catch {
        return @{ x = 0; y = 0; w = 1024; h = 768 }
    }
}

function Open-AppBrowser {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [ValidateSet('tactil','tradicional','desarrollo')]
        [string]$Hardware = 'tradicional',
        [int]$MonitorIndex = 0,
        [string]$ProfileDir = "$env:LOCALAPPDATA\sistema-llaves-fcea\chrome-profile"
    )

    $browser = Get-BrowserPath
    if (-not $browser) {
        Write-Host "[ERROR] No se encontro Chrome ni Edge instalados." -ForegroundColor Red
        return $false
    }

    if (-not (Test-Path $ProfileDir)) {
        New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    }

    $bounds = Get-MonitorBounds -Index $MonitorIndex

    $args = @(
        "--user-data-dir=`"$ProfileDir`"",
        "--no-first-run",
        "--no-default-browser-check",
        "--disable-features=TranslateUI",
        "--disable-pinch",
        "--overscroll-history-navigation=0"
    )

    switch ($Hardware) {
        'tactil' {
            $args += @(
                "--kiosk",
                "--start-fullscreen",
                "--window-position=$($bounds.x),$($bounds.y)",
                "--window-size=$($bounds.w),$($bounds.h)",
                "--touch-events=enabled",
                "--disable-restore-session-state"
            )
        }
        'tradicional' {
            $args += @(
                "--start-maximized",
                "--window-position=$($bounds.x),$($bounds.y)"
            )
        }
        'desarrollo' {
            $args += @(
                "--window-position=$($bounds.x + 50),$($bounds.y + 50)",
                "--window-size=1280,800"
            )
        }
    }

    $args += $Url

    try {
        Start-Process -FilePath $browser.path -ArgumentList $args -ErrorAction Stop
        return $true
    } catch {
        Write-Host "[ERROR] No se pudo lanzar el navegador: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}
