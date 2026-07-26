# =============================================================
# DIAGNOSTICAR_RED.ps1
# Corre en MONITOR o TERMINAL-A. Detecta:
#   - IPs LAN de esta PC
#   - Si hay PocketBase escuchando en 8090 (PID + ruta del exe)
#   - Si esta PC ES 192.168.100.10 (Monitor) o NO (Terminal)
#   - A que IP apunta config.json (dist y public)
#   - Ping + curl a esa IP:8090
#   - Cuantas solicitudes hay en la DB local (via curl a la API)
#   - Detecta "PocketBase zombie" (residuo en Terminal-A)
# NO modifica nada. Solo lee y muestra.
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'DIAGNOSTICAR RED - Sistema FCEA'

function Line($c='='){ Write-Host ($c * 62) -ForegroundColor Yellow }
function Header($t) { Line; Write-Host "  $t" -ForegroundColor Yellow; Line }
function Sub($t) { Write-Host ""; Write-Host "--- $t ---" -ForegroundColor Cyan }

$hostname = $env:COMPUTERNAME
Header "DIAGNOSTICO DE RED - PC: $hostname"

# ---- [1] Rol declarado ----
Sub "[1] Hostname y variables"
Write-Host "  Hostname:            $hostname"
Write-Host "  FCEA_ROL (env):      $env:FCEA_ROL"
Write-Host "  FCEA_HARDWARE (env): $env:FCEA_HARDWARE"

# Heuristica: si el hostname arranca con FCEA-TERM* asumimos Terminal
$rolProbable = 'desconocido'
if ($hostname -match '^FCEA-TERM')    { $rolProbable = 'terminal' }
elseif ($hostname -match '^FCEA-MON') { $rolProbable = 'monitor' }
elseif ($env:FCEA_ROL)                { $rolProbable = $env:FCEA_ROL }
Write-Host "  Rol probable:        $rolProbable" -ForegroundColor Cyan

# ---- [2] IPs LAN ----
Sub "[2] IPs LAN de esta PC"
$ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
       Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' -and $_.PrefixOrigin -ne 'WellKnown' } |
       Select-Object IPAddress, InterfaceAlias, PrefixOrigin
$soyMonitor = $false
foreach ($ip in $ips) {
  $marca = ''
  if ($ip.IPAddress -eq '192.168.100.10') { $marca = '  <-- IP DEL MONITOR OFICIAL'; $soyMonitor = $true }
  Write-Host ("  {0,-16}  ({1}, origen={2}){3}" -f $ip.IPAddress, $ip.InterfaceAlias, $ip.PrefixOrigin, $marca)
}
if ($ips.Count -eq 0) { Write-Host "  [!] No hay IPs LAN activas" -ForegroundColor Red }

if ($soyMonitor) {
  Write-Host "  >>> Esta PC ES el Monitor oficial (192.168.100.10)" -ForegroundColor Green
} else {
  Write-Host "  >>> Esta PC NO es el Monitor. Si es una Terminal, esta bien." -ForegroundColor Gray
}

# ---- [3] Puerto 8090 escuchando ----
Sub "[3] Puerto 8090 (PocketBase) en esta PC"
$conns = Get-NetTCPConnection -LocalPort 8090 -State Listen -ErrorAction SilentlyContinue
if (-not $conns) {
  Write-Host "  Nadie escucha en 8090 en esta PC." -ForegroundColor Yellow
  $tienePb = $false
} else {
  $tienePb = $true
  $seen = @{}
  foreach ($c in $conns) {
    $procId = $c.OwningProcess
    if ($seen.ContainsKey($procId)) { continue }
    $seen[$procId] = $true
    $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
    $ruta = try { (Get-Process -Id $procId).Path } catch { '' }
    Write-Host ("  Local {0}:{1}  PID={2}  proc={3}" -f $c.LocalAddress, $c.LocalPort, $procId, ($proc.ProcessName))
    Write-Host ("    exe: {0}" -f $ruta) -ForegroundColor Gray
  }
}

# ---- [4] config.json ----
Sub "[4] config.json (a que servidor apunta esta PC)"
$paths = @(
  'C:\sistema-llaves-fcea\dist\config.json',
  'C:\sistema-llaves-fcea\public\config.json',
  'C:\sistema-llaves-fcea\config.json'
)
$urlPbConfigurada = $null
foreach ($p in $paths) {
  if (Test-Path $p) {
    try {
      $j = Get-Content $p -Raw | ConvertFrom-Json
      Write-Host ("  {0}" -f $p) -ForegroundColor Cyan
      Write-Host ("     rol={0}  hardware={1}" -f $j.rol, $j.hardware)
      Write-Host ("     pocketbaseUrl={0}" -f $j.pocketbaseUrl)
      if (-not $urlPbConfigurada) { $urlPbConfigurada = $j.pocketbaseUrl }
    } catch {
      Write-Host ("  {0}  [ERROR al parsear JSON]" -f $p) -ForegroundColor Red
    }
  }
}
if (-not $urlPbConfigurada) { Write-Host "  [!] No se encontro ningun config.json" -ForegroundColor Red }

# ---- [5] Ping + curl a la IP configurada ----
if ($urlPbConfigurada) {
  Sub "[5] Ping + curl al servidor configurado"
  # Extraer host de la URL
  $u = $null
  try { $u = [Uri]$urlPbConfigurada } catch {}
  if ($u) {
    $srvHost = $u.Host
    Write-Host "  Target: $urlPbConfigurada  (host=$srvHost)"
    $ping = Test-Connection -ComputerName $srvHost -Count 2 -Quiet -ErrorAction SilentlyContinue
    if ($ping) { Write-Host "  PING $srvHost : OK" -ForegroundColor Green }
    else       { Write-Host "  PING $srvHost : FALLA (o ICMP bloqueado)" -ForegroundColor Yellow }

    try {
      $r = Invoke-WebRequest -Uri "$urlPbConfigurada/api/health" -TimeoutSec 3 -UseBasicParsing
      Write-Host ("  HTTP /api/health : {0} {1}" -f $r.StatusCode, $r.StatusDescription) -ForegroundColor Green
    } catch {
      Write-Host ("  HTTP /api/health : FALLA ({0})" -f $_.Exception.Message) -ForegroundColor Red
    }
  }
}

# ---- [6] Contar solicitudes en las DBs visibles ----
Sub "[6] Cuantas SOLICITUDES ve esta PC"
$urls = @()
if ($urlPbConfigurada) { $urls += $urlPbConfigurada }
if ($tienePb -and $urlPbConfigurada -notlike '*127.0.0.1*') { $urls += 'http://127.0.0.1:8090' }
if ($urls.Count -eq 0 -and $tienePb) { $urls += 'http://127.0.0.1:8090' }

foreach ($u in ($urls | Select-Object -Unique)) {
  try {
    $r = Invoke-WebRequest -Uri "$u/api/collections/solicitudes/records?perPage=1&sort=-created" -TimeoutSec 3 -UseBasicParsing
    $data = $r.Content | ConvertFrom-Json
    $total = $data.totalItems
    $ultima = if ($data.items.Count -gt 0) { $data.items[0].created } else { '(sin datos)' }
    Write-Host ("  {0}" -f $u) -ForegroundColor Cyan
    Write-Host ("     total solicitudes: {0}" -f $total) -ForegroundColor Green
    Write-Host ("     ultima creada:     {0}" -f $ultima)
  } catch {
    Write-Host ("  {0}  [SIN RESPUESTA: {1}]" -f $u, $_.Exception.Message) -ForegroundColor Yellow
  }
}

# ---- [7] Diagnostico de POCKETBASE ZOMBIE ----
Sub "[7] Deteccion de PocketBase ZOMBIE"
$zombie = $false
if ($tienePb -and $rolProbable -eq 'terminal') {
  Write-Host "  [ZOMBIE DETECTADO]" -ForegroundColor Red
  Write-Host "  Esta PC parece ser una TERMINAL y sin embargo esta corriendo" -ForegroundColor Red
  Write-Host "  su propio pocketbase.exe en el puerto 8090. Eso hace que las" -ForegroundColor Red
  Write-Host "  solicitudes que se envian a 'localhost' o a esta PC vayan a" -ForegroundColor Red
  Write-Host "  una DB muerta en vez de a la del Monitor." -ForegroundColor Red
  Write-Host "  SOLUCION: ejecutar 'MATAR_POCKETBASE_ZOMBIE.bat' desde el pendrive." -ForegroundColor Red
  $zombie = $true
} elseif ($tienePb -and $soyMonitor) {
  Write-Host "  OK: Esta PC es el Monitor y tiene PocketBase local. Es lo esperado." -ForegroundColor Green
} elseif (-not $tienePb -and $rolProbable -eq 'monitor') {
  Write-Host "  [!] Esta PC parece ser el Monitor pero NO tiene PocketBase corriendo." -ForegroundColor Red
} else {
  Write-Host "  Sin residuos zombies detectados." -ForegroundColor Green
}

# ---- [8] Chequeo cruzado: si el urlPbConfigurada apunta a esta misma PC ----
Sub "[8] Chequeo cruzado: config.json apunta a esta PC?"
if ($urlPbConfigurada -and $ips) {
  $misIps = $ips | ForEach-Object { $_.IPAddress }
  $misIps += '127.0.0.1'
  $misIps += 'localhost'
  $urlHost = try { ([Uri]$urlPbConfigurada).Host } catch { '' }
  if ($misIps -contains $urlHost) {
    if ($rolProbable -eq 'terminal') {
      Write-Host "  [PROBLEMA] La Terminal tiene config.json apuntando a SI MISMA ($urlHost)" -ForegroundColor Red
      Write-Host "  Deberia apuntar a la IP del Monitor (192.168.100.10)." -ForegroundColor Red
      Write-Host "  SOLUCION: ejecutar 'APUNTAR_TERMINAL_A_MONITOR.bat' desde el pendrive." -ForegroundColor Red
    } else {
      Write-Host "  OK: el Monitor apunta a si mismo (127.0.0.1). Es lo esperado." -ForegroundColor Green
    }
  } else {
    Write-Host "  config.json apunta a $urlHost (una IP externa). Es lo esperado en Terminal." -ForegroundColor Green
  }
}

# ---- Resumen final ----
Write-Host ""
Line
if ($zombie) {
  Write-Host "  RESULTADO: HAY POCKETBASE ZOMBIE - correr MATAR_POCKETBASE_ZOMBIE.bat" -ForegroundColor Red
} else {
  Write-Host "  RESULTADO: diagnostico completado. Enviar foto a soporte." -ForegroundColor Green
}
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
