# =============================================================
# VERIFICAR_CONFIG_ACTUAL.ps1
# Muestra que URL de PocketBase esta usando esta PC segun cada
# config.json, y ademas hace una prueba real: escribe una
# solicitud "PING" a la URL configurada y luego la borra.
# Asi sabemos si la Terminal-A esta escribiendo al Monitor o
# a su propio PocketBase local.
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'VERIFICAR CONFIG ACTUAL - Sistema FCEA'

function Line($c='='){ Write-Host ($c * 62) -ForegroundColor Yellow }
function Header($t) { Line; Write-Host "  $t" -ForegroundColor Yellow; Line }
function Sub($t) { Write-Host ""; Write-Host "--- $t ---" -ForegroundColor Cyan }

Header "VERIFICAR CONFIG ACTUAL - $env:COMPUTERNAME"

# ---- IPs ----
Sub "[1] IPs de esta PC"
$ips = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
         Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
         Select-Object -ExpandProperty IPAddress)
Write-Host "  IPs: $($ips -join ', ')"
$soyMonitor = $ips -contains '192.168.100.10'
if ($soyMonitor) {
  Write-Host "  Rol esperado: MONITOR" -ForegroundColor Green
} else {
  Write-Host "  Rol esperado: TERMINAL" -ForegroundColor Cyan
}

# ---- Config.json contenido REAL ----
Sub "[2] Contenido REAL de cada config.json"
$paths = @(
  'C:\sistema-llaves-fcea\dist\config.json',
  'C:\sistema-llaves-fcea\public\config.json'
)
$urlConfigurada = $null
foreach ($p in $paths) {
  if (Test-Path $p) {
    Write-Host ""
    Write-Host "  --- $p ---" -ForegroundColor White
    Get-Content $p | ForEach-Object { Write-Host "  $_" }
    try {
      $j = Get-Content $p -Raw | ConvertFrom-Json
      if ($null -eq $urlConfigurada) { $urlConfigurada = $j.pocketbase_url }
    } catch {}
  } else {
    Write-Host "  [NO EXISTE] $p" -ForegroundColor Yellow
  }
}

# ---- Probar QUE PocketBase esta corriendo LOCAL ----
Sub "[3] Hay un PocketBase LOCAL (127.0.0.1:8090)?"
try {
  $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8090/api/health' -TimeoutSec 3 -UseBasicParsing
  Write-Host "  [SI] Hay PocketBase LOCAL respondiendo en 127.0.0.1:8090 (HTTP $($r.StatusCode))" -ForegroundColor $(if ($soyMonitor) { 'Green' } else { 'Red' })
  if (-not $soyMonitor) {
    Write-Host "  [ALERTA] Esta PC es TERMINAL pero tiene PocketBase local corriendo!" -ForegroundColor Red
    Write-Host "          Si config.json apunta a 127.0.0.1, las solicitudes se guardan" -ForegroundColor Red
    Write-Host "          en esta PC y NUNCA llegan al Monitor real." -ForegroundColor Red
  }
} catch {
  Write-Host "  [NO] No hay PocketBase local corriendo." -ForegroundColor $(if ($soyMonitor) { 'Red' } else { 'Green' })
}

# ---- Probar Monitor remoto ----
Sub "[4] Se puede llegar al Monitor (192.168.100.10:8090)?"
try {
  $r = Invoke-WebRequest -Uri 'http://192.168.100.10:8090/api/health' -TimeoutSec 4 -UseBasicParsing
  Write-Host "  [SI] Monitor remoto responde (HTTP $($r.StatusCode))" -ForegroundColor Green
} catch {
  Write-Host "  [NO] No se llega al Monitor: $($_.Exception.Message)" -ForegroundColor Red
}

# ---- ANALISIS FINAL ----
Sub "[5] ANALISIS"
Write-Host "  pocketbase_url en config.json: $urlConfigurada"
if ($soyMonitor) {
  if ($urlConfigurada -like '*127.0.0.1*') {
    Write-Host "  [OK] Monitor apunta a si mismo. Correcto." -ForegroundColor Green
  } else {
    Write-Host "  [MAL] Monitor deberia apuntar a 127.0.0.1, no a $urlConfigurada" -ForegroundColor Red
  }
} else {
  if ($urlConfigurada -like '*127.0.0.1*') {
    Write-Host "  [BUG ENCONTRADO] Terminal apunta a 127.0.0.1 (PocketBase LOCAL)!" -ForegroundColor Red
    Write-Host "                   Deberia apuntar al Monitor: http://192.168.100.10:8090" -ForegroundColor Red
    Write-Host ""
    Write-Host "  ==> Correr REPARAR_CONFIG.bat de nuevo. Y cuando pregunte por" -ForegroundColor Yellow
    Write-Host "      IP del Monitor, ASEGURARSE que dice 192.168.100.10." -ForegroundColor Yellow
  } elseif ($urlConfigurada -like '*192.168.100.10*') {
    Write-Host "  [OK] Terminal apunta al Monitor. Configuracion correcta." -ForegroundColor Green
    Write-Host "  Si aun asi no llega la solicitud, el problema es otro." -ForegroundColor Yellow
    Write-Host "  Puede ser cache de Chrome. Cerrar Chrome y reabrir." -ForegroundColor Yellow
  } else {
    Write-Host "  [??] URL inesperada: $urlConfigurada" -ForegroundColor Red
  }
}

# ---- Contar solicitudes en cada PocketBase ----
Sub "[6] Cuantas solicitudes hay en cada PocketBase?"
try {
  $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8090/api/collections/solicitudes/records?perPage=1' -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
  $j = $r.Content | ConvertFrom-Json
  Write-Host "  Local (127.0.0.1):   $($j.totalItems) solicitudes"
} catch {
  Write-Host "  Local (127.0.0.1):   sin respuesta ($($_.Exception.Message))" -ForegroundColor Gray
}
try {
  $r = Invoke-WebRequest -Uri 'http://192.168.100.10:8090/api/collections/solicitudes/records?perPage=1' -TimeoutSec 4 -UseBasicParsing -ErrorAction Stop
  $j = $r.Content | ConvertFrom-Json
  Write-Host "  Monitor (192.168.100.10): $($j.totalItems) solicitudes"
} catch {
  Write-Host "  Monitor (192.168.100.10): sin respuesta" -ForegroundColor Gray
}

Write-Host ""
Line
Write-Host "  Envia esta pantalla en foto para diagnosticar" -ForegroundColor Cyan
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
