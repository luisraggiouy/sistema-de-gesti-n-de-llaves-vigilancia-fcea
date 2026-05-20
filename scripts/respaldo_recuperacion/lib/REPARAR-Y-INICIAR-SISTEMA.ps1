# =====================================================================
#  REPARAR Y INICIAR SISTEMA DE LLAVES FCEA  (v2.0 - mayo 2026)
# ---------------------------------------------------------------------
#  Para usar cuando el sistema YA esta instalado en la PC pero no
#  arranca, o el navegador no abre, o algo falla. NO reinstala todo,
#  solo arregla lo justo y necesario para que vuelva a funcionar:
#    - Verifica que PocketBase corra (lo levanta si no).
#    - Verifica que el frontend este escuchando en :8080.
#    - Lee install_config.json (modo + hardware) si existe.
#    - Abre Chrome en kiosk con la URL/monitor correcto para esa PC.
#
#  Si el sistema NO esta instalado, hay que usar REINSTALAR-COMPLETO.
# =====================================================================

$ErrorActionPreference = "Continue"
$Host.UI.RawUI.WindowTitle = "REPARAR Y INICIAR SISTEMA DE LLAVES FCEA"

# ---------------------------------------------------------------------
# Helpers de presentacion (mismos que usa REINSTALAR)
# ---------------------------------------------------------------------
function Write-Titulo($texto) {
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Magenta
    Write-Host " $texto" -ForegroundColor Magenta
    Write-Host "=====================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Paso   ($n,$t)  { Write-Host ""; Write-Host "[$n] $t" -ForegroundColor Yellow }
function Write-OK     ($t)     { Write-Host "    [OK] $t" -ForegroundColor Green }
function Write-Aviso  ($t)     { Write-Host "    [!]  $t" -ForegroundColor Yellow }
function Write-Error2 ($t)     { Write-Host "    [ERROR] $t" -ForegroundColor Red }

# ---------------------------------------------------------------------
# Rutas
# ---------------------------------------------------------------------
# IMPORTANTE: $PSCommandPath puede llegar vacio si el .bat invoca con
# `& 'ruta\script.ps1'` desde -Command. Usamos fallback robusto.
$thisScriptPath = $PSCommandPath
if ([string]::IsNullOrWhiteSpace($thisScriptPath)) { $thisScriptPath = $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($thisScriptPath) -and $PSScriptRoot) { $thisScriptPath = Join-Path $PSScriptRoot "_dummy.ps1" }
# $PENDRIVE_DIR  = carpeta lib\ donde vive ESTE script
# $PENDRIVE_ROOT = raiz del pendrive (un nivel arriba)
$PENDRIVE_DIR  = if ($thisScriptPath) { Split-Path -Parent $thisScriptPath } else { Get-Location }
$PENDRIVE_ROOT = Split-Path -Parent $PENDRIVE_DIR

$LIB_DIR_LOCAL = $PENDRIVE_DIR
# Cuando se ejecuta DESDE LA RAIZ DEL PENDRIVE, $PENDRIVE_ROOT termina siendo
# "E:\" y Split-Path -Parent "E:\" devuelve cadena vacia, lo que rompe el
# Join-Path siguiente. Protegemos ese caso.
$_parentRoot = Split-Path -Parent $PENDRIVE_ROOT
if ([string]::IsNullOrWhiteSpace($_parentRoot)) {
    $LIB_DIR_REPO = $LIB_DIR_LOCAL
} else {
    $LIB_DIR_REPO = Join-Path $_parentRoot "lib"  # cuando se ejecuta desde el repo
}

$SISTEMA_DIR_NUEVO = "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
$SISTEMA_DIR_VIEJO = "C:\sistema-llaves-fcea"
$SISTEMA_DIR = if (Test-Path $SISTEMA_DIR_NUEVO) { $SISTEMA_DIR_NUEVO }
               elseif (Test-Path $SISTEMA_DIR_VIEJO) { $SISTEMA_DIR_VIEJO }
               else { $null }

$LOG_FILE = Join-Path $PENDRIVE_ROOT "ultimo_log_reparacion.txt"
"=== REPARACION INICIADA $(Get-Date) ===" | Out-File -FilePath $LOG_FILE -Encoding UTF8
function Log($texto) {
    "$(Get-Date -Format 'HH:mm:ss') $texto" | Out-File -FilePath $LOG_FILE -Append -Encoding UTF8
}

# ---------------------------------------------------------------------
# Cargar librerias opcionales (las mismas que usa REINSTALAR)
# IMPORTANTE: NO encapsular `. $p` en una funcion: las funciones cargadas
# dentro de una funcion solo viven en su scope local y se pierden al
# retornar. Hay que hacer el dot-source en el scope del script.
# ---------------------------------------------------------------------
$libsCargadas = $false
$libsRequeridas = @('detectar_hardware.ps1','install_config_io.ps1','abrir_chrome_kiosk.ps1')
foreach ($candidato in @($LIB_DIR_LOCAL, $LIB_DIR_REPO)) {
    if (-not (Test-Path $candidato)) { continue }
    Log "Probando cargar libs desde: $candidato"
    $todasOk = $true
    foreach ($lib in $libsRequeridas) {
        $p = Join-Path $candidato $lib
        if (Test-Path $p) {
            try { . $p; Log "  Cargada: $lib" }
            catch { Log "  ERROR cargando $lib : $_"; $todasOk = $false }
        } else {
            Log "  NO existe: $p"
            $todasOk = $false
        }
    }
    if ($todasOk) {
        # Verificacion explicita: que la funcion clave este realmente disponible
        if (Get-Command Get-DeteccionHardwareCompleta -ErrorAction SilentlyContinue) {
            $libsCargadas = $true
            Log "Librerias cargadas OK desde $candidato"
            break
        } else {
            Log "WARNING: dot-source no fallo pero Get-DeteccionHardwareCompleta no esta disponible"
        }
    }
}
if (-not $libsCargadas) {
    Write-Aviso "Librerias auxiliares no encontradas - modo simple."
    Log "WARNING: Librerias auxiliares no encontradas"
}

# =====================================================================
# INICIO DEL FLUJO
# =====================================================================
try {
    Clear-Host
    Write-Titulo "REPARAR E INICIAR SISTEMA DE LLAVES FCEA  v2.0"
    Write-Host " Esta opcion NO reinstala. Solo arregla lo que este parado." -ForegroundColor White
    Write-Host ""
    Write-Host " Pendrive: $PENDRIVE_ROOT" -ForegroundColor Gray
    if ($SISTEMA_DIR) {
        Write-Host " Sistema instalado en: $SISTEMA_DIR" -ForegroundColor Gray
    } else {
        Write-Host " Sistema instalado en: (no detectado)" -ForegroundColor Red
    }
    Write-Host ""

    # =================================================================
    # PASO 1: Verificar que el sistema este instalado
    # =================================================================
    Write-Paso "1/5" "Verificando instalacion existente..."
    if (-not $SISTEMA_DIR) {
        Write-Error2 "No se detecto ninguna instalacion del sistema en C:\."
        Write-Host ""
        Write-Host "  Use la opcion 'REINSTALAR-COMPLETO' del pendrive en lugar de esta." -ForegroundColor Yellow
        return
    }
    if (-not (Test-Path "$SISTEMA_DIR\pocketbase\pocketbase.exe")) {
        Write-Error2 "Falta $SISTEMA_DIR\pocketbase\pocketbase.exe - instalacion corrupta."
        Write-Host "  Use 'REINSTALAR-COMPLETO' para repararlo." -ForegroundColor Yellow
        return
    }
    if (-not (Test-Path "$SISTEMA_DIR\node_modules")) {
        Write-Error2 "Falta carpeta node_modules - hay que reinstalar dependencias."
        Write-Host "  Use 'REINSTALAR-COMPLETO' para repararlo." -ForegroundColor Yellow
        return
    }
    Write-OK "Instalacion detectada"

    # =================================================================
    # PASO 2: Verificar / iniciar PocketBase
    # =================================================================
    Write-Paso "2/5" "Verificando PocketBase..."
    $pbCorriendo = $false
    try {
        $r = Invoke-WebRequest -Uri "http://127.0.0.1:8090/api/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
        if ($r.StatusCode -eq 200) { $pbCorriendo = $true }
    } catch { }

    if ($pbCorriendo) {
        Write-OK "PocketBase ya estaba corriendo"
    } else {
        Write-Host "    PocketBase no responde, levantandolo..." -ForegroundColor Gray
        Start-Process -FilePath "$SISTEMA_DIR\pocketbase\pocketbase.exe" `
            -ArgumentList "serve","--http=127.0.0.1:8090" `
            -WorkingDirectory "$SISTEMA_DIR\pocketbase" -WindowStyle Minimized
        Start-Sleep -Seconds 4
        for ($i = 1; $i -le 10; $i++) {
            try {
                $r = Invoke-WebRequest -Uri "http://127.0.0.1:8090/api/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
                if ($r.StatusCode -eq 200) { $pbCorriendo = $true; break }
            } catch { }
            Start-Sleep -Seconds 1
        }
        if ($pbCorriendo) { Write-OK "PocketBase iniciado" }
        else { Write-Aviso "PocketBase no responde aun - se intentara igual" }
    }

    # =================================================================
    # PASO 3: Verificar / iniciar frontend
    # =================================================================
    Write-Paso "3/5" "Verificando frontend (puerto 8080)..."
    $feCorriendo = $false
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:8080/" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
        if ($r.StatusCode -eq 200) { $feCorriendo = $true }
    } catch { }

    if ($feCorriendo) {
        Write-OK "Frontend ya respondia"
    } else {
        $usaDist = Test-Path "$SISTEMA_DIR\dist\assets"
        if ($usaDist) {
            $cmdArgs = "/k cd /d `"$SISTEMA_DIR`" && npm run preview -- --port 8080 --host"
            Write-Host "    Lanzando frontend en modo PREVIEW (build dist/)..." -ForegroundColor Gray
        } else {
            $cmdArgs = "/k cd /d `"$SISTEMA_DIR`" && npm run dev -- --port 8080 --host"
            Write-Host "    Lanzando frontend en modo DEV (sin build)..." -ForegroundColor Gray
        }
        Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -WindowStyle Normal

        Write-Host "    Esperando que conteste 200 (puede tardar 30-90s)..." -ForegroundColor Gray
        $tIni = Get-Date
        for ($i = 1; $i -le 40; $i++) {
            Start-Sleep -Seconds 3
            try {
                $r = Invoke-WebRequest -Uri "http://localhost:8080/" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
                if ($r.StatusCode -eq 200) { $feCorriendo = $true; break }
            } catch { }
            $segs = [int]((Get-Date) - $tIni).TotalSeconds
            Write-Host ("    ... esperando frontend ({0}s)" -f $segs) -ForegroundColor DarkCyan
        }
        if ($feCorriendo) { Write-OK "Frontend listo" }
        else { Write-Aviso "Frontend tardo mas de lo esperado" }
    }

    # =================================================================
    # PASO 4: Leer install_config y abrir Chrome
    # =================================================================
    Write-Paso "4/5" "Leyendo configuracion (modo / hardware)..."
    $configActiva = $null
    if ($libsCargadas) {
        try {
            $previa = Get-InstallConfigSmart
            if ($previa) {
                $configActiva = $previa.config
                Write-OK ("Config detectada (origen: {0})" -f $previa.origen)
                Show-InstallConfigResumen -Config $configActiva
            }
        } catch { Log "Error leyendo config: $_" }
    }

    Write-Paso "5/5" "Abriendo el sistema en cada monitor..."
    if ($libsCargadas -and $configActiva -and $configActiva.monitores -and $configActiva.monitores.asignacion) {
        # Cerrar instancias previas de Chrome kiosk antes de abrir las nuevas
        try { Stop-ChromeKioskInstancias } catch { }
        Open-SistemaEnMonitores -Config $configActiva -BaseUrl "http://localhost:8080"
        Write-OK "Ventanas abiertas segun configuracion"
    } else {
        # Fallback simple: abrir monitor + terminal en navegador disponible
        $browsers = @(
            "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
            "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
            "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
        )
        $br = $null; foreach ($b in $browsers) { if (Test-Path $b) { $br = $b; break } }
        if ($br) {
            Start-Process $br -ArgumentList "--new-window","http://localhost:8080/monitor"
            Start-Sleep 2
            Start-Process $br -ArgumentList "http://localhost:8080/terminal"
        } else {
            Start-Process "http://localhost:8080/monitor"
            Start-Sleep 2
            Start-Process "http://localhost:8080/terminal"
        }
        Write-OK "Navegador abierto (modo simple)"
    }

    Write-Titulo "REPARACION COMPLETADA"
    Write-Host " Monitor  : http://localhost:8080/monitor"   -ForegroundColor White
    Write-Host " Terminal : http://localhost:8080/terminal"  -ForegroundColor White
    Write-Host " Dashboard: http://localhost:8080/dashboard" -ForegroundColor White
    Write-Host ""
    Write-Host " IMPORTANTE: NO cierre la ventana cmd.exe del frontend." -ForegroundColor Yellow
    Log "Reparacion finalizada OK"

} catch {
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Red
    Write-Host " ERROR EN LA REPARACION" -ForegroundColor Red
    Write-Host "=====================================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Log "ERROR: $($_.Exception.Message)"
    Log $_.ScriptStackTrace
}

# Final: NO cerrar solo. Esperar Enter del usuario.
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " Presione Enter para cerrar esta ventana (el sistema" -ForegroundColor Cyan
Write-Host " seguira corriendo en segundo plano)." -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
try { [void](Read-Host) } catch { }
