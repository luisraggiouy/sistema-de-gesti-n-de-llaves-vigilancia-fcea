# ============================================================
# Sistema de Gestion de Llaves FCEA v2.0
# Configurar inicio automatico al login del usuario
# ============================================================
# Crea una tarea programada de Windows que ejecuta INICIAR.bat
# cada vez que el usuario inicia sesion. Compatible con kiosk.
# ============================================================

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# Resolver ruta absoluta al INICIAR.bat (asumiendo que este script
# vive en scripts\install\ y INICIAR.bat tambien).
$repoRoot   = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$iniciarBat = Join-Path $PSScriptRoot "INICIAR.bat"

if (-not (Test-Path $iniciarBat)) {
  Write-Host "[ERROR] No se encontro $iniciarBat" -ForegroundColor Red
  exit 1
}

$taskName = "FCEA-Sistema-Llaves-AutoStart"

# Eliminar tarea previa si existe (idempotente).
$existente = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existente) {
  Write-Host "Eliminando tarea previa '$taskName'..."
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Trigger: al iniciar sesion del usuario actual.
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

# Action: ejecutar INICIAR.bat con el directorio de trabajo del repo.
$action = New-ScheduledTaskAction `
  -Execute "cmd.exe" `
  -Argument "/c `"$iniciarBat`"" `
  -WorkingDirectory $repoRoot

# Settings: arrancar cuanto antes, sin limite de tiempo, reiniciar si falla.
$settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
  -RestartCount 3 `
  -RestartInterval (New-TimeSpan -Minutes 1)

# Principal: usuario actual, sin elevar (modo interactivo).
$principal = New-ScheduledTaskPrincipal `
  -UserId $env:USERNAME `
  -LogonType Interactive `
  -RunLevel Limited

Register-ScheduledTask `
  -TaskName $taskName `
  -Description "Inicia el Sistema de Gestion de Llaves FCEA al iniciar sesion." `
  -Trigger $trigger `
  -Action $action `
  -Settings $settings `
  -Principal $principal | Out-Null

Write-Host ""
Write-Host "[OK] Tarea programada '$taskName' creada correctamente." -ForegroundColor Green
Write-Host "     Se ejecutara automaticamente al iniciar sesion como $env:USERNAME."
Write-Host ""
Write-Host "     Para desactivarla, ejecute:"
Write-Host "       Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false"
Write-Host ""
