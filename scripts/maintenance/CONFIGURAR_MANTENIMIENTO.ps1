# ============================================================
# Sistema de Gestion de Llaves FCEA v2.0
# Configurar tareas de mantenimiento (solo en servidor)
# ============================================================
# Crea dos tareas programadas:
#   1) FCEA-Watchdog        → corre al login (loop infinito, monitorea PB)
#   2) FCEA-Backup-Diario   → corre todos los dias a las 03:00
#
# Si la PC no tiene rol=monitor, no registra nada.
# ============================================================

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

$repoRoot     = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$configPath   = Join-Path $repoRoot "public\config.json"
$watchdog     = Join-Path $PSScriptRoot "watchdog.ps1"
$backup       = Join-Path $PSScriptRoot "backup_automatico.ps1"

if (Test-Path $configPath) {
  $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
  if ($cfg.rol -ne "monitor") {
    Write-Host "[INFO] Esta PC tiene rol '$($cfg.rol)'. Mantenimiento solo se instala en 'monitor'." -ForegroundColor Yellow
    exit 0
  }
} else {
  Write-Host "[ERROR] public\config.json no existe. Ejecute INSTALAR.bat primero." -ForegroundColor Red
  exit 1
}

# --- 1) Watchdog -----------------------------------------------------------
$nombreWD = "FCEA-Watchdog"
Get-ScheduledTask -TaskName $nombreWD -ErrorAction SilentlyContinue | ForEach-Object {
  Write-Host "Eliminando tarea previa: $nombreWD"
  Unregister-ScheduledTask -TaskName $nombreWD -Confirm:$false
}

$triggerWD = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$actionWD  = New-ScheduledTaskAction `
  -Execute "powershell.exe" `
  -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$watchdog`"" `
  -WorkingDirectory $repoRoot
$settingsWD = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
  -RestartCount 999 `
  -RestartInterval (New-TimeSpan -Minutes 1)
$principalWD = New-ScheduledTaskPrincipal `
  -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $nombreWD `
  -Description "Watchdog del servidor PocketBase del Sistema FCEA." `
  -Trigger $triggerWD -Action $actionWD `
  -Settings $settingsWD -Principal $principalWD | Out-Null
Write-Host "[OK] Tarea '$nombreWD' creada." -ForegroundColor Green

# --- 2) Backup diario a las 03:00 -----------------------------------------
$nombreBK = "FCEA-Backup-Diario"
Get-ScheduledTask -TaskName $nombreBK -ErrorAction SilentlyContinue | ForEach-Object {
  Write-Host "Eliminando tarea previa: $nombreBK"
  Unregister-ScheduledTask -TaskName $nombreBK -Confirm:$false
}

$triggerBK = New-ScheduledTaskTrigger -Daily -At "03:00"
$actionBK  = New-ScheduledTaskAction `
  -Execute "powershell.exe" `
  -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$backup`"" `
  -WorkingDirectory $repoRoot
$settingsBK = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -RunOnlyIfNetworkAvailable:$false `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
$principalBK = New-ScheduledTaskPrincipal `
  -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName $nombreBK `
  -Description "Backup diario de pb_data del Sistema FCEA." `
  -Trigger $triggerBK -Action $actionBK `
  -Settings $settingsBK -Principal $principalBK | Out-Null
Write-Host "[OK] Tarea '$nombreBK' creada (corre todos los dias a las 03:00)." -ForegroundColor Green

Write-Host ""
Write-Host "Mantenimiento configurado correctamente."
Write-Host "  - Watchdog: relanza PocketBase si deja de responder."
Write-Host "  - Backup  : copia pb_data a backups\YYYY-MM-DD_HH-mm-ss.zip"
Write-Host "  - Logs en : pocketbase\maintenance\logs\"
Write-Host ""
