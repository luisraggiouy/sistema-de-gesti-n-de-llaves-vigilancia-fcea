# =============================================================================
# ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1
# -----------------------------------------------------------------------------
# Copia los scripts del recuperador v2.0 + desinstalador + carpeta lib/ a la
# raiz del pendrive recuperador, sin tocar respaldos_db, sistema/ ni
# instaladores/.
#
# Uso (PowerShell ELEVADO):
#     .\ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1 -Letra D
#     .\ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1            # autodetecta
#
# Si no hay privilegios de admin se autoeleva.
#
# Que copia (layout v2.1: solo .bat visibles en raiz):
#     REINSTALAR-COMPLETO.bat                  (wrapper a lib\REINSTALAR-COMPLETO.ps1)
#     DESINSTALAR-SISTEMA.bat                  (wrapper a lib\DESINSTALAR-SISTEMA.ps1)
#     LEEME-PRIMERO.txt
#     lib\REINSTALAR-COMPLETO.ps1              (motor real, tambien hace 'reparar' si detecta install_config previo)
#     lib\DESINSTALAR-SISTEMA.ps1              (wrapper PS, llama al desinstalador real)
#     lib\DESINSTALAR_SISTEMA_LIMPIO.ps1       (desinstalador real)
#     lib\detectar_hardware.ps1
#     lib\install_config_io.ps1
#     lib\abrir_chrome_kiosk.ps1
# =============================================================================

[CmdletBinding()]
param(
    [string]$Letra = ""
)

$ErrorActionPreference = "Stop"

# Para escribir en pendrive USB no hace falta admin: alcanza con limpiar
# atributos S/R/H. (Si necesitas admin, ejecutalo desde una consola elevada).

function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-OK  ($m){ Write-Host "[OK]   $m" -ForegroundColor Green }
function Write-Err ($m){ Write-Host "[ERR]  $m" -ForegroundColor Red }
function Write-Wrn ($m){ Write-Host "[WRN]  $m" -ForegroundColor Yellow }

# ----- Resolver letra del pendrive --------------------------------------
function Find-PendrivePath {
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        $cand = Join-Path "$($_.Root)" "RECUPERACION_SISTEMA_LLAVES_FCEA"
        if (Test-Path $cand) { return $cand }
        if (Test-Path (Join-Path $_.Root "REINSTALAR-COMPLETO.bat")) {
            return $_.Root.TrimEnd('\')
        }
    } | Select-Object -First 1
}

if ($Letra) {
    $L = $Letra.TrimEnd(':','\')
    $candidatos = @("${L}:\RECUPERACION_SISTEMA_LLAVES_FCEA", "${L}:")
    $pendriveDir = $candidatos | Where-Object { Test-Path $_ } | Select-Object -First 1
} else {
    $pendriveDir = Find-PendrivePath
}

if (-not $pendriveDir -or -not (Test-Path $pendriveDir)) {
    Write-Err "No encontre el pendrive recuperador. Pase -Letra X."
    Read-Host "Presione Enter"
    exit 1
}

Write-Info "Pendrive detectado en: $pendriveDir"

# ----- Resolver origen (este repo) --------------------------------------
$repoRoot = $PSScriptRoot
$recDir   = Join-Path $repoRoot "scripts\respaldo_recuperacion"
$src = @{
    # Wrappers .bat que van en la raiz del pendrive
    RecBat       = Join-Path $recDir "REINSTALAR-COMPLETO.bat"
    DesinstBat   = Join-Path $recDir "DESINSTALAR-SISTEMA.bat"
    Leeme        = Join-Path $recDir "LEEME-PRIMERO.txt"
    # Motores reales y wrappers PS que van dentro de lib\
    Recuperador  = Join-Path $recDir "lib\REINSTALAR-COMPLETO.ps1"
    DesinstWrap  = Join-Path $recDir "lib\DESINSTALAR-SISTEMA.ps1"
    DesinstReal  = Join-Path $recDir "lib\DESINSTALAR_SISTEMA_LIMPIO.ps1"
    # Libs compartidas (detectar_hardware, install_config_io, abrir_chrome_kiosk)
    LibDirShared = Join-Path $repoRoot "scripts\lib"
}
foreach ($k in $src.Keys) {
    if (-not (Test-Path $src[$k])) { Write-Err "No existe en repo: $($src[$k])"; exit 1 }
}

# ----- Helper para forzar la copia incluso si el destino tiene atributos
#       'System' o 'ReadOnly' (eso es lo que paso la vez anterior) --------
function Copy-Force {
    param(
        [Parameter(Mandatory)] [string]$SourcePath,
        [Parameter(Mandatory)] [string]$DestPath
    )
    if (Test-Path $DestPath) {
        try {
            # Limpiar atributos S, R, H que puedan bloquear la sobrescritura
            attrib -S -R -H "$DestPath" 2>$null | Out-Null
        } catch {}
    }
    Copy-Item -Force -Path $SourcePath -Destination $DestPath
}

# ----- Limpieza de archivos del layout viejo (v1 y v2.0) ----------------
# En el layout v2.1 SOLO viven en la raiz los 3 .bat + LEEME. Cualquier
# .ps1 que quede en la raiz es residuo del layout anterior.
$residuosRaiz = @(
    "REINSTALAR-COMPLETO.ps1",
    "DESINSTALAR-SISTEMA.ps1",
    "DESINSTALAR_SISTEMA_LIMPIO.ps1",
    "REPARAR-Y-INICIAR-SISTEMA.ps1",
    "REPARAR-Y-INICIAR-SISTEMA.bat",
    "ultimo_log_reinstalacion.txt"
)
foreach ($a in $residuosRaiz) {
    $sp = Join-Path $pendriveDir $a
    if (Test-Path $sp) {
        try { attrib -S -R -H "$sp" 2>$null | Out-Null } catch {}
        Remove-Item $sp -Force -ErrorAction SilentlyContinue
        Write-Info "Eliminado residuo del layout viejo: $a"
    }
}
# Tambien borrar carpetas _backup_v1_* viejas
Get-ChildItem $pendriveDir -Directory -Filter "_backup_v1_*" -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    Write-Info "Eliminado backup viejo: $($_.Name)"
}

# ----- Copiar wrappers .bat a la raiz -----------------------------------
Copy-Force -SourcePath $src.RecBat     -DestPath (Join-Path $pendriveDir "REINSTALAR-COMPLETO.bat")
Copy-Force -SourcePath $src.DesinstBat -DestPath (Join-Path $pendriveDir "DESINSTALAR-SISTEMA.bat")
Copy-Force -SourcePath $src.Leeme      -DestPath (Join-Path $pendriveDir "LEEME-PRIMERO.txt")
Write-OK "Wrappers .bat copiados a la raiz (2 archivos + LEEME)"

# ----- Reconstruir carpeta lib\ -----------------------------------------
$dstLibDir = Join-Path $pendriveDir "lib"
if (Test-Path $dstLibDir) {
    try { attrib -S -R -H "$dstLibDir\*" 2>$null | Out-Null } catch {}
    Remove-Item $dstLibDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $dstLibDir -Force | Out-Null

# Motores reales del recuperador (viven en scripts\respaldo_recuperacion\lib\)
Copy-Force -SourcePath $src.Recuperador -DestPath (Join-Path $dstLibDir "REINSTALAR-COMPLETO.ps1")
Copy-Force -SourcePath $src.DesinstWrap -DestPath (Join-Path $dstLibDir "DESINSTALAR-SISTEMA.ps1")
Copy-Force -SourcePath $src.DesinstReal -DestPath (Join-Path $dstLibDir "DESINSTALAR_SISTEMA_LIMPIO.ps1")
# Libs compartidas (detectar_hardware, install_config_io, abrir_chrome_kiosk)
Copy-Item -Force "$($src.LibDirShared)\*.ps1" -Destination $dstLibDir
$libsCount = (Get-ChildItem $dstLibDir -Filter "*.ps1").Count
Write-OK "Carpeta lib\ reconstruida ($libsCount archivos .ps1)"

# ----- Resumen ----------------------------------------------------------
Write-Host ""
Write-Host "==============================================" -ForegroundColor Magenta
Write-Host " PENDRIVE RECUPERADOR ACTUALIZADO A v2.0      " -ForegroundColor Magenta
Write-Host "==============================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Archivos en raiz del pendrive:" -ForegroundColor White
Get-ChildItem $pendriveDir -File | Sort-Object Name | ForEach-Object {
    Write-Host ("  {0,-38} {1,8}" -f $_.Name, $_.Length) -ForegroundColor Gray
}
Write-Host ""
Write-Host "Carpeta lib/:" -ForegroundColor White
Get-ChildItem $dstLibDir -File | ForEach-Object { Write-Host "  lib\$($_.Name)" -ForegroundColor Gray }
Write-Host ""
Write-Host "PROXIMOS PASOS:" -ForegroundColor Green
Write-Host "  1. Sacar el pendrive con seguridad."           -ForegroundColor White
Write-Host "  2. Conectarlo a la PC limpia."                 -ForegroundColor White
Write-Host "  3. (Opcional) Ejecutar DESINSTALAR-SISTEMA.bat para borrar instalacion previa." -ForegroundColor White
Write-Host "  4. Ejecutar REINSTALAR-COMPLETO.bat (clic derecho > Ejecutar como admin)." -ForegroundColor White
Write-Host ""

Read-Host "Presione Enter para cerrar"
