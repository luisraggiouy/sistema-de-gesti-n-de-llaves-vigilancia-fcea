$t = "C:\sistema-llaves-fcea-TEST"
if (Test-Path "$t\package.json") {
    Write-Host "[OK] package.json existe - copia correcta!" -ForegroundColor Green
} else {
    Write-Host "[COPIANDO o FALLO] package.json no existe aun en $t" -ForegroundColor Yellow
    if (Test-Path $t) {
        Write-Host "Contenido actual:" -ForegroundColor Gray
        Get-ChildItem $t | Select-Object Name | Format-Table -AutoSize
    } else {
        Write-Host "La carpeta TEST no existe todavia" -ForegroundColor Red
    }
}
if (Test-Path "$t\dist\assets") {
    Write-Host "[OK] dist\assets existe" -ForegroundColor Green
} else {
    Write-Host "[FALTA] dist\assets" -ForegroundColor Yellow
}
