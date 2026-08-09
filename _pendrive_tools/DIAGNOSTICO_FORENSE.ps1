# =============================================================
# DIAGNOSTICO_FORENSE.ps1   (SOLO LECTURA - no modifica el sistema)
# Objetivo: reunir evidencia para determinar si un problema es
#   (A) del software FCEA (sistema de llaves),
#   (B) de Windows / el equipo, o
#   (C) de alguien que metio/ejecuto algo (pendrive, virus, sabotaje).
#
# Todo se vuelca a un .log en el pendrive (_RESULTADOS). Luis lo
# trae y Cline lo lee desde la laptop para dar el veredicto.
#
# Ademas mantiene una LINEA BASE de hashes de la app (dist):
#   - Primera corrida en una PC sana -> crea la baseline.
#   - Corridas siguientes -> compara y muestra que archivos de la
#     app cambiaron (evidencia anti-sabotaje: prueba si el software
#     que entregamos sigue intacto o si lo tocaron).
#
# Reutilizable en Terminal A, Terminal B y Monitor Vigilancia.
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'DIAGNOSTICO FORENSE - Sistema FCEA'

$carpetaLog = Join-Path $PSScriptRoot '_RESULTADOS'
if (-not (Test-Path $carpetaLog)) { New-Item -ItemType Directory -Path $carpetaLog -Force | Out-Null }
$baseDir = Join-Path $PSScriptRoot '_BASELINE'
if (-not (Test-Path $baseDir)) { New-Item -ItemType Directory -Path $baseDir -Force | Out-Null }

$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$logPath = Join-Path $carpetaLog ("LOG_FORENSE_{0}_{1}.log" -f $env:COMPUTERNAME, $stamp)
try { Start-Transcript -Path $logPath -Force | Out-Null } catch {}

function Line($c='='){ Write-Host ($c * 64) }
function Header($t) { Write-Host ""; Line '#'; Write-Host "  $t"; Line '#' }
function Sub($t) { Write-Host ""; Write-Host "===== $t =====" }
function Try-Do($desc, $block) {
    try { & $block }
    catch { Write-Host ("  [no disponible] {0}: {1}" -f $desc, $_.Exception.Message) }
}

$APP = 'C:\sistema-llaves-fcea'
$DIST = Join-Path $APP 'dist'

Header "DIAGNOSTICO FORENSE - $env:COMPUTERNAME - $(Get-Date)"
Write-Host "  Usuario: $env:USERNAME"
Write-Host "  Log: $logPath"

# ---------------------------------------------------------------
Sub "1) WINDOWS / EQUIPO"
Try-Do "OS" {
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host ("  Windows        : {0} (build {1})" -f $os.Caption, $os.BuildNumber)
    Write-Host ("  Instalado el   : {0}" -f $os.InstallDate)
    Write-Host ("  Ultimo arranque: {0}" -f $os.LastBootUpTime)
    $up = (Get-Date) - $os.LastBootUpTime
    Write-Host ("  Encendida hace : {0} dias {1} hs" -f $up.Days, $up.Hours)
}
Try-Do "Disco C:" {
    $d = Get-PSDrive C
    Write-Host ("  Disco C: libre {0} GB de {1} GB" -f [math]::Round($d.Free/1GB,1), [math]::Round(($d.Used+$d.Free)/1GB,1))
}

# ---------------------------------------------------------------
Sub "2) ESTADO DE LA APP FCEA (sistema de llaves)"
Write-Host ("  Carpeta app existe ({0}): {1}" -f $APP, (Test-Path $APP))
Write-Host ("  Carpeta dist existe ({0}): {1}" -f $DIST, (Test-Path $DIST))
$cfg = Join-Path $DIST 'config.json'
if (Test-Path $cfg) {
    Try-Do "config.json" {
        $j = Get-Content $cfg -Raw | ConvertFrom-Json
        Write-Host ("  config.json -> rol={0}  hardware={1}  pocketbase_url={2}" -f $j.rol, $j.hardware, $j.pocketbase_url)
    }
} else { Write-Host "  [ATENCION] No existe dist\config.json" }

Try-Do "PocketBase proceso" {
    $pb = Get-Process -Name pocketbase -ErrorAction SilentlyContinue
    if ($pb) { Write-Host ("  PocketBase: CORRIENDO (PID {0})" -f ($pb.Id -join ',')) }
    else { Write-Host "  PocketBase: NO esta corriendo" }
}
Try-Do "Puerto 8090" {
    $t = Test-NetConnection -ComputerName 127.0.0.1 -Port 8090 -WarningAction SilentlyContinue
    Write-Host ("  Puerto 8090 (PocketBase) escucha: {0}" -f $t.TcpTestSucceeded)
}
Try-Do "Health PocketBase" {
    $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8090/api/health' -TimeoutSec 4 -UseBasicParsing
    Write-Host ("  Health HTTP: {0}" -f $r.StatusCode)
}
Try-Do "Navegador kiosko" {
    $br = Get-Process -Name msedge,chrome -ErrorAction SilentlyContinue
    if ($br) { Write-Host ("  Navegador kiosko: CORRIENDO ({0} procesos)" -f $br.Count) }
    else { Write-Host "  Navegador kiosko: NO esta corriendo" }
}
Try-Do "Ultimos archivos modificados en la app" {
    Write-Host "  Ultimos 15 archivos modificados dentro de la carpeta app:"
    Get-ChildItem $APP -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 15 |
        ForEach-Object { Write-Host ("    {0}  {1}" -f $_.LastWriteTime, $_.FullName) }
}

# ---------------------------------------------------------------
Sub "3) INTEGRIDAD DE LA APP (baseline de hashes)"
$baseFile = Join-Path $baseDir ("baseline_dist_{0}.csv" -f $env:COMPUTERNAME)
if (Test-Path $DIST) {
    Write-Host "  Calculando hashes actuales de dist..."
    $actual = Get-ChildItem $DIST -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        [pscustomobject]@{
            Rel  = $_.FullName.Substring($DIST.Length).TrimStart('\')
            Hash = (Get-FileHash $_.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        }
    }
    Write-Host ("  Archivos en dist: {0}" -f $actual.Count)

    if (-not (Test-Path $baseFile)) {
        $actual | Export-Csv -Path $baseFile -NoTypeInformation -Encoding UTF8
        Write-Host "  [BASELINE CREADA] Se guardo la linea base de esta PC (asumida SANA)."
        Write-Host ("  Archivo baseline: {0}" -f $baseFile)
        Write-Host "  Corre esta herramienta de nuevo si sospechas que tocaron el software."
    } else {
        Write-Host "  Comparando contra la baseline guardada..."
        $base = Import-Csv $baseFile
        $baseMap = @{}; foreach ($b in $base) { $baseMap[$b.Rel] = $b.Hash }
        $actMap  = @{}; foreach ($a in $actual) { $actMap[$a.Rel] = $a.Hash }

        $cambiados = @(); $nuevos = @(); $borrados = @()
        foreach ($a in $actual) {
            if ($baseMap.ContainsKey($a.Rel)) {
                if ($baseMap[$a.Rel] -ne $a.Hash) { $cambiados += $a.Rel }
            } else { $nuevos += $a.Rel }
        }
        foreach ($b in $base) { if (-not $actMap.ContainsKey($b.Rel)) { $borrados += $b.Rel } }

        Write-Host ("  CAMBIADOS: {0}   NUEVOS: {1}   BORRADOS: {2}" -f $cambiados.Count, $nuevos.Count, $borrados.Count)
        if ($cambiados.Count -eq 0 -and $nuevos.Count -eq 0 -and $borrados.Count -eq 0) {
            Write-Host "  [OK] El software FCEA esta INTACTO (identico a la baseline)."
            Write-Host "       => Si algo falla, NO es porque tocaron nuestros archivos."
        } else {
            Write-Host "  [ATENCION] La app difiere de la baseline. Detalle:"
            $cambiados | Select-Object -First 40 | ForEach-Object { Write-Host "    CAMBIADO: $_" }
            $nuevos    | Select-Object -First 40 | ForEach-Object { Write-Host "    NUEVO   : $_" }
            $borrados  | Select-Object -First 40 | ForEach-Object { Write-Host "    BORRADO : $_" }
        }
    }
} else { Write-Host "  No hay carpeta dist para verificar integridad." }

# ---------------------------------------------------------------
Sub "4) WINDOWS DEFENDER (amenazas detectadas = virus)"
Try-Do "Estado Defender" {
    $s = Get-MpComputerStatus
    Write-Host ("  Antivirus activo        : {0}" -f $s.AntivirusEnabled)
    Write-Host ("  Proteccion tiempo real  : {0}" -f $s.RealTimeProtectionEnabled)
    Write-Host ("  Ultima actualiz. firmas : {0}" -f $s.AntivirusSignatureLastUpdated)
}
Try-Do "Amenazas detectadas" {
    $th = Get-MpThreatDetection -ErrorAction SilentlyContinue | Sort-Object InitialDetectionTime -Descending
    if ($th) {
        Write-Host "  [!!!] Defender DETECTO amenazas (esto es evidencia de virus):"
        $th | Select-Object -First 20 | ForEach-Object {
            Write-Host ("    {0}  ThreatID={1}  Recurso={2}" -f $_.InitialDetectionTime, $_.ThreatID, ($_.Resources -join ';'))
        }
    } else { Write-Host "  Sin amenazas registradas por Defender. (bueno)" }
}

# ---------------------------------------------------------------
Sub "5) PROGRAMAS INSTALADOS RECIENTEMENTE (ultimos 30 dias)"
Try-Do "Programas recientes" {
    $keys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $lim = (Get-Date).AddDays(-30).ToString('yyyyMMdd')
    Get-ItemProperty $keys -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and $_.InstallDate -and $_.InstallDate -ge $lim } |
        Select-Object DisplayName, InstallDate |
        ForEach-Object { Write-Host ("    {0}  {1}" -f $_.InstallDate, $_.DisplayName) }
}

# ---------------------------------------------------------------
Sub "6) ARRANQUE AUTOMATICO / PERSISTENCIA (donde se esconde el malware)"
Try-Do "Claves Run" {
    foreach ($k in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')) {
        Write-Host "  $k"
        $p = Get-ItemProperty $k -ErrorAction SilentlyContinue
        if ($p) { $p.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object { Write-Host ("    {0} = {1}" -f $_.Name, $_.Value) } }
    }
}
Try-Do "Tareas programadas recientes/sospechosas" {
    Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object { $_.State -ne 'Disabled' -and $_.TaskPath -notlike '\Microsoft\*' } |
        Select-Object TaskName, TaskPath |
        ForEach-Object { Write-Host ("    {0}{1}" -f $_.TaskPath, $_.TaskName) }
}
Try-Do "Carpeta de Inicio (Startup)" {
    $su = [Environment]::GetFolderPath('Startup')
    Get-ChildItem $su -ErrorAction SilentlyContinue | ForEach-Object { Write-Host ("    {0}" -f $_.FullName) }
}

# ---------------------------------------------------------------
Sub "7) CUENTAS Y ADMINISTRADORES"
Try-Do "Usuarios locales" {
    Get-LocalUser -ErrorAction SilentlyContinue | Select-Object Name, Enabled, LastLogon |
        ForEach-Object { Write-Host ("    {0}  habilitado={1}  ultimo_login={2}" -f $_.Name, $_.Enabled, $_.LastLogon) }
}
Try-Do "Grupo Administradores" {
    Get-LocalGroupMember -Group 'Administradores' -ErrorAction SilentlyContinue |
        ForEach-Object { Write-Host ("    admin: {0}" -f $_.Name) }
    Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue |
        ForEach-Object { Write-Host ("    admin: {0}" -f $_.Name) }
}

# ---------------------------------------------------------------
Sub "8) HISTORIAL DE PENDRIVES USB CONECTADOS"
Try-Do "USBSTOR" {
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR' -ErrorAction SilentlyContinue |
        ForEach-Object { Write-Host ("    {0}" -f ($_.PSChildName)) }
}

# ---------------------------------------------------------------
Sub "9) EVENTOS DE WINDOWS (ultimas 72 hs)"
$desde = (Get-Date).AddHours(-72)
Try-Do "System (errores/criticos)" {
    Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=$desde} -ErrorAction SilentlyContinue |
        Select-Object -First 25 TimeCreated, Id, ProviderName, @{n='Msg';e={$_.Message -replace '\s+',' '}} |
        ForEach-Object { Write-Host ("    {0} Id={1} {2}: {3}" -f $_.TimeCreated, $_.Id, $_.ProviderName, ($_.Msg.Substring(0,[Math]::Min(120,$_.Msg.Length)))) }
}
Try-Do "Application (errores)" {
    Get-WinEvent -FilterHashtable @{LogName='Application'; Level=1,2; StartTime=$desde} -ErrorAction SilentlyContinue |
        Select-Object -First 25 TimeCreated, Id, ProviderName, @{n='Msg';e={$_.Message -replace '\s+',' '}} |
        ForEach-Object { Write-Host ("    {0} Id={1} {2}: {3}" -f $_.TimeCreated, $_.Id, $_.ProviderName, ($_.Msg.Substring(0,[Math]::Min(120,$_.Msg.Length)))) }
}

# ---------------------------------------------------------------
Sub "10) RED"
Try-Do "IPs" {
    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -notlike '169.254.*' } |
        ForEach-Object { Write-Host ("    {0}  ({1})" -f $_.IPAddress, $_.InterfaceAlias) }
}

Write-Host ""
Line '#'
Write-Host "  DIAGNOSTICO TERMINADO."
Write-Host "  Traé el pendrive a la laptop y pasale a Cline este archivo:"
Write-Host "    $logPath"
Line '#'
try { Stop-Transcript | Out-Null } catch {}
Write-Host ""
Write-Host "Presiona ENTER para cerrar..."
[void][System.Console]::ReadLine()
