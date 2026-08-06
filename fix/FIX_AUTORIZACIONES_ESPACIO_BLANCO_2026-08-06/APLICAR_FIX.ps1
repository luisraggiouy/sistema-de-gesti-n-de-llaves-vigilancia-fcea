# =============================================================
# APLICAR_FIX.ps1  -  FIX AUTORIZACIONES: ESPACIO EN BLANCO (2026-08-06)
#
# QUE ARREGLA:
#   En el Monitor Vigilancia -> Agenda / Autorizaciones -> pestanas
#   AUTORIZACIONES e HISTORIAL quedaba un gran ESPACIO EN BLANCO
#   entre las 3 pestanas (Contactos / Autorizaciones / Historial) y
#   el contenido (botones Verificar / Nueva, buscador y lista). El
#   contenido "flotaba" en la parte baja del modal.
#
#   Causa: la pestana Contactos usaba layout flex que llena el alto
#   del modal, pero Autorizaciones e Historial NO. Ahora las 3
#   pestanas usan el mismo layout (flex-col flex-1) y el contenido
#   arranca pegado debajo de las pestanas, sin hueco. La lista crece
#   para ocupar todo el alto disponible.
#
#   NOTA sobre "Verificar / Nueva": ambos botones SI tienen funcion.
#     - Verificar  = modo busqueda / verificacion de autorizaciones
#     - Nueva      = formulario para registrar una autorizacion nueva
#   Por eso NO se quitaron; solo se corrigio el espacio en blanco.
#
# POR QUE NO COMPILA EN PRODUCCION:
#   El node_modules de produccion tiene versiones incompatibles y un
#   build nuevo ahi rompe. Por eso este fix trae el dist YA COMPILADO
#   desde la laptop (con el fix) y lo instala, PRESERVANDO el
#   config.json y system_health.json propios de ESTA PC. La config es
#   100% runtime (fetch /config.json), asi que un unico dist sirve
#   para los 3 roles (Monitor, Terminal A y B).
#
# QUE HACE ESTE SCRIPT:
#   1) Verifica dist_nuevo (pendrive) e instalacion. Si falta algo,
#      ABORTA sin tocar nada.
#   2) Respalda el dist\ actual (rollback) y guarda config.json y
#      system_health.json de esta PC.
#   3) Reemplaza el contenido de dist\ por el dist_nuevo (fix).
#   4) Restaura config.json y system_health.json de esta PC.
#   5) (Consistencia) actualiza los fuentes AgendaModal.tsx y
#      AutorizacionesTab.tsx (con backup).
#   6) Reinicia el servidor de frontend (5173).
#   Si algo falla en el reemplazo, hace ROLLBACK del dist.
#
# NO toca PocketBase. NO toca la base de datos. NO compila. NO toca
# scripts criticos. Solo el frontend de ESTA PC. Rollback disponible.
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'APLICAR FIX AUTORIZACIONES (espacio en blanco) - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST      = Join-Path $INSTALL 'dist'
$INDEX     = Join-Path $DIST 'index.html'
$DISTNUEVO = Join-Path $PSScriptRoot 'dist_nuevo'
$RUNFRONT  = Join-Path $INSTALL 'scripts\lib\run_frontend.bat'
$SERVE     = Join-Path $INSTALL 'scripts\lib\serve_dist.cjs'
$DETACH    = Join-Path $INSTALL 'scripts\lib\start_detached.ps1'
$NODE_PORT = Join-Path $INSTALL 'node-portable\node\node.exe'
$STAMP     = (Get-Date -Format 'yyyy-MM-dd_HHmm')
$PC        = $env:COMPUTERNAME

# Fuentes que se actualizan (consistencia, NO se compila)
$FUENTES = @(
    @{ Nuevo = (Join-Path $PSScriptRoot 'AgendaModal.tsx');       Destino = (Join-Path $INSTALL 'src\components\monitor\AgendaModal.tsx') },
    @{ Nuevo = (Join-Path $PSScriptRoot 'AutorizacionesTab.tsx'); Destino = (Join-Path $INSTALL 'src\components\monitor\AutorizacionesTab.tsx') }
)

# Archivos per-PC que hay que PRESERVAR (no pisar con los de la laptop)
$PRESERVAR = @('config.json','system_health.json','config.schema.json')

# --- Log al pendrive (el pendrive es el "cable") ---
$logDir = Join-Path $PSScriptRoot '_RESULTADOS'
try { if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null } } catch {}
$LOG = Join-Path $logDir ("LOG_APLICAR_FIX_AUTORIZACIONES_{0}_{1}.log" -f $PC, $STAMP)
try { Start-Transcript -Path $LOG -Force | Out-Null } catch {}

function Line { param($c='='); Write-Host ($c * 62) -ForegroundColor Yellow }
function Header { param($t); Line; Write-Host "  $t" -ForegroundColor Yellow; Line }
function Sub { param($t); Write-Host ""; Write-Host "--- $t ---" -ForegroundColor Cyan }
function Fin { param($code); Write-Host ""; Write-Host "Log guardado en: $LOG" -ForegroundColor Gray; try { Stop-Transcript | Out-Null } catch {}; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray; [void][System.Console]::ReadLine(); exit $code }

Header "APLICAR FIX AUTORIZACIONES (espacio en blanco) - $PC - $STAMP"

# ---------------------------------------------------------------
# 1) VERIFICACIONES
# ---------------------------------------------------------------
Sub "[1] Verificaciones previas"
$okDistNuevo = Test-Path (Join-Path $DISTNUEVO 'index.html')
$okDist      = Test-Path $INDEX
Write-Host ("  dist_nuevo\index.html (pendrive) : {0}" -f $(if($okDistNuevo){'[OK]'}else{'[FALTA] '+$DISTNUEVO}))
Write-Host ("  dist\index.html (instalado)      : {0}" -f $(if($okDist){'[OK]'}else{'[FALTA] '+$DIST}))

if (-not $okDistNuevo) { Write-Host "`n  [ABORTA] No encuentro dist_nuevo\index.html junto a este script." -ForegroundColor Red; Fin 1 }
if (-not $okDist)      { Write-Host "`n  [ABORTA] No existe la instalacion (dist\) en esta PC." -ForegroundColor Red; Fin 1 }

# ---------------------------------------------------------------
# 2) BACKUP + preservar archivos per-PC
# ---------------------------------------------------------------
Sub "[2] Respaldo del dist actual + preservar config"
$bakDist = Join-Path $INSTALL "dist_bak_$STAMP"
try {
    Copy-Item $DIST $bakDist -Recurse -Force
    Write-Host "  [OK] Backup del dist -> $bakDist" -ForegroundColor Green
} catch {
    Write-Host ("  [ABORTA] No pude respaldar dist\: {0}" -f $_.Exception.Message) -ForegroundColor Red; Fin 1
}

$tmpPreserva = Join-Path $env:TEMP ("fcea_preserva_$STAMP")
New-Item -ItemType Directory -Force -Path $tmpPreserva | Out-Null
foreach ($f in $PRESERVAR) {
    $src = Join-Path $DIST $f
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $tmpPreserva $f) -Force
        Write-Host "  [OK] Preservado de esta PC: $f" -ForegroundColor Green
    }
}

# ---------------------------------------------------------------
# 3) REEMPLAZAR dist por dist_nuevo (mirror)
# ---------------------------------------------------------------
Sub "[3] Instalando el dist nuevo (con el fix)"
robocopy $DISTNUEVO $DIST /MIR /NFL /NDL /NJH /NP | Out-Null
$rc = $LASTEXITCODE
if ($rc -ge 8) {
    Write-Host "`n  [FALLO] robocopy fallo (codigo $rc). Haciendo ROLLBACK del dist..." -ForegroundColor Red
    try { Remove-Item $DIST -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Copy-Item $bakDist $DIST -Recurse -Force
    Write-Host "  [OK] dist restaurado del backup. Sistema como estaba antes." -ForegroundColor Green
    Fin 1
}
Write-Host "  [OK] dist nuevo instalado (robocopy codigo $rc)." -ForegroundColor Green

# ---------------------------------------------------------------
# 4) RESTAURAR archivos per-PC
# ---------------------------------------------------------------
Sub "[4] Restaurando config.json / system_health.json de esta PC"
foreach ($f in $PRESERVAR) {
    $tmp = Join-Path $tmpPreserva $f
    if (Test-Path $tmp) {
        Copy-Item $tmp (Join-Path $DIST $f) -Force
        Write-Host "  [OK] Restaurado: $f" -ForegroundColor Green
    }
}
# Verificacion critica: que quedo un config.json valido
if (-not (Test-Path (Join-Path $DIST 'config.json'))) {
    Write-Host "  [AVISO] No hay config.json en dist tras restaurar. Restaurando dist del backup por seguridad." -ForegroundColor Red
    try { Remove-Item $DIST -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    Copy-Item $bakDist $DIST -Recurse -Force
    Write-Host "  [OK] dist restaurado del backup." -ForegroundColor Green
    Fin 1
}

# ---------------------------------------------------------------
# 5) (Consistencia) actualizar los fuentes .tsx  -  NO se compila
# ---------------------------------------------------------------
Sub "[5] Actualizando los fuentes (consistencia, no se compila)"
foreach ($fu in $FUENTES) {
    if ((Test-Path $fu.Nuevo) -and (Test-Path $fu.Destino)) {
        try {
            Copy-Item $fu.Destino ("{0}.bak_{1}" -f $fu.Destino, $STAMP) -Force
            Copy-Item $fu.Nuevo $fu.Destino -Force
            Write-Host ("  [OK] Actualizado: {0} (backup .bak_{1})" -f (Split-Path $fu.Destino -Leaf), $STAMP) -ForegroundColor Green
        } catch {
            Write-Host ("  [WARN] No pude actualizar {0} (no afecta el fix): {1}" -f (Split-Path $fu.Destino -Leaf), $_.Exception.Message) -ForegroundColor Yellow
        }
    } else {
        Write-Host ("  [INFO] Se omite {0} (no es critico para el fix)." -f (Split-Path $fu.Destino -Leaf)) -ForegroundColor Gray
    }
}

# ---------------------------------------------------------------
# 6) REINICIAR EL FRONTEND (5173)
# ---------------------------------------------------------------
Sub "[6] Reiniciando el servidor de frontend (5173)"
if (Test-Path $NODE_PORT) { $env:PATH = (Split-Path $NODE_PORT -Parent) + ';' + $env:PATH }
try {
    Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
      Where-Object { $_.CommandLine -match 'vite' -or $_.CommandLine -match 'serve_dist' -or $_.CommandLine -match '5173' } |
      ForEach-Object { Write-Host ("  Cerrando node PID {0} (frontend)" -f $_.ProcessId); Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
} catch {}
Start-Sleep -Seconds 2

$relaunched = $false
if ((Test-Path $RUNFRONT) -and (Test-Path $DETACH)) {
    try {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $DETACH -CommandLine "cmd /c `"$RUNFRONT`"" -WorkingDirectory $INSTALL
        $relaunched = $true
        Write-Host "  [OK] Frontend relanzado (run_frontend.bat desacoplado)." -ForegroundColor Green
    } catch { Write-Host ("  [WARN] {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}
if (-not $relaunched -and (Test-Path $SERVE) -and (Test-Path $NODE_PORT)) {
    try {
        Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', "node `"$SERVE`" 5173 `"$DIST`"" -WorkingDirectory $INSTALL -WindowStyle Minimized
        $relaunched = $true
        Write-Host "  [OK] Frontend relanzado (serve_dist.cjs)." -ForegroundColor Green
    } catch { Write-Host ("  [WARN] {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}
if (-not $relaunched) {
    Write-Host "  [AVISO] No pude relanzar el frontend automaticamente." -ForegroundColor Yellow
    Write-Host "  Reinicia la PC (arranca solo) o abri el kiosko del escritorio." -ForegroundColor Yellow
}

# Limpieza temp
try { Remove-Item $tmpPreserva -Recurse -Force -ErrorAction SilentlyContinue } catch {}

# ---------------------------------------------------------------
# 7) RESUMEN
# ---------------------------------------------------------------
Sub "[7] RESUMEN"
Line
Write-Host "  FIX APLICADO en $PC (sin compilar)" -ForegroundColor Green
Write-Host "  - dist backup : $bakDist" -ForegroundColor Gray
Write-Host ""
Write-Host "  PROBAR AHORA:" -ForegroundColor Cyan
Write-Host "   1) CERRA y volve a abrir el kiosko (o Ctrl+F5) para cargar el dist nuevo." -ForegroundColor Cyan
Write-Host "   2) Monitor -> abri 'Agenda / Autorizaciones'." -ForegroundColor Cyan
Write-Host "   3) Entra a la pestana AUTORIZACIONES: el contenido debe quedar" -ForegroundColor Cyan
Write-Host "      pegado debajo de las pestanas (SIN el espacio en blanco de antes)." -ForegroundColor Cyan
Write-Host "   4) Idem en la pestana HISTORIAL." -ForegroundColor Cyan
Line
Write-Host ""
Write-Host "  ROLLBACK manual si hiciera falta:" -ForegroundColor Gray
Write-Host "   Borra $DIST y renombra $bakDist a dist. Reinicia la PC." -ForegroundColor Gray
Fin 0
