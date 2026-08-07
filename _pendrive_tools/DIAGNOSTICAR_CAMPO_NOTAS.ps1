# =============================================================
# DIAGNOSTICAR_CAMPO_NOTAS.ps1   (SOLO LECTURA)
# Verifica si la coleccion 'solicitudes' del PocketBase de ESTA PC
# (Monitor de Vigilancia) tiene el campo 'notas' y si algun registro
# tiene notas cargadas.
#
# NO modifica nada. Solo consulta la API REST local y escribe un .log
# en el pendrive para traerlo a la laptop de desarrollo.
# Fecha: 2026-08-07
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'DIAGNOSTICO Campo Notas - Sistema FCEA'

# El pendrive es esta misma carpeta (donde esta el script) hacia arriba.
$SCRIPTDIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PENDRIVE  = Split-Path -Parent $SCRIPTDIR   # sale de _pendrive_tools -> raiz del pendrive
$RESULTADOS = Join-Path $PENDRIVE '_RESULTADOS'
if (-not (Test-Path $RESULTADOS)) { New-Item -ItemType Directory -Path $RESULTADOS | Out-Null }

$STAMP = Get-Date -Format 'yyyy-MM-dd_HHmm'
$LOG   = Join-Path $RESULTADOS ("LOG_CAMPO_NOTAS_" + $env:COMPUTERNAME + "_" + $STAMP + ".log")

$BASE = 'http://127.0.0.1:8090'

function W($msg) { Write-Host $msg; Add-Content -Path $LOG -Value $msg }

W ("=" * 62)
W "  DIAGNOSTICO: campo 'notas' en coleccion 'solicitudes'"
W ("  PC: {0}   Fecha: {1}" -f $env:COMPUTERNAME, $STAMP)
W ("  PocketBase: {0}" -f $BASE)
W ("=" * 62)

# 1) Traer algunos registros (la coleccion es publica: listRule = "")
try {
    $url = "$BASE/api/collections/solicitudes/records?perPage=5&sort=-created"
    W ""
    W "[1] GET $url"
    $resp = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 10
    W ("    totalItems reportado por PocketBase: {0}" -f $resp.totalItems)

    if ($resp.items -and $resp.items.Count -gt 0) {
        $primero = $resp.items[0]
        W ""
        W "[2] Campos presentes en el primer registro:"
        $campos = ($primero.PSObject.Properties | ForEach-Object { $_.Name }) | Sort-Object
        foreach ($c in $campos) { W ("      - {0}" -f $c) }

        $tieneCampoNotas = $campos -contains 'notas'
        W ""
        if ($tieneCampoNotas) {
            W "[3] RESULTADO: la coleccion SI tiene el campo 'notas'."
        } else {
            W "[3] RESULTADO: la coleccion NO tiene el campo 'notas'."
            W "    (Por eso las notas escritas nunca se guardan y el historial no las muestra)."
        }

        # 4) Cuantos de los ultimos 5 registros tienen notas con contenido
        W ""
        W "[4] Notas en los ultimos 5 registros:"
        $i = 0
        foreach ($it in $resp.items) {
            $i++
            $val = $null
            if ($it.PSObject.Properties.Name -contains 'notas') { $val = $it.notas }
            $lugar = $it.lugar_nombre
            if ([string]::IsNullOrWhiteSpace([string]$val)) {
                W ("      {0}) {1} -> (sin notas)" -f $i, $lugar)
            } else {
                W ("      {0}) {1} -> NOTA: '{2}'" -f $i, $lugar, $val)
            }
        }
    } else {
        W "    [AVISO] No vinieron registros (items vacio)."
    }
} catch {
    W ""
    W "[ERROR] No se pudo consultar la API de PocketBase:"
    W ("        {0}" -f $_.Exception.Message)
    W "        Verifica que PocketBase este corriendo en esta PC (Monitor)."
}

W ""
W ("=" * 62)
W ("  LOG guardado en: {0}" -f $LOG)
W ("=" * 62)
Write-Host ""
Write-Host "Trae este archivo .log a la laptop de desarrollo:" -ForegroundColor Yellow
Write-Host "  $LOG" -ForegroundColor Yellow
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
