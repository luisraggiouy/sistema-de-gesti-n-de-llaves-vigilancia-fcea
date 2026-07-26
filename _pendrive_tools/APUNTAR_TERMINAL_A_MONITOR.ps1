# =============================================================
# APUNTAR_TERMINAL_A_MONITOR.ps1
# SOLO EJECUTAR EN UNA TERMINAL.
# Reescribe C:\sistema-llaves-fcea\dist\config.json y
# C:\sistema-llaves-fcea\public\config.json para que apunten a
# la IP del monitor. Por defecto sugiere 192.168.100.10.
# Prueba conectividad antes de aceptar. Mata Chrome y lo relanza
# (opcional).
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'APUNTAR TERMINAL A MONITOR - Sistema FCEA'

function Line($c='='){ Write-Host ($c * 62) -ForegroundColor Yellow }
function H($t)  { Line; Write-Host "  $t" -ForegroundColor Yellow; Line }
function Sub($t){ Write-Host ""; Write-Host "--- $t ---" -ForegroundColor Cyan }

H "APUNTAR TERMINAL AL MONITOR - $env:COMPUTERNAME"

# ---- 1. Estado actual ----
Sub "[1] Estado actual de config.json"
$paths = @(
  'C:\sistema-llaves-fcea\dist\config.json',
  'C:\sistema-llaves-fcea\public\config.json'
)
$found = @()
foreach ($p in $paths) {
  if (Test-Path $p) {
    try {
      $j = Get-Content $p -Raw | ConvertFrom-Json
      Write-Host ("  {0}" -f $p)
      Write-Host ("     rol={0}  pocketbaseUrl={1}" -f $j.rol, $j.pocketbaseUrl)
      $found += @{ path = $p; json = $j }
    } catch {
      Write-Host ("  {0}  [ERROR JSON]" -f $p) -ForegroundColor Red
    }
  }
}
if ($found.Count -eq 0) {
  Write-Host "  [ERROR] No se encontro ningun config.json" -ForegroundColor Red
  Write-Host "  Esperado en C:\sistema-llaves-fcea\dist\config.json" -ForegroundColor Red
  Write-Host ""; Write-Host "Presiona ENTER..." -ForegroundColor Gray; [void][System.Console]::ReadLine(); exit
}

# ---- 2. Pedir IP del monitor ----
Sub "[2] IP del Monitor"
$actual = $found[0].json.pocketbaseUrl
$sugerida = '192.168.100.10'
Write-Host "  URL actual:   $actual"
Write-Host "  IP sugerida:  $sugerida"
$nueva = Read-Host "  IP del Monitor (ENTER = $sugerida)"
if ([string]::IsNullOrWhiteSpace($nueva)) { $nueva = $sugerida }
if ($nueva -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
  Write-Host "  [ERROR] IP invalida: $nueva" -ForegroundColor Red
  Write-Host ""; Write-Host "Presiona ENTER..." -ForegroundColor Gray; [void][System.Console]::ReadLine(); exit
}
$nuevaUrl = "http://${nueva}:8090"
Write-Host "  Nueva URL:    $nuevaUrl" -ForegroundColor Cyan

# ---- 3. Test de conectividad ANTES de guardar ----
Sub "[3] Test HTTP a $nuevaUrl/api/health"
$okServer = $false
try {
  $r = Invoke-WebRequest -Uri "$nuevaUrl/api/health" -TimeoutSec 4 -UseBasicParsing
  Write-Host ("  HTTP {0} - {1} ms" -f $r.StatusCode, $r.Headers.'X-Response-Time') -ForegroundColor Green
  $okServer = $true
} catch {
  Write-Host ("  [ERROR] {0}" -f $_.Exception.Message) -ForegroundColor Red
  Write-Host "  El Monitor no responde en esa IP. Confirmar que:" -ForegroundColor Yellow
  Write-Host "    - El Monitor esta encendido"
  Write-Host "    - Comparten la misma red LAN"
  Write-Host "    - El firewall del Monitor permite el puerto 8090"
  Write-Host "    - En el Monitor pocketbase.exe esta corriendo"
  Write-Host ""
  $c = Read-Host "  Continuar de todos modos y guardar la config? (S/N, default N)"
  if ($c -notmatch '^[sS]') {
    Write-Host "  Abortado sin guardar." -ForegroundColor Green
    Write-Host ""; Write-Host "Presiona ENTER..." -ForegroundColor Gray; [void][System.Console]::ReadLine(); exit
  }
}

# ---- 4. Escribir config.json ----
Sub "[4] Escribiendo config.json"
foreach ($f in $found) {
  $p = $f.path
  $j = $f.json
  # Backup
  $bak = "$p.bak.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
  Copy-Item $p $bak -Force
  Write-Host "  Backup: $bak" -ForegroundColor Gray

  $j.pocketbaseUrl = $nuevaUrl
  $out = $j | ConvertTo-Json -Depth 5
  Set-Content -Path $p -Value $out -Encoding UTF8
  Write-Host ("  [OK] {0}  =>  pocketbaseUrl={1}" -f $p, $nuevaUrl) -ForegroundColor Green
}

# ---- 5. Refrescar Chrome ----
Sub "[5] Reiniciar Chrome (kiosk) para tomar el cambio"
$r = Read-Host "  Matar Chrome ahora para que recargue con la nueva URL? (S/N, default S)"
if ($r -notmatch '^[nN]') {
  Get-Process -Name chrome -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Get-Process -Name msedge -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 1
  Write-Host "  [OK] Chrome cerrado. El sistema o el usuario lo van a relanzar solos." -ForegroundColor Green
  Write-Host "  (Si no arranca solo, doble click en 'ARRANCAR SISTEMA' del escritorio.)" -ForegroundColor Gray
} else {
  Write-Host "  Dejando Chrome como esta. Recarga la pagina manualmente con F5." -ForegroundColor Gray
}

Write-Host ""
Line
if ($okServer) {
  Write-Host "  LISTO - Terminal apunta a $nuevaUrl y el Monitor responde." -ForegroundColor Green
} else {
  Write-Host "  Guardado, pero el Monitor NO respondia en el test." -ForegroundColor Yellow
  Write-Host "  Correr DIAGNOSTICAR_RED.bat para ver que falta." -ForegroundColor Yellow
}
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
