# ============================================================
#  DIAGNOSTICAR_INSTANCIA_POCKETBASE.ps1   (SOLO LECTURA)
#  Sistema de Gestion de Llaves FCEA - HERRAMIENTAS_RED
# ------------------------------------------------------------
#  OBJETIVO (2026-08-01):
#    Confirmar, en un ARRANQUE FALLADO del Monitor (levanta pero
#    NO llegan pedidos / no pasan a "en uso"), cual de estas dos
#    causas es la verdadera:
#
#      (A) DOBLE INSTANCIA: hay 2+ pocketbase.exe (o 2+ loops
#          run_pocketbase.bat) peleando por el mismo data.db ->
#          el segundo sirve en modo readonly.
#      (B) READONLY CON INSTANCIA UNICA: hay 1 solo pocketbase.exe
#          pero abrio la base en solo-lectura (WAL/SHM colgados
#          del apagado). El log muestra "readonly database (8)".
#
#  NO MODIFICA NADA salvo un CREATE+DELETE de prueba (throwaway,
#  con rollback) en la coleccion 'lugares' para saber si ESCRIBE.
#  No mata procesos, no toca config, no toca la base.
#
#  Vuelca TODO a un archivo de log al lado de este script (en el
#  pendrive) para que Luis lo traiga a la laptop de desarrollo.
# ============================================================

$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'DIAGNOSTICAR INSTANCIA POCKETBASE - FCEA'

$PB_URL = 'http://127.0.0.1:8090'
$ADMIN_EMAIL = 'vigilancia@llaves.local'
$ADMIN_PASS  = 'vigilanciamvd2026'

$readonlyEnLog = $false

# --- Log a archivo (al lado del script, o al TEMP si es solo lectura) ---
$stamp   = Get-Date -Format 'yyyyMMdd_HHmmss'
$logName = "DIAG_INSTANCIA_${env:COMPUTERNAME}_$stamp.log"
$logPath = Join-Path $PSScriptRoot $logName
try {
  Start-Transcript -Path $logPath -Force | Out-Null
  $transcriptOn = $true
} catch {
  # Si el pendrive esta protegido, volcar al TEMP
  $logPath = Join-Path $env:TEMP $logName
  try { Start-Transcript -Path $logPath -Force | Out-Null; $transcriptOn = $true } catch { $transcriptOn = $false }
}

function Line($c='='){ Write-Host ($c * 64) -ForegroundColor Yellow }
function Header($t){ Line; Write-Host "  $t" -ForegroundColor Yellow; Line }
function Sub($t){ Write-Host ""; Write-Host "--- $t ---" -ForegroundColor Cyan }

Header "DIAGNOSTICO INSTANCIA POCKETBASE - $env:COMPUTERNAME"
Write-Host ("  Fecha/hora: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Host ("  Log: {0}" -f $logPath)

# ============================================================
# [1] Todos los pocketbase.exe (con PID, arranque, padre, CMD)
# ============================================================
Sub "[1] Procesos pocketbase.exe corriendo"
$allProc = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
$pbProc  = @($allProc | Where-Object { $_.Name -eq 'pocketbase.exe' })
$pbCount = $pbProc.Count

if ($pbCount -eq 0) {
  Write-Host "  [NADA] No hay ningun pocketbase.exe corriendo." -ForegroundColor Red
} else {
  $col = if ($pbCount -eq 1) { 'Green' } else { 'Red' }
  Write-Host ("  Cantidad de pocketbase.exe: {0}" -f $pbCount) -ForegroundColor $col
  if ($pbCount -gt 1) {
    Write-Host "  [!!!] HAY MAS DE UNO -> esto es la DOBLE INSTANCIA (causa A)." -ForegroundColor Red
  }
  foreach ($p in $pbProc) {
    Write-Host ""
    Write-Host ("  PID={0}  arrancado={1}  ppid={2}" -f $p.ProcessId, $p.CreationDate, $p.ParentProcessId) -ForegroundColor White
    Write-Host ("    EXE: {0}" -f $p.ExecutablePath) -ForegroundColor Gray
    Write-Host ("    CMD: {0}" -f $p.CommandLine) -ForegroundColor Gray
  }
}

# ============================================================
# [2] Cadena de lanzadores (padre / abuelo de cada pocketbase.exe)
# ============================================================
Sub "[2] Quien lanzo cada pocketbase.exe (cadena de padres)"
function Get-ProcById($procId) { $allProc | Where-Object { $_.ProcessId -eq $procId } | Select-Object -First 1 }
if ($pbCount -gt 0) {
  foreach ($p in $pbProc) {
    Write-Host ""
    Write-Host ("  pocketbase.exe PID={0}" -f $p.ProcessId) -ForegroundColor White
    $cur = $p; $nivel = 0
    while ($cur -and $cur.ParentProcessId -and $nivel -lt 5) {
      $padre = Get-ProcById $cur.ParentProcessId
      if (-not $padre) { Write-Host ("      ^-- (padre PID={0} ya no existe)" -f $cur.ParentProcessId) -ForegroundColor DarkGray; break }
      $cmdCorto = "$($padre.CommandLine)"
      if ($cmdCorto.Length -gt 120) { $cmdCorto = $cmdCorto.Substring(0,120) + '...' }
      Write-Host ("      ^-- {0} (PID={1}): {2}" -f $padre.Name, $padre.ProcessId, $cmdCorto) -ForegroundColor DarkCyan
      $cur = $padre; $nivel++
    }
  }
  Write-Host ""
  Write-Host "  (Buscamos ver si un PB viene de run_pocketbase.bat via AutoStart y" -ForegroundColor DarkGray
  Write-Host "   otro del watchdog: eso confirma DOS lanzadores independientes.)" -ForegroundColor DarkGray
}

# ============================================================
# [3] Loops run_pocketbase.bat y watchdog vivos
# ============================================================
Sub "[3] Loops relanzadores y watchdog activos"
$cmdLoops = @($allProc | Where-Object { $_.Name -eq 'cmd.exe' -and "$($_.CommandLine)" -match 'run_pocketbase\.bat' })
$wdProc   = @($allProc | Where-Object { $_.Name -eq 'powershell.exe' -and "$($_.CommandLine)" -match 'watchdog\.ps1' })
Write-Host ("  Loops 'run_pocketbase.bat' vivos: {0}" -f $cmdLoops.Count) -ForegroundColor $(if ($cmdLoops.Count -le 1){'Green'}else{'Red'})
foreach ($c in $cmdLoops) { Write-Host ("    - cmd PID={0} ppid={1}" -f $c.ProcessId, $c.ParentProcessId) -ForegroundColor Gray }
if ($cmdLoops.Count -gt 1) { Write-Host "  [!!!] Hay 2+ loops -> cada uno relanza PB -> DOBLE INSTANCIA garantizada." -ForegroundColor Red }
Write-Host ("  Watchdog (watchdog.ps1) vivos: {0}" -f $wdProc.Count) -ForegroundColor Gray
foreach ($w in $wdProc) { Write-Host ("    - powershell PID={0} ppid={1}" -f $w.ProcessId, $w.ParentProcessId) -ForegroundColor Gray }

# ============================================================
# [4] Puerto 8090: quien escucha
# ============================================================
Sub "[4] Puerto 8090 (quien escucha)"
$conns = netstat -ano | Select-String ':8090\s+.*LISTENING'
if ($conns) {
  foreach ($c in $conns) { Write-Host ("  {0}" -f $c.Line.Trim()) -ForegroundColor Gray }
} else {
  Write-Host "  [NADA] Nadie escuchando en 8090." -ForegroundColor Red
}

# ============================================================
# [5] Tareas programadas FCEA (estado + ultimo resultado)
# ============================================================
Sub "[5] Tareas programadas FCEA (arranque + watchdog)"
$tareas = @('FCEA-Sistema-Llaves-AutoStart','FCEA-Watchdog','FCEA-Watchdog-PocketBase','FCEA-Chequeo-Salud','FCEA-KeepAwake')
foreach ($t in $tareas) {
  try {
    $info = schtasks /Query /TN $t /FO LIST /V 2>$null | Select-String 'Estado|Status|Last Run Time|Ultima|Result|Resultado'
    if ($info) {
      Write-Host ("  [{0}]" -f $t) -ForegroundColor White
      foreach ($l in $info) { Write-Host ("      {0}" -f $l.Line.Trim()) -ForegroundColor Gray }
    } else {
      $exists = schtasks /Query /TN $t 2>$null
      if ($exists) { Write-Host ("  [{0}] existe (sin detalle parseable)" -f $t) -ForegroundColor Gray }
      else { Write-Host ("  [{0}] NO existe" -f $t) -ForegroundColor DarkGray }
    }
  } catch {
    Write-Host ("  [{0}] error consultando: {1}" -f $t, $_.Exception.Message) -ForegroundColor DarkYellow
  }
}

# ============================================================
# [6] Archivos de pb_data (data.db + WAL + SHM) y lock
# ============================================================
Sub "[6] Estado de pb_data (data.db / WAL / SHM)"
$pbDataReal = $null
if ($pbCount -gt 0) {
  foreach ($p in $pbProc) {
    $m = [regex]::Match("$($p.CommandLine)", '--dir[=\s]+"?([^"\s]+)"?')
    if ($m.Success) { $pbDataReal = $m.Groups[1].Value; break }
  }
}
if (-not $pbDataReal) {
  foreach ($c in @('C:\ProgramData\FCEA-Sistema-Llaves\pb_data','C:\sistema-llaves-fcea\pocketbase\pb_data')) {
    if (Test-Path $c) { $pbDataReal = $c; break }
  }
}
Write-Host ("  pb_data: {0}" -f $pbDataReal) -ForegroundColor Cyan
$dbFile = $null
if ($pbDataReal -and (Test-Path $pbDataReal)) {
  $dbFile = Join-Path $pbDataReal 'data.db'
  foreach ($f in @('data.db','data.db-wal','data.db-shm')) {
    $fp = Join-Path $pbDataReal $f
    if (Test-Path $fp) {
      $it = Get-Item $fp
      $extra = if ($f -eq 'data.db') { "  readonly=$($it.IsReadOnly)" } else { '' }
      Write-Host ("  {0,-14}: {1,8:N1} KB   mod: {2}{3}" -f $f, ($it.Length/1KB), $it.LastWriteTime, $extra) -ForegroundColor Gray
    } else {
      Write-Host ("  {0,-14}: (no existe)" -f $f) -ForegroundColor DarkGray
    }
  }
  # Lock exclusivo sobre data.db
  Write-Host ""
  try {
    $fs = [System.IO.File]::Open($dbFile, 'Open', 'ReadWrite', 'None')
    $fs.Close()
    Write-Host "  [OK] data.db abre en modo exclusivo (NADIE lo tiene tomado)." -ForegroundColor Green
    if ($pbCount -ge 1) { Write-Host "      (Raro: hay PB corriendo pero no bloquea la base... revisar.)" -ForegroundColor DarkYellow }
  } catch {
    Write-Host ("  [LOCK] data.db tomado por otro proceso: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "      (Normal con 1 PB. Con 2+ PB es la causa del readonly.)" -ForegroundColor DarkGray
  }
} else {
  Write-Host "  [ERROR] No encontre pb_data en las rutas conocidas." -ForegroundColor Red
}

# ============================================================
# [7] pocketbase.log: readonly + ultimas lineas
# ============================================================
Sub "[7] pocketbase.log (buscando 'readonly database')"
# OJO: run_pocketbase.bat hace `cd pocketbase` y redirige a ..\logs\pocketbase.log
#      -> la ruta REAL es C:\sistema-llaves-fcea\logs\pocketbase.log
$logCandidates = @(
  'C:\sistema-llaves-fcea\logs\pocketbase.log',
  'C:\sistema-llaves-fcea\pocketbase\logs\pocketbase.log',
  'C:\sistema-llaves-fcea\pocketbase\maintenance\logs\pocketbase.log'
)
$pbLog = $logCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
# Respaldo: si no aparece, buscar cualquier pocketbase.log bajo la instalacion
if (-not $pbLog) {
  $pbLog = Get-ChildItem 'C:\sistema-llaves-fcea' -Recurse -Filter 'pocketbase.log' -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if ($pbLog) {
  Write-Host ("  Log: {0}" -f $pbLog) -ForegroundColor Cyan
  $ro = Select-String -Path $pbLog -Pattern 'readonly database|SQLITE_READONLY|attempt to write a readonly|database is locked' -ErrorAction SilentlyContinue | Select-Object -Last 10
  if ($ro) {
    $readonlyEnLog = $true
    Write-Host "  [READONLY] Encontradas lineas de readonly/locked (causa confirmada a nivel log):" -ForegroundColor Red
    foreach ($l in $ro) { Write-Host ("      L{0}: {1}" -f $l.LineNumber, $l.Line.Trim()) -ForegroundColor Red }
  } else {
    Write-Host "  [OK] No hay lineas 'readonly database' / 'database is locked' en el log." -ForegroundColor Green
  }
  Write-Host ""
  Write-Host "  Ultimas 25 lineas del log:" -ForegroundColor DarkGray
  Get-Content $pbLog -Tail 25 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host ("      {0}" -f $_) -ForegroundColor DarkGray }
} else {
  Write-Host "  [AVISO] No encontre pocketbase.log en las rutas conocidas." -ForegroundColor Yellow
}

# ============================================================
# [8] TEST DE ESCRITURA DEFINITIVO (autenticado como ADMIN)
# ------------------------------------------------------------
# Clave: un ADMIN (superuser) SALTEA las reglas de la coleccion.
# Entonces si un CREATE de admin falla:
#   - con data.data POBLADO (errores por campo) -> es VALIDACION
#     (falta un campo requerido), NO es readonly.
#   - con data VACIO / mensaje 'readonly'/'locked' -> es READONLY
#     de verdad (fallo a nivel base de datos).
# Asi eliminamos la ambiguedad del 400 sin login.
# ============================================================
Sub "[8] Prueba de escritura DEFINITIVA (autenticada como admin)"
# $escribe:  $true = escribe OK | $false = readonly | 'validacion' = falta campo
$escribe = $null
$token = $null

function Invoke-PBCreate($url, $bodyObj, $headers) {
  # Devuelve hashtable: ok, status, dataCount, msg, id, raw
  $out = @{ ok=$false; status=$null; dataCount=0; msg=$null; id=$null; raw=$null }
  try {
    $resp = Invoke-WebRequest -Uri $url -Method Post -Body ($bodyObj | ConvertTo-Json) -Headers $headers -TimeoutSec 8 -UseBasicParsing -ErrorAction Stop
    $out.ok = $true; $out.status = $resp.StatusCode; $out.raw = $resp.Content
    try { $out.id = ($resp.Content | ConvertFrom-Json).id } catch {}
  } catch {
    try { $out.status = $_.Exception.Response.StatusCode.Value__ } catch {}
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $out.raw = $_.ErrorDetails.Message }
    if ($out.raw) {
      try {
        $j = $out.raw | ConvertFrom-Json
        $out.msg = $j.message
        if ($j.data) { $out.dataCount = @($j.data.PSObject.Properties).Count }
      } catch {}
    }
  }
  return $out
}

try {
  $r = Invoke-WebRequest -Uri "$PB_URL/api/health" -TimeoutSec 4 -UseBasicParsing -ErrorAction Stop
  Write-Host ("  /api/health -> HTTP {0}" -f $r.StatusCode) -ForegroundColor Green

  # --- 8a. Autenticar como admin (PB 0.22+ y <=0.21) ---
  $authBody = @{ identity = $ADMIN_EMAIL; password = $ADMIN_PASS } | ConvertTo-Json
  foreach ($ep in @("$PB_URL/api/collections/_superusers/auth-with-password","$PB_URL/api/admins/auth-with-password")) {
    try {
      $ar = Invoke-RestMethod -Uri $ep -Method Post -Body $authBody -ContentType 'application/json' -TimeoutSec 6 -ErrorAction Stop
      if ($ar.token) { $token = $ar.token; Write-Host ("  [OK] Autenticado admin via {0}" -f (Split-Path $ep -Leaf)) -ForegroundColor Green; break }
    } catch {}
  }
  if (-not $token) { Write-Host "  [AVISO] No pude autenticarme como admin. Hare el test SIN token (menos preciso)." -ForegroundColor Yellow }

  $headers = @{ 'Content-Type' = 'application/json' }
  if ($token) { $headers['Authorization'] = $token }

  # --- 8b. CREATE de prueba en 'lugares' (admin saltea reglas) ---
  $res = Invoke-PBCreate "$PB_URL/api/collections/lugares/records" (@{ nombre = "__DIAG_WTEST_$stamp" }) $headers
  Write-Host ("  CREATE lugares -> HTTP {0}" -f $res.status) -ForegroundColor $(if ($res.ok){'Green'}else{'Red'})
  if ($res.raw) { $short = "$($res.raw)"; if ($short.Length -gt 300){$short=$short.Substring(0,300)+'...'}; Write-Host ("      resp: {0}" -f $short) -ForegroundColor Gray }

  if ($res.ok) {
    $escribe = $true
    Write-Host "  [ESCRIBE] CREATE autenticado funciono -> la base ESCRIBE, NO es readonly." -ForegroundColor Green
    if ($res.id) { try { Invoke-RestMethod -Uri "$PB_URL/api/collections/lugares/records/$($res.id)" -Method Delete -Headers $headers -TimeoutSec 6 | Out-Null; Write-Host "  [OK] Rollback: registro de prueba borrado." -ForegroundColor Gray } catch {} }
  }
  elseif ($token -and $res.dataCount -gt 0) {
    $escribe = 'validacion'
    Write-Host "  [VALIDACION] Fallo por campos requeridos ($($res.dataCount) campos), NO por readonly." -ForegroundColor Yellow
    Write-Host "      (La base SI escribiria; solo falto un campo en el payload de prueba.)" -ForegroundColor DarkYellow
  }
  else {
    # data vacio o mensaje readonly/locked -> readonly a nivel DB
    $escribe = $false
    $msgTxt = "$($res.msg) $($res.raw)"
    if ($msgTxt -match 'readonly|locked') {
      Write-Host "  [READONLY] Mensaje del server menciona readonly/locked -> READONLY confirmado." -ForegroundColor Red
    } else {
      Write-Host "  [READONLY] CREATE de admin fallo con data vacia -> fallo a nivel base = READONLY." -ForegroundColor Red
    }
  }
} catch {
  Write-Host ("  [SIN SALUD] /api/health no responde: {0}" -f $_.Exception.Message) -ForegroundColor Red
}

# ============================================================
# [9] VEREDICTO
# ============================================================
Sub "[9] VEREDICTO AUTOMATICO"
if ($pbCount -gt 1 -or $cmdLoops.Count -gt 1) {
  Write-Host "  >>> CAUSA (A): DOBLE INSTANCIA." -ForegroundColor Red
  Write-Host ("      pocketbase.exe={0}  loops run_pocketbase={1}" -f $pbCount, $cmdLoops.Count) -ForegroundColor Red
  Write-Host "      Hay mas de un lanzador arrancando PocketBase en paralelo." -ForegroundColor Red
  Write-Host "      FIX correcto: dueno unico con mutex (run_pocketbase) + watchdog sin spawn." -ForegroundColor Yellow
} elseif ($escribe -eq $false -or $readonlyEnLog) {
  Write-Host "  >>> CAUSA (B): READONLY CON INSTANCIA UNICA." -ForegroundColor Red
  Write-Host ("      pocketbase.exe={0}. Write autenticado: {1}. readonly en log: {2}." -f $pbCount, $escribe, $readonlyEnLog) -ForegroundColor Red
  Write-Host "      Hay 1 solo PB pero abrio la base en solo-lectura (WAL/SHM colgado del apagado)." -ForegroundColor Red
  Write-Host "      FIX correcto: el dueno unico debe SANEAR la base (checkpoint/limpiar WAL y" -ForegroundColor Yellow
  Write-Host "      verificar escritura real) ANTES de servir, y reintentar si sigue readonly." -ForegroundColor Yellow
} elseif ($escribe -eq 'validacion') {
  Write-Host "  >>> LA BASE ESCRIBE (el fallo del test fue por payload, no readonly)." -ForegroundColor Green
  Write-Host "      No es readonly. Si la app falla, el problema esta en OTRO lado (revisar)." -ForegroundColor Yellow
} elseif ($escribe -eq $true) {
  Write-Host "  >>> EN ESTE MOMENTO EL SISTEMA ESCRIBE BIEN (sano)." -ForegroundColor Green
  Write-Host "      Si el fallo ya paso, correr este diag JUSTO cuando falle." -ForegroundColor Yellow
} else {
  Write-Host "  >>> INDETERMINADO (sin salud o sin PB). Revisar secciones [1] y [7]." -ForegroundColor Yellow
}

Write-Host ""
Line
Write-Host ("  Log guardado en: {0}" -f $logPath) -ForegroundColor Green
Write-Host "  Traelo a la laptop de desarrollo (o mandale foto de la pantalla)." -ForegroundColor Green
Line

if ($transcriptOn) { try { Stop-Transcript | Out-Null } catch {} }

Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
