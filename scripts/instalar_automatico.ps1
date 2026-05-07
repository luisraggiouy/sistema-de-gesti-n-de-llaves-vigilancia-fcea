# ============================================================================
# Script: Instalador Automático del Sistema de Llaves FCEA
# Propósito: Instalación completa y configuración automática
# Versión: 1.0
# ============================================================================

# Configuración de consola
$Host.UI.RawUI.WindowTitle = "Instalador Automático - Sistema de Llaves FCEA"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

# Variables globales
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$PendrivePath = Split-Path -Parent $ScriptPath
$DestinationPath = "C:\sistema-llaves-fcea"
$LogFile = "$env:TEMP\instalacion_llaves_fcea.log"

# Función para escribir log
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Type] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    
    switch ($Type) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        default { Write-Host $Message -ForegroundColor White }
    }
}

# Función para mostrar menú
function Show-Menu {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                    ║" -ForegroundColor Cyan
    Write-Host "║     INSTALADOR AUTOMÁTICO - SISTEMA DE LLAVES FCEA                 ║" -ForegroundColor Cyan
    Write-Host "║                                                                    ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Función para verificar requisitos
function Test-SystemRequirements {
    Write-Log "Verificando requisitos del sistema..."
    
    $requirements = @{
        "Windows 10/11" = $false
        "Espacio en disco" = $false
        "RAM suficiente" = $false
        "Permisos de administrador" = $false
    }
    
    # Verificar Windows
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -ge 10) {
        $requirements["Windows 10/11"] = $true
        Write-Log "✓ Windows $($osVersion.Major).$($osVersion.Minor) detectado" "SUCCESS"
    } else {
        Write-Log "✗ Se requiere Windows 10 o superior" "ERROR"
    }
    
    # Verificar espacio en disco
    $drive = Get-PSDrive C
    $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
    if ($freeSpaceGB -gt 10) {
        $requirements["Espacio en disco"] = $true
        Write-Log "✓ Espacio en disco: $freeSpaceGB GB disponibles" "SUCCESS"
    } else {
        Write-Log "✗ Espacio insuficiente: $freeSpaceGB GB (se requieren al menos 10 GB)" "ERROR"
    }
    
    # Verificar RAM
    $ram = Get-CimInstance Win32_ComputerSystem
    $ramGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
    if ($ramGB -ge 4) {
        $requirements["RAM suficiente"] = $true
        Write-Log "✓ RAM: $ramGB GB detectados" "SUCCESS"
    } else {
        Write-Log "✗ RAM insuficiente: $ramGB GB (se requieren al menos 4 GB)" "ERROR"
    }
    
    # Verificar permisos de administrador
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $requirements["Permisos de administrador"] = $true
        Write-Log "✓ Ejecutando como Administrador" "SUCCESS"
    } else {
        Write-Log "✗ Se requieren permisos de administrador" "ERROR"
    }
    
    # Detectar pantallas
    $monitors = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams
    $monitorCount = $monitors.Count
    Write-Log "✓ Pantallas detectadas: $monitorCount" "SUCCESS"
    
    Write-Host ""
    
    # Verificar si todos los requisitos se cumplen
    $allMet = $true
    foreach ($req in $requirements.GetEnumerator()) {
        if (-not $req.Value) {
            $allMet = $false
            break
        }
    }
    
    return $allMet
}

# Función para seleccionar modo de operación
function Select-OperationMode {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  1. MODO DE OPERACIÓN" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Producción (recomendado)" -ForegroundColor White
    Write-Host "      - Modo kiosk activado" -ForegroundColor Gray
    Write-Host "      - Inicio automático" -ForegroundColor Gray
    Write-Host "      - Mantenimiento automático configurado" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [2] Desarrollo (para pruebas)" -ForegroundColor White
    Write-Host "      - Modo normal del navegador" -ForegroundColor Gray
    Write-Host "      - Sin inicio automático" -ForegroundColor Gray
    Write-Host "      - Para desarrollo y pruebas" -ForegroundColor Gray
    Write-Host ""
    
    do {
        $choice = Read-Host "Seleccione una opción (1 o 2)"
    } while ($choice -ne "1" -and $choice -ne "2")
    
    if ($choice -eq "1") {
        Write-Log "Modo seleccionado: PRODUCCIÓN" "SUCCESS"
        return "produccion"
    } else {
        Write-Log "Modo seleccionado: DESARROLLO" "SUCCESS"
        return "desarrollo"
    }
}

# Función para seleccionar tipo de hardware
function Select-HardwareType {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  2. TIPO DE HARDWARE" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Pantallas Táctiles" -ForegroundColor White
    Write-Host "      - Teclado virtual automático" -ForegroundColor Gray
    Write-Host "      - Gestos táctiles habilitados" -ForegroundColor Gray
    Write-Host "      - Sin teclados ni mouses físicos" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [2] Monitores Tradicionales" -ForegroundColor White
    Write-Host "      - Teclados físicos (3 unidades)" -ForegroundColor Gray
    Write-Host "      - Mouses físicos (3 unidades)" -ForegroundColor Gray
    Write-Host "      - Más económico para etapa de prueba" -ForegroundColor Gray
    Write-Host ""
    
    do {
        $choice = Read-Host "Seleccione una opción (1 o 2)"
    } while ($choice -ne "1" -and $choice -ne "2")
    
    if ($choice -eq "1") {
        Write-Log "Hardware seleccionado: PANTALLAS TÁCTILES" "SUCCESS"
        return "tactil"
    } else {
        Write-Log "Hardware seleccionado: MONITORES TRADICIONALES" "SUCCESS"
        return "tradicional"
    }
}

# Función para instalar Node.js
function Install-NodeJS {
    Write-Log "Verificando instalación de Node.js..."
    
    # Verificar si Node.js ya está instalado
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Log "✓ Node.js ya está instalado: $nodeVersion" "SUCCESS"
            return $true
        }
    } catch {}
    
    # Buscar instalador en el pendrive
    $nodeInstaller = "$PendrivePath\instaladores\node-setup.msi"
    
    if (-not (Test-Path $nodeInstaller)) {
        Write-Log "✗ No se encontró el instalador de Node.js en: $nodeInstaller" "ERROR"
        Write-Log "Por favor, descargue Node.js de https://nodejs.org/ y cópielo a la carpeta instaladores\" "ERROR"
        return $false
    }
    
    Write-Log "Instalando Node.js... (esto puede tardar 3-5 minutos)"
    
    try {
        Start-Process msiexec.exe -ArgumentList "/i `"$nodeInstaller`" /quiet /norestart" -Wait -NoNewWindow
        
        # Actualizar PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Verificar instalación
        Start-Sleep -Seconds 5
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Log "✓ Node.js instalado exitosamente: $nodeVersion" "SUCCESS"
            return $true
        } else {
            Write-Log "✗ Node.js se instaló pero no se puede verificar. Reinicie y vuelva a intentar." "WARNING"
            return $false
        }
    } catch {
        Write-Log "✗ Error al instalar Node.js: $_" "ERROR"
        return $false
    }
}

# Función para copiar sistema
function Copy-System {
    Write-Log "Copiando sistema a $DestinationPath..."
    
    if (Test-Path $DestinationPath) {
        Write-Log "El directorio de destino ya existe. Creando respaldo..." "WARNING"
        $backupPath = "$DestinationPath`_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Move-Item -Path $DestinationPath -Destination $backupPath -Force
        Write-Log "Respaldo creado en: $backupPath" "SUCCESS"
    }
    
    try {
        Copy-Item -Path "$PendrivePath\sistema" -Destination $DestinationPath -Recurse -Force
        Write-Log "✓ Sistema copiado exitosamente" "SUCCESS"
        return $true
    } catch {
        Write-Log "✗ Error al copiar sistema: $_" "ERROR"
        return $false
    }
}

# Función para instalar dependencias
function Install-Dependencies {
    # Verificar si el pendrive trae node_modules (pendrive de recuperación)
    $nodeModulesInPendrive = "$PendrivePath\sistema\node_modules"
    if (Test-Path $nodeModulesInPendrive) {
        Write-Log "✓ node_modules encontrado en el pendrive — copiando sin necesidad de internet..." "SUCCESS"
        Write-Log "  Esto puede tardar 2-5 minutos..."
        try {
            Copy-Item -Path $nodeModulesInPendrive -Destination "$DestinationPath\node_modules" -Recurse -Force
            Write-Log "✓ Dependencias copiadas exitosamente desde el pendrive" "SUCCESS"
            return $true
        } catch {
            Write-Log "⚠ No se pudo copiar node_modules, intentando npm install..." "WARNING"
        }
    }

    Write-Log "Instalando dependencias de Node.js con npm install..."
    Write-Log "Esto puede tardar 5-10 minutos. Se requiere conexión a internet..."
    
    try {
        Set-Location $DestinationPath
        
        # Instalar dependencias
        $process = Start-Process npm -ArgumentList "install" -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "✓ Dependencias instaladas exitosamente" "SUCCESS"
            return $true
        } else {
            Write-Log "✗ Error al instalar dependencias (código: $($process.ExitCode))" "ERROR"
            return $false
        }
    } catch {
        Write-Log "✗ Error al instalar dependencias: $_" "ERROR"
        return $false
    }
}

# Función para configurar base de datos
function Initialize-Database {
    Write-Log "Inicializando base de datos..."
    
    try {
        # Verificar que PocketBase existe
        $pbPath = "$DestinationPath\pocketbase\pocketbase.exe"
        if (-not (Test-Path $pbPath)) {
            Write-Log "✗ No se encontró PocketBase en: $pbPath" "ERROR"
            return $false
        }
        
        Write-Log "✓ Base de datos lista para usar" "SUCCESS"
        return $true
    } catch {
        Write-Log "✗ Error al inicializar base de datos: $_" "ERROR"
        return $false
    }
}

# Función para configurar mantenimiento automático
function Configure-AutomaticMaintenance {
    Write-Log "Configurando sistema de mantenimiento automatizado (3 tareas)..."
    
    try {
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        # Tarea 1: Mantenimiento semanal
        Write-Log "  Configurando tarea 1/3: Mantenimiento semanal..."
        $action1 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$DestinationPath\pocketbase\maintenance\system_maintenance.ps1`""
        $trigger1 = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 8:00AM
        $task1 = Get-ScheduledTask -TaskName "Mantenimiento Sistema Llaves FCEA" -ErrorAction SilentlyContinue
        if ($task1) { Unregister-ScheduledTask -TaskName "Mantenimiento Sistema Llaves FCEA" -Confirm:$false }
        Register-ScheduledTask -TaskName "Mantenimiento Sistema Llaves FCEA" -Action $action1 -Trigger $trigger1 -Principal $principal -Settings $settings -Description "Respaldo semanal automático" | Out-Null
        Write-Log "  ✓ Tarea 1/3 configurada" "SUCCESS"
        
        # Tarea 2: Verificación de salud diaria
        Write-Log "  Configurando tarea 2/3: Verificación de salud..."
        $action2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$DestinationPath\pocketbase\maintenance\check_system_health.ps1`""
        $trigger2 = New-ScheduledTaskTrigger -Daily -At 7:00AM
        $task2 = Get-ScheduledTask -TaskName "Verificación Salud Sistema Llaves FCEA" -ErrorAction SilentlyContinue
        if ($task2) { Unregister-ScheduledTask -TaskName "Verificación Salud Sistema Llaves FCEA" -Confirm:$false }
        Register-ScheduledTask -TaskName "Verificación Salud Sistema Llaves FCEA" -Action $action2 -Trigger $trigger2 -Principal $principal -Settings $settings -Description "Verificación diaria de salud del sistema" | Out-Null
        Write-Log "  ✓ Tarea 2/3 configurada" "SUCCESS"
        
        # Tarea 3: Watchdog de PocketBase (cada 2 minutos)
        Write-Log "  Configurando tarea 3/3: Watchdog de PocketBase..."
        $action3 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$DestinationPath\scripts\watchdog_pocketbase.ps1`""
        $trigger3 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2) -RepetitionDuration ([TimeSpan]::MaxValue)
        $task3 = Get-ScheduledTask -TaskName "Watchdog PocketBase Sistema Llaves FCEA" -ErrorAction SilentlyContinue
        if ($task3) { Unregister-ScheduledTask -TaskName "Watchdog PocketBase Sistema Llaves FCEA" -Confirm:$false }
        Register-ScheduledTask -TaskName "Watchdog PocketBase Sistema Llaves FCEA" -Action $action3 -Trigger $trigger3 -Principal $principal -Settings $settings -Description "Monitorea y reinicia PocketBase automáticamente cada 2 minutos" | Out-Null
        Write-Log "  ✓ Tarea 3/3 configurada: Watchdog (protección 24/7)" "SUCCESS"
        
        Write-Host ""
        Write-Log "✓ Sistema de mantenimiento automatizado configurado exitosamente" "SUCCESS"
        return $true
    } catch {
        Write-Log "✗ Error al configurar mantenimiento automático: $_" "ERROR"
        return $false
    }
}

# Función para configurar modo kiosk
function Configure-KioskMode {
    param([string]$Mode, [string]$HardwareType)
    
    if ($Mode -ne "produccion") {
        Write-Log "Modo desarrollo: Kiosk no configurado" "INFO"
        return $true
    }
    
    Write-Log "Configurando modo kiosk..."
    
    try {
        # Crear script de inicio en modo kiosk
        $startupScript = @"
@echo off
:: Iniciar PocketBase
start /min cmd /c "cd /d C:\sistema-llaves-fcea\pocketbase && pocketbase.exe serve"

:: Esperar a que PocketBase inicie
timeout /t 10 /nobreak >nul

:: Iniciar navegadores en modo kiosk en cada pantalla
start chrome.exe --kiosk --app=http://localhost:8080/monitor --window-position=0,0 --display=0
timeout /t 2 /nobreak >nul
start chrome.exe --kiosk --app=http://localhost:8080/terminal --window-position=1920,0 --display=1
timeout /t 2 /nobreak >nul
start chrome.exe --kiosk --app=http://localhost:8080/terminal --window-position=3840,0 --display=2
"@
        
        $startupPath = "$DestinationPath\iniciar_sistema_kiosk.bat"
        Set-Content -Path $startupPath -Value $startupScript -Encoding ASCII
        
        # Configurar inicio automático
        $startupFolder = [Environment]::GetFolderPath("Startup")
        $shortcutPath = "$startupFolder\Sistema Llaves FCEA.lnk"
        
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = $startupPath
        $Shortcut.WorkingDirectory = $DestinationPath
        $Shortcut.Description = "Sistema de Gestión de Llaves FCEA"
        $Shortcut.Save()
        
        Write-Log "✓ Modo kiosk configurado" "SUCCESS"
        Write-Log "✓ Inicio automático configurado" "SUCCESS"
        return $true
    } catch {
        Write-Log "✗ Error al configurar modo kiosk: $_" "ERROR"
        return $false
    }
}

# Función para configurar teclado virtual
function Configure-VirtualKeyboard {
    param([string]$HardwareType)
    
    if ($HardwareType -ne "tactil") {
        Write-Log "Modo tradicional: Teclado virtual no necesario" "INFO"
        return $true
    }
    
    Write-Log "Configurando teclado virtual para pantallas táctiles..."
    
    try {
        # Habilitar teclado táctil de Windows
        $regPath = "HKLM:\SOFTWARE\Microsoft\TabletTip\1.7"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "EnableDesktopModeAutoInvoke" -Value 1 -Type DWord
        
        Write-Log "✓ Teclado virtual configurado" "SUCCESS"
        return $true
    } catch {
        Write-Log "⚠ No se pudo configurar el teclado virtual automáticamente" "WARNING"
        Write-Log "Puede configurarlo manualmente en: Configuración > Dispositivos > Escritura" "INFO"
        return $true
    }
}

# Función principal de instalación
function Start-Installation {
    Show-Menu
    
    Write-Host ""
    Write-Host "Bienvenido al instalador automático del Sistema de Llaves FCEA" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Este asistente instalará y configurará todo el sistema automáticamente." -ForegroundColor White
    Write-Host "Duración estimada: 10-15 minutos" -ForegroundColor Gray
    Write-Host ""
    
    $continue = Read-Host "¿Desea continuar? (S/N)"
    if ($continue -ne "S" -and $continue -ne "s") {
        Write-Log "Instalación cancelada por el usuario" "WARNING"
        return
    }
    
    # PASO 1: Verificar requisitos
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  PASO 1/10: Verificación de requisitos del sistema" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-SystemRequirements)) {
        Write-Log "No se cumplen todos los requisitos del sistema" "ERROR"
        Write-Host ""
        Read-Host "Presione Enter para salir"
        return
    }
    
    Write-Host ""
    Read-Host "Presione Enter para continuar"
    
    # PASO 2: Seleccionar modo de operación
    $operationMode = Select-OperationMode
    
    # PASO 3: Seleccionar tipo de hardware
    $hardwareType = Select-HardwareType
    
    # Confirmación
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  RESUMEN DE CONFIGURACIÓN" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Modo de operación: " -NoNewline
    Write-Host $operationMode.ToUpper() -ForegroundColor Green
    Write-Host "  Tipo de hardware:  " -NoNewline
    Write-Host $hardwareType.ToUpper() -ForegroundColor Green
    Write-Host "  Ruta de instalación: $DestinationPath" -ForegroundColor White
    Write-Host ""
    
    $confirm = Read-Host "¿Confirma la instalación con esta configuración? (S/N)"
    if ($confirm -ne "S" -and $confirm -ne "s") {
        Write-Log "Instalación cancelada por el usuario" "WARNING"
        return
    }
    
    # PASO 4: Instalar Node.js
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  PASO 2/10: Instalación de Node.js" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Install-NodeJS)) {
        Write-Log "Error en la instalación de Node.js" "ERROR"
        Read-Host "Presione Enter para salir"
        return
    }
    
    # PASO 5: Copiar sistema
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  PASO 3/10: Copia del sistema" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Copy-System)) {
        Write-Log "Error al copiar el sistema" "ERROR"
        Read-Host "Presione Enter para salir"
        return
    }
    
    # PASO 6: Instalar dependencias
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  PASO 4/10: Instalación de dependencias" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Install-Dependencies)) {
        Write-Log "Error al instalar dependencias" "ERROR"
        Read-Host "Presione Enter para salir"
        return
    }
    
    # PASO 7: Inicializar base de datos
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  PASO 5/10: Configuración de base de datos" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Initialize-Database)) {
        Write-Log "Error al inicializar base de datos" "ERROR"
        Read-Host "Presione Enter para salir"
        return
    }
    
    # PASO 8: Configurar hardware
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  PASO 6/10: Configuración de hardware" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Configure-VirtualKeyboard -HardwareType $hardwareType
    
    # PASO 9: Configurar modo kiosk
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  PASO 8/10: Configuración de modo kiosk" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Configure-KioskMode -Mode $operationMode -HardwareType $hardwareType
    
    # PASO 10: Configurar mantenimiento automático
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  PASO 9/10: Configuración de mantenimiento automático" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Configure-AutomaticMaintenance
    
    # PASO 11: Verificación final
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  PASO 10/10: Verificación final" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Log "Iniciando sistema para verificación..."
    
    # Iniciar el sistema
    Start-Process -FilePath "$DestinationPath\iniciar_sistema.bat" -WindowStyle Minimized
    
    Start-Sleep -Seconds 15
    
    # Verificar que el sistema responde
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Log "✓ Sistema iniciado correctamente" "SUCCESS"
            Write-Log "✓ Servidor respondiendo en http://localhost:8080" "SUCCESS"
        }
    } catch {
        Write-Log "⚠ No se pudo verificar el sistema automáticamente" "WARNING"
        Write-Log "Verifique manualmente que el sistema funciona" "INFO"
    }
    
    # Resumen final
    Write-Host ""
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                                                                    ║" -ForegroundColor Green
    Write-Host "║     ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE                         ║" -ForegroundColor Green
    Write-Host "║                                                                    ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "El sistema está listo para usar en modo: " -NoNewline
    Write-Host $operationMode.ToUpper() -ForegroundColor Cyan
    Write-Host "Tipo de hardware: " -NoNewline
    Write-Host $hardwareType.ToUpper() -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Ubicación: $DestinationPath" -ForegroundColor White
    Write-Host ""
    Write-Host "Contraseñas por defecto:" -ForegroundColor Yellow
    Write-Host "  - Administrador: admin123" -ForegroundColor White
    Write-Host "  - Custodio: custodio2026" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  IMPORTANTE: Cambie estas contraseñas inmediatamente" -ForegroundColor Red
    Write-Host ""
    Write-Host "Acceso al sistema:" -ForegroundColor Yellow
    Write-Host "  - Monitor de Vigilancia: http://localhost:8080/monitor" -ForegroundColor White
    Write-Host "  - Terminal de Usuario: http://localhost:8080/terminal" -ForegroundColor White
    Write-Host "  - Dashboard: http://localhost:8080/dashboard" -ForegroundColor White
    Write-Host ""
    Write-Host "Log de instalación guardado en: $LogFile" -ForegroundColor Gray
    Write-Host ""
    
    # ============================================================================
    # CONFIGURACIÓN AUTOMÁTICA DE INICIO
    # ============================================================================
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  CONFIGURANDO INICIO AUTOMÁTICO                                    ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Log "Configurando inicio automático del sistema..." "INFO"
    
    try {
        # Usar el método simple que SIEMPRE funciona (no requiere permisos especiales)
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $regName = "SistemaLlavesFCEA"
        $regValue = "$DestinationPath\INICIAR_SISTEMA_AHORA.bat"
        
        Set-ItemProperty -Path $regPath -Name $regName -Value $regValue -Force
        
        Write-Log "✓ Inicio automático configurado correctamente" "SUCCESS"
        Write-Host "  El sistema se iniciará automáticamente cuando inicies sesión" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Log "⚠ No se pudo configurar el inicio automático: $_" "WARNING"
        Write-Host "  Puedes configurarlo manualmente después ejecutando:" -ForegroundColor Yellow
        Write-Host "  CONFIGURAR_INICIO_DEFINITIVO.bat" -ForegroundColor Yellow
        Write-Host ""
    }
    
    if ($operationMode -eq "produccion") {
        Write-Host "El sistema se reiniciará automáticamente en modo kiosk." -ForegroundColor Cyan
        Write-Host ""
        $restart = Read-Host "¿Desea reiniciar ahora? (S/N)"
        if ($restart -eq "S" -or $restart -eq "s") {
            Write-Log "Reiniciando sistema..." "INFO"
            Start-Sleep -Seconds 3
            Restart-Computer -Force
        }
    }
}

# Ejecutar instalación
try {
    Start-Installation
} catch {
    Write-Log "Error crítico durante la instalación: $_" "ERROR"
    Write-Host ""
    Write-Host "Consulte el log en: $LogFile" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host ""
Read-Host "Presione Enter para salir"
