# ============================================================
# Sistema FCEA - Reparador de conexion al servidor
# ------------------------------------------------------------
# Escanea la red buscando una instancia de PocketBase (puerto TCP
# 8090). Cuando la encuentra, reescribe la configuracion local
# para que esta PC (que asumimos es una Terminal A/B o Dashboard)
# apunte al servidor correcto.
#
# NO reinstala nada. NO toca datos. Solo edita archivos JSON:
#   - <repo>\public\config.json                        (lo que lee INICIAR.bat)
#   - <repo>\dist\config.json                          (bundle del frontend)
#   - C:\sistema-llaves-fcea\config\install_config.json (config persistente)
#
# MODOS:
#   - Interactivo (por defecto): doble-click en el .bat del pendrive.
#     Muestra progreso, pregunta cuando no encuentra servidor, pausa al final.
#   - Silencioso (-Silencioso): usado por INICIAR.bat en el auto-repair a
#     los 90s. Sin prompts, sin pausa, sin cerrar navegador. Si no encuentra
#     servidor, sale con codigo 1 y deja que el caller siga con retries.
# ============================================================

param(
    # Modo no interactivo para auto-repair desde INICIAR.bat.
    # No hace prompts, no pausa al final, y no cierra Edge/Chrome
    # (INICIAR aun no abrio navegador en ese punto).
    [switch]$Silencioso
)

$ErrorActionPreference = 'Stop'

function Write-Info    { param($m) if (-not $script:Silent) { Write-Host "  $m" -ForegroundColor Gray } }
function Write-Ok      { param($m) if (-not $script:Silent) { Write-Host "  [OK] $m" -ForegroundColor Green } }
function Write-Warn    { param($m) if (-not $script:Silent) { Write-Host "  [!]  $m" -ForegroundColor Yellow } }
function Write-Err     { param($m) Write-Host "  [X]  $m" -ForegroundColor Red }  # errores siempre visibles
function Write-Section { param($m) if (-not $script:Silent) { Write-Host ""; Write-Host "============================================================" -ForegroundColor Cyan; Write-Host "  $m" -ForegroundColor Cyan; Write-Host "============================================================" -ForegroundColor Cyan; Write-Host "" } }

# Flag global de silencio; las funciones Write-* lo consultan.
$script:Silent = [bool]$Silencioso

# ------------------------------------------------------------
# Localizar la libreria de autodeteccion (mismo pendrive/repo)
# ------------------------------------------------------------
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$autoDetect = Join-Path $scriptDir 'autodetectar_rol.ps1'
if (-not (Test-Path $autoDetect)) {
    Write-Err "No encontre autodetectar_rol.ps1 junto a este script."
    Write-Err "Ruta esperada: $autoDetect"
    Read-Host "`nPresione Enter para salir"
    exit 1
}

# ------------------------------------------------------------
# Helper: probar puerto abierto (Test-NetConnection es lento por si
# solo, esta version con TcpClient tarda milisegundos).
# ------------------------------------------------------------
function Test-PuertoAbierto {
    param([string]$Ip, [int]$Puerto = 8090, [int]$TimeoutMs = 500)
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

# ------------------------------------------------------------
# Helper: obtener IP local (misma logica que autodetectar_rol)
# ------------------------------------------------------------
function Get-LocalIPv4List {
    $result = @()
    try {
        $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
               Where-Object {
                   $_.IPAddress -notlike '169.254.*' -and
                   $_.IPAddress -ne '127.0.0.1' -and
                   $_.PrefixOrigin -ne 'WellKnown'
               }
        foreach ($ip in $ips) {
            $a = $ip.IPAddress
            if ($a -like '192.168.*' -or $a -like '10.*' -or $a -like '172.*') {
                $result += $a
            }
        }
    } catch {}
    return $result
}

# ------------------------------------------------------------
# Helper: escanear /24 en paralelo. Devuelve TODAS las IPs con
# PocketBase abierto (no solo la primera) para poder mostrarlas
# al usuario si hay varias.
# ------------------------------------------------------------
function Find-TodasPocketBase {
    param([string]$LocalIp)

    $parts = $LocalIp.Split('.')
    if ($parts.Count -ne 4) { return @() }
    $prefix = "$($parts[0]).$($parts[1]).$($parts[2])"
    $miOcteto = [int]$parts[3]

    Write-Info "Escaneando subred $prefix.0/24 (255 IPs en paralelo)..."

    $encontradas = @()
    try {
        $pool = [runspacefactory]::CreateRunspacePool(1, 60)
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
            }).AddArgument($ipTest).AddArgument(8090).AddArgument(400)
            $ps.RunspacePool = $pool
            $jobs += [PSCustomObject]@{ PS = $ps; Handle = $ps.BeginInvoke() }
        }

        foreach ($j in $jobs) {
            $res = $j.PS.EndInvoke($j.Handle)
            if ($res) { $encontradas += "$res" }
            $j.PS.Dispose()
        }
        $pool.Close(); $pool.Dispose()
    } catch {
        Write-Warn "Error en el escaneo paralelo: $_"
    }

    return $encontradas
}

# ------------------------------------------------------------
# Helper: verificar que la IP responde con contenido de PocketBase.
# Un puerto 8090 abierto no garantiza que sea PocketBase (podria ser
# otro proceso). Pegamos /api/health y validamos JSON.
# ------------------------------------------------------------
function Test-EsPocketBase {
    param([string]$Ip)
    try {
        $url = "http://${Ip}:8090/api/health"
        $resp = Invoke-WebRequest -Uri $url -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        if ($resp.StatusCode -eq 200 -and $resp.Content -match '"code"') {
            return $true
        }
    } catch {}
    return $false
}

# ============================================================
# INICIO
# ============================================================

Clear-Host
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  FCEA - Reparador de Conexion al Servidor" -ForegroundColor Cyan
Write-Host "  Sistema de Gestion de Llaves" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Este script busca el Monitor Vigilancia en la red" -ForegroundColor White
Write-Host "  y reconfigura esta PC para que se conecte a el." -ForegroundColor White
Write-Host ""
Write-Host "  NO reinstala nada, NO borra datos. Solo edita el" -ForegroundColor White
Write-Host "  archivo de configuracion." -ForegroundColor White
Write-Host ""

# Verificar que hay una instalacion en C:\sistema-llaves-fcea
$installDir = 'C:\sistema-llaves-fcea'
if (-not (Test-Path $installDir)) {
    Write-Err "No encontre una instalacion en $installDir"
    Write-Err "Este PC no parece tener el sistema instalado."
    Write-Err "Use INSTALAR SISTEMA.bat en su lugar."
    Read-Host "`nPresione Enter para salir"
    exit 1
}

# Detectar IPs locales
Write-Section "Paso 1/4: Detectar red local"
$localIps = Get-LocalIPv4List
if ($localIps.Count -eq 0) {
    Write-Err "No detecte ninguna IP privada en esta PC."
    Write-Err "Verifique que este conectada al switch/router del edificio."
    Read-Host "`nPresione Enter para salir"
    exit 1
}
foreach ($ip in $localIps) { Write-Ok "IP local detectada: $ip" }

# Escanear cada subred buscando PocketBase
Write-Section "Paso 2/4: Escanear la red buscando el servidor"
$candidatos = @()
foreach ($localIp in $localIps) {
    $ips = Find-TodasPocketBase -LocalIp $localIp
    foreach ($ip in $ips) {
        if ($candidatos -notcontains $ip) { $candidatos += $ip }
    }
}

# Filtrar los que realmente son PocketBase (no otro servicio en 8090)
Write-Info "Verificando cuales candidatos son PocketBase real..."
$servidores = @()
foreach ($ip in $candidatos) {
    if (Test-EsPocketBase -Ip $ip) {
        $servidores += $ip
        Write-Ok "PocketBase confirmado en: $ip"
    } else {
        Write-Warn "Puerto 8090 abierto pero NO es PocketBase: $ip (descartado)"
    }
}

if ($servidores.Count -eq 0) {
    # En modo silencioso: no preguntar nada, salir con codigo 1.
    # El caller (INICIAR.bat) seguira reintentando el health-check
    # hasta agotar los 3 minutos.
    if ($script:Silent) {
        Write-Err "No encontre PocketBase en la red (modo silencioso). Salgo con codigo 1."
        exit 1
    }
    Write-Host ""
    Write-Err "No encontre ningun Monitor Vigilancia con PocketBase en la red."
    Write-Host ""
    Write-Host "  Verifique lo siguiente:" -ForegroundColor Yellow
    Write-Host "    1. El Monitor Vigilancia esta ENCENDIDO." -ForegroundColor Yellow
    Write-Host "    2. Esta corriendo el sistema (icono en bandeja)." -ForegroundColor Yellow
    Write-Host "    3. Esta conectado al mismo switch/router que esta PC." -ForegroundColor Yellow
    Write-Host "    4. El firewall del Monitor no bloquea el puerto 8090." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Opciones:" -ForegroundColor Cyan
    Write-Host "    [R] Reintentar escaneo (volver a probar)" -ForegroundColor White
    Write-Host "    [M] Ingresar la IP manualmente" -ForegroundColor White
    Write-Host "    [S] Salir sin cambios" -ForegroundColor White
    Write-Host ""
    $op = Read-Host "  Que hace [R/M/S]"
    switch -Regex ($op) {
        '^[rR]' {
            & $MyInvocation.MyCommand.Path
            exit $LASTEXITCODE
        }
        '^[mM]' {
            $ipManual = ''
            while (-not $ipManual) {
                $ipManual = Read-Host "  Ingrese la IP del Monitor Vigilancia (ej: 192.168.1.10)"
                if ($ipManual -notmatch '^\d+\.\d+\.\d+\.\d+$') {
                    Write-Warn "Formato invalido. Debe ser IPv4 (ej: 192.168.1.10)."
                    $ipManual = ''
                    continue
                }
                if ($ipManual -eq '127.0.0.1' -or $ipManual -eq '0.0.0.0') {
                    Write-Warn "$ipManual no es una IP valida para un servidor remoto."
                    $ipManual = ''
                    continue
                }
                Write-Info "Verificando que responda en ${ipManual}:8090 ..."
                if (-not (Test-EsPocketBase -Ip $ipManual)) {
                    Write-Warn "No responde o no es PocketBase."
                    $seguir = Read-Host "  Guardar de todas formas? [S/N]"
                    if ($seguir -notmatch '^[sSyY]') { $ipManual = ''; continue }
                }
                $servidores = @($ipManual)
                break
            }
        }
        default {
            Write-Info "Saliendo sin cambios."
            exit 0
        }
    }
}

# Elegir la IP a usar
Write-Section "Paso 3/4: Seleccionar el servidor"
$ipElegida = $null
if ($servidores.Count -eq 1) {
    $ipElegida = $servidores[0]
    Write-Ok "Un solo servidor encontrado, usando: $ipElegida"
} elseif ($script:Silent) {
    # En modo silencioso con multiples candidatos, tomamos el PRIMERO
    # (no podemos preguntar). El operador puede corregir manualmente
    # despues corriendo REPARAR_CONEXION_SERVIDOR.bat en modo interactivo.
    $ipElegida = $servidores[0]
    Write-Warn "Multiples servidores en la red; en modo silencioso uso el primero: $ipElegida"
} else {
    Write-Host "  Encontre $($servidores.Count) servidores. Elija uno:" -ForegroundColor White
    Write-Host ""
    for ($i = 0; $i -lt $servidores.Count; $i++) {
        Write-Host ("    [{0}] {1}" -f ($i + 1), $servidores[$i]) -ForegroundColor Cyan
    }
    Write-Host ""
    $seleccion = 0
    while ($seleccion -lt 1 -or $seleccion -gt $servidores.Count) {
        $s = Read-Host "  Numero"
        if ($s -match '^\d+$') { $seleccion = [int]$s }
    }
    $ipElegida = $servidores[$seleccion - 1]
    Write-Ok "Usando: $ipElegida"
}

# Reescribir archivos de configuracion
Write-Section "Paso 4/4: Actualizar configuracion"

# Helper local: actualiza un config.json en la ruta indicada,
# forzando pocketbase_url y red.ip_servidor. Devuelve $true si tuvo
# exito, $false si el archivo no existe o hubo error.
function Update-ConfigJson {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Ip
    )
    if (-not (Test-Path $Path)) {
        Write-Warn "No existe $Path (omito)."
        return $false
    }
    try {
        $cfg = Get-Content $Path -Raw | ConvertFrom-Json
        $cfg.pocketbase_url = "http://${Ip}:8090"
        if ($cfg.red) {
            $cfg.red.ip_servidor = $Ip
        }
        # Si el rol dice 'monitor' pero apuntamos a un servidor REMOTO,
        # es evidencia de config rota (esta PC no puede ser el monitor
        # si el servidor esta en otra IP). Bajamos a 'terminal-a' como
        # default seguro. El operador puede cambiarlo despues.
        if ($cfg.rol -eq 'monitor' -and $Ip -ne '127.0.0.1') {
            Write-Warn "Rol era 'monitor' con servidor remoto; cambiando a 'terminal-a'."
            $cfg.rol = 'terminal-a'
        }
        $cfg | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
        Write-Ok "$([System.IO.Path]::GetFileName($Path)) actualizado en $([System.IO.Path]::GetDirectoryName($Path))."
        return $true
    } catch {
        Write-Err "Fallo al actualizar $Path : $_"
        return $false
    }
}

# 1a) public/config.json - lo que lee INICIAR.bat (config canonica de la PC).
#     Esta es la ruta CRITICA cuando ejecutamos en modo silencioso desde
#     INICIAR.bat: si no la actualizamos, la proxima lectura seguira dando
#     la IP vieja.
Update-ConfigJson -Path (Join-Path $installDir 'public\config.json') -Ip $ipElegida | Out-Null

# 1b) dist/config.json - lo que sirve el bundle al navegador.
Update-ConfigJson -Path (Join-Path $installDir 'dist\config.json') -Ip $ipElegida | Out-Null

# 2) install_config.json - config persistente que sobrevive reinstalaciones
$installCfgPath = Join-Path $installDir 'config\install_config.json'
if (Test-Path $installCfgPath) {
    Write-Info "Actualizando $installCfgPath ..."
    try {
        $cfg = Get-Content $installCfgPath -Raw | ConvertFrom-Json
        if ($cfg.red) {
            $cfg.red.ip_servidor = $ipElegida
        } else {
            $cfg | Add-Member -MemberType NoteProperty -Name 'red' -Value ([PSCustomObject]@{ ip_servidor = $ipElegida }) -Force
        }
        if ($cfg.rol -eq 'monitor' -and $ipElegida -ne '127.0.0.1') {
            $cfg.rol = 'terminal-a'
        }
        $cfg | ConvertTo-Json -Depth 10 | Set-Content $installCfgPath -Encoding UTF8
        Write-Ok "install_config.json actualizado."
    } catch {
        Write-Err "Fallo al actualizar install_config.json: $_"
    }
} else {
    Write-Info "$installCfgPath no existe (opcional, no es critico)."
}

# Cerrar Edge/Chrome para forzar recarga limpia del bundle SOLO en modo
# interactivo. En modo silencioso (llamado desde INICIAR.bat en el
# arranque en frio) el navegador aun no esta abierto — cerrarlo aqui
# no tendria efecto y ademas mataria a Chrome si el usuario recien esta
# volviendo al PC.
if (-not $script:Silent) {
    Write-Info "Cerrando Edge/Chrome para forzar recarga con nueva config..."
    Get-Process -Name 'msedge','chrome' -ErrorAction SilentlyContinue | ForEach-Object {
        try { $_.CloseMainWindow() | Out-Null } catch {}
    }
    Start-Sleep -Seconds 1
    Get-Process -Name 'msedge','chrome' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

Write-Section "REPARACION COMPLETADA"
Write-Ok "Esta PC ahora apunta a http://${ipElegida}:8090"

# En modo silencioso: no imprimir "proximos pasos" ni esperar Enter.
# Devolvemos 0 y el caller decide que hacer con el mensaje al usuario.
if ($script:Silent) {
    exit 0
}

Write-Host ""
Write-Host "  Proximos pasos:" -ForegroundColor Cyan
Write-Host "    1. Abra el sistema desde el acceso directo del escritorio," -ForegroundColor White
Write-Host "       o reinicie la PC." -ForegroundColor White
Write-Host "    2. Verifique con Ctrl+Shift+D que el diagnostico" -ForegroundColor White
Write-Host "       muestre 'OK' en Conectividad con PocketBase." -ForegroundColor White
Write-Host "    3. Pruebe registrar un usuario nuevo." -ForegroundColor White
Write-Host ""
Read-Host "  Presione Enter para salir"
exit 0
