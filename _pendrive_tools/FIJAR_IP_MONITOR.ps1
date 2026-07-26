# =============================================================
# FIJAR_IP_MONITOR.ps1
# SOLO EJECUTAR EN EL MONITOR.
# Fija IP estatica 192.168.100.10/24 en el adaptador Ethernet
# activo (o el que elija el usuario si hay varios).
# No toca gateway ni DNS (para no romper internet en otros
# adaptadores como Wi-Fi).
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'FIJAR IP MONITOR - Sistema FCEA'

function Line($c='='){ Write-Host ($c * 62) -ForegroundColor Yellow }
function H($t)  { Line; Write-Host "  $t" -ForegroundColor Yellow; Line }
function Sub($t){ Write-Host ""; Write-Host "--- $t ---" -ForegroundColor Cyan }

H "FIJAR IP 192.168.100.10 - $env:COMPUTERNAME"

# ---- Salvaguarda: no correr en Terminal ----
if ($env:COMPUTERNAME -match '^FCEA-TERM') {
  Write-Host "  [!] Esta PC parece ser una Terminal ($env:COMPUTERNAME)" -ForegroundColor Red
  Write-Host "  Este script es SOLO para el Monitor." -ForegroundColor Red
  $c = Read-Host "  Escribe SI-CONTINUAR para forzar (o ENTER para abortar)"
  if ($c -ne 'SI-CONTINUAR') { Write-Host "  Abortado." -ForegroundColor Green; Write-Host ""; Write-Host "Presiona ENTER..." -ForegroundColor Gray; [void][System.Console]::ReadLine(); exit }
}

# ---- 1. Estado actual ----
Sub "[1] Estado actual del adaptador"
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.HardwareInterface -eq $true }
if (-not $adapters) {
  Write-Host "  [ERROR] No hay ningun adaptador de red activo." -ForegroundColor Red
  Write-Host "  Conecta el cable de red y volve a ejecutar." -ForegroundColor Red
  Write-Host ""; Write-Host "Presiona ENTER..." -ForegroundColor Gray; [void][System.Console]::ReadLine(); exit
}

for ($i = 0; $i -lt $adapters.Count; $i++) {
  $a = $adapters[$i]
  $ipsA = @(Get-NetIPAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.IPAddress -notlike '169.254.*' } |
            Select-Object -ExpandProperty IPAddress)
  Write-Host ("  [{0}] {1}  ({2})  IPs=[{3}]" -f $i, $a.Name, $a.InterfaceDescription, ($ipsA -join ', '))
}

# ---- 2. Elegir adaptador ----
Sub "[2] Elegir adaptador Ethernet"
$eth = $adapters | Where-Object { $_.MediaType -eq '802.3' -or $_.PhysicalMediaType -match 'Ethernet|802.3' -or $_.Name -match 'Ethernet' } | Select-Object -First 1
if (-not $eth) { $eth = $adapters | Select-Object -First 1 }

if ($adapters.Count -gt 1) {
  Write-Host "  Sugerencia: adaptador '$($eth.Name)' (Ethernet)."
  $sel = Read-Host "  Indice del adaptador a configurar (ENTER=$($eth.Name))"
  if ($sel -match '^\d+$' -and [int]$sel -lt $adapters.Count) {
    $eth = $adapters[[int]$sel]
  }
} else {
  Write-Host "  Solo hay un adaptador. Se usa: $($eth.Name)"
}
Write-Host ("  Adaptador elegido: {0}  (ifIndex={1})" -f $eth.Name, $eth.ifIndex) -ForegroundColor Cyan

# ---- 3. Backup config actual ----
Sub "[3] Backup de la config IP actual del adaptador"
$backup = "C:\fcea_ip_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$dump = @()
$dump += "Adapter: $($eth.Name)"
$dump += "InterfaceDescription: $($eth.InterfaceDescription)"
$dump += "ifIndex: $($eth.ifIndex)"
$dump += "--- IPs ---"
$dump += (Get-NetIPAddress -InterfaceIndex $eth.ifIndex -AddressFamily IPv4 | Format-Table -AutoSize | Out-String)
$dump += "--- Rutas ---"
$dump += (Get-NetRoute -InterfaceIndex $eth.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Format-Table -AutoSize | Out-String)
$dump += "--- DNS ---"
$dump += (Get-DnsClientServerAddress -InterfaceIndex $eth.ifIndex -AddressFamily IPv4 | Format-Table -AutoSize | Out-String)
$dump | Set-Content -Path $backup -Encoding UTF8
Write-Host "  Backup guardado en: $backup" -ForegroundColor Green

# ---- 4. Aplicar IP estatica ----
Sub "[4] Aplicando IP estatica 192.168.100.10/24"
try {
  # Quitar IPs anteriores para evitar conflicto
  Get-NetIPAddress -InterfaceIndex $eth.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.PrefixOrigin -ne 'WellKnown' } |
    ForEach-Object {
      try { Remove-NetIPAddress -InterfaceIndex $_.InterfaceIndex -IPAddress $_.IPAddress -Confirm:$false -ErrorAction SilentlyContinue } catch {}
    }
  # Poner en manual (deshabilitar DHCP)
  Set-NetIPInterface -InterfaceIndex $eth.ifIndex -Dhcp Disabled -ErrorAction SilentlyContinue
  # Asignar la IP
  New-NetIPAddress -InterfaceIndex $eth.ifIndex -IPAddress '192.168.100.10' -PrefixLength 24 -ErrorAction Stop | Out-Null
  Write-Host "  [OK] IP 192.168.100.10/24 asignada." -ForegroundColor Green
} catch {
  Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "  Se puede intentar con netsh como fallback." -ForegroundColor Yellow
  $r = & netsh interface ip set address name="$($eth.Name)" static 192.168.100.10 255.255.255.0 2>&1
  Write-Host "  netsh: $r" -ForegroundColor Gray
}

# ---- 5. Verificar ----
Sub "[5] Verificando"
Start-Sleep -Seconds 1
$ipFinal = Get-NetIPAddress -InterfaceIndex $eth.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
           Where-Object { $_.IPAddress -notlike '169.254.*' } |
           Select-Object -ExpandProperty IPAddress
Write-Host "  IPs finales del adaptador: [$($ipFinal -join ', ')]"
if ($ipFinal -contains '192.168.100.10') {
  Write-Host "  [OK] El Monitor ahora tiene la IP 192.168.100.10" -ForegroundColor Green
} else {
  Write-Host "  [!] No se pudo confirmar la IP. Ver el detalle arriba." -ForegroundColor Red
}

# Test rapido al PocketBase local
Sub "[6] Test HTTP al PocketBase local"
try {
  $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8090/api/health' -TimeoutSec 3 -UseBasicParsing
  Write-Host "  PocketBase local: HTTP $($r.StatusCode)" -ForegroundColor Green
} catch {
  Write-Host "  PocketBase local: SIN RESPUESTA ($($_.Exception.Message))" -ForegroundColor Yellow
}
try {
  $r = Invoke-WebRequest -Uri 'http://192.168.100.10:8090/api/health' -TimeoutSec 3 -UseBasicParsing
  Write-Host "  PocketBase via 192.168.100.10: HTTP $($r.StatusCode)" -ForegroundColor Green
} catch {
  Write-Host "  PocketBase via 192.168.100.10: SIN RESPUESTA" -ForegroundColor Yellow
}

Write-Host ""
Line
Write-Host "  LISTO. Ahora en Terminal-A hacer un pedido y ver en el Monitor." -ForegroundColor Green
Write-Host "  Si algo falla se puede restaurar la config con el backup:" -ForegroundColor Gray
Write-Host "    $backup" -ForegroundColor Gray
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
