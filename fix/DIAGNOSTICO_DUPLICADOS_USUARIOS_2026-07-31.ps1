# ============================================================================
# DIAGNOSTICO_DUPLICADOS_USUARIOS  (SOLO LECTURA - NO MODIFICA NADA)
# Sistema de Gestion de Llaves FCEA - 2026-07-31
# ============================================================================
# OBJETIVO:
#   Confirmar si el bug de "usuario duplicado 3 veces" en la busqueda por
#   telefono de la Terminal se debe a FILAS REALES DUPLICADAS en la base
#   (coleccion usuarios_registrados) o a una duplicacion en memoria/render
#   del frontend.
#
#   NO borra, NO edita, NO crea nada. Solo consulta la API REST de PocketBase
#   (GET) y agrupa por celular normalizado (solo digitos) para mostrar
#   cuantas filas comparten el mismo numero.
#
# DONDE EJECUTAR:
#   Se puede correr en el MONITOR DE VIGILANCIA (donde vive PocketBase en
#   localhost:8090) o en la TERMINAL A (que consulta al Monitor por red).
#   El script prueba solo varias direcciones hasta encontrar la base:
#     - lo que diga el config.json instalado (si existe)
#     - 127.0.0.1:8090 y localhost:8090  (caso Monitor)
#     - 192.168.100.10:8090              (caso Terminal A -> Monitor por LAN)
#   Doble clic en DIAGNOSTICO_DUPLICADOS_USUARIOS_2026-07-31.bat

#
# QUE MIRAR EN LA SALIDA:
#   - Si Lionel Messi (099098765) aparece con "Total filas: 3" -> son
#     DUPLICADOS REALES en la base (hay que limpiar datos + arreglar codigo).
#   - Si aparece con "Total filas: 1" -> es duplicacion de RENDER en el
#     frontend (alcanza con arreglar el codigo, no hay que tocar la base).
#   - Revisar tambien el celular 095321123 (Juan Peiras): ver que digitos
#     tiene realmente guardados en la base.
# ============================================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'DIAGNOSTICO DUPLICADOS USUARIOS - FCEA (solo lectura)'

function Line($c='='){ Write-Host ($c * 66) -ForegroundColor Yellow }
function Header($t){ Line; Write-Host "  $t" -ForegroundColor Yellow; Line }

Header "DIAGNOSTICO DUPLICADOS usuarios_registrados (SOLO LECTURA)"

# --- 1) Encontrar la URL de PocketBase ---------------------------------------
# Sirve tanto en el Monitor (localhost:8090) como en la Terminal A (que apunta
# al Monitor por LAN). Armamos una lista de candidatos:
#   a) pocketbase_url del config.json instalado (si existe y no es localhost)
#   b) 127.0.0.1 / localhost  (caso Monitor)
#   c) 192.168.100.10          (IP fijo del Monitor, caso Terminal A)
$candidatos = New-Object System.Collections.ArrayList

# a) Leer config.json instalado (varias rutas posibles)
$configPaths = @(
    'C:\sistema-llaves-fcea\dist\config.json',
    'C:\sistema-llaves-fcea\public\config.json',
    'C:\sistema-llaves-fcea\config.json'
)
foreach ($cp in $configPaths) {
    if (Test-Path $cp) {
        try {
            $cfg = Get-Content $cp -Raw | ConvertFrom-Json
            if ($cfg.pocketbase_url) {
                Write-Host ("  [config] pocketbase_url = {0}  (de {1})" -f $cfg.pocketbase_url, $cp) -ForegroundColor DarkCyan
                [void]$candidatos.Add(($cfg.pocketbase_url.TrimEnd('/')))
            }
        } catch {}
        break
    }
}

# b) y c) candidatos fijos
foreach ($u in @('http://127.0.0.1:8090','http://localhost:8090','http://192.168.100.10:8090')) {
    if (-not $candidatos.Contains($u)) { [void]$candidatos.Add($u) }
}

$base = $null
foreach ($b in $candidatos) {
    try {
        $h = Invoke-RestMethod -Uri "$b/api/health" -TimeoutSec 4 -ErrorAction Stop
        $base = $b
        Write-Host "  [OK] PocketBase responde en $b" -ForegroundColor Green
        break
    } catch {
        Write-Host "  [..] No responde en $b" -ForegroundColor DarkGray
    }
}

if (-not $base) {
    Write-Host ""
    Write-Host "  [ERROR] No se pudo contactar PocketBase en ninguna direccion." -ForegroundColor Red
    Write-Host "  Corre esto en el MONITOR con el sistema encendido, o en la" -ForegroundColor Yellow
    Write-Host "  Terminal A si el Monitor esta prendido y en red (192.168.100.10)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine()
    exit 1
}


# --- 2) Traer TODOS los usuarios_registrados (paginado) ----------------------
$page = 1
$items = @()
do {
    $url = "$base/api/collections/usuarios_registrados/records?perPage=500&page=$page&sort=created"
    try {
        $resp = Invoke-RestMethod -Uri $url -TimeoutSec 10 -ErrorAction Stop
    } catch {
        Write-Host ("  [ERROR] Fallo al listar (pagina {0}): {1}" -f $page, $_.Exception.Message) -ForegroundColor Red
        break
    }
    if ($resp.items) { $items += $resp.items }
    $totalPages = [int]$resp.totalPages
    $page++
} while ($page -le $totalPages)

Write-Host ""
Write-Host ("  Total de registros en usuarios_registrados: {0}" -f $items.Count) -ForegroundColor Cyan

# --- 3) Agrupar por celular normalizado (solo digitos) -----------------------
function NormTel($t){ if ($null -eq $t) { return '' }; return ([regex]::Replace([string]$t, '\D', '')) }

$grupos = @{}
foreach ($it in $items) {
    $key = NormTel $it.celular
    if ([string]::IsNullOrWhiteSpace($key)) { $key = '(sin celular)' }
    if (-not $grupos.ContainsKey($key)) { $grupos[$key] = New-Object System.Collections.ArrayList }
    [void]$grupos[$key].Add($it)
}

# --- 4) Reportar duplicados por celular --------------------------------------
Write-Host ""
Line
Write-Host "  CELULARES CON MAS DE UNA FILA (posibles duplicados REALES)" -ForegroundColor Yellow
Line

$huboDup = $false
foreach ($k in ($grupos.Keys | Sort-Object)) {
    $filas = $grupos[$k]
    if ($k -ne '(sin celular)' -and $filas.Count -gt 1) {
        $huboDup = $true
        Write-Host ""
        Write-Host ("  >> Celular {0}  ->  Total filas: {1}" -f $k, $filas.Count) -ForegroundColor Red
        foreach ($f in $filas) {
            Write-Host ("       id={0}  nombre='{1}'  celular='{2}'  tipo='{3}'  created={4}" -f `
                $f.id, $f.nombre, $f.celular, $f.tipo, $f.created) -ForegroundColor Gray
        }
    }
}
if (-not $huboDup) {
    Write-Host ""
    Write-Host "  [OK] Ningun celular tiene mas de una fila en la base." -ForegroundColor Green
    Write-Host "       => Los '3 Lionel Messi' NO son datos duplicados: es RENDER." -ForegroundColor Green
    Write-Host "       => El fix es SOLO de codigo (no hay que limpiar la base)." -ForegroundColor Green
}

# --- 5) Foco en los dos numeros del reporte del bug --------------------------
Write-Host ""
Line
Write-Host "  DETALLE de los numeros del reporte (099098765 y 095321123)" -ForegroundColor Yellow
Line
foreach ($objetivo in @('099098765','095321123')) {
    $filas = if ($grupos.ContainsKey($objetivo)) { $grupos[$objetivo] } else { @() }
    Write-Host ""
    Write-Host ("  Celular buscado: {0}  ->  filas encontradas: {1}" -f $objetivo, $filas.Count) -ForegroundColor Cyan
    foreach ($f in $filas) {
        Write-Host ("     id={0}  nombre='{1}'  celular='{2}'  email='{3}'  tipo='{4}'" -f `
            $f.id, $f.nombre, $f.celular, $f.email, $f.tipo) -ForegroundColor Gray
    }
}

# --- 6) Prueba del filtro 'includes' vs 'startsWith' -------------------------
# Reproduce la logica actual del frontend (includes) para ver que devolveria
# al tipear 099098765, y contrastar con startsWith (fix propuesto).
Write-Host ""
Line
Write-Host "  SIMULACION del filtro al tipear '099098765'" -ForegroundColor Yellow
Line
$q = '099098765'
$conIncludes = @($items | Where-Object { (NormTel $_.celular).Contains($q) })
$conStarts   = @($items | Where-Object { (NormTel $_.celular).StartsWith($q) })
Write-Host ("  includes  (codigo ACTUAL): {0} coincidencia(s)" -f $conIncludes.Count) -ForegroundColor Gray
foreach ($f in $conIncludes) { Write-Host ("       - {0} ({1})" -f $f.nombre, $f.celular) -ForegroundColor DarkGray }
Write-Host ("  startsWith (fix PROPUESTO): {0} coincidencia(s)" -f $conStarts.Count) -ForegroundColor Gray
foreach ($f in $conStarts) { Write-Host ("       - {0} ({1})" -f $f.nombre, $f.celular) -ForegroundColor DarkGray }

Write-Host ""
Line
Write-Host "  FIN DEL DIAGNOSTICO (no se modifico nada)." -ForegroundColor Green
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
