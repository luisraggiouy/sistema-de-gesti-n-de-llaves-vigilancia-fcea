# ============================================================
# DIAGNOSTICO DEL BACKUP DIARIO  (SOLO LECTURA)
# Sistema de Gestion de Llaves FCEA
#
# OBJETIVO
#   Averiguar POR QUE el Monitor de Salud muestra "Backup atrasado"
#   aunque la tarea FCEA-Backup-Diario deberia correr todos los dias
#   a las 03:00. Reune todas las pistas en UN solo log para analizar.
#
# SEGURIDAD (MUY IMPORTANTE - ESTO CORRE EN PRODUCCION)
#   - Es 100% SOLO LECTURA. NO modifica tareas, NO borra ZIPs, NO
#     fuerza backups, NO reinicia PocketBase, NO toca la base de datos.
#   - Todo esta envuelto en try/catch y $ErrorActionPreference='Continue',
#     por lo que NUNCA aborta ni puede tumbar el sistema.
#
# COMO USARLO (en la cabina / Monitor de Vigilancia)
#   1. Enchufar el pendrive de RESCATE.
#   2. Click derecho en este .ps1 -> "Ejecutar con PowerShell".
#      NO requiere administrador, pero si lo corres como admin ve mas
#      detalles de las tareas programadas.
#   3. Al terminar deja LOG_BACKUP_DIARIO_<PC>_<fecha>.log en la
#      subcarpeta _RESULTADOS\ (al lado, en el pendrive). Traer ese archivo.
# ============================================================

$ErrorActionPreference = 'Continue'
try { $Host.UI.RawUI.WindowTitle = 'DIAGNOSTICO BACKUP DIARIO (solo lectura) - FCEA' } catch {}

# --- Rutas de salida -------------------------------------------------------
# Regla de Logs al Pendrive (03/08/2026): el .log va a la subcarpeta
# _RESULTADOS\ del pendrive, con nombre que incluye tema + PC + fecha/hora.
# Si _RESULTADOS no existe (se corrio fuera del pendrive), cae al lado del script.
# Resolver la carpeta del script de forma robusta tambien bajo RunAs
# (al elevar, el CWD es System32, pero $PSScriptRoot/$MyInvocation
#  siguen apuntando a la ruta real del .ps1 en el pendrive).
$SCRIPTDIR = $PSScriptRoot
if (-not $SCRIPTDIR) { $SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $SCRIPTDIR) { $SCRIPTDIR = (Get-Location).Path }
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$RESULTADOS = Join-Path $SCRIPTDIR '_RESULTADOS'
if (-not (Test-Path $RESULTADOS)) {
  try { New-Item -ItemType Directory -Path $RESULTADOS -Force -ErrorAction Stop | Out-Null }
  catch { $RESULTADOS = $SCRIPTDIR }
}
$LOG = Join-Path $RESULTADOS ("LOG_BACKUP_DIARIO_" + $env:COMPUTERNAME + "_" + $STAMP + ".log")

# --- Helpers de log (mismo estilo que DIAGNOSTICO_DISCO_Y_BACKUP.ps1) ------
function L   { param([string]$t) $t | Tee-Object -FilePath $LOG -Append }
function Sec { param([string]$t) ("`n" + ('=' * 64) + "`n  " + $t + "`n" + ('=' * 64)) | Tee-Object -FilePath $LOG -Append }
function GB  { param($b) if ($null -eq $b) { '0' } else { [math]::Round($b/1GB,2).ToString() + ' GB' } }
function MB  { param($b) if ($null -eq $b) { '0' } else { [math]::Round($b/1MB,2).ToString() + ' MB' } }

"DIAGNOSTICO BACKUP DIARIO - FCEA" | Set-Content -Path $LOG -Encoding UTF8
L ("Generado : " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
L ("PC       : " + $env:COMPUTERNAME + "   Usuario: " + $env:USERNAME)
try {
  $esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  L ("Admin    : " + $esAdmin)
} catch { L "Admin    : (no se pudo determinar)" }

# ============================================================
# 0) DETECTAR LA INSTALACION REAL DEL SISTEMA
#    Replica la logica de backup_automatico.ps1 / check_system_health.ps1.
# ============================================================
Sec "0) LOCALIZAR INSTALACION"

$InstallCandidates = @(
  'C:\sistema-llaves-fcea',
  (Join-Path $env:USERPROFILE 'sistema-llaves-fcea'),
  'C:\ProgramData\FCEA-Sistema-Llaves'
)
$INSTALL = $null
foreach ($c in $InstallCandidates) {
  if (Test-Path $c) {
    if ((Test-Path (Join-Path $c 'scripts\maintenance')) -or (Test-Path (Join-Path $c 'pocketbase'))) {
      $INSTALL = $c; break
    }
  }
}
if (-not $INSTALL) {
  L "[AVISO] No encontre la instalacion en las rutas tipicas:"
  foreach ($c in $InstallCandidates) { L ("   - " + $c + "  (existe: " + (Test-Path $c) + ")") }
  $INSTALL = 'C:\sistema-llaves-fcea'
  L ("Usare por defecto: " + $INSTALL + " (aunque no exista, para dejar constancia)")
} else {
  L ("Instalacion detectada: " + $INSTALL)
}

# Ruta real de pb_data (portable vs productiva)
$PbDataCandidates = @(
  (Join-Path $INSTALL 'pocketbase\pb_data'),
  'C:\ProgramData\FCEA-Sistema-Llaves\pb_data'
)
$PBDATA = $null
foreach ($c in $PbDataCandidates) {
  if (Test-Path (Join-Path $c 'data.db')) { $PBDATA = $c; break }
}
if ($PBDATA) { L ("pb_data (data.db) : " + $PBDATA) }
else         { L "[AVISO] No encontre data.db en las rutas candidatas de pb_data." }

$BACKUPS_NEW = Join-Path $INSTALL 'backups'
$BACKUPS_OLD = Join-Path $INSTALL 'pocketbase\pb_backups'
$BACKUP_LOG  = Join-Path $INSTALL 'pocketbase\maintenance\logs\backup.log'
$MAINT_LOG   = Join-Path $INSTALL 'pocketbase\maintenance\logs\maintenance.log'
$HEALTH_JSON_PUB  = Join-Path $INSTALL 'public\system_health.json'
$HEALTH_JSON_DIST = Join-Path $INSTALL 'dist\system_health.json'
$CONFIG_JSON = Join-Path $INSTALL 'public\config.json'

# ============================================================
# 1) ESPACIO EN DISCO  (sospechoso: disco al ~80%)
# ============================================================
Sec "1) ESPACIO EN DISCO C:"
try {
  $d = Get-PSDrive -Name C -ErrorAction Stop
  $tot = $d.Used + $d.Free
  L ("Total : " + (GB $tot))
  L ("Usado : " + (GB $d.Used))
  L ("Libre : " + (GB $d.Free) + "  (" + [math]::Round(($d.Free/$tot)*100,1) + "% libre)")
} catch { L ("[ERROR] No pude leer el disco C: $_") }


# ============================================================
# 2) ESTADO DE LA TAREA PROGRAMADA FCEA-Backup-Diario
#    Clave: State, LastRunTime, LastTaskResult.
#    LastTaskResult = 0 -> la TAREA termino sin error (ojo: el script
#      puede haber fallado la compresion y aun asi salir en 0).
#    Distinto de 0 / State=Disabled -> problema en la tarea misma.
# ============================================================
Sec "2) TAREA PROGRAMADA: FCEA-Backup-Diario"
try {
  $t = Get-ScheduledTask -TaskName 'FCEA-Backup-Diario' -ErrorAction Stop
  L ("TaskName : " + $t.TaskName)
  L ("State    : " + $t.State)
  try {
    $info = Get-ScheduledTaskInfo -TaskName 'FCEA-Backup-Diario' -ErrorAction Stop
    L ("LastRunTime        : " + $info.LastRunTime)
    L ("LastTaskResult     : " + $info.LastTaskResult + "   (0 = la TAREA termino sin error)")
    L ("NextRunTime        : " + $info.NextRunTime)
    L ("NumberOfMissedRuns : " + $info.NumberOfMissedRuns)
  } catch { L ("[AVISO] No pude leer Get-ScheduledTaskInfo: $_") }
  try {
    foreach ($a in $t.Actions) {
      L ("Action.Execute   : " + $a.Execute)
      L ("Action.Arguments : " + $a.Arguments)
      L ("Action.WorkDir   : " + $a.WorkingDirectory)
    }
    foreach ($tr in $t.Triggers) {
      L ("Trigger          : StartBoundary=" + $tr.StartBoundary + "  Enabled=" + $tr.Enabled)
    }
    $st = $t.Settings
    L ("StartWhenAvailable (recupera ejec. perdidas): " + $st.StartWhenAvailable)
    L ("ExecutionTimeLimit : " + $st.ExecutionTimeLimit)
  } catch { L ("[AVISO] No pude leer acciones/triggers: $_") }
}
catch {
  L "[IMPORTANTE] La tarea 'FCEA-Backup-Diario' NO existe (o no se pudo leer)."
  L "   -> Esto por si solo explicaria el 'Backup atrasado'."
  L ("   Detalle: $_")
}

Sec "2b) TODAS LAS TAREAS 'FCEA*'"
try {
  $all = Get-ScheduledTask -TaskName 'FCEA*' -ErrorAction SilentlyContinue
  if ($all) {
    foreach ($x in $all) {
      $extra = ''
      try { $xi = Get-ScheduledTaskInfo -TaskName $x.TaskName -ErrorAction Stop
            $extra = "  LastRun=" + $xi.LastRunTime + "  Result=" + $xi.LastTaskResult } catch {}
      L ("   " + $x.State.ToString().PadRight(10) + " " + $x.TaskName + $extra)
    }
  } else { L "   (no se encontraron tareas FCEA*)" }
} catch { L ("[AVISO] $_") }

# ============================================================
# 3) ZIPs DE BACKUP  (lo que realmente mira el Monitor de Salud)
# ============================================================
Sec "3) ARCHIVOS DE BACKUP (.zip)"
foreach ($dir in @($BACKUPS_NEW, $BACKUPS_OLD)) {
  L ("`n--- Carpeta: " + $dir + " ---")
  if (-not (Test-Path $dir)) { L "   (no existe)"; continue }
  try {
    $zips = Get-ChildItem -LiteralPath $dir -Filter '*.zip' -ErrorAction SilentlyContinue
    if ($zips) {
      L ("   Cantidad de .zip: " + $zips.Count)
      $zips | Sort-Object LastWriteTime -Descending |
        ForEach-Object { L (("   {0,10}" -f (MB $_.Length)) + "  " + $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm') + "  " + $_.Name) }
      $last = $zips | Sort-Object LastWriteTime -Descending | Select-Object -First 1
      $dias = [math]::Round((New-TimeSpan -Start $last.LastWriteTime -End (Get-Date)).TotalDays,1)
      L ("   >>> ULTIMO ZIP: hace " + $dias + " dias (" + $last.LastWriteTime + ")")
    } else {
      L "   (no hay archivos .zip)"
    }
    $sinZip = Get-ChildItem -LiteralPath $dir -Directory -ErrorAction SilentlyContinue
    if ($sinZip) {
      L "   [PISTA] Hay CARPETAS sin comprimir dentro (posible compresion fallida):"
      $sinZip | ForEach-Object { L ("      " + $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm') + "  " + $_.Name) }
    }
  } catch { L ("   [AVISO] $_") }
}

# ============================================================
# 4) LOG DEL BACKUP  (EL DATO MAS IMPORTANTE)
#    backup_automatico.ps1 escribe aqui. Si la compresion falla deja
#    una linea "[WARN] No se pudo comprimir".
# ============================================================
Sec "4) LOG DE BACKUP (ultimas 60 lineas)  <-- CLAVE"
L ("Archivo: " + $BACKUP_LOG)
if (Test-Path $BACKUP_LOG) {
  try {
    Get-Content -LiteralPath $BACKUP_LOG -Tail 60 -ErrorAction Stop | ForEach-Object { L ("   " + $_) }
  } catch { L ("[AVISO] No pude leer el log: $_") }
  Sec "4b) LINEAS CON WARN/ERROR EN TODO backup.log"
  try {
    $hits = Select-String -LiteralPath $BACKUP_LOG -Pattern '\[WARN\]|\[ERROR\]' -ErrorAction SilentlyContinue
    if ($hits) { $hits | Select-Object -Last 40 | ForEach-Object { L ("   " + $_.Line) } }
    else       { L "   (sin WARN/ERROR registrados)" }
  } catch { L ("[AVISO] $_") }
} else {
  L "[IMPORTANTE] No existe backup.log."
  L "   -> Si la tarea existe pero NUNCA creo este log, quiza nunca"
  L "      llego a ejecutar backup_automatico.ps1."
}

# ============================================================
# 5) ESTADO DE POCKETBASE Y DATA.DB
# ============================================================
Sec "5) POCKETBASE / BASE DE DATOS"
try {
  $pb = Get-Process pocketbase -ErrorAction SilentlyContinue
  if ($pb) { L ("PocketBase corriendo: SI  (PID " + ($pb.Id -join ', ') + ")") }
  else     { L "PocketBase corriendo: NO (no se ve el proceso)" }
} catch { L ("[AVISO] $_") }
if ($PBDATA) {
  $dbFile = Join-Path $PBDATA 'data.db'
  if (Test-Path $dbFile) {
    try {
      $f = Get-Item -LiteralPath $dbFile
      L ("data.db : " + (MB $f.Length) + "   modificado: " + $f.LastWriteTime)
    } catch { L ("[AVISO] $_") }
  }
}

# ============================================================
# 6) SYSTEM_HEALTH.JSON  (lo que el Monitor esta mostrando)
# ============================================================
Sec "6) SYSTEM_HEALTH.JSON (lo que ve el Monitor)"
foreach ($j in @($HEALTH_JSON_DIST, $HEALTH_JSON_PUB)) {
  L ("`n--- " + $j + " ---")
  if (Test-Path $j) {
    try {
      $f = Get-Item -LiteralPath $j
      L ("   modificado: " + $f.LastWriteTime)
      Get-Content -LiteralPath $j -Raw -ErrorAction Stop | ForEach-Object { L $_ }
    } catch { L ("   [AVISO] $_") }
  } else { L "   (no existe)" }
}

# ============================================================
# 7) CONFIG.JSON  (rol de la PC: el backup solo corre si rol=monitor)
# ============================================================
Sec "7) CONFIG.JSON (rol de esta PC)"
if (Test-Path $CONFIG_JSON) {
  try {
    $cfg = Get-Content -LiteralPath $CONFIG_JSON -Raw | ConvertFrom-Json
    L ("rol : " + $cfg.rol + "   (el backup diario SOLO corre si rol = 'monitor')")
  } catch { L ("[AVISO] No pude parsear config.json: $_") }
} else { L "   (no existe public\config.json)" }

# ============================================================
# 8) OTROS LOGS DE MANTENIMIENTO (ERRORES recientes)
# ============================================================
Sec "8) maintenance.log (ERRORES recientes)"
if (Test-Path $MAINT_LOG) {
  try {
    $hits = Select-String -LiteralPath $MAINT_LOG -Pattern '\[ERROR\]' -ErrorAction SilentlyContinue
    if ($hits) { $hits | Select-Object -Last 20 | ForEach-Object { L ("   " + $_.Line) } }
    else       { L "   (sin [ERROR] en maintenance.log)" }
  } catch { L ("[AVISO] $_") }
} else { L "   (no existe maintenance.log)" }

# ============================================================
# RESUMEN
# ============================================================
Sec "RESUMEN PARA EL ANALISIS"
L "Revisar en este orden:"
L "  (2) FCEA-Backup-Diario: State debe ser 'Ready' y LastTaskResult = 0."
L "  (3) En backups\: tiene que haber un .zip de HOY/AYER. Si el ultimo"
L "      es de hace ~10 dias, ahi esta la falla."
L "  (4) backup.log: buscar '[WARN] No se pudo comprimir' o '[ERROR]'."
L "      --> Si aparece, la causa es la COMPRESION (disco lleno/archivo"
L "          bloqueado); la tarea 'pasa' pero no deja ZIP."
L "  (1) Disco: si esta <20% libre, refuerza la hipotesis de compresion."
L ""
L ("LOG GUARDADO EN: " + $LOG)
L "Traer este archivo para armar el fix quirurgico."

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Diagnostico terminado (solo lectura, no se modifico nada)." -ForegroundColor Cyan
Write-Host "  Log: $LOG" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
try { Read-Host "Presione ENTER para cerrar" } catch {}
