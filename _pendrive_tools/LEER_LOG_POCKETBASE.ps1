# ============================================================
#  LEER_LOG_POCKETBASE.ps1   (SOLO LECTURA - no toca nada)
#  Muestra el final del log de PocketBase para ver el ERROR REAL
#  que aparece cuando arranca en el boot y no puede escribir.
#  Sistema FCEA - Monitor Vigilancia
# ============================================================
$ErrorActionPreference = 'Continue'
$desktopLog = Join-Path ([Environment]::GetFolderPath('Desktop')) 'LOG_POCKETBASE_CAPTURA.txt'
Start-Transcript -Path $desktopLog -Force | Out-Null

function Sec($m){ Write-Host ""; Write-Host ("===== " + $m + " =====") -ForegroundColor Cyan }

# Posibles ubicaciones del log que genera run_pocketbase.bat / start-server.bat
$candidatos = @(
  'C:\sistema-llaves-fcea\logs\pocketbase.log',
  'C:\sistema-llaves-fcea\pocketbase\logs\pocketbase.log',
  'C:\sistema-llaves-fcea\pocketbase\maintenance\logs\watchdog.log'
)

foreach ($f in $candidatos) {
  Sec ("Archivo: " + $f)
  if (Test-Path $f) {
    $i = Get-Item $f
    Write-Host ("  Tamano: {0:N0} bytes   Ultima mod: {1}" -f $i.Length, $i.LastWriteTime) -ForegroundColor Gray
    Write-Host "  ---- ULTIMAS 60 LINEAS ----" -ForegroundColor Yellow
    Get-Content $f -Tail 60 | ForEach-Object { Write-Host $_ }
    Write-Host "  ---- FIN ----" -ForegroundColor Yellow
  } else {
    Write-Host "  (no existe)" -ForegroundColor DarkGray
  }
}

# Buscar lineas con palabras clave de error en el log principal
Sec "Lineas con posibles ERRORES (locked / readonly / I/O / migration / SQLITE)"
$main = $candidatos | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($main) {
  $hits = Select-String -Path $main -Pattern 'locked|readonly|read-only|I/O|disk|migration|error|panic|SQLITE|failed' -SimpleMatch:$false -ErrorAction SilentlyContinue |
          Select-Object -Last 25
  if ($hits) { $hits | ForEach-Object { Write-Host ("  " + $_.Line) -ForegroundColor Red } }
  else { Write-Host "  (sin coincidencias de error en el log principal)" -ForegroundColor Green }
} else {
  Write-Host "  (no encontre log principal)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Sacale FOTO a TODO, o mandame el archivo del Escritorio: LOG_POCKETBASE_CAPTURA.txt" -ForegroundColor Cyan
Stop-Transcript | Out-Null
Write-Host ""
Read-Host "Presiona ENTER para cerrar"
