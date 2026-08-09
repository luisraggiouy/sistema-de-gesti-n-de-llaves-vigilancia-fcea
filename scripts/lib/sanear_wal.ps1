# ============================================================
# Sistema de Gestion de Llaves FCEA
# sanear_wal.ps1  -  SANEADOR REAL DEL WAL (corazon del fix de raiz)
# ============================================================
# Se ejecuta con PocketBase DETENIDO, JUSTO ANTES de cada arranque
# de pocketbase.exe (lo llama el loop de run_pocketbase.bat en CADA
# iteracion, y tambien iniciar_pocketbase.ps1). Deja la base en un
# estado 100% escribible para que SQLite NO reabra en solo-lectura.
#
# POR QUE (diagnostico cerrado 02/08/2026, 99% certeza):
#   El log del Monitor mostro cientos de:
#       "attempt to write a readonly database (8)"  (SQLITE_READONLY)
#   con UNA sola instancia y UN solo lanzador. La base a nivel archivo
#   NO era readonly: SQLite la reabria en solo-lectura por los archivos
#   data.db-wal / data.db-shm colgados de un apagado duro.
#   El band-aid anterior mataba+relanzaba SIN tocar el WAL -> PB reabria
#   el MISMO WAL trabado -> readonly de nuevo. Ese era el agujero.
#
# QUE HACE (seguro, sin perder datos):
#   1) Mata cualquier pocketbase.exe suelto y espera acceso EXCLUSIVO.
#   2) Rota el pocketbase.log si es gigante (higiene; hoy +1M lineas).
#   3) Quita atributos Read-Only/System de toda la carpeta pb_data.
#   4) Verifica que el directorio pb_data sea ESCRIBIBLE (probe file).
#   5) Backup preventivo de data.db (+ -wal/-shm) rotado (ultimos 10).
#   6) SANEA el WAL:
#        - si data.db-wal NO existe o mide 0 bytes  -> borra -wal y -shm
#          (arranque totalmente limpio; caso de hoy, sin riesgo).
#        - si data.db-wal TRAE datos (>0 bytes)     -> CONSERVA -wal y
#          borra SOLO -shm; al abrir, SQLite reconstruye -shm y REPRODUCE
#          el -wal (checkpoint de recuperacion) sin perder transacciones.
#   Tras esto, el arranque de pocketbase.exe recrea -wal/-shm limpios y
#   la base queda ESCRIBIBLE.
# Exit 0 siempre (best-effort; no debe abortar el arranque).
# ============================================================

#Requires -Version 5.1
param(
  [string]$PbData = "C:\ProgramData\FCEA-Sistema-Llaves\pb_data",
  [int]$LogMaxMB = 5
)

$ErrorActionPreference = "Continue"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$dataDb   = Join-Path $PbData "data.db"
$walFile  = "$dataDb-wal"
$shmFile  = "$dataDb-shm"
$backupDir= Join-Path $PbData "_backups_arranque"
$pbLog    = Join-Path $repoRoot "logs\pocketbase.log"
$logDir   = Join-Path $repoRoot "pocketbase\maintenance\logs"
$logFile  = Join-Path $logDir  "sanear_wal.log"

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Log($m) {
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  "[$ts] $m" | Tee-Object -FilePath $logFile -Append | Out-Null
  Write-Host "   [SANEAR-WAL] $m"
}

function Get-PBCount {
  @(Get-Process -Name pocketbase -ErrorAction SilentlyContinue).Count
}

function Kill-AllPB {
  Get-Process -Name pocketbase -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
  for ($i = 0; $i -lt 20; $i++) {
    if ((Get-PBCount) -eq 0) { break }
    Start-Sleep -Milliseconds 300
  }
}

function Test-Exclusive {
  if (-not (Test-Path $dataDb)) { return $true }
  try {
    $fs = [System.IO.File]::Open($dataDb, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    $fs.Close(); $fs.Dispose()
    return $true
  } catch { return $false }
}

Log "===== Saneo de WAL: inicio (pb_data=$PbData) ====="

# --- 1) Acceso exclusivo (no debe haber PB corriendo en este punto) ---
if ((Get-PBCount) -ge 1) {
  Log "Habia pocketbase.exe corriendo; lo detengo para sanear con exclusividad."
  Kill-AllPB
}
$exclusivo = $false
for ($i = 0; $i -lt 12; $i++) {
  if ((Get-PBCount) -ge 1) { Kill-AllPB }
  if (Test-Exclusive) { $exclusivo = $true; break }
  Start-Sleep -Milliseconds 500
}
if (-not $exclusivo) { Log "[ADVERTENCIA] No logre acceso exclusivo a data.db; saneo best-effort igual." }

# --- 2) Rotar pocketbase.log si es gigante (higiene) ---
if (Test-Path $pbLog) {
  try {
    $sizeMB = (Get-Item $pbLog).Length / 1MB
    if ($sizeMB -gt $LogMaxMB) {
      $old = "$pbLog.1"
      if (Test-Path $old) { Remove-Item $old -Force -ErrorAction SilentlyContinue }
      Move-Item $pbLog $old -Force -ErrorAction Stop
      Log ("pocketbase.log rotado ({0} MB -> pocketbase.log.1)." -f [math]::Round($sizeMB,1))
    }
  } catch {
    Log "No se pudo rotar pocketbase.log (quiza en uso): $($_.Exception.Message)"
  }
}

# --- 3) Quitar atributos Read-Only/System de pb_data ---
if (Test-Path $PbData) {
  try { & attrib -R -S "$PbData" /D 2>$null | Out-Null } catch {}
  try { & attrib -R -S "$PbData\*" /S /D 2>$null | Out-Null } catch {}
  Get-ChildItem -Path $PbData -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
    try { if ($_.Attributes -band [System.IO.FileAttributes]::ReadOnly) { $_.Attributes = [System.IO.FileAttributes]::Normal } } catch {}
  }
  Log "Atributos Read-Only limpiados en pb_data."
} else {
  Log "[ADVERTENCIA] No existe $PbData."
}

# --- 4) Verificar que el directorio sea ESCRIBIBLE ---
$dirWritable = $false
if (Test-Path $PbData) {
  $probe = Join-Path $PbData ("__wtest_{0}.tmp" -f (Get-Date -Format 'HHmmssfff'))
  try {
    Set-Content -Path $probe -Value 'x' -ErrorAction Stop
    Remove-Item $probe -Force -ErrorAction SilentlyContinue
    $dirWritable = $true
  } catch {
    Log "[ADVERTENCIA] El directorio pb_data NO parece escribible: $($_.Exception.Message)"
  }
}
if ($dirWritable) { Log "Directorio pb_data escribible: OK." }

# --- 5) Backup preventivo (rotado, ultimos 10) ---
if (Test-Path $dataDb) {
  try {
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    Copy-Item $dataDb (Join-Path $backupDir "data.db.$stamp") -Force -ErrorAction SilentlyContinue
    if (Test-Path $walFile) { Copy-Item $walFile (Join-Path $backupDir "data.db-wal.$stamp") -Force -ErrorAction SilentlyContinue }
    if (Test-Path $shmFile) { Copy-Item $shmFile (Join-Path $backupDir "data.db-shm.$stamp") -Force -ErrorAction SilentlyContinue }
    Get-ChildItem -Path $backupDir -Filter "data.db.*" -File -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending | Select-Object -Skip 10 |
      ForEach-Object { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }
    Log "Backup preventivo hecho ($stamp)."
  } catch {
    Log "No se pudo hacer backup preventivo: $($_.Exception.Message)"
  }
}

# --- 6) SANEO del WAL / SHM ---
$walExists = Test-Path $walFile
$walLen = 0
if ($walExists) { try { $walLen = (Get-Item $walFile).Length } catch { $walLen = 0 } }

if (-not $walExists -or $walLen -eq 0) {
  # Caso limpio: WAL vacio o ausente. Borrar -wal y -shm sin riesgo.
  if ($walExists) {
    try { Remove-Item $walFile -Force -ErrorAction Stop; Log "data.db-wal (0 bytes) eliminado." }
    catch { Log "No se pudo eliminar -wal: $($_.Exception.Message)" }
  }
  if (Test-Path $shmFile) {
    try { Remove-Item $shmFile -Force -ErrorAction Stop; Log "data.db-shm eliminado." }
    catch { Log "No se pudo eliminar -shm: $($_.Exception.Message)" }
  }
  Log "WAL vacio/ausente -> arranque totalmente limpio (sin -wal ni -shm)."
} else {
  # WAL con datos: NO borrar (tiene transacciones). Borrar solo -shm; al
  # abrir, SQLite reconstruye -shm y REPRODUCE el -wal (checkpoint de
  # recuperacion) sin perder nada.
  if (Test-Path $shmFile) {
    try { Remove-Item $shmFile -Force -ErrorAction Stop; Log "data.db-shm eliminado (SQLite lo reconstruye)." }
    catch { Log "No se pudo eliminar -shm: $($_.Exception.Message)" }
  }
  Log ("data.db-wal TRAE datos ({0} bytes): conservado. SQLite lo reproducira al abrir (sin perdida)." -f $walLen)
}

Log "===== Saneo de WAL: fin ====="
exit 0
