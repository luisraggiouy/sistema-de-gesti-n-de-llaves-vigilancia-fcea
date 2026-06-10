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
# Helper: descubrir el servidor PocketBase en la red local.
#
# Estrategia (en orden):
#   1) Probar IPs "preferidas" (.10, .1, .100, .50) con timeout corto.
#   2) Si nada respondio, escanear TODO el segmento /24 en paralelo
#      (255 IPs, ~3 seg total con timeout de 200ms por IP).
#
# Cualquier host que tenga abierto el puerto TCP 8090 se considera
# servidor candidato. Devuelve la IP o $null.
# ------------------------------------------------------------
function Test-PuertoAbierto {
    param([string]$Ip, [int]$Puerto = 8090, [int]$TimeoutMs = 300)
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $iar = $tcp.BeginConnect($Ip, $Puerto, $null, $null)
        $ok  = $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
        $conectado = ($ok -and $tcp.Connected)
        $tcp.Close()
        return $conectado
    } catch {
        return $false
    }
}

function Find-PocketBaseEnRed {
    param(
        [string]$LocalIp,
        [switch]$EscaneoCompleto   # Si true, recorre toda la /24 (mas lento, ~3-5 seg)
    )

    if (-not $LocalIp) { return $null }
    if ($LocalIp -notlike '192.168.*' -and $LocalIp -notlike '10.*' -and $LocalIp -notlike '172.*') {
        return $null
    }

    $parts = $LocalIp.Split('.')
    if ($parts.Count -ne 4) { return $null }
    $prefix = "$($parts[0]).$($parts[1]).$($parts[2])"
    $miOcteto = [int]$parts[3]

    # ---- Fase 1: candidatos preferidos (rapido) ----
    $candidatos = @("${prefix}.10","${prefix}.1","${prefix}.100","${prefix}.50")
    foreach ($ip in $candidatos) {
        if ($ip -eq $LocalIp) { continue }
        if (Test-PuertoAbierto -Ip $ip -Puerto 8090 -TimeoutMs 400) {
            return $ip
        }
    }

    if (-not $EscaneoCompleto) { return $null }

    # ---- Fase 2: barrido /24 en paralelo (con runspaces) ----
    # Lanzamos hasta 50 sockets simultaneos para que el escaneo total
    # de las 255 IPs tome ~3-5 segundos en lugar de minutos.
    try {
        $pool = [runspacefactory]::CreateRunspacePool(1, 50)
        $pool.Open()
        $jobs = @()

        for ($i = 1; $i -le 254; $i++) {
            if ($i -eq $miOcteto) { continue }
            $ipTest = "${prefix}.$i"
            $ps = [powershell]::Create().AddScript({
                param($ip, $port, $timeout)
                try {
                    $tcp = New-Object System.Net.Sockets.TcpClient
                    $iar = $tcp.BeginConnect($ip, $port, $null, $null)
                    if ($iar.AsyncWaitHandle.WaitOne($timeout, $false) -and $tcp.Connected) {
                        $tcp.Close()
                        return $ip
                    }
                    $tcp.Close()
                } catch {}
                return $null
            }).AddArgument($ipTest).AddArgument(8090).AddArgument(200)
            $ps.RunspacePool = $pool
            $jobs += [PSCustomObject]@{ PS = $ps; Handle = $ps.BeginInvoke() }
        }

        $encontrada = $null
        foreach ($j in $jobs) {
            $res = $j.PS.EndInvoke($j.Handle)
            if ($res -and -not $encontrada) { $encontrada = "$res" }
            $j.PS.Dispose()
        }
        $pool.Close(); $pool.Dispose()
        return $encontrada
    } catch {
        return $null
    }
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

# 4) Por busqueda en la red: si hay un servidor activo, soy terminal.
#    Hacemos ESCANEO COMPLETO de la /24 - tarda 3-5 segundos pero
#    asi NO hay que preguntarle la IP al usuario en las terminales.
if (-not $resultado.rol) {
    $servidorRemoto = Find-PocketBaseEnRed -LocalIp $localIp -EscaneoCompleto
    if ($servidorRemoto) {
        $resultado.rol         = 'terminal-a'
        $resultado.ip_servidor = $servidorRemoto
    }
}

# 4b) Si ya sabemos que somos terminal-* o dashboard pero todavia no
#     tenemos IP del servidor (porque vino por hostname/IP fija),
#     hacer ESCANEO COMPLETO para descubrirla solos.
if ($resultado.rol -and $resultado.rol -ne 'monitor' -and -not $resultado.ip_servidor) {
    $servidorRemoto = Find-PocketBaseEnRed -LocalIp $localIp -EscaneoCompleto
    if ($servidorRemoto) {
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
