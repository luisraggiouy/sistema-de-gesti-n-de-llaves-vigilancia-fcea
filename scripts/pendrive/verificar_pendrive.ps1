# Verifica el contenido de un pendrive instalador FCEA
param(
  [string]$Drive = "D:"
)
if ($Drive -notmatch "\\$") { $Drive = $Drive.TrimEnd(":") + ":\" }

Write-Host ""
Write-Host "=== Contenido VISIBLE de $Drive (lo que ve un usuario comun) ===" -ForegroundColor Cyan
Get-ChildItem $Drive -ErrorAction SilentlyContinue |
  Where-Object { -not ($_.Attributes -band [System.IO.FileAttributes]::Hidden) } |
  Select-Object Mode, @{N='SizeMB';E={if($_.PSIsContainer){''}else{[math]::Round($_.Length/1MB,2)}}}, LastWriteTime, Name |
  Format-Table -AutoSize

Write-Host ""
Write-Host "=== Contenido COMPLETO de $Drive (incluye ocultos) ===" -ForegroundColor Cyan
Get-ChildItem $Drive -Force -ErrorAction SilentlyContinue |
  Select-Object Mode, Attributes, @{N='SizeMB';E={if($_.PSIsContainer){''}else{[math]::Round($_.Length/1MB,2)}}}, LastWriteTime, Name |
  Format-Table -AutoSize

Write-Host ""
Write-Host "=== Verificaciones ===" -ForegroundColor Cyan

$dbPath = Join-Path $Drive "sistema-llaves-fcea\pocketbase\pb_data\data.db"
if (Test-Path $dbPath) {
  $i = Get-Item $dbPath -Force
  $mb = [math]::Round($i.Length/1MB,2)
  Write-Host "[OK] data.db = $mb MB - modificado $($i.LastWriteTime)" -ForegroundColor Green
} else {
  Write-Host "[FALTA] data.db NO existe en $dbPath" -ForegroundColor Red
}

$nodePath = Join-Path $Drive "node-portable\node\node.exe"
if (Test-Path $nodePath) {
  Write-Host "[OK] node-portable presente" -ForegroundColor Green
} else {
  Write-Host "[FALTA] node-portable NO existe" -ForegroundColor Red
}

$instPath = Join-Path $Drive "INSTALAR SISTEMA.bat"
if (Test-Path $instPath) {
  Write-Host "[OK] 'INSTALAR SISTEMA.bat' presente (visible)" -ForegroundColor Green
} else {
  Write-Host "[FALTA] 'INSTALAR SISTEMA.bat' NO existe" -ForegroundColor Red
}

$desPath = Join-Path $Drive "DESINSTALAR SISTEMA.bat"
if (Test-Path $desPath) {
  Write-Host "[OK] 'DESINSTALAR SISTEMA.bat' presente (visible)" -ForegroundColor Green
} else {
  Write-Host "[FALTA] 'DESINSTALAR SISTEMA.bat' NO existe" -ForegroundColor Red
}

# Verificar que los archivos auxiliares esten ocultos
Write-Host ""
Write-Host "=== Atributos de archivos auxiliares (deben ser HIDDEN) ===" -ForegroundColor Cyan
foreach ($n in @("sistema-llaves-fcea","node-portable","LEEME.txt","ULTIMO_BACKUP.txt","autorun.inf")) {
  $p = Join-Path $Drive $n
  if (Test-Path $p) {
    $it = Get-Item -LiteralPath $p -Force
    $isHidden = ($it.Attributes -band [System.IO.FileAttributes]::Hidden) -ne 0
    if ($isHidden) {
      Write-Host "[OK] $n -> oculto" -ForegroundColor Green
    } else {
      Write-Host "[AVISO] $n -> NO esta oculto (atributos: $($it.Attributes))" -ForegroundColor Yellow
    }
  } else {
    Write-Host "[N/A] $n -> no existe" -ForegroundColor Gray
  }
}

Write-Host ""
Write-Host "=== Tamano total del pendrive ===" -ForegroundColor Cyan
$size = (Get-ChildItem $Drive -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host ("Total: {0:N1} MB" -f $size)
