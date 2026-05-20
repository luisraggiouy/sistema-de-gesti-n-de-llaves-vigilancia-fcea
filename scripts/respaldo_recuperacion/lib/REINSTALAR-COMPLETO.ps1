# =====================================================================
#  REINSTALAR COMPLETO SISTEMA DE LLAVES FCEA   (v2.0 - mayo 2026)
# =====================================================================
#  Este script:
#   1) Detecta si existe configuracion previa (install_config.json o
#      registro en sistema_config de PocketBase). Si la encuentra,
#      ofrece reinstalar IDENTICO o cambiar.
#   2) Si no hay config previa, pide modo + hardware como un instalador.
#   3) Hace respaldo de la base de datos actual (si existe).
#   4) Borra TODA la instalacion vieja excepto pb_data.
#   5) Copia el sistema desde el pendrive desde cero.
#   6) Restaura los datos historicos del pendrive.
#   7) Instala dependencias (con manejo limpio de warnings deprecated).
#   8) Persiste install_config.json + sincroniza PocketBase.
#   9) Arranca todo y abre Chrome en kiosk en cada monitor segun config.
# =====================================================================

$ErrorActionPreference = "Continue"
$Host.UI.RawUI.WindowTitle = "REINSTALAR COMPLETO SISTEMA DE LLAVES FCEA v2.0"

# ---------------------------------------------------------------------
# Helpers de presentacion
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
# IMPORTANTE: cuando el .bat invoca este .ps1 con "& 'ruta\script.ps1'"
# desde un -Command externo, $PSCommandPath puede llegar vacio. Usamos
# fallback robusto: $MyInvocation.MyCommand.Path o $PSScriptRoot.
$thisScriptPath = $PSCommandPath
if ([string]::IsNullOrWhiteSpace($thisScriptPath)) { $thisScriptPath = $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($thisScriptPath) -and $PSScriptRoot) { $thisScriptPath = Join-Path $PSScriptRoot "_dummy.ps1" }
$PENDRIVE_DIR_LIB = if ($thisScriptPath) { Split-Path -Parent $thisScriptPath } else { Get-Location }
# El .ps1 vive en <pendrive>\lib\, asi que el pendrive es el padre del padre del .ps1
$PENDRIVE_DIR    = Split-Path -Parent $PENDRIVE_DIR_LIB
$LIB_DIR_LOCAL   = $PENDRIVE_DIR_LIB                                # En el pendrive (las libs estan en el mismo dir que este .ps1)
# $LIB_DIR_REPO  : ruta `scripts/lib` cuando se ejecuta desde el repo en
# `scripts/respaldo_recuperacion/lib/`. Si se ejecuta DESDE LA RAIZ DE UN
# PENDRIVE (ej. E:\lib\), $PENDRIVE_DIR sera "E:\" y Split-Path -Parent "E:\"
# devuelve "" (string vacio), lo que rompe Join-Path. Protegemos el caso.
$_padre = Split-Path -Parent $PENDRIVE_DIR
if ([string]::IsNullOrWhiteSpace($_padre)) {
    # Estamos en la raiz del pendrive: no hay carpeta "scripts/lib" del repo
    # disponible. $LIB_DIR_LOCAL (las libs al lado de este .ps1) alcanza.
    $LIB_DIR_REPO = $LIB_DIR_LOCAL
} else {
    $LIB_DIR_REPO = Join-Path $_padre "lib"
}
$SISTEMA_DIR_NUEVO = "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"  # Mantener ruta historica
$SISTEMA_DIR_VIEJO = "C:\sistema-llaves-fcea"
$LOG_FILE        = Join-Path $PENDRIVE_DIR "ultimo_log_reinstalacion.txt"

# Funcion log a archivo
"=== REINSTALACION INICIADA $(Get-Date) ===" | Out-File -FilePath $LOG_FILE -Encoding UTF8
function Log($texto) {
    "$(Get-Date -Format 'HH:mm:ss') $texto" | Out-File -FilePath $LOG_FILE -Append -Encoding UTF8
}

# Determinar SISTEMA_DIR (prioridad: nueva > vieja > nueva por defecto)
$SISTEMA_DIR = if (Test-Path $SISTEMA_DIR_NUEVO) { $SISTEMA_DIR_NUEVO }
               elseif (Test-Path $SISTEMA_DIR_VIEJO) { $SISTEMA_DIR_VIEJO }
               else { $SISTEMA_DIR_NUEVO }

# ---------------------------------------------------------------------
# Cargar librerias (probamos primero del pendrive, luego del repo)
# IMPORTANTE: NO encapsular el dot-source en una funcion: las funciones
# cargadas dentro de una funcion solo viven en su scope local y se
# pierden al retornar. Hay que hacer el `. $p` en el scope del script.
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
            try {
                . $p
                Log "  Cargada: $lib"
            } catch {
                Log "  ERROR cargando $lib : $_"
                $todasOk = $false
            }
        } else {
            Log "  NO existe: $p"
            $todasOk = $false
        }
    }
    if ($todasOk) {
        $libsCargadas = $true
        Log "Librerias cargadas OK desde $candidato"
        # Verificacion explicita: la funcion clave debe estar disponible
        if (-not (Get-Command Get-DeteccionHardwareCompleta -ErrorAction SilentlyContinue)) {
            Log "WARNING: aunque dot-source no fallo, Get-DeteccionHardwareCompleta NO esta disponible"
            $libsCargadas = $false
        } else {
            break
        }
    }
}
if (-not $libsCargadas) {
    Write-Aviso "Librerias auxiliares no encontradas. El recuperador funcionara en modo SIMPLE."
    Log "WARNING: Librerias auxiliares no encontradas. Modo simple."
}

# ---------------------------------------------------------------------
# Funciones del flujo de configuracion
# ---------------------------------------------------------------------
function Get-ConfigPrevia {
    if (-not $libsCargadas) { return $null }
    try {
        return Get-InstallConfigSmart
    } catch {
        Log "Error en Get-InstallConfigSmart: $_"
        return $null
    }
}

function Read-ConfigInstaladorInteractivo {
    # Pregunta modo y hardware al usuario y devuelve un objeto config nuevo.
    Write-Host ""
    Write-Host "  CONFIGURACION DE INSTALACION" -ForegroundColor Cyan
    Write-Host "  ----------------------------" -ForegroundColor DarkCyan

    Write-Host ""
    Write-Host "  Modo de operacion:" -ForegroundColor White
    Write-Host "    [1] Produccion (uso real)" -ForegroundColor Gray
    Write-Host "    [2] Desarrollo (1 monitor con botones de alternancia)" -ForegroundColor Gray
    do { $modeChoice = Read-Host "  Seleccione (1 o 2)" } while ($modeChoice -ne "1" -and $modeChoice -ne "2")
    $modo = if ($modeChoice -eq "1") { "produccion" } else { "desarrollo" }

    Write-Host ""
    Write-Host "  Tipo de hardware:" -ForegroundColor White
    Write-Host "    [A] Tactil completo (3 monitores tactiles + webcam)" -ForegroundColor Gray
    Write-Host "    [B] Tradicional (3 monitores + 3 teclados + 3 mouses + webcam)" -ForegroundColor Gray
    Write-Host "    [C] Desarrollo (1 monitor)" -ForegroundColor Gray
    do { $hwChoice = Read-Host "  Seleccione (A, B o C)" } while ($hwChoice -notmatch '^[ABCabc]$')
    $hardware = switch ($hwChoice.ToUpper()) {
        'A' { 'tactil' }
        'B' { 'tradicional' }
        'C' { 'desarrollo' }
    }

    if ($libsCargadas) {
        Write-Host ""
        Write-Host "  Detectando hardware en esta PC..." -ForegroundColor Cyan
        $det = Get-DeteccionHardwareCompleta
        Show-DeteccionResumen -Deteccion $det

        $notas = ""
        if ($modo -eq 'produccion' -and $hardware -ne 'desarrollo' -and $det.cantidad_monitores -lt 3) {
            $notas = "Se detectaron solo $($det.cantidad_monitores) monitores. Para uso completo se requieren 3."
            Write-Aviso $notas
        }
        if ($hardware -ne 'desarrollo' -and $det.cantidad_webcams -lt 1) {
            $notas2 = "No se detecto webcam. El monitor de vigilancia no podra tomar fotos."
            $notas = if ($notas) { "$notas $notas2" } else { $notas2 }
            Write-Aviso $notas2
        }

        return New-InstallConfig -Modo $modo -Hardware $hardware -Deteccion $det -Notas $notas
    } else {
        # Sin librerias -> objeto minimo para que el resto del flujo no se rompa
        return [PSCustomObject]@{
            version='1.0'; modo=$modo; hardware=$hardware
            fecha_instalacion=(Get-Date).ToString('o')
            pc_identifier=$env:COMPUTERNAME
            monitores=$null; dispositivos=$null; notas='libs no cargadas'
        }
    }
}

# =====================================================================
# INICIO DEL FLUJO
# =====================================================================
try {
    Clear-Host
    Write-Titulo "REINSTALACION COMPLETA DEL SISTEMA  v2.0"
    Write-Host " ATENCION: Este proceso reinstalara TODO el sistema desde cero." -ForegroundColor Yellow
    Write-Host " Sus datos seran respaldados antes de proceder." -ForegroundColor Yellow
    Write-Host ""
    Write-Host " Pendrive: $PENDRIVE_DIR" -ForegroundColor Gray
    Write-Host " Destino : $SISTEMA_DIR" -ForegroundColor Gray
    Write-Host ""
    $resp = Read-Host " Escriba SI y presione Enter para continuar (o cierre para cancelar)"
    if ($resp -ne "SI") {
        Write-Host ""
        Write-Aviso "Reinstalacion CANCELADA por el usuario."
        Read-Host " Presione Enter para cerrar"
        return
    }

    # =================================================================
    # PASO 0: Determinar configuracion (FLUJO INTELIGENTE)
    # =================================================================
    Write-Paso "0/9" "Determinando configuracion (instalacion nueva o reinstalacion)..."

    $configActiva = $null
    $previa = Get-ConfigPrevia

    if ($previa) {
        Write-OK ("Configuracion previa detectada (origen: {0})" -f $previa.origen)
        if ($libsCargadas) { Show-InstallConfigResumen -Config $previa.config }

        Write-Host ""
        Write-Host "  Opciones:" -ForegroundColor Cyan
        Write-Host "    [S] Reinstalar IGUAL a esta configuracion" -ForegroundColor White
        Write-Host "    [N] Cambiar a otra configuracion (mostrar dialogos)" -ForegroundColor White
        do { $op = Read-Host "  Su eleccion (S/N)" } while ($op -notmatch '^[SsNn]$')
        if ($op -match '^[Ss]$') {
            $configActiva = $previa.config
            Write-OK "Se reinstalara con la configuracion previa."
        } else {
            $configActiva = Read-ConfigInstaladorInteractivo
            Write-OK "Nueva configuracion seleccionada."
        }
    } else {
        Write-Aviso "No se encontro configuracion previa (instalacion nueva)."
        $configActiva = Read-ConfigInstaladorInteractivo
        Write-OK "Configuracion seleccionada para instalacion nueva."
    }
    Log ("Modo={0} Hardware={1}" -f $configActiva.modo, $configActiva.hardware)

    # =================================================================
    # PASO 1: Detener procesos y limpiar tareas viejas
    # =================================================================
    Write-Paso "1/9" "Deteniendo procesos y limpiando tareas programadas..."
    Get-Process pocketbase -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    try {
        $conn = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
        foreach ($c in $conn) { Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue }
    } catch { }

    try {
        $todas = schtasks.exe /Query /FO CSV /NH 2>$null | ConvertFrom-Csv -Header Nombre,Proximo,Estado
        foreach ($t in $todas) {
            if ($t.Nombre -and ($t.Nombre -match 'FCEA|Llaves|llave')) {
                $nombre = $t.Nombre.Trim('"').TrimStart('\')
                schtasks.exe /Delete /TN "$nombre" /F 2>&1 | Out-Null
                Write-Host "    Eliminada tarea programada: $nombre" -ForegroundColor DarkGray
            }
        }
    } catch { }

    $startupPaths = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
    )
    foreach ($sp in $startupPaths) {
        if (Test-Path $sp) {
            Get-ChildItem $sp -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'FCEA|Llaves|llave|Sistema' } | ForEach-Object {
                Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            }
        }
    }
    Start-Sleep -Seconds 2
    Write-OK "Procesos detenidos y tareas viejas eliminadas"

    # Cerrar Chrome kiosk si existe
    if ($libsCargadas) {
        try { Stop-ChromeKioskInstancias } catch {}
    }

    # =================================================================
    # PASO 2: Respaldar datos existentes
    # =================================================================
    Write-Paso "2/9" "Respaldando datos actuales (si existen)..."
    $dbActual = "$SISTEMA_DIR\pocketbase\pb_data"
    if (Test-Path "$dbActual\data.db") {
        $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $respaldoDir = "$env:USERPROFILE\Desktop\RESPALDO_LLAVES_FCEA_$stamp"
        New-Item -Path $respaldoDir -ItemType Directory -Force | Out-Null
        Copy-Item -Path "$dbActual\*" -Destination $respaldoDir -Recurse -Force
        Write-OK "Respaldo creado en: $respaldoDir"
        Log "Respaldo: $respaldoDir"
    } else {
        Write-Aviso "No hay datos previos para respaldar"
    }

    # =================================================================
    # PASO 3: Verificar / instalar Node.js
    # =================================================================
    Write-Paso "3/9" "Verificando Node.js..."
    $nodeOk = $false
    try {
        $nodeVer = & node --version 2>&1
        if ($LASTEXITCODE -eq 0) { $nodeOk = $true; Write-OK "Node.js $nodeVer" }
    } catch { }

    if (-not $nodeOk) {
        Write-Aviso "Instalando Node.js..."
        $msi1 = Join-Path $PENDRIVE_DIR "instaladores\node-setup.msi.msi"
        $msi2 = Join-Path $PENDRIVE_DIR "instaladores\node-setup.msi"
        $msi = if (Test-Path $msi1) { $msi1 } elseif (Test-Path $msi2) { $msi2 } else { $null }
        if ($msi) {
            Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /passive" -Wait
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Write-OK "Node.js instalado"
        } else {
            Write-Error2 "No se encontro instalador de Node.js"
            Read-Host " Presione Enter para cerrar"
            return
        }
    }

    # =================================================================
    # PASO 4: Borrar instalacion vieja (excepto pb_data por si acaso)
    # =================================================================
    Write-Paso "4/9" "Eliminando instalacion vieja..."
    if (Test-Path $SISTEMA_DIR) {
        Get-ChildItem -Path $SISTEMA_DIR -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.FullName -ne "$SISTEMA_DIR\pocketbase") {
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        if (Test-Path "$SISTEMA_DIR\pocketbase") {
            Get-ChildItem -Path "$SISTEMA_DIR\pocketbase" -Force -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.Name -ne "pb_data") {
                    Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
        Write-OK "Instalacion vieja eliminada"
    } else {
        Write-OK "No habia instalacion previa"
    }

    # =================================================================
    # PASO 5: Copiar archivos del sistema desde el pendrive
    # =================================================================
    Write-Paso "5/9" "Copiando sistema desde el pendrive..."
    $sistemaPendrive = Join-Path $PENDRIVE_DIR "sistema"
    if (-not (Test-Path $sistemaPendrive)) {
        Write-Error2 "No se encontro carpeta 'sistema' en el pendrive: $sistemaPendrive"
        return
    }
    if (-not (Test-Path $SISTEMA_DIR)) {
        New-Item -Path $SISTEMA_DIR -ItemType Directory -Force | Out-Null
    }

    # Calcular tamano total para mostrar progreso real
    Write-Host "    Calculando archivos a copiar..." -ForegroundColor Gray
    try {
        $stats = Get-ChildItem $sistemaPendrive -Recurse -File -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum
        $totalMB = [math]::Round($stats.Sum / 1MB, 1)
        $totalArchivos = $stats.Count
        Write-Host ("    A copiar: {0} archivos, {1} MB" -f $totalArchivos, $totalMB) -ForegroundColor Gray
    } catch {
        $totalMB = 0; $totalArchivos = 0
    }

    Write-Host "    Copiando archivos (espere, esto puede tardar varios minutos)..." -ForegroundColor Gray
    Write-Host "    -> Ira mostrando avance cada 3 segundos." -ForegroundColor DarkGray

    $rcArgs = @("`"$sistemaPendrive`"", "`"$SISTEMA_DIR`"", "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/nc", "/ns", "/np", "/R:1", "/W:1")
    $rc = Start-Process robocopy.exe -ArgumentList $rcArgs -WindowStyle Hidden -PassThru
    $tInicio = Get-Date
    while (-not $rc.HasExited) {
        Start-Sleep -Seconds 3
        try {
            $copiados = Get-ChildItem $SISTEMA_DIR -Recurse -File -ErrorAction SilentlyContinue |
                        Measure-Object -Property Length -Sum
            $mbCop = [math]::Round($copiados.Sum / 1MB, 1)
            $segs = [int]((Get-Date) - $tInicio).TotalSeconds
            if ($totalMB -gt 0) {
                $pct = [math]::Min(100, [int](($mbCop / $totalMB) * 100))
                Write-Host ("    ... {0}% ({1} / {2} MB, {3}s)" -f $pct, $mbCop, $totalMB, $segs) -ForegroundColor DarkCyan
            } else {
                Write-Host ("    ... copiados {0} MB ({1}s)" -f $mbCop, $segs) -ForegroundColor DarkCyan
            }
        } catch { }
    }
    Log "Robocopy exit: $($rc.ExitCode)"
    Write-OK "Sistema copiado"

    # =================================================================
    # PASO 6: Restaurar base de datos del pendrive
    # =================================================================
    Write-Paso "6/9" "Restaurando base de datos del pendrive..."
    $dbPendriveDir = Join-Path $PENDRIVE_DIR "respaldos_db\pb_data_ultimo"
    if (Test-Path "$dbPendriveDir\data.db") {
        $pbDataDir = "$SISTEMA_DIR\pocketbase\pb_data"
        if (-not (Test-Path $pbDataDir)) { New-Item -Path $pbDataDir -ItemType Directory -Force | Out-Null }
        Copy-Item -Path "$dbPendriveDir\*" -Destination $pbDataDir -Recurse -Force
        Write-OK "Base de datos restaurada"
    } else {
        Write-Aviso "No hay base de datos en el pendrive (sistema iniciara vacio)"
    }

    # =================================================================
    # PASO 7: Instalar dependencias (con manejo limpio de warnings)
    # -----------------------------------------------------------------
    # Antes la salida de "npm warn deprecated ..." iba a stderr y PowerShell
    # la convertia en RemoteException pintada en rojo, asustando al usuario
    # aunque la instalacion era exitosa. Lo evitamos:
    #   1) Redirigimos stderr de cmd hacia stdout (`2>&1`).
    #   2) NO usamos Tee-Object con $LASTEXITCODE -- en su lugar capturamos
    #      la salida en una variable y la escribimos al log nosotros.
    #   3) Filtramos las lineas para mostrar solo las informativas en la
    #      consola en color discreto.
    # =================================================================
    Write-Paso "7/9" "Instalando dependencias (puede tardar 3-5 min)..."
    Push-Location $SISTEMA_DIR
    try {
        Write-Host "    Lanzando npm install en segundo plano (vea avance cada 4 seg)..." -ForegroundColor Gray
        # Lanzar npm en segundo plano, salida a un log aparte, y monitorear
        # cuantas carpetas hay en node_modules para mostrar progreso real.
        $npmLog = Join-Path $PENDRIVE_DIR "ultimo_log_npm_install.txt"
        $npmProc = Start-Process -FilePath "cmd.exe" `
            -ArgumentList "/c","npm install --no-audit --no-fund --loglevel=warn > `"$npmLog`" 2>&1" `
            -WorkingDirectory $SISTEMA_DIR -WindowStyle Hidden -PassThru
        $tIni = Get-Date
        $nodeModulesPath = Join-Path $SISTEMA_DIR "node_modules"
        while (-not $npmProc.HasExited) {
            Start-Sleep -Seconds 4
            $segs = [int]((Get-Date) - $tIni).TotalSeconds
            $cantPkgs = 0
            if (Test-Path $nodeModulesPath) {
                try {
                    $cantPkgs = (Get-ChildItem $nodeModulesPath -Directory -ErrorAction SilentlyContinue).Count
                } catch { }
            }
            Write-Host ("    ... npm install corriendo ({0}s, {1} paquetes descargados)" -f $segs, $cantPkgs) -ForegroundColor DarkCyan
        }
        $exitCode = $npmProc.ExitCode

        # Volcar log de npm al log principal y dar resumen
        if (Test-Path $npmLog) {
            "----- Inicio salida npm install -----" | Out-File -FilePath $LOG_FILE -Append -Encoding UTF8
            Get-Content $npmLog | Out-File -FilePath $LOG_FILE -Append -Encoding UTF8
            "----- Fin salida npm install -----"    | Out-File -FilePath $LOG_FILE -Append -Encoding UTF8

            $salida = Get-Content $npmLog
            $lineasInfo  = $salida | Where-Object { $_ -match '^added|^changed|^removed|^audited|^up to date' }
            $cantWarn    = ($salida | Where-Object { $_ -match '^npm warn' } | Measure-Object).Count
            $cantError   = ($salida | Where-Object { $_ -match '^npm err'  } | Measure-Object).Count
            foreach ($l in $lineasInfo) { Write-Host "    $l" -ForegroundColor DarkGreen }
            if ($cantWarn -gt 0)  { Write-Host "    ($cantWarn warnings deprecated ignorados, son cosmeticos)" -ForegroundColor DarkGray }
            if ($cantError -gt 0) { Write-Aviso "$cantError lineas de error en npm install (revise el log)" }
        }

        if ($exitCode -eq 0 -and (Test-Path "$SISTEMA_DIR\node_modules")) {
            Write-OK "Dependencias instaladas"
        } else {
            Write-Error2 "npm install termino con codigo $exitCode. Revise el log: $LOG_FILE"
        }
    } finally {
        Pop-Location
    }

    # =================================================================
    # PASO 8: Iniciar todo y persistir configuracion
    # =================================================================
    Write-Paso "8/9" "Iniciando servicios..."

    # PocketBase
    Start-Process -FilePath "$SISTEMA_DIR\pocketbase\pocketbase.exe" `
        -ArgumentList "serve","--http=127.0.0.1:8090" `
        -WorkingDirectory "$SISTEMA_DIR\pocketbase" -WindowStyle Minimized
    Start-Sleep -Seconds 4
    Write-OK "PocketBase iniciado"

    # Frontend (vite preview o dev)
    $usaDist = Test-Path "$SISTEMA_DIR\dist\assets"
    if ($usaDist) {
        $cmdArgs = "/k cd /d `"$SISTEMA_DIR`" && npm run preview -- --port 8080 --host"
    } else {
        $cmdArgs = "/k cd /d `"$SISTEMA_DIR`" && npm run dev -- --port 8080 --host"
    }
    Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -WindowStyle Normal

    # Esperar hasta que el frontend conteste 200
    if ($libsCargadas) {
        $frontendOk = Wait-FrontendReady -BaseUrl "http://localhost:8080" -TimeoutSec 120
    } else {
        Write-Host "    Esperando frontend..." -NoNewline
        $frontendOk = $false
        for ($i = 1; $i -le 30; $i++) {
            Start-Sleep -Seconds 3
            try {
                $r = Invoke-WebRequest -Uri "http://localhost:8080/" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
                if ($r.StatusCode -eq 200) { $frontendOk = $true; break }
            } catch { }
            Write-Host "." -NoNewline
        }
        Write-Host ""
    }
    if ($frontendOk) { Write-OK "Frontend listo" } else { Write-Aviso "Frontend tarda mas de lo esperado" }

    # Persistir configuracion (JSON local + PocketBase)
    if ($libsCargadas) {
        # Refrescar deteccion de hardware AHORA (despues de copiar todo) por
        # si el usuario conecto/desconecto algo durante la instalacion.
        try {
            $detPost = Get-DeteccionHardwareCompleta
            # Si el config actual NO tiene asignacion (fue tomado de un previa
            # parcial) o el modo es produccion y el numero de monitores cambio,
            # rehacemos la asignacion con la deteccion fresca, manteniendo
            # modo+hardware elegidos.
            if (-not $configActiva.monitores -or
                -not $configActiva.monitores.asignacion -or
                ($configActiva.modo -eq 'produccion' -and
                 $configActiva.monitores.cantidad -ne $detPost.cantidad_monitores)) {
                $configActiva = New-InstallConfig -Modo $configActiva.modo `
                                                  -Hardware $configActiva.hardware `
                                                  -Deteccion $detPost `
                                                  -Notas "Reasignado en reinstalacion"
            }
        } catch { Log "Error refrescando deteccion: $_" }

        $jsonPath = Save-InstallConfigLocal -Config $configActiva
        Write-OK "Config guardada: $jsonPath"

        if (Save-InstallConfigPocketBase -Config $configActiva) {
            Write-OK "Config sincronizada en PocketBase"
        } else {
            Write-Aviso "PocketBase aun no responde - se guardara solo el JSON local"
        }
    }

    # =================================================================
    # PASO 9: Abrir navegador segun configuracion
    # =================================================================
    Write-Paso "9/9" "Abriendo el sistema en cada monitor segun configuracion..."

    if ($libsCargadas -and $configActiva.monitores -and $configActiva.monitores.asignacion) {
        Open-SistemaEnMonitores -Config $configActiva -BaseUrl "http://localhost:8080"
        Write-OK "Ventanas abiertas"
    } else {
        # Fallback: comportamiento clasico
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
            Start-Sleep 3
            Start-Process $br -ArgumentList "http://localhost:8080/terminal"
        } else {
            Start-Process "http://localhost:8080/monitor"
            Start-Sleep 3
            Start-Process "http://localhost:8080/terminal"
        }
        Write-OK "Navegador abierto (modo simple)"
    }

    # =================================================================
    # FIN
    # =================================================================
    Write-Titulo "REINSTALACION COMPLETA EXITOSA"
    Write-Host (" Modo     : {0}" -f $configActiva.modo) -ForegroundColor White
    Write-Host (" Hardware : {0}" -f $configActiva.hardware) -ForegroundColor White
    Write-Host ""
    Write-Host " Monitor  : http://localhost:8080/monitor"   -ForegroundColor White
    Write-Host " Terminal : http://localhost:8080/terminal"  -ForegroundColor White
    Write-Host " Dashboard: http://localhost:8080/dashboard" -ForegroundColor White
    Write-Host ""
    Write-Host " IMPORTANTE: NO cierre la ventana cmd.exe del frontend" -ForegroundColor Yellow
    Log "Reinstalacion finalizada OK"

} catch {
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Red
    Write-Host " ERROR EN LA REINSTALACION" -ForegroundColor Red
    Write-Host "=====================================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Log "ERROR: $($_.Exception.Message)"
    Log $_.ScriptStackTrace
}

# Final: NO cerrar solo. Esperar que el usuario presione Enter.
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " Presione Enter para cerrar esta ventana (el sistema" -ForegroundColor Cyan
Write-Host " seguira corriendo en segundo plano)." -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
try { [void](Read-Host) } catch { }
