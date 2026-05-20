# ============================================================================
# scripts\lib\detectar_hardware.ps1
# ----------------------------------------------------------------------------
# Funciones reusables para detectar hardware fisico en la PC donde se instala
# o se reinstala el Sistema de Gestion de Llaves FCEA.
#
# Detecta:
#   - Monitores conectados (cantidad, resolucion, posicion X/Y, primary)
#   - Camaras / webcams
#   - Teclados fisicos conectados (USB / PS2)
#   - Mouses fisicos conectados (USB / PS2)
#
# Este archivo se "dot-source-ea" desde otros scripts:
#     . "$PSScriptRoot\lib\detectar_hardware.ps1"
#
# Devuelve siempre objetos PSCustomObject estructurados, listos para
# serializar a JSON con ConvertTo-Json.
# ============================================================================

# ----------------------------------------------------------------------------
# Get-MonitoresFisicos
# ----------------------------------------------------------------------------
# Devuelve un arreglo de objetos describiendo cada monitor conectado, en el
# orden que les da Windows. Usa System.Windows.Forms.Screen porque entrega
# la posicion (Bounds.X, Bounds.Y) y resolucion real, lo que necesitamos
# despues para abrir Chrome con --window-position en cada pantalla.
# ----------------------------------------------------------------------------
function Get-MonitoresFisicos {
    [CmdletBinding()]
    param()

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    } catch {
        Write-Warning "No se pudo cargar System.Windows.Forms: $_"
        return @()
    }

    $screens = [System.Windows.Forms.Screen]::AllScreens
    if (-not $screens) { return @() }

    # Ordenar por posicion X (izquierda a derecha) para que el monitor mas
    # a la izquierda fisicamente sea siempre el #1.
    $screens = $screens | Sort-Object { $_.Bounds.X }

    $resultado = @()
    $i = 1
    foreach ($s in $screens) {
        $resultado += [PSCustomObject]@{
            indice       = $i
            nombre       = $s.DeviceName
            primary      = [bool]$s.Primary
            x            = [int]$s.Bounds.X
            y            = [int]$s.Bounds.Y
            ancho        = [int]$s.Bounds.Width
            alto         = [int]$s.Bounds.Height
            working_x    = [int]$s.WorkingArea.X
            working_y    = [int]$s.WorkingArea.Y
            working_w    = [int]$s.WorkingArea.Width
            working_h    = [int]$s.WorkingArea.Height
        }
        $i++
    }
    return ,$resultado
}

# ----------------------------------------------------------------------------
# Get-WebcamsConectadas
# ----------------------------------------------------------------------------
# Devuelve un arreglo de objetos describiendo las camaras/webcams detectadas.
# Considera tanto la clase moderna "Camera" como la antigua "Image" (que es
# donde aparecen muchas webcams USB en Windows 10/11).
# ----------------------------------------------------------------------------
function Get-WebcamsConectadas {
    [CmdletBinding()]
    param()

    $resultado = @()
    try {
        $devs = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {
            ($_.Class -eq 'Camera' -or $_.Class -eq 'Image') -and
            $_.Status -eq 'OK'
        }
        foreach ($d in $devs) {
            $resultado += [PSCustomObject]@{
                nombre   = $d.FriendlyName
                clase    = $d.Class
                instance = $d.InstanceId
            }
        }
    } catch {
        Write-Warning "No se pudo enumerar camaras: $_"
    }
    return ,$resultado
}

# ----------------------------------------------------------------------------
# Get-DispositivosEntrada
# ----------------------------------------------------------------------------
# Cuenta cuantos teclados y mouses FISICOS estan conectados (los virtuales
# que crea Windows tipo "HID-compliant device" se filtran lo mejor posible
# por nombre / instancia con prefijo USB o ACPI).
# ----------------------------------------------------------------------------
function Get-DispositivosEntrada {
    [CmdletBinding()]
    param()

    $teclados = @()
    $mouses   = @()

    try {
        $allKb = Get-PnpDevice -Class 'Keyboard' -ErrorAction SilentlyContinue |
                 Where-Object { $_.Status -eq 'OK' }
        foreach ($k in $allKb) {
            # Filtrar dispositivos terminal-server / RDP virtuales
            if ($k.InstanceId -match 'TERMINPUT|RDP') { continue }
            $teclados += [PSCustomObject]@{
                nombre   = $k.FriendlyName
                instance = $k.InstanceId
                fisico   = ($k.InstanceId -match '^(USB|HID|ACPI)')
            }
        }
    } catch {}

    try {
        $allMs = Get-PnpDevice -Class 'Mouse' -ErrorAction SilentlyContinue |
                 Where-Object { $_.Status -eq 'OK' }
        foreach ($m in $allMs) {
            if ($m.InstanceId -match 'TERMINPUT|RDP') { continue }
            $mouses += [PSCustomObject]@{
                nombre   = $m.FriendlyName
                instance = $m.InstanceId
                fisico   = ($m.InstanceId -match '^(USB|HID|ACPI)')
            }
        }
    } catch {}

    return [PSCustomObject]@{
        teclados        = $teclados
        mouses          = $mouses
        cantidad_teclados_fisicos = ($teclados | Where-Object { $_.fisico } | Measure-Object).Count
        cantidad_mouses_fisicos   = ($mouses   | Where-Object { $_.fisico } | Measure-Object).Count
    }
}

# ----------------------------------------------------------------------------
# Test-PantallaTactil
# ----------------------------------------------------------------------------
# Devuelve $true si Windows reporta capacidad de pantalla tactil. Util para
# auto-sugerir el modo "tactil" en el dialogo del instalador.
# ----------------------------------------------------------------------------
function Test-PantallaTactil {
    [CmdletBinding()]
    param()

    try {
        # SM_DIGITIZER (94) en GetSystemMetrics indica capacidad tactil.
        # Lo consultamos via WMI (mas portable que P/Invoke en PS5).
        $touch = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {
            $_.FriendlyName -match 'touch|tactil|HID-compliant touch' -and
            $_.Status -eq 'OK'
        }
        return ([bool]$touch)
    } catch {
        return $false
    }
}

# ----------------------------------------------------------------------------
# Get-PCIdentifier
# ----------------------------------------------------------------------------
# Devuelve un identificador unico de la PC para diagnosticar a que maquina
# pertenece una configuracion guardada.
# ----------------------------------------------------------------------------
function Get-PCIdentifier {
    [CmdletBinding()]
    param()

    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
        $bs = Get-CimInstance -ClassName Win32_BIOS           -ErrorAction SilentlyContinue
        return ("{0}|{1}|{2}" -f $env:COMPUTERNAME, $cs.Manufacturer, $bs.SerialNumber)
    } catch {
        return $env:COMPUTERNAME
    }
}

# ----------------------------------------------------------------------------
# Get-DeteccionHardwareCompleta
# ----------------------------------------------------------------------------
# Funcion de alto nivel que devuelve un objeto unico con TODA la deteccion.
# Es lo que el instalador y el recuperador llaman.
# ----------------------------------------------------------------------------
function Get-DeteccionHardwareCompleta {
    [CmdletBinding()]
    param()

    $monitores = @(Get-MonitoresFisicos)
    $webcams   = @(Get-WebcamsConectadas)
    $entrada   = Get-DispositivosEntrada
    $tactil    = Test-PantallaTactil
    $pcid      = Get-PCIdentifier

    return [PSCustomObject]@{
        pc_identifier             = $pcid
        cantidad_monitores        = $monitores.Count
        monitores                 = $monitores
        cantidad_webcams          = $webcams.Count
        webcams                   = $webcams
        teclados                  = $entrada.teclados
        mouses                    = $entrada.mouses
        cantidad_teclados_fisicos = $entrada.cantidad_teclados_fisicos
        cantidad_mouses_fisicos   = $entrada.cantidad_mouses_fisicos
        soporta_tactil            = $tactil
        timestamp                 = (Get-Date).ToString('o')
    }
}

# ----------------------------------------------------------------------------
# Show-DeteccionResumen
# ----------------------------------------------------------------------------
# Imprime en consola un resumen amigable de la deteccion para que el usuario
# vea que detecto el instalador antes de confirmar.
# ----------------------------------------------------------------------------
function Show-DeteccionResumen {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Deteccion)

    Write-Host ""
    Write-Host "  Hardware detectado en esta PC:" -ForegroundColor Cyan
    Write-Host "  --------------------------------" -ForegroundColor DarkCyan
    Write-Host ("    Monitores : {0}" -f $Deteccion.cantidad_monitores) -ForegroundColor White
    foreach ($m in $Deteccion.monitores) {
        $tag = if ($m.primary) { '[PRIMARY]' } else { '         ' }
        Write-Host ("      #{0} {1} {2}x{3} en ({4},{5}) {6}" -f `
            $m.indice, $tag, $m.ancho, $m.alto, $m.x, $m.y, $m.nombre) -ForegroundColor Gray
    }
    Write-Host ("    Webcams   : {0}" -f $Deteccion.cantidad_webcams) -ForegroundColor White
    foreach ($w in $Deteccion.webcams) {
        Write-Host ("      - {0}" -f $w.nombre) -ForegroundColor Gray
    }
    Write-Host ("    Teclados fisicos : {0}" -f $Deteccion.cantidad_teclados_fisicos) -ForegroundColor White
    Write-Host ("    Mouses fisicos   : {0}" -f $Deteccion.cantidad_mouses_fisicos) -ForegroundColor White
    Write-Host ("    Soporta tactil   : {0}" -f $Deteccion.soporta_tactil) -ForegroundColor White
    Write-Host ""
}

# Las funciones se exportan automaticamente al hacer dot-sourcing.
