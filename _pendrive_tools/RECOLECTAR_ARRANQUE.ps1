# ============================================================
#  RECOLECTAR_ARRANQUE.ps1   (SOLO LECTURA - no modifica nada)
#  Caja de herramientas permanente FCEA
# ------------------------------------------------------------
#  Copia al pendrive los scripts REALES de arranque que hoy corren
#  en esta PC (INICIAR.bat, scripts\lib\*, scripts\maintenance\*),
#  ademas de los que contienen "DUENO-UNICO", y las colas de los logs.
#  Sirve para que en la laptop de desarrollo se vea EXACTAMENTE que
#  esta corriendo y construir el fix de raiz sin romper nada.
#
#  NO arranca, NO mata, NO borra, NO edita. Solo lee y copia.
# ============================================================

$ErrorActionPreference = 'Continue'

function Info($m){ Write-Host $m -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

Write-Host "==============================================================="
Write-Host "  RECOLECTAR ARRANQUE (solo lectura)"
Write-Host "==============================================================="

$INSTALL = 'C:\sistema-llaves-fcea'
if (-not (Test-Path $INSTALL)) {
  Warn "No encontre $INSTALL."
  $INSTALL = Read-Host "Escribi la ruta de instalacion (ej: C:\sistema-llaves-fcea)"
}
if (-not (Test-Path $INSTALL)) { Warn "No existe $INSTALL. Abortando."; Read-Host "ENTER"; exit 1 }

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$out = Join-Path $PSScriptRoot ("RECOLECTADO_ARRANQUE_" + $env:COMPUTERNAME + "_" + $stamp)
New-Item -ItemType Directory -Force -Path $out | Out-Null
Info "Guardando en: $out"

function Copia($rel) {
  $src = Join-Path $INSTALL $rel
  if (Test-Path $src) {
    $dstName = ($rel -replace '[\\/]', '__')
    Copy-Item $src (Join-Path $out $dstName) -Force -ErrorAction SilentlyContinue
    Ok "  copiado: $rel"
  } else {
    Warn "  (no existe): $rel"
  }
}

# 1) Scripts clave sueltos
Info "[1/4] Copiando scripts sueltos..."
Copia 'INICIAR.bat'
Copia 'INSTALAR.bat'
Copia 'DESINSTALAR.bat'
Copia 'config.json'
Copia 'public\config.json'

# 2) Carpetas de scripts (bat/ps1/cjs), SIN node_modules ni dist
Info "[2/4] Copiando scripts\lib y scripts\maintenance..."
foreach ($sub in @('scripts\lib','scripts\maintenance','scripts\install','scripts\recovery')) {
  $base = Join-Path $INSTALL $sub
  if (Test-Path $base) {
    Get-ChildItem $base -Recurse -Include *.bat,*.ps1,*.cjs,*.js -ErrorAction SilentlyContinue |
      Where-Object { -not $_.PSIsContainer -and $_.FullName -notmatch 'node_modules' } |
      ForEach-Object {
        $rel = $_.FullName.Substring($INSTALL.Length).TrimStart('\')
        $dstName = ($rel -replace '[\\/]', '__')
        Copy-Item $_.FullName (Join-Path $out $dstName) -Force -ErrorAction SilentlyContinue
      }
    Ok "  copiada carpeta: $sub"
  } else {
    Warn "  (no existe carpeta): $sub"
  }
}

# 3) Cazar TODO archivo que mencione DUENO-UNICO (por si esta en otro lado)
Info "[3/4] Buscando archivos con 'DUENO-UNICO'..."
try {
  $hits = Get-ChildItem $INSTALL -Recurse -Include *.bat,*.ps1,*.cmd -ErrorAction SilentlyContinue |
    Where-Object { -not $_.PSIsContainer -and $_.FullName -notmatch 'node_modules' } |
    Select-String -Pattern 'DUENO-UNICO' -List |
    Select-Object -ExpandProperty Path -Unique
  foreach ($h in $hits) {
    $rel = $h.Substring($INSTALL.Length).TrimStart('\')
    $dstName = 'DUENO__' + ($rel -replace '[\\/]', '__')
    Copy-Item $h (Join-Path $out $dstName) -Force -ErrorAction SilentlyContinue
    Ok "  con DUENO-UNICO: $rel"
  }
  if (-not $hits) { Warn "  Ninguno (raro; puede estar embebido en un .bat ya copiado)." }
} catch { Warn "  Error buscando DUENO-UNICO: $_" }

# 4) Colas de logs (ultimas 200 lineas)
Info "[4/4] Copiando colas de logs..."
$logs = @(
  'pocketbase\maintenance\logs\watchdog.log',
  'scripts\watchdog_completo.log',
  'pocketbase\pb_data\logs.db'  # solo referencia, no se lee
)
foreach ($lg in @('pocketbase\maintenance\logs\watchdog.log','scripts\watchdog_completo.log')) {
  $p = Join-Path $INSTALL $lg
  if (Test-Path $p) {
    $dstName = 'LOG__' + ($lg -replace '[\\/]', '__')
    try {
      Get-Content $p -Tail 200 -ErrorAction SilentlyContinue | Set-Content (Join-Path $out $dstName) -Encoding UTF8
      Ok "  cola de log: $lg"
    } catch { Warn "  no pude leer $lg (en uso)" }
  }
}

# Inventario
Get-ChildItem $out | Where-Object { -not $_.PSIsContainer } | Select-Object Name,Length | Out-File (Join-Path $out '_INVENTARIO.txt') -Encoding UTF8

Write-Host ""
Ok "LISTO. Se recolecto en:"
Write-Host "   $out"
Write-Host "Avisale a Cline el nombre de esa carpeta para que la lea."
Write-Host ""
Read-Host "Presiona ENTER para cerrar"
