# ============================================================================
# Watchdog de PocketBase - Sistema de Gestión de Llaves FCEA
# ============================================================================
# Este script monitorea constantemente PocketBase y lo reinicia si se cae
# Diseñado para ejecutarse como tarea programada cada 2 minutos
# ============================================================================

$ErrorActionPreference = "Continue"

# Configuración
$ProjectRoot = "C:\sistema-llaves-fcea"
$PocketBaseExe = Join-Path $ProjectRoot "pocketbase\pocketbase.exe"
$PocketBaseDir = Join-Path $ProjectRoot "pocketbase"
$LogFile = Join-Path $ProjectRoot "pocketbase\maintenance\logs\watchdog.log"
$PocketBaseUrl = "http://localhost:8090/api/health"
$MaxRestartAttempts = 3
$RestartDelay = 10 # segundos

# Función para escribir en el log
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    # Crear directorio de logs si no existe
    $LogDir = Split-Path -Parent $LogFile
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    
    Add-Content -Path $LogFile -Value $LogMessage
    Write-Host $LogMessage
}

# Función para verificar si PocketBase está corriendo
function Test-PocketBaseRunning {
    $process = Get-Process -Name "pocketbase" -ErrorAction SilentlyContinue
    return ($null -ne $process)
}

# Función para verificar si PocketBase responde
function Test-PocketBaseResponding {
    try {
        $response = Invoke-WebRequest -Uri $PocketBaseUrl -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        return ($response.StatusCode -eq 200)
    } catch {
        return $false
    }
}

# Función para iniciar PocketBase
function Start-PocketBase {
    param([int]$Attempt = 1)
    
    Write-Log "Intento $Attempt de $MaxRestartAttempts: Iniciando PocketBase..." "WARNING"
    
    try {
        # Cambiar al directorio de PocketBase
        Set-Location $PocketBaseDir
        
        # Iniciar PocketBase en segundo plano
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $PocketBaseExe
        $processInfo.Arguments = "serve"
        $processInfo.WorkingDirectory = $PocketBaseDir
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null
        
        Write-Log "PocketBase iniciado (PID: $($process.Id))" "INFO"
        
        # Esperar a que PocketBase esté listo
        Write-Log "Esperando $RestartDelay segundos para que PocketBase inicie..." "INFO"
        Start-Sleep -Seconds $RestartDelay
        
        # Verificar que responde
        if (Test-PocketBaseResponding) {
            Write-Log "✓ PocketBase iniciado correctamente y respondiendo" "INFO"
            return $true
        } else {
            Write-Log "✗ PocketBase inició pero no responde" "ERROR"
            return $false
        }
        
    } catch {
        Write-Log "Error al iniciar PocketBase: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# ============================================================================
# LÓGICA PRINCIPAL DEL WATCHDOG
# ============================================================================

Write-Log "=== Watchdog iniciado ==="

# Verificar si el ejecutable existe
if (-not (Test-Path $PocketBaseExe)) {
    Write-Log "CRÍTICO: No se encontró pocketbase.exe en $PocketBaseExe" "ERROR"
    exit 1
}

# Verificar si PocketBase está corriendo
$isRunning = Test-PocketBaseRunning

if ($isRunning) {
    Write-Log "PocketBase está corriendo (proceso activo)"
    
    # Verificar si responde
    $isResponding = Test-PocketBaseResponding
    
    if ($isResponding) {
        Write-Log "✓ PocketBase está funcionando correctamente"
        exit 0
    } else {
        Write-Log "✗ PocketBase está corriendo pero NO responde" "WARNING"
        Write-Log "Matando proceso colgado..." "WARNING"
        
        # Matar el proceso colgado
        Get-Process -Name "pocketbase" -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 2
        
        # Intentar reiniciar
        $attempt = 1
        $success = $false
        
        while ($attempt -le $MaxRestartAttempts -and -not $success) {
            $success = Start-PocketBase -Attempt $attempt
            if (-not $success) {
                $attempt++
                if ($attempt -le $MaxRestartAttempts) {
                    Write-Log "Esperando antes del siguiente intento..." "WARNING"
                    Start-Sleep -Seconds 5
                }
            }
        }
        
        if ($success) {
            Write-Log "✓ PocketBase recuperado exitosamente" "INFO"
            exit 0
        } else {
            Write-Log "✗ CRÍTICO: No se pudo recuperar PocketBase después de $MaxRestartAttempts intentos" "ERROR"
            exit 2
        }
    }
} else {
    Write-Log "✗ PocketBase NO está corriendo" "ERROR"
    
    # Intentar iniciar
    $attempt = 1
    $success = $false
    
    while ($attempt -le $MaxRestartAttempts -and -not $success) {
        $success = Start-PocketBase -Attempt $attempt
        if (-not $success) {
            $attempt++
            if ($attempt -le $MaxRestartAttempts) {
                Write-Log "Esperando antes del siguiente intento..." "WARNING"
                Start-Sleep -Seconds 5
            }
        }
    }
    
    if ($success) {
        Write-Log "✓ PocketBase iniciado exitosamente" "INFO"
        exit 0
    } else {
        Write-Log "✗ CRÍTICO: No se pudo iniciar PocketBase después de $MaxRestartAttempts intentos" "ERROR"
        exit 2
    }
}

Write-Log "=== Watchdog finalizado ==="
