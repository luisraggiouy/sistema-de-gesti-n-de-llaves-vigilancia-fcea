# ============================================================================
#  PROBAR_ENTREGA.ps1  - Herramienta de diagnostico (HERRAMIENTAS_RED)
#  ---------------------------------------------------------------------------
#  Objetivo: averiguar POR QUE el Monitor no puede marcar una llave como
#  "entregada" (PocketBase responde HTTP 400 "Failed to update record").
#
#  Que hace (NO toca los pedidos reales):
#    1. Verifica conexion con PocketBase local.
#    2. Muestra los campos reales de un pedido existente (para detectar
#       diferencias de schema entre este PocketBase y el codigo).
#    3. Crea un pedido de PRUEBA temporal.
#    4. Intenta marcarlo como entregada CAMPO POR CAMPO e imprime el error
#       EXACTO que devuelve PocketBase en cada paso (asi vemos cual rompe).
#    5. Borra el pedido de prueba al final.
#
#  Ejecutar en la PC del MONITOR VIGILANCIA (es donde corre PocketBase).
# ============================================================================

$ErrorActionPreference = 'Stop'
$base = 'http://127.0.0.1:8090'
$col  = 'solicitudes'

# Guardar TODO lo que se imprime en un archivo de log (para no perder el detalle).
$logFile = Join-Path ([Environment]::GetFolderPath('Desktop')) 'PROBAR_ENTREGA_LOG.txt'
try { Start-Transcript -Path $logFile -Force | Out-Null } catch {}
Write-Host "Log guardandose en: $logFile"


function Send-PB {
    param(
        [string]$Method,
        [string]$Url,
        [string]$JsonBody
    )
    # Devuelve un objeto con Status y Body, capturando tambien los errores HTTP
    # (compatible con Windows PowerShell 5.1).
    try {
        $params = @{
            Method      = $Method
            Uri         = $Url
            ContentType = 'application/json'
            UseBasicParsing = $true
        }
        if ($JsonBody) { $params['Body'] = $JsonBody }
        $resp = Invoke-WebRequest @params
        return [pscustomobject]@{ Status = [int]$resp.StatusCode; Body = $resp.Content }
    } catch {
        $status = -1
        $body = $_.Exception.Message
        # En PowerShell, el cuerpo de la respuesta de error suele venir aca:
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            $body = $_.ErrorDetails.Message
        }
        $r = $_.Exception.Response
        if ($r -ne $null) {
            try { $status = [int]$r.StatusCode } catch {}
            if (-not ($_.ErrorDetails -and $_.ErrorDetails.Message)) {
                try {
                    $sr = New-Object System.IO.StreamReader($r.GetResponseStream())
                    $body = $sr.ReadToEnd()
                    $sr.Close()
                } catch {}
            }
        }
        return [pscustomobject]@{ Status = $status; Body = $body }
    }

}

function Titulo($t) {
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "  $t" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Cyan
}

Titulo "SONDA DE ENTREGA DE LLAVE - PocketBase local ($base)"

# --- 1) Conectividad --------------------------------------------------------
Titulo "1) Conectividad con PocketBase"
$health = Send-PB -Method 'GET' -Url "$base/api/health"
Write-Host ("   HTTP {0}" -f $health.Status)
if ($health.Status -ne 200) {
    Write-Host "   [X] No hay conexion con PocketBase. Abortar." -ForegroundColor Red
    Write-Host "   Respuesta: $($health.Body)"
    Read-Host "`nENTER para salir"
    exit 1
}
Write-Host "   [OK] PocketBase responde." -ForegroundColor Green

# --- 2) Campos reales de un pedido existente --------------------------------
Titulo "2) Campos reales de un pedido existente (deteccion de schema)"
$lista = Send-PB -Method 'GET' -Url "$base/api/collections/$col/records?perPage=1&sort=-created"
if ($lista.Status -eq 200) {
    try {
        $obj = $lista.Body | ConvertFrom-Json
        if ($obj.items -and $obj.items.Count -gt 0) {
            $rec = $obj.items[0]
            Write-Host "   Campos presentes en el registro mas reciente:" -ForegroundColor Yellow
            $rec.PSObject.Properties | ForEach-Object {
                Write-Host ("     - {0} = {1}" -f $_.Name, $_.Value)
            }
        } else {
            Write-Host "   (No hay pedidos aun para inspeccionar)"
        }
    } catch {
        Write-Host "   No se pudo parsear la lista: $($lista.Body)"
    }
} else {
    Write-Host "   HTTP $($lista.Status) - $($lista.Body)"
}

# --- 3) Crear pedido de PRUEBA ---------------------------------------------
Titulo "3) Crear pedido de PRUEBA temporal"
$nowIso = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$crearBody = @{
    lugar_nombre   = 'PRUEBA_DIAGNOSTICO'
    lugar_id       = 'diag'
    usuario_nombre = 'PRUEBA Diagnostico'
    usuario_celular= '000000000'
    tipo_usuario   = 'Docente'
    estado         = 'pendiente'
    hora_solicitud = $nowIso
    terminal       = 'DIAGNOSTICO'
} | ConvertTo-Json
$crear = Send-PB -Method 'POST' -Url "$base/api/collections/$col/records" -JsonBody $crearBody
Write-Host ("   POST create -> HTTP {0}" -f $crear.Status)
if ($crear.Status -ne 200) {
    Write-Host "   [X] No se pudo crear el pedido de prueba. Detalle:" -ForegroundColor Red
    Write-Host "   $($crear.Body)"
    Read-Host "`nENTER para salir"
    exit 1
}
$rid = ($crear.Body | ConvertFrom-Json).id
Write-Host "   [OK] Pedido de prueba creado. id = $rid" -ForegroundColor Green

# --- 4) Intentos de UPDATE campo por campo ----------------------------------
Titulo "4) Intentar marcar ENTREGADA (campo por campo)"

function ProbarUpdate($label, $bodyHash) {
    $json = $bodyHash | ConvertTo-Json -Compress
    $res = Send-PB -Method 'PATCH' -Url "$base/api/collections/$col/records/$rid" -JsonBody $json
    $color = if ($res.Status -eq 200) { 'Green' } else { 'Red' }
    Write-Host ""
    Write-Host ("   [{0}] PATCH {1}" -f $res.Status, $label) -ForegroundColor $color
    Write-Host ("        body enviado: {0}" -f $json)
    Write-Host ("        respuesta   : {0}" -f $res.Body)
}

ProbarUpdate "solo estado"          @{ estado = 'entregada' }
ProbarUpdate "solo hora_entrega"    @{ hora_entrega = $nowIso }
ProbarUpdate "solo entregado_por"   @{ entregado_por = 'PRUEBA' }
ProbarUpdate "los 3 juntos (como la app)" @{ estado = 'entregada'; hora_entrega = $nowIso; entregado_por = 'PRUEBA' }

# --- 5) Limpieza ------------------------------------------------------------
Titulo "5) Borrar pedido de prueba"
$del = Send-PB -Method 'DELETE' -Url "$base/api/collections/$col/records/$rid"
Write-Host ("   DELETE -> HTTP {0}" -f $del.Status)
if ($del.Status -eq 204 -or $del.Status -eq 200) {
    Write-Host "   [OK] Pedido de prueba eliminado." -ForegroundColor Green
} else {
    Write-Host "   [!] No se pudo borrar el pedido de prueba (id $rid). Borralo a mano si quedo." -ForegroundColor Yellow
    Write-Host "   $($del.Body)"
}

Titulo "FIN - Copiá TODO este resultado y pegámelo en la laptop de desarrollo"
Read-Host "`nENTER para salir"
