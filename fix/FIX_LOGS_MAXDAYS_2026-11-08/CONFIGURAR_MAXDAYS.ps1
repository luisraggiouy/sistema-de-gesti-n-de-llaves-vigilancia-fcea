# ============================================================
# CONFIGURAR maxDays DE LOGS EN POCKETBASE  (FCEA) - 2026-11-08
# ============================================================
# Pone Settings.Logs.MaxDays = 7 para que PocketBase borre solos los
# logs de mas de 7 dias (evita que logs.db vuelva a crecer a GBs).
#
# ROBUSTO: health check TCP previo (timeout real) + varios reintentos
# de autenticacion y del PATCH. Si PocketBase no responde, avisa y sale
# sin romper nada. NO toca datos. Correr en el MONITOR.
# ============================================================
param(
  [string]$BaseUrl  = 'http://127.0.0.1:8090',
  [string]$Identity = 'vigilancia@llaves.local',
  [string]$Password = 'vigilanciamvp2026',
  [int]$MaxDays     = 7,
  [string]$LogDir,
  [switch]$NoPause
)
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

if (-not $LogDir) {
  $pen = Split-Path (Split-Path $PSScriptRoot)
  $cand = Join-Path $pen '_RESULTADOS'
  $LogDir = if (Test-Path $cand) { $cand } else { $PSScriptRoot }
}
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$LOG = Join-Path $LogDir ("LOG_MAXDAYS_" + $env:COMPUTERNAME + "_" + $stamp + ".log")
function L { param([string]$m) $m | Tee-Object -FilePath $LOG -Append }

L ("================================================")
L ("CONFIGURAR maxDays=$MaxDays   " + (Get-Date) + "   PC: " + $env:COMPUTERNAME)
L ("================================================")

# --- 1) health check TCP (timeout real) con reintentos ---
function Test-PbTcp {
  try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $iar = $tcp.BeginConnect('127.0.0.1', 8090, $null, $null)
    $ok = $iar.AsyncWaitHandle.WaitOne(3000, $false) -and $tcp.Connected
    $tcp.Close(); return $ok
  } catch { return $false }
}
$vivo = $false
for ($i=1; $i -le 10; $i++) {
  if (Test-PbTcp) { $vivo = $true; break }
  L ("  [..] PocketBase no responde aun (intento $i/10). Esperando 3s...")
  Start-Sleep -Seconds 3
}
if (-not $vivo) {
  L ("  [ERROR] PocketBase no responde en $BaseUrl tras varios intentos.")
  L ("          Verifica que el sistema este prendido y PocketBase corriendo, y reintenta.")
  L ("Log: " + $LOG)
  if (-not $NoPause) { Write-Host "ENTER para cerrar..."; [void][System.Console]::ReadLine() }
  return
}
L ("  [OK] PocketBase responde (TCP 8090).")

# --- 2) autenticar superusuario (con reintentos y ambos endpoints) ---
$token = $null
$authBody = @{ identity = $Identity; password = $Password } | ConvertTo-Json
for ($i=1; $i -le 5 -and -not $token; $i++) {
  foreach ($u in @("$BaseUrl/api/collections/_superusers/auth-with-password","$BaseUrl/api/admins/auth-with-password")) {
    try {
      $r = Invoke-RestMethod -Uri $u -Method Post -Body $authBody -ContentType 'application/json' -TimeoutSec 20
      if ($r.token) { $token = $r.token; break }
    } catch {}
  }
  if (-not $token) { L ("  [..] auth intento $i/5 sin exito; reintento en 2s..."); Start-Sleep -Seconds 2 }
}
if (-not $token) {
  L ("  [ERROR] No se pudo autenticar como superusuario. Revisar credenciales.")
  L ("Log: " + $LOG)
  if (-not $NoPause) { Write-Host "ENTER para cerrar..."; [void][System.Console]::ReadLine() }
  return
}
L ("  [OK] Autenticado como superusuario.")

# --- 3) PATCH /api/settings {logs:{maxDays}} con reintentos ---
$hdr = @{ Authorization = $token }
$body = ('{"logs":{"maxDays":' + $MaxDays + '}}')
$done = $false
for ($i=1; $i -le 5 -and -not $done; $i++) {
  try {
    Invoke-RestMethod -Uri "$BaseUrl/api/settings" -Method Patch -Headers $hdr -Body $body -ContentType 'application/json' -TimeoutSec 30 | Out-Null
    $done = $true
  } catch {
    L ("  [..] PATCH intento $i/5 fallo: " + $_.Exception.Message + " ; reintento en 3s...")
    Start-Sleep -Seconds 3
  }
}
if (-not $done) {
  L ("  [ERROR] No se pudo aplicar maxDays via API tras 5 intentos.")
  L ("Log: " + $LOG)
  if (-not $NoPause) { Write-Host "ENTER para cerrar..."; [void][System.Console]::ReadLine() }
  return
}
L ("  [OK] logs.maxDays = $MaxDays aplicado.")

# --- 4) VERIFICAR leyendo settings de vuelta ---
try {
  $s = Invoke-RestMethod -Uri "$BaseUrl/api/settings" -Method Get -Headers $hdr -TimeoutSec 20
  $actual = $s.logs.maxDays
  if ($actual -eq $MaxDays) { L ("  [VERIFICADO] settings.logs.maxDays = $actual") }
  else { L ("  [ALERTA] settings devuelve maxDays=$actual (esperado $MaxDays)") }
} catch {
  L ("  [WARN] no pude releer settings para verificar: " + $_.Exception.Message)
}

L ("")
L ("LISTO. maxDays configurado. logs.db ya no crecera sin limite.")
L ("Log: " + $LOG)
if (-not $NoPause) { Write-Host ""; Write-Host "ENTER para cerrar..." -ForegroundColor Gray; [void][System.Console]::ReadLine() }
