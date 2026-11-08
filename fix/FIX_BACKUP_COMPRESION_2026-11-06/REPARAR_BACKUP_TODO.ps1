# ============================================================
# REPARAR BACKUP - TODO EN UNO  (FCEA)  v2  2026-11-07
# ============================================================
# Hace TODO de corrido, en el MONITOR, con permisos de admin:
#   1) Comprime la carpeta cruda MAS RECIENTE de backups\ a .zip
#      (respaldo valido) y BORRA las demas carpetas crudas -> libera disco.
#   2) Instala el backup_automatico.ps1 corregido (backup del viejo).
#   3) Corre un backup real AHORA y verifica que deja un .zip.
#   4) Escribe un log al pendrive (_RESULTADOS).
#
# NO toca la base productiva (pb_data). Solo la carpeta backups\ (que son
# copias) y el script de backup.
# ============================================================
param(
  [string]$Install = 'C:\sistema-llaves-fcea',
  [string]$LogDir,
  [switch]$NoPause,          # no esperar ENTER al final (uso en pruebas)
  [switch]$SkipLogsPurge     # saltar partes 2 y 3 (PocketBase) - para pruebas
)
$ErrorActionPreference = 'Continue'

# --- log al pendrive (_RESULTADOS) o, si no, junto al script ---
if (-not $LogDir) {
  $pen = Split-Path (Split-Path $PSScriptRoot)   # sube de FIX\PAQUETE\ a la raiz del pendrive
  $cand = Join-Path $pen '_RESULTADOS'
  if (Test-Path $cand) { $LogDir = $cand } else { $LogDir = $PSScriptRoot }
}
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$LOG = Join-Path $LogDir ("LOG_REPARAR_BACKUP_" + $env:COMPUTERNAME + "_" + $stamp + ".log")
function L { param([string]$m) $line = $m; $line | Tee-Object -FilePath $LOG -Append }

L ("================================================")
L ("REPARAR BACKUP - TODO EN UNO   " + (Get-Date))
L ("PC: " + $env:COMPUTERNAME + "   Install: " + $Install)
L ("================================================")

$backupsDir = Join-Path $Install 'backups'
if (-not (Test-Path $backupsDir)) {
  L ("[ERROR] No existe " + $backupsDir + ". Abortando.")
  L ("Log: " + $LOG); return
}

# --- estado inicial del disco ---
$dC = Get-PSDrive -Name C
L ("Disco C: libre ANTES = " + [math]::Round($dC.Free/1GB,2) + " GB")

# ============================================================
# 1) Comprimir la carpeta cruda MAS RECIENTE y borrar las demas
# ============================================================
L ""
L ("--- 1) Limpieza de carpetas crudas en backups\ ---")
Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
$crudas = Get-ChildItem $backupsDir -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if (-not $crudas) {
  L ("  No hay carpetas crudas. Nada que limpiar.")
} else {
  L ("  Carpetas crudas encontradas: " + $crudas.Count)
  $masReciente = $crudas[0]
  $zip = $masReciente.FullName + ".zip"
  L ("  Mas reciente (se conserva como .zip): " + $masReciente.Name)
  $zipOk = $false
  try {
    if (Test-Path $zip) { Remove-Item -Force $zip -ErrorAction SilentlyContinue }
    [System.IO.Compression.ZipFile]::CreateFromDirectory($masReciente.FullName, $zip, [System.IO.Compression.CompressionLevel]::Optimal, $false)
    if ((Test-Path $zip) -and ((Get-Item $zip).Length -gt 0)) { $zipOk = $true }
  } catch { L ("  [WARN] ZipFile fallo en la mas reciente: " + $_) }
  if (-not $zipOk) {
    try { & tar.exe -a -c -f $zip -C $masReciente.FullName "." 2>$null; if ($LASTEXITCODE -eq 0) { $zipOk = $true } } catch {}
  }
  if ($zipOk) {
    $mb = [math]::Round((Get-Item $zip).Length/1MB,2)
    L ("  [OK] .zip creado: " + (Split-Path $zip -Leaf) + " (" + $mb + " MB)")
    Remove-Item -Recurse -Force $masReciente.FullName -ErrorAction SilentlyContinue
    L ("  [OK] carpeta cruda mas reciente borrada (ya esta en el .zip)")
  } else {
    L ("  [ALERTA] no se pudo comprimir la mas reciente; se CONSERVA la carpeta cruda y NO se borra.")
  }
  # borrar TODAS las demas carpetas crudas
  $resto = $crudas | Select-Object -Skip 1
  $n = 0
  foreach ($c in $resto) {
    Remove-Item -Recurse -Force $c.FullName -ErrorAction SilentlyContinue
    $n++
  }
  L ("  [OK] carpetas crudas viejas borradas: " + $n)
}

$dC2 = Get-PSDrive -Name C

# ============================================================
# 2) y 3) PocketBase (retencion de logs + purga). Se pueden saltar con -SkipLogsPurge.
# ============================================================
if ($SkipLogsPurge) {
  L ""
  L ("--- 2+3) OMITIDAS por -SkipLogsPurge (no se toca PocketBase) ---")
}
if (-not $SkipLogsPurge) {
# --- health check RAPIDO con TcpClient (respeta timeout de verdad; Invoke-RestMethod
#     a un puerto cerrado puede colgarse). Si PB no responde en 3s, saltamos 2 y 3. ---
$pbVivo = $false
try {
  $tcp = New-Object System.Net.Sockets.TcpClient
  $iar = $tcp.BeginConnect('127.0.0.1', 8090, $null, $null)
  if ($iar.AsyncWaitHandle.WaitOne(3000, $false) -and $tcp.Connected) { $pbVivo = $true }
  $tcp.Close()
} catch {}

if (-not $pbVivo) {
  L ""
  L ("--- 2+3) PocketBase NO responde en 127.0.0.1:8090 -> se OMITEN retencion y purga de logs.")
  L ("         (El backup liviano igual se instala. Reintentar las partes de logs cuando PB este arriba.)")
}
if ($pbVivo) {
# ============================================================
# 2) Frenar el crecimiento de logs de PocketBase (maxDays=7) via API
# ============================================================
L ""
L ("--- 2) Configurar retencion de logs en PocketBase (maxDays=7) ---")
$BaseUrl  = 'http://127.0.0.1:8090'
$Identity = 'vigilancia@llaves.local'
$Password = 'vigilanciamvp2026'
$token = $null
try {
  $authBody = @{ identity = $Identity; password = $Password } | ConvertTo-Json
  foreach ($u in @("$BaseUrl/api/collections/_superusers/auth-with-password","$BaseUrl/api/admins/auth-with-password")) {
    try { $r = Invoke-RestMethod -Uri $u -Method Post -Body $authBody -ContentType 'application/json' -TimeoutSec 15; if ($r.token) { $token = $r.token; break } } catch {}
  }
} catch {}
if ($token) {
  try {
    $hdr = @{ Authorization = $token }
    $body = '{"logs":{"maxDays":7}}'
    Invoke-RestMethod -Uri "$BaseUrl/api/settings" -Method Patch -Headers $hdr -Body $body -ContentType 'application/json' -TimeoutSec 20 | Out-Null
    L ("  [OK] logs.maxDays = 7 (PocketBase borrara logs mas viejos que 7 dias)")
  } catch {
    L ("  [WARN] no se pudo setear maxDays via API: " + $_)
  }
} else {
  L ("  [WARN] no se pudo autenticar en PocketBase; se omite maxDays (reintentar luego)")
}

# ============================================================
# 3) Purgar el logs.db actual (metodo A): detener PB, borrar logs.db*, reiniciar
# ============================================================
L ""
L ("--- 3) Purgar logs.db actual (libera GBs) ---")
# localizar pb_data real (igual que backup_automatico.ps1)
$pbData = $null
foreach ($c in @((Join-Path $Install "pocketbase\pb_data"), "C:\ProgramData\FCEA-Sistema-Llaves\pb_data")) {
  if (Test-Path (Join-Path $c "data.db")) { $pbData = $c; break }
}
if (-not $pbData) {
  L ("  [WARN] no encontre pb_data; se omite la purga de logs.")
} else {
  $logsDb = Join-Path $pbData 'logs.db'
  $tamLogs = if (Test-Path $logsDb) { [math]::Round((Get-Item $logsDb).Length/1MB,2) } else { 0 }
  L ("  pb_data: " + $pbData + "   logs.db actual = " + $tamLogs + " MB")
  $startBat = Join-Path $Install 'pocketbase\start-server.bat'
  try {
    L ("  Deteniendo PocketBase...")
    Get-Process pocketbase -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    foreach ($f in @('logs.db','logs.db-wal','logs.db-shm')) {
      $fp = Join-Path $pbData $f
      if (Test-Path $fp) { Remove-Item -Force $fp -ErrorAction SilentlyContinue; L ("    borrado: " + $f) }
    }
    # tambien backups internos viejos de logs que inflan
    foreach ($d in (Get-ChildItem $pbData -Directory -Filter '_backup_logsdb*' -ErrorAction SilentlyContinue)) {
      Remove-Item -Recurse -Force $d.FullName -ErrorAction SilentlyContinue; L ("    borrado dir: " + $d.Name)
    }
    L ("  Reiniciando PocketBase...")
    if (Test-Path $startBat) {
      Start-Process -FilePath $startBat -WorkingDirectory (Split-Path $startBat) -WindowStyle Minimized
    } else {
      L ("    [WARN] no encontre start-server.bat; el watchdog deberia relanzarlo solo en ~30 seg.")
    }
    # esperar a que PB vuelva a responder
    $vivo = $false
    for ($i=0; $i -lt 20; $i++) {
      Start-Sleep -Seconds 2
      try { $h = Invoke-RestMethod -Uri "$BaseUrl/api/health" -TimeoutSec 4 -Method Get; if ($h.code -eq 200) { $vivo = $true; break } } catch {}
    }
    if ($vivo) { L ("  [OK] PocketBase volvio a responder. logs.db regenerado vacio.") }
    else { L ("  [ALERTA] PocketBase no respondio aun. El watchdog lo relanza en ~30 seg; verificar el sistema.") }
  } catch {
    L ("  [ERROR] en la purga de logs: " + $_)
  }
}


} # fin de if ($pbVivo)
} # fin de if (-not $SkipLogsPurge)

# ============================================================
# 4) Instalar el backup_automatico.ps1 corregido (liviano)
# ============================================================
L ""
L ("--- 4) Instalar backup_automatico.ps1 corregido (liviano) ---")
$destScript = Join-Path $Install 'scripts\maintenance\backup_automatico.ps1'
$nuevo = Join-Path $PSScriptRoot 'backup_automatico.ps1'
if (-not (Test-Path $nuevo)) {
  L ("  [ERROR] No esta el backup_automatico.ps1 corregido en el paquete.")
} elseif (-not (Test-Path (Split-Path $destScript))) {
  L ("  [ERROR] No existe " + (Split-Path $destScript))
} else {
  if (Test-Path $destScript) {
    $bk = "$destScript.backup_$stamp"
    Copy-Item $destScript $bk -Force
    L ("  [OK] backup del script actual -> " + (Split-Path $bk -Leaf))
  }
  Copy-Item $nuevo $destScript -Force
  if (Select-String -Path $destScript -Pattern 'CreateFromDirectory' -Quiet) {
    L ("  [VERIFICADO] script instalado usa ZipFile::CreateFromDirectory (fix presente)")
  } else {
    L ("  [ALERTA] no se detecto la firma del fix en el script instalado")
  }
}

# ============================================================
# 3) Correr un backup real AHORA y verificar que deja un .zip
# ============================================================
L ""
L ("--- 5) Backup real inmediato (liviano) ---")
$zipsAntes = (Get-ChildItem $backupsDir -Filter '*.zip' -File -ErrorAction SilentlyContinue).Count
try {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $destScript 2>&1 | ForEach-Object { L ("  [backup] " + $_) }
} catch {
  L ("  [ERROR] al correr el backup: " + $_)
}
$zipsDespues = Get-ChildItem $backupsDir -Filter '*.zip' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
L ("  .zip en backups\ ANTES = " + $zipsAntes + "   DESPUES = " + $zipsDespues.Count)
$hoy = Get-Date -Format 'yyyy-MM-dd'
$zipHoy = $zipsDespues | Where-Object { $_.Name -like ($hoy + '*') } | Select-Object -First 1
if ($zipHoy) {
  L ("  [OK] Backup de HOY generado: " + $zipHoy.Name + " (" + [math]::Round($zipHoy.Length/1MB,2) + " MB)")
} else {
  L ("  [ALERTA] NO aparecio un .zip de hoy. Revisar el detalle [backup] de arriba.")
}
$crudasFin = (Get-ChildItem $backupsDir -Directory -ErrorAction SilentlyContinue).Count
L ("  carpetas crudas restantes en backups\ = " + $crudasFin + " (deberia ser 0)")

# ============================================================
# Resumen final
# ============================================================
$dC3 = Get-PSDrive -Name C
L ""
L ("================================================")
L ("RESUMEN FINAL")
L ("  Disco C: libre final = " + [math]::Round($dC3.Free/1GB,2) + " GB (" + [math]::Round(($dC3.Free/($dC3.Used+$dC3.Free))*100,1) + "% libre)")
L ("  .zip de backup presentes = " + $zipsDespues.Count)
L ("  carpetas crudas = " + $crudasFin)
L ("================================================")
L ("Log: " + $LOG)
Write-Host ""
Write-Host ("LISTO. Traele este log a la laptop: " + $LOG) -ForegroundColor Green
if (-not $NoPause) {
  Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
  [void][System.Console]::ReadLine()
}

L ("  Disco C: libre DESPUES de limpiar = " + [math]::Round($dC2.Free/1GB,2) + " GB")
