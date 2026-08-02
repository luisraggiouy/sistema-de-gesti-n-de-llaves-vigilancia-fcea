# ============================================================
#  FIX KIOSK 404 (Monitor Vigilancia) - 2026-08-02
# ------------------------------------------------------------
#  Problema:
#    Al cerrar el kiosk con Alt+F4 y reabrir con el icono del
#    escritorio "abrir llaves FCEA modo kiosk", el navegador
#    mostraba {"code":404,"message":"Not Found.","data":{}} en
#    vez del sistema. Ese 404 es PocketBase (puerto 8090)
#    respondiendo en su raiz -> el launcher/acceso directo del
#    Monitor era una version VIEJA (pre 2026-07-31) que abria el
#    8090 en vez del frontend local 5173.
#
#  Solucion (este fix):
#    1) Copia las versiones CORRECTAS de:
#         - scripts\lib\abrir_llaves_kiosk.bat
#         - scripts\lib\lanzar_navegador.ps1
#       (ambas fuerzan SIEMPRE el frontend local http://127.0.0.1:5173)
#    2) Rehace el acceso directo del escritorio
#       "abrir llaves FCEA modo kiosk" para que apunte al .bat
#       correcto (minimizado).
#
#  Es idempotente y de bajo riesgo: solo toca esos 2 archivos y
#  el acceso directo; NO toca datos, PocketBase ni config.json.
# ============================================================

$ErrorActionPreference = 'Stop'

function Log($msg) { Write-Host "  $msg" }

$InstallDir = 'C:\sistema-llaves-fcea'
$LibDir     = Join-Path $InstallDir 'scripts\lib'
$OrigenDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host ''
Write-Host ' ============================================================'
Write-Host '  FIX KIOSK 404 (Monitor) - abrir siempre el frontend 5173'
Write-Host ' ============================================================'
Write-Host ''

# --- Validaciones ---
if (-not (Test-Path $InstallDir)) {
  Write-Host "  [ERROR] No existe $InstallDir. El sistema no esta instalado aqui." -ForegroundColor Red
  exit 1
}
if (-not (Test-Path $LibDir)) {
  New-Item -ItemType Directory -Force -Path $LibDir | Out-Null
}

# --- 1) Copiar los 2 archivos correctos ---
$archivos = @('abrir_llaves_kiosk.bat', 'lanzar_navegador.ps1')
foreach ($a in $archivos) {
  $src = Join-Path $OrigenDir $a
  $dst = Join-Path $LibDir $a
  if (-not (Test-Path $src)) {
    Write-Host "  [ERROR] No se encontro el archivo de origen: $src" -ForegroundColor Red
    exit 1
  }
  Copy-Item $src $dst -Force
  Log "[OK] Copiado: $a -> $dst"
}

# --- 2) Rehacer el acceso directo del escritorio ---
$batTarget = Join-Path $LibDir 'abrir_llaves_kiosk.bat'
$nombreLnk = 'abrir llaves FCEA modo kiosk.lnk'

# Escritorios candidatos: usuario actual + publico (para que lo vea cualquier login)
$desktops = @(
  [Environment]::GetFolderPath('Desktop'),
  (Join-Path $env:PUBLIC 'Desktop')
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

$wsh = New-Object -ComObject WScript.Shell

foreach ($d in $desktops) {
  $lnkPath = Join-Path $d $nombreLnk
  try {
    $sc = $wsh.CreateShortcut($lnkPath)
    $sc.TargetPath       = $batTarget
    $sc.WorkingDirectory = $InstallDir
    $sc.WindowStyle      = 7            # 7 = minimizado
    $sc.Description       = 'Abrir Llaves FCEA en modo kiosk (frontend local 5173)'
    # Icono: usa Edge si esta, si no deja el default del .bat
    $edge = @(
      (Join-Path $env:ProgramFiles        'Microsoft\Edge\Application\msedge.exe'),
      (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe')
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($edge) { $sc.IconLocation = "$edge,0" }
    $sc.Save()
    Log "[OK] Acceso directo actualizado: $lnkPath"
  } catch {
    Log "[AVISO] No se pudo actualizar el acceso directo en $d : $($_.Exception.Message)"
  }
}

Write-Host ''
Write-Host ' ============================================================'
Write-Host '  [LISTO] Fix aplicado.'
Write-Host ' ============================================================'
Write-Host '   Ahora el icono "abrir llaves FCEA modo kiosk" abre SIEMPRE'
Write-Host '   el frontend local http://127.0.0.1:5173 (no el 8090).'
Write-Host ''
Write-Host '   PRUEBA: cerra el kiosk con Alt+F4 y volve a abrirlo con el'
Write-Host '   icono del escritorio. Debe cargar el sistema, no un 404.'
Write-Host ''
exit 0
