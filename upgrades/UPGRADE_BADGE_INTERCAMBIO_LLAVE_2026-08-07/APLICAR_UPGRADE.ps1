# =============================================================
# APLICAR_UPGRADE.ps1
# UPGRADE: "Cartel 'Intercambio de llave' en la tarjeta de Llaves en Uso"
#          Monitor de Vigilancia
# Fecha: 2026-08-07
#
# QUE RESUELVE:
#   Cuando se hace un intercambio de llave (una llave que estaba en uso
#   pasa de un usuario a otro sin devolverla al mostrador), la tarjeta de
#   "Llaves en Uso" mostraba SOLO el texto plano
#   "Entregada por X ... A cargo de Y ..." sin ningun distintivo. No quedaba
#   claro visualmente que hubo un intercambio.
#
#   CAUSA RAIZ: la coleccion 'solicitudes' del PocketBase del Monitor NO
#   tenia los campos 'es_intercambio' ni 'usuario_anterior_*'. Por eso el
#   flag del intercambio NUNCA se guardaba (PocketBase ignora campos que no
#   existen en el schema) y, al recargar, la tarjeta lo mostraba como una
#   entrega comun.
#
# QUE HACE ESTE UPGRADE (2 PARTES):
#   PARTE A - PocketBase (en caliente, sin reiniciar):
#     Agrega a 'solicitudes' los campos que faltaban (idempotente):
#       - es_intercambio               (bool)
#       - usuario_anterior_nombre      (text)
#       - usuario_anterior_celular     (text)
#       - usuario_anterior_tipo        (text)
#       - usuario_anterior_departamento(text)
#       - usuario_anterior_empresa     (text)
#   PARTE B - Frontend:
#     Reemplaza el dist por el nuevo (que muestra el cartel ambar
#     "Intercambio de llave" al lado de "En uso" + el detalle Entrego/Recibio).
#
#   NO borra datos. NO reinicia PocketBase. NO corta el servicio.
#   PRESERVA config.json y system_health.json (config de red de esta PC).
#
# ESTE UPGRADE VA EN: Monitor de Vigilancia (que hace de servidor PocketBase).
#
# ROLLBACK del frontend: usar 2-DESHACER_ROLLBACK.bat (restaura el ultimo
#   backup del dist). Los campos nuevos de PocketBase pueden quedar: son
#   inofensivos y no molestan aunque se vuelva al dist viejo.
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UPGRADE Cartel Intercambio de Llave - Sistema FCEA'

$BASE  = 'http://127.0.0.1:8090'
$EMAIL = 'vigilancia@llaves.local'
$PASS  = 'vigilanciamvp2026'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST_DEST = Join-Path $INSTALL 'dist'
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DIST_SRC  = Join-Path $SCRIPTDIR 'dist'
$STAMP     = Get-Date -Format 'yyyy-MM-dd_HHmm'
$BACKUP    = Join-Path $INSTALL ("dist_backup_" + $STAMP)

# Log al pendrive (raiz de la unidad + \_RESULTADOS)
$PENDRIVE   = [System.IO.Path]::GetPathRoot($SCRIPTDIR)
$RESULTADOS = Join-Path $PENDRIVE '_RESULTADOS'
if (-not (Test-Path $RESULTADOS)) { New-Item -ItemType Directory -Path $RESULTADOS | Out-Null }
$LOG = Join-Path $RESULTADOS ("LOG_UPGRADE_INTERCAMBIO_" + $env:COMPUTERNAME + "_" + $STAMP + ".log")

function W($m)  { Write-Host $m; Add-Content -Path $LOG -Value $m }
function Line   { W ('=' * 62) }

Line
W "  UPGRADE: Cartel 'Intercambio de llave' en Llaves en Uso"
W ("  PC: {0}   Fecha: {1}" -f $env:COMPUTERNAME, $STAMP)
W "  (Aplicar en el MONITOR DE VIGILANCIA)"
Line

# -------------------------------------------------------------
# PARTE A: agregar campos faltantes a la coleccion 'solicitudes'
# -------------------------------------------------------------
$endpoints = @(
    "$BASE/api/admins/auth-with-password",                   # PocketBase <= 0.22
    "$BASE/api/collections/_superusers/auth-with-password"   # PocketBase >= 0.23
)

function Try-Auth([string]$email, [string]$pass) {
    $body = @{ identity = $email; password = $pass } | ConvertTo-Json
    foreach ($ep in $endpoints) {
        try {
            W "    -> probando: $ep"
            $auth = Invoke-RestMethod -Uri $ep -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 10
            if ($auth.token) { W "    [OK] Autenticado."; return $auth.token }
        } catch {
            W ("       (fallo: {0})" -f $_.Exception.Message)
        }
    }
    return $null
}

W ""
W "[PARTE A] Agregar campos faltantes a 'solicitudes' (PocketBase)."
W ""
W "[A1] Autenticando admin con credenciales por defecto..."
$token = Try-Auth $EMAIL $PASS

if (-not $token) {
    W ""
    W "    Las credenciales por defecto no sirvieron (posiblemente se cambio"
    W "    la contrasena del admin de PocketBase despues de instalar)."
    Write-Host ""
    Write-Host "  --------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "  Ingresa las credenciales del ADMIN de PocketBase (panel /_/)." -ForegroundColor Yellow
    Write-Host "  Si no las sabes, cierra esta ventana y avisale a Cline." -ForegroundColor Yellow
    Write-Host "  --------------------------------------------------------------" -ForegroundColor Yellow
    for ($intento = 1; $intento -le 3 -and -not $token; $intento++) {
        Write-Host ""
        Write-Host ("  Intento {0} de 3" -f $intento) -ForegroundColor Cyan
        $emailIn = Read-Host "  Email admin (ENTER = vigilancia@llaves.local)"
        if ([string]::IsNullOrWhiteSpace($emailIn)) { $emailIn = $EMAIL }
        $passSec = Read-Host "  Contrasena admin" -AsSecureString
        $passIn  = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                     [Runtime.InteropServices.Marshal]::SecureStringToBSTR($passSec))
        W ("    (intento manual {0} con email: {1})" -f $intento, $emailIn)
        $token = Try-Auth $emailIn $passIn
    }
}

if (-not $token) {
    W ""
    W "[ERROR] No se pudo autenticar como admin. No se toco NADA."
    W "        Avisar a Cline. LOG: $LOG"
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
$headers = @{ Authorization = $token }

W ""
W "[A2] Leyendo schema de 'solicitudes'..."
$col = Invoke-RestMethod -Uri "$BASE/api/collections/solicitudes" -Method Get -Headers $headers -TimeoutSec 10

# PocketBase <=0.22 usa 'schema'; >=0.23 usa 'fields'.
$propSchema = $col.PSObject.Properties.Name -contains 'schema'
$propFields = $col.PSObject.Properties.Name -contains 'fields'
if ($propSchema -and $col.schema) { $campoLista = 'schema' }
elseif ($propFields -and $col.fields) { $campoLista = 'fields' }
else { $campoLista = 'schema' }
W ("    Formato de schema detectado: '{0}'" -f $campoLista)

$lista = @($col.$campoLista)

function Existe-Campo([string]$nombre) {
    foreach ($f in $lista) { if ($f.name -eq $nombre) { return $true } }
    return $false
}

function Nuevo-Campo([string]$nombre, [string]$tipo) {
    $rndId = -join ((1..11) | ForEach-Object { '0123456789abcdefghijklmnopqrstuvwxyz'[(Get-Random -Max 36)] })
    if ($campoLista -eq 'schema') {
        # PocketBase <= 0.22
        if ($tipo -eq 'bool') {
            return [ordered]@{
                system = $false; id = $rndId; name = $nombre; type = 'bool'
                required = $false; presentable = $false; unique = $false
                options = [ordered]@{}
            }
        } else {
            return [ordered]@{
                system = $false; id = $rndId; name = $nombre; type = 'text'
                required = $false; presentable = $false; unique = $false
                options = [ordered]@{ min = $null; max = $null; pattern = '' }
            }
        }
    } else {
        # PocketBase >= 0.23
        if ($tipo -eq 'bool') {
            return [ordered]@{
                hidden = $false; id = ("bool$rndId"); name = $nombre
                presentable = $false; required = $false; system = $false; type = 'bool'
            }
        } else {
            return [ordered]@{
                hidden = $false; id = ("text$rndId"); name = $nombre
                presentable = $false; required = $false; system = $false; type = 'text'
                max = 0; min = 0; pattern = ''
            }
        }
    }
}

# Campos que este upgrade necesita: nombre -> tipo
$requeridos = [ordered]@{
    'es_intercambio'                = 'bool'
    'usuario_anterior_nombre'       = 'text'
    'usuario_anterior_celular'      = 'text'
    'usuario_anterior_tipo'         = 'text'
    'usuario_anterior_departamento' = 'text'
    'usuario_anterior_empresa'      = 'text'
}

W ""
W "[A3] Verificando cuales faltan..."
$aAgregar = @()
foreach ($nombre in $requeridos.Keys) {
    if (Existe-Campo $nombre) {
        W ("    - {0}: YA existe (ok)" -f $nombre)
    } else {
        W ("    - {0}: FALTA -> se agregara ({1})" -f $nombre, $requeridos[$nombre])
        $aAgregar += (Nuevo-Campo $nombre $requeridos[$nombre])
    }
}

if ($aAgregar.Count -eq 0) {
    W ""
    W "[A4] No falta ningun campo (idempotente). PocketBase ya estaba al dia."
} else {
    W ""
    W ("[A4] Agregando {0} campo(s) via PATCH..." -f $aAgregar.Count)
    $listaNueva = @()
    $listaNueva += $lista
    $listaNueva += $aAgregar
    $patch = @{ $campoLista = $listaNueva } | ConvertTo-Json -Depth 12
    $null = Invoke-RestMethod -Uri "$BASE/api/collections/solicitudes" -Method Patch -Headers $headers -Body $patch -ContentType 'application/json' -TimeoutSec 15

    # Verificar
    $col2   = Invoke-RestMethod -Uri "$BASE/api/collections/solicitudes" -Method Get -Headers $headers -TimeoutSec 10
    $lista2 = @($col2.$campoLista)
    $faltan = @()
    foreach ($nombre in $requeridos.Keys) {
        $ok = $false
        foreach ($f in $lista2) { if ($f.name -eq $nombre) { $ok = $true } }
        if (-not $ok) { $faltan += $nombre }
    }
    if ($faltan.Count -eq 0) {
        W "     [OK] Todos los campos quedaron agregados."
    } else {
        W ("     [ERROR] No quedaron: {0}. Revisar el panel /_/ manualmente." -f ($faltan -join ', '))
        W "     No sigo con el frontend. Avisar a Cline. LOG: $LOG"
        Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
        [void][System.Console]::ReadLine(); exit 1
    }
}

# -------------------------------------------------------------
# PARTE B: reemplazar el frontend (dist)
# -------------------------------------------------------------
W ""
W "[PARTE B] Reemplazar frontend (dist)."

if (-not (Test-Path $INSTALL)) {
    W "  [ERROR] No existe $INSTALL en esta PC."
    W "  Este upgrade va en la PC del Monitor de Vigilancia."
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
if (-not (Test-Path (Join-Path $DIST_SRC 'index.html'))) {
    W "  [ERROR] No se encuentra el dist nuevo junto a este script:"
    W ("          {0}\index.html" -f $DIST_SRC)
    W "  Grabaste la carpeta COMPLETA del upgrade en el pendrive?"
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}

if (Test-Path $DIST_DEST) {
    W "  [B1] Respaldando dist actual ->"
    W ("       {0}" -f $BACKUP)
    robocopy $DIST_DEST $BACKUP /E /NFL /NDL /NJH /NJS /NP | Out-Null
    W "       [OK] Backup creado."
} else {
    W "  [B1] No habia dist previo (instalacion nueva?). Sigo igual."
}

W "  [B2] Copiando frontend nuevo (preservando config.json y system_health.json) ->"
W ("       {0}" -f $DIST_DEST)
robocopy $DIST_SRC $DIST_DEST /MIR /XF config.json system_health.json /NFL /NDL /NJH /NJS /NP | Out-Null
$rc = $LASTEXITCODE
if ($rc -ge 8) {
    W ("       [ERROR] robocopy devolvio codigo {0}. Revisar permisos." -f $rc)
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
W "       [OK] Frontend actualizado."

Line
W "  EXITO. Upgrade aplicado."
W "  1) Cerra el navegador/kiosko del Monitor y volvelo a abrir (Ctrl+F5)."
W "  2) Proba un intercambio de llave: la tarjeta de 'Llaves en Uso' debe"
W "     mostrar el cartel ambar 'Intercambio de llave' al lado de 'En uso'"
W "     y el detalle Entrego / Recibio."
W ("  Backup del dist: {0}" -f $BACKUP)
W ("  LOG: {0}" -f $LOG)
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
