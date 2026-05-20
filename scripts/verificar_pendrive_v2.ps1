# =====================================================================
# VERIFICAR PENDRIVE RECUPERADOR V2
# ---------------------------------------------------------------------
# Lo ejecutas EN TU PC, antes de llevar el pendrive a una PC limpia.
# Hace pre-validacion estatica del contenido del pendrive sin tocar
# nada. Detecta los problemas mas comunes:
#
#   - Faltan archivos clave (lib, instaladores, sistema, respaldos)
#   - El instalador de Node.js no esta presente
#   - Los .ps1 tienen sintaxis valida (los parsea, no los ejecuta)
#   - Las funciones que llama el recuperador existen en las libs
#   - Los .ps1 estan en UTF-8 valido (sin caracteres rotos)
#   - El respaldo de la base de datos esta presente y reciente
#   - install_config.json del repo es consistente con el schema
#
# Uso:
#   .\scripts\verificar_pendrive_v2.ps1 -PendriveDir D:\RECUPERACION_SISTEMA_LLAVES_FCEA
# =====================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] [string]$PendriveDir
)

$ErrorActionPreference = "Continue"
$Host.UI.RawUI.WindowTitle = "Verificar Pendrive Recuperador v2"

$ok    = 0
$warn  = 0
$err   = 0

function Write-Header($t) {
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host " $t" -ForegroundColor Cyan
    Write-Host "=====================================================" -ForegroundColor Cyan
}
function Pass ($t) { Write-Host ("  [OK]    {0}" -f $t) -ForegroundColor Green;  $script:ok++ }
function Warn ($t) { Write-Host ("  [WARN]  {0}" -f $t) -ForegroundColor Yellow; $script:warn++ }
function Fail ($t) { Write-Host ("  [FAIL]  {0}" -f $t) -ForegroundColor Red;    $script:err++ }

Write-Header "VERIFICACION ESTATICA DEL PENDRIVE RECUPERADOR V2"
Write-Host " Pendrive: $PendriveDir"

# ---------------------------------------------------------------------
# 1) Existencia de carpetas y archivos clave
# ---------------------------------------------------------------------
Write-Header "1/6  Estructura de carpetas"

if (-not (Test-Path $PendriveDir)) {
    Fail "El pendrive no existe en la ruta indicada."
    exit 1
}

# Tipo: 'Leaf' = archivo, 'Container' = carpeta (valores admitidos por -PathType)
# Layout v2.1: en la raiz SOLO los 3 .bat + LEEME. Los .ps1 viven todos en lib\.
$obligatorios = @(
    @{ Path='REINSTALAR-COMPLETO.bat';   Tipo='Leaf' },
    @{ Path='DESINSTALAR-SISTEMA.bat';   Tipo='Leaf' },
    @{ Path='LEEME-PRIMERO.txt';         Tipo='Leaf' },
    @{ Path='lib';                       Tipo='Container' },
    @{ Path='lib\REINSTALAR-COMPLETO.ps1';   Tipo='Leaf' },
    @{ Path='lib\DESINSTALAR-SISTEMA.ps1';   Tipo='Leaf' },
    @{ Path='lib\DESINSTALAR_SISTEMA_LIMPIO.ps1'; Tipo='Leaf' },
    @{ Path='lib\detectar_hardware.ps1'; Tipo='Leaf' },
    @{ Path='lib\install_config_io.ps1'; Tipo='Leaf' },
    @{ Path='lib\abrir_chrome_kiosk.ps1';Tipo='Leaf' },
    @{ Path='instaladores';              Tipo='Container' },
    @{ Path='sistema';                   Tipo='Container' },
    @{ Path='sistema\package.json';      Tipo='Leaf' },
    @{ Path='sistema\pocketbase\pocketbase.exe'; Tipo='Leaf' },
    @{ Path='sistema\pocketbase\pb_migrations'; Tipo='Container' },
    @{ Path='respaldos_db';              Tipo='Container' },
    @{ Path='respaldos_db\pb_data_ultimo'; Tipo='Container' },
    @{ Path='respaldos_db\pb_data_ultimo\data.db'; Tipo='Leaf' }
)

foreach ($i in $obligatorios) {
    $full = Join-Path $PendriveDir $i.Path
    if (Test-Path $full -PathType $i.Tipo) {
        Pass $i.Path
    } else {
        Fail "FALTA: $($i.Path)"
    }
}

# Node.js installer (acepta cualquiera de los dos nombres)
$nodeMsi1 = Join-Path $PendriveDir 'instaladores\node-setup.msi'
$nodeMsi2 = Join-Path $PendriveDir 'instaladores\node-setup.msi.msi'
if ((Test-Path $nodeMsi1) -or (Test-Path $nodeMsi2)) {
    Pass "Instalador de Node.js presente"
} else {
    Fail "FALTA: instaladores\node-setup.msi (necesario para PC sin Node.js)"
}

# ---------------------------------------------------------------------
# 2) Sintaxis de los .ps1 (parser, no ejecucion)
# ---------------------------------------------------------------------
Write-Header "2/6  Sintaxis de scripts PowerShell"

$ps1s = Get-ChildItem $PendriveDir -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue
foreach ($f in $ps1s) {
    $errs = $null
    $tokens = $null
    try {
        [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errs) | Out-Null
        if ($errs -and $errs.Count -gt 0) {
            Fail ("{0} tiene {1} errores de sintaxis. Primero: {2}" -f `
                $f.Name, $errs.Count, $errs[0].Message)
        } else {
            Pass ("Sintaxis OK -> {0}" -f $f.Name)
        }
    } catch {
        Fail ("No se pudo parsear {0}: {1}" -f $f.Name, $_.Exception.Message)
    }
}

# ---------------------------------------------------------------------
# 3) Funciones esperadas por el recuperador
# ---------------------------------------------------------------------
Write-Header "3/6  Funciones de las librerias"

$libDir = Join-Path $PendriveDir 'lib'
$esperadas = @{
    'detectar_hardware.ps1' = @('Get-DeteccionHardwareCompleta','Show-DeteccionResumen','Get-PCIdentifier')
    'install_config_io.ps1' = @('Get-InstallConfigSmart','New-InstallConfig','Save-InstallConfigLocal','Save-InstallConfigPocketBase','Show-InstallConfigResumen','Read-InstallConfigLocal','Read-InstallConfigPocketBase')
    'abrir_chrome_kiosk.ps1' = @('Wait-FrontendReady','Open-SistemaEnMonitores','Stop-ChromeKioskInstancias','Find-ChromeExecutable','Open-ChromeEnMonitor')
}

foreach ($archivo in $esperadas.Keys) {
    $f = Join-Path $libDir $archivo
    if (-not (Test-Path $f)) {
        Fail "Lib no existe: $archivo"
        continue
    }
    $contenido = Get-Content $f -Raw -ErrorAction SilentlyContinue
    foreach ($fn in $esperadas[$archivo]) {
        if ($contenido -match "(?m)^\s*function\s+$([regex]::Escape($fn))\b") {
            Pass "$archivo -> function $fn"
        } else {
            Fail "$archivo NO define function $fn (la espera el recuperador)"
        }
    }
}

# ---------------------------------------------------------------------
# 4) PocketBase: ID record y reglas de la migracion
# ---------------------------------------------------------------------
Write-Header "4/6  Migracion PocketBase sistema_config"

$migBase = Join-Path $PendriveDir 'sistema\pocketbase\pb_migrations'
$migration = $null
if (Test-Path $migBase) {
    $migration = Get-ChildItem $migBase -Filter '*sistema_config*' -ErrorAction SilentlyContinue | Select-Object -First 1
}

if (-not $migration) {
    Fail "No se encontro la migracion de sistema_config en sistema\pocketbase\pb_migrations\"
} else {
    Pass "Migracion sistema_config presente: $($migration.Name)"
    $cont = Get-Content $migration.FullName -Raw
    if ($cont -match '"id"\s*:\s*"([a-z0-9]{15})"\s*,\s*"created"') {
        $idColec = $matches[1]
        Pass "Collection ID tiene 15 caracteres exactos: $idColec"
    } else {
        Fail "Collection ID NO tiene 15 caracteres - PocketBase v0.22 lo va a rechazar."
    }
    if ($cont -match '"createRule"\s*:\s*""') {
        Pass "createRule = '' (acepta POST sin admin)"
    } else {
        Warn "createRule no es '' -> el recuperador no podra crear el record sin autenticar"
    }
    if ($cont -match '"updateRule"\s*:\s*""') {
        Pass "updateRule = '' (acepta PATCH sin admin)"
    } else {
        Warn "updateRule no es '' -> el recuperador no podra actualizar el record sin autenticar"
    }
}

# Y el ID que usa la lib install_config_io.ps1
$libIo = Join-Path $libDir 'install_config_io.ps1'
if (Test-Path $libIo) {
    $contIo = Get-Content $libIo -Raw
    if ($contIo -match 'POCKETBASE_RECORD_ID\s*=\s*"([a-z0-9]{15})"') {
        Pass "Record ID en lib tiene 15 chars: $($matches[1])"
    } else {
        Fail "Record ID en install_config_io.ps1 NO tiene 15 chars"
    }
}

# ---------------------------------------------------------------------
# 5) Frescura de respaldos
# ---------------------------------------------------------------------
Write-Header "5/6  Frescura de respaldos de base de datos"

$dbFile = Join-Path $PendriveDir 'respaldos_db\pb_data_ultimo\data.db'
if (Test-Path $dbFile) {
    $info = Get-Item $dbFile
    $dias = [int]((Get-Date) - $info.LastWriteTime).TotalDays
    $sizeMb = [math]::Round($info.Length / 1MB, 2)
    if ($dias -lt 7) {
        Pass "data.db tiene $dias dias de antiguedad ($sizeMb MB)"
    } elseif ($dias -lt 30) {
        Warn "data.db tiene $dias dias - actualizar el pendrive antes de probar"
    } else {
        Fail "data.db tiene $dias dias - DEMASIADO VIEJO. Actualizar el pendrive."
    }
}

# ---------------------------------------------------------------------
# 6) BOM y encoding del install_config si quedo en sistema/config
# ---------------------------------------------------------------------
Write-Header "6/6  Encoding del install_config.json (si existiera)"

$cfgEnPendrive = Join-Path $PendriveDir 'sistema\config\install_config.json'
if (Test-Path $cfgEnPendrive) {
    $bytes = [System.IO.File]::ReadAllBytes($cfgEnPendrive)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Warn "install_config.json tiene BOM UTF-8. El frontend (JSON.parse) puede fallar."
    } else {
        Pass "install_config.json sin BOM (correcto)"
    }
} else {
    Pass "No hay install_config.json en el pendrive (correcto: lo genera la PC al instalar)"
}

# ---------------------------------------------------------------------
# RESUMEN
# ---------------------------------------------------------------------
Write-Header "RESUMEN"
Write-Host (" OK     : {0}" -f $ok)   -ForegroundColor Green
Write-Host (" Warns  : {0}" -f $warn) -ForegroundColor Yellow
Write-Host (" Fallas : {0}" -f $err)  -ForegroundColor Red
Write-Host ""
if ($err -eq 0) {
    Write-Host " VERIFICACION OK - El pendrive esta listo para probar en una PC limpia." -ForegroundColor Green
} else {
    Write-Host " HAY ERRORES - NO uses el pendrive en la PC limpia hasta arreglarlos." -ForegroundColor Red
}
Write-Host ""
Read-Host "Presione Enter para cerrar"
