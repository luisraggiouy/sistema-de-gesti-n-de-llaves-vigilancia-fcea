# =============================================================
# DIAGNOSTICAR_LLAVES_SYNC.ps1   (2026-08-03)
# -------------------------------------------------------------
# OBJETIVO
#   Diagnosticar por que una llave AGREGADA en el Monitor de
#   Vigilancia (pestana Llaves) NO aparece en Terminal A / B.
#
#   Hipotesis confirmada leyendo el codigo: la coleccion
#   'lugares' (las llaves) NO se refresca en las terminales
#   (ni polling ni realtime), a diferencia de 'usuarios_registrados'
#   que SI tiene suscripcion realtime y por eso se actualiza sola.
#
#   Este script NO modifica NADA. Es SOLO LECTURA. Se puede
#   correr con el sistema atendiendo gente sin ningun riesgo.
#
# QUE HACE
#   - Detecta identidad de la PC (nombre, IPs, rol probable).
#   - Lee el config.json REAL de esta PC (dist / public / raiz).
#   - Mira que hay escuchando en 5173 (frontend) y 8090 (PocketBase).
#   - Confirma si existe la carpeta dist\ (frontend buildeado local).
#   - Consulta por HTTP GET la coleccion 'lugares' (las llaves) y
#     'usuarios_registrados' (el caso que SI funciona) para comparar
#     totales entre esta PC y el Monitor.
#   - Chequea /api/health del backend configurado.
#
# SALIDA
#   Escribe TODO a un .log en el PENDRIVE (regla 03/08/2026):
#     <pendrive>\_RESULTADOS\LOG_LLAVES_SYNC_<PC>_<fecha>.log
#   Al final muestra en pantalla la ruta exacta del .log.
#
# USO (se lanza desde el .bat companero):
#   powershell -NoProfile -ExecutionPolicy Bypass `
#     -File DIAGNOSTICAR_LLAVES_SYNC.ps1 -PendriveDir "D:\..."
# =============================================================

[CmdletBinding()]
param(
  # Carpeta del pendrive donde dejar el .log (la pasa el .bat).
  # Si no se pasa, se usa la carpeta del propio script.
  [string]$PendriveDir = ''
)

$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'DIAGNOSTICAR LLAVES SYNC - Sistema FCEA'

# -------------------------------------------------------------
# 0) Preparar carpeta y archivo de log en el PENDRIVE
# -------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($PendriveDir)) {
  $PendriveDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$resultDir = Join-Path $PendriveDir '_RESULTADOS'
try {
  if (-not (Test-Path $resultDir)) {
    New-Item -ItemType Directory -Force -Path $resultDir | Out-Null
  }
} catch {
  # Si por lo que sea no se puede crear en el pendrive, caemos a la
  # carpeta del script para no perder el diagnostico.
  $resultDir = $PendriveDir
}

$fecha    = Get-Date -Format 'yyyy-MM-dd_HHmm'
$pcName   = $env:COMPUTERNAME
$logPath  = Join-Path $resultDir ("LOG_LLAVES_SYNC_{0}_{1}.log" -f $pcName, $fecha)

try {
  Start-Transcript -Path $logPath -Force | Out-Null
  $transcriptOn = $true
} catch {
  $transcriptOn = $false
}

function Line($c='='){ Write-Host ($c * 62) -ForegroundColor Yellow }
function Header($t) { Line; Write-Host "  $t" -ForegroundColor Yellow; Line }
function Sub($t) { Write-Host ""; Write-Host "--- $t ---" -ForegroundColor Cyan }

Header "DIAGNOSTICO LLAVES SYNC - PC: $pcName"
Write-Host ("  Fecha/hora : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Host ("  Log en     : {0}" -f $logPath)
Write-Host  "  MODO       : SOLO LECTURA (no modifica nada)"

# -------------------------------------------------------------
# 1) Identidad de la PC
# -------------------------------------------------------------
Sub "[1] Identidad de esta PC"
Write-Host "  Hostname            : $pcName"
Write-Host "  FCEA_ROL (env)      : $env:FCEA_ROL"
Write-Host "  FCEA_HARDWARE (env) : $env:FCEA_HARDWARE"

$ips = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
         Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
         Select-Object -ExpandProperty IPAddress)
Write-Host "  IPs LAN             : $($ips -join ', ')"

$soyMonitor = $ips -contains '192.168.100.10'
$rolProbable = 'desconocido'
if ($soyMonitor)                          { $rolProbable = 'monitor' }
elseif ($pcName -match '^FCEA-TERM')      { $rolProbable = 'terminal' }
elseif ($pcName -match '^FCEA-MON')       { $rolProbable = 'monitor' }
elseif ($env:FCEA_ROL)                    { $rolProbable = $env:FCEA_ROL }
Write-Host "  Rol probable        : $rolProbable" -ForegroundColor Cyan

# -------------------------------------------------------------
# 2) config.json REAL de esta PC
# -------------------------------------------------------------
Sub "[2] config.json REAL (a que backend apunta esta PC)"
$paths = @(
  'C:\sistema-llaves-fcea\dist\config.json',
  'C:\sistema-llaves-fcea\public\config.json',
  'C:\sistema-llaves-fcea\config.json'
)
$urlPb = $null
foreach ($p in $paths) {
  if (Test-Path $p) {
    Write-Host ""
    Write-Host ("  --- {0} ---" -f $p) -ForegroundColor White
    try {
      $raw = Get-Content $p -Raw
      $raw -split "`n" | ForEach-Object { Write-Host ("    {0}" -f $_.TrimEnd()) }
      $j = $raw | ConvertFrom-Json
      # El schema real usa 'pocketbase_url' (con guion bajo).
      $u = $null
      if ($j.PSObject.Properties.Name -contains 'pocketbase_url') { $u = $j.pocketbase_url }
      elseif ($j.PSObject.Properties.Name -contains 'pocketbaseUrl') { $u = $j.pocketbaseUrl }
      if ($null -eq $urlPb -and $u) { $urlPb = $u }
    } catch {
      Write-Host ("    [ERROR al parsear JSON: {0}]" -f $_.Exception.Message) -ForegroundColor Red
    }
  } else {
    Write-Host ("  [NO EXISTE] {0}" -f $p) -ForegroundColor DarkGray
  }
}
if (-not $urlPb) {
  Write-Host "  [!] No se encontro pocketbase_url en ningun config.json" -ForegroundColor Red
  # Fallback razonable para poder seguir consultando.
  if ($soyMonitor) { $urlPb = 'http://127.0.0.1:8090' }
}
Write-Host ""
Write-Host ("  >> pocketbase_url efectivo: {0}" -f $urlPb) -ForegroundColor Green

# -------------------------------------------------------------
# 3) Puertos 5173 (frontend) y 8090 (PocketBase)
# -------------------------------------------------------------
Sub "[3] Puertos en escucha en esta PC"
foreach ($port in @(5173, 8090)) {
  $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
  if (-not $conns) {
    Write-Host ("  Puerto {0}: nadie escucha." -f $port) -ForegroundColor Yellow
  } else {
    $seen = @{}
    foreach ($c in $conns) {
      $procId = $c.OwningProcess
      if ($seen.ContainsKey($procId)) { continue }
      $seen[$procId] = $true
      $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
      Write-Host ("  Puerto {0}: {1}:{2}  PID={3}  proc={4}" -f $port, $c.LocalAddress, $c.LocalPort, $procId, ($proc.ProcessName))
    }
  }
}

# -------------------------------------------------------------
# 4) Frontend buildeado local (dist\)
# -------------------------------------------------------------
Sub "[4] Frontend buildeado local (C:\sistema-llaves-fcea\dist)"
$distDir = 'C:\sistema-llaves-fcea\dist'
$distIdx = Join-Path $distDir 'index.html'
if (Test-Path $distIdx) {
  $fi = Get-Item $distIdx
  Write-Host ("  [SI] dist\index.html existe.  Modificado: {0}" -f $fi.LastWriteTime) -ForegroundColor Green
  # Cantidad de archivos JS en assets (indicador del build)
  $assets = Join-Path $distDir 'assets'
  if (Test-Path $assets) {
    $njs = @(Get-ChildItem $assets -Filter *.js -ErrorAction SilentlyContinue).Count
    Write-Host ("       assets\ tiene {0} archivos .js" -f $njs)
  }
} else {
  Write-Host ("  [NO] No existe {0}" -f $distIdx) -ForegroundColor Yellow
  Write-Host  "       (esta PC quiza no buildea local, o la ruta de instalacion es otra)"
}

# Helper para consultar una coleccion por HTTP GET (solo lectura)
function Get-ColeccionInfo($baseUrl, $coleccion) {
  $out = [PSCustomObject]@{ Ok=$false; Total=$null; Ultima=$null; Muestra=@(); Error='' }
  if (-not $baseUrl) { $out.Error = 'sin URL'; return $out }
  $uri = "$baseUrl/api/collections/$coleccion/records?perPage=5&sort=-created"
  try {
    $r = Invoke-WebRequest -Uri $uri -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    $j = $r.Content | ConvertFrom-Json
    $out.Ok = $true
    $out.Total = $j.totalItems
    if ($j.items.Count -gt 0) {
      $out.Ultima = $j.items[0].created
      $out.Muestra = @($j.items | ForEach-Object { $_.nombre })
    }
  } catch {
    $out.Error = $_.Exception.Message
  }
  return $out
}

# -------------------------------------------------------------
# 5) Salud del backend configurado
# -------------------------------------------------------------
Sub "[5] Salud del backend (/api/health)"
if ($urlPb) {
  try {
    $r = Invoke-WebRequest -Uri "$urlPb/api/health" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    Write-Host ("  [OK] {0}/api/health -> HTTP {1}" -f $urlPb, $r.StatusCode) -ForegroundColor Green
  } catch {
    Write-Host ("  [FALLA] {0}/api/health -> {1}" -f $urlPb, $_.Exception.Message) -ForegroundColor Red
  }
}

# -------------------------------------------------------------
# 6) LLAVES (lugares) vs USUARIOS - comparacion clave del bug
# -------------------------------------------------------------
Sub "[6] Coleccion LLAVES (lugares) y USUARIOS - comparacion"

# 6a) Contra el backend configurado (a donde escribe/lee esta PC)
Write-Host ""
Write-Host ("  == Backend configurado: {0} ==" -f $urlPb) -ForegroundColor White
$lugCfg = Get-ColeccionInfo $urlPb 'lugares'
$usrCfg = Get-ColeccionInfo $urlPb 'usuarios_registrados'
if ($lugCfg.Ok) {
  Write-Host ("     lugares               : {0} llaves | ultima creada: {1}" -f $lugCfg.Total, $lugCfg.Ultima) -ForegroundColor Green
  if ($lugCfg.Muestra.Count -gt 0) { Write-Host ("        ultimas: {0}" -f ($lugCfg.Muestra -join ', ')) }
} else {
  Write-Host ("     lugares               : SIN RESPUESTA ({0})" -f $lugCfg.Error) -ForegroundColor Yellow
}
if ($usrCfg.Ok) {
  Write-Host ("     usuarios_registrados  : {0} usuarios | ultima creada: {1}" -f $usrCfg.Total, $usrCfg.Ultima) -ForegroundColor Green
} else {
  Write-Host ("     usuarios_registrados  : SIN RESPUESTA ({0})" -f $usrCfg.Error) -ForegroundColor Yellow
}

# 6b) Contra el Monitor oficial (192.168.100.10:8090) si NO es el mismo
$urlMon = 'http://192.168.100.10:8090'
if ($urlPb -notlike '*192.168.100.10*') {
  Write-Host ""
  Write-Host ("  == Monitor oficial: {0} ==" -f $urlMon) -ForegroundColor White
  $lugMon = Get-ColeccionInfo $urlMon 'lugares'
  if ($lugMon.Ok) {
    Write-Host ("     lugares               : {0} llaves | ultima creada: {1}" -f $lugMon.Total, $lugMon.Ultima) -ForegroundColor Green
    if ($lugMon.Muestra.Count -gt 0) { Write-Host ("        ultimas: {0}" -f ($lugMon.Muestra -join ', ')) }
  } else {
    Write-Host ("     lugares               : SIN RESPUESTA ({0})" -f $lugMon.Error) -ForegroundColor Yellow
  }
}

# 6c) Contra un PocketBase LOCAL (127.0.0.1:8090) si esta PC no es Monitor
#     -> detecta el caso "zombie" donde la terminal lee de su propia DB.
if (-not $soyMonitor) {
  Write-Host ""
  Write-Host  "  == PocketBase LOCAL (127.0.0.1:8090) [no deberia existir en Terminal] ==" -ForegroundColor White
  $lugLoc = Get-ColeccionInfo 'http://127.0.0.1:8090' 'lugares'
  if ($lugLoc.Ok) {
    Write-Host ("     lugares               : {0} llaves  <-- ALERTA: hay PocketBase local en una Terminal" -f $lugLoc.Total) -ForegroundColor Red
  } else {
    Write-Host  "     (sin PocketBase local: correcto para una Terminal)" -ForegroundColor Green
  }
}

# -------------------------------------------------------------
# 7) Resumen orientativo
# -------------------------------------------------------------
Sub "[7] Notas para el analisis (Cline las leera del .log)"
Write-Host  "  - Comparar el total de 'lugares' entre backend configurado y Monitor:"
Write-Host  "    si difieren, esta PC esta leyendo de una DB distinta a la del Monitor."
Write-Host  "  - El bug de sincronizacion de llaves es de CODIGO (frontend), no de datos:"
Write-Host  "    aunque los totales coincidan, la Terminal no refresca 'lugares' en vivo."
Write-Host  "  - Este log confirma rutas de instalacion, build local y estado de la"
Write-Host  "    coleccion para escribir el fix a medida."

Write-Host ""
Line
Write-Host ("  LOG GENERADO EN:") -ForegroundColor Cyan
Write-Host ("    {0}" -f $logPath) -ForegroundColor Green
Write-Host  "  Traelo en el pendrive a la laptop de desarrollo." -ForegroundColor Cyan
Line

if ($transcriptOn) {
  try { Stop-Transcript | Out-Null } catch {}
}

# NOTA v2 (2026-08-06): la pausa la hace ahora el .bat lanzador.
# No usamos Read-Host aca porque el .bat redirige la salida a un archivo
# (_WRAP_...txt en el pendrive), y un Read-Host bajo redireccion se
# colgaria esperando ENTER sin mostrar el prompt. El .bat hace PAUSE.
