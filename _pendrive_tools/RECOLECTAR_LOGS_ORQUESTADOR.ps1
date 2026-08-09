# ============================================================
#  RECOLECTAR_LOGS_ORQUESTADOR.ps1   (HERRAMIENTAS_RED - SOLO LECTURA)
# ------------------------------------------------------------
#  Trae al pendrive los logs CON TIMESTAMPS del arranque, para
#  saber EXACTAMENTE en que sub-paso se van los ~7-8 minutos:
#    - pocketbase\maintenance\logs\iniciar_pocketbase.log  (orquestador)
#    - pocketbase\maintenance\logs\sanear_wal.log
#    - logs\pocketbase.log
#    - check_system_health*.log (si existe)
#  Ademas: hora de boot de Windows y ultima ejecucion de la tarea
#  AutoStart. NO modifica nada del sistema.
# ============================================================
[CmdletBinding()]
param([string]$OutDir = "$PSScriptRoot\_RESULTADOS")

$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$pc    = $env:COMPUTERNAME
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$log   = Join-Path $OutDir "LOG_ORQUESTADOR_${pc}_${stamp}.log"
Start-Transcript -Path $log -Force | Out-Null

Write-Host "===== LOGS DEL ORQUESTADOR FCEA (SOLO LECTURA) ====="
Write-Host ("Fecha/hora : " + (Get-Date))
Write-Host ("PC         : $pc")
Write-Host ""

$base    = "C:\sistema-llaves-fcea"
$logsDir = Join-Path $base "pocketbase\maintenance\logs"
$dst     = Join-Path $OutDir "_LOGS_ORQUESTADOR_${pc}_${stamp}"
New-Item -ItemType Directory -Force -Path $dst | Out-Null

Write-Host "----- Copiando logs al pendrive -----"
$archivos = @(
  (Join-Path $logsDir "iniciar_pocketbase.log"),
  (Join-Path $logsDir "sanear_wal.log"),
  (Join-Path $base "logs\pocketbase.log")
)
foreach ($f in $archivos) {
  if (Test-Path $f) {
    Copy-Item $f $dst -Force -ErrorAction SilentlyContinue
    Write-Host ("  copiado : $f  (" + [math]::Round((Get-Item $f).Length/1KB,1) + " KB)")
  } else {
    Write-Host ("  NO existe: $f")
  }
}
Get-ChildItem -Path $base -Recurse -Filter "check_system_health*.log" -ErrorAction SilentlyContinue | ForEach-Object {
  Copy-Item $_.FullName $dst -Force -ErrorAction SilentlyContinue
  Write-Host ("  copiado : " + $_.FullName)
}

Write-Host ""
Write-Host "----- Boot de Windows + tarea AutoStart -----"
try {
  $os = Get-CimInstance Win32_OperatingSystem
  Write-Host ("  Windows arranco    : " + $os.LastBootUpTime)
} catch { Write-Host "  (no pude leer LastBootUpTime)" }
try {
  $t = Get-ScheduledTask -TaskName "FCEA-Sistema-Llaves-AutoStart" -ErrorAction SilentlyContinue
  if ($t) {
    $i = $t | Get-ScheduledTaskInfo
    Write-Host ("  AutoStart ultimaEjec: " + $i.LastRunTime + "   resultado: " + $i.LastTaskResult)
  }
} catch {}

Write-Host ""
Write-Host "===== ULTIMAS 100 LINEAS de iniciar_pocketbase.log (con timestamps) ====="
$ip = Join-Path $logsDir "iniciar_pocketbase.log"
if (Test-Path $ip) { Get-Content $ip -Tail 100 } else { Write-Host "  (no existe)" }

Write-Host ""
Write-Host "===== ULTIMAS 60 LINEAS de sanear_wal.log ====="
$sw = Join-Path $logsDir "sanear_wal.log"
if (Test-Path $sw) { Get-Content $sw -Tail 60 } else { Write-Host "  (no existe)" }

Write-Host ""
Write-Host ("LISTO. Copias en: $dst")
Write-Host ("Log de esta corrida: $log")
Stop-Transcript | Out-Null

Write-Host ""
Write-Host "Trae el pendrive de vuelta: Cline leera estos .log directamente."
