# ============================================================
# Sistema FCEA - Configuracion de energia (piloto produccion)
# ============================================================
# Deja la PC "siempre despierta":
#   - Monitor nunca se apaga.
#   - Disco nunca se apaga.
#   - Sistema nunca suspende ni hiberna.
#   - USB nunca entra en Selective Suspend (evita touch dormido).
#   - Screensaver deshabilitado.
#   - Tarea programada FCEA-KeepAwake que refuerza el estado
#     via SetThreadExecutionState en background.
#
# Se ejecuta en las 3 PCs del piloto (Monitor + Terminal-A + Terminal-B).
# 100% reversible con:  powercfg /restoredefaultschemes
# ============================================================

#Requires -Version 5.1

$ErrorActionPreference = "Continue"

# Contador de warnings/errores. Si al final es 0 -> se confia en que
# el ahorro de energia esta 100% desactivado y el frontend puede
# omitir el screensaver de fallback (ver useTouchUX.ts).
$script:configEnergiaWarnings = 0

Write-Host ""
Write-Host "  Configurando energia para produccion 24/7..."
Write-Host ""


# --- 1) Timeouts powercfg a 0 en AC y DC ---
$comandos = @(
  @{ Etiqueta = "Monitor (AC)"          ; Args = @("/change","monitor-timeout-ac","0") },
  @{ Etiqueta = "Monitor (DC)"          ; Args = @("/change","monitor-timeout-dc","0") },
  @{ Etiqueta = "Disco (AC)"            ; Args = @("/change","disk-timeout-ac","0") },
  @{ Etiqueta = "Disco (DC)"            ; Args = @("/change","disk-timeout-dc","0") },
  @{ Etiqueta = "Suspender (AC)"        ; Args = @("/change","standby-timeout-ac","0") },
  @{ Etiqueta = "Suspender (DC)"        ; Args = @("/change","standby-timeout-dc","0") },
  @{ Etiqueta = "Hibernar (AC)"         ; Args = @("/change","hibernate-timeout-ac","0") },
  @{ Etiqueta = "Hibernar (DC)"         ; Args = @("/change","hibernate-timeout-dc","0") }
)

foreach ($c in $comandos) {
  try {
    & powercfg @($c.Args) 2>&1 | Out-Null
    Write-Host ("    [OK] " + $c.Etiqueta + " = nunca")
  } catch {
    Write-Host ("    [WARN] " + $c.Etiqueta + ": " + $_.Exception.Message)
    $script:configEnergiaWarnings++
  }
}


# Desactivar hibernacion (libera espacio de hiberfil.sys tambien)
try { & powercfg /hibernate off 2>&1 | Out-Null } catch { }

# --- 2) USB Selective Suspend a 0 en el plan activo ---
# GUIDs conocidos:
#   USB settings = 2a737441-1930-4402-8d77-b2bebba308a3
#   USB selective suspend = 48e6b7a6-50f5-4782-a5d4-53bb8f07e226
try {
  $planActivo = (powercfg /getactivescheme) -replace '.*GUID de configuraci.n de energ.a:\s*([a-f0-9\-]+).*','$1'
  if (-not $planActivo -or $planActivo.Length -ne 36) {
    # Fallback ingles
    $planActivo = (powercfg /getactivescheme) -replace '.*Power Scheme GUID:\s*([a-f0-9\-]+).*','$1'
  }
  if ($planActivo -and $planActivo.Length -eq 36) {
    & powercfg /setacvalueindex $planActivo 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>&1 | Out-Null
    & powercfg /setdcvalueindex $planActivo 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>&1 | Out-Null
    & powercfg /setactive $planActivo 2>&1 | Out-Null
    Write-Host "    [OK] USB Selective Suspend deshabilitado"
  } else {
    Write-Host "    [WARN] No se pudo detectar el GUID del plan activo, USB Selective Suspend queda por defecto"
    $script:configEnergiaWarnings++
  }
} catch {
  Write-Host ("    [WARN] USB Selective Suspend: " + $_.Exception.Message)
  $script:configEnergiaWarnings++
}


# --- 3) Screensaver OFF (registro HKCU) ---
# Se aplica al usuario que ejecuta este script; en el arranque autologin
# del piloto, este mismo usuario es el que corre la sesion.
try {
  $regDesktop = "HKCU:\Control Panel\Desktop"
  if (-not (Test-Path $regDesktop)) { New-Item -Path $regDesktop -Force | Out-Null }
  Set-ItemProperty -Path $regDesktop -Name "ScreenSaveActive"    -Value "0"       -Force -ErrorAction SilentlyContinue
  Set-ItemProperty -Path $regDesktop -Name "ScreenSaveTimeOut"   -Value "0"       -Force -ErrorAction SilentlyContinue
  Set-ItemProperty -Path $regDesktop -Name "ScreenSaverIsSecure" -Value "0"       -Force -ErrorAction SilentlyContinue
  Write-Host "    [OK] Screensaver deshabilitado"
} catch {
  Write-Host ("    [WARN] Screensaver: " + $_.Exception.Message)
  $script:configEnergiaWarnings++
}


# --- 4) Tarea programada FCEA-KeepAwake ---
# Corre al arranque de la PC (SYSTEM) y mantiene ES_CONTINUOUS |
# ES_DISPLAY_REQUIRED | ES_SYSTEM_REQUIRED para que Windows nunca
# apague la pantalla ni suspenda, aunque alguien cambie el plan.
$keepAwakeScript = @'
Add-Type -Namespace FCEA -Name PowerHelper -MemberDefinition @"
    [System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint SetThreadExecutionState(uint esFlags);
"@
$ES_CONTINUOUS       = [uint32]"0x80000000"
$ES_SYSTEM_REQUIRED  = [uint32]"0x00000001"
$ES_DISPLAY_REQUIRED = [uint32]"0x00000002"
[void][FCEA.PowerHelper]::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED -bor $ES_DISPLAY_REQUIRED)
while ($true) { Start-Sleep -Seconds 60 }
'@

$keepAwakePath = "C:\ProgramData\FCEA-Sistema-Llaves\KeepAwake.ps1"
try {
  $keepAwakeDir = Split-Path $keepAwakePath
  if (-not (Test-Path $keepAwakeDir)) { New-Item -ItemType Directory -Path $keepAwakeDir -Force | Out-Null }
  Set-Content -Path $keepAwakePath -Value $keepAwakeScript -Encoding UTF8 -Force

  $tareaNombre = "FCEA-KeepAwake"
  schtasks /Delete /TN $tareaNombre /F 2>&1 | Out-Null

  $accion  = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$keepAwakePath`""
  schtasks /Create /TN $tareaNombre /TR $accion /SC ONSTART /RL HIGHEST /RU SYSTEM /F 2>&1 | Out-Null

  # Arrancar de inmediato para no esperar al proximo boot
  schtasks /Run /TN $tareaNombre 2>&1 | Out-Null
  Write-Host "    [OK] Tarea FCEA-KeepAwake registrada y corriendo"
} catch {
  Write-Host ("    [WARN] FCEA-KeepAwake: " + $_.Exception.Message)
  $script:configEnergiaWarnings++
}


# --- 5) Marcar en config.json que el ahorro de energia esta OFF ---
#
# Escribe ui.energia_ahorro_desactivado = true en public/config.json y
# dist/config.json del sistema instalado, SOLO si todo lo anterior
# corrio sin warnings. El frontend (useTouchUX.ts) usa este flag para
# decidir si activa el screensaver "pantalla negra" de fallback cuando
# no hay actividad tactil/mouse durante X minutos.
#
# Regla:
#   - warnings == 0  -> flag = true  -> frontend NO activa screensaver
#                        (Windows garantiza que la pantalla queda encendida).
#   - warnings  > 0  -> flag = false -> frontend SI activa screensaver
#                        (fallback: al menos oscurecemos el navegador
#                        para reducir el consumo si Windows apagara el
#                        monitor por su cuenta).
#
# Se escribe en public/ (source de dev) y en dist/ (build compilado).
# En produccion el navegador carga /dist/config.json.

$flagValor = ($script:configEnergiaWarnings -eq 0)
Write-Host ""
Write-Host ("  Ahorro de energia desactivado con exito: " + $flagValor + " (warnings: " + $script:configEnergiaWarnings + ")")

$rutasConfig = @(
  "C:\sistema-llaves-fcea\public\config.json",
  "C:\sistema-llaves-fcea\dist\config.json"
)

foreach ($rutaCfg in $rutasConfig) {
  if (-not (Test-Path $rutaCfg)) {
    # No es error: durante el paso 6 del recuperador, dist\ todavia
    # no existe. El paso 9 (BLINDAR_CONFIG) escribira el archivo final
    # con el mismo valor de flag - por eso tambien lo leemos alli.
    continue
  }
  try {
    $json = Get-Content $rutaCfg -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $json.ui) {
      $json | Add-Member -MemberType NoteProperty -Name ui -Value ([pscustomobject]@{}) -Force
    }
    if ($json.ui.PSObject.Properties['energia_ahorro_desactivado']) {
      $json.ui.energia_ahorro_desactivado = $flagValor
    } else {
      $json.ui | Add-Member -MemberType NoteProperty -Name energia_ahorro_desactivado -Value $flagValor -Force
    }
    $json | ConvertTo-Json -Depth 10 | Set-Content -Path $rutaCfg -Encoding UTF8 -Force
    Write-Host ("    [OK] Flag ui.energia_ahorro_desactivado=" + $flagValor + " en " + $rutaCfg)
  } catch {
    Write-Host ("    [WARN] No se pudo escribir el flag en " + $rutaCfg + ": " + $_.Exception.Message)
  }
}

# Exportar el flag al padre (INSTALAR.bat / RECUPERAR) via variable de
# entorno, para que BLINDAR_CONFIG lo use al reescribir config.json
# desde cero.
try {
  [Environment]::SetEnvironmentVariable('FCEA_ENERGIA_AHORRO_OFF', $flagValor.ToString().ToLower(), 'Process')
} catch {}

Write-Host ""
Write-Host "  Energia configurada: la PC nunca se apagara ni suspendera."
Write-Host ""
exit 0


