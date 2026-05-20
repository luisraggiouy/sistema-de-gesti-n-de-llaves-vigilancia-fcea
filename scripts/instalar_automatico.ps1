# ============================================================================
# Script: Instalador Automatico del Sistema de Llaves FCEA
# Version: 3.0 - Con indicadores de progreso y apertura automatica de Chrome
# ============================================================================

$Host.UI.RawUI.WindowTitle = "Instalador Automatico - Sistema de Llaves FCEA"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

$ScriptPath      = Split-Path -Parent $MyInvocation.MyCommand.Path
$PendrivePath    = Split-Path -Parent $ScriptPath
$DestinationPath = "C:\sistema-llaves-fcea"
$LogFile         = "$env:TEMP\instalacion_llaves_fcea.log"

# ---- Funcion de log ----
function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$ts] [$Type] $Message" -ErrorAction SilentlyContinue
    switch ($Type) {
        "ERROR"   { Write-Host $Message -ForegroundColor Red }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        default   { Write-Host $Message -ForegroundColor White }
    }
}

# ---- Barra de progreso animada ----
function Show-Progress {
    param([string]$Mensaje, [int]$Segundos = 3)
    Write-Host ""
    Write-Host "  $Mensaje " -NoNewline -ForegroundColor Cyan
    for ($i = 0; $i -lt $Segundos; $i++) {
        Write-Host "." -NoNewline -ForegroundColor Cyan
        Start-Sleep -Seconds 1
    }
    Write-Host " OK" -ForegroundColor Green
}

# ---- Separador de seccion ----
function Show-Step {
    param([string]$Titulo, [int]$Paso, [int]$Total)
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "  PASO $Paso/$Total : $Titulo" -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# INICIO
# ============================================================================
Clear-Host
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "                                                                    " -ForegroundColor Cyan
Write-Host "     INSTALADOR AUTOMATICO - SISTEMA DE LLAVES FCEA                " -ForegroundColor Cyan
Write-Host "                                                                    " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Este asistente instalara y configurara todo el sistema." -ForegroundColor White
Write-Host "  Duracion estimada: 5-10 minutos." -ForegroundColor Gray
Write-Host ""

$continue = Read-Host "Desea continuar? (S/N)"
if ($continue -ne "S" -and $continue -ne "s") { exit }

# ============================================================================
# PASO 1: Verificar requisitos
# ============================================================================
Show-Step "Verificacion de requisitos" 1 8

$osOK    = ([System.Environment]::OSVersion.Version.Major -ge 10)
$diskGB  = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
$diskOK  = ($diskGB -gt 5)
$ramGB   = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
$ramOK   = ($ramGB -ge 4)
$adminOK = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Log "Windows: $([System.Environment]::OSVersion.Version)  $(if($osOK){'[OK]'}else{'[ERROR]'})" $(if($osOK){"SUCCESS"}else{"ERROR"})
Write-Log "Disco libre: $diskGB GB  $(if($diskOK){'[OK]'}else{'[ERROR] Se requieren 5 GB'})" $(if($diskOK){"SUCCESS"}else{"ERROR"})
Write-Log "RAM: $ramGB GB  $(if($ramOK){'[OK]'}else{'[ERROR] Se requieren 4 GB'})" $(if($ramOK){"SUCCESS"}else{"ERROR"})
Write-Log "Administrador: $(if($adminOK){'[OK]'}else{'[ERROR] Ejecute como Administrador'})" $(if($adminOK){"SUCCESS"}else{"ERROR"})

if (-not ($osOK -and $diskOK -and $ramOK -and $adminOK)) {
    Write-Host ""
    Write-Host "No se cumplen los requisitos. Corrija los errores y vuelva a ejecutar." -ForegroundColor Red
    Read-Host "Presione Enter para salir"
    exit
}

# ============================================================================
# PASO 2: Seleccion de modo y hardware
# ============================================================================
Show-Step "Configuracion de instalacion" 2 8

Write-Host "  Modo de operacion:" -ForegroundColor White
Write-Host "    [1] Produccion (recomendado para uso real)" -ForegroundColor Gray
Write-Host "    [2] Desarrollo (para pruebas)" -ForegroundColor Gray
Write-Host ""
do { $modeChoice = Read-Host "  Seleccione (1 o 2)" } while ($modeChoice -ne "1" -and $modeChoice -ne "2")
$operationMode = if ($modeChoice -eq "1") { "produccion" } else { "desarrollo" }

Write-Host ""
Write-Host "  Tipo de hardware:" -ForegroundColor White
Write-Host "    [1] Pantallas Tactiles" -ForegroundColor Gray
Write-Host "    [2] Monitores Tradicionales (teclado y mouse)" -ForegroundColor Gray
Write-Host ""
do { $hwChoice = Read-Host "  Seleccione (1 o 2)" } while ($hwChoice -ne "1" -and $hwChoice -ne "2")
$hardwareType = if ($hwChoice -eq "1") { "tactil" } else { "tradicional" }

Write-Host ""
Write-Host "  Modo: " -NoNewline; Write-Host $operationMode.ToUpper() -ForegroundColor Green
Write-Host "  Hardware: " -NoNewline; Write-Host $hardwareType.ToUpper() -ForegroundColor Green
Write-Host "  Destino: $DestinationPath" -ForegroundColor White
Write-Host ""
$confirm = Read-Host "Confirma? (S/N)"
if ($confirm -ne "S" -and $confirm -ne "s") { exit }

# ============================================================================
# PASO 3: Instalar Node.js
# ============================================================================
Show-Step "Instalacion de Node.js" 3 8

# Actualizar PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$nodeOK = $false
try {
    $ver = & node --version 2>$null
    if ($ver) { Write-Log "Node.js ya instalado: $ver" "SUCCESS"; $nodeOK = $true }
} catch {}

if (-not $nodeOK) {
    # Buscar en rutas tipicas
    foreach ($ruta in @("C:\Program Files\nodejs\node.exe","C:\Program Files (x86)\nodejs\node.exe","$env:LOCALAPPDATA\Programs\nodejs\node.exe")) {
        if (Test-Path $ruta) {
            $env:Path = (Split-Path $ruta -Parent) + ";" + $env:Path
            Write-Log "Node.js encontrado en $ruta" "SUCCESS"
            $nodeOK = $true; break
        }
    }
}

if (-not $nodeOK) {
    Write-Log "Buscando instalador de Node.js en el pendrive..." "INFO"
    $msi = $null
    foreach ($letra in 'D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z') {
        if (Test-Path "${letra}:\instaladores\node-setup.msi") { $msi = "${letra}:\instaladores\node-setup.msi"; break }
    }
    if (-not $msi) {
        Write-Log "[ERROR] No se encontro node-setup.msi en el pendrive." "ERROR"
        Read-Host "Presione Enter para salir"
        exit
    }
    Write-Host "  Instalando Node.js desde $msi ..." -ForegroundColor Cyan
    Write-Host "  (esto tarda 2-4 minutos, por favor espere)" -ForegroundColor Yellow
    Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet /norestart" -Wait -NoNewWindow
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Start-Sleep -Seconds 5
    try { $ver = & node --version 2>$null; if ($ver) { Write-Log "Node.js instalado: $ver" "SUCCESS"; $nodeOK = $true } } catch {}
    if (-not $nodeOK) {
        foreach ($ruta in @("C:\Program Files\nodejs\node.exe","C:\Program Files (x86)\nodejs\node.exe")) {
            if (Test-Path $ruta) { $env:Path = (Split-Path $ruta -Parent) + ";" + $env:Path; $nodeOK = $true; break }
        }
    }
    if (-not $nodeOK) {
        Write-Log "[ERROR] Node.js no se pudo instalar. Reinicie el equipo e intente de nuevo." "ERROR"
        Read-Host "Presione Enter para salir"
        exit
    }
}

# ============================================================================
# PASO 4: Copiar sistema
# ============================================================================
Show-Step "Copia del sistema al disco" 4 8

if (Test-Path $DestinationPath) {
    $backup = "${DestinationPath}_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Host "  Creando respaldo del sistema anterior..." -ForegroundColor Yellow
    Move-Item -Path $DestinationPath -Destination $backup -Force
    Write-Log "Respaldo creado: $backup" "SUCCESS"
}

Write-Host "  Copiando archivos del sistema..." -ForegroundColor Cyan
Write-Host "  (puede tardar 2-5 minutos dependiendo del pendrive)" -ForegroundColor Yellow

# IMPORTANTE: Crear el directorio destino ANTES de copiar
# Si no existe, Copy-Item copia la carpeta "sistema" dentro del destino
# en lugar de copiar el CONTENIDO directamente
New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null

$sistemaSrc = "$PendrivePath\sistema"
Write-Host "  Origen: $sistemaSrc" -ForegroundColor Gray
Write-Host "  Destino: $DestinationPath" -ForegroundColor Gray

# Copiar el CONTENIDO de sistema\* al destino (no la carpeta en si)
# Se copian primero los archivos sueltos, luego las carpetas grandes
$copyJob = Start-Job -ScriptBlock {
    param($src, $dst)
    # Primero copiar archivos sueltos (package.json, index.html, etc.)
    Get-ChildItem -Path $src -File | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $dst -Force -ErrorAction SilentlyContinue
    }
    # Luego copiar carpetas (src, dist, pocketbase, scripts, etc.) excepto node_modules
    Get-ChildItem -Path $src -Directory | Where-Object { $_.Name -ne "node_modules" } | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $dst -Recurse -Force -ErrorAction SilentlyContinue
    }
    # Por ultimo node_modules (la mas pesada)
    $nm = Join-Path $src "node_modules"
    if (Test-Path $nm) {
        $nmDst = Join-Path $dst "node_modules"
        if (-not (Test-Path $nmDst)) { New-Item -ItemType Directory -Path $nmDst -Force | Out-Null }
        Get-ChildItem -Path $nm | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $nmDst -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
} -ArgumentList $sistemaSrc, $DestinationPath

$dots = 0
while ($copyJob.State -eq "Running") {
    Write-Host "." -NoNewline -ForegroundColor Cyan
    $dots++
    if ($dots % 60 -eq 0) { Write-Host "" }
    Start-Sleep -Seconds 1
}
Receive-Job $copyJob -ErrorAction SilentlyContinue
Remove-Job $copyJob

if (Test-Path "$DestinationPath\package.json") {
    Write-Log "`n[OK] Sistema copiado correctamente a $DestinationPath" "SUCCESS"
} else {
    # Verificar si se copio dentro de una subcarpeta por error
    if (Test-Path "$DestinationPath\sistema\package.json") {
        Write-Log "`n[AVISO] Sistema copiado en subcarpeta, moviendo..." "WARNING"
        Get-ChildItem "$DestinationPath\sistema" | ForEach-Object {
            Move-Item -Path $_.FullName -Destination $DestinationPath -Force -ErrorAction SilentlyContinue
        }
        Remove-Item "$DestinationPath\sistema" -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path "$DestinationPath\package.json") {
        Write-Log "[OK] Sistema copiado correctamente a $DestinationPath" "SUCCESS"
    } else {
        Write-Log "`n[ERROR] Error al copiar el sistema. Origen: $sistemaSrc" "ERROR"
        Write-Host "  Contenido del destino:" -ForegroundColor Yellow
        Get-ChildItem $DestinationPath -ErrorAction SilentlyContinue | Select-Object Name | Format-Table -AutoSize
        Read-Host "Presione Enter para salir"
        exit
    }
}

# ============================================================================
# PASO 5: Instalar dependencias (node_modules)
# ============================================================================
Show-Step "Instalacion de dependencias" 5 8

$nmDst = "$DestinationPath\node_modules"

# Buscar node_modules en el pendrive (busca la letra correcta del pendrive)
$nmSrc = $null
foreach ($letra in 'D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z') {
    if (Test-Path "${letra}:\sistema\node_modules") { $nmSrc = "${letra}:\sistema\node_modules"; break }
}

if ($nmSrc) {
    Write-Host "  Copiando dependencias desde el pendrive..." -ForegroundColor Cyan
    Write-Host "  (puede tardar 3-8 minutos, por favor espere)" -ForegroundColor Yellow

    # Eliminar destino si ya existe para evitar duplicacion
    if (Test-Path $nmDst) {
        Write-Host "  Eliminando dependencias anteriores..." -ForegroundColor Yellow
        Remove-Item -Path $nmDst -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $nmDst -Force | Out-Null

    $nmJob = Start-Job -ScriptBlock {
        param($src, $dst)
        # Copiar contenido de node_modules (no la carpeta en si)
        Get-ChildItem -Path $src | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $dst -Recurse -Force -ErrorAction SilentlyContinue
        }
    } -ArgumentList $nmSrc, $nmDst

    $dots = 0
    while ($nmJob.State -eq "Running") {
        Write-Host "." -NoNewline -ForegroundColor Cyan
        $dots++
        if ($dots % 60 -eq 0) { Write-Host "" }
        Start-Sleep -Seconds 1
    }
    Receive-Job $nmJob -ErrorAction SilentlyContinue
    Remove-Job $nmJob

    if (Test-Path "$nmDst\vite") {
        Write-Log "`n[OK] Dependencias copiadas correctamente" "SUCCESS"
    } else {
        Write-Log "`n[AVISO] Dependencias incompletas. Ejecutando npm install..." "WARNING"
        $proc = Start-Process "npm" -ArgumentList "install" -WorkingDirectory $DestinationPath -Wait -NoNewWindow -PassThru
        if ($proc.ExitCode -ne 0) {
            Write-Log "[ERROR] npm install fallo" "ERROR"
            Read-Host "Presione Enter para salir"
            exit
        }
    }
} else {
    Write-Host "  node_modules no encontrado en pendrive. Ejecutando npm install..." -ForegroundColor Yellow
    Write-Host "  (requiere internet, puede tardar 10-15 minutos)" -ForegroundColor Yellow
    $proc = Start-Process "npm" -ArgumentList "install" -WorkingDirectory $DestinationPath -Wait -NoNewWindow -PassThru
    if ($proc.ExitCode -eq 0) {
        Write-Log "[OK] npm install completado" "SUCCESS"
    } else {
        Write-Log "[ERROR] npm install fallo" "ERROR"
        Read-Host "Presione Enter para salir"
        exit
    }
}

# ============================================================================
# PASO 6: Configurar inicio automatico
# ============================================================================
Show-Step "Configuracion de inicio automatico" 6 8

try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $regPath -Name "SistemaLlavesFCEA" -Value "$DestinationPath\iniciar_sistema.bat" -Force
    Write-Log "[OK] Inicio automatico configurado (se iniciara al iniciar sesion)" "SUCCESS"
} catch {
    Write-Log "[AVISO] No se pudo configurar inicio automatico: $_" "WARNING"
}

# ============================================================================
# PASO 7: Configurar mantenimiento automatico
# ============================================================================
Show-Step "Configuracion de mantenimiento" 7 8

try {
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    $action1  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$DestinationPath\pocketbase\maintenance\system_maintenance.ps1`""
    $trigger1 = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 8:00AM
    Register-ScheduledTask -TaskName "Mantenimiento Sistema Llaves FCEA" -Action $action1 -Trigger $trigger1 -Principal $principal -Settings $settings -Force | Out-Null

    $action2  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$DestinationPath\scripts\watchdog_completo.ps1`""
    $trigger2 = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName "Watchdog Sistema Llaves FCEA" -Action $action2 -Trigger $trigger2 -Principal $principal -Settings $settings -Force | Out-Null

    Write-Log "[OK] Mantenimiento automatico configurado" "SUCCESS"
} catch {
    Write-Log "[AVISO] No se pudo configurar mantenimiento: $_" "WARNING"
}

# ============================================================================
# PASO 8: Iniciar el sistema y abrir Chrome
# ============================================================================
Show-Step "Iniciando el sistema" 8 8

Write-Host "  Iniciando PocketBase (base de datos)..." -ForegroundColor Cyan
$pbExe = "$DestinationPath\pocketbase\pocketbase.exe"
if (Test-Path $pbExe) {
    Start-Process -FilePath $pbExe -ArgumentList "serve","--http=127.0.0.1:8090" -WorkingDirectory "$DestinationPath\pocketbase" -WindowStyle Hidden
    Start-Sleep -Seconds 4
    Write-Log "[OK] PocketBase iniciado" "SUCCESS"
} else {
    Write-Log "[ERROR] No se encontro pocketbase.exe en $pbExe" "ERROR"
}

# Verificar si existe dist compilado
$distPath = "$DestinationPath\dist\assets"
if (Test-Path $distPath) {
    Write-Host "  Iniciando Frontend (modo produccion con dist compilado)..." -ForegroundColor Cyan
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c","cd /d `"$DestinationPath`" && npm run preview -- --port 8080 --host" -WindowStyle Hidden
} else {
    Write-Host "  Iniciando Frontend (modo desarrollo)..." -ForegroundColor Cyan
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c","cd /d `"$DestinationPath`" && npm run dev -- --port 8080 --host" -WindowStyle Hidden
}

Write-Host "  Esperando que el sistema arranque" -NoNewline -ForegroundColor Cyan
$listo = $false
for ($i = 0; $i -lt 24; $i++) {
    Start-Sleep -Seconds 5
    Write-Host "." -NoNewline -ForegroundColor Cyan
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 3 -UseBasicParsing -ErrorAction SilentlyContinue
        if ($resp.StatusCode -eq 200) { $listo = $true; break }
    } catch {}
}
Write-Host ""

if ($listo) {
    Write-Log "[OK] Sistema listo en http://localhost:8080" "SUCCESS"
} else {
    Write-Log "[AVISO] El sistema tarda mas de lo esperado. Abriendo navegador de todas formas..." "WARNING"
    Start-Sleep -Seconds 8
}

# Abrir Chrome
Write-Host ""
Write-Host "  Abriendo el sistema en el navegador..." -ForegroundColor Cyan

$chrome = $null
foreach ($p in @("C:\Program Files\Google\Chrome\Application\chrome.exe","C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")) {
    if (Test-Path $p) { $chrome = $p; break }
}

if ($chrome) {
    Start-Process $chrome -ArgumentList "--new-window","http://localhost:8080/monitor"
    Start-Sleep -Seconds 2
    Start-Process $chrome -ArgumentList "http://localhost:8080/terminal"
    Write-Log "[OK] Chrome abierto con el sistema" "SUCCESS"
} else {
    Start-Process "http://localhost:8080/monitor"
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:8080/terminal"
    Write-Log "[OK] Navegador predeterminado abierto" "SUCCESS"
}

# ============================================================================
# RESUMEN FINAL
# ============================================================================
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "  [OK] INSTALACION COMPLETADA EXITOSAMENTE                         " -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Modo:     $($operationMode.ToUpper())" -ForegroundColor Cyan
Write-Host "  Hardware: $($hardwareType.ToUpper())" -ForegroundColor Cyan
Write-Host "  Ubicacion: $DestinationPath" -ForegroundColor White
Write-Host ""
Write-Host "  Contrasenas por defecto:" -ForegroundColor Yellow
Write-Host "    Administrador: admin123" -ForegroundColor White
Write-Host "    Custodio:      custodio2026" -ForegroundColor White
Write-Host ""
Write-Host "  IMPORTANTE: Cambie las contrasenas inmediatamente" -ForegroundColor Red
Write-Host ""
Write-Host "  Acceso al sistema:" -ForegroundColor Yellow
Write-Host "    Monitor:  http://localhost:8080/monitor" -ForegroundColor White
Write-Host "    Terminal: http://localhost:8080/terminal" -ForegroundColor White
Write-Host "    Dashboard:http://localhost:8080/dashboard" -ForegroundColor White
Write-Host ""
Write-Host "  El sistema se iniciara automaticamente al encender el equipo." -ForegroundColor Green
Write-Host ""
Write-Host "  Log: $LogFile" -ForegroundColor Gray
Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "  El sistema ya esta abierto en el navegador.                      " -ForegroundColor Green
Write-Host "  Puede cerrar esta ventana.                                       " -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Presione Enter para cerrar este instalador"
