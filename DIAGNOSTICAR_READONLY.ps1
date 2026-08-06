# ============================================================
# Sistema de Gestion de Llaves FCEA
# DIAGNOSTICAR_READONLY.ps1  -  SOLO LECTURA (no modifica nada)
# ============================================================
# Captura la evidencia decisiva del "attempt to write a readonly
# database (8)" para hallar la causa REAL (permisos NTFS, cuenta que
# corre PocketBase, instancias/loops duplicados y el error exacto de
# SQLite en el log viejo). Deja un TXT al lado de este script (pendrive)
# para traerlo a la laptop de desarrollo.
# ============================================================
#Requires -Version 5.1
$ErrorActionPreference = "Continue"

$repoRoot = "C:\sistema-llaves-fcea"
if (-not (Test-Path $repoRoot)) {
  foreach ($d in (Get-ChildItem "C:\" -Directory -ErrorAction SilentlyContinue)) {
    if (Test-Path (Join-Path $d.FullName "pocketbase\pocketbase.exe")) { $repoRoot = $d.FullName; break }
  }
}
$pbData = "C:\ProgramData\FCEA-Sistema-Llaves\pb_data"
$dataDb = Join-Path $pbData "data.db"
$out    = Join-Path $PSScriptRoot ("_RESULTADO_DIAG_READONLY_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

function W($m) { $m | Tee-Object -FilePath $out -Append | Out-Null; Write-Host $m }

W "==================================================================="
W " DIAGNOSTICO READONLY (solo lectura)  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W " Repo: $repoRoot"
W " pb_data: $pbData"
W "==================================================================="

W ""
W "----- 1) Usuario actual (quien ejecuta este diagnostico) -----"
W (whoami /user 2>&1 | Out-String)

W "----- 2) Procesos pocketbase.exe y su CUENTA (clave) -----"
try {
  $procs = Get-CimInstance Win32_Process -Filter "Name='pocketbase.exe'" -ErrorAction Stop
  if (-not $procs) { W "  (no hay pocketbase.exe corriendo en este instante)" }
  foreach ($p in $procs) {
    $ownerInfo = Invoke-CimMethod -InputObject $p -MethodName GetOwner -ErrorAction SilentlyContinue
    $owner = if ($ownerInfo) { "$($ownerInfo.Domain)\$($ownerInfo.User)" } else { "?" }
    W ("  PID {0}  Cuenta: {1}" -f $p.ProcessId, $owner)
    W ("     CmdLine: {0}" -f $p.CommandLine)
  }
} catch { W "  ERROR leyendo procesos: $($_.Exception.Message)" }

W ""
W "----- 3) Cuantos loops run_pocketbase.bat / cmd relanzadores -----"
try {
  $cmds = Get-CimInstance Win32_Process -Filter "Name='cmd.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'run_pocketbase' }
  W ("  Loops run_pocketbase activos: {0}" -f (@($cmds).Count))
  foreach ($c in $cmds) { W ("     PID {0}: {1}" -f $c.ProcessId, $c.CommandLine) }
} catch { W "  ERROR: $($_.Exception.Message)" }

W ""
W "----- 4) Tareas programadas FCEA (autostart / watchdog) -----"
W (cmd /c "schtasks /Query /FO LIST /V 2>nul | findstr /I \"FCEA PocketBase Watchdog TaskName\"" | Out-String)

W ""
W "----- 5) Atributos y PERMISOS NTFS de pb_data -----"
W (cmd /c "attrib `"$pbData`" 2>nul" | Out-String)
W (cmd /c "icacls `"$pbData`" 2>nul" | Out-String)
W "----- 5b) Permisos de data.db -----"
if (Test-Path $dataDb) {
  W (cmd /c "attrib `"$dataDb`" 2>nul" | Out-String)
  W (cmd /c "icacls `"$dataDb`" 2>nul" | Out-String)
  try {
    $fi = Get-Item $dataDb
    W ("  Tamano data.db: {0:N0} bytes   Ultima mod: {1}" -f $fi.Length, $fi.LastWriteTime)
  } catch {}
} else { W "  (no existe data.db)" }

W ""
W "----- 6) Archivos -wal / -shm / -journal presentes ahora -----"
foreach ($ext in @("-wal","-shm","-journal")) {
  $f = "$dataDb$ext"
  if (Test-Path $f) { W ("  {0}  ->  {1:N0} bytes" -f (Split-Path $f -Leaf), (Get-Item $f).Length) }
  else { W ("  {0}  ->  (ausente)" -f (Split-Path $f -Leaf)) }
}

W ""
W "----- 7) Prueba de escritura al DIRECTORIO como ESTE usuario -----"
$probe = Join-Path $pbData ("__diag_{0}.tmp" -f (Get-Date -Format 'HHmmssfff'))
try {
  Set-Content -Path $probe -Value 'x' -ErrorAction Stop
  Remove-Item $probe -Force -ErrorAction SilentlyContinue
  W "  Directorio pb_data: ESCRIBIBLE por este usuario."
} catch { W "  Directorio pb_data: NO escribible por este usuario -> $($_.Exception.Message)" }

W ""
W "----- 8) ERROR REAL de SQLite (ultimas lineas con 'readonly') -----"
$logs = @((Join-Path $repoRoot "logs\pocketbase.log.1"), (Join-Path $repoRoot "logs\pocketbase.log"))
foreach ($lg in $logs) {
  if (Test-Path $lg) {
    W ("  >>> {0} (size {1:N1} MB)" -f $lg, ((Get-Item $lg).Length/1MB))
    try {
      $hits = Select-String -Path $lg -Pattern "readonly|read-only|SQLITE|permission|unable to open|disk I/O" -ErrorAction SilentlyContinue |
              Select-Object -Last 25
      if ($hits) { foreach ($h in $hits) { W ("     " + $h.Line) } }
      else { W "     (sin coincidencias de readonly en este log)" }
    } catch { W "     ERROR leyendo log: $($_.Exception.Message)" }
  }
}

W ""
W "----- 9) Prueba de ESCRITURA REAL contra la API (POST y lee body) -----"
try {
  $body = '{"__diag":"x"}'
  try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8090/api/collections/llaves/records" -Method Post -Body $body -ContentType "application/json" -UseBasicParsing -TimeoutSec 6
    W ("  HTTP {0}: {1}" -f $r.StatusCode, $r.Content)
  } catch {
    $resp = $_.Exception.Response
    if ($resp) {
      $code = [int]$resp.StatusCode
      $txt = ""
      try { $sr = New-Object System.IO.StreamReader($resp.GetResponseStream()); $txt = $sr.ReadToEnd() } catch {}
      W ("  HTTP {0}: {1}" -f $code, $txt)
    } else { W "  Sin respuesta HTTP: $($_.Exception.Message)" }
  }
} catch { W "  ERROR probe API: $($_.Exception.Message)" }

W ""
W "==================================================================="
W " FIN. Resultado guardado en:"
W "   $out"
W " Traer el pendrive a la laptop y pegar/leer ese archivo."
W "==================================================================="
Write-Host ""
Write-Host "Presione una tecla para cerrar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
