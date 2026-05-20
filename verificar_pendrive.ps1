if (Test-Path "D:\sistema\node_modules") {
    $count = (Get-ChildItem "D:\sistema\node_modules" -Directory -ErrorAction SilentlyContinue | Measure-Object).Count
    $sizeMB = [math]::Round((Get-ChildItem "D:\sistema\node_modules" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 0)
    Write-Host "[OK] node_modules en pendrive: $count paquetes, $sizeMB MB"
} else {
    Write-Host "[FALTA] node_modules aun no esta en el pendrive"
}
