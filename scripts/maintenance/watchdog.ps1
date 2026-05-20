# ============================================================
# Sistema de Gestion de Llaves FCEA v2.0
# Watchdog del servidor PocketBase
# ============================================================
# Verifica cada N segundos que PocketBase esta respondiendo.
# Si no responde, lo relanza. Solo se ejecuta en la PC servidor
# (rol = monitor). Si se ejecuta en una terminal, se autodetiene.
# ============================================================

#Requires -Version 5.1

param(
  [int]$IntervaloSegundos = 30,
  [string]$Url = "http://127.0.0.1:8090/api/health"
)

$ErrorActionPreference = "Continue"

$repoRoot      = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$configPath    = Join-Path $repoRoot "public\config.json"
$startServer   = Join-Path $repoRoot "pocketbase\start-server.bat"
$logFile       = Join-Path $repoRoot "pocketbase\maintenance\logs\watchdog.log"

# Crear carpeta de logs si no existe.
New-Item -ItemType Directory -Force -Path (Split-Path $logFile) | Out-Null

function Log {
  param([string]$Msg)
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  "[$ts] $Msg" | Tee-Object -FilePath $logFile -Append
}

# Verificar rol: solo correr en monitor.
if (Test-Path $configPath) {
  try {
    $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
    if ($cfg.rol -ne "monitor") {
      Log "Rol = $($cfg.rol). Watchdog solo corre en 'monitor'. Saliendo."
      exit 0
    }
  } catch {
    Log "No se pudo leer config.json: $_. Continuando de todos modos."
  }
} else {
  Log "config.json no existe. Continuando con defaults."
}

Log "Watchdog iniciado. URL=$Url, intervalo=${IntervaloSegundos}s"

while ($true) {
  $ok = $false
  try {
    $r = Invoke-WebRequest -Uri $Url -TimeoutSec 5 -UseBasicParsing
    if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500) { $ok = $true }
  } catch {
    $ok = $false
  }

  if (-not $ok) {
    Log "PocketBase NO responde. Relanzando..."
    # Intentar matar procesos colgados primero.
    Get-Process -Name pocketbase -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process -FilePath $startServer -WindowStyle Minimized
    Log "Servidor relanzado. Esperando 10s para verificar..."
    Start-Sleep -Seconds 10
  }

  Start-Sleep -Seconds $IntervaloSegundos
}
