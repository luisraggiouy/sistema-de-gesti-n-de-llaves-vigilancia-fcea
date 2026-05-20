# ============================================================================
# WATCHDOG COMPLETO - Protege PocketBase Y Frontend (Vite)
# Sistema de Gestion de Llaves FCEA
# ============================================================================

$ErrorActionPreference = "Continue"

# Configuracion - ruta donde se instala el sistema
$ProjectRoot = "C:\sistema-llaves-fcea"
$PocketBaseExe = Join-Path $ProjectRoot "pocketbase\pocketbase.exe"
$LogFile = Join-Path $ProjectRoot "scripts\watchdog_completo.log"
$CheckInterval = 120 # Verificar cada 2 minutos

# Variables de estado
$PocketBasePID = $null
$NodePID = $null

# Funcion para escribir en el log
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    try { Add-Content -Path $LogFile -Value $LogMessage -ErrorAction SilentlyContinue } catch {}
    Write-Host $LogMessage
}

# Funcion para iniciar PocketBase
function Start-PocketBase {
    Write-Log "Iniciando PocketBase..." "INFO"
    try {
        $process = Start-Process -FilePath $PocketBaseExe `
                                 -ArgumentList "serve", "--http=127.0.0.1:8090" `
                                 -WorkingDirectory (Split-Path $PocketBaseExe) `
                                 -WindowStyle Hidden `
                                 -PassThru
        Start-Sleep -Seconds 3
        if ($process -and !$process.HasExited) {
            $script:PocketBasePID = $process.Id
            Write-Log "PocketBase iniciado (PID: $($process.Id))" "INFO"
            return $true
        } else {
            Write-Log "PocketBase fallo al iniciar" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error al iniciar PocketBase: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Funcion para iniciar Frontend (Vite)
function Start-Frontend {
    Write-Log "Iniciando Frontend (Vite)..." "INFO"
    try {
        # Verificar si ya hay algo en el puerto 8080
        $port8080Check = netstat -ano 2>$null | Select-String ":8080" | Select-String "LISTENING"
        if ($port8080Check) {
            Write-Log "Puerto 8080 ya esta activo" "INFO"
            return $true
        }

        # Matar procesos node anteriores que no responden
        $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
        if ($nodeProcesses) {
            $nodeProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }

        # Verificar que node_modules existe
        $nodeModules = Join-Path $ProjectRoot "node_modules"
        if (-not (Test-Path $nodeModules)) {
            Write-Log "ERROR: node_modules no existe en $ProjectRoot" "ERROR"
            Write-Log "Ejecute npm install en $ProjectRoot primero" "ERROR"
            return $false
        }

        # Iniciar npm run dev
        $process = Start-Process -FilePath "cmd.exe" `
                                 -ArgumentList "/c", "cd /d `"$ProjectRoot`" && npm run dev -- --port 8080 --host" `
                                 -WindowStyle Hidden `
                                 -PassThru

        # Esperar hasta 30 segundos a que Vite arranque
        $intentos = 0
        while ($intentos -lt 6) {
            Start-Sleep -Seconds 5
            $intentos++
            $port8080 = netstat -ano 2>$null | Select-String ":8080" | Select-String "LISTENING"
            if ($port8080) {
                Write-Log "Frontend iniciado correctamente (puerto 8080 activo)" "INFO"
                return $true
            }
            Write-Log "Esperando que Vite arranque... intento $intentos/6" "INFO"
        }

        Write-Log "Frontend no respondio en 30 segundos" "ERROR"
        return $false
    } catch {
        Write-Log "Error al iniciar Frontend: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Funcion para verificar si PocketBase esta corriendo
function Test-PocketBaseRunning {
    $process = Get-Process -Name "pocketbase" -ErrorAction SilentlyContinue
    if ($process) {
        $script:PocketBasePID = $process.Id
        return $true
    }
    return $false
}

# Funcion para verificar si Frontend esta corriendo
function Test-FrontendRunning {
    $nodeProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue
    if ($nodeProcess) {
        $port8080 = netstat -ano 2>$null | Select-String ":8080" | Select-String "LISTENING"
        if ($port8080) {
            $script:NodePID = $nodeProcess.Id
            return $true
        }
    }
    return $false
}

# ============================================================================
# INICIO DEL WATCHDOG
# ============================================================================

Write-Log "========================================"
Write-Log "WATCHDOG COMPLETO INICIADO"
Write-Log "Directorio del sistema: $ProjectRoot"
Write-Log "Intervalo de verificacion: $CheckInterval segundos"
Write-Log "========================================"

# Verificar e iniciar procesos si no estan corriendo
if (!(Test-PocketBaseRunning)) {
    Write-Log "PocketBase no esta corriendo. Iniciando..."
    Start-PocketBase
} else {
    Write-Log "PocketBase ya esta corriendo (PID: $PocketBasePID)"
}

if (!(Test-FrontendRunning)) {
    Write-Log "Frontend no esta corriendo. Iniciando..."
    Start-Frontend
} else {
    Write-Log "Frontend ya esta corriendo (PID: $NodePID)"
}

# Loop principal de monitoreo
$iteration = 0
while ($true) {
    Start-Sleep -Seconds $CheckInterval
    $iteration++

    Write-Log "--- Verificacion #$iteration ---"

    if (!(Test-PocketBaseRunning)) {
        Write-Log "ALERTA: PocketBase se cayo. Reiniciando..." "ERROR"
        Start-PocketBase
    } else {
        Write-Log "PocketBase OK (PID: $PocketBasePID)"
    }

    if (!(Test-FrontendRunning)) {
        Write-Log "ALERTA: Frontend se cayo. Reiniciando..." "ERROR"
        Start-Frontend
    } else {
        Write-Log "Frontend OK (PID: $NodePID)"
    }
}
