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
# 0) FRONTEND SIEMPRE LOCAL  (fix 2026-07-31)
#
#    En esta arquitectura CADA PC (Monitor, Terminal A y B) sirve
#    su PROPIO frontend en http://127.0.0.1:5173 (lo levanta
#    INICIAR.bat / run_frontend.bat sobre dist\). Los DATOS van al
#    PocketBase del Monitor (ej. 192.168.100.10:8090), y de eso se
#    encarga la propia app leyendo pocketbase_url de config.json.
#
#    El navegador NUNCA debe apuntarse al 8090 del Monitor: ese
#    puerto es SOLO-API y responde {"code":404,"message":"Not
#    Found."} para rutas SPA como /terminal?id=B.
#
#    La vieja "defensa v2.8" hacia justamente eso: leia
#    pocketbase_url, sondeaba el 8090 del Monitor y redirigia el
#    kiosko a http://IP_MONITOR:8090 -> 404. Ese era el bug que
#    dejaba "la Terminal sin levantar".
#
#    Por eso ahora forzamos SIEMPRE el frontend LOCAL. Si el
#    llamador paso un -BaseUrl remoto (otra IP) o con puerto 8090,
#    lo corregimos a 127.0.0.1:5173.
# ------------------------------------------------------------
$FRONTEND_LOCAL = 'http://127.0.0.1:5173'
try {
    $u = [Uri]$BaseUrl
    if ($u.Host -ne '127.0.0.1' -and $u.Host -ne 'localhost') {
        Write-Host "       [fix] BaseUrl remoto ($BaseUrl) -> forzando frontend local $FRONTEND_LOCAL"
        $BaseUrl = $FRONTEND_LOCAL
    } elseif ($u.Port -eq 8090) {
        Write-Host "       [fix] BaseUrl apuntaba al puerto 8090 (API) -> forzando $FRONTEND_LOCAL"
        $BaseUrl = $FRONTEND_LOCAL
    }
} catch {
    $BaseUrl = $FRONTEND_LOCAL
}

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
# 2) Buscar navegador (Edge primero: es el estandar en las PCs FCEA)
# ------------------------------------------------------------
$candidatos = @(
  (Join-Path $env:ProgramFiles        'Microsoft\Edge\Application\msedge.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
  (Join-Path $env:ProgramFiles        'Google\Chrome\Application\chrome.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
  (Join-Path $env:LOCALAPPDATA        'Google\Chrome\Application\chrome.exe')
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
# 3) Perfil dedicado del navegador (Edge/Chrome) para el sistema
# ------------------------------------------------------------
$profileDir = Join-Path $env:LOCALAPPDATA 'sistema-llaves-fcea\browser-profile'
if (-not (Test-Path $profileDir)) {
  New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
}

# ------------------------------------------------------------
# 4) Construir argumentos segun hardware/modo
# ------------------------------------------------------------
$disableFeatures = @(
  'TranslateUI',
  'msEdgeSidebar',
  'msImplicitSignin',
  'msWebOOUI',
  'CopilotEdge',
  'EdgeCopilot',
  'SplitView',
  'SidePanel',
  'msLinkedInFeature',
  'msLaunchCoachmarks'
) -join ','

$chromeArgs = @(
  '--no-first-run',
  '--no-default-browser-check',
  ('--disable-features=' + $disableFeatures),
  '--disable-sync',
  '--disable-background-networking',
  '--disable-component-update',
  '--disable-domain-reliability',
  '--disable-breakpad',
  ('--user-data-dir=' + $profileDir)
)

$esRolProduccionKiosk = ($Modo -ieq 'produccion') -and (
  $Rol -ieq 'monitor'    -or
  $Rol -ieq 'terminal-a' -or
  $Rol -ieq 'terminal-b' -or
  $Rol -ieq 'dashboard'
)

if ($esRolProduccionKiosk) {
  $chromeArgs += @(
    '--kiosk',
    '--disable-pinch',
    '--overscroll-history-navigation=0'
  )
  if ($Hardware -ieq 'tactil') {
    $chromeArgs += '--touch-events=enabled'
  }
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
