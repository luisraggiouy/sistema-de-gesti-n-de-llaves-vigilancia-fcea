Write-Host "=== DIAGNOSTICO DEL SISTEMA INSTALADO ===" -ForegroundColor Cyan
Write-Host ""

$base = "C:\sistema-llaves-fcea"

# 1. Existe el directorio?
if (-not (Test-Path $base)) {
    Write-Host "[ERROR] C:\sistema-llaves-fcea NO EXISTE" -ForegroundColor Red
    Write-Host "El instalador no copio el sistema correctamente." -ForegroundColor Red
    Read-Host "Presione Enter para salir"
    exit
}

Write-Host "[OK] C:\sistema-llaves-fcea existe" -ForegroundColor Green

# 2. Que archivos hay?
Write-Host ""
Write-Host "Archivos en la raiz:" -ForegroundColor Yellow
Get-ChildItem $base | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize

# 3. Existe dist?
if (Test-Path "$base\dist\assets") {
    $js = Get-ChildItem "$base\dist\assets" -Filter "*.js" | Select-Object -First 1
    $css = Get-ChildItem "$base\dist\assets" -Filter "*.css" | Select-Object -First 1
    Write-Host "[OK] dist\assets existe" -ForegroundColor Green
    if ($js)  { Write-Host "  JS:  $($js.Name) ($([math]::Round($js.Length/1KB,0)) KB)" }
    if ($css) { Write-Host "  CSS: $($css.Name) ($([math]::Round($css.Length/1KB,0)) KB)" }
} else {
    Write-Host "[ERROR] dist\assets NO existe" -ForegroundColor Red
}

# 4. Existe vite.config.ts?
if (Test-Path "$base\vite.config.ts") {
    $content = Get-Content "$base\vite.config.ts" -Raw
    if ($content -match "appType") {
        Write-Host "[OK] vite.config.ts tiene appType:spa" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] vite.config.ts NO tiene appType:spa" -ForegroundColor Red
    }
} else {
    Write-Host "[ERROR] vite.config.ts NO existe" -ForegroundColor Red
}

# 5. Existe node_modules?
if (Test-Path "$base\node_modules\vite") {
    Write-Host "[OK] node_modules\vite existe" -ForegroundColor Green
} else {
    Write-Host "[ERROR] node_modules\vite NO existe" -ForegroundColor Red
}

# 6. Que proceso esta en puerto 8080?
Write-Host ""
Write-Host "Procesos en puerto 8080:" -ForegroundColor Yellow
$port = netstat -ano 2>$null | Select-String ":8080"
if ($port) { $port | ForEach-Object { Write-Host $_ } }
else { Write-Host "  NINGUNO - el servidor no esta corriendo" -ForegroundColor Red }

# 7. Que proceso esta en puerto 8090?
Write-Host ""
Write-Host "Procesos en puerto 8090 (PocketBase):" -ForegroundColor Yellow
$pb = netstat -ano 2>$null | Select-String ":8090"
if ($pb) { $pb | ForEach-Object { Write-Host $_ } }
else { Write-Host "  NINGUNO - PocketBase no esta corriendo" -ForegroundColor Red }

Write-Host ""
Write-Host "=== FIN DIAGNOSTICO ===" -ForegroundColor Cyan
Read-Host "Presione Enter para salir"
