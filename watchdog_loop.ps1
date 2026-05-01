# Watchdog Loop - Se ejecuta continuamente en segundo plano
$pocketbasePath = "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase"
$pocketbaseExe = Join-Path $pocketbasePath "pocketbase.exe"

Write-Host "Watchdog iniciado - Monitoreando PocketBase cada 2 minutos..." -ForegroundColor Green
Write-Host "Presione Ctrl+C para detener" -ForegroundColor Yellow
Write-Host ""

while ($true) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    if (Test-Path $pocketbaseExe) {
        $process = Get-Process -Name "pocketbase" -ErrorAction SilentlyContinue
        
        if (-not $process) {
            Write-Host "[$timestamp] PocketBase caido - Reiniciando..." -ForegroundColor Red
            Set-Location $pocketbasePath
            Start-Process -FilePath $pocketbaseExe -ArgumentList "serve" -WindowStyle Hidden -WorkingDirectory $pocketbasePath
            Write-Host "[$timestamp] PocketBase reiniciado" -ForegroundColor Green
        } else {
            Write-Host "[$timestamp] PocketBase OK (PID: $($process.Id))" -ForegroundColor Gray
        }
    } else {
        Write-Host "[$timestamp] ERROR: pocketbase.exe no encontrado" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 120  # Esperar 2 minutos
}
