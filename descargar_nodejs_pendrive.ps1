Write-Host "Descargando Node.js LTS v20.19.2 directamente al pendrive..."
Write-Host "Esto puede tardar varios minutos segun la velocidad de internet..."
Write-Host ""

$url  = "https://nodejs.org/dist/v20.19.2/node-v20.19.2-x64.msi"
$dest = "D:\instaladores\node-setup.msi"

# Asegurar que la carpeta existe
if (-not (Test-Path "D:\instaladores")) {
    New-Item -ItemType Directory -Path "D:\instaladores" -Force | Out-Null
}

try {
    # Usar WebClient que muestra progreso y es mas rapido
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($url, $dest)

    $sizeMB = [math]::Round((Get-Item $dest).Length / 1MB, 1)
    Write-Host "[OK] Node.js descargado: $sizeMB MB"
    Write-Host "[OK] Guardado en: $dest"
    Write-Host ""

    # Tambien copiar a D:\sistema\scripts\ para que el instalador lo encuentre ahi
    Copy-Item -Path $dest -Destination "D:\scripts\node-setup.msi" -Force
    Write-Host "[OK] Copia adicional en D:\scripts\node-setup.msi"

    Write-Host ""
    Write-Host "El pendrive instalador ya tiene Node.js incluido."
    Write-Host "Ahora puede ejecutar INSTALAR_SISTEMA.bat en la PC destino."

} catch {
    Write-Host "[ERROR] No se pudo descargar: $_"
    Write-Host ""
    Write-Host "Verifique la conexion a internet e intente nuevamente."
}
