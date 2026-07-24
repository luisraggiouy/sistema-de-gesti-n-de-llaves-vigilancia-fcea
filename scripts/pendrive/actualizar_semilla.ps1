# ============================================================
# Sistema FCEA - ACTUALIZAR SEMILLA DEL PENDRIVE
# ============================================================
# Copia la base productiva del Monitor Vigilancia al pendrive,
# de forma segura y consistente. Deja el pendrive "al dia" con
# todas las llaves, usuarios, vigilantes, turnos, objetos e
# historial acumulados hasta el momento.
#
# Reglas:
#   1) SOLO se ejecuta en la PC con rol = "monitor".
#   2) Detiene PocketBase brevemente para copia consistente.
#   3) Copia   C:\ProgramData\FCEA-Sistema-Llaves\pb_data\*
#      hacia  <PENDRIVE>\sistema-llaves-fcea\pocketbase\pb_data\
#   4) Copia los ultimos backups locales al pendrive tambien.
#   5) Escribe _SEMILLA_INFO.txt con timestamp + conteos, en
#      ambos lugares (pendrive y ProgramData local).
#   6) Reanuda PocketBase.
#
# Se puede correr:
#   - A mano vos, cuando quieras dejar el pendrive fresco.
#   - Automaticamente desde DESINSTALAR SISTEMA.bat antes de borrar.
#
# JAMAS borra datos productivos. Solo agrega/actualiza el pendrive.
# ============================================================

#Requires -Version 5.1

param(
  [Parameter(Mandatory=$true)]
  [string]$PendriveRoot,      # Ej: E:\  o  E:
  [switch]$SinDetenerPocketBase # opcional, si se llama con PB ya detenido
)

$ErrorActionPreference = "Continue"

function Log { param([string]$m) Write-Host ("  " + $m) }

Log ""
Log "============================================================"
Log "  ACTUALIZAR SEMILLA DEL PENDRIVE"
Log "============================================================"
Log ""

# --- 1) Validar pendrive ---
if (-not (Test-Path $PendriveRoot)) {
  Log "[ERROR] No existe la ruta del pendrive: $PendriveRoot"
  exit 2
}
$pendriveSistema = Join-Path $PendriveRoot "sistema-llaves-fcea"
if (-not (Test-Path $pendriveSistema)) {
  Log "[ERROR] El pendrive no contiene la carpeta sistema-llaves-fcea."
  Log "        Ruta esperada: $pendriveSistema"
  Log "        Verifique que enchufo el pendrive correcto del sistema."
  exit 3
}

# --- 2) Validar rol = monitor ---
$configPath = "C:\sistema-llaves-fcea\public\config.json"
$rolActual = ""
if (Test-Path $configPath) {
  try {
    $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
    $rolActual = $cfg.rol
  } catch {
    Log "[WARN] No se pudo leer $configPath : $_"
  }
}

if ($rolActual -ne "monitor") {
  Log "[ERROR] Esta PC tiene rol '$rolActual', no 'monitor'."
  Log "        ACTUALIZAR SEMILLA solo se ejecuta en el Monitor Vigilancia,"
  Log "        que es la PC donde vive la base de datos productiva."
  Log ""
  Log "        Vaya al Monitor Vigilancia, enchufe el pendrive alli, y"
  Log "        ejecute ACTUALIZAR_SEMILLA_PENDRIVE.bat desde el pendrive."
  exit 4
}

# --- 3) Elegir la FUENTE de datos mas nueva (fix 2026-07-24) -----------------
# Historicamente los datos podian vivir en cualquiera de estos lugares:
#   a) C:\ProgramData\FCEA-Sistema-Llaves\pb_data       (ruta canonica actual)
#   b) C:\sistema-llaves-fcea\pocketbase\pb_data        (legacy - bug --dir relativo)
#   c) C:\backup_fcea_YYYY-MM-DD_HH-MM\pb_data          (backup de desinstaladores)
#
# Elegimos la que tenga data.db mas reciente por LastWriteTime.
# Esto garantiza que, aunque el usuario tenga una PC afectada por el bug
# --dir=pb_data (relativo), la semilla del pendrive capture los datos reales.
$candidatos = @()
$rutaProgData = "C:\ProgramData\FCEA-Sistema-Llaves\pb_data"
$rutaLegacy   = "C:\sistema-llaves-fcea\pocketbase\pb_data"

if (Test-Path (Join-Path $rutaProgData "data.db")) {
  $candidatos += [PSCustomObject]@{
    Origen = "persistente"
    Ruta   = $rutaProgData
    Fecha  = (Get-Item (Join-Path $rutaProgData "data.db")).LastWriteTime
  }
}
if (Test-Path (Join-Path $rutaLegacy "data.db")) {
  $candidatos += [PSCustomObject]@{
    Origen = "instalacion_legacy"
    Ruta   = $rutaLegacy
    Fecha  = (Get-Item (Join-Path $rutaLegacy "data.db")).LastWriteTime
  }
}
Get-ChildItem "C:\" -Directory -Filter "backup_fcea_*" -ErrorAction SilentlyContinue | ForEach-Object {
  $db = Join-Path $_.FullName "pb_data\data.db"
  if (Test-Path $db) {
    $candidatos += [PSCustomObject]@{
      Origen = "backup_local($($_.Name))"
      Ruta   = (Split-Path $db)
      Fecha  = (Get-Item $db).LastWriteTime
    }
  }
}

if ($candidatos.Count -eq 0) {
  Log "[ERROR] No se encontro data.db en ninguna ubicacion conocida:"
  Log "        - $rutaProgData"
  Log "        - $rutaLegacy"
  Log "        - C:\backup_fcea_*\pb_data"
  Log "        Es posible que PocketBase nunca haya arrancado en esta PC."
  Log "        Arranque el sistema, cargue datos, y luego reintente."
  exit 5
}

Log "  Candidatos de datos encontrados (ordenados del mas nuevo al mas viejo):"
foreach ($c in ($candidatos | Sort-Object Fecha -Descending)) {
  Log ("    - " + $c.Fecha.ToString("yyyy-MM-dd HH:mm:ss") + "  [" + $c.Origen + "]  " + $c.Ruta)
}

$ganador = $candidatos | Sort-Object Fecha -Descending | Select-Object -First 1
$pbDataProd = $ganador.Ruta
$dbProd     = Join-Path $pbDataProd "data.db"
$tamMB = [math]::Round((Get-Item $dbProd).Length / 1MB, 2)
Log ""
Log ("  Fuente elegida: [" + $ganador.Origen + "]")
Log "    Ruta   : $dbProd"
Log "    Fecha  : $($ganador.Fecha.ToString('yyyy-MM-dd HH:mm:ss'))"
Log "    Tamano : $tamMB MB"
Log ""

# --- 4) Detener PocketBase 5 segundos ---
$pbStopped = $false
if (-not $SinDetenerPocketBase) {
  Log "  Deteniendo PocketBase temporalmente para copia consistente..."
  try {
    Get-Process pocketbase -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    $pbStopped = $true
    Log "    [OK] PocketBase detenido."
  } catch {
    Log ("    [WARN] No se pudo detener PocketBase: " + $_.Exception.Message)
    Log "           Continuo, la copia puede tener el WAL pendiente."
  }
}

# --- 5) Copiar pb_data al pendrive con robocopy ---
$pendrivePbData = Join-Path $pendriveSistema "pocketbase\pb_data"
Log "  Copiando pb_data al pendrive..."
Log "    Destino: $pendrivePbData"

$rc = 0
try {
  # /MIR replica exacto, /R:1 /W:1 evita esperas eternas si un archivo esta
  # bloqueado, /NFL /NDL silencia el output, /NP oculta porcentaje.
  & robocopy $pbDataProd $pendrivePbData /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
  $rc = $LASTEXITCODE
} catch {
  $rc = 16
  Log ("    [ERROR] robocopy fallo: " + $_.Exception.Message)
}

# robocopy exit codes: 0-7 son OK (0..3 sin cambios/copiado, 4-7 warnings)
if ($rc -ge 8) {
  Log "    [ERROR] robocopy termino con codigo $rc (hubo errores)."
} else {
  Log "    [OK] pb_data copiado (codigo robocopy=$rc)"
}

# --- 6) Copiar backups locales al pendrive (historial rodante) ---
$backupsLocales = "C:\sistema-llaves-fcea\backups"
$pendrivePbBackups = Join-Path $pendriveSistema "pocketbase\pb_backups"
if (Test-Path $backupsLocales) {
  Log "  Copiando backups locales al pendrive..."
  try {
    if (-not (Test-Path $pendrivePbBackups)) {
      New-Item -ItemType Directory -Path $pendrivePbBackups -Force | Out-Null
    }
    # Solo los ultimos 5 zips mas recientes
    Get-ChildItem $backupsLocales -Filter "*.zip" -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 5 |
      ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $pendrivePbBackups -Force -ErrorAction SilentlyContinue
        Log ("    -> " + $_.Name)
      }
  } catch {
    Log ("    [WARN] Al copiar backups: " + $_.Exception.Message)
  }
}

# --- 7) Contar registros para _SEMILLA_INFO.txt ---
# Uso el binario de PocketBase para volcar conteos rapidos usando su propia
# BD (mas robusto que instalar sqlite3). Si no arranca, dejo conteos vacios.
$conteos = @{
  llaves          = "?"
  usuarios        = "?"
  vigilantes      = "?"
  turnos          = "?"
  objetos_hallados = "?"
  autorizaciones  = "?"
}

# Intento contar directo desde el data.db con sqlite si esta instalado
$sqlite = Get-Command sqlite3.exe -ErrorAction SilentlyContinue
if ($sqlite) {
  $consultas = @{
    llaves           = "SELECT COUNT(*) FROM llaves;"
    usuarios         = "SELECT COUNT(*) FROM usuarios_registrados;"
    vigilantes       = "SELECT COUNT(*) FROM vigilantes;"
    turnos           = "SELECT COUNT(*) FROM turnos;"
    objetos_hallados = "SELECT COUNT(*) FROM objetos_hallados;"
    autorizaciones   = "SELECT COUNT(*) FROM autorizaciones;"
  }
  foreach ($k in $consultas.Keys) {
    try {
      $out = & $sqlite.Source $dbProd $consultas[$k] 2>$null
      if ($out -match '^\d+$') { $conteos[$k] = [int]$out }
    } catch { }
  }
}

# --- 8) Escribir _SEMILLA_INFO.txt en pendrive y en ProgramData ---
$now = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$hostname = $env:COMPUTERNAME

$info = @"
last_seed_written_at: $now
origen: $hostname
tamano_data_db_mb: $tamMB
conteos:
  llaves:           $($conteos.llaves)
  usuarios:         $($conteos.usuarios)
  vigilantes:       $($conteos.vigilantes)
  turnos:           $($conteos.turnos)
  objetos_hallados: $($conteos.objetos_hallados)
  autorizaciones:   $($conteos.autorizaciones)
generado_por: actualizar_semilla.ps1
"@

$infoPendrive = Join-Path $pendrivePbData "_SEMILLA_INFO.txt"
$infoProgData = Join-Path $pbDataProd "_SEMILLA_INFO.txt"
try {
  Set-Content -Path $infoPendrive -Value $info -Encoding UTF8 -Force
  Set-Content -Path $infoProgData -Value $info -Encoding UTF8 -Force
  Log ""
  Log "  [OK] _SEMILLA_INFO.txt actualizado:"
  Log "    -> $infoPendrive"
  Log "    -> $infoProgData"
} catch {
  Log ("  [WARN] No se pudo escribir _SEMILLA_INFO.txt: " + $_.Exception.Message)
}

# --- 9) Reanudar PocketBase si lo detuvimos ---
if ($pbStopped) {
  Log ""
  Log "  Reanudando PocketBase..."
  $pbExe = "C:\sistema-llaves-fcea\pocketbase\pocketbase.exe"
  if (Test-Path $pbExe) {
    try {
      $pbDir = Split-Path $pbExe
      Start-Process -FilePath $pbExe `
        -ArgumentList @("serve","--http=0.0.0.0:8090","--dir=`"$pbDataProd`"") `
        -WorkingDirectory $pbDir `
        -WindowStyle Hidden | Out-Null
      Log "    [OK] PocketBase reiniciado."
    } catch {
      Log ("    [WARN] No se pudo reanudar PocketBase: " + $_.Exception.Message)
      Log "           Reinicie el sistema o ejecute INICIAR.bat manualmente."
    }
  } else {
    Log "    [WARN] $pbExe no existe, no se reanuda automaticamente."
  }
}

Log ""
Log "============================================================"
Log "  [LISTO] SEMILLA DEL PENDRIVE ACTUALIZADA"
Log "============================================================"
Log ""
Log "  El pendrive ahora contiene la foto mas reciente de la base"
Log "  de datos productiva del Monitor Vigilancia."
Log ""
Log "  Fecha : $now"
Log "  Origen: $hostname"
Log "  Tamano: $tamMB MB"
Log "  Llaves: $($conteos.llaves)   Usuarios: $($conteos.usuarios)"
Log ""
exit 0
