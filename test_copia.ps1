$testDst = "C:\sistema-llaves-fcea-TEST"

Write-Host "Probando copia desde D:\sistema a $testDst ..." -ForegroundColor Cyan

# Crear destino primero (igual que el instalador corregido)
New-Item -ItemType Directory -Path $testDst -Force | Out-Null

# Copiar contenido (no la carpeta)
Get-ChildItem -Path "D:\sistema" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $testDst -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "=== RESULTADO ===" -ForegroundColor Yellow

if (Test-Path "$testDst\package.json") {
    Write-Host "[OK] package.json existe - copia correcta" -ForegroundColor Green
} else {
    Write-Host "[ERROR] package.json NO existe" -ForegroundColor Red
    Write-Host "Contenido de $testDst :" -ForegroundColor Yellow
    Get-ChildItem $testDst | Select-Object Name | Format-Table -AutoSize
}

if (Test-Path "$testDst\dist\assets") {
    $js = Get-ChildItem "$testDst\dist\assets" -Filter "*.js" | Select-Object -First 1
    Write-Host "[OK] dist\assets existe - JS: $($js.Name)" -ForegroundColor Green
} else {
    Write-Host "[ERROR] dist\assets NO existe" -ForegroundColor Red
}

if (Test-Path "$testDst\vite.config.ts") {
    $c = Get-Content "$testDst\vite.config.ts" -Raw
    if ($c -match "appType") {
        Write-Host "[OK] vite.config.ts tiene appType:spa" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] vite.config.ts sin appType" -ForegroundColor Red
    }
} else {
    Write-Host "[ERROR] vite.config.ts NO existe" -ForegroundColor Red
}

# Limpiar
Remove-Item $testDst -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "Test completado. Carpeta de prueba eliminada." -ForegroundColor Gray
