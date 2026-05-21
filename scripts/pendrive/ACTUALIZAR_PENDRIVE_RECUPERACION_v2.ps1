# ============================================================================
# ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1
# ----------------------------------------------------------------------------
# Refresca el pendrive de recuperacion SIN tener que grabarlo de cero.
# Solo copia los archivos del repo que pueden haber cambiado:
#   - scripts/recovery/*
#   - scripts/lib/*
#   - scripts/install/*  (por si tambien se actualiza el instalador)
#   - pocketbase/pb_migrations/*
#   - frontend/dist (build fresca)         [opcional, con -SkipFrontend]
# NO copia: node-portable, pocketbase.exe (pesados, rara vez cambian)
#   - excepto si se pasa -FullRefresh
#
# Detecta automaticamente el pendrive buscando un marker
# .FCEA_PENDRIVE_RECUPERACION en la raiz de cualquier letra montada.
# Si no encuentra, pide la letra al usuario.
#
# Uso tipico:
#   .\ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1
#   .\ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1 -Drive E:
#   .\ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1 -SkipFrontend
#   .\ACTUALIZAR_PENDRIVE_RECUPERACION_v2.ps1 -FullRefresh
# ============================================================================

[CmdletBinding()]
param(
    [string]$Drive,
    [switch]$SkipFrontend,
    [switch]$FullRefresh,
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = 'Stop'

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
$REPO_ROOT  = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)  # ../..

$MARKER_NAME = ".FCEA_PENDRIVE_RECUPERACION"

function Find-PendriveDrive {
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object {
        $_.Root -match '^[A-Z]:\\$' -and $_.Used -ge 0
    }
    foreach ($d in $drives) {
        $marker = Join-Path $d.Root $MARKER_NAME
        if (Test-Path -LiteralPath $marker) {
            return $d.Root
        }
    }
    return $null
}

function Normalize-DriveRoot {
    param([string]$D)
    if (-not $D) { return $null }
    $D = $D.TrimEnd('\').TrimEnd(':')
    return "$D`:\"
}

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Copy-Tree {
    param([string]$Source, [string]$Dest, [string[]]$Exclude = @())
    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Host "  [SKIP] No existe origen: $Source" -ForegroundColor DarkGray
        return
    }
    Ensure-Dir -Path $Dest
    # robocopy es mucho mas rapido que Copy-Item para muchos archivos
    $excludeArgs = @()
    foreach ($e in $Exclude) {
        $excludeArgs += @("/XD", $e)
    }
    $args = @($Source, $Dest, "/MIR", "/NFL", "/NDL", "/NJH", "/NJS", "/NP", "/R:1", "/W:1") + $excludeArgs
    & robocopy @args | Out-Null
    # robocopy devuelve >=8 si hubo error
    if ($LASTEXITCODE -ge 8) {
        throw "robocopy fallo copiando $Source -> $Dest (exit $LASTEXITCODE)"
    }
}

function Build-Frontend {
    Write-Host ""
    Write-Host "  Construyendo build fresca del frontend..." -ForegroundColor Cyan
    Push-Location $REPO_ROOT
    try {
        if (-not (Test-Path "node_modules")) {
            Write-Host "    -> npm install (primera vez)..." -ForegroundColor DarkGray
            & npm install --no-audit --no-fund | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "npm install fallo" }
        }
        & npm run build
        if ($LASTEXITCODE -ne 0) { throw "npm run build fallo" }
        $dist = Join-Path $REPO_ROOT "dist"
        if (-not (Test-Path $dist)) { throw "No se genero la carpeta dist/" }
        return $dist
    } finally {
        Pop-Location
    }
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
Clear-Host
Write-Host ""
Write-Host "  ===========================================================" -ForegroundColor Cyan
Write-Host "    ACTUALIZAR PENDRIVE DE RECUPERACION FCEA  (v2)"            -ForegroundColor White
Write-Host "  ===========================================================" -ForegroundColor Cyan
Write-Host ""

# 1) Detectar/validar drive
if (-not $Drive) {
    $Drive = Find-PendriveDrive
    if ($Drive) {
        Write-Host "  Pendrive detectado automaticamente: $Drive" -ForegroundColor Green
    } else {
        Write-Host "  No se detecto pendrive con marker $MARKER_NAME" -ForegroundColor Yellow
        $Drive = Read-Host "  Ingresa la letra del pendrive (ej. E)"
        $Drive = Normalize-DriveRoot $Drive
    }
} else {
    $Drive = Normalize-DriveRoot $Drive
}

if (-not (Test-Path -LiteralPath $Drive)) {
    Write-Host "  [ERROR] La unidad $Drive no existe." -ForegroundColor Red
    exit 1
}

# 2) Crear marker si no existe
$marker = Join-Path $Drive $MARKER_NAME
if (-not (Test-Path -LiteralPath $marker)) {
    "" | Out-File -FilePath $marker -Encoding ASCII -Force
    attrib +h $marker 2>$null
    Write-Host "  Marker creado: $marker" -ForegroundColor DarkGray
}

# 3) Directorios destino dentro del pendrive
$ROOT_PEN  = Join-Path $Drive "sistema-llaves-fcea"
$SCRIPTS_PEN = Join-Path $ROOT_PEN "scripts"
$PB_PEN      = Join-Path $ROOT_PEN "pocketbase"
$FRONT_PEN   = Join-Path $ROOT_PEN "frontend\dist"

Write-Host ""
Write-Host "  Destino base: $ROOT_PEN" -ForegroundColor White
Write-Host ""

# 4) Sincronizar scripts (recovery, lib, install, pendrive, maintenance)
Write-Host "  [1/5] Copiando scripts/recovery ..." -ForegroundColor White
Copy-Tree -Source (Join-Path $REPO_ROOT "scripts\recovery") -Dest (Join-Path $SCRIPTS_PEN "recovery")

Write-Host "  [2/5] Copiando scripts/lib ..." -ForegroundColor White
Copy-Tree -Source (Join-Path $REPO_ROOT "scripts\lib") -Dest (Join-Path $SCRIPTS_PEN "lib")

Write-Host "  [3/5] Copiando scripts/install y scripts/maintenance ..." -ForegroundColor White
Copy-Tree -Source (Join-Path $REPO_ROOT "scripts\install")     -Dest (Join-Path $SCRIPTS_PEN "install")
Copy-Tree -Source (Join-Path $REPO_ROOT "scripts\maintenance") -Dest (Join-Path $SCRIPTS_PEN "maintenance")

# 5) Migraciones de PocketBase
Write-Host "  [4/5] Copiando migraciones de PocketBase ..." -ForegroundColor White
Copy-Tree -Source (Join-Path $REPO_ROOT "pocketbase\pb_migrations") -Dest (Join-Path $PB_PEN "pb_migrations")

# 6) (opcional) build frontend
if ($SkipFrontend) {
    Write-Host "  [5/5] Frontend: omitido (-SkipFrontend)" -ForegroundColor DarkGray
} else {
    try {
        $dist = Build-Frontend
        Write-Host "  [5/5] Copiando frontend/dist ..." -ForegroundColor White
        Copy-Tree -Source $dist -Dest $FRONT_PEN
    } catch {
        Write-Host "  [AVISO] No se pudo actualizar el frontend: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 7) Refresh completo (pesado) si se pide
if ($FullRefresh) {
    Write-Host ""
    Write-Host "  [EXTRA] FullRefresh: copiando node-portable y pocketbase.exe ..." -ForegroundColor Yellow
    $nodeSrc = Join-Path $REPO_ROOT "node-portable"
    if (Test-Path $nodeSrc) {
        Copy-Tree -Source $nodeSrc -Dest (Join-Path $Drive "node-portable")
    }
    $pbExeSrc = Join-Path $REPO_ROOT "pocketbase\pocketbase.exe"
    if (Test-Path $pbExeSrc) {
        Ensure-Dir -Path $PB_PEN
        Copy-Item -Path $pbExeSrc -Destination (Join-Path $PB_PEN "pocketbase.exe") -Force
    }
}

# 8) Escribir version.txt y LEEME
$verFile = Join-Path $ROOT_PEN "version.txt"
@"
Pendrive de recuperacion FCEA
version: $Version
fecha:   $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
host:    $env:COMPUTERNAME / $env:USERNAME
"@ | Out-File -FilePath $verFile -Encoding UTF8 -Force

$leeme = Join-Path $Drive "LEEME_RECUPERACION.txt"
@"
PENDRIVE DE RECUPERACION - Sistema de Llaves FCEA
====================================================
Para recuperar el sistema:

  1) Conectar este pendrive a la PC con problemas
  2) Abrir la carpeta sistema-llaves-fcea\scripts\recovery
  3) Doble click en RECUPERAR_v2.bat
  4) Aceptar el cartel de Administrador

El script va a diagnosticar todo y te va a ofrecer
unicamente las acciones de reparacion que hagan falta.

Version del pendrive: $Version
Actualizado: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@ | Out-File -FilePath $leeme -Encoding UTF8 -Force

Write-Host ""
Write-Host "  ===========================================================" -ForegroundColor Green
Write-Host "    PENDRIVE ACTUALIZADO CORRECTAMENTE"                       -ForegroundColor Green
Write-Host "  ===========================================================" -ForegroundColor Green
Write-Host "    Drive: $Drive"
Write-Host "    Version escrita: $Version"
if ($SkipFrontend) { Write-Host "    Frontend: NO actualizado (use -SkipFrontend)" -ForegroundColor Yellow }
if ($FullRefresh)  { Write-Host "    FullRefresh activo: incluye node-portable y pocketbase.exe" }
Write-Host ""
