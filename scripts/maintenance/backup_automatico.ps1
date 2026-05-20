# ============================================================
# Sistema de Gestion de Llaves FCEA v2.0
# Backup automatico de pb_data
# ============================================================
# Copia pocketbase\pb_data\ a una carpeta backups\YYYY-MM-DD\
# y mantiene solo los ultimos N respaldos.
# Diseñado para correr en la PC servidor (rol = monitor).
# ============================================================

#Requires -Version 5.1

param(
  [int]$RetencionDias = 14
)

$ErrorActionPreference = "Continue"

$repoRoot   = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$configPath = Join-Path $repoRoot "public\config.json"
$src        = Join-Path $repoRoot "pocketbase\pb_data"
$backupsDir = Join-Path $repoRoot "backups"
$logFile    = Join-Path $repoRoot "pocketbase\maintenance\logs\backup.log"

New-Item -ItemType Directory -Force -Path (Split-Path $logFile) | Out-Null
New-Item -ItemType Directory -Force -Path $backupsDir | Out-Null

function Log {
  param([string]$Msg)
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  "[$ts] $Msg" | Tee-Object -FilePath $logFile -Append
}

# Verificar rol: backup solo en el servidor.
if (Test-Path $configPath) {
  try {
    $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
    if ($cfg.rol -ne "monitor") {
      Log "Rol = $($cfg.rol). Backup solo corre en 'monitor'. Saliendo."
      exit 0
    }
  } catch {
    Log "No se pudo leer config.json: $_"
  }
}

if (-not (Test-Path $src)) {
  Log "[ERROR] No existe $src. Nada que respaldar."
  exit 1
}

$stamp  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$target = Join-Path $backupsDir $stamp

Log "Iniciando backup -> $target"
New-Item -ItemType Directory -Force -Path $target | Out-Null

# Usamos robocopy para que ignore archivos abiertos por PocketBase y
# haga una copia consistente (sqlite WAL).
& robocopy $src $target /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
$rc = $LASTEXITCODE
if ($rc -ge 8) {
  Log "[WARN] robocopy termino con codigo $rc (algunos errores)"
} else {
  Log "[OK] Backup completado (robocopy=$rc)"
}

# Comprimir a ZIP para ahorrar espacio.
$zipFile = "$target.zip"
try {
  Compress-Archive -Path "$target\*" -DestinationPath $zipFile -Force
  Remove-Item -Recurse -Force $target
  Log "Comprimido en $zipFile"
} catch {
  Log "[WARN] No se pudo comprimir: $_"
}

# Limpieza de retencion: borrar backups mas viejos que N dias.
$limite = (Get-Date).AddDays(-$RetencionDias)
Get-ChildItem -Path $backupsDir -File -Filter "*.zip" |
  Where-Object { $_.LastWriteTime -lt $limite } |
  ForEach-Object {
    Log "Eliminando backup antiguo: $($_.Name)"
    Remove-Item -Force $_.FullName
  }

Log "Fin backup automatico."
