# ============================================================================
# Script: Desinstalador Completo - Sistema de Llaves FCEA   (v2.0)
# ----------------------------------------------------------------------------
# Elimina TODOS los rastros del sistema en la PC. Funciona con instalaciones
# en cualquiera de las dos rutas posibles:
#       C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea  (actual)
#       C:\sistema-llaves-fcea                            (legacy)
#
# Uso: Ejecutar como Administrador.
# ============================================================================

$Host.UI.RawUI.WindowTitle = "Desinstalador - Sistema de Llaves FCEA v2.0"
Clear-Host

Write-Host "====================================================================" -ForegroundColor Red
Write-Host "   DESINSTALADOR COMPLETO - SISTEMA DE LLAVES FCEA  v2.0           " -ForegroundColor Red
Write-Host "====================================================================" -ForegroundColor Red
Write-Host ""
Write-Host "  Este script eliminara TODOS los rastros del sistema:" -ForegroundColor White
Write-Host ""
Write-Host "   [x] Detener procesos (PocketBase, Node, watchdog, Chrome kiosk)" -ForegroundColor Gray
Write-Host "   [x] Eliminar carpetas del sistema (ambas rutas posibles)" -ForegroundColor Gray
Write-Host "   [x] Eliminar tareas programadas" -ForegroundColor Gray
Write-Host "   [x] Limpiar Registro de Windows (Run + politicas Chrome)" -ForegroundColor Gray
Write-Host "   [x] Eliminar logs y archivos temporales" -ForegroundColor Gray
Write-Host "   [x] Eliminar perfiles Chrome del kiosk (Chrome_LlavesFCEA_*)" -ForegroundColor Gray
Write-Host "   [x] Eliminar accesos directos del menu Inicio y Startup" -ForegroundColor Gray
Write-Host "   [x] Eliminar respaldos en escritorio (RESPALDO_LLAVES_FCEA_*)" -ForegroundColor Gray
Write-Host ""
Write-Host "  ADVERTENCIA: Esta accion es IRREVERSIBLE." -ForegroundColor Red
Write-Host "  Los respaldos en escritorio se conservan SOLO si responde 'NO' a la" -ForegroundColor Yellow
Write-Host "  pregunta correspondiente al final." -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Escriba CONFIRMAR para continuar (cualquier otra cosa cancela)"
if ($confirm -ne "CONFIRMAR") {
    Write-Host ""
    Write-Host "  Operacion cancelada. No se elimino nada." -ForegroundColor Green
    Read-Host "Presione Enter para salir"
    exit
}

Write-Host ""
Write-Host "  Iniciando desinstalacion completa..." -ForegroundColor Yellow
Write-Host ""

# ----------------------------------------------------------------------------
# Constantes / rutas a buscar
# ----------------------------------------------------------------------------
$RUTAS_SISTEMA = @(
    "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea",
    "C:\sistema-llaves-fcea"
)
$PATRONES_BACKUP = @(
    "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea_backup_*",
    "C:\sistema-llaves-fcea_backup_*"
)

# ============================================================================
# PASO 1: Detener procesos
# ============================================================================
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  [1/8] Deteniendo procesos en ejecucion..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan

$pbProcs = Get-Process -Name "pocketbase" -ErrorAction SilentlyContinue
if ($pbProcs) {
    $pbProcs | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] PocketBase detenido" -ForegroundColor Green
} else {
    Write-Host "  [--] PocketBase no estaba en ejecucion" -ForegroundColor Gray
}

# Liberar puertos 8080 (frontend) y 8090 (PocketBase)
foreach ($puerto in @(8080, 8090)) {
    try {
        $conn = Get-NetTCPConnection -LocalPort $puerto -State Listen -ErrorAction SilentlyContinue
        foreach ($c in $conn) {
            Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Proceso en puerto $puerto detenido (PID $($c.OwningProcess))" -ForegroundColor Green
        }
    } catch { }
}

$nodeProcs = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcs) {
    $nodeProcs | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Node.js detenido ($($nodeProcs.Count) proceso(s))" -ForegroundColor Green
} else {
    Write-Host "  [--] Node.js no estaba en ejecucion" -ForegroundColor Gray
}

# Cerrar Chrome kiosk del sistema (los lanzados por el recuperador llevan
# --user-data-dir con prefijo "Chrome_LlavesFCEA_")
$chromeKiosk = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
        ($_.Name -ieq 'chrome.exe') -and
        ($_.CommandLine -match 'Chrome_LlavesFCEA_' -or $_.CommandLine -match '--app=http://localhost:8080')
    }
if ($chromeKiosk) {
    foreach ($cp in $chromeKiosk) {
        Stop-Process -Id $cp.ProcessId -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  [OK] Chrome kiosk del sistema cerrado ($($chromeKiosk.Count) ventana(s))" -ForegroundColor Green
}

# Watchdog en PowerShell - matar por titulo de ventana O por CommandLine
$watchdogProcs = Get-Process -Name "powershell","pwsh" -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowTitle -match 'watchdog|sistema.*llaves|reinstalar' }
foreach ($w in $watchdogProcs) {
    if ($w.Id -ne $PID) {
        Stop-Process -Id $w.Id -Force -ErrorAction SilentlyContinue
    }
}

# NUEVO v2.1: matar cualquier proceso (de cualquier nombre) cuyo CommandLine
# o ExecutablePath apunte a alguna de las rutas del sistema. Esto cubre node.exe
# del watchdog, npm, vite, conhost, cmd, powershell, etc.
$rutasRegex = 'sistema-llaves-fcea|sistema-de-gesti-n-de-llaves'
$procsEnRuta = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
        ($_.ProcessId -ne $PID) -and (
            ($_.CommandLine -match $rutasRegex) -or
            ($_.ExecutablePath -match $rutasRegex)
        )
    }
if ($procsEnRuta) {
    foreach ($p in $procsEnRuta) {
        try {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop
            Write-Host "  [OK] Matado proceso $($p.Name) (PID $($p.ProcessId)) que tenia handles en ruta del sistema" -ForegroundColor Green
        } catch {
            Write-Host "  [!]  No pude matar $($p.Name) (PID $($p.ProcessId)): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# Esperar mas tiempo para que los handles realmente se liberen (los sockets
# y archivos abiertos pueden tardar varios segundos en cerrarse despues de
# Stop-Process).
Write-Host "  Esperando 5s para liberacion completa de handles..." -ForegroundColor Gray
Start-Sleep -Seconds 5
Write-Host ""

# ============================================================================
# PASO 2: Eliminar carpetas del sistema
# ============================================================================
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  [2/8] Eliminando carpetas del sistema..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan

function Stop-ProcesosConHandleEn {
    # Mata cualquier proceso (excepto el propio) que tenga su ExecutablePath,
    # CommandLine o CurrentDirectory apuntando a la ruta dada o por debajo.
    param([string]$Ruta)
    $patron = [regex]::Escape($Ruta)
    $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object {
            ($_.ProcessId -ne $PID) -and (
                ($_.ExecutablePath -match $patron) -or
                ($_.CommandLine -match $patron)
            )
        }
    $matados = 0
    foreach ($p in $procs) {
        try {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop
            $matados++
        } catch {}
    }
    return $matados
}

function Remove-CarpetaForzada {
    param([string]$Ruta)
    if (-not (Test-Path $Ruta)) { return $false }
    Write-Host "  Eliminando: $Ruta ..." -ForegroundColor Yellow

    # Intento 0: limpiar atributos de solo-lectura/oculto/sistema en todo el arbol
    # (esto soluciona problemas tipicos con .git/objects que vienen read-only)
    try {
        & attrib -R -H -S "$Ruta" /S /D 2>&1 | Out-Null
    } catch {}

    # Intento 1: Remove-Item directo
    $err1 = $null
    try {
        Remove-Item -Path $Ruta -Recurse -Force -ErrorAction Stop
    } catch { $err1 = $_ }
    if (-not (Test-Path $Ruta)) {
        Write-Host "    [OK] Eliminado en intento 1 (Remove-Item directo)" -ForegroundColor Green
        return $true
    }

    # Intento 2: matar procesos que esten dentro de la ruta y reintentar
    $m = Stop-ProcesosConHandleEn -Ruta $Ruta
    if ($m -gt 0) {
        Write-Host "    [i]  Maten $m proceso(s) con handles en esta ruta. Esperando 3s..." -ForegroundColor DarkYellow
        Start-Sleep -Seconds 3
        try {
            Remove-Item -Path $Ruta -Recurse -Force -ErrorAction Stop
        } catch {}
        if (-not (Test-Path $Ruta)) {
            Write-Host "    [OK] Eliminado en intento 2 (despues de matar procesos)" -ForegroundColor Green
            return $true
        }
    }

    # Intento 3: renombrar la carpeta a un nombre temporal y luego borrar.
    # Esto suelta los lockers de "esta carpeta esta abierta en explorer" o cwd
    # de algun cmd. Si Move funciona, el handle se invalida en muchos casos.
    $renamed = $null
    try {
        $renamed = "$Ruta.__del_$(Get-Random -Maximum 99999)"
        Move-Item -Path $Ruta -Destination $renamed -Force -ErrorAction Stop
        Write-Host "    [i]  Renombrado a $(Split-Path $renamed -Leaf) para liberar locks" -ForegroundColor DarkYellow
        Start-Sleep -Seconds 2
        Remove-Item -Path $renamed -Recurse -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path $renamed)) {
            Write-Host "    [OK] Eliminado en intento 3 (rename + remove)" -ForegroundColor Green
            return $true
        }
    } catch {}

    # Intento 4: robocopy /MIR contra una carpeta vacia. Robocopy es brutalmente
    # eficaz porque baja un nivel a la API de archivos y soporta nombres largos.
    $target = if ($renamed -and (Test-Path $renamed)) { $renamed } else { $Ruta }
    if (Test-Path $target) {
        $emptyDir = "$env:TEMP\empty_dir_$(Get-Random)"
        New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
        Write-Host "    [i]  Aplicando robocopy /MIR ..." -ForegroundColor DarkYellow
        & robocopy $emptyDir $target /MIR /NFL /NDL /NJH /NJS /NC /NS /NP /R:0 /W:0 | Out-Null
        Remove-Item -Path $emptyDir -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Remove-Item -Path $target -Recurse -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path $target)) {
            Write-Host "    [OK] Eliminado en intento 4 (robocopy /MIR)" -ForegroundColor Green
            return $true
        }
    }

    # Intento 5: marcar para borrar al proximo reinicio usando MoveFileEx (P/Invoke)
    # Si llegamos aca, hay un handle del kernel que no podemos liberar (raro).
    if (Test-Path $target) {
        try {
            if (-not ('Win32Native' -as [type])) {
                Add-Type -Namespace Native -Name Win32 -MemberDefinition @"
[DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
public static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName, int dwFlags);
"@
            }
            [Native.Win32]::MoveFileEx($target, $null, 4) | Out-Null  # 4 = MOVEFILE_DELAY_UNTIL_REBOOT
            Write-Host "    [AVISO] No se pudo borrar AHORA. Marcado para borrar al proximo reinicio." -ForegroundColor Yellow
        } catch {
            Write-Host "    [ERROR] Fallo total al eliminar ${target}: $($_.Exception.Message)" -ForegroundColor Red
        }
        return $false
    }
    return $true
}

$alguno = $false
foreach ($ruta in $RUTAS_SISTEMA) {
    if (Test-Path $ruta) {
        Remove-CarpetaForzada -Ruta $ruta | Out-Null
        $alguno = $true
    } else {
        Write-Host "  [--] No encontrado: $ruta" -ForegroundColor Gray
    }
}

# Backups con patron *_backup_*
foreach ($patron in $PATRONES_BACKUP) {
    $items = Get-Item -Path $patron -ErrorAction SilentlyContinue
    foreach ($it in $items) {
        Remove-CarpetaForzada -Ruta $it.FullName | Out-Null
        $alguno = $true
    }
}
if (-not $alguno) {
    Write-Host "  [--] No habia ninguna instalacion previa." -ForegroundColor Gray
}
Write-Host ""

# ============================================================================
# PASO 3: Tareas programadas
# ============================================================================
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  [3/8] Eliminando tareas programadas..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan

# Estrategia: barrer TODAS las tareas y matar las que coincidan con patrones FCEA/Llaves
$borradas = 0; $noBorradas = 0
try {
    $todas = Get-ScheduledTask -ErrorAction SilentlyContinue
    foreach ($t in $todas) {
        if ($t.TaskName -match 'FCEA|Llaves|llave|SistemaFCEA') {
            try {
                Unregister-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -Confirm:$false -ErrorAction Stop
                Write-Host "  [OK] Tarea eliminada: $($t.TaskPath)$($t.TaskName)" -ForegroundColor Green
                $borradas++
            } catch {
                Write-Host "  [!]  No pude eliminar: $($t.TaskName)  ($_)" -ForegroundColor Yellow
                $noBorradas++
            }
        }
    }
} catch {
    Write-Host "  [!]  Error consultando tareas programadas: $_" -ForegroundColor Yellow
}
if ($borradas -eq 0 -and $noBorradas -eq 0) {
    Write-Host "  [--] No habia tareas programadas relacionadas." -ForegroundColor Gray
}
Write-Host ""

# ============================================================================
# PASO 4: Registro de Windows
# ============================================================================
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  [4/8] Limpiando Registro de Windows..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan

$regRunPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
)
$nombresRun = @(
    "SistemaLlavesFCEA","Sistema Llaves FCEA","InicioSistemaFCEA",
    "Sistema Llaves FCEA Inicio","FCEAInicio","FCEA"
)
foreach ($rp in $regRunPaths) {
    if (-not (Test-Path $rp)) { continue }
    foreach ($n in $nombresRun) {
        try {
            $val = Get-ItemProperty -Path $rp -Name $n -ErrorAction SilentlyContinue
            if ($val) {
                Remove-ItemProperty -Path $rp -Name $n -Force
                Write-Host "  [OK] $rp -> $n" -ForegroundColor Green
            }
        } catch {}
    }
    # Tambien escanear claves cuyo VALOR apunte a alguna de nuestras rutas
    try {
        $key = Get-Item $rp -ErrorAction SilentlyContinue
        foreach ($name in $key.GetValueNames()) {
            $v = (Get-ItemProperty -Path $rp -Name $name -ErrorAction SilentlyContinue).$name
            if ($v -and ($v -match 'sistema-llaves-fcea|sistema-de-gesti-n-de-llaves')) {
                Remove-ItemProperty -Path $rp -Name $name -Force -ErrorAction SilentlyContinue
                Write-Host "  [OK] $rp -> $name (apuntaba al sistema)" -ForegroundColor Green
            }
        }
    } catch {}
}

# Politicas de Chrome configuradas por el instalador
$chromePolicyPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
if (Test-Path $chromePolicyPath) {
    foreach ($p in @("TouchVirtualKeyboardPolicy")) {
        try {
            $val = Get-ItemProperty -Path $chromePolicyPath -Name $p -ErrorAction SilentlyContinue
            if ($val) {
                Remove-ItemProperty -Path $chromePolicyPath -Name $p -Force
                Write-Host "  [OK] Politica Chrome eliminada: $p" -ForegroundColor Green
            }
        } catch {}
    }
}

# TabletTip
$tabletTipPath = "HKCU:\Software\Microsoft\TabletTip\1.7"
if (Test-Path $tabletTipPath) {
    foreach ($k in @("EnableTextPrediction","EnableAutocorrection","EnableDoubleTapSpace","EnablePredictionSpaceInsertion","EnableDesktopModeAutoInvoke")) {
        try {
            $val = Get-ItemProperty -Path $tabletTipPath -Name $k -ErrorAction SilentlyContinue
            if ($val) {
                Remove-ItemProperty -Path $tabletTipPath -Name $k -Force
                Write-Host "  [OK] TabletTip eliminado: $k" -ForegroundColor Green
            }
        } catch {}
    }
}
Write-Host ""

# ============================================================================
# PASO 5: Logs y temporales
# ============================================================================
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  [5/8] Eliminando logs y archivos temporales..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan

$archivosTemp = @(
    "$env:TEMP\instalacion_llaves_fcea.log",
    "$env:TEMP\sistema_llaves_*.log",
    "$env:TEMP\pocketbase_*.log",
    "$env:TEMP\watchdog_*.log",
    "$env:TEMP\reinstalacion_fcea*.log",
    "$env:ProgramData\sistema_llaves_fcea\*.log"
)
foreach ($arch in $archivosTemp) {
    $items = Get-Item -Path $arch -ErrorAction SilentlyContinue
    if ($items) {
        foreach ($i in $items) {
            Remove-Item -Path $i.FullName -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] $($i.Name)" -ForegroundColor Green
        }
    }
}
Write-Host ""

# ============================================================================
# PASO 6: Perfiles Chrome del kiosk + cache
# ============================================================================
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  [6/8] Limpiando perfiles Chrome del kiosk..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan

# Los perfiles del kiosk son carpetas %LOCALAPPDATA%\Chrome_LlavesFCEA_*
$kioskProfiles = Get-ChildItem -Path "$env:LOCALAPPDATA" -Directory `
                  -Filter "Chrome_LlavesFCEA_*" -ErrorAction SilentlyContinue
foreach ($p in $kioskProfiles) {
    Remove-CarpetaForzada -Ruta $p.FullName | Out-Null
}
if (-not $kioskProfiles) {
    Write-Host "  [--] No habia perfiles kiosk del sistema." -ForegroundColor Gray
}

# Cache de Chrome standard solo si Chrome no esta corriendo
$chromeProcs = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
if ($chromeProcs) {
    Write-Host "  [!]  Chrome esta abierto. Cierre Chrome y limpie cache manualmente si lo desea." -ForegroundColor Yellow
} else {
    foreach ($cachePath in @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache"
    )) {
        if (Test-Path $cachePath) {
            Remove-Item -Path $cachePath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Cache eliminado: $(Split-Path $cachePath -Leaf)" -ForegroundColor Green
        }
    }
}
Write-Host ""

# ============================================================================
# PASO 7: Accesos directos en Inicio y Startup
# ============================================================================
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  [7/8] Eliminando accesos directos del menu Inicio / Startup..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan

$paths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
)
foreach ($p in $paths) {
    if (-not (Test-Path $p)) { continue }
    Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'FCEA|Llaves|llave|Sistema de Llaves' } |
        ForEach-Object {
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Eliminado: $($_.FullName)" -ForegroundColor Green
        }
}
# Pregunta sobre respaldos en Desktop
$desktopBackups = Get-ChildItem -Path "$env:USERPROFILE\Desktop" -Directory `
                    -Filter "RESPALDO_LLAVES_FCEA_*" -ErrorAction SilentlyContinue
if ($desktopBackups) {
    Write-Host ""
    Write-Host "  Encontre $($desktopBackups.Count) respaldo(s) en el escritorio:" -ForegroundColor Yellow
    foreach ($b in $desktopBackups) { Write-Host "    - $($b.Name)" -ForegroundColor Gray }
    $r = Read-Host "  Eliminarlos tambien? (S/N)"
    if ($r -match '^[Ss]$') {
        foreach ($b in $desktopBackups) {
            Remove-Item $b.FullName -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Respaldo eliminado: $($b.Name)" -ForegroundColor Green
        }
    } else {
        Write-Host "  [--] Respaldos conservados." -ForegroundColor Gray
    }
}
Write-Host ""

# ============================================================================
# PASO 8: Verificacion final
# ============================================================================
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  [8/8] Verificacion final..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------" -ForegroundColor Cyan

$rastros = @()
foreach ($r in $RUTAS_SISTEMA) {
    if (Test-Path $r) { $rastros += "  [!] Carpeta AUN EXISTE: $r" }
}
try {
    $tareasResid = Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object { $_.TaskName -match 'FCEA|Llaves|llave' }
    foreach ($t in $tareasResid) { $rastros += "  [!] Tarea AUN EXISTE: $($t.TaskName)" }
} catch {}
foreach ($rp in $regRunPaths) {
    if (-not (Test-Path $rp)) { continue }
    try {
        $key = Get-Item $rp -ErrorAction SilentlyContinue
        foreach ($name in $key.GetValueNames()) {
            $v = (Get-ItemProperty -Path $rp -Name $name -ErrorAction SilentlyContinue).$name
            if ($v -and ($v -match 'sistema-llaves-fcea|sistema-de-gesti-n-de-llaves')) {
                $rastros += "  [!] Registro AUN EXISTE: $rp -> $name"
            }
        }
    } catch {}
}

Write-Host ""
if ($rastros.Count -eq 0) {
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "  [OK] DESINSTALACION COMPLETADA - NO QUEDAN RASTROS               " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Resumen de lo eliminado:" -ForegroundColor Yellow
    Write-Host "   - Carpetas del sistema (ambas rutas posibles)" -ForegroundColor White
    Write-Host "   - Tareas programadas FCEA/Llaves" -ForegroundColor White
    Write-Host "   - Entradas de inicio automatico (HKCU + HKLM)" -ForegroundColor White
    Write-Host "   - Logs en %TEMP% y ProgramData" -ForegroundColor White
    Write-Host "   - Perfiles Chrome del kiosk (Chrome_LlavesFCEA_*)" -ForegroundColor White
    Write-Host "   - Accesos directos del menu Inicio y Startup" -ForegroundColor White
    Write-Host ""
    Write-Host "  Node.js NO fue desinstalado (puede usarse para otros fines)." -ForegroundColor Yellow
} else {
    Write-Host "====================================================================" -ForegroundColor Yellow
    Write-Host "  [AVISO] DESINSTALACION PARCIAL - Quedan algunos rastros:          " -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Yellow
    foreach ($r in $rastros) { Write-Host $r -ForegroundColor Red }
    Write-Host ""
    Write-Host "  Reinicie el equipo y vuelva a ejecutar este script." -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Presione Enter para cerrar"
