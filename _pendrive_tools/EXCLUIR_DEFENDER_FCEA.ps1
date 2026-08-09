# ============================================================
#  EXCLUIR_DEFENDER_FCEA.ps1
#  Sistema FCEA - Monitor Vigilancia
#
#  FIX del ARRANQUE LENTO (diagnostico 09/08/2026):
#  En arranque en frio, Windows Defender escanea pocketbase.exe y
#  los powershell/cmd del arranque ANTES de dejarlos ejecutar, lo
#  que retrasa el lanzamiento de PocketBase varios minutos.
#  Este script AGREGA a las exclusiones de Defender la carpeta del
#  sistema, la carpeta de datos y el proceso pocketbase.exe.
#
#  SEGURO Y REVERSIBLE:
#   - NO toca config.json, ni la base, ni el WAL, ni el orquestador.
#   - Solo agrega exclusiones de Defender (Add-MpPreference).
#   - Rollback: correr con -Quitar (o QUITAR_EXCLUSION_DEFENDER_FCEA.bat).
#   - Requiere ADMINISTRADOR (el .bat pide permisos solo).
#   - Escribe su salida a un .log en el pendrive (subcarpeta _RESULTADOS).
# ============================================================
[CmdletBinding()]
param(
  [switch]$Quitar,
  [string]$OutDir = ''
)

$ErrorActionPreference = 'Continue'

if ([string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = Join-Path $PSScriptRoot '_RESULTADOS' }
try { if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null } } catch {}

$stamp  = Get-Date -Format 'yyyy-MM-dd_HHmm'
$pc     = $env:COMPUTERNAME
$accion = if ($Quitar) { 'QUITAR' } else { 'APLICAR' }
$log    = Join-Path $OutDir ("LOG_DEFENDER_{0}_{1}_{2}.log" -f $accion, $pc, $stamp)

Start-Transcript -Path $log -Force | Out-Null

Write-Host ""
Write-Host "===== EXCLUSIONES DEFENDER FCEA ($accion) =====" -ForegroundColor Cyan
Write-Host ("Fecha/hora : {0}" -f (Get-Date))
Write-Host ("PC         : {0}" -f $pc)

# --- Verificar privilegios de administrador ---
$idActual = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($idActual)
$esAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) {
  Write-Host ""
  Write-Host "[ERROR] Este script necesita ejecutarse COMO ADMINISTRADOR." -ForegroundColor Red
  Write-Host "        Cerra esta ventana y hace doble clic en el .bat (pide permisos solo)."
  Stop-Transcript | Out-Null
  Read-Host "Presiona ENTER para cerrar"
  exit 1
}

$rutas    = @('C:\sistema-llaves-fcea', 'C:\ProgramData\FCEA-Sistema-Llaves')
$procesos = @('pocketbase.exe')

Write-Host ""
Write-Host "--- Exclusiones ANTES ---"
try {
  $mp = Get-MpPreference
  Write-Host ("ExclusionPath    : {0}" -f (($mp.ExclusionPath)    -join ' ; '))
  Write-Host ("ExclusionProcess : {0}" -f (($mp.ExclusionProcess) -join ' ; '))
} catch { Write-Host ("(no se pudo leer Get-MpPreference: {0})" -f $_.Exception.Message) }

if ($Quitar) {
  Write-Host ""
  Write-Host "--- QUITANDO exclusiones FCEA (rollback) ---" -ForegroundColor Yellow
  foreach ($r in $rutas) {
    try { Remove-MpPreference -ExclusionPath $r -ErrorAction Stop; Write-Host ("  quitada ruta   : {0}" -f $r) }
    catch { Write-Host ("  (no estaba/err ruta {0}: {1})" -f $r, $_.Exception.Message) }
  }
  foreach ($p in $procesos) {
    try { Remove-MpPreference -ExclusionProcess $p -ErrorAction Stop; Write-Host ("  quitado proceso: {0}" -f $p) }
    catch { Write-Host ("  (no estaba/err proc {0}: {1})" -f $p, $_.Exception.Message) }
  }
} else {
  Write-Host ""
  Write-Host "--- AGREGANDO exclusiones FCEA ---" -ForegroundColor Green
  foreach ($r in $rutas) {
    if (-not (Test-Path $r)) { Write-Host ("  (OJO: no existe {0}; la agrego igual)" -f $r) -ForegroundColor Yellow }
    try { Add-MpPreference -ExclusionPath $r -ErrorAction Stop; Write-Host ("  agregada ruta   : {0}" -f $r) }
    catch { Write-Host ("  (error ruta {0}: {1})" -f $r, $_.Exception.Message) }
  }
  foreach ($p in $procesos) {
    try { Add-MpPreference -ExclusionProcess $p -ErrorAction Stop; Write-Host ("  agregado proceso: {0}" -f $p) }
    catch { Write-Host ("  (error proceso {0}: {1})" -f $p, $_.Exception.Message) }
  }
}

Write-Host ""
Write-Host "--- Exclusiones DESPUES ---"
try {
  $mp2 = Get-MpPreference
  Write-Host ("ExclusionPath    : {0}" -f (($mp2.ExclusionPath)    -join ' ; '))
  Write-Host ("ExclusionProcess : {0}" -f (($mp2.ExclusionProcess) -join ' ; '))
} catch {}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Green
if ($Quitar) {
  Write-Host " LISTO (rollback). Se quitaron las exclusiones FCEA de Defender." -ForegroundColor Green
} else {
  Write-Host " LISTO. Ahora REINICIA el Monitor y compara cuanto tarda en" -ForegroundColor Green
  Write-Host " arrancar (deberia bajar de ~8 min a segundos)." -ForegroundColor Green
}
Write-Host (" Log en: {0}" -f $log) -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor Green
Write-Host ""
Stop-Transcript | Out-Null
Read-Host "Presiona ENTER para cerrar"
