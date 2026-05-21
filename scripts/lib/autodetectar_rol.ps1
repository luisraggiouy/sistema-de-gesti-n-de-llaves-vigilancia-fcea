# ============================================================
# Sistema FCEA - Auto-detector de ROL y HARDWARE
# ------------------------------------------------------------
# Devuelve UNA sola linea por stdout:
#
#   rol|hardware|ip_servidor
#
# Donde:
#   rol         = monitor | terminal-a | terminal-b | dashboard
#   hardware    = tactil  | tradicional
#   ip_servidor = IP de la PC servidor (o 127.0.0.1 si soy yo)
#
# REGLAS DE DETECCION (en orden de prioridad):
#
# 1. Si existe C:\sistema-llaves-fcea\config\install_config.json y
#    contiene un rol valido -> se usa ese (PC ya configurada antes).
#
# 2. Por HOSTNAME (configuracion fisica recomendada en FCEA):
#       FCEA-CABINA       -> monitor
#       FCEA-TERMINAL-A   -> terminal-a
#       FCEA-TERMINAL-B   -> terminal-b
#       FCEA-DASHBOARD    -> dashboard
#       FCEA-MONITOR      -> monitor (alias)
#       FCEA-SERVIDOR     -> monitor (alias)
#    Tambien se aceptan los mismos nombres en mayuscula/minuscula
#    y con underscore en vez de guion.
#
# 3. Por OCTETO FINAL de la IP local en la red interna 192.168.X.X
#    o 10.X.X.X (rangos privados):
#       .10 -> monitor    (servidor)
#       .11 -> terminal-a
#       .12 -> terminal-b
#       .13 -> dashboard
#
# 4. Por ARP / PING: si ya existe un servidor PocketBase corriendo
#    en la red (puerto 8090), me detecto como terminal-a por defecto
#    y apunto al servidor encontrado.
#
# 5. Fallback: monitor (servidor + monitor de vigilancia).
#
# El HARDWARE se detecta con la libreria detectar_hardware.ps1:
# si Windows reporta digitalizador tactil -> "tactil"; si no
# -> "tradicional". El rol "dashboard" siempre es "tradicional".
# ============================================================

$ErrorActionPreference = 'SilentlyContinue'

# ------------------------------------------------------------
# Helper: obtener la primera IPv4 privada de la PC
# ------------------------------------------------------------
function Get-LocalIPv4 {
    try {
        $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
               Where-Object {
                   $_.IPAddress -notlike '169.254.*' -and
                   $_.IPAddress -ne '127.0.0.1' -and
                   $_.PrefixOrigin -ne 'WellKnown'
               }
        foreach ($ip in $ips) {
            $a = $ip.IPAddress
            if ($a -like '192.168.*' -or $a -like '10.*' -or $a -like '172.16.*' -or
                $a -like '172.17.*' -or $a -like '172.18.*' -or $a -like '172.19.*' -or
                $a -like '172.2*.*' -or $a -like '172.30.*' -or $a -like '172.31.*') {
                return $a
            }
        }
        if ($ips -and $ips.Count -gt 0) { return $ips[0].IPAddress }
    } catch {}
    return $null
}

# ------------------------------------------------------------
# Helper: ¿hay un PocketBase corriendo en alguna IP de la red?
# Hace un ping rapido a las IPs candidatas y prueba el puerto 8090.
# ------------------------------------------------------------
function Find-PocketBaseEnRed {
    param([string]$LocalIp)

    if (-not $LocalIp) { return $null }
    if ($LocalIp -notlike '192.168.*' -and $LocalIp -notlike '10.*' -and $LocalIp -notlike '172.*') {
        return $null
    }

    # Inferir prefijo /24 de la red local
    $parts = $LocalIp.Split('.')
    if ($parts.Count -ne 4) { return $null }
    $prefix = "$($parts[0]).$($parts[1]).$($parts[2])"

    # Candidatos comunes para el servidor (en este orden)
    $candidatos = @("${prefix}.10","${prefix}.1","${prefix}.100","${prefix}.50")

    foreach ($ip in $candidatos) {
        if ($ip -eq $LocalIp) { continue }
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $iar = $tcp.BeginConnect($ip, 8090, $null, $null)
            $ok  = $iar.AsyncWaitHandle.WaitOne(400, $false)
            if ($ok -and $tcp.Connected) {
                $tcp.Close()
                return $ip
            }
            $tcp.Close()
        } catch {}
    }
    return $null
}

# ------------------------------------------------------------
# Helper: leer rol previo de install_config.json (si existe)
# ------------------------------------------------------------
function Get-RolPrevioInstalado {
    $path = 'C:\sistema-llaves-fcea\config\install_config.json'
    if (-not (Test-Path $path)) { return $null }
    try {
        $j = Get-Content $path -Raw | ConvertFrom-Json
        if ($j.rol -and $j.rol -ne '') {
            return [PSCustomObject]@{
                rol         = $j.rol
                hardware    = $j.hardware
                ip_servidor = $j.red.ip_servidor
            }
        }
    } catch {}
    return $null
}

# ------------------------------------------------------------
# Helper: detectar hardware tactil con la libreria existente
# ------------------------------------------------------------
function Get-HardwareTipo {
    try {
        $libPath = Join-Path $PSScriptRoot 'detectar_hardware.ps1'
        if (Test-Path $libPath) {
            . $libPath
            if (Test-TouchAvailable) { return 'tactil' }
        }
    } catch {}
    return 'tradicional'
}

# ------------------------------------------------------------
# Normalizar hostname para comparar
# ------------------------------------------------------------
function Normalize-Hostname {
    param([string]$h)
    if (-not $h) { return '' }
    return ($h -replace '[_\s]','-').ToUpperInvariant()
}

# ============================================================
# LOGICA PRINCIPAL
# ============================================================

$resultado = @{
    rol         = ''
    hardware    = ''
    ip_servidor = ''
}

# 1) ¿Hay instalacion previa que ya sabe que rol es?
$previo = Get-RolPrevioInstalado
if ($previo -and $previo.rol) {
    $resultado.rol         = $previo.rol
    $resultado.hardware    = if ($previo.hardware) { $previo.hardware } else { (Get-HardwareTipo) }
    $resultado.ip_servidor = if ($previo.ip_servidor) { $previo.ip_servidor } else { '127.0.0.1' }
    Write-Output ("{0}|{1}|{2}" -f $resultado.rol, $resultado.hardware, $resultado.ip_servidor)
    return
}

# 2) Por HOSTNAME
$h = Normalize-Hostname $env:COMPUTERNAME
switch -Regex ($h) {
    '^FCEA-CABINA$'      { $resultado.rol = 'monitor';    break }
    '^FCEA-MONITOR$'     { $resultado.rol = 'monitor';    break }
    '^FCEA-SERVIDOR$'    { $resultado.rol = 'monitor';    break }
    '^FCEA-TERMINAL-A$'  { $resultado.rol = 'terminal-a'; break }
    '^FCEA-TERMINAL-B$'  { $resultado.rol = 'terminal-b'; break }
    '^FCEA-DASHBOARD$'   { $resultado.rol = 'dashboard';  break }
    default              { }
}

$localIp = Get-LocalIPv4

# 3) Por ULTIMO OCTETO de IP
if (-not $resultado.rol -and $localIp) {
    $oct = $localIp.Split('.')[-1]
    switch ($oct) {
        '10' { $resultado.rol = 'monitor'    }
        '11' { $resultado.rol = 'terminal-a' }
        '12' { $resultado.rol = 'terminal-b' }
        '13' { $resultado.rol = 'dashboard'  }
    }
}

# 4) Por busqueda en la red: si hay un servidor activo, soy terminal
if (-not $resultado.rol) {
    $servidorRemoto = Find-PocketBaseEnRed -LocalIp $localIp
    if ($servidorRemoto) {
        $resultado.rol         = 'terminal-a'
        $resultado.ip_servidor = $servidorRemoto
    }
}

# 5) Fallback: soy el servidor + monitor
if (-not $resultado.rol) {
    $resultado.rol = 'monitor'
}

# ------------------------------------------------------------
# Resolver hardware y IP del servidor
# ------------------------------------------------------------
if (-not $resultado.hardware) {
    if ($resultado.rol -eq 'dashboard') {
        # El dashboard tipicamente es PC con monitor LCD comun
        $resultado.hardware = 'tradicional'
    } else {
        $resultado.hardware = (Get-HardwareTipo)
    }
}

if (-not $resultado.ip_servidor -or $resultado.ip_servidor -eq '') {
    if ($resultado.rol -eq 'monitor') {
        $resultado.ip_servidor = '127.0.0.1'
    } else {
        # Si no encontramos servidor por red, asumir prefijo + .10
        if ($localIp) {
            $parts = $localIp.Split('.')
            $resultado.ip_servidor = "$($parts[0]).$($parts[1]).$($parts[2]).10"
        } else {
            $resultado.ip_servidor = '127.0.0.1'
        }
    }
}

Write-Output ("{0}|{1}|{2}" -f $resultado.rol, $resultado.hardware, $resultado.ip_servidor)
