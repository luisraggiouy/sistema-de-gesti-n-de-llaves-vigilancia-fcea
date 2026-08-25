# =============================================================
# DIAGNOSTICAR_HORA_INTERCAMBIO.ps1
# Fecha: 2026-08-25
#
# OBJETIVO:
#   Entender por que, tras un intercambio, el "tiempo en uso" de la
#   llave aparece con ~5 horas de mas. Este script NO modifica nada
#   (solo lectura). Trae la evidencia exacta para decidir el fix real.
#
# QUE MIRA:
#   1) Hora actual de ESTA PC (Monitor) + su zona horaria configurada.
#   2) Hora del servidor PocketBase (header HTTP 'Date').
#   3) Las 5 solicitudes mas recientes, mostrando el VALOR CRUDO de
#      hora_entrega / hora_devolucion / hora_solicitud / created tal
#      como estan guardados en la base.
#   4) Para la ultima ENTREGADA: calcula cuantos minutos/horas de
#      diferencia hay entre 'hora_entrega' guardada y el 'ahora' de la
#      PC. Eso confirma si el desfase viene del dato guardado.
#
#   * No crea, no borra, no actualiza. Es 100% lectura.
# =============================================================
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'DIAGNOSTICO Hora Intercambio - FCEA'

$BASE = 'http://127.0.0.1:8090'

$SCRIPTDIR  = Split-Path -Parent $MyInvocation.MyCommand.Path
$PENDRIVE   = [System.IO.Path]::GetPathRoot($SCRIPTDIR)
$RESULTADOS = Join-Path $PENDRIVE '_RESULTADOS'
if (-not (Test-Path $RESULTADOS)) { New-Item -ItemType Directory -Path $RESULTADOS | Out-Null }
$STAMP = Get-Date -Format 'yyyy-MM-dd_HHmm'
$LOG   = Join-Path $RESULTADOS ("LOG_HORA_INTERCAMBIO_" + $env:COMPUTERNAME + "_" + $STAMP + ".log")

function W($m) { Write-Host $m; Add-Content -Path $LOG -Value $m }
function Line { W ('=' * 62) }

Line
W "  DIAGNOSTICO: hora de entrega / intercambio (SOLO LECTURA)"
W ("  PC: {0}   Fecha script: {1}" -f $env:COMPUTERNAME, $STAMP)
Line

# ---- 1) Hora y zona horaria de esta PC ----
W ""
W "[1] Hora de ESTA PC (Monitor):"
$ahora = Get-Date
W ("    Hora local        : {0}" -f $ahora.ToString('yyyy-MM-dd HH:mm:ss'))
W ("    Hora local (ISO)  : {0}" -f $ahora.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ"))
try {
    $tz = Get-TimeZone
    W ("    Zona horaria      : {0}  (UTC offset actual: {1})" -f $tz.Id, $ahora.ToString('zzz'))
} catch {
    W ("    Zona horaria      : (no se pudo leer: {0})" -f $_.Exception.Message)
}

# ---- 2) Hora del servidor PocketBase ----
W ""
W "[2] Hora del servidor PocketBase (header HTTP 'Date'):"
try {
    $health = Invoke-WebRequest -Uri "$BASE/api/health" -Method Get -UseBasicParsing -TimeoutSec 10
    $serverDate = $health.Headers['Date']
    W ("    Header Date       : {0}" -f $serverDate)
} catch {
    W ("    [ERROR] No se pudo consultar PocketBase: {0}" -f $_.Exception.Message)
}

# ---- 3) Ultimas 5 solicitudes con valores CRUDOS ----
W ""
W "[3] Ultimas 5 solicitudes (valores CRUDOS guardados en la base):"
try {
    $resp = Invoke-WebRequest -Uri "$BASE/api/collections/solicitudes/records?perPage=5&sort=-created" -Method Get -UseBasicParsing -TimeoutSec 10
    $data = $resp.Content | ConvertFrom-Json
} catch {
    W ("    [ERROR] No se pudo leer solicitudes: {0}" -f $_.Exception.Message)
    Write-Host ""; Write-Host "ENTER para cerrar..."; [void][System.Console]::ReadLine(); exit 1
}

if (-not $data.items -or $data.items.Count -eq 0) {
    W "    (no hay solicitudes)"
} else {
    foreach ($s in $data.items) {
        W ""
        W ("    ---- id {0} ----" -f $s.id)
        W ("      lugar_nombre    : {0}" -f $s.lugar_nombre)
        W ("      usuario_nombre  : {0}" -f $s.usuario_nombre)
        W ("      estado          : {0}" -f $s.estado)
        W ("      es_intercambio  : {0}" -f $s.es_intercambio)
        W ("      created (server): {0}" -f $s.created)
        W ("      hora_solicitud  : {0}" -f $s.hora_solicitud)
        W ("      hora_entrega    : {0}" -f $s.hora_entrega)
        W ("      hora_devolucion : {0}" -f $s.hora_devolucion)
    }

    # ---- 4) Analisis de la ultima ENTREGADA ----
    W ""
    W "[4] Analisis de diferencia de tiempo (ultima ENTREGADA):"
    $entregada = $data.items | Where-Object { $_.estado -eq 'entregada' -and $_.hora_entrega } | Select-Object -First 1
    if (-not $entregada) {
        W "    (no hay ninguna solicitud 'entregada' con hora_entrega para analizar)"
    } else {
        $raw = [string]$entregada.hora_entrega
        W ("    hora_entrega cruda : '{0}'" -f $raw)
        # Intentar parsear de varias formas para ver como lo interpreta el sistema
        $parsed = $null
        try { $parsed = [datetime]::Parse($raw, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind) } catch {}
        if ($parsed) {
            $parsedUtc = $parsed.ToUniversalTime()
            $nowUtc = (Get-Date).ToUniversalTime()
            $diff = $nowUtc - $parsedUtc
            W ("    interpretada (UTC) : {0}" -f $parsedUtc.ToString('yyyy-MM-dd HH:mm:ss'))
            W ("    ahora PC     (UTC) : {0}" -f $nowUtc.ToString('yyyy-MM-dd HH:mm:ss'))
            W ("    DIFERENCIA         : {0} horas, {1} minutos, {2} seg" -f [int]$diff.TotalHours, $diff.Minutes, $diff.Seconds)
            W ""
            W "    INTERPRETACION:"
            W "      - Si la DIFERENCIA es ~0 y recien intercambiaste: el dato esta BIEN"
            W "        (el problema estaria en el navegador: cache del JS viejo -> Ctrl+F5)."
            W "      - Si la DIFERENCIA es ~3 h: desfase de zona horaria de Uruguay."
            W "      - Si es ~5 h: revisar el formato crudo de arriba (como se guardo)."
        } else {
            W "    [!] No se pudo parsear la hora_entrega. Mira el valor CRUDO de arriba"
            W "        y traelo: ese formato exacto es la clave del fix."
        }
    }
}

Line
W ("  LOG: {0}" -f $LOG)
Write-Host ""
Write-Host "Trae este .log a la laptop de desarrollo. ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
