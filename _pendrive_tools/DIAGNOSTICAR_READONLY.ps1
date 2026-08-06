# ============================================================
# Sistema de Gestion de Llaves FCEA
# DIAGNOSTICAR_READONLY.ps1  -  SOLO LECTURA / prueba inocua
# ============================================================
# Objetivo DECISIVO: distinguir si el "attempt to write a readonly
# database (8)" afecta a la base PRINCIPAL (data.db -> rompe la app)
# o solo a la base interna de LOGS de PocketBase (no rompe la app).
#
# Hace:
#  - Enumera TODAS las bases dentro de pb_data (data.db, logs.db,
#    auxiliary.db y sus -wal/-shm) con tamanos.
#  - Muestra la cuenta que corre pocketbase.exe y los permisos NTFS.
#  - Prueba de escritura AUTENTICADA e IDEMPOTENTE contra data.db:
#    PATCH /api/settings con {} (no cambia nada). 200 => data.db
#    ESCRIBIBLE ; 500 readonly => data.db READONLY.
# Deja un TXT al lado de este script (pendrive).
# ============================================================
#Requires -Version 5.1
$ErrorActionPreference = "Continue"

$repoRoot = "C:\sistema-llaves-fcea"
if (-not (Test-Path $repoRoot)) {
  foreach ($d in (Get-ChildItem "C:\" -Directory -ErrorAction SilentlyContinue)) {
    if (Test-Path (Join-Path $d.FullName "pocketbase\pocketbase.exe")) { $repoRoot = $d.FullName; break }
  }
}
$pbData  = "C:\ProgramData\FCEA-Sistema-Llaves\pb_data"
$dataDb  = Join-Path $pbData "data.db"
$BaseUrl = "http://127.0.0.1:8090"
$AdminEmail = "vigilancia@llaves.local"
$AdminPass  = "vigilanciamvd2026"
$out = Join-Path $PSScriptRoot ("_RESULTADO_DIAG_READONLY_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

function W($m) { $m | Tee-Object -FilePath $out -Append | Out-Null; Write-Host $m }

W "==================================================================="
W " DIAGNOSTICO READONLY DECISIVO  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W " Repo: $repoRoot | pb_data: $pbData"
W "==================================================================="

W ""
W "----- 1) Usuario actual + cuenta de pocketbase.exe -----"
W ("  Usuario diagnostico: " + (whoami))
try {
  $procs = Get-CimInstance Win32_Process -Filter "Name='pocketbase.exe'" -ErrorAction Stop
  W ("  Instancias pocketbase.exe: " + (@($procs).Count))
  foreach ($p in $procs) {
    $o = Invoke-CimMethod -InputObject $p -MethodName GetOwner -ErrorAction SilentlyContinue
    $owner = if ($o) { "$($o.Domain)\$($o.User)" } else { "?" }
    W ("    PID {0}  Cuenta: {1}" -f $p.ProcessId, $owner)
    W ("       CMD: {0}" -f $p.CommandLine)
  }
} catch { W "  ERROR procesos: $($_.Exception.Message)" }

W ""
W "----- 2) Loops run_pocketbase.bat activos (deberia ser 0 o 1) -----"
try {
  $cmds = Get-CimInstance Win32_Process -Filter "Name='cmd.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'run_pocketbase' }
  W ("  Loops run_pocketbase: " + (@($cmds).Count))
  foreach ($c in $cmds) { W ("    PID {0}: {1}" -f $c.ProcessId, $c.CommandLine) }
} catch { W "  ERROR: $($_.Exception.Message)" }

W ""
W "----- 3) TODAS las bases dentro de pb_data (clave: cual esta stuck) -----"
if (Test-Path $pbData) {
  Get-ChildItem $pbData -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '\.db($|-wal$|-shm$|-journal$)' } |
    Sort-Object Name | ForEach-Object {
      W ("  {0,-24} {1,12:N0} bytes   ro={2}   mod={3}" -f $_.Name, $_.Length, ([bool]($_.Attributes -band [IO.FileAttributes]::ReadOnly)), $_.LastWriteTime)
    }
} else { W "  (no existe pb_data)" }

W ""
W "----- 4) Permisos NTFS de pb_data y data.db -----"
W (cmd /c "icacls `"$pbData`" 2>nul" | Out-String)
if (Test-Path $dataDb) { W (cmd /c "icacls `"$dataDb`" 2>nul" | Out-String) }

W ""
W "----- 5) Escritura al DIRECTORIO como este usuario -----"
$probe = Join-Path $pbData ("__diag_{0}.tmp" -f (Get-Date -Format 'HHmmssfff'))
try { Set-Content -Path $probe -Value 'x' -ErrorAction Stop; Remove-Item $probe -Force -EA SilentlyContinue; W "  Directorio pb_data: ESCRIBIBLE." }
catch { W "  Directorio pb_data: NO escribible -> $($_.Exception.Message)" }

W ""
W "----- 6) PRUEBA DE ESCRITURA AUTENTICADA a data.db (DECISIVA) -----"
$token = $null
foreach ($ep in @("/api/admins/auth-with-password","/api/collections/_superusers/auth-with-password")) {
  if ($token) { break }
  try {
    $b = @{ identity = $AdminEmail; password = $AdminPass } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$BaseUrl$ep" -Method Post -Body $b -ContentType "application/json" -TimeoutSec 8
    if ($r.token) { $token = $r.token; W "  Auth OK via $ep" }
  } catch { W "  Auth fallo via $ep : $($_.Exception.Message)" }
}
if (-not $token) {
  W "  [AVISO] No pude autenticar admin. Hago PATCH /api/settings SIN token (menos preciso)."
}
try {
  $headers = @{}
  if ($token) { $headers["Authorization"] = $token }
  $resp = Invoke-WebRequest -Uri "$BaseUrl/api/settings" -Method Patch -Body "{}" -ContentType "application/json" -Headers $headers -UseBasicParsing -TimeoutSec 10
  W ("  PATCH /api/settings -> HTTP {0}" -f $resp.StatusCode)
  W "  >>> VEREDICTO: data.db ESCRIBIBLE (la app deberia poder escribir)."
} catch {
  $r = $_.Exception.Response
  $code = if ($r) { [int]$r.StatusCode } else { 0 }
  $txt = ""
  if ($r) { try { $sr = New-Object IO.StreamReader($r.GetResponseStream()); $txt = $sr.ReadToEnd() } catch {} }
  W ("  PATCH /api/settings -> HTTP {0} : {1}" -f $code, $txt)
  if ($txt -match "readonly" -or $code -eq 500) {
    W "  >>> VEREDICTO: data.db READONLY (esta es la causa de que la app no escriba)."
  } elseif ($code -eq 401 -or $code -eq 403) {
    W "  >>> No concluyente (sin permiso). Necesito el token admin."
  } else {
    W "  >>> Revisar manualmente el codigo/cuerpo de arriba."
  }
}

W ""
W "----- 7) Ultimas lineas 'readonly' del log (que DB menciona) -----"
$logs = @((Join-Path $repoRoot "logs\pocketbase.log.1"), (Join-Path $repoRoot "logs\pocketbase.log"))
foreach ($lg in $logs) {
  if (Test-Path $lg) {
    W ("  >>> {0} ({1:N1} MB)" -f $lg, ((Get-Item $lg).Length/1MB))
    try {
      Select-String -Path $lg -Pattern "readonly|read-only" -EA SilentlyContinue | Select-Object -Last 8 |
        ForEach-Object { W ("     " + ($_.Line.Substring(0, [Math]::Min(200,$_.Line.Length)))) }
    } catch { W "     ERROR: $($_.Exception.Message)" }
  }
}

W ""
W "==================================================================="
W " FIN. Resultado en: $out"
W " Traer el pendrive a la laptop de desarrollo."
W "==================================================================="
Write-Host ""
Write-Host "Presione una tecla para cerrar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
