# =============================================================
# REPARAR_ROL_CONFIG.ps1
# Corrige SOLO el campo "rol" del config.json de esta PC, segun
# el nombre del equipo. NO toca pocketbase_url, red, ni nada mas.
#
#   FCEA-MONITOR      -> rol = monitor
#   FCEA-TERMINAL-A   -> rol = terminal-a
#   FCEA-TERMINAL-B   -> rol = terminal-b
#
# Hace backup de cada config.json antes de tocarlo.
# Reutilizable en las 3 PCs. Escribe un log en el pendrive.
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'REPARAR ROL CONFIG - Sistema FCEA'

$carpetaLog = Join-Path $PSScriptRoot '_RESULTADOS'
if (-not (Test-Path $carpetaLog)) { New-Item -ItemType Directory -Path $carpetaLog -Force | Out-Null }
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$logPath = Join-Path $carpetaLog ("LOG_REPARAR_ROL_{0}_{1}.log" -f $env:COMPUTERNAME, $stamp)
try { Start-Transcript -Path $logPath -Force | Out-Null } catch {}

function Line($c='='){ Write-Host ($c * 62) -ForegroundColor Yellow }
Line; Write-Host "  REPARAR ROL CONFIG - $env:COMPUTERNAME" -ForegroundColor Yellow; Line
Write-Host "  Log: $logPath" -ForegroundColor Gray
Write-Host ""

# --- 1) Determinar el rol correcto segun el nombre de la PC ---
$pc = $env:COMPUTERNAME.ToUpper()
$rolCorrecto = $null
switch -Wildcard ($pc) {
    '*MONITOR*'    { $rolCorrecto = 'monitor' }
    '*TERMINAL-A*' { $rolCorrecto = 'terminal-a' }
    '*TERMINAL_A*' { $rolCorrecto = 'terminal-a' }
    '*TERMINAL-B*' { $rolCorrecto = 'terminal-b' }
    '*TERMINAL_B*' { $rolCorrecto = 'terminal-b' }
}

if (-not $rolCorrecto) {
    Write-Host "  No pude deducir el rol por el nombre '$pc'." -ForegroundColor Yellow
    Write-Host "  Elegi manualmente:" -ForegroundColor White
    Write-Host "    1) monitor"
    Write-Host "    2) terminal-a"
    Write-Host "    3) terminal-b"
    $op = Read-Host "  Opcion (1/2/3)"
    switch ($op) {
        '1' { $rolCorrecto = 'monitor' }
        '2' { $rolCorrecto = 'terminal-a' }
        '3' { $rolCorrecto = 'terminal-b' }
        default { Write-Host "  Opcion invalida. Cancelo." -ForegroundColor Red; try { Stop-Transcript | Out-Null } catch {}; Write-Host "ENTER..."; [void][System.Console]::ReadLine(); exit 1 }
    }
}

Write-Host "  PC detectada : $pc" -ForegroundColor Cyan
Write-Host "  Rol correcto : $rolCorrecto" -ForegroundColor Green
Write-Host ""

# --- 2) Archivos config.json a corregir (dist es el que sirve la app) ---
$targets = @(
    'C:\sistema-llaves-fcea\dist\config.json',
    'C:\sistema-llaves-fcea\public\config.json'
)

$algoCambiado = $false
foreach ($f in $targets) {
    Write-Host "--- $f ---" -ForegroundColor Cyan
    if (-not (Test-Path $f)) { Write-Host "  (no existe, lo salto)" -ForegroundColor Gray; Write-Host ""; continue }

    $raw = Get-Content -Path $f -Raw -Encoding UTF8
    $m = [regex]::Match($raw, '("rol"\s*:\s*")([^"]*)(")')
    if (-not $m.Success) { Write-Host "  [OJO] No encontre el campo 'rol' en el archivo. No lo toco." -ForegroundColor Red; Write-Host ""; continue }

    $rolActual = $m.Groups[2].Value
    Write-Host "  rol actual : $rolActual"
    if ($rolActual -eq $rolCorrecto) {
        Write-Host "  [OK] Ya estaba correcto. No hace falta cambiar." -ForegroundColor Green
        Write-Host ""
        continue
    }

    # Backup antes de tocar
    $bak = "$f.bak_$stamp"
    Copy-Item -Path $f -Destination $bak -Force
    Write-Host "  Backup     : $bak" -ForegroundColor Gray

    # Quitar solo-lectura si lo tuviera
    try { (Get-Item $f).IsReadOnly = $false } catch {}

    # Reemplazo quirurgico: SOLO el valor del rol
    $nuevo = [regex]::Replace($raw, '("rol"\s*:\s*")([^"]*)(")', ('${1}' + $rolCorrecto + '${3}'), 1)
    Set-Content -Path $f -Value $nuevo -Encoding UTF8 -NoNewline

    # Verificar
    $raw2 = Get-Content -Path $f -Raw -Encoding UTF8
    $m2 = [regex]::Match($raw2, '("rol"\s*:\s*")([^"]*)(")')
    $rolNuevo = if ($m2.Success) { $m2.Groups[2].Value } else { '???' }
    if ($rolNuevo -eq $rolCorrecto) {
        Write-Host "  [CAMBIADO] rol: $rolActual  ->  $rolNuevo" -ForegroundColor Green
        $algoCambiado = $true
    } else {
        Write-Host "  [ERROR] No quedo bien (rol=$rolNuevo). Restauro backup." -ForegroundColor Red
        Copy-Item -Path $bak -Destination $f -Force
    }
    Write-Host ""
}

Line
if ($algoCambiado) {
    Write-Host "  LISTO. Se corrigio el rol a '$rolCorrecto' en $env:COMPUTERNAME." -ForegroundColor Green
    Write-Host "  Ahora RECARGA el kiosko para que tome el cambio:" -ForegroundColor Cyan
    Write-Host "    - Cerra el navegador del kiosko (Alt+F4) y volve a abrirlo," -ForegroundColor White
    Write-Host "      o reinicia la PC." -ForegroundColor White
} else {
    Write-Host "  No se cambio nada (ya estaba correcto o no se encontro el campo)." -ForegroundColor Yellow
}
Line
Write-Host ""
Write-Host "  Verifica el resultado con el forense o corriendo VER de nuevo." -ForegroundColor Gray
try { Stop-Transcript | Out-Null } catch {}
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
