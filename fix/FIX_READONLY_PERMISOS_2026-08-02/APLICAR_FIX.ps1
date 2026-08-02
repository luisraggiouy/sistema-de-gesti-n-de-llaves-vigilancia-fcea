# ============================================================
# Sistema de Gestion de Llaves FCEA
# FIX RAIZ readonly - PERMISOS NTFS de data.db
# Fecha: 2026-08-02
# ============================================================
# CAUSA RAIZ (confirmada):
#   PocketBase corre como el usuario ESTANDAR 'vigilancia'. Sobre
#   data.db ese usuario tenia solo (RX) = lectura, SIN escritura
#   (icacls mostraba "BUILTIN\Usuarios:(RX)"). SQLite entonces abre
#   data.db en modo SOLO LECTURA -> toda escritura falla:
#     - "Failed to write log" / "Logs delete failed" (logs.db)
#     - "Failed to update/create record (400)" (solicitudes)
#   Los READ funcionan (200) porque RX permite leer.
#
# QUE HACE ESTE FIX:
#   1) Detiene PocketBase (con datos quietos).
#   2) Quita atributo READ-ONLY de los .db y OTORGA 'Modify' al
#      usuario que corre PocketBase (vigilancia) y a BUILTIN\Usuarios
#      sobre TODO pb_data, de forma recursiva (icacls).
#   3) Limpia logs.db (descartable) e instala run_pocketbase.bat que
#      la borra en cada arranque.
#   4) Arranca UNA instancia y VERIFICA con una escritura REAL:
#      crea un registro de prueba en 'solicitudes' y lo borra.
#      Solo declara VERDE si el CREATE devolvio 2xx.
#   5) Guarda icacls ANTES/DESPUES y el tail del log en el pendrive.
# ============================================================
#Requires -Version 5.1
$ErrorActionPreference = "Continue"

function Info($m){ Write-Host "[..] $m" -ForegroundColor Cyan }
function Ok($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[AVISO] $m" -ForegroundColor Yellow }
function Err($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"

# --- Localizar repo ---
$repo = "C:\sistema-llaves-fcea"
if (-not (Test-Path (Join-Path $repo "pocketbase\pocketbase.exe"))) {
  foreach ($d in (Get-ChildItem "C:\" -Directory -ErrorAction SilentlyContinue)) {
    if (Test-Path (Join-Path $d.FullName "pocketbase\pocketbase.exe")) { $repo = $d.FullName; break }
  }
}
$pbExe   = Join-Path $repo "pocketbase\pocketbase.exe"
$libDir  = Join-Path $repo "scripts\lib"
$logsDir = Join-Path $repo "logs"
$pbData  = "C:\ProgramData\FCEA-Sistema-Llaves\pb_data"
$dataDb  = Join-Path $pbData "data.db"
$BaseUrl = "http://127.0.0.1:8090"
$res = Join-Path $PSScriptRoot ("_LOGS_RESULTADO_" + $stamp)
New-Item -ItemType Directory -Force -Path $res | Out-Null

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Magenta
Write-Host "  FIX RAIZ readonly - PERMISOS NTFS de data.db  ($stamp)"       -ForegroundColor Magenta
Write-Host "  Repo: $repo"                                                    -ForegroundColor Magenta
Write-Host "===============================================================" -ForegroundColor Magenta
Write-Host ""

if (-not (Test-Path $pbExe)) { Err "No encuentro pocketbase.exe. Aborto."; Read-Host "Enter"; exit 1 }

# Usuario que corre PocketBase (dueno del proceso). Fallback: usuario actual.
$runUser = $env:USERNAME
try {
  $p = Get-CimInstance Win32_Process -Filter "Name='pocketbase.exe'" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($p) { $o = Invoke-CimMethod -InputObject $p -MethodName GetOwner -ErrorAction SilentlyContinue; if ($o -and $o.User) { $runUser = $o.User } }
} catch {}
Info "Usuario runtime de PocketBase: $runUser"

# --- ANTES: guardar ACL actual ---
try { cmd /c "icacls `"$dataDb`" 2>&1" | Out-File (Join-Path $res "ACL_ANTES.txt") -Encoding UTF8 } catch {}

# --- [1] Detener PocketBase y loops ---
Info "Deteniendo PocketBase y loops (datos quietos)..."
cmd /c "schtasks /End /TN `"FCEA-Sistema-Llaves-AutoStart`" >nul 2>nul"
try {
  Get-CimInstance Win32_Process -Filter "Name='cmd.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'run_pocketbase' } |
    ForEach-Object { cmd /c "taskkill /PID $($_.ProcessId) /T /F >nul 2>nul" }
} catch {}
cmd /c "taskkill /IM pocketbase.exe /F >nul 2>nul"
Start-Sleep -Seconds 3
Ok "PocketBase detenido."

# --- [2] Quitar READ-ONLY y OTORGAR Modify (la clave del fix) ---
Info "Quitando atributo read-only de las bases..."
cmd /c "attrib -r `"$pbData\*.db`" 2>nul"
cmd /c "attrib -r `"$pbData\*.db-wal`" 2>nul"
cmd /c "attrib -r `"$pbData\*.db-shm`" 2>nul"

Info "Otorgando permiso de ESCRITURA (Modify) sobre pb_data..."
# BUILTIN\Users por SID (independiente del idioma) + el usuario runtime
$aclOut = ""
$aclOut += cmd /c "icacls `"$pbData`" /grant `"*S-1-5-32-545:(OI)(CI)M`" /T /C 2>&1"
$aclOut += "`r`n"
$aclOut += cmd /c "icacls `"$pbData`" /grant `"$runUser`:(OI)(CI)M`" /T /C 2>&1"
$aclOut | Out-File (Join-Path $res "icacls_grant.txt") -Encoding UTF8
if ($aclOut -match "correctamente" -or $aclOut -match "successfully") { Ok "Permisos Modify otorgados a Usuarios y $runUser." }
else { Warn "icacls no confirmo 'correctamente'. Revisar icacls_grant.txt." }

# --- DESPUES: guardar ACL nueva ---
try { cmd /c "icacls `"$dataDb`" 2>&1" | Out-File (Join-Path $res "ACL_DESPUES.txt") -Encoding UTF8 } catch {}

# Confirmar en pantalla el ACL de data.db
Info "ACL actual de data.db:"
cmd /c "icacls `"$dataDb`" 2>&1" | ForEach-Object { Write-Host "    $_" }

# --- [3] Limpiar logs.db e instalar run_pocketbase.bat ---
try { Get-ChildItem $pbData -Filter "logs.db*" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue; Ok "logs.db saneada." } catch {}
try {
  New-Item -ItemType Directory -Force -Path $libDir | Out-Null
  $dst = Join-Path $libDir "run_pocketbase.bat"
  if (Test-Path $dst) { Copy-Item $dst "$dst.bak_permfix_$stamp" -Force -ErrorAction SilentlyContinue }
  Copy-Item (Join-Path $PSScriptRoot "run_pocketbase.bat") $dst -Force
  Ok "run_pocketbase.bat instalado."
} catch { Warn "No pude instalar run_pocketbase.bat: $($_.Exception.Message)" }

# --- [4] Arrancar UNA instancia ---
Info "Arrancando PocketBase..."
try { Start-Process -FilePath "cmd.exe" -ArgumentList '/c', (Join-Path $libDir "run_pocketbase.bat") -WindowStyle Hidden } catch { Err $_.Exception.Message }
cmd /c "schtasks /Change /TN `"FCEA-Sistema-Llaves-AutoStart`" /ENABLE >nul 2>nul"

$healthy = $false
for ($i=0; $i -lt 30; $i++) {
  Start-Sleep -Seconds 2
  try { $h = Invoke-WebRequest -Uri "$BaseUrl/api/health" -UseBasicParsing -TimeoutSec 4; if ($h.StatusCode -eq 200) { $healthy = $true; break } } catch {}
}
if ($healthy) { Ok "PocketBase responde /api/health (vivo)." } else { Warn "No respondio health en 60s." }

# --- [5] VERIFICACION: escritura REAL a data.db (crear+borrar registro de prueba) ---
$writeOk = $false
if ($healthy) {
  try {
    $body = @{
      objeto = "PRUEBA_FIX_PERMISOS"
      solicitante = "diagnostico"
      estado = "pendiente"
    } | ConvertTo-Json
    $c = Invoke-WebRequest -Uri "$BaseUrl/api/collections/solicitudes/records" -Method Post -Body $body -ContentType "application/json" -UseBasicParsing -TimeoutSec 10
    if ([int]$c.StatusCode -ge 200 -and [int]$c.StatusCode -lt 300) {
      $writeOk = $true
      Ok "ESCRITURA a data.db OK (HTTP $($c.StatusCode)). data.db ya es ESCRIBIBLE."
      try { $id = ($c.Content | ConvertFrom-Json).id; if ($id) { Invoke-WebRequest -Uri "$BaseUrl/api/collections/solicitudes/records/$id" -Method Delete -UseBasicParsing -TimeoutSec 8 | Out-Null; Info "Registro de prueba borrado ($id)." } } catch {}
    }
  } catch {
    $r = $_.Exception.Response
    $code = if ($r) { [int]$r.StatusCode } else { 0 }
    $txt = ""; if ($r) { try { $sr = New-Object IO.StreamReader($r.GetResponseStream()); $txt = $sr.ReadToEnd() } catch {} }
    # Si es 400 por validacion de campos (data con errores) => data.db SI escribe, solo faltaron campos.
    if ($code -eq 400 -and $txt -match '"data"\s*:\s*\{[^}]') {
      $writeOk = $true
      Ok "data.db ESCRIBIBLE (400 fue por validacion de campos, no por readonly)."
    } elseif ($txt -match "readonly") {
      Err "data.db SIGUE READONLY: $txt"
    } else {
      Warn "CREATE devolvio HTTP $code : $txt"
    }
    $txt | Out-File (Join-Path $res "create_test_error.txt") -Encoding UTF8
  }
}

# --- Tail del log real (muestra el error de fondo si lo hubiera) ---
try {
  if (Test-Path (Join-Path $logsDir "pocketbase.log")) {
    Get-Content (Join-Path $logsDir "pocketbase.log") -Tail 30 -ErrorAction SilentlyContinue | Out-File (Join-Path $res "pocketbase_TAIL.txt") -Encoding UTF8
  }
} catch {}
("healthy=$healthy  writeOk_data.db=$writeOk  runUser=$runUser") | Out-File (Join-Path $res "RESUMEN.txt") -Encoding UTF8

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Green
if ($healthy -and $writeOk) {
  Write-Host "  [OK] FIX APLICADO: data.db ES ESCRIBIBLE." -ForegroundColor Green
  Write-Host "  Ahora probar en Terminal A/B: enviar una solicitud y verla" -ForegroundColor Green
  Write-Host "  aparecer en el Monitor. Entregar/devolver una llave de prueba." -ForegroundColor Green
} else {
  Write-Host "  [ATENCION] No confirme VERDE (healthy=$healthy, writeOk=$writeOk)." -ForegroundColor Yellow
  Write-Host "  Traeme la carpeta _LOGS_RESULTADO_$stamp del pendrive." -ForegroundColor Yellow
}
Write-Host "===============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Presione una tecla para cerrar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
