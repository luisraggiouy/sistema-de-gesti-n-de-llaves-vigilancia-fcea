# =============================================================
# APLICAR_FIX.ps1
# FIX: Agregar el campo 'notas' a la coleccion 'solicitudes'
#      del PocketBase del Monitor de Vigilancia.
# Fecha: 2026-08-07
#
# PROBLEMA QUE RESUELVE:
#   La coleccion 'solicitudes' NO tenia el campo 'notas'. Por eso las
#   notas que el vigilante escribia en la tarjeta de "llave en uso"
#   nunca se guardaban (PocketBase ignora campos que no existen en el
#   schema) y el Buscador Historico no tenia notas para mostrar.
#
# QUE HACE (EN CALIENTE, SIN REINICIAR POCKETBASE):
#   1) Se autentica como admin en el PocketBase local.
#   2) Lee el schema actual de 'solicitudes'.
#   3) Si YA tiene 'notas', no hace nada (idempotente).
#   4) Si NO lo tiene, agrega el campo text 'notas' via PATCH.
#   5) Verifica que quedo agregado.
#
# NO borra datos. NO reinicia el servidor. NO corta el servicio.
# Las notas VIEJAS no existen (nunca se pudieron guardar): solo
# apareceran las notas que se carguen de ahora en adelante.
#
# ESTE FIX VA EN: Monitor de Vigilancia (es el servidor PocketBase).
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'FIX Campo Notas (solicitudes) - Sistema FCEA'

$BASE  = 'http://127.0.0.1:8090'
$EMAIL = 'vigilancia@llaves.local'
$PASS  = 'vigilanciamvp2026'


# Log al pendrive. Usamos la RAIZ de la unidad (D:\) sin importar cuantas
# carpetas de profundidad tenga este script, para que el .log quede siempre
# en <unidad>:\_RESULTADOS y sea facil de encontrar.
$SCRIPTDIR  = Split-Path -Parent $MyInvocation.MyCommand.Path
$PENDRIVE   = [System.IO.Path]::GetPathRoot($SCRIPTDIR)   # ej: "D:\"
$RESULTADOS = Join-Path $PENDRIVE '_RESULTADOS'

if (-not (Test-Path $RESULTADOS)) { New-Item -ItemType Directory -Path $RESULTADOS | Out-Null }
$STAMP = Get-Date -Format 'yyyy-MM-dd_HHmm'
$LOG   = Join-Path $RESULTADOS ("LOG_FIX_CAMPO_NOTAS_" + $env:COMPUTERNAME + "_" + $STAMP + ".log")

function W($m) { Write-Host $m; Add-Content -Path $LOG -Value $m }
function Line { W ('=' * 62) }

Line
W "  FIX: agregar campo 'notas' a coleccion 'solicitudes'"
W ("  PC: {0}   Fecha: {1}" -f $env:COMPUTERNAME, $STAMP)
W ("  PocketBase: {0}" -f $BASE)
Line

# ---- 1) Autenticacion admin ----
# Probamos ambos endpoints por compatibilidad de version. Si las credenciales
# por defecto no sirven (contrasena cambiada post-instalacion), pedimos las
# credenciales por teclado y reintentamos.
$endpoints = @(
    "$BASE/api/admins/auth-with-password",                      # PocketBase <= 0.22
    "$BASE/api/collections/_superusers/auth-with-password"      # PocketBase >= 0.23
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
W "[1] Autenticando admin con credenciales por defecto..."
$token = Try-Auth $EMAIL $PASS

if (-not $token) {
    W ""
    W "    Las credenciales por defecto no sirvieron (posiblemente se cambio la"
    W "    contrasena del admin de PocketBase despues de instalar)."
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
    W "[ERROR] No se pudo autenticar como admin (ni por defecto ni manual)."
    W "        No se toco nada. Avisar a Cline: probablemente haya que aplicar"
    W "        el campo por migracion (reiniciando PocketBase) en vez de por API."
    W ("  LOG: {0}" -f $LOG)
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 1
}
$headers = @{ Authorization = $token }


# ---- 2) Leer la coleccion 'solicitudes' ----
W ""
W "[2] Leyendo schema de 'solicitudes'..."
$col = Invoke-RestMethod -Uri "$BASE/api/collections/solicitudes" -Method Get -Headers $headers -TimeoutSec 10

# PocketBase <=0.22 usa 'schema'; >=0.23 usa 'fields'. Detectamos cual.
$campoLista = $null
$propSchema = $col.PSObject.Properties.Name -contains 'schema'
$propFields = $col.PSObject.Properties.Name -contains 'fields'
if ($propSchema -and $col.schema) { $campoLista = 'schema' }
elseif ($propFields -and $col.fields) { $campoLista = 'fields' }
else { $campoLista = 'schema' }
W ("    Formato de schema detectado: '{0}'" -f $campoLista)

$lista = @($col.$campoLista)
$yaExiste = $false
foreach ($f in $lista) { if ($f.name -eq 'notas') { $yaExiste = $true } }

if ($yaExiste) {
    W ""
    W "[3] El campo 'notas' YA existe. No hay nada que hacer (idempotente)."
    Line
    W "  RESULTADO: OK (ya estaba)."
    Line
    Write-Host ""; Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine(); exit 0
}

# ---- 3) Construir el nuevo campo 'notas' (text) ----
W ""
W "[3] El campo 'notas' NO existe. Agregandolo..."
$rndId = -join ((1..11) | ForEach-Object { '0123456789abcdefghijklmnopqrstuvwxyz'[(Get-Random -Max 36)] })

if ($campoLista -eq 'schema') {
    # Formato PocketBase <= 0.22
    $nuevo = [ordered]@{
        system      = $false
        id          = $rndId
        name        = 'notas'
        type        = 'text'
        required    = $false
        presentable = $false
        unique      = $false
        options     = [ordered]@{ min = $null; max = $null; pattern = '' }
    }
} else {
    # Formato PocketBase >= 0.23
    $nuevo = [ordered]@{
        hidden      = $false
        id          = "text$rndId"
        name        = 'notas'
        presentable = $false
        required    = $false
        system      = $false
        type        = 'text'
        max         = 0
        min         = 0
        pattern     = ''
    }
}

$listaNueva = @()
$listaNueva += $lista
$listaNueva += $nuevo

$patch = @{ $campoLista = $listaNueva } | ConvertTo-Json -Depth 12
W "    Enviando PATCH a la coleccion..."
$res = Invoke-RestMethod -Uri "$BASE/api/collections/solicitudes" -Method Patch -Headers $headers -Body $patch -ContentType 'application/json' -TimeoutSec 15

# ---- 4) Verificar ----
W ""
W "[4] Verificando..."
$col2 = Invoke-RestMethod -Uri "$BASE/api/collections/solicitudes" -Method Get -Headers $headers -TimeoutSec 10
$lista2 = @($col2.$campoLista)
$ok = $false
foreach ($f in $lista2) { if ($f.name -eq 'notas') { $ok = $true } }

Line
if ($ok) {
    W "  EXITO. El campo 'notas' quedo agregado a 'solicitudes'."
    W "  Ahora las notas que escriban los vigilantes SE GUARDARAN."
    W "  (Las notas viejas no existen: apareceran solo las nuevas)."
} else {
    W "  [ERROR] El PATCH no agrego el campo. Revisar manualmente en el panel /_/."
}
Line
W ("  LOG: {0}" -f $LOG)
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
