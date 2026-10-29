# ============================================================
# DIAGNOSTICO DE DISCO Y BACKUP  (SOLO LECTURA)
# Sistema de Gestion de Llaves FCEA
# Fecha: 2026-10-05
#
# Correr en el MONITOR (PC servidor). NO modifica, NO borra, NO
# toca la base ni la tarea programada. Solo mide y graba un log.
#
# El log queda en la carpeta de este script (pendrive), con nombre
# DIAGNOSTICO_DISCO_<fecha>.txt para traerlo a la laptop.
# ============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'DIAGNOSTICO DISCO Y BACKUP (solo lectura) - FCEA'

$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$STAMP = Get-Date -Format 'yyyy-MM-dd_HHmm'
$LOG = Join-Path $SCRIPTDIR ("DIAGNOSTICO_DISCO_" + $STAMP + ".txt")

function L { param([string]$t) $t | Tee-Object -FilePath $LOG -Append }
function Sec { param([string]$t) ("`n" + ('=' * 64) + "`n  " + $t + "`n" + ('=' * 64)) | Tee-Object -FilePath $LOG -Append }
function GB { param($b) if ($null -eq $b) { '0' } else { [math]::Round($b/1GB,2).ToString() + ' GB' } }
function MB { param($b) if ($null -eq $b) { '0' } else { [math]::Round($b/1MB,2).ToString() + ' MB' } }

function FolderSize {
  param([string]$path)
  if (-not (Test-Path $path)) { return $null }
  try {
    $sum = (Get-ChildItem -LiteralPath $path -Recurse -File -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum
    return $sum
  } catch { return $null }
}

"DIAGNOSTICO DISCO Y BACKUP - FCEA" | Set-Content -Path $LOG -Encoding UTF8
L ("Generado: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
L ("PC: " + $env:COMPUTERNAME + "   Usuario: " + $env:USERNAME)

Sec "1) DISCO C: (total / usado / libre)"
try {
  $d = Get-PSDrive -Name C -ErrorAction Stop
  $tot = $d.Used + $d.Free
  L ("Total : " + (GB $tot))
  L ("Usado : " + (GB $d.Used))
  L ("Libre : " + (GB $d.Free) + "  (" + [math]::Round(($d.Free/$tot)*100,1) + "% libre)")
} catch { L ("[ERROR] No pude leer el disco C: $_") }

Sec "2) TOP 25 CARPETAS MAS GRANDES DE C:\ (nivel 1 y 2)"
L "(puede tardar un minuto; mide todo el disco para cazar lo que ocupe)"
try {
  $dirs = @()
  $dirs += Get-ChildItem -LiteralPath 'C:\' -Directory -Force -ErrorAction SilentlyContinue
  foreach ($d1 in $dirs.Clone()) {
    $dirs += Get-ChildItem -LiteralPath $d1.FullName -Directory -Force -ErrorAction SilentlyContinue
  }
  $res = foreach ($d in $dirs) {
    $s = FolderSize $d.FullName
    [PSCustomObject]@{ Size = [long]($s); Path = $d.FullName }
  }
  $res | Where-Object { $_.Size -gt 0 } | Sort-Object Size -Descending | Select-Object -First 25 |
    ForEach-Object { L (("{0,12}" -f (GB $_.Size)) + "  " + $_.Path) }
} catch { L ("[ERROR] $_") }

Sec "3) C:\sistema-llaves-fcea  (desglose de subcarpetas)"
$INSTALL = 'C:\sistema-llaves-fcea'
if (Test-Path $INSTALL) {
  L ("Total instalacion: " + (GB (FolderSize $INSTALL)))
  Get-ChildItem -LiteralPath $INSTALL -Directory -Force -ErrorAction SilentlyContinue |
    ForEach-Object { [PSCustomObject]@{ Size=[long](FolderSize $_.FullName); Name=$_.Name } } |
    Sort-Object Size -Descending |
    ForEach-Object { L (("{0,12}" -f (GB $_.Size)) + "  " + $_.Name) }
} else { L ("[AVISO] No existe $INSTALL") }

Sec "4) C:\ProgramData\FCEA-Sistema-Llaves (si existe)"
$PD = 'C:\ProgramData\FCEA-Sistema-Llaves'
if (Test-Path $PD) {
  L ("Total: " + (GB (FolderSize $PD)))
  Get-ChildItem -LiteralPath $PD -Directory -Force -ErrorAction SilentlyContinue |
    ForEach-Object { L (("{0,12}" -f (GB (FolderSize $_.FullName))) + "  " + $_.Name) }
} else { L ("No existe (instalacion portable, datos en C:\sistema-llaves-fcea)") }

Sec "5) dist_backup_*  (los que crea cada APLICAR_*.ps1)"
$db = Get-ChildItem -LiteralPath $INSTALL -Directory -Force -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like 'dist_backup_*' }
if ($db) {
  $totDb = 0
  $db | Sort-Object Name | ForEach-Object {
    $s = FolderSize $_.FullName; $totDb += [long]$s
    L (("{0,10}" -f (MB $s)) + "  " + $_.Name)
  }
  L ("--------")
  L ("Cantidad: " + $db.Count + "    PESO TOTAL dist_backup_*: " + (GB $totDb))
} else { L "No hay carpetas dist_backup_* en la instalacion." }

Sec "6) Carpeta backups\ (ZIP de la BD + retencion)"
$bk = Join-Path $INSTALL 'backups'
if (Test-Path $bk) {
  $zips = Get-ChildItem -LiteralPath $bk -File -Filter '*.zip' -ErrorAction SilentlyContinue
  $otros = Get-ChildItem -LiteralPath $bk -Force -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -or $_.Extension -ne '.zip' }
  L ("Peso total carpeta backups: " + (GB (FolderSize $bk)))
  if ($zips) {
    $totZ = ($zips | Measure-Object Length -Sum).Sum
    L ("ZIP de backup: " + $zips.Count + "   peso total: " + (MB $totZ))
    L ("Mas viejo: " + ($zips | Sort-Object LastWriteTime | Select-Object -First 1).LastWriteTime)
    L ("Mas nuevo: " + ($zips | Sort-Object LastWriteTime | Select-Object -Last 1).LastWriteTime)
    L "--- listado ---"
    $zips | Sort-Object LastWriteTime | ForEach-Object { L (("{0,10}" -f (MB $_.Length)) + "  " + $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm') + "  " + $_.Name) }
  } else { L "No hay archivos .zip en backups\ (la tarea no dejo backups?)." }
  if ($otros) { L "--- NO-zip dentro de backups\ (carpetas sin comprimir?) ---"; $otros | ForEach-Object { L ("   " + (MB (FolderSize $_.FullName)) + "  " + $_.Name) } }
} else { L ("[AVISO] No existe $bk") }

Sec "7) SQLite / WAL (lo que puede crecer sin checkpoint)"
$cands = @(
  (Join-Path $INSTALL 'pocketbase\pb_data'),
  'C:\ProgramData\FCEA-Sistema-Llaves\pb_data'
)
foreach ($c in $cands) {
  if (Test-Path $c) {
    L ("pb_data: " + $c + "   total: " + (MB (FolderSize $c)))
    foreach ($f in @('data.db','data.db-wal','data.db-shm','auxiliary.db','auxiliary.db-wal')) {
      $fp = Join-Path $c $f
      if (Test-Path $fp) { L (("   {0,10}" -f (MB (Get-Item $fp).Length)) + "  " + $f) }
    }
  }
}

Sec "8) LOGS del sistema (archivos .log mas grandes)"
$logDirs = @(
  (Join-Path $INSTALL 'pocketbase\maintenance\logs'),
  (Join-Path $INSTALL 'logs'),
  $INSTALL
)
$allLogs = foreach ($ld in $logDirs) {
  if (Test-Path $ld) { Get-ChildItem -LiteralPath $ld -Recurse -File -Filter '*.log' -ErrorAction SilentlyContinue }
}
if ($allLogs) {
  $allLogs | Sort-Object Length -Descending | Select-Object -First 15 |
    ForEach-Object { L (("{0,10}" -f (MB $_.Length)) + "  " + $_.FullName) }
} else { L "No se encontraron archivos .log." }

Sec "9) Papelera de reciclaje y TEMP"
try {
  $rb = FolderSize 'C:\$Recycle.Bin'
  L ("Papelera (C:\`$Recycle.Bin): " + (GB $rb))
} catch { L "Papelera: no accesible" }
foreach ($tp in @($env:TEMP, 'C:\Windows\Temp')) {
  if (Test-Path $tp) { L ("TEMP " + $tp + ": " + (GB (FolderSize $tp))) }
}

Sec "10) TAREAS PROGRAMADAS DE BACKUP (explica el 'atrasado')"
try {
  $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
           Where-Object { $_.TaskName -like '*FCEA*' -or $_.TaskName -like '*Backup*' -or $_.TaskName -like '*Llaves*' }
  if ($tasks) {
    foreach ($t in $tasks) {
      L ("")
      L ("TAREA: " + $t.TaskName + "   (estado: " + $t.State + ")")
      try {
        $i = Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue
        L ("   Ultima ejecucion : " + $i.LastRunTime)
        L ("   Ultimo resultado : " + $i.LastTaskResult + "  (0 = OK; distinto de 0 = fallo)")
        L ("   Proxima ejecucion: " + $i.NextRunTime)
      } catch { L ("   (no pude leer info de ejecucion)") }
    }
  } else { L "[IMPORTANTE] NO se encontro ninguna tarea FCEA/Backup. Puede estar BORRADA o DESHABILITADA." }
} catch { L ("[ERROR] Get-ScheduledTask fallo (requiere admin?): $_") }

Sec "11) Ultimas lineas de backup.log"
$blog = Join-Path $INSTALL 'pocketbase\maintenance\logs\backup.log'
if (Test-Path $blog) {
  L ("Archivo: " + $blog + "   (" + (MB (Get-Item $blog).Length) + ")")
  L "--- ultimas 40 lineas ---"
  Get-Content $blog -Tail 40 -ErrorAction SilentlyContinue | ForEach-Object { L $_ }
} else { L ("No existe " + $blog) }

Sec "12) CONTEXTO (fecha del sistema y rol)"
L ("Fecha del sistema: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss dddd'))
$cfg = Join-Path $INSTALL 'dist\config.json'
if (-not (Test-Path $cfg)) { $cfg = Join-Path $INSTALL 'public\config.json' }
if (Test-Path $cfg) {
  try { $c = Get-Content $cfg -Raw | ConvertFrom-Json; L ("rol: " + $c.rol + "   (config: " + $cfg + ")") }
  catch { L ("No pude parsear " + $cfg) }
} else { L "No encontre config.json" }

Sec "FIN DEL DIAGNOSTICO"
L ("Log guardado en: " + $LOG)
Write-Host ""
Write-Host ("LISTO. Traele este archivo a la laptop: " + $LOG) -ForegroundColor Green
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
