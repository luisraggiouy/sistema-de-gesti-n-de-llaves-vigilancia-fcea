# ============================================================
#  DIAGNOSTICAR_ARRANQUE.ps1   (SOLO LECTURA - no repara nada)
#  Caza el origen del "PocketBase arranca pero no escribe" tras reboot.
#  Sistema FCEA - Monitor Vigilancia
# ============================================================
#  Reporta:
#   1) Cuantos pocketbase.exe hay, sus PIDs, hora de arranque y CMD (--dir).
#   2) Estado de data.db / -wal / -shm (tamano y fecha) + salud HTTP.
#   3) Tareas programadas FCEA-* que arrancan el sistema al login
#      (nombre, estado, que ejecutan) -> para detectar DOBLE autostart.
#   4) Cuantos cmd.exe estan corriendo run_pocketbase.bat / run_frontend.bat
#      (cada uno relanza PocketBase/Frontend en loop -> si hay 2, colision).
#  NO mata procesos, NO toca la base, NO cambia config.
# ============================================================

$ErrorActionPreference = 'Continue'
$log = Join-Path ([Environment]::GetFolderPath('Desktop')) 'DIAGNOSTICAR_ARRANQUE_LOG.txt'
Start-Transcript -Path $log -Force | Out-Null

function T($m){ Write-Host $m }
function H($m){ Write-Host ""; Write-Host "===== $m =====" -ForegroundColor Cyan }

$PB_DATA = 'C:\ProgramData\FCEA-Sistema-Llaves\pb_data'

H "1) Procesos pocketbase.exe"
$pbs = @(Get-CimInstance Win32_Process -Filter "Name='pocketbase.exe'" -ErrorAction SilentlyContinue)
T ("Cantidad de pocketbase.exe: {0}" -f $pbs.Count)
foreach($p in $pbs){
  $ct = try { $p.CreationDate } catch { $null }
  T ("  PID {0}  arrancado {1}" -f $p.ProcessId, $ct)
  T ("     CMD: {0}" -f $p.CommandLine)
}
if ($pbs.Count -gt 1) { Write-Host "  [ALERTA] HAY MAS DE UNA INSTANCIA -> colision de WAL probable." -ForegroundColor Red }

H "2) Estado de la base y salud HTTP"
foreach($f in 'data.db','data.db-wal','data.db-shm'){
  $fp = Join-Path $PB_DATA $f
  if(Test-Path $fp){ $i=Get-Item $fp; T ("  {0,-14} {1,10:N0} bytes   mod {2}" -f $f, $i.Length, $i.LastWriteTime) }
  else { T ("  {0,-14} (no existe)" -f $f) }
}
try {
  $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8090/api/health' -TimeoutSec 5 -UseBasicParsing
  T ("  /api/health -> HTTP {0}  {1}" -f [int]$r.StatusCode, $r.Content)
} catch { T ("  /api/health -> SIN RESPUESTA: {0}" -f $_.Exception.Message) }

H "3) Tareas programadas FCEA-* (autostart / watchdog)"
$tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like 'FCEA*' })
T ("Cantidad de tareas FCEA-*: {0}" -f $tasks.Count)
$autostart = 0
foreach($t in $tasks){
  $info = try { Get-ScheduledTaskInfo -TaskName $t.TaskName -ErrorAction SilentlyContinue } catch { $null }
  T ("  - {0}   estado={1}   ultimaEjec={2}" -f $t.TaskName, $t.State, ($info.LastRunTime))
  foreach($a in $t.Actions){
    T ("       ejecuta: {0} {1}" -f $a.Execute, $a.Arguments)
    if (("$($a.Execute) $($a.Arguments)") -match 'INICIAR|run_pocketbase|start-server') { $autostart++ }
  }
}
if ($autostart -gt 1) { Write-Host "  [ALERTA] $autostart acciones arrancan PocketBase al login -> DOBLE ARRANQUE." -ForegroundColor Red }

H "4) Loops (cmd.exe) que relanzan PocketBase / Frontend"
$cmds = @(Get-CimInstance Win32_Process -Filter "Name='cmd.exe'" -ErrorAction SilentlyContinue)
$runPb = @($cmds | Where-Object { $_.CommandLine -match 'run_pocketbase' })
$runFe = @($cmds | Where-Object { $_.CommandLine -match 'run_frontend' })
T ("  Loops run_pocketbase.bat corriendo: {0}" -f $runPb.Count)
foreach($c in $runPb){ T ("     PID {0}: {1}" -f $c.ProcessId, $c.CommandLine) }
T ("  Loops run_frontend.bat corriendo:  {0}" -f $runFe.Count)
if ($runPb.Count -gt 1) { Write-Host "  [ALERTA] HAY $($runPb.Count) loops de run_pocketbase -> cada uno relanza PB." -ForegroundColor Red }

H "RESUMEN"
T ("  pocketbase.exe = {0} | loops run_pocketbase = {1} | tareas que arrancan PB = {2}" -f $pbs.Count, $runPb.Count, $autostart)
T ""
T "Sacale FOTO a TODO esto (o mandame el archivo del Escritorio: DIAGNOSTICAR_ARRANQUE_LOG.txt)."
Stop-Transcript | Out-Null
Write-Host ""
Read-Host "Presiona ENTER para cerrar"
