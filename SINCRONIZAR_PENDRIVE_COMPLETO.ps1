# =============================================================================
# SINCRONIZAR_PENDRIVE_COMPLETO.ps1
# -----------------------------------------------------------------------------
# Sincroniza el pendrive recuperador con el repo en 2 pasos:
#
#   1) Pisa la copia del repo dentro del pendrive (D:\RECUPERACION_...\sistema\)
#      con la version limpia de C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\
#      via robocopy /MIR. Asi se eliminan los .ps1 con encoding corrupto que
#      detectamos en el pendrive.
#
#   2) Llama a ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1 para que la raiz del
#      pendrive (REINSTALAR-COMPLETO.*, DESINSTALAR-*, lib\) quede actualizada
#      con la version v2 del recuperador.
#
# Tras completar, parsea todos los .ps1 del pendrive para confirmar que
# ninguno tiene errores de sintaxis (asi evitamos llevarlos a la PC limpia).
#
# Uso:
#     PowerShell (puede ser sin admin para escribir un USB):
#       .\SINCRONIZAR_PENDRIVE_COMPLETO.ps1            # autodetecta
#       .\SINCRONIZAR_PENDRIVE_COMPLETO.ps1 -Letra D
#
# Lo que excluye al copiar el repo a sistema\ del pendrive:
#   - node_modules (gigantesco e innecesario)
#   - .git
#   - dist (la regenera el recuperador en la PC limpia con npm run build)
#   - pocketbase\pb_data (datos vivos, NO deben viajar al pendrive aqui;
#     los datos que se restauran vienen de respaldos_db\ del pendrive)
#   - respaldo_pre_restauracion
#   - logs, *.log, *.tmp
# =============================================================================

[CmdletBinding()]
param(
    [string]$Letra = ""
)

$ErrorActionPreference = "Stop"

function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-OK  ($m){ Write-Host "[OK]   $m" -ForegroundColor Green }
function Write-Err ($m){ Write-Host "[ERR]  $m" -ForegroundColor Red }
function Write-Wrn ($m){ Write-Host "[WRN]  $m" -ForegroundColor Yellow }
function Write-Step($n,$m){ Write-Host "" ; Write-Host ("===== PASO {0}: {1} =====" -f $n,$m) -ForegroundColor Magenta }

$repoRoot = $PSScriptRoot
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }
Write-Info "Repo origen: $repoRoot"

# ----- Resolver pendrive ----------------------------------------------------
function Find-PendrivePath {
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        $cand = Join-Path "$($_.Root)" "RECUPERACION_SISTEMA_LLAVES_FCEA"
        if (Test-Path $cand) { return $cand }
    } | Select-Object -First 1
}

if ($Letra) {
    $L = $Letra.TrimEnd(':','\')
    $pendriveDir = "${L}:\RECUPERACION_SISTEMA_LLAVES_FCEA"
    if (-not (Test-Path $pendriveDir)) {
        Write-Err "No existe $pendriveDir"
        Read-Host "Presione Enter"; exit 1
    }
} else {
    $pendriveDir = Find-PendrivePath
}

if (-not $pendriveDir -or -not (Test-Path $pendriveDir)) {
    Write-Err "No encontre el pendrive recuperador. Pase -Letra X."
    Read-Host "Presione Enter"; exit 1
}

Write-Info "Pendrive en: $pendriveDir"

# ----- PASO 1: robocopy /MIR  repo -> pendrive\sistema\ ---------------------
Write-Step 1 "Sincronizando repo limpio -> pendrive\sistema\ (robocopy /MIR)"

$dstSistema = Join-Path $pendriveDir "sistema"
if (-not (Test-Path $dstSistema)) {
    New-Item -ItemType Directory -Path $dstSistema -Force | Out-Null
}

# Carpetas y patrones a excluir
$xd = @(
    (Join-Path $repoRoot "node_modules"),
    (Join-Path $repoRoot ".git"),
    (Join-Path $repoRoot "dist"),
    (Join-Path $repoRoot "pocketbase\pb_data"),
    (Join-Path $repoRoot "pocketbase\pb_backups"),
    (Join-Path $repoRoot "respaldo_pre_restauracion"),
    (Join-Path $repoRoot ".vite"),
    (Join-Path $repoRoot "coverage")
)
$xf = @("*.log","*.tmp","Thumbs.db","desktop.ini")

$rcArgs = @(
    "`"$repoRoot`"", "`"$dstSistema`"",
    "/MIR",          # mirror: borra del destino lo que no esta en origen
    "/R:2", "/W:2",  # 2 reintentos, 2 segundos de espera
    "/NFL", "/NDL",  # no listar archivos ni directorios uno a uno
    "/NP",           # sin barra de progreso
    "/XJ"            # ignorar junctions/symlinks
)
foreach ($d in $xd) { $rcArgs += @("/XD", "`"$d`"") }
foreach ($p in $xf) { $rcArgs += @("/XF", $p) }

Write-Info "Ejecutando robocopy..."
$proc = Start-Process -FilePath "robocopy.exe" -ArgumentList $rcArgs -NoNewWindow -PassThru -Wait
$rc   = $proc.ExitCode
# Robocopy: 0..7 = OK, 8+ = error
if ($rc -ge 8) {
    Write-Err "Robocopy fallo con codigo $rc"
    Read-Host "Presione Enter"; exit 2
} else {
    Write-OK "Robocopy completo (codigo $rc, 0..7 = exito)"
}

# ----- PASO 2: actualizar raiz del pendrive con recuperador v2 ---------------
Write-Step 2 "Actualizando raiz del pendrive con recuperador v2"

$updRoot = Join-Path $repoRoot "ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1"
if (-not (Test-Path $updRoot)) {
    Write-Err "No existe $updRoot"
    Read-Host "Presione Enter"; exit 3
}

$letraDetectada = ($pendriveDir -split ':')[0]
& $updRoot -Letra $letraDetectada

# ----- PASO 3: validar sintaxis de los .ps1 del pendrive --------------------
Write-Step 3 "Validando sintaxis de .ps1 en el pendrive"

$ps1 = Get-ChildItem -Path $pendriveDir -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue
$badList = @()
foreach ($f in $ps1) {
    $errs = $null; $tk = $null
    [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tk, [ref]$errs) | Out-Null
    if ($errs -and $errs.Count -gt 0) {
        $badList += [PSCustomObject]@{
            Path   = $f.FullName.Replace($pendriveDir,"").TrimStart('\')
            Errors = $errs.Count
            FirstLine = $errs[0].Extent.StartLineNumber
        }
    }
}

if ($badList.Count -eq 0) {
    Write-OK ("Todos los .ps1 del pendrive parsean correctamente ({0} archivos)" -f $ps1.Count)
} else {
    Write-Err ("{0} archivo(s) con errores de sintaxis:" -f $badList.Count)
    $badList | Format-Table -AutoSize | Out-Host
    Write-Wrn "Estos scripts fallarian al ejecutarse en la PC limpia."
}

# ----- Resumen final --------------------------------------------------------
Write-Host ""
Write-Host "==============================================" -ForegroundColor Magenta
Write-Host "  SINCRONIZACION COMPLETADA                    " -ForegroundColor Magenta
Write-Host "==============================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Pendrive listo en: $pendriveDir" -ForegroundColor White
Write-Host ""
Write-Host "Proximos pasos:" -ForegroundColor Green
Write-Host "  1) Sacar el pendrive con seguridad."           -ForegroundColor White
Write-Host "  2) Probarlo en una PC limpia siguiendo el checklist." -ForegroundColor White
Write-Host ""

Read-Host "Presione Enter para cerrar"
