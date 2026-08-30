# ============================================================
#  FIX: Ventana negra del Chequeo de Salud / Watchdog
#  Sistema de Gestion de Llaves FCEA
#  Fecha: 2026-08-30
#
#  Problema:
#    Las tareas programadas FCEA-Chequeo-Salud (cada 30 min) y
#    FCEA-Watchdog (al login) se ejecutaban con "powershell.exe"
#    en modo interactivo, por lo que aparecia una consola negra
#    ~2 segundos cada vez que corrian, molestando la operativa
#    del Monitor de Vigilancia.
#
#  Solucion:
#    Reemplazar la accion de esas tareas para que lancen el mismo
#    script PowerShell a traves de un wrapper VBScript
#    (run_hidden.vbs) con ventana OCULTA (WScript ... modo 0).
#    No cambia NADA de la logica: solo desaparece el parpadeo.
#
#  Solo aplica en el Monitor de Vigilancia (rol=monitor).
# ============================================================
#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# --- Auto-elevacion: re-lanzarse como administrador si no lo esta ---
$idn = [Security.Principal.WindowsIdentity]::GetCurrent()
$pri = New-Object Security.Principal.WindowsPrincipal($idn)
if (-not $pri.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "Solicitando permisos de administrador (UAC)..." -ForegroundColor Yellow
  try {
    Start-Process -FilePath "powershell.exe" `
      -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`"") `
      -Verb RunAs
  } catch {
    Write-Host "No se pudo elevar. Ejecute el .bat con clic derecho > Ejecutar como administrador." -ForegroundColor Red
    Read-Host "Presione ENTER para cerrar"
  }
  exit
}

function Info($m) { Write-Host $m -ForegroundColor Cyan }
function Ok($m)   { Write-Host $m -ForegroundColor Green }
function Warn($m) { Write-Host $m -ForegroundColor Yellow }
function Err($m)  { Write-Host $m -ForegroundColor Red }

$INSTALL = "C:\sistema-llaves-fcea"
$libDir  = Join-Path $INSTALL "scripts\lib"
$configPath  = Join-Path $INSTALL "public\config.json"
$watchdog    = Join-Path $INSTALL "scripts\maintenance\watchdog.ps1"
$healthCheck = Join-Path $INSTALL "pocketbase\maintenance\check_system_health.ps1"

Write-Host ""
Info "=== FIX ventana negra Chequeo de Salud / Watchdog (2026-08-30) ==="
Write-Host ""

# --- Verificar rol monitor ---
if (-not (Test-Path $configPath)) {
  Err "No existe $configPath. Esta PC no parece tener el sistema instalado."
  exit 1
}
$cfg = Get-Content $configPath -Raw | ConvertFrom-Json
if ($cfg.rol -ne "monitor") {
  Warn "Esta PC tiene rol '$($cfg.rol)'. Este fix SOLO aplica al Monitor de Vigilancia."
  Warn "No se hace ningun cambio. (Las Terminales no corren estas tareas.)"
  exit 0
}

# --- 1) Copiar run_hidden.vbs a la instalacion ---
$vbsOrigen  = Join-Path $PSScriptRoot "run_hidden.vbs"
$vbsDestino = Join-Path $libDir "run_hidden.vbs"
if (-not (Test-Path $vbsOrigen)) {
  Err "No se encontro run_hidden.vbs junto a este script."
  exit 1
}
if (-not (Test-Path $libDir)) { New-Item -ItemType Directory -Path $libDir -Force | Out-Null }
Copy-Item $vbsOrigen $vbsDestino -Force
Ok "[1/3] run_hidden.vbs copiado a $vbsDestino"

$wscript = Join-Path $env:WINDIR "System32\wscript.exe"

# --- Funcion para re-registrar una tarea usando wscript oculto ---
function Set-TareaOculta {
  param(
    [string]$Nombre,
    [string]$ScriptPs1,
    [object]$Triggers,
    [object]$Settings,
    [string]$Descripcion
  )

  if (-not (Test-Path $ScriptPs1)) {
    Warn "  No existe $ScriptPs1 -> se omite '$Nombre'."
    return
  }

  $existente = Get-ScheduledTask -TaskName $Nombre -ErrorAction SilentlyContinue
  if (-not $existente) {
    Warn "  La tarea '$Nombre' no existe en esta PC -> se omite."
    return
  }

  $arg = "`"$vbsDestino`" `"$ScriptPs1`""
  $action = New-ScheduledTaskAction -Execute $wscript -Argument $arg -WorkingDirectory $INSTALL

  # Solo reemplazamos la ACCION (no tocamos triggers/principal existentes).
  Set-ScheduledTask -TaskName $Nombre -Action $action | Out-Null
  Ok "  Tarea '$Nombre' actualizada (ahora corre OCULTA, sin ventana)."
}

# --- 2) FCEA-Chequeo-Salud (al login + cada 30 min) ---
Info "[2/3] Re-registrando FCEA-Chequeo-Salud..."
$trgHL1 = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$trgHL2 = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(2) `
  -RepetitionInterval (New-TimeSpan -Minutes 30) `
  -RepetitionDuration ([TimeSpan]::FromDays(365 * 10))
$setHL = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
  -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
Set-TareaOculta -Nombre "FCEA-Chequeo-Salud" -ScriptPs1 $healthCheck `
  -Triggers @($trgHL1, $trgHL2) -Settings $setHL `
  -Descripcion "Genera public\system_health.json para el Monitor de Vigilancia (cada 30 min). Corre oculto."

# --- 3) FCEA-Watchdog (al login) ---
Info "[3/3] Re-registrando FCEA-Watchdog..."
$trgWD = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$setWD = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
  -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
  -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)
Set-TareaOculta -Nombre "FCEA-Watchdog" -ScriptPs1 $watchdog `
  -Triggers @($trgWD) -Settings $setWD `
  -Descripcion "Watchdog del servidor PocketBase del Sistema FCEA. Corre oculto."

Write-Host ""
Ok "=== FIX aplicado. Ya no deberia aparecer la ventana negra. ==="
Write-Host ""
Info "Nota: el Watchdog seguia corriendo continuo; la ventana visible"
Info "era mayormente la del Chequeo de Salud cada 30 min. Ambas quedaron ocultas."
Write-Host ""
Info "Para verificar que el chequeo sigue funcionando (sin ventana):"
Info "  Start-ScheduledTask -TaskName 'FCEA-Chequeo-Salud'"
Info "  Luego revisar la fecha de: $INSTALL\public\system_health.json"
Write-Host ""
Read-Host "Presione ENTER para cerrar"
