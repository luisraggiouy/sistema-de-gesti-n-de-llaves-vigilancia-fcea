# ============================================================
#  scripts\lib\lanzar_navegador.ps1
#  Abre Chrome (o Edge / navegador por defecto) en la URL que
#  corresponda segun rol/modo/hardware del config.json del FCEA.
#
#  Uso:
#    powershell -NoProfile -ExecutionPolicy Bypass `
#      -File scripts\lib\lanzar_navegador.ps1 `
#      -Rol monitor -Modo desarrollo -Hardware tradicional
#
#  Parametros opcionales: -BaseUrl http://127.0.0.1:5173
# ============================================================

[CmdletBinding()]
param(
  [string]$Rol      = 'monitor',
  [string]$Modo     = 'desarrollo',
  [string]$Hardware = 'tradicional',
  [string]$BaseUrl  = 'http://127.0.0.1:5173'
)

$ErrorActionPreference = 'Continue'

# ------------------------------------------------------------
# 1) Calcular URL final segun rol
# ------------------------------------------------------------
switch ($Rol.ToLower()) {
  'monitor' {
    if ($Modo -ieq 'produccion') { $url = "$BaseUrl/monitor" }
    else                         { $url = "$BaseUrl/" }
  }
  'terminal-a' { $url = "$BaseUrl/terminal?id=A" }
  'terminal-b' { $url = "$BaseUrl/terminal?id=B" }
  'dashboard'  { $url = "$BaseUrl/dashboard" }
  default      { $url = "$BaseUrl/" }
}

Write-Host "       URL final  : $url"

# ------------------------------------------------------------
# 2) Buscar navegador (Chrome primero, luego Edge)
# ------------------------------------------------------------
$candidatos = @(
  (Join-Path $env:ProgramFiles        'Google\Chrome\Application\chrome.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
  (Join-Path $env:LOCALAPPDATA        'Google\Chrome\Application\chrome.exe'),
  (Join-Path $env:ProgramFiles        'Microsoft\Edge\Application\msedge.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe')
)

$browser = $candidatos | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not $browser) {
  Write-Host "       [AVISO] No se encontro Chrome ni Edge. Usando navegador por defecto."
  try {
    Start-Process $url
  } catch {
    Write-Host "       [ERROR] No se pudo abrir el navegador por defecto: $($_.Exception.Message)"
    exit 1
  }
  exit 0
}

Write-Host "       Navegador  : $browser"

# ------------------------------------------------------------
# 3) Perfil de Chrome propio para el sistema
# ------------------------------------------------------------
$profileDir = Join-Path $env:LOCALAPPDATA 'sistema-llaves-fcea\chrome-profile'
if (-not (Test-Path $profileDir)) {
  New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
}

# ------------------------------------------------------------
# 4) Construir argumentos segun hardware/modo
# ------------------------------------------------------------
$chromeArgs = @(
  '--no-first-run',
  '--no-default-browser-check',
  '--disable-features=TranslateUI',
  ('--user-data-dir=' + $profileDir)
)

if ($Hardware -ieq 'tactil') {
  $chromeArgs += @(
    '--kiosk',
    '--disable-pinch',
    '--overscroll-history-navigation=0',
    '--touch-events=enabled'
  )
} elseif ($Modo -ieq 'produccion') {
  $chromeArgs += '--start-fullscreen'
} else {
  $chromeArgs += '--start-maximized'
}

$chromeArgs += $url

Write-Host "       Argumentos : $($chromeArgs -join ' ')"

# ------------------------------------------------------------
# 5) Lanzar
# ------------------------------------------------------------
try {
  Start-Process -FilePath $browser -ArgumentList $chromeArgs
  Write-Host "       Navegador lanzado correctamente."
  exit 0
} catch {
  Write-Host "       [ERROR] No se pudo lanzar el navegador con esos argumentos:"
  Write-Host "               $($_.Exception.Message)"
  Write-Host "       Reintentando con configuracion minima..."
  try {
    Start-Process -FilePath $browser -ArgumentList @(('--user-data-dir=' + $profileDir), $url)
    exit 0
  } catch {
    Write-Host "       [ERROR] Reintento fallido: $($_.Exception.Message)"
    Write-Host "       Abriendo con navegador por defecto..."
    Start-Process $url
    exit 1
  }
}
