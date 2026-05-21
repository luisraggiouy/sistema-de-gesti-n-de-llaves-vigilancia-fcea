# ============================================================================
# Libreria: detectar_hardware.ps1
# ----------------------------------------------------------------------------
# Funciones para detectar el hardware de la PC donde se instala el sistema:
# monitores, resoluciones, presencia de pantalla tactil, webcams, impresoras
# y dispositivos de audio. Las funciones devuelven objetos PSObject listos
# para serializar a JSON (install_config.json) o mostrar al usuario.
#
# Uso:
#   . "$PSScriptRoot\..\lib\detectar_hardware.ps1"
#   $snap = Get-HardwareSnapshot
#   $snap | ConvertTo-Json -Depth 6
#
# NUNCA tira excepciones al llamador: cada funcion captura sus propios
# errores y devuelve arrays vacios + un campo "_error" si hace falta.
# ============================================================================

function Get-MonitoresInfo {
    $result = @()
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $screens = [System.Windows.Forms.Screen]::AllScreens
        $i = 0
        foreach ($s in $screens) {
            $result += [PSCustomObject]@{
                indice  = $i
                ancho   = [int]$s.Bounds.Width
                alto    = [int]$s.Bounds.Height
                x       = [int]$s.Bounds.X
                y       = [int]$s.Bounds.Y
                primary = [bool]$s.Primary
                nombre  = $s.DeviceName
            }
            $i++
        }
    } catch {
        $result = @([PSCustomObject]@{ _error = $_.Exception.Message })
    }
    return ,$result
}

function Test-TouchAvailable {
    try {
        $touch = Get-PnpDevice -Class HIDClass -ErrorAction SilentlyContinue |
                 Where-Object { $_.FriendlyName -match 'touch' -and $_.Status -eq 'OK' }
        if ($touch) { return $true }

        # Fallback: Win32_PointingDevice
        $pd = Get-CimInstance Win32_PointingDevice -ErrorAction SilentlyContinue |
              Where-Object { $_.Description -match 'touch' }
        if ($pd) { return $true }

        # Fallback: GetSystemMetrics SM_DIGITIZER
        try {
            $sig = '[DllImport("user32.dll")] public static extern int GetSystemMetrics(int nIndex);'
            $type = Add-Type -MemberDefinition $sig -Name UserMetrics -Namespace Native -PassThru -ErrorAction Stop
            $digitizer = $type::GetSystemMetrics(94)  # SM_DIGITIZER
            return (($digitizer -band 0x80) -ne 0)    # NID_READY
        } catch {
            return $false
        }
    } catch {
        return $false
    }
}

function Get-WebcamsInfo {
    $result = @()
    try {
        $cams = Get-PnpDevice -Class Camera -Status OK -ErrorAction SilentlyContinue
        if (-not $cams) {
            $cams = Get-PnpDevice -Class Image -Status OK -ErrorAction SilentlyContinue |
                    Where-Object { $_.FriendlyName -match '(cam|webcam|video)' }
        }
        foreach ($c in $cams) {
            $result += [PSCustomObject]@{
                nombre = $c.FriendlyName
                id     = $c.InstanceId
            }
        }
    } catch {}
    return ,$result
}

function Get-ImpresorasInfo {
    $result = @()
    try {
        $printers = Get-Printer -ErrorAction SilentlyContinue
        foreach ($p in $printers) {
            $result += [PSCustomObject]@{
                nombre   = $p.Name
                driver   = $p.DriverName
                default  = [bool]$p.IsDefault
                offline  = [bool]$p.PrinterStatus -ne 'Normal'
            }
        }
    } catch {}
    return ,$result
}

function Get-AudioDevicesInfo {
    $result = @()
    try {
        $audio = Get-PnpDevice -Class AudioEndpoint -Status OK -ErrorAction SilentlyContinue
        foreach ($a in $audio) {
            $result += [PSCustomObject]@{
                nombre = $a.FriendlyName
                id     = $a.InstanceId
            }
        }
    } catch {}
    return ,$result
}

function Get-PCIdentifier {
    try {
        $hostname = $env:COMPUTERNAME
        $user     = $env:USERNAME
        return "$hostname / $user"
    } catch {
        return "unknown"
    }
}

function Get-HardwareSnapshot {
    [PSCustomObject]@{
        monitores      = (Get-MonitoresInfo)
        touch_available = (Test-TouchAvailable)
        webcams        = (Get-WebcamsInfo)
        impresoras     = (Get-ImpresorasInfo)
        audio          = (Get-AudioDevicesInfo)
        pc_identifier  = (Get-PCIdentifier)
        timestamp      = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    }
}

function Suggest-HardwareMode {
    # Heuristica para sugerir "tactil" vs "tradicional":
    # - Si hay touch detectado -> tactil
    # - Si hay 2+ monitores y uno de baja resolucion (<= 1280x1024) -> tactil
    # - En otro caso -> tradicional
    param([PSObject]$Snapshot)
    if ($null -eq $Snapshot) { $Snapshot = Get-HardwareSnapshot }

    if ($Snapshot.touch_available) { return 'tactil' }

    $smallSecondary = $Snapshot.monitores | Where-Object {
        -not $_.primary -and $_.ancho -le 1280
    }
    if ($Snapshot.monitores.Count -ge 2 -and $smallSecondary) {
        return 'tactil'
    }
    return 'tradicional'
}
