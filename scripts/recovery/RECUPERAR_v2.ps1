# ============================================================================
# RECUPERAR_v2.ps1  -  Recuperador inteligente del sistema FCEA
# ----------------------------------------------------------------------------
# Flujo:
#   1) Lee install_config.json (o lo recupera desde PocketBase, o pregunta)
#   2) Ejecuta un diagnostico silencioso de todos los componentes
#   3) Muestra una tabla de resultados (verde / amarillo / rojo) - sin
#      lineas rojas crudas de errores: TODO esta envuelto en try/catch y
#      lo crudo va al log
#   4) Ofrece un menu con solo las acciones relevantes a los fallos
#      detectados
#
# Convencion clave para NO mostrar lineas rojas:
#   $ErrorActionPreference = 'Stop' + try/catch en cada bloque
#   + Write-Host con color amarillo en lugar de Write-Error
# ============================================================================

[CmdletBinding()]
param(
    [switch]$NoMenu,           # solo diagnostico, no muestra menu
    [string]$PbUrl = "http://localhost:8090"
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
$REPO_ROOT  = Split-Path -Parent $SCRIPT_DIR
$LIB_DIR    = Join-Path $REPO_ROOT "lib"

# Cargar librerias compartidas
. (Join-Path $LIB_DIR "detectar_hardware.ps1")
. (Join-Path $LIB_DIR "install_config_io.ps1")

$INSTALL_BASE   = "C:\sistema-llaves-fcea"
$LOG_DIR        = Join-Path $INSTALL_BASE "logs"
$LOG_FILE       = Join-Path $LOG_DIR ("recuperar_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")

if (-not (Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
}

function Log {
    param([string]$Msg, [string]$Level = "INFO")
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "HH:mm:ss"), $Level, $Msg
    Add-Content -Path $LOG_FILE -Value $line -Encoding UTF8
}

function Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host (" " + $Title)      -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

function Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "      RECUPERADOR DEL SISTEMA DE LLAVES - FCEA  (v2)" -ForegroundColor White
    Write-Host "  ============================================================" -ForegroundColor Cyan
    Write-Host "      Log de esta sesion: $LOG_FILE" -ForegroundColor DarkGray
    Write-Host ""
}

# ---------------------------------------------------------------------------
# 1) Resolver install_config (local -> PB -> preguntar al usuario)
# ---------------------------------------------------------------------------
function Resolve-InstallConfig {
    Write-Host "  [1/3] Leyendo configuracion de instalacion..." -ForegroundColor White

    $cfg = Read-InstallConfig
    if ($cfg) {
        Write-Host "        OK - install_config.json local" -ForegroundColor Green
        Log "install_config leido desde disco. modo=$($cfg.modo) hw=$($cfg.hardware)"
        return $cfg
    }

    Write-Host "        No hay install_config local. Intento desde PocketBase..." -ForegroundColor Yellow
    $cfg = Restore-InstallConfigFromPocketBase -PbUrl $PbUrl
    if ($cfg) {
        Write-Host "        OK - restaurado desde PocketBase" -ForegroundColor Green
        Write-InstallConfig -Config $cfg | Out-Null
        Log "install_config restaurado desde PB y guardado en disco."
        return $cfg
    }

    Write-Host "        Tampoco hay en PocketBase. Voy a preguntarte." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Modo de instalacion:"
    Write-Host "    [P] Produccion"
    Write-Host "    [D] Desarrollo"
    $modo = Read-Host "  Eleccion (P/D)"
    $modoStr = if ($modo -match '^[Dd]') { 'desarrollo' } else { 'produccion' }

    Write-Host ""
    Write-Host "  Tipo de hardware:"
    Write-Host "    [T] Tactil (kiosk fullscreen)"
    Write-Host "    [R] Tradicional (PC de oficina)"
    $hw = Read-Host "  Eleccion (T/R)"
    $hwStr = if ($hw -match '^[Tt]') { 'tactil' } else { 'tradicional' }
    if ($modoStr -eq 'desarrollo') { $hwStr = 'desarrollo' }

    $snap = Get-HardwareSnapshot
    $cfg  = New-InstallConfig -Modo $modoStr -Hardware $hwStr -HardwareSnapshot $snap
    Write-InstallConfig -Config $cfg | Out-Null
    Sync-InstallConfigToPocketBase -Config $cfg -PbUrl $PbUrl | Out-Null
    Log "install_config creado interactivamente. modo=$modoStr hw=$hwStr"
    return $cfg
}

# ---------------------------------------------------------------------------
# 2) Diagnostico
# ---------------------------------------------------------------------------
function Invoke-Diagnostico {
    param([PSObject]$Cfg)
    $r = [ordered]@{}

    # A) Carpeta base
    try {
        $r["base_dir"] = if (Test-Path $INSTALL_BASE) { "ok" } else { "fail" }
    } catch { $r["base_dir"] = "fail"; Log $_.Exception.Message "ERR" }

    # B) PocketBase exe presente
    try {
        $pbExe = Join-Path $INSTALL_BASE "pocketbase\pocketbase.exe"
        $r["pb_exe"] = if (Test-Path $pbExe) { "ok" } else { "fail" }
    } catch { $r["pb_exe"] = "fail"; Log $_.Exception.Message "ERR" }

    # C) PocketBase respondiendo
    try {
        $alive = Test-PocketBaseAlive -PbUrl $PbUrl
        $r["pb_running"] = if ($alive) { "ok" } else { "fail" }
    } catch { $r["pb_running"] = "fail"; Log $_.Exception.Message "ERR" }

    # D) Frontend dist
    try {
        $dist = Join-Path $INSTALL_BASE "frontend\dist\index.html"
        $r["frontend"] = if (Test-Path $dist) { "ok" } else { "fail" }
    } catch { $r["frontend"] = "fail"; Log $_.Exception.Message "ERR" }

    # E) Node portable
    try {
        $node = Join-Path $INSTALL_BASE "node-portable\node\node.exe"
        $r["node"] = if (Test-Path $node) { "ok" } else { "fail" }
    } catch { $r["node"] = "fail"; Log $_.Exception.Message "ERR" }

    # F) Tareas programadas
    try {
        $tareas = @("FCEA_Watchdog","FCEA_Backup","FCEA_Inicio")
        $faltan = 0
        foreach ($t in $tareas) {
            $found = $false
            try { Get-ScheduledTask -TaskName $t -ErrorAction Stop | Out-Null; $found = $true } catch {}
            if (-not $found) { $faltan++ }
        }
        $r["tareas"] = if ($faltan -eq 0) { "ok" } elseif ($faltan -lt 3) { "warn" } else { "fail" }
    } catch { $r["tareas"] = "fail"; Log $_.Exception.Message "ERR" }

    # G) Ultimo backup
    try {
        $backupDir = Join-Path $INSTALL_BASE "backups"
        if (Test-Path $backupDir) {
            $last = Get-ChildItem $backupDir -Filter "*.zip" -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($last) {
                $hrs = ((Get-Date) - $last.LastWriteTime).TotalHours
                $r["backup"] = if ($hrs -lt 24) { "ok" } elseif ($hrs -lt 72) { "warn" } else { "fail" }
            } else {
                $r["backup"] = "fail"
            }
        } else {
            $r["backup"] = "fail"
        }
    } catch { $r["backup"] = "fail"; Log $_.Exception.Message "ERR" }

    # H) Coincidencia hardware vs config
    try {
        if ($Cfg.hardware -eq 'tactil') {
            $touch = Test-TouchAvailable
            $r["hw_match"] = if ($touch) { "ok" } else { "warn" }
        } else {
            $r["hw_match"] = "ok"
        }
    } catch { $r["hw_match"] = "warn" }

    return $r
}

function Show-DiagnosticoTable {
    param([hashtable]$R)
    $labels = [ordered]@{
        "base_dir"   = "Carpeta C:\sistema-llaves-fcea"
        "pb_exe"     = "PocketBase ejecutable"
        "pb_running" = "PocketBase corriendo (puerto 8090)"
        "frontend"   = "Frontend (dist/index.html)"
        "node"       = "Node portable"
        "tareas"     = "Tareas programadas"
        "backup"     = "Ultimo backup (< 24 h)"
        "hw_match"   = "Hardware coincide con install_config"
    }
    Section "Diagnostico"
    foreach ($k in $labels.Keys) {
        $status = $R[$k]
        $label  = $labels[$k]
        switch ($status) {
            "ok"   { Write-Host ("  [OK]    " + $label) -ForegroundColor Green }
            "warn" { Write-Host ("  [AVISO] " + $label) -ForegroundColor Yellow }
            "fail" { Write-Host ("  [FALLA] " + $label) -ForegroundColor Red }
            default{ Write-Host ("  [?]     " + $label) -ForegroundColor DarkGray }
        }
    }
    Write-Host ""
}

# ---------------------------------------------------------------------------
# 3) Acciones de reparacion (todas envueltas en try/catch)
# ---------------------------------------------------------------------------
function Invoke-Safe {
    param([string]$Title, [scriptblock]$Action)
    Write-Host ""
    Write-Host "  >> $Title ..." -ForegroundColor White
    try {
        & $Action
        Write-Host "  >> $Title: completado." -ForegroundColor Green
        Log "Accion OK: $Title"
    } catch {
        Write-Host "  >> $Title: fallo. Revisa el log." -ForegroundColor Yellow
        Log "Accion FALLO: $Title - $($_.Exception.Message)" "ERR"
        Log ($_ | Out-String) "ERR"
    }
}

function Action-RepararPocketBase {
    Invoke-Safe "Reparar PocketBase" {
        $bat = Join-Path $SCRIPT_DIR "reparar_pocketbase.bat"
        if (Test-Path $bat) {
            Start-Process -FilePath $bat -Wait -NoNewWindow
        } else {
            $pbDir = Join-Path $INSTALL_BASE "pocketbase"
            $startBat = Join-Path $pbDir "start-server.bat"
            if (Test-Path $startBat) {
                Start-Process -FilePath $startBat -WorkingDirectory $pbDir
                Start-Sleep -Seconds 3
            } else {
                throw "No se encuentra start-server.bat en $pbDir"
            }
        }
    }
}

function Action-ReinstalarFrontend {
    Invoke-Safe "Reinstalar frontend" {
        $bat = Join-Path $SCRIPT_DIR "reinstalar_frontend.bat"
        if (Test-Path $bat) {
            Start-Process -FilePath $bat -Wait -NoNewWindow
        } else {
            throw "No se encuentra reinstalar_frontend.bat"
        }
    }
}

function Action-RestaurarBackup {
    Invoke-Safe "Restaurar ultimo backup" {
        $bat = Join-Path $SCRIPT_DIR "restaurar_backup.bat"
        if (Test-Path $bat) {
            Start-Process -FilePath $bat -Wait -NoNewWindow
        } else {
            throw "No se encuentra restaurar_backup.bat"
        }
    }
}

function Action-ReconfigurarTareas {
    Invoke-Safe "Reconfigurar tareas programadas" {
        $repoMaint = Join-Path $REPO_ROOT "maintenance"
        $ps1 = Join-Path $repoMaint "CONFIGURAR_MANTENIMIENTO.ps1"
        if (Test-Path $ps1) {
            powershell -NoProfile -ExecutionPolicy Bypass -File $ps1
        } else {
            throw "No se encuentra CONFIGURAR_MANTENIMIENTO.ps1"
        }
    }
}

function Action-RedetectarHardware {
    param([ref]$CfgRef)
    Invoke-Safe "Re-detectar hardware y actualizar install_config" {
        $snap = Get-HardwareSnapshot
        $sug  = Suggest-HardwareMode -Snapshot $snap
        Write-Host "    Hardware sugerido: $sug" -ForegroundColor Cyan
        $resp = Read-Host "    Aceptar y guardar? (S/N)"
        if ($resp -match '^[Ss]') {
            $new = New-InstallConfig -Modo $CfgRef.Value.modo -Hardware $sug -HardwareSnapshot $snap
            Write-InstallConfig -Config $new | Out-Null
            Sync-InstallConfigToPocketBase -Config $new -PbUrl $PbUrl | Out-Null
            Publish-InstallConfigForFrontend -Config $new | Out-Null
            $CfgRef.Value = $new
        } else {
            Write-Host "    Cancelado, no se modifico nada." -ForegroundColor DarkGray
        }
    }
}

function Action-VerLog {
    if (Test-Path $LOG_FILE) {
        Write-Host ""
        Write-Host "  --- $LOG_FILE ---" -ForegroundColor DarkGray
        Get-Content $LOG_FILE | Select-Object -Last 60 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        Write-Host "  --- (fin) ---" -ForegroundColor DarkGray
    }
}

# ---------------------------------------------------------------------------
# 4) Menu
# ---------------------------------------------------------------------------
function Show-Menu {
    param([hashtable]$R, [ref]$CfgRef)

    while ($true) {
        Section "Acciones disponibles"
        $options = @()

        if ($R["pb_running"] -ne "ok" -or $R["pb_exe"] -ne "ok") {
            Write-Host "  [A] Reparar PocketBase"          -ForegroundColor White
            $options += "A"
        }
        if ($R["frontend"] -ne "ok") {
            Write-Host "  [B] Reinstalar frontend"          -ForegroundColor White
            $options += "B"
        }
        Write-Host     "  [C] Restaurar ultimo backup"      -ForegroundColor White; $options += "C"
        if ($R["tareas"] -ne "ok") {
            Write-Host "  [D] Reconfigurar tareas programadas" -ForegroundColor White
            $options += "D"
        }
        Write-Host     "  [E] Re-detectar hardware (install_config)" -ForegroundColor White; $options += "E"
        Write-Host     "  [F] Ver log de esta sesion"               -ForegroundColor White; $options += "F"
        Write-Host     "  [R] Volver a correr diagnostico"          -ForegroundColor White; $options += "R"
        Write-Host     "  [Q] Salir"                                 -ForegroundColor White; $options += "Q"
        Write-Host ""

        $choice = (Read-Host "  Eleccion").ToUpper()
        if ($choice -notin $options) {
            Write-Host "  Opcion invalida." -ForegroundColor Yellow
            continue
        }

        switch ($choice) {
            "A" { Action-RepararPocketBase }
            "B" { Action-ReinstalarFrontend }
            "C" { Action-RestaurarBackup }
            "D" { Action-ReconfigurarTareas }
            "E" { Action-RedetectarHardware -CfgRef $CfgRef }
            "F" { Action-VerLog }
            "R" {
                $R = Invoke-Diagnostico -Cfg $CfgRef.Value
                Show-DiagnosticoTable -R $R
            }
            "Q" { return }
        }
    }
}

# ===========================================================================
# MAIN
# ===========================================================================
try {
    Banner
    Write-Host "  Diagnosticando esta PC..." -ForegroundColor White
    Write-Host ""

    $cfg = Resolve-InstallConfig

    Write-Host "  [2/3] Configuracion detectada:" -ForegroundColor White
    Write-Host "        modo     = $($cfg.modo)"
    Write-Host "        hardware = $($cfg.hardware)"
    Write-Host "        pc       = $($cfg.pc_identifier)"

    Write-Host ""
    Write-Host "  [3/3] Ejecutando diagnostico..." -ForegroundColor White
    $results = Invoke-Diagnostico -Cfg $cfg
    Show-DiagnosticoTable -R $results

    if ($NoMenu) {
        Log "Modo NoMenu, fin."
        exit 0
    }

    $cfgRef = [ref]$cfg
    Show-Menu -R $results -CfgRef $cfgRef

    Write-Host ""
    Write-Host "  Hasta luego." -ForegroundColor Cyan
    Log "Sesion finalizada normalmente."
    exit 0
} catch {
    Write-Host ""
    Write-Host "  [ERROR FATAL] $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  Revisa el log: $LOG_FILE" -ForegroundColor Yellow
    Log "ERROR FATAL: $($_.Exception.Message)" "ERR"
    Log ($_ | Out-String) "ERR"
    exit 1
}
