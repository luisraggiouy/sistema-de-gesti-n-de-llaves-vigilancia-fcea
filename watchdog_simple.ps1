# Watchdog simple para PocketBase
$pb = "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\pocketbase"
if (Test-Path "$pb\pocketbase.exe") {
    if (-not (Get-Process pocketbase -EA SilentlyContinue)) {
        cd $pb
        Start-Process ".\pocketbase.exe" -ArgumentList "serve" -WindowStyle Hidden
    }
}
