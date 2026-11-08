# ============================================================
# Sistema de Gestion de Llaves FCEA v2.0
# Backup automatico de pb_data  -- VERSION CORREGIDA 2026-11-06
# ============================================================
# Copia pocketbase\pb_data\ a backups\YYYY-MM-DD_HH-mm-ss\, la
# comprime a .zip y mantiene solo los ultimos N respaldos.
#
# FIX 2026-11-06 (causa raiz del "No hay backups"):
#   1) Compress-Archive fallaba ("Secuencia demasiado larga") con el
#      WAL grande -> no se generaba el .zip. Reemplazado por
#      [IO.Compression.ZipFile]::CreateFromDirectory (API .NET nativa,
#      genera .zip real y NO sufre ese bug).
#   2) El Remove-Item de la carpeta cruda estaba DENTRO del try de la
#      compresion y DESPUES del compress: si el compress fallaba, la
#      cruda quedaba. Ahora la cruda se borra SOLO si el .zip existe y
#      tiene tamanio > 0 (verificacion explicita).
#   3) La retencion solo borraba *.zip; las carpetas crudas huerfanas
#      nunca se limpiaban y inflaban el disco. Ahora la retencion borra
#      *.zip viejos Y carpetas crudas huerfanas viejas.
# Disenado para correr en la PC servidor (rol = monitor).
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

# BACKUP LIVIANO (2026-11-07): copia SOLO la base real (data.db + su WAL/SHM),
# que contiene TODOS los datos del negocio (llaves, pedidos, objetos y las FOTOS
# embebidas). data.db pesa ~17 MB -> .zip de ~6 MB.
#
# Se EXCLUYE a proposito todo lo que NO son datos del negocio y solo infla el disco:
#   - logs.db / logs.db-wal / logs.db-shm  = auditoria interna de PocketBase (GBs)
#   - _backup_logsdb* / _backups_arranque* = backups internos viejos
#   - data.db.bak_*                        = copias .bak sueltas antiguas
# NO se excluye data.db-wal/-shm: segun el postmortem del WAL (26/07/2026),
# el -wal puede traer transacciones no consolidadas; se copia para no perder nada.
$copiar = @('data.db','data.db-wal','data.db-shm')
& robocopy $src $target $copiar /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
$rc = $LASTEXITCODE
if ($rc -ge 8) {
  Log "[WARN] robocopy termino con codigo $rc (algunos errores)"
} else {
  Log "[OK] Backup (solo data.db + WAL) completado (robocopy=$rc)"

# ------------------------------------------------------------
# Comprimir a ZIP (metodo robusto, reemplaza Compress-Archive).
# ------------------------------------------------------------
$zipFile = "$target.zip"
$zipOk = $false
try {
  if (Test-Path $zipFile) { Remove-Item -Force $zipFile -ErrorAction SilentlyContinue }
  Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
  [System.IO.Compression.ZipFile]::CreateFromDirectory(
    $target, $zipFile,
    [System.IO.Compression.CompressionLevel]::Optimal,
    $false)
  $zipOk = $true
  Log "Comprimido en $zipFile (metodo ZipFile)"
} catch {
  Log "[WARN] ZipFile fallo: $_. Intentando fallback con tar.exe..."
  try {
    & tar.exe -a -c -f $zipFile -C $target "." 2>$null
    if ($LASTEXITCODE -eq 0) { $zipOk = $true; Log "Comprimido en $zipFile (metodo tar.exe)" }
    else { Log "[WARN] tar.exe termino con codigo $LASTEXITCODE" }
  } catch {
    Log "[WARN] tar.exe tambien fallo: $_"
  }
}

# ------------------------------------------------------------
# Borrar la carpeta cruda SOLO si el .zip existe y tiene contenido.
# ------------------------------------------------------------
if ($zipOk -and (Test-Path $zipFile) -and ((Get-Item $zipFile).Length -gt 0)) {
  Remove-Item -Recurse -Force $target -ErrorAction SilentlyContinue
  $mb = [math]::Round((Get-Item $zipFile).Length/1MB,2)
  Log "[OK] Carpeta cruda eliminada; backup final: $zipFile ($mb MB)"
} else {
  Log "[ERROR] La compresion NO dejo un .zip valido. Se CONSERVA la carpeta cruda $target para no perder el backup. Revisar espacio en disco / WAL."
}

# ------------------------------------------------------------
# Retencion: borrar .zip viejos Y carpetas crudas huerfanas viejas.
# NO afecta la base productiva (pb_data\ queda intacto).
# ------------------------------------------------------------
$limite = (Get-Date).AddDays(-$RetencionDias)

# 1) ZIP obsoletos
Get-ChildItem -Path $backupsDir -File -Filter "*.zip" -ErrorAction SilentlyContinue |
  Where-Object { $_.LastWriteTime -lt $limite } |
  ForEach-Object {
    Log "Eliminando ZIP de backup obsoleto: $($_.Name)"
    Remove-Item -Force $_.FullName -ErrorAction SilentlyContinue
  }

# 2) Carpetas crudas huerfanas mas viejas que el limite de retencion.
Get-ChildItem -Path $backupsDir -Directory -ErrorAction SilentlyContinue |
  Where-Object { $_.LastWriteTime -lt $limite } |
  ForEach-Object {
    Log "Eliminando carpeta cruda huerfana obsoleta: $($_.Name)"
    Remove-Item -Recurse -Force $_.FullName -ErrorAction SilentlyContinue
  }

Log "Fin backup automatico."

}
