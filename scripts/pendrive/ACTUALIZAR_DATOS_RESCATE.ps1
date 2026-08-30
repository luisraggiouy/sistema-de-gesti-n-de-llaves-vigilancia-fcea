# ============================================================
#  ACTUALIZAR DATOS - Pendrive de RESCATE FCEA  (version SEGURA)
# ------------------------------------------------------------
#  Toma una FOTO consistente de TODOS los datos (llaves, objetos,
#  autorizaciones, usuarios, vigilantes, agenda, historial, etc.)
#  usando el BACKUP INTERNO de PocketBase por HTTP.
#
#  * NO detiene el servidor.
#  * NO corta el servicio (downtime = 0).
#  * NO modifica los datos de produccion (solo LEE un snapshot).
#
#  Deja el snapshot expandido en el pendrive, listo para recuperar:
#     <pendrive>\sistema-llaves-fcea\pocketbase\pb_data
#
#  Correr en el MONITOR VIGILANCIA (donde vive PocketBase).
#
#  Probado contra PocketBase 0.22.4:
#    - login superusuario: POST /api/admins/auth-with-password
#    - descarga de backup : requiere "file token" (/api/files/token)
# ============================================================

param(
  [string]$PendriveRoot = "",
  [string]$BaseUrl      = "http://127.0.0.1:8090",
  [string]$Identity     = "vigilancia@llaves.local",
  [string]$Password     = "vigilanciamvp2026",
  [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'   # evita el spam de barras de Invoke-WebRequest
function Ok($m)   { Write-Host $m -ForegroundColor Green }

function Info($m) { Write-Host $m -ForegroundColor Cyan }
function Warn($m) { Write-Host $m -ForegroundColor Yellow }
function Pausa    { if (-not $NoPause) { Read-Host "Presione ENTER para cerrar" | Out-Null } }
function DetenerLog { try { Stop-Transcript | Out-Null } catch { } }
function Die($m)  {
  Write-Host "" ; Write-Host "[ERROR] $m" -ForegroundColor Red ; Write-Host ""
  if ($script:logFile) { Write-Host ("Log guardado en: " + $script:logFile) -ForegroundColor Yellow }
  DetenerLog ; Pausa ; exit 1
}



# --- Resolver raiz del pendrive ---
if ([string]::IsNullOrWhiteSpace($PendriveRoot)) {
  $PendriveRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
}
# Sanea el valor recibido: el launcher .bat puede mandar 'D:\' y, por el
# escape de la comilla (\"), llegar como 'D:"'. Quitamos comillas y barra final.
$PendriveRoot = $PendriveRoot.Trim('"').TrimEnd('\')
if ([string]::IsNullOrWhiteSpace($PendriveRoot) -or $PendriveRoot -match '["<>|]') {
  $PendriveRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path.TrimEnd('\')
}

$target = Join-Path $PendriveRoot "sistema-llaves-fcea\pocketbase\pb_data"
$pocketDir = Split-Path $target -Parent
$selloPath = Join-Path $PendriveRoot 'ULTIMO_REFRESCO_DE_DATOS.txt'

# --- LOG al pendrive (regla: el output se guarda en el pendrive) ---
$script:logFile = $null
try {
  $logDir = Join-Path $PendriveRoot '_RESULTADOS'
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  $script:logFile = Join-Path $logDir ("LOG_ACTUALIZAR_" + $env:COMPUTERNAME + "_" + (Get-Date -Format 'yyyy-MM-dd_HHmm') + ".log")
  Start-Transcript -Path $script:logFile -Force | Out-Null
} catch { }

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  ACTUALIZAR DATOS (SEGURO) - Pendrive de RESCATE FCEA" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Info ("  PC       : " + $env:COMPUTERNAME + "   (" + (Get-Date -Format 'yyyy-MM-dd HH:mm') + ")")

Info "  Pendrive : $PendriveRoot"
Info "  Destino  : $target"
Info "  Servidor : $BaseUrl"
Write-Host ""

# --- Mostrar SIEMPRE el ultimo respaldo previo ---
Write-Host "  Ultimo respaldo guardado en este pendrive:" -ForegroundColor Magenta
if (Test-Path $selloPath) {
  Get-Content $selloPath | Where-Object { $_ -match 'Fecha/hora' -or $_ -match 'NUNCA' } | ForEach-Object { Write-Host ("    " + $_) -ForegroundColor Magenta }
} else {
  Write-Host "    (todavia no se corrio ACTUALIZAR DATOS en este pendrive)" -ForegroundColor Magenta
}
Write-Host ""


if (-not (Test-Path $pocketDir)) {
  Die "No se encontro $pocketDir. Este .ps1 debe correr desde el pendrive de RESCATE."
}

# --- 1) Health check ---
Info "[1/6] Verificando que PocketBase este vivo en el Monitor..."
try {
  $h = Invoke-RestMethod -Uri "$BaseUrl/api/health" -TimeoutSec 10 -Method Get
  Ok  "      PocketBase responde. (code=$($h.code))"
} catch {
  Die "PocketBase no responde en $BaseUrl.`n        Confirme que esta en el MONITOR VIGILANCIA y que el sistema esta prendido."
}

# --- 2) Autenticacion de superusuario (compatibilidad de versiones) ---
Info "[2/6] Autenticando (superusuario)..."
$authBody = @{ identity = $Identity; password = $Password } | ConvertTo-Json
$token = $null
$authUrls = @(
  "$BaseUrl/api/admins/auth-with-password",
  "$BaseUrl/api/collections/_superusers/auth-with-password"
)

foreach ($u in $authUrls) {
  try {
    $r = Invoke-RestMethod -Uri $u -Method Post -Body $authBody -ContentType 'application/json' -TimeoutSec 15
    if ($r.token) { $token = $r.token; break }
  } catch { }
}
if (-not $token) {
  Die "No se pudo autenticar. Revise usuario/contrasena del panel (doc 2 - CONTRASENAS)."
}
$headers = @{ Authorization = $token }
Ok "      Autenticado OK."

# --- 3) Crear backup interno (snapshot consistente, sin cortar servicio) ---
$stamp = Get-Date -Format 'yyyyMMdd_HHmm'
$bkName = "rescate_$stamp.zip"
Info "[3/6] Pidiendo backup interno: $bkName ..."
$bkBody = @{ name = $bkName } | ConvertTo-Json
try {
  Invoke-RestMethod -Uri "$BaseUrl/api/backups" -Method Post -Headers $headers -Body $bkBody -ContentType 'application/json' -TimeoutSec 120 | Out-Null
} catch {
  Die "El servidor no pudo crear el backup interno.`n        Detalle: $($_.Exception.Message)"
}

# Confirmar que el backup aparece en la lista (reintentos)
$exists = $false
for ($i=0; $i -lt 10; $i++) {
  Start-Sleep -Seconds 2
  try {
    $list = Invoke-RestMethod -Uri "$BaseUrl/api/backups" -Method Get -Headers $headers -TimeoutSec 30
    if ($list -and ($list | Where-Object { $_.key -eq $bkName })) { $exists = $true; break }
  } catch { }
}
if (-not $exists) { Die "El backup $bkName no aparecio en el servidor." }
Ok "      Backup creado en el servidor."

# --- 4) Descargar el backup al pendrive ---
#     En PocketBase 0.22 la descarga de un backup requiere un
#     "file token" (POST /api/files/token) pasado como ?token=...
$tempZip = Join-Path $env:TEMP $bkName
Info "[4/6] Descargando el backup al pendrive..."
$fileToken = $null
try {
  $ftResp = Invoke-RestMethod -Uri "$BaseUrl/api/files/token" -Method Post -Headers $headers -TimeoutSec 30
  $fileToken = $ftResp.token
} catch { }

$downloaded = $false
$dlUrls = @()
if ($fileToken) { $dlUrls += "$BaseUrl/api/backups/$bkName`?token=$fileToken" }
$dlUrls += "$BaseUrl/api/backups/$bkName"   # respaldo: intento con header solamente
foreach ($du in $dlUrls) {
  try {
    Invoke-WebRequest -Uri $du -Headers $headers -OutFile $tempZip -TimeoutSec 300
    if ((Test-Path $tempZip) -and (Get-Item $tempZip).Length -ge 1024) { $downloaded = $true; break }
  } catch { }
}
if (-not $downloaded) {
  Die "No se pudo descargar el backup (probado con file token y con header)."
}

if (-not (Test-Path $tempZip) -or (Get-Item $tempZip).Length -lt 1024) {
  Die "El archivo descargado esta vacio o es invalido."
}
$mb = [math]::Round((Get-Item $tempZip).Length/1MB,2)
Ok "      Descargado ($mb MB)."

# --- 5) Expandir el snapshot en el pb_data del pendrive ---
Info "[5/6] Expandiendo snapshot en el pendrive (reemplazo limpio)..."
try {
  if (Test-Path $target) { Remove-Item "$target\*" -Recurse -Force -ErrorAction SilentlyContinue }
  else { New-Item -ItemType Directory -Force -Path $target | Out-Null }
  Expand-Archive -Path $tempZip -DestinationPath $target -Force
} catch {
  Die "No se pudo expandir el backup en el pendrive.`n        Detalle: $($_.Exception.Message)"
}
if (-not (Test-Path (Join-Path $target 'data.db'))) {
  Die "El snapshot expandido no contiene data.db. Abortado."
}
Ok "      Snapshot listo en el pendrive."

# --- 6) Limpieza: borrar el backup temporal del servidor y del TEMP ---
Info "[6/6] Limpiando temporales..."
try { Invoke-RestMethod -Uri "$BaseUrl/api/backups/$bkName" -Method Delete -Headers $headers -TimeoutSec 60 | Out-Null } catch { Warn "      (No se pudo borrar el backup del servidor; no es grave.)" }
Remove-Item $tempZip -Force -ErrorAction SilentlyContinue

# --- Sello de fecha en el pendrive ---
$sello = @(
  "Ultimo refresco de datos reales al pendrive de RESCATE",
  "-----------------------------------------------------",
  ("Fecha/hora : " + (Get-Date -Format 'yyyy-MM-dd HH:mm')),
  ("PC origen  : " + $env:COMPUTERNAME),
  "Metodo     : backup interno de PocketBase (SIN cortar el servicio)",
  ("Contenido  : foto completa (llaves, objetos, autorizaciones,"),
  ("             usuarios, vigilantes, agenda, historial, etc.)")
) -join [Environment]::NewLine
Set-Content -Path (Join-Path $PendriveRoot 'ULTIMO_REFRESCO_DE_DATOS.txt') -Value $sello -Encoding UTF8

# --- Marcador para el Monitor del Sistema (check_system_health.ps1) ---
# El monitor de salud verifica cuando fue el ultimo resguardo portable leyendo
# el campo "last_seed_written_at:" del archivo:
#   C:\ProgramData\FCEA-Sistema-Llaves\pb_data\_RESGUARDO_DATOS_INFO.txt
# (nombre nuevo desde 2026-08-20; antes se llamaba _SEMILLA_INFO.txt).
# Ahora que el resguardo se hace con ESTE script ("ACTUALIZAR DATOS"), dejamos
# ese sello para que la advertencia "Nunca se actualizaron los datos del
# pendrive" desaparezca. Escribimos el nombre NUEVO y ademas mantenemos el
# nombre viejo por compatibilidad con instalaciones que aun tengan el lector
# antiguo.
try {
  $progDataPbData = "C:\ProgramData\FCEA-Sistema-Llaves\pb_data"
  if (Test-Path $progDataPbData) {
    $nowIso   = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    $infoProg = Join-Path $progDataPbData "_RESGUARDO_DATOS_INFO.txt"
    $infoProgLegacy = Join-Path $progDataPbData "_SEMILLA_INFO.txt"
    $infoTxt  = @(
      "last_seed_written_at: $nowIso",
      "origen: $($env:COMPUTERNAME)",
      "metodo: backup interno de PocketBase (ACTUALIZAR DATOS, sin cortar servicio)",
      "generado_por: ACTUALIZAR_DATOS_RESCATE.ps1"
    ) -join [Environment]::NewLine
    Set-Content -Path $infoProg -Value $infoTxt -Encoding UTF8 -Force
    # Compatibilidad: dejar tambien el nombre viejo por si el lector es antiguo.
    Set-Content -Path $infoProgLegacy -Value $infoTxt -Encoding UTF8 -Force
    Ok "      Marcador de resguardo actualizado para el Monitor del Sistema."
  } else {
    Warn "      (No existe $progDataPbData : no se escribio el marcador del Monitor. No es grave.)"
  }
} catch {
  Warn ("      (No se pudo escribir el marcador del Monitor: " + $_.Exception.Message + ")")
}

# --- Refrescar el Monitor del Sistema en el acto (regenerar system_health.json) ---
# Sin esto, la advertencia "Nunca se actualizaron los datos del pendrive"
# sigue mostrandose hasta que la tarea programada FCEA-Chequeo-Salud vuelva a
# correr (cada 30 min o al iniciar sesion). Corriendo el chequeo aca mismo, la
# advertencia desaparece apenas termina este script (solo hay que recargar la
# pagina del Monitor con F5). Esto NO toca datos ni config.json.
try {
  $healthScript = "C:\sistema-llaves-fcea\pocketbase\maintenance\check_system_health.ps1"
  if (Test-Path $healthScript) {
    Info "      Refrescando el Monitor del Sistema..."
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $healthScript | Out-Null
    Ok "      Monitor del Sistema actualizado. La advertencia debe desaparecer."
    Ok "      (Si sigue visible, recargue la pagina del Monitor con F5.)"
  } else {
    Warn "      (No se encontro check_system_health.ps1; el Monitor se refrescara solo en <=30 min o al reiniciar sesion.)"
  }
} catch {
  Warn ("      (No se pudo refrescar el Monitor automaticamente: " + $_.Exception.Message + ")")
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Ok "  LISTO. El pendrive de RESCATE tiene la foto de datos de hoy."
Ok "  No se corto el servicio y no se toco la base de produccion."
Ok "  Guarde el pendrive en su lugar de custodia."
Write-Host "============================================================" -ForegroundColor Green
if ($script:logFile) { Write-Host ("Log guardado en: " + $script:logFile) -ForegroundColor Yellow }
Write-Host ""
DetenerLog
Pausa



