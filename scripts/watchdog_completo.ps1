# ============================================================================
# WATCHDOG COMPLETO - Protege PocketBase Y Frontend (Vite)
# Sistema de Gestión de Llaves FCEA
# ============================================================================
# Este script monitorea AMBOS procesos críticos del sistema:
# 1. PocketBase (backend/base de datos)
# 2. Node.js/Vite (frontend)
# Si alguno se cae, lo reinicia automáticamente
# ============================================================================

$ErrorActionPreference = "Continue"

# Configuración
$ProjectRoot = "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
$PocketBaseExe = Join-Path $ProjectRoot "pocketbase\pocketbase.exe"
$LogFile = Join-Path $ProjectRoot "scripts\watchdog_completo.log"
$CheckInterval = 120 # Verificar cada 2 minutos

# Variables de estado
$PocketBasePID = $null
$NodePID = $null

# Función para escribir en el log
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

# Función para iniciar PocketBase
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
            Write-Log "PocketBase falló al iniciar" "ERROR"
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
        # Matar cualquier proceso node.exe anterior
        Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        # Iniciar npm run dev
        $process = Start-Process -FilePath "cmd.exe" `
                                 -ArgumentList "/c", "cd /d `"$ProjectRoot`" && npm run dev" `
                                 -WindowStyle Hidden `
                                 -PassThru
        
        Start-Sleep -Seconds 5
        
        # Verificar que node.exe esté corriendo
        $nodeProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($nodeProcess) {
            $script:NodePID = $nodeProcess.Id
            Write-Log "Frontend iniciado correctamente (PID: $($nodeProcess.Id))" "SUCCESS"
            return $true
        } else {
            Write-Log "Frontend falló al iniciar" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error al iniciar Frontend: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Función para verificar si PocketBase está corriendo
function Test-PocketBaseRunning {
    $process = Get-Process -Name "pocketbase" -ErrorAction SilentlyContinue
    if ($process) {
        $script:PocketBasePID = $process.Id
        return $true
    }
    return $false
}

# Función para verificar si Frontend está corriendo
function Test-FrontendRunning {
    # Verificar si node.exe está corriendo Y escuchando en puerto 8080
    $nodeProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue
    if ($nodeProcess) {
        # Verificar si el puerto 8080 está en uso
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
Write-Log "Intervalo de verificación: $CheckInterval segundos" "INFO"
Write-Log "========================================" "INFO"

# Verificar e iniciar procesos si no están corriendo
if (!(Test-PocketBaseRunning)) {
    Write-Log "PocketBase no está corriendo. Iniciando..." "WARNING"
    Start-PocketBase
} else {
    Write-Log "PocketBase ya está corriendo (PID: $PocketBasePID)" "INFO"
}

if (!(Test-FrontendRunning)) {
    Write-Log "Frontend no está corriendo. Iniciando..." "WARNING"
    Start-Frontend
} else {
    Write-Log "Frontend ya está corriendo (PID: $NodePID)" "INFO"
}

# Loop principal de monitoreo
$iteration = 0
while ($true) {
    Start-Sleep -Seconds $CheckInterval
    $iteration++
    
    Write-Log "--- Verificación #$iteration ---" "INFO"
    
    # Verificar PocketBase
    if (!(Test-PocketBaseRunning)) {
        Write-Log "¡ALERTA! PocketBase se cayó. Reiniciando..." "ERROR"
        Start-PocketBase
    } else {
        Write-Log "PocketBase OK (PID: $PocketBasePID)" "INFO"
    }
    
    # Verificar Frontend
    if (!(Test-FrontendRunning)) {
        Write-Log "¡ALERTA! Frontend se cayó. Reiniciando..." "ERROR"
        Start-Frontend
    } else {
        Write-Log "Frontend OK (PID: $NodePID)" "INFO"
    }
}
