# Script mejorado para crear tarea de inicio automático
# Versión con verificación de permisos y mejor manejo de errores

$ErrorActionPreference = "Stop"

# Colores para mensajes
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Error-Custom { param($msg) Write-Host $msg -ForegroundColor Red }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Warning-Custom { param($msg) Write-Host $msg -ForegroundColor Yellow }

Write-Info "========================================="
Write-Info "CONFIGURADOR DE INICIO AUTOMATICO"
Write-Info "Sistema de Gestión de Llaves FCEA"
Write-Info "========================================="
Write-Host ""

# PASO 1: Verificar si se está ejecutando como administrador
Write-Info "Verificando permisos de administrador..."
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error-Custom "ERROR: Este script NO se está ejecutando como administrador"
    Write-Host ""
    Write-Warning-Custom "SOLUCIÓN:"
    Write-Host "1. Cierra esta ventana"
    Write-Host "2. Haz CLIC DERECHO en el archivo .bat"
    Write-Host "3. Selecciona 'Ejecutar como administrador'"
    Write-Host ""
    Write-Warning-Custom "ALTERNATIVA: Usa el Método Simple (no requiere admin)"
    Write-Host "Ejecuta: CONFIGURAR_INICIO_DEFINITIVO.bat y elige opción 1"
    Write-Host ""
    Write-Host "Presiona cualquier tecla para salir..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Success "✓ Permisos de administrador verificados"
Write-Host ""

# PASO 2: Verificar que existen los archivos necesarios
$TaskName = "SistemaLlavesFCEA_AutoInicio"
$WatchdogScript = "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\scripts\watchdog_completo.ps1"
$IniciarScript = "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\INICIAR_SISTEMA_AHORA.bat"

Write-Info "Verificando archivos del sistema..."

if (-not (Test-Path $WatchdogScript)) {
    Write-Error-Custom "ERROR: No se encuentra el archivo watchdog_completo.ps1"
    Write-Host "Ruta esperada: $WatchdogScript"
    Write-Host ""
    Write-Warning-Custom "Usando método alternativo con INICIAR_SISTEMA_AHORA.bat"
    $WatchdogScript = $IniciarScript
}

if (-not (Test-Path $WatchdogScript)) {
    Write-Error-Custom "ERROR CRÍTICO: No se encuentran los archivos del sistema"
    Write-Host "Verifica que el sistema esté instalado en:"
    Write-Host "c:\sistema-de-gesti-n-de-llaves-vigilancia-fcea\"
    Write-Host ""
    Write-Host "Presiona cualquier tecla para salir..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Success "✓ Archivos del sistema encontrados"
Write-Host ""

# PASO 3: Eliminar tarea anterior si existe
Write-Info "Verificando si existe una tarea anterior..."
try {
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Warning-Custom "Se encontró una tarea anterior, eliminándola..."
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Success "✓ Tarea anterior eliminada"
    } else {
        Write-Info "No hay tarea anterior"
    }
} catch {
    Write-Warning-Custom "Advertencia al verificar tarea anterior: $($_.Exception.Message)"
}
Write-Host ""

# PASO 4: Crear la nueva tarea programada
Write-Info "Creando nueva tarea programada..."
Write-Host ""

try {
    # Determinar qué tipo de script usar
    if ($WatchdogScript -like "*.ps1") {
        Write-Info "Usando watchdog de PowerShell (método avanzado)"
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$WatchdogScript`""
    } else {
        Write-Info "Usando script BAT (método simple)"
        $Action = New-ScheduledTaskAction -Execute "cmd.exe" `
            -Argument "/c `"$WatchdogScript`""
    }
    
    # Crear trigger: al inicio del sistema con delay de 30 segundos
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    $Trigger.Delay = "PT30S"
    
    # Configuración de la tarea
    $Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1) `
        -ExecutionTimeLimit (New-TimeSpan -Days 365)
    
    # Obtener el usuario actual para ejecutar la tarea
    $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Info "Usuario para la tarea: $CurrentUser"
    
    # Crear principal con el usuario actual (más compatible que SYSTEM)
    $Principal = New-ScheduledTaskPrincipal -UserId $CurrentUser -LogonType Interactive -RunLevel Highest
    
    # Registrar la tarea
    Write-Info "Registrando tarea en el programador de Windows..."
    $Task = Register-ScheduledTask -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Settings $Settings `
        -Principal $Principal `
        -Description "Inicia automáticamente el Sistema de Gestión de Llaves FCEA al arrancar Windows" `
        -Force
    
    Write-Host ""
    Write-Success "========================================="
    Write-Success "✓ TAREA CREADA EXITOSAMENTE"
    Write-Success "========================================="
    Write-Host ""
    Write-Success "El sistema se iniciará automáticamente al arrancar Windows"
    Write-Info "Delay de inicio: 30 segundos después del arranque"
    Write-Info "Usuario: $CurrentUser"
    Write-Host ""
    
    # Verificar que la tarea se creó correctamente
    $verifyTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($verifyTask) {
        Write-Success "✓ Tarea verificada en el programador de Windows"
        Write-Info "Estado: $($verifyTask.State)"
    }
    
} catch {
    Write-Host ""
    Write-Error-Custom "========================================="
    Write-Error-Custom "ERROR AL CREAR LA TAREA"
    Write-Error-Custom "========================================="
    Write-Host ""
    Write-Error-Custom "Detalles del error:"
    Write-Host $_.Exception.Message
    Write-Host ""
    Write-Host "Información adicional:"
    Write-Host $_.Exception.GetType().FullName
    Write-Host ""
    
    Write-Warning-Custom "SOLUCIÓN ALTERNATIVA:"
    Write-Host "Usa el Método Simple que no requiere permisos de administrador:"
    Write-Host "1. Ejecuta: CONFIGURAR_INICIO_DEFINITIVO.bat"
    Write-Host "2. Elige opción 1 (Método Simple)"
    Write-Host ""
    Write-Host "Presiona cualquier tecla para salir..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""
Write-Info "Para verificar la tarea, ejecuta en CMD:"
Write-Host 'schtasks /query /tn "SistemaLlavesFCEA_AutoInicio" /fo LIST /v'
Write-Host ""
Write-Host "Presiona cualquier tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
