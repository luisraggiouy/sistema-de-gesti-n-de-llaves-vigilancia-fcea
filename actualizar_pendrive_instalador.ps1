$src = 'c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea'
$found = $false

foreach ($letter in @('D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z')) {
    $drivePath = $letter + ":\"
    if (Test-Path $drivePath) {
        $vol = Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue
        if ($vol -and $vol.FileSystemLabel -like '*INSTALADOR*') {
            Write-Host "Pendrive instalador encontrado en $letter - actualizando archivos..." -ForegroundColor Cyan
            Write-Host ""

            # Asegurar que existe la carpeta scripts en el pendrive
            $scriptsDir = $letter + ":\scripts"
            if (-not (Test-Path $scriptsDir)) { New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null }

            # 1. Script instalador principal
            $destInstalar = $letter + ":\scripts\instalar_automatico.ps1"
            Copy-Item -Path "$src\scripts\instalar_automatico.ps1" -Destination $destInstalar -Force
            Write-Host "  [OK] scripts\instalar_automatico.ps1" -ForegroundColor Green

            # 2. Desinstalador (bat lanzador en raiz)
            $destDesinstBat = $letter + ":\DESINSTALAR_SISTEMA.bat"
            Copy-Item -Path "$src\DESINSTALAR_SISTEMA.bat" -Destination $destDesinstBat -Force
            Write-Host "  [OK] DESINSTALAR_SISTEMA.bat" -ForegroundColor Green

            # 3. Desinstalador (script PowerShell en scripts\)
            # NOTA: en el repo el desinstalador real ahora vive en
            # scripts\respaldo_recuperacion\lib\, pero en el pendrive instalador
            # mantenemos la convencion previa (scripts\DESINSTALAR_SISTEMA_LIMPIO.ps1)
            # para no romper instaladores ya en circulacion.
            $destDesinstPs1 = $letter + ":\scripts\DESINSTALAR_SISTEMA_LIMPIO.ps1"
            $srcDesinstPs1  = "$src\scripts\respaldo_recuperacion\lib\DESINSTALAR_SISTEMA_LIMPIO.ps1"
            Copy-Item -Path $srcDesinstPs1 -Destination $destDesinstPs1 -Force
            Write-Host "  [OK] scripts\DESINSTALAR_SISTEMA_LIMPIO.ps1" -ForegroundColor Green

            Write-Host ""
            Write-Host "Pendrive instalador actualizado correctamente en $letter" -ForegroundColor Green
            $found = $true
            break
        }
    }
}
if (-not $found) {
    Write-Host "Pendrive INSTALADOR no encontrado. Conectalo y volvé a ejecutar." -ForegroundColor Yellow
}
