$distPath = "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\dist"
if (Test-Path $distPath) {
    $size = [math]::Round((Get-ChildItem $distPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
    Write-Host "dist existe: $size MB"
    Get-ChildItem $distPath | Select-Object Name, Length
} else {
    Write-Host "dist NO existe - hay que compilar con npm run build"
}
