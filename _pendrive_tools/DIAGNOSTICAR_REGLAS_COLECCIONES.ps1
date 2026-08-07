# =============================================================
# DIAGNOSTICAR_REGLAS_COLECCIONES.ps1  (SOLO LECTURA)
# Fecha: 2026-08-07
#
# OBJETIVO:
#   Averiguar por que:
#     - El historico no agrega devoluciones nuevas (updates a 'solicitudes'
#       parecen rechazados).
#     - Las terminales no ven usuarios ni llaves.
#
#   Hipotesis: las REGLAS DE ACCESO (API rules) de las colecciones cambiaron
#   y ahora bloquean lecturas/escrituras anonimas (que es como entra la app).
#
# QUE HACE (NO MODIFICA NADA):
#   1) Se autentica como admin (para poder leer las reglas).
#   2) Lee listRule/viewRule/createRule/updateRule/deleteRule de las
#      colecciones clave: usuarios, lugares, solicitudes (y las que haya).
#   3) Simula a la app: hace requests ANONIMAS (sin token) de LECTURA a esas
#      colecciones y reporta si responden 200 o si las rechaza (403/404).
#   4) Escribe todo a un .log en el pendrive (<unidad>:\_RESULTADOS).
#
#   * NO hace ningun create/update/delete. Es seguro.
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'DIAGNOSTICO Reglas de Colecciones - FCEA'

$BASE  = 'http://127.0.0.1:8090'
$EMAIL = 'vigilancia@llaves.local'
$PASS  = 'vigilanciamvp2026'

$SCRIPTDIR  = Split-Path -Parent $MyInvocation.MyCommand.Path
$PENDRIVE   = [System.IO.Path]::GetPathRoot($SCRIPTDIR)
$RESULTADOS = Join-Path $PENDRIVE '_RESULTADOS'
if (-not (Test-Path $RESULTADOS)) { New-Item -ItemType Directory -Path $RESULTADOS | Out-Null }
$STAMP = Get-Date -Format 'yyyy-MM-dd_HHmm'
$LOG   = Join-Path $RESULTADOS ("LOG_REGLAS_COLECCIONES_" + $env:COMPUTERNAME + "_" + $STAMP + ".log")

function W($m) { Write-Host $m; Add-Content -Path $LOG -Value $m }
function Line { W ('=' * 62) }

Line
W "  DIAGNOSTICO: reglas de acceso de colecciones (SOLO LECTURA)"
W ("  PC: {0}   Fecha: {1}" -f $env:COMPUTERNAME, $STAMP)
W ("  PocketBase: {0}" -f $BASE)
Line

# ---- 1) Auth admin ----
$endpoints = @(
    "$BASE/api/admins/auth-with-password",
    "$BASE/api/collections/_superusers/auth-with-password"
)
function Try-Auth([string]$email, [string]$pass) {
    $body = @{ identity = $email; password = $pass } | ConvertTo-Json
    foreach ($ep in $endpoints) {
        try {
            $auth = Invoke-RestMethod -Uri $ep -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 10
            if ($auth.token) { return $auth.token }
        } catch { }
    }
    return $null
}
W ""
W "[1] Autenticando admin..."
$token = Try-Auth $EMAIL $PASS
if (-not $token) {
    W "    Credenciales por defecto no sirvieron. Pedimos manual."
    for ($i=1; $i -le 3 -and -not $token; $i++) {
        $emailIn = Read-Host "  Email admin (ENTER = $EMAIL)"
        if ([string]::IsNullOrWhiteSpace($emailIn)) { $emailIn = $EMAIL }
        $passSec = Read-Host "  Contrasena admin" -AsSecureString
        $passIn  = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                     [Runtime.InteropServices.Marshal]::SecureStringToBSTR($passSec))
        $token = Try-Auth $emailIn $passIn
    }
}
if (-not $token) {
    W "[ERROR] No se pudo autenticar. Sin token no puedo leer las reglas."
    W ("  LOG: {0}" -f $LOG)
    Write-Host ""; Write-Host "ENTER para cerrar..."; [void][System.Console]::ReadLine(); exit 1
}
W "    [OK] Autenticado."
$headers = @{ Authorization = $token }

# ---- 2) Leer reglas de cada coleccion ----
W ""
W "[2] Reglas de acceso por coleccion:"
W "    (null = SOLO ADMIN / bloqueado para la app anonima;  ""'' vacio"" = PUBLICO)"
W ""
try {
    $cols = Invoke-RestMethod -Uri "$BASE/api/collections?perPage=200" -Method Get -Headers $headers -TimeoutSec 15
    $items = $cols.items
    foreach ($c in $items) {
        if ($c.system) { continue }
        W ("  Coleccion: {0}   (type={1})" -f $c.name, $c.type)
        function Fmt($v) { if ($null -eq $v) { return 'null (SOLO ADMIN)' } elseif ($v -eq '') { return '"" (publico)' } else { return $v } }
        W ("      listRule   : {0}" -f (Fmt $c.listRule))
        W ("      viewRule   : {0}" -f (Fmt $c.viewRule))
        W ("      createRule : {0}" -f (Fmt $c.createRule))
        W ("      updateRule : {0}" -f (Fmt $c.updateRule))
        W ("      deleteRule : {0}" -f (Fmt $c.deleteRule))
        W ""
    }
} catch {
    W ("  [ERROR] leyendo /api/collections: {0}" -f $_.Exception.Message)
}

# ---- 3) Simular a la app: requests ANONIMAS de lectura ----
W ""
W "[3] Prueba ANONIMA (como entra la app/terminal, SIN token):"
$objetivo = @('usuarios','lugares','solicitudes')
foreach ($col in $objetivo) {
    try {
        $r = Invoke-WebRequest -Uri "$BASE/api/collections/$col/records?perPage=1" -Method Get -UseBasicParsing -TimeoutSec 10
        $ti = ($r.Content | ConvertFrom-Json).totalItems
        W ("    {0,-12} -> HTTP {1}  (lectura anonima OK, totalItems={2})" -f $col, $r.StatusCode, $ti)
    } catch {
        $code = 'sin respuesta'
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        W ("    {0,-12} -> HTTP {1}  (lectura anonima RECHAZADA)  {2}" -f $col, $code, $_.Exception.Message)
    }
}

Line
W "  INTERPRETACION RAPIDA:"
W "   - Si 'usuarios' o 'lugares' dan listRule=null o la lectura anonima"
W "     es RECHAZADA -> por eso las terminales no ven usuarios/llaves."
W "   - Si 'solicitudes' tiene updateRule=null o createRule=null -> por eso"
W "     las devoluciones/entregas no se guardan (historico congelado)."
Line
W ("  LOG: {0}" -f $LOG)
Write-Host ""
Write-Host "Traé este .log a la laptop de desarrollo. ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
