# =============================================================
# DIAGNOSTICAR_UPDATE_SOLICITUD.ps1
# Fecha: 2026-08-07
#
# OBJETIVO:
#   Ver el ERROR EXACTO que devuelve PocketBase cuando la app intenta
#   actualizar una solicitud (lo que pasa al ENTREGAR o DEVOLVER una llave).
#   El historico no agrega devoluciones => el update se esta rechazando.
#
# QUE HACE:
#   1) Lee (anonimo, como la app) la solicitud mas reciente.
#   2) Muestra sus campos actuales.
#   3) Hace un PATCH ANONIMO (igual que la app, SIN token) reenviando los
#      MISMOS valores que ya tiene (estado, hora_entrega, hora_devolucion,
#      recibido_por, entregado_por). Es IDEMPOTENTE: no cambia datos reales.
#   4) Reporta el codigo HTTP y, si falla, el MENSAJE DE ERROR del servidor
#      (ej: que campo rechaza la validacion). Eso es lo que necesito.
#
#   * No crea ni borra registros. El update reenvia los valores actuales.
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'DIAGNOSTICO Update Solicitud - FCEA'

$BASE = 'http://127.0.0.1:8090'

$SCRIPTDIR  = Split-Path -Parent $MyInvocation.MyCommand.Path
$PENDRIVE   = [System.IO.Path]::GetPathRoot($SCRIPTDIR)
$RESULTADOS = Join-Path $PENDRIVE '_RESULTADOS'
if (-not (Test-Path $RESULTADOS)) { New-Item -ItemType Directory -Path $RESULTADOS | Out-Null }
$STAMP = Get-Date -Format 'yyyy-MM-dd_HHmm'
$LOG   = Join-Path $RESULTADOS ("LOG_UPDATE_SOLICITUD_" + $env:COMPUTERNAME + "_" + $STAMP + ".log")

function W($m) { Write-Host $m; Add-Content -Path $LOG -Value $m }
function Line { W ('=' * 62) }

Line
W "  DIAGNOSTICO: update de solicitud (como la app, anonimo)"
W ("  PC: {0}   Fecha: {1}" -f $env:COMPUTERNAME, $STAMP)
Line

# ---- 1) Traer la solicitud mas reciente (anonimo) ----
W ""
W "[1] Leyendo la solicitud mas reciente (anonimo)..."
try {
    $resp = Invoke-WebRequest -Uri "$BASE/api/collections/solicitudes/records?perPage=1&sort=-created" -Method Get -UseBasicParsing -TimeoutSec 10
    $data = $resp.Content | ConvertFrom-Json
} catch {
    W ("    [ERROR] No se pudo leer solicitudes: {0}" -f $_.Exception.Message)
    Write-Host ""; Write-Host "ENTER para cerrar..."; [void][System.Console]::ReadLine(); exit 1
}
if (-not $data.items -or $data.items.Count -eq 0) {
    W "    [ERROR] No hay solicitudes para probar."
    Write-Host ""; Write-Host "ENTER para cerrar..."; [void][System.Console]::ReadLine(); exit 1
}
$s = $data.items[0]
W ("    id            : {0}" -f $s.id)
W ("    estado        : {0}" -f $s.estado)
W ("    lugar_nombre  : {0}" -f $s.lugar_nombre)
W ("    hora_entrega  : {0}" -f $s.hora_entrega)
W ("    hora_devoluc. : {0}" -f $s.hora_devolucion)
W ("    entregado_por : {0}" -f $s.entregado_por)
W ("    recibido_por  : {0}" -f $s.recibido_por)
W ("    notas         : {0}" -f $s.notas)

# ---- 2) Reenviar los MISMOS valores (idempotente) via PATCH anonimo ----
W ""
W "[2] PATCH anonimo reenviando los MISMOS valores (no cambia datos)..."
$updBody = @{
    estado          = $s.estado
    hora_entrega    = $s.hora_entrega
    hora_devolucion = $s.hora_devolucion
    entregado_por   = $s.entregado_por
    recibido_por    = $s.recibido_por
} | ConvertTo-Json

W "    Body enviado:"
W ("    " + ($updBody -replace "`r?`n", ' '))

try {
    $r2 = Invoke-WebRequest -Uri "$BASE/api/collections/solicitudes/records/$($s.id)" -Method Patch -Body $updBody -ContentType 'application/json' -UseBasicParsing -TimeoutSec 10
    W ""
    W ("    -> HTTP {0}  UPDATE ANONIMO OK. Los updates funcionan." -f $r2.StatusCode)
    W "       => El problema NO es el servidor rechazando el update."
    W "          Hay que mirar el frontend (version instalada / estado de conexion)."
} catch {
    $code = 'sin respuesta'
    $bodyErr = ''
    if ($_.Exception.Response) {
        try { $code = [int]$_.Exception.Response.StatusCode } catch {}
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $bodyErr = $reader.ReadToEnd()
        } catch {}
    }
    W ""
    W ("    -> HTTP {0}  UPDATE ANONIMO RECHAZADO." -f $code)
    W  "       MENSAJE DEL SERVIDOR (clave para el fix):"
    W ("       {0}" -f $bodyErr)
    W ("       (excepcion: {0})" -f $_.Exception.Message)
}

Line
W ("  LOG: {0}" -f $LOG)
Write-Host ""
Write-Host "Traé este .log a la laptop de desarrollo. ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
