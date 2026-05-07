$TaskName = "SistemaLlavesFCEA"
$ProjectRoot = "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
$ScriptPath = "$ProjectRoot\iniciar_sistema.bat"

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-WindowStyle Normal -Command `"Start-Process -FilePath 'cmd.exe' -ArgumentList '/c \`"$ScriptPath\`"' -WorkingDirectory '$ProjectRoot' -Verb RunAs`"" `
    -WorkingDirectory $ProjectRoot

$Trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$Trigger.Delay = "PT30S"

$Principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Highest

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
    -MultipleInstances IgnoreNew

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings `
    -Description "Inicia automaticamente el Sistema de Gestion de Llaves FCEA al iniciar sesion en Windows. Incluye PocketBase (puerto 8090), Frontend (puerto 8080) y Watchdog de proteccion completo." `
    -Force | Out-Null

Write-Host "Tarea '$TaskName' actualizada correctamente con delay de 30 segundos." -ForegroundColor Green
$task = Get-ScheduledTask -TaskName $TaskName
Write-Host "Estado: $($task.State)" -ForegroundColor Cyan
