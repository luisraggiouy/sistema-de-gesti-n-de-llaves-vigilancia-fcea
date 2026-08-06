# ============================================================
#  APLICAR_UPGRADE.ps1  -  Instala el Splash de Arranque FCEA
#  (Monitor Vigilancia). ADITIVO y REVERSIBLE.
#
#  Que hace (y SOLO esto):
#   1) Copia splash_arranque.ps1 + SPLASH_ARRANQUE.vbs a
#        C:\sistema-llaves-fcea\scripts\lib\splash\
#      (si ya existian, guarda copia .bak con fecha).
#   2) Crea un acceso directo en la carpeta INICIO de Windows:
#        FCEA_Splash_Arranque.lnk  ->  wscript.exe "...\SPLASH_ARRANQUE.vbs"
#      Asi el cartel aparece SOLO al iniciar sesion, en paralelo,
#      SIN tocar el arranque actual (orquestador, PocketBase, config).
#
#  NO modifica PocketBase, ni la base, ni INICIAR.bat, ni tareas.
#  Rollback: correr QUITAR_UPGRADE.bat (borra el .lnk y la carpeta splash).
# ============================================================
$ErrorActionPreference = 'Stop'

function Ok($m){ Write-Host "  [OK] $m" -ForegroundColor Green }
function Info($m){ Write-Host $m }
function Err($m){ Write-Host "  [ERROR] $m" -ForegroundColor Red }

$origen = $PSScriptRoot
$destino = 'C:\sistema-llaves-fcea\scripts\lib\splash'
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'

Write-Host ""
Write-Host "=== Instalando Splash de Arranque FCEA (aditivo) ===" -ForegroundColor Cyan
Write-Host ""

try {
  if (-not (Test-Path 'C:\sistema-llaves-fcea')) {
    Err "No existe C:\sistema-llaves-fcea . Este upgrade es para el Monitor Vigilancia."
    Read-Host "ENTER para cerrar"; exit 1
  }

  if (-not (Test-Path $destino)) { New-Item -ItemType Directory -Path $destino -Force | Out-Null }
  Ok "Carpeta destino: $destino"

  foreach ($f in @('splash_arranque.ps1','SPLASH_ARRANQUE.vbs')) {
    $src = Join-Path $origen $f
    $dst = Join-Path $destino $f
    if (-not (Test-Path $src)) { Err "No encuentro $f en el pendrive."; Read-Host "ENTER"; exit 1 }
    if (Test-Path $dst) { Copy-Item $dst "$dst.bak_$stamp" -Force; Info "  (respaldo previo: $dst.bak_$stamp)" }
    Copy-Item $src $dst -Force
    Ok "Copiado: $f"
  }

  # --- Acceso directo en la carpeta Inicio del usuario ---
  $startup = [Environment]::GetFolderPath('Startup')
  $lnk = Join-Path $startup 'FCEA_Splash_Arranque.lnk'
  $vbs = Join-Path $destino 'SPLASH_ARRANQUE.vbs'
  $wsh = New-Object -ComObject WScript.Shell
  $sc  = $wsh.CreateShortcut($lnk)
  $sc.TargetPath       = "$env:SystemRoot\System32\wscript.exe"
  $sc.Arguments        = '"' + $vbs + '"'
  $sc.WorkingDirectory = $destino
  $sc.WindowStyle      = 7
  $sc.Description       = 'Cartel de espera de arranque - Sistema Llaves FCEA'
  $sc.Save()
  Ok "Acceso directo creado en Inicio: $lnk"

  Write-Host ""
  Write-Host "=== LISTO ===" -ForegroundColor Green
  Write-Host " El cartel de espera aparecera en el PROXIMO reinicio (o cierre/inicio de sesion)." -ForegroundColor Green
  Write-Host " Para verlo YA sin reiniciar, podes ejecutar:" -ForegroundColor Gray
  Write-Host "   $vbs" -ForegroundColor Yellow
  Write-Host " Para DESINSTALAR: ejecutar QUITAR_UPGRADE.bat" -ForegroundColor Gray
  Write-Host ""
}
catch {
  Err $_.Exception.Message
}
Read-Host "Presiona ENTER para cerrar"
