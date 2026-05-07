# ============================================================================
# WATCHDOG COMPLETO - Protege PocketBase Y Frontend (Vite)
# Sistema de Gestiรณn de Llaves FCEA
# ============================================================================
# Este script monitorea AMBOS procesos crรญticos del sistema:
# 1. PocketBase (backend/base de datos)
# 2. Node.js/Vite (frontend)
# Si alguno se cae, lo reinicia automรกticamente
# ============================================================================

$ErrorActionPreference = "Continue"

# Configuraciรณn
$ProjectRoot = "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
$PocketBaseExe = Join-Path $ProjectRoot "pocketbase\pocketbase.exe"
$LogFile = Join-Path $ProjectRoot "scripts\watchdog_completo.log"
$CheckInterval = 120 # Verificar cada 2 minutos

# Variables de estado
$PocketBasePID = $null
$NodePID = $null

# Funciรณn para escribir en el log
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

# Funciรณn para iniciar PocketBase
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
            Write-Log "PocketBase iniciado correctamente (PID: $($process.Id))" "SUCCESS"
            return $true
        } else {
            Write-Log "PocketBase fallรณ al iniciar" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error al iniciar PocketBase: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Función para iniciar Frontend (Vite)
function Start-Frontend {
    Write-Log "Iniciando Frontend (Vite)..." "INFO"
    try {
        # IMPORTANTE: Solo matar node.exe si el puerto 8080 NO está respondiendo
        # No matar procesos node que puedan estar sirviendo correctamente
        $port8080Check = netstat -ano 2>$null | Select-String ":8080" | Select-String "LISTENING"
        if ($port8080Check) {
            Write-Log "Puerto 8080 ya está en uso, no se reiniciará el frontend" "WARNING"
            return $true
        }
        
        # Solo matar node.exe si realmente no hay nada en el puerto 8080
        $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
        if ($nodeProcesses) {
            Write-Log "Deteniendo procesos node.exe anteriores (puerto 8080 no responde)..." "INFO"
            $nodeProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
        }
        
        # Iniciar npm run dev
        $process = Start-Process -FilePath "cmd.exe" `
                                 -ArgumentList "/c", "cd /d `"$ProjectRoot`" && npm run dev" `
                                 -WindowStyle Hidden `
                                 -PassThru
        
        # Esperar más tiempo para que Vite arranque completamente
        Start-Sleep -Seconds 10
        
        # Verificar que el puerto 8080 esté escuchando
        $port8080 = netstat -ano 2>$null | Select-String ":8080" | Select-String "LISTENING"
        if ($port8080) {
            $nodeProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue | Select-Object -First 1
            $script:NodePID = if ($nodeProcess) { $nodeProcess.Id } else { 0 }
            Write-Log "Frontend iniciado correctamente (puerto 8080 activo)" "SUCCESS"
            return $true
        } else {
            Write-Log "Frontend falló al iniciar (puerto 8080 no responde)" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error al iniciar Frontend: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Funciรณn para verificar si PocketBase estรก corriendo
function Test-PocketBaseRunning {
    $process = Get-Process -Name "pocketbase" -ErrorAction SilentlyContinue
    if ($process) {
        $script:PocketBasePID = $process.Id
        return $true
    }
    return $false
}

# Funciรณn para verificar si Frontend estรก corriendo
function Test-FrontendRunning {
    # Verificar si node.exe estรก corriendo Y escuchando en puerto 8080
    $nodeProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue
    if ($nodeProcess) {
        # Verificar si el puerto 8080 estรก en uso
        $port8080 = netstat -ano | Select-String ":8080" | Select-String "LISTENING"
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

Write-Log "========================================" "INFO"
Write-Log "WATCHDOG COMPLETO INICIADO" "INFO"
Write-Log "Monitoreando: PocketBase + Frontend" "INFO"
Write-Log "Intervalo de verificaciรณn: $CheckInterval segundos" "INFO"
Write-Log "========================================" "INFO"

# Verificar e iniciar procesos si no estรกn corriendo
if (!(Test-PocketBaseRunning)) {
    Write-Log "PocketBase no estรก corriendo. Iniciando..." "WARNING"
    Start-PocketBase
} else {
    Write-Log "PocketBase ya estรก corriendo (PID: $PocketBasePID)" "INFO"
}

if (!(Test-FrontendRunning)) {
    Write-Log "Frontend no estรก corriendo. Iniciando..." "WARNING"
    Start-Frontend
} else {
    Write-Log "Frontend ya estรก corriendo (PID: $NodePID)" "INFO"
}

# Loop principal de monitoreo
$iteration = 0
while ($true) {
    Start-Sleep -Seconds $CheckInterval
    $iteration++
    
    Write-Log "--- Verificaciรณn #$iteration ---" "INFO"
    
    # Verificar PocketBase
    if (!(Test-PocketBaseRunning)) {
        Write-Log "ยกALERTA! PocketBase se cayรณ. Reiniciando..." "ERROR"
        Start-PocketBase
    } else {
        Write-Log "PocketBase OK (PID: $PocketBasePID)" "INFO"
    }
    
    # Verificar Frontend
    if (!(Test-FrontendRunning)) {
        Write-Log "ยกALERTA! Frontend se cayรณ. Reiniciando..." "ERROR"
        Start-Frontend
    } else {
        Write-Log "Frontend OK (PID: $NodePID)" "INFO"
    }
}
