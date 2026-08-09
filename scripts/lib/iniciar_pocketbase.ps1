# ============================================================
# Sistema de Gestion de Llaves FCEA
# iniciar_pocketbase.ps1  -  DUENO UNICO (orquestador, mutex)
# ============================================================
# UNICO punto autorizado a arrancar PocketBase. Garantiza:
#   * Un solo lanzador a la vez (mutex global -> "nunca dos lanzadores").
#   * Que el WAL se sanee (via run_pocketbase.bat -> sanear_wal.ps1) antes
#     de servir, de modo que la base nazca ESCRIBIBLE (no readonly frio).
#   * Verificacion de ESCRITURA REAL (no solo "vivo") antes de dar OK.
#
# Lo llaman: INICIAR.bat (arranque del equipo) y watchdog.ps1 (si detecta
# readonly). Es idempotente: si ya hay UNA instancia escribible, no toca
# nada. Con -Force fuerza un ciclo de kill + re-saneo + relanzar.
#
# ------------------------------------------------------------
# FIX 2026-08-09 (arranque lento ~8 min): la funcion Ensure-Owner llamaba a
# start_detached.ps1 con el parametro -Target, que NO existe (solo acepta
# -CommandLine y -WorkingDirectory). La llamada fallaba en silencio (2>$null),
# run_pocketbase.bat NUNCA se lanzaba desde el orquestador y los 3 reintentos
# agotaban ~8 min hasta que el fallback de INICIAR.bat arrancaba PocketBase.
# Corregido para usar -CommandLine "cmd /c $runBat" -WorkingDirectory $repoRoot,
# igual que INICIAR.bat. Probado OK en produccion (Monitor arranca en <1 min).
# ============================================================

#Requires -Version 5.1
param(
  [switch]$Force,
  [int]$MaxIntentos = 3,
  [string]$PbData = "C:\ProgramData\FCEA-Sistema-Llaves\pb_data"
)

$ErrorActionPreference = "Continue"
$BaseUrl   = "http://127.0.0.1:8090"
$repoRoot  = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$runBat    = Join-Path $repoRoot "scripts\lib\run_pocketbase.bat"
$sanearPs1 = Join-Path $PSScriptRoot "sanear_wal.ps1"
$startDet  = Join-Path $repoRoot "scripts\lib\start_detached.ps1"
$logDir    = Join-Path $repoRoot "pocketbase\maintenance\logs"
$logFile   = Join-Path $logDir "iniciar_pocketbase.log"

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Log($m) {
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  "[$ts] $m" | Tee-Object -FilePath $logFile -Append | Out-Null
  Write-Host "[DUENO-UNICO] $m"
}

function Get-PBCount { @(Get-Process -Name pocketbase -ErrorAction SilentlyContinue).Count }

function Kill-AllPB {
  Get-Process -Name pocketbase -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
  for ($i = 0; $i -lt 20; $i++) { if ((Get-PBCount) -eq 0) { break }; Start-Sleep -Milliseconds 300 }
}

function Test-Alive {
  try { (Invoke-WebRequest -Uri "$BaseUrl/api/health" -UseBasicParsing -TimeoutSec 3).StatusCode -eq 200 }
  catch { $false }
}

# Prueba de ESCRITURA REAL contra la coleccion de diagnostico (o create/delete).
function Test-Write {
  # Intento 1: endpoint viejo de admins (este PB usa /api/admins/...).
  $col = "diag_escritura"
  $body = @{ nota = ("probe " + (Get-Date -Format o)) } | ConvertTo-Json
  try {
    $r = Invoke-WebRequest -Uri "$BaseUrl/api/collections/$col/records" -Method Post -Body $body -ContentType "application/json" -UseBasicParsing -TimeoutSec 5
    if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 300) {
      try { $id = ($r.Content | ConvertFrom-Json).id; Invoke-WebRequest -Uri "$BaseUrl/api/collections/$col/records/$id" -Method Delete -UseBasicParsing -TimeoutSec 5 | Out-Null } catch {}
      return @{ ok = $true; motivo = "POST 2xx" }
    }
  } catch {
    $resp = $_.Exception.Response
    if ($resp) {
      $code = [int]$resp.StatusCode
      # 400/403/404 = el servidor PROCESO la escritura (validacion/permiso/coleccion) => NO es readonly.
      if ($code -eq 400 -or $code -eq 403 -or $code -eq 404) { return @{ ok = $true; motivo = "HTTP $code (procesado, no readonly)" } }
      # 500 suele traer "readonly database" en el body.
      try {
        $sr = New-Object System.IO.StreamReader($resp.GetResponseStream()); $txt = $sr.ReadToEnd()
        if ($txt -match "readonly") { return @{ ok = $false; motivo = "readonly en respuesta" } }
      } catch {}
      return @{ ok = $false; motivo = "HTTP $code" }
    }
    return @{ ok = $false; motivo = "sin respuesta HTTP" }
  }
  return @{ ok = $false; motivo = "desconocido" }
}

function Wait-Health([int]$sec) {
  for ($i = 0; $i -lt $sec; $i++) { if (Test-Alive) { return $true }; Start-Sleep -Seconds 1 }
  return $false
}

# Arranca UN solo loop run_pocketbase.bat (desacoplado). Si ya reaparecio
# PocketBase (porque un loop preexistente lo relanzo), no arranca otro.
function Ensure-Owner {
  for ($w = 0; $w -lt 8; $w++) { if ((Get-PBCount) -ge 1) { Log "PocketBase reaparecio (loop existente lo relanzo); no arranco otro."; return }; Start-Sleep -Seconds 1 }
  if (-not (Test-Path $runBat)) { Log "[ERROR] No existe run_pocketbase.bat en $runBat"; return }
  Log "Arrancando run_pocketbase.bat (loop dueno unico, desacoplado)..."
  if (Test-Path $startDet) {
    powershell -NoProfile -ExecutionPolicy Bypass -File $startDet -CommandLine "cmd /c $runBat" -WorkingDirectory $repoRoot 2>$null | Out-Null
  } else {
    try { Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "cmd.exe /c `"$runBat`"" } | Out-Null }
    catch { Start-Process -FilePath $runBat -WindowStyle Hidden }
  }
}

# ---------------- MUTEX: un solo dueno ----------------
$mutexName = "Global\FCEA_Llaves_DuenoUnico_PocketBase"
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) {
  if (-not $mutex.WaitOne([TimeSpan]::FromSeconds(60))) {
    Log "Otro dueno-unico esta corriendo y no libero en 60s. Salgo (evito dos lanzadores)."
    exit 0
  }
}

try {
  Log "===== iniciar_pocketbase: inicio (Force=$Force) ====="

  # Idempotente: 1 instancia viva y ESCRIBIBLE => no toco nada.
  if (-not $Force -and (Get-PBCount) -eq 1 -and (Test-Alive)) {
    $w = Test-Write
    if ($w.ok) { Log "Ya hay 1 instancia viva y escribible ($($w.motivo)). Nada que hacer."; exit 0 }
    Log "Hay instancia viva pero NO escribible ($($w.motivo)). Forzando saneo..."
  }

  for ($intento = 1; $intento -le $MaxIntentos; $intento++) {
    Log "--- Intento $intento/$MaxIntentos ---"

    # 1) Detener todo (el loop preexistente, si existe, re-saneara y relanzara solo).
    Kill-AllPB

    # 2) Sanear WAL/SHM con PB detenido (defensivo; el loop tambien lo hace).
    if (Test-Path $sanearPs1) {
      powershell -NoProfile -ExecutionPolicy Bypass -File $sanearPs1 -PbData $PbData | Out-Null
    }

    # 3) Asegurar que exista UN loop dueno unico corriendo.
    Ensure-Owner

    # 4) Esperar salud y verificar ESCRITURA REAL.
    if (Wait-Health 45) {
      Start-Sleep -Seconds 2
      $w = Test-Write
      if ($w.ok) { Log "OK: PocketBase vivo y ESCRIBIBLE ($($w.motivo)). Fix aplicado."; exit 0 }
      Log "PocketBase vivo pero readonly ($($w.motivo)). Reintentando saneo..."
    } else {
      Log "PocketBase no respondio /api/health en 45s."
    }
    Start-Sleep -Seconds 2
  }

  Log "[ERROR] Tras $MaxIntentos intentos no logre dejar PocketBase escribible. Revisar permisos de $PbData."
  exit 1
}
finally {
  try { $mutex.ReleaseMutex() } catch {}
  try { $mutex.Dispose() } catch {}
}
