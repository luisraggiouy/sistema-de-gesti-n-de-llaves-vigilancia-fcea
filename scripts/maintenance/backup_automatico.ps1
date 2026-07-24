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
$backupsDir = Join-Path $repoRoot "backups"
$logFile    = Join-Path $repoRoot "pocketbase\maintenance\logs\backup.log"

# Detectar automaticamente la ruta real de pb_data.
# Puede estar en:
#   a) $repoRoot\pocketbase\pb_data          (instalacion "portable")
#   b) C:\ProgramData\FCEA-Sistema-Llaves\pb_data  (instalacion "productiva")
# La ruta activa se determina buscando data.db en cada candidato.
$src = $null
$candidatosPbData = @(
  (Join-Path $repoRoot "pocketbase\pb_data"),
  "C:\ProgramData\FCEA-Sistema-Llaves\pb_data"
)
foreach ($c in $candidatosPbData) {
  if (Test-Path (Join-Path $c "data.db")) {
    $src = $c
    break
  }
}
if (-not $src) {
  # Fallback al comportamiento original: probablemente falle, pero no
  # rompemos scripts anteriores que asumian esta ruta.
  $src = Join-Path $repoRoot "pocketbase\pb_data"
}

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

# Limpieza de retencion: borrar SOLO los archivos ZIP de backup mas viejos
# que N dias dentro de la carpeta backups\.
#
# IMPORTANTE: esto NO afecta a la base de datos productiva ni a ningun dato
# del sistema. Solo se eliminan copias comprimidas (ZIP) ya obsoletas que
# fueron generadas por backups anteriores. Los datos en pb_data\ permanecen
# intactos. Para retencion historica de largo plazo, ver § 5.1 de la guia
# (archivado anual a pendrive permanente).
$limite = (Get-Date).AddDays(-$RetencionDias)
Get-ChildItem -Path $backupsDir -File -Filter "*.zip" |
  Where-Object { $_.LastWriteTime -lt $limite } |
  ForEach-Object {
    Log "Eliminando archivo ZIP de backup obsoleto: $($_.Name)"
    Remove-Item -Force $_.FullName
  }

Log "Fin backup automatico."
