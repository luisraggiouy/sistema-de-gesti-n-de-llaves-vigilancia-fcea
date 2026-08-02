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
#    REEMPLAZA a la vieja "defensa v2.8" (2026-07-23), que leia
#    pocketbase_url del config.json, sondeaba el puerto 8090 del
#    Monitor y redirigia el kiosko a http://IP_MONITOR:8090. Eso
#    estaba MAL en esta arquitectura: el 8090 del Monitor es
#    PocketBase SOLO-API y devuelve {"code":404,"message":"Not
#    Found."} para rutas SPA como /terminal?id=B -> la Terminal
#    "no levantaba" (mostraba el 404).
#
#    Realidad: CADA PC (Monitor, Terminal A y B) sirve su PROPIO
#    frontend en http://127.0.0.1:5173 (lo levanta INICIAR.bat /
#    run_frontend.bat sobre dist\). Los DATOS van al PocketBase del
#    Monitor y de eso se encarga la propia app leyendo
#    pocketbase_url de config.json. Por lo tanto el navegador debe
#    apuntar SIEMPRE al frontend LOCAL.
#
#    Probado con exito en Terminal B (2026-07-31): abre la Terminal,
#    identifica usuario, pide llave y aparece en el Monitor.
#
#    Si el llamador paso un -BaseUrl remoto (otra IP) o con puerto
#    8090, lo corregimos a 127.0.0.1:5173.
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
# ---
# Flags base (P4 - 2026-07-21):
# --disable-features acumula flags separadas por coma. Incluimos:
#   - TranslateUI             : evita el banner "traducir esta pagina"
#   - msEdgeSidebar           : oculta la Sidebar de Edge (Bing, apps).
#                               En Windows 11, tocar el borde derecho de
#                               la pantalla la desplegaba encima del kiosk,
#                               tapando la lista de solicitudes.
#   - msImplicitSignin        : evita el pop-up "usar cuenta Microsoft"
#                               que aparecia al primer arranque.
#   - msWebOOUI               : evita el "Out-of-box experience" de Edge
#                               que muestra tour de bienvenida al primer uso.
#   - CopilotEdge / EdgeCopilot : bota los distintos experimentos del
#                               boton flotante de Copilot en la topbar.
#   - SplitView / SidePanel   : cierra el panel lateral de recopilaciones/
#                               historial que a veces se abre solo si el
#                               vigilante toca el borde por accidente.
# Estos son "best effort": si en una version futura de Edge alguna flag
# ya no existe, simplemente se ignora, no rompe nada.
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
  # Bloqueos adicionales de Edge/Chrome que vienen como argumentos propios
  # (no como --disable-features):
  '--disable-sync',                    # sin sync de favoritos/historial (no hay cuenta)
  '--disable-background-networking',   # menos trafico saliente, util con red mala
  '--disable-component-update',        # no bajar componentes en pleno kiosk
  '--disable-domain-reliability',      # no reportar telemetria de dominio
  '--disable-breakpad',                # no envio de crash reports (offline)
  ('--user-data-dir=' + $profileDir)
)

# --- Decidir modo de ventana ---
#
# REGLA v2.5 (julio 2026):
#   En PRODUCCION las 3 PCs del sistema (Monitor Vigilancia + Terminal-A +
#   Terminal-B + Dashboard opcional) arrancan SIEMPRE en modo kiosk, sin
#   importar el hardware (tactil o tradicional con teclado+mouse). El
#   vigilante puede salir del kiosk con Alt+F4 cuando necesite hacer algo
#   en Windows, y volver al kiosk haciendo doble click en el icono
#   "abrir llaves FCEA modo kiosk" del escritorio (ver scripts\lib\
#   abrir_llaves_kiosk.bat).
#
#   Motivo del cambio: los usuarios finales no deben ver el escritorio de
#   Windows en ninguna de las 3 PCs. Antes solo terminales-tactil iban
#   en kiosk; el Monitor Vigilancia arrancaba maximizado (por lo que se
#   veia la barra de tareas). Ahora se unifica en kiosk para las 3.
#
# En DESARROLLO seguimos usando --start-maximized para no molestar al dev.
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
  # touch-events solo si el hardware realmente es tactil, para no forzar
  # eventos tactiles en PCs con monitor comun + mouse.
  if ($Hardware -ieq 'tactil') {
    $chromeArgs += '--touch-events=enabled'
  }
} elseif ($Modo -ieq 'produccion') {
  # Fallback defensivo: rol desconocido pero en produccion. No arriesgamos
  # kiosk (que ocultaria todo); mejor start-fullscreen para que el vigilante
  # vea que algo raro pasa y pueda diagnosticar.
  $chromeArgs += '--start-fullscreen'
} else {
  # Modo desarrollo: ventana normal maximizada, con acceso a devtools.
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
