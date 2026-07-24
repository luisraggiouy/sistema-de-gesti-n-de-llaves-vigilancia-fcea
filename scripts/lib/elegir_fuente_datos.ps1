# ============================================================
# Sistema FCEA - Elegir fuente de datos MAS NUEVA (v2)
# ============================================================
# Cambio clave respecto a v1: para las carpetas backup_fcea_*
# usamos la fecha de la CARPETA (LastWriteTime del directorio) y
# NO la del data.db interno, porque robocopy /MIR conserva
# timestamps y todos los data.db pueden terminar con la misma
# fecha (aparentando ser "viejos" de 53+ dias). La carpeta
# backup_fcea_YYYY-MM-DD_HH-MM en cambio la crea el desinstalador
# en el momento y tiene mtime real.
#
# Uso: llamado por INSTALAR.bat al restaurar datos.
#
# Fuentes:
#   1) persistente  : C:\ProgramData\FCEA-Sistema-Llaves\pb_data
#                     (fecha del data.db)
#   2) backup_local : C:\backup_fcea_YYYY-MM-DD_HH-MM\pb_data
#                     (fecha de la CARPETA)
#   3) legacy       : C:\sistema-llaves-fcea\pocketbase\pb_data
#                     (fecha del data.db)
#   4) pendrive     : <pendrive>\sistema-llaves-fcea\pocketbase\pb_data
#                     (fecha del data.db)
#
# Regla adicional: si existen backups locales, la persistente NO
# se prefiere sobre ellos aunque tenga fecha ligeramente mas nueva.
# Motivo: PocketBase puede haber escrito data.db en la persistente
# despues de arrancar vacio, ganandole por unos segundos a un
# backup con datos reales. Solo se prefiere la persistente si:
#   - No hay backups locales, o
#   - La persistente es AL MENOS 24h mas nueva que el mejor backup,
#     lo que indica que ya se uso productivamente.
#
# Escribe en el archivo indicado por -Salida:
#   ORIGEN|RUTA_A_pb_data
# ============================================================

param(
  [Parameter(Mandatory=$true)][string]$RutaPendrivePbData,
  [Parameter(Mandatory=$true)][string]$Salida
)

$ErrorActionPreference = "Continue"

$candidatos = @()

# 1) Persistente
$p1 = "C:\ProgramData\FCEA-Sistema-Llaves\pb_data\data.db"
if (Test-Path $p1) {
  $candidatos += [PSCustomObject]@{
    Origen = "persistente"
    Ruta   = (Split-Path $p1)
    Fecha  = (Get-Item $p1).LastWriteTime
    Bytes  = (Get-Item $p1).Length
  }
}

# 2) Backups locales - usar fecha de la CARPETA (mtime real del desinstalador)
Get-ChildItem "C:\" -Directory -Filter "backup_fcea_*" -ErrorAction SilentlyContinue | ForEach-Object {
  $db = Join-Path $_.FullName "pb_data\data.db"
  if (Test-Path $db) {
    $candidatos += [PSCustomObject]@{
      Origen = "backup_local"
      Ruta   = (Split-Path $db)
      Fecha  = $_.LastWriteTime   # <-- fecha de la carpeta, no del data.db
      Bytes  = (Get-Item $db).Length
    }
  }
}

# 3) Legacy (bug historico)
$p3 = "C:\sistema-llaves-fcea\pocketbase\pb_data\data.db"
if (Test-Path $p3) {
  $candidatos += [PSCustomObject]@{
    Origen = "instalacion_legacy"
    Ruta   = (Split-Path $p3)
    Fecha  = (Get-Item $p3).LastWriteTime
    Bytes  = (Get-Item $p3).Length
  }
}

# 4) Pendrive
$p4 = Join-Path $RutaPendrivePbData "data.db"
if (Test-Path $p4) {
  $candidatos += [PSCustomObject]@{
    Origen = "pendrive"
    Ruta   = (Split-Path $p4)
    Fecha  = (Get-Item $p4).LastWriteTime
    Bytes  = (Get-Item $p4).Length
  }
}

if ($candidatos.Count -eq 0) {
  Set-Content -Path $Salida -Value "ninguno|" -Encoding ASCII
  Write-Host "  No se encontraron datos en ninguna ubicacion."
  exit 0
}

# Mostrar todos ordenados por fecha desc
$ordenados = $candidatos | Sort-Object Fecha -Descending
Write-Host "  Candidatos encontrados:"
foreach ($c in $ordenados) {
  $mb = [math]::Round($c.Bytes / 1MB, 2)
  Write-Host ("    - " + $c.Fecha.ToString("yyyy-MM-dd HH:mm:ss") + "  " + $mb.ToString("0.00") + " MB  [" + $c.Origen + "]  " + $c.Ruta)
}

# ------------------------------------------------------------
# Regla anti-persistente-recien-creada:
# Si el candidato mas nuevo es 'persistente' PERO existe un
# 'backup_local' con fecha reciente, y la persistente NO tiene
# 24h+ de ventaja, preferir el backup local.
# ------------------------------------------------------------
$win = $ordenados | Select-Object -First 1

$mejorBackup = $ordenados | Where-Object { $_.Origen -eq "backup_local" } | Select-Object -First 1
if ($win.Origen -eq "persistente" -and $mejorBackup -ne $null) {
  $ventaja = ($win.Fecha - $mejorBackup.Fecha).TotalHours
  if ($ventaja -lt 24) {
    Write-Host ""
    Write-Host ("  [PROTECCION] persistente solo tiene " + [math]::Round($ventaja,2) + "h de ventaja sobre el backup local mas nuevo.") -ForegroundColor Yellow
    Write-Host "               Es probable que sea una base vacia recien creada por PocketBase." -ForegroundColor Yellow
    Write-Host "               Prefiriendo el backup local para no perder datos." -ForegroundColor Yellow
    $win = $mejorBackup
  }
}

$line = $win.Origen + "|" + $win.Ruta
Set-Content -Path $Salida -Value $line -Encoding ASCII

Write-Host ""
Write-Host ("  Ganador: " + $win.Origen + " (" + $win.Fecha.ToString("yyyy-MM-dd HH:mm:ss") + ")") -ForegroundColor Green
exit 0
