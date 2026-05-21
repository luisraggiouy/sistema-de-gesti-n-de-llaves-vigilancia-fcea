# ============================================================
# Copia de directorios con BARRA DE PROGRESO REAL.
# ============================================================
# Uso:
#   .\copiar_con_progreso.ps1 -Origen "D:\sistema-llaves-fcea" `
#                             -Destino "C:\sistema-llaves-fcea" `
#                             -Etiqueta "Copiando sistema desde el pendrive"
#
# Implementacion:
#   1) Cuenta archivos del origen.
#   2) Recorre cada archivo con Copy-Item, actualizando Write-Progress
#      con cantidad copiada / total y % de avance.
#   3) Tambien escribe una barra ASCII en stdout para que se vea
#      desde la consola .bat aunque la ventana de progreso de
#      PowerShell se quede minimizada.
#
# Si Origen no existe, sale con codigo 1.
# Si la copia se completa sin errores, sale con codigo 0.
# ============================================================

param(
  [Parameter(Mandatory=$true)] [string]$Origen,
  [Parameter(Mandatory=$true)] [string]$Destino,
  [string]$Etiqueta = "Copiando archivos",
  [string[]]$Excluir = @()
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Origen)) {
  Write-Host "[ERROR] No existe el origen: $Origen" -ForegroundColor Red
  exit 1
}

# Asegurar destino
if (-not (Test-Path $Destino)) {
  New-Item -ItemType Directory -Force -Path $Destino | Out-Null
}

Write-Host ""
Write-Host "============================================================"
Write-Host " $Etiqueta"
Write-Host "============================================================"
Write-Host " Origen : $Origen"
Write-Host " Destino: $Destino"
Write-Host ""

# Conteo de archivos para la barra
Write-Host "Calculando archivos a copiar..." -NoNewline
$archivos = Get-ChildItem -Path $Origen -Recurse -File -Force -ErrorAction SilentlyContinue |
  Where-Object {
    $rel = $_.FullName.Substring($Origen.Length).TrimStart('\','/')
    $skip = $false
    foreach ($ex in $Excluir) {
      if ($rel -like "$ex*" -or $rel -like "*\$ex\*") { $skip = $true; break }
    }
    -not $skip
  }
$total = $archivos.Count
$totalSize = ($archivos | Measure-Object -Property Length -Sum).Sum
$totalMB = [math]::Round($totalSize / 1MB, 1)
Write-Host " $total archivos ($totalMB MB)"
Write-Host ""

if ($total -eq 0) {
  Write-Host "[AVISO] No hay archivos para copiar."
  exit 0
}

$copiados = 0
$bytesCopiados = [int64]0
$barWidth = 40
$inicio = Get-Date

foreach ($f in $archivos) {
  $rel = $f.FullName.Substring($Origen.Length).TrimStart('\','/')
  $destFile = Join-Path $Destino $rel
  $destDir = Split-Path $destFile -Parent
  if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  }

  try {
    Copy-Item -LiteralPath $f.FullName -Destination $destFile -Force
  } catch {
    Write-Host ""
    Write-Host "[AVISO] No se pudo copiar: $rel - $_" -ForegroundColor Yellow
  }

  $copiados++
  $bytesCopiados += $f.Length

  # Solo refrescar la barra cada N archivos (rendimiento)
  if (($copiados % 25) -eq 0 -or $copiados -eq $total) {
    $pct = [int](($copiados / $total) * 100)
    Write-Progress -Activity $Etiqueta `
                   -Status "$copiados / $total archivos  ($pct %)" `
                   -PercentComplete $pct

    # Barra ASCII para la ventana .bat (la mostramos sobre la misma linea)
    $filled = [int]($barWidth * $copiados / $total)
    $bar = ('#' * $filled) + ('-' * ($barWidth - $filled))
    $mbHechos = [math]::Round($bytesCopiados / 1MB, 1)
    $linea = ("`r [{0}] {1,3}%  {2}/{3} archivos  {4} / {5} MB" -f $bar, $pct, $copiados, $total, $mbHechos, $totalMB)
    [Console]::Write($linea)
  }
}

# Salto de linea final despues de la barra ASCII
Write-Host ""

$dur = (Get-Date) - $inicio
$durStr = "{0:mm\:ss}" -f $dur

Write-Progress -Activity $Etiqueta -Completed
Write-Host ""
Write-Host "[OK] $copiados archivos copiados ($totalMB MB) en $durStr." -ForegroundColor Green
exit 0
