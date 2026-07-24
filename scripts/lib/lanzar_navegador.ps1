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
# 0) Defensa v2.8 (2026-07-23) contra ERR_CONNECTION_REFUSED
#    en Terminal A/B en modo kiosk.
#
#    Si el llamador NO pasa -BaseUrl explicito (o pasa exactamente
#    el default 'http://127.0.0.1:5173'), intentamos releer el
#    servidor real desde config.json. Esta es defensa en profundidad:
#    el .bat wrapper (abrir_llaves_kiosk.bat) ya calcula BaseUrl y
#    la pasa, pero si algun launcher legacy invoca este script sin
#    -BaseUrl, el default 127.0.0.1:5173 solo funciona en el Monitor
#    (que corre el server) y rompe en las Terminales (solo consumen
#    el server remoto del Monitor).
# ------------------------------------------------------------
$defaultBaseUrl = 'http://127.0.0.1:5173'
if ($BaseUrl -eq $defaultBaseUrl) {
    $cfgCandidatos = @(
        'C:\sistema-llaves-fcea\dist\config.json',
        'C:\sistema-llaves-fcea\public\config.json'
    )
    $cfg = $null
    foreach ($c in $cfgCandidatos) {
        if (Test-Path $c) {
            try {
                $cfg = Get-Content $c -Raw | ConvertFrom-Json
                break
            } catch { }
        }
    }
    if ($cfg) {
        $host2 = $null
        if ($cfg.pocketbase_url) {
            try { $host2 = ([Uri]$cfg.pocketbase_url).Host } catch { }
        }
        if (-not $host2 -and $cfg.red -and $cfg.red.ip_servidor) {
            $host2 = $cfg.red.ip_servidor
        }
        if ($host2 -and $host2 -ne '127.0.0.1') {
            # Elegir puerto: probamos 8090 (PB sirviendo dist), 5173 (Vite dev).
            $puertoElegido = $null
            foreach ($p in 8090, 5173) {
                try {
                    $tcp = New-Object Net.Sockets.TcpClient
                    $ar = $tcp.BeginConnect($host2, $p, $null, $null)
                    if ($ar.AsyncWaitHandle.WaitOne(500)) {
                        $tcp.EndConnect($ar); $puertoElegido = $p; $tcp.Close(); break
                    }
                    $tcp.Close()
                } catch { }
            }
            if (-not $puertoElegido) { $puertoElegido = 8090 }
            $BaseUrl = "http://${host2}:${puertoElegido}"
            Write-Host "       [v2.8] BaseUrl auto-detectada desde config.json: $BaseUrl"
        }
    }
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
