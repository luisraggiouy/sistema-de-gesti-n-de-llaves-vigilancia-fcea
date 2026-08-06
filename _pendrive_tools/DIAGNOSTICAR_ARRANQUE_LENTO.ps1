# ============================================================
#  DIAGNOSTICAR_ARRANQUE_LENTO.ps1   (SOLO LECTURA - no repara nada)
#  Sistema FCEA - Monitor Vigilancia
#  Objetivo: entender POR QUE el arranque tarda ~10 min (no es normal).
#
#  Segun las reglas (03/08/2026) este diagnostico ESCRIBE su salida a un
#  .log EN EL PENDRIVE (parametro -OutDir), no en el Escritorio, para que
#  Luis solo traiga el pendrive y Cline lea el .log directamente.
#
#  Captura (todo SOLO LECTURA, no mata procesos, no toca la base):
#   0) Hora de arranque de Windows vs hora actual (cuanto tardo el boot).
#   1) Instancias pocketbase.exe (PID, hora, --dir) -> zombies / colision.
#   2) data.db / -wal / -shm (tamano) + tiempo de respuesta de /api/health.
#   3) Tareas programadas FCEA-* (doble autostart / tormenta al login).
#   4) Loops cmd.exe run_pocketbase / run_frontend.
#   5) TIMELINE del pocketbase.log (ultimas 150 lineas con horas).
#   6) Exclusiones de Windows Defender (proceso/carpeta) -> escaneo en frio.
#   7) Copia el CODIGO REAL del arranque (INICIAR.bat + scripts\lib\*) al
#      pendrive para que Cline lo lea (el orquestador DUENO-UNICO vive solo
#      en C: del Monitor, no esta en el repo).
# ============================================================
[CmdletBinding()]
param(
  [string]$OutDir = ''
)

$ErrorActionPreference = 'Continue'

# --- Resolver carpeta de resultados en el PENDRIVE ---
if ([string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = Join-Path $PSScriptRoot '_RESULTADOS' }
try { if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null } } catch {}

$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$pc    = $env:COMPUTERNAME
$log   = Join-Path $OutDir ("LOG_ARRANQUE_LENTO_{0}_{1}.log" -f $pc, $stamp)
$fuentes = Join-Path $OutDir ("_FUENTES_ARRANQUE_{0}_{1}" -f $pc, $stamp)

Start-Transcript -Path $log -Force | Out-Null

function H($m){ Write-Host ""; Write-Host "===== $m =====" -ForegroundColor Cyan }
function T($m){ Write-Host $m }

$INSTALL = 'C:\sistema-llaves-fcea'
$PB_DATA = 'C:\ProgramData\FCEA-Sistema-Llaves\pb_data'

H "ENCABEZADO"
T ("Fecha/hora   : {0}" -f (Get-Date))
T ("PC           : {0}" -f $pc)
T ("Diagnostico  : ARRANQUE LENTO del Monitor (~10 min) - SOLO LECTURA")
T ("Log en       : {0}" -f $log)

H "0) Cuanto tardo el arranque de Windows"
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $boot = $os.LastBootUpTime
  $now  = Get-Date
  T ("  Windows arranco : {0}" -f $boot)
  T ("  Hora actual     : {0}" -f $now)
  T ("  Uptime          : {0:g}" -f ($now - $boot))
} catch { T ("  (no se pudo leer LastBootUpTime: {0})" -f $_.Exception.Message) }

H "1) Procesos pocketbase.exe (zombies / colision)"
$pbs = @(Get-CimInstance Win32_Process -Filter "Name='pocketbase.exe'" -ErrorAction SilentlyContinue)
T ("  Cantidad de pocketbase.exe: {0}" -f $pbs.Count)
foreach($p in $pbs){
  $ct = try { $p.CreationDate } catch { $null }
  T ("   PID {0}  arrancado {1}" -f $p.ProcessId, $ct)
  T ("      CMD: {0}" -f $p.CommandLine)
}
if ($pbs.Count -gt 1) { Write-Host "  [ALERTA] MAS DE UNA INSTANCIA -> pelea por puerto 8090 / WAL." -ForegroundColor Red }

H "2) Base de datos + tiempo de respuesta de /api/health"
foreach($f in 'data.db','data.db-wal','data.db-shm','logs.db','logs.db-wal','logs.db-shm'){
  $fp = Join-Path $PB_DATA $f
  if(Test-Path $fp){ $i=Get-Item $fp; T ("  {0,-14} {1,12:N0} bytes   mod {2}" -f $f, $i.Length, $i.LastWriteTime) }
  else { T ("  {0,-14} (no existe)" -f $f) }
}
try {
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8090/api/health' -TimeoutSec 5 -UseBasicParsing
  $sw.Stop()
  T ("  /api/health -> HTTP {0} en {1} ms  {2}" -f [int]$r.StatusCode, $sw.ElapsedMilliseconds, $r.Content)
} catch { T ("  /api/health -> SIN RESPUESTA: {0}" -f $_.Exception.Message) }

$puerto = @(Get-NetTCPConnection -LocalPort 8090 -State Listen -ErrorAction SilentlyContinue)
T ("  Escuchando en el puerto 8090: {0} conexion(es) LISTEN" -f $puerto.Count)
foreach($c in $puerto){ T ("     PID {0}" -f $c.OwningProcess) }

H "3) Tareas programadas FCEA-* (doble autostart / tormenta de I/O al login)"
$tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'FCEA*' })
T ("  Cantidad de tareas FCEA-*: {0}" -f $tasks.Count)
$autostart = 0
foreach($t in $tasks){
  $info = try { Get-ScheduledTaskInfo -TaskName $t.TaskName -ErrorAction SilentlyContinue } catch { $null }
  T ("  - {0}   estado={1}   ultimaEjec={2}   ultimoResultado={3}" -f $t.TaskName, $t.State, ($info.LastRunTime), ($info.LastTaskResult))
  foreach($a in $t.Actions){
    T ("       ejecuta: {0} {1}" -f $a.Execute, $a.Arguments)
    if (("$($a.Execute) $($a.Arguments)") -match 'INICIAR|run_pocketbase|start-server') { $autostart++ }
  }
}
if ($autostart -gt 1) { Write-Host "  [ALERTA] $autostart acciones arrancan PocketBase -> DOBLE ARRANQUE." -ForegroundColor Red }

H "4) Loops (cmd.exe) que relanzan PocketBase / Frontend"
$cmds = @(Get-CimInstance Win32_Process -Filter "Name='cmd.exe'" -ErrorAction SilentlyContinue)
$runPb = @($cmds | Where-Object { $_.CommandLine -match 'run_pocketbase' })
$runFe = @($cmds | Where-Object { $_.CommandLine -match 'run_frontend' })
T ("  Loops run_pocketbase.bat corriendo: {0}" -f $runPb.Count)
foreach($c in $runPb){ T ("     PID {0}: {1}" -f $c.ProcessId, $c.CommandLine) }
T ("  Loops run_frontend.bat corriendo:  {0}" -f $runFe.Count)
if ($runPb.Count -gt 1) { Write-Host "  [ALERTA] $($runPb.Count) loops de run_pocketbase -> cada uno relanza PB." -ForegroundColor Red }

H "5) TIMELINE del pocketbase.log (ultimas 150 lineas con horas)"
$logsPb = @(
  'C:\sistema-llaves-fcea\logs\pocketbase.log',
  'C:\sistema-llaves-fcea\pocketbase\logs\pocketbase.log'
)
$pbLog = $logsPb | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($pbLog) {
  $i = Get-Item $pbLog
  T ("  Archivo: {0}  ({1:N0} bytes, mod {2})" -f $pbLog, $i.Length, $i.LastWriteTime)
  T "  ---- ULTIMAS 150 LINEAS ----"
  Get-Content $pbLog -Tail 150 | ForEach-Object { Write-Host $_ }
  T "  ---- FIN ----"
} else {
  T "  (no encontre pocketbase.log)"
}

H "6) Windows Defender (escaneo en frio de pocketbase.exe / data.db)"
try {
  $mp = Get-MpPreference -ErrorAction Stop
  T ("  ExclusionPath    : {0}" -f (($mp.ExclusionPath)    -join ' ; '))
  T ("  ExclusionProcess : {0}" -f (($mp.ExclusionProcess) -join ' ; '))
  $incluida = $false
  foreach($e in @($mp.ExclusionPath)){ if ("$e" -match 'sistema-llaves|FCEA') { $incluida = $true } }
  if (-not $incluida) { Write-Host "  [OJO] La carpeta del sistema NO figura excluida de Defender -> puede escanear en cada arranque." -ForegroundColor Yellow }
} catch { T ("  (no se pudo leer Get-MpPreference, quiza sin admin: {0})" -f $_.Exception.Message) }

H "7) Copiando CODIGO REAL del arranque al pendrive (para que Cline lo lea)"
try {
  if (-not (Test-Path $fuentes)) { New-Item -ItemType Directory -Path $fuentes -Force | Out-Null }
  $aCopiar = @(
    (Join-Path $INSTALL 'scripts\install\INICIAR.bat'),
    (Join-Path $INSTALL 'pocketbase\pb_config.json'),
    (Join-Path $INSTALL 'public\config.json')
  )
  foreach($src in $aCopiar){
    if (Test-Path $src) { Copy-Item $src -Destination $fuentes -Force -ErrorAction SilentlyContinue; T ("  copiado: {0}" -f $src) }
    else { T ("  (no existe): {0}" -f $src) }
  }
  # Toda la carpeta scripts\lib (ahi vive el orquestador iniciar_pocketbase / esperar_pocketbase / run_pocketbase)
  $libSrc = Join-Path $INSTALL 'scripts\lib'
  if (Test-Path $libSrc) {
    $libDst = Join-Path $fuentes 'scripts_lib'
    New-Item -ItemType Directory -Path $libDst -Force | Out-Null
    Get-ChildItem $libSrc -Include *.bat,*.ps1 -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
      Copy-Item $_.FullName -Destination $libDst -Force -ErrorAction SilentlyContinue
    }
    T ("  copiado: {0}\*.bat,*.ps1 -> {1}" -f $libSrc, $libDst)
  } else { T ("  (no existe): {0}" -f $libSrc) }
  T ("  >> Codigo del arranque copiado en: {0}" -f $fuentes)
} catch { T ("  (error copiando fuentes: {0})" -f $_.Exception.Message) }

H "RESUMEN"
T ("  pocketbase.exe = {0} | loops run_pocketbase = {1} | tareas que arrancan PB = {2}" -f $pbs.Count, $runPb.Count, $autostart)
T ("  LOG guardado en el pendrive: {0}" -f $log)
T ("  Fuentes del arranque en    : {0}" -f $fuentes)
T ""
Stop-Transcript | Out-Null

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Green
Write-Host " LISTO. Trae de vuelta el pendrive: Cline leera este .log:" -ForegroundColor Green
Write-Host "   $log" -ForegroundColor Yellow
Write-Host " y las fuentes del arranque en:" -ForegroundColor Green
Write-Host "   $fuentes" -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Presiona ENTER para cerrar"
