# =============================================================
# CAZAR_POCKETBASE_ZOMBIE.ps1  (v2 - con credenciales admin)
# Diagnostico + fix de PocketBase zombie.
#
# El sintoma es: la UI del Monitor pide guardar (por ejemplo un
# vigilante o una solicitud) y responde con "error al guardar,
# verifica la conexion", pero /api/health devuelve 200. Eso
# significa que HAY un PocketBase corriendo, pero es uno "zombie":
#   - una version vieja sin las colecciones actuales, o
#   - un PocketBase de otro directorio (con pb_data distinto), o
#   - un PocketBase huerfano de una instalacion anterior.
#
# v2: se autentica con las credenciales admin correctas para
# poder listar TODAS las colecciones (incluyendo las protegidas
# por permisos), inspeccionar el schema real, y hasta probar
# un CREATE en la coleccion vigilantes (con rollback).
#
#   Admin: vigilancia@llaves.local / vigilanciamvp2026
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'CAZAR POCKETBASE ZOMBIE v2 - Sistema FCEA'

$ADMIN_EMAIL = 'vigilancia@llaves.local'
$ADMIN_PASS  = 'vigilanciamvp2026'
$PB_URL      = 'http://127.0.0.1:8090'

function Line($c='='){ Write-Host ($c * 62) -ForegroundColor Yellow }
function Header($t) { Line; Write-Host "  $t" -ForegroundColor Yellow; Line }
function Sub($t) { Write-Host ""; Write-Host "--- $t ---" -ForegroundColor Cyan }

Header "CAZAR POCKETBASE ZOMBIE v2 - $env:COMPUTERNAME"

# ---- 1. Procesos pocketbase.exe corriendo ----
Sub "[1] Procesos pocketbase.exe activos"
$procesos = Get-CimInstance Win32_Process -Filter "Name='pocketbase.exe'" -ErrorAction SilentlyContinue
if (-not $procesos) {
  Write-Host "  [NADA] No hay procesos pocketbase.exe corriendo." -ForegroundColor Red
} else {
  $cnt = @($procesos).Count
  Write-Host ("  Encontrados: {0} proceso(s) pocketbase.exe" -f $cnt) -ForegroundColor $(if ($cnt -eq 1) { 'Green' } else { 'Red' })
  if ($cnt -gt 1) {
    Write-Host "  [ZOMBIE] Hay mas de 1 pocketbase.exe. Solo deberia haber UNO." -ForegroundColor Red
  }
  foreach ($p in $procesos) {
    Write-Host ""
    Write-Host ("  PID={0}   arrancado {1}" -f $p.ProcessId, $p.CreationDate) -ForegroundColor White
    Write-Host ("    EXE: {0}" -f $p.ExecutablePath)
    Write-Host ("    CMD: {0}" -f $p.CommandLine)
  }
}

# ---- 2. Puerto 8090 escuchando: quien es dueno? ----
Sub "[2] Quien escucha el puerto 8090?"
$conns = netstat -ano | Select-String ':8090\s+.*LISTENING'
if ($conns) {
  foreach ($c in $conns) {
    Write-Host ("  {0}" -f $c.Line.Trim())
  }
} else {
  Write-Host "  [NADA] Nadie escuchando en 8090." -ForegroundColor Red
}

# ---- 3. /api/health ----
Sub "[3] /api/health responde?"
$healthOk = $false
try {
  $r = Invoke-WebRequest -Uri "$PB_URL/api/health" -TimeoutSec 3 -UseBasicParsing
  Write-Host ("  HTTP {0}" -f $r.StatusCode) -ForegroundColor Green
  Write-Host ("  Body: {0}" -f $r.Content) -ForegroundColor Gray
  $healthOk = $true
} catch {
  Write-Host ("  [SIN RESPUESTA] {0}" -f $_.Exception.Message) -ForegroundColor Red
}

# ---- 4. Autenticarse como admin ----
Sub "[4] Autenticando como admin ($ADMIN_EMAIL)"
$token = $null
if (-not $healthOk) {
  Write-Host "  [SKIP] Sin health check no probamos login." -ForegroundColor Yellow
} else {
  $body = @{ identity = $ADMIN_EMAIL; password = $ADMIN_PASS } | ConvertTo-Json
  # PocketBase 0.22+ usa /api/collections/_superusers/auth-with-password
  # PocketBase <=0.21 usa /api/admins/auth-with-password
  $endpoints = @(
    "$PB_URL/api/collections/_superusers/auth-with-password",
    "$PB_URL/api/admins/auth-with-password"
  )
  foreach ($ep in $endpoints) {
    try {
      $r = Invoke-RestMethod -Uri $ep -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 5
      if ($r.token) {
        $token = $r.token
        Write-Host ("  [OK] Autenticado via {0}" -f $ep) -ForegroundColor Green
        Write-Host ("  Token: {0}..." -f $token.Substring(0, [Math]::Min(30, $token.Length))) -ForegroundColor Gray
        break
      }
    } catch {
      $status = $null
      try { $status = $_.Exception.Response.StatusCode.Value__ } catch {}
      Write-Host ("  [FAIL] {0} => HTTP {1} ({2})" -f (Split-Path $ep -Leaf), $status, $_.Exception.Message) -ForegroundColor DarkYellow
    }
  }
  if (-not $token) {
    Write-Host "  [ERROR] No se pudo autenticar con esas credenciales." -ForegroundColor Red
    Write-Host "  Posibles causas:" -ForegroundColor Yellow
    Write-Host "   - Este PocketBase es de otra instalacion (no tiene ese admin)" -ForegroundColor Yellow
    Write-Host "   - El pb_data esta corrupto" -ForegroundColor Yellow
    Write-Host "   - Version de PocketBase incompatible" -ForegroundColor Yellow
  }
}

$authHeaders = @{}
if ($token) { $authHeaders['Authorization'] = $token }

# ---- 5. Listar TODAS las colecciones existentes ----
Sub "[5] Colecciones existentes en la DB (via admin)"
$existentes = @()
if ($token) {
  try {
    $r = Invoke-RestMethod -Uri "$PB_URL/api/collections?perPage=200" -Headers $authHeaders -TimeoutSec 5
    $existentes = @($r.items | Select-Object -ExpandProperty name)
    Write-Host ("  Total: {0} colecciones" -f $existentes.Count) -ForegroundColor Cyan
    foreach ($col in ($r.items | Sort-Object name)) {
      Write-Host ("    - {0,-25}  type={1}  fields={2}" -f $col.name, $col.type, @($col.fields).Count)
    }
  } catch {
    Write-Host ("  [ERROR listando] {0}" -f $_.Exception.Message) -ForegroundColor Red
  }
} else {
  Write-Host "  [SKIP] Sin token no podemos listar todas las colecciones." -ForegroundColor Yellow
}

# ---- 6. Colecciones criticas + conteo de registros ----
Sub "[6] Colecciones criticas + cantidad de registros"
# Nombres reales tal como se usan en src/**/*.ts(x)
# vigilante (singular!), solicitudes, lugares, usuarios_registrados,
# historial_llaves, objetos_olvidados, configuracion, admin_config
$colecciones = @(
  'vigilante',
  'solicitudes',
  'lugares',
  'usuarios_registrados',
  'historial_llaves',
  'objetos_olvidados',
  'configuracion',
  'admin_config'
)
$faltantes = @()
foreach ($col in $colecciones) {
  $exists = ($existentes -contains $col)
  if (-not $exists -and $token) {
    Write-Host ("  [FALTA] {0} - NO existe en el schema" -f $col) -ForegroundColor Red
    $faltantes += $col
    continue
  }
  try {
    $r = Invoke-RestMethod -Uri "$PB_URL/api/collections/$col/records?perPage=1" -Headers $authHeaders -TimeoutSec 5
    Write-Host ("  [OK] {0,-25}  {1} registros" -f $col, $r.totalItems) -ForegroundColor Green
  } catch {
    $status = $null
    try { $status = $_.Exception.Response.StatusCode.Value__ } catch {}
    Write-Host ("  [FAIL] {0,-25}  HTTP {1}" -f $col, $status) -ForegroundColor Red
    $faltantes += $col
  }
}

# ---- 6.5. Schema REAL de vigilante ----
Sub "[6.5] Schema REAL de coleccion 'vigilante' (campos + reglas)"
# OJO: en PocketBase v0.22+ la propiedad se llama 'fields', en v0.21-
# se llama 'schema'. Miramos las DOS.
$schemaVig = $null
if ($token -and ($existentes -contains 'vigilante')) {
  try {
    $schemaVig = Invoke-RestMethod -Uri "$PB_URL/api/collections/vigilante" -Headers $authHeaders -TimeoutSec 5
    Write-Host ("  Coleccion: {0}  id={1}" -f $schemaVig.name, $schemaVig.id) -ForegroundColor Cyan
    # Intentar leer 'fields' (v0.22+) y 'schema' (v0.21-)
    $campos = @()
    if ($schemaVig.fields)  { $campos = @($schemaVig.fields) }
    if ($schemaVig.schema)  { $campos = @($schemaVig.schema) }
    Write-Host ("  Cantidad de campos: {0}" -f $campos.Count)
    Write-Host "  Campos:"
    if ($campos.Count -eq 0) {
      Write-Host "    (ninguno detectado por API - probable diferencia de version PB)" -ForegroundColor Yellow
      # DUMP raw JSON de la coleccion para diagnostico final
      Write-Host ""
      Write-Host "  JSON crudo de la coleccion (primeras 2000 chars):" -ForegroundColor DarkGray
      $raw = $schemaVig | ConvertTo-Json -Depth 10 -Compress
      if ($raw.Length -gt 2000) { $raw = $raw.Substring(0, 2000) + '...[TRUNCADO]' }
      Write-Host ("    {0}" -f $raw) -ForegroundColor DarkGray
    } else {
      foreach ($f in $campos) {
        $req = if ($f.required) { 'REQ' } else { 'opt' }
        Write-Host ("    - {0,-25} type={1,-10} {2}" -f $f.name, $f.type, $req)
      }
    }
    Write-Host ""
    Write-Host "  Reglas:"
    $showRule = { param($x) if ($null -eq $x -or $x -eq '') { '(publica - null)' } else { "$x" } }
    Write-Host ("    listRule  : {0}" -f (& $showRule $schemaVig.listRule))
    Write-Host ("    viewRule  : {0}" -f (& $showRule $schemaVig.viewRule))
    Write-Host ("    createRule: {0}" -f (& $showRule $schemaVig.createRule))
    Write-Host ("    updateRule: {0}" -f (& $showRule $schemaVig.updateRule))
    Write-Host ("    deleteRule: {0}" -f (& $showRule $schemaVig.deleteRule))
  } catch {
    Write-Host ("  [ERROR] {0}" -f $_.Exception.Message) -ForegroundColor Red
  }
}

# ---- 7. Test CREATE + DELETE en vigilante ----
Sub "[7] Test CREATE en 'vigilante' (multiples intentos)"
# Probamos 3 variantes de payload para acorralar el problema.
$vigOk = $false
$creadoId = $null
if ($token -and ($existentes -contains 'vigilante')) {
  $stamp = Get-Date -Format 'HHmmss'
  $intentos = @(
    @{
      nombre = 'Solo nombre (minimo absoluto)'
      body   = @{ nombre = "__TEST_MIN_$stamp" }
    },
    @{
      nombre = 'Payload igual al frontend'
      body   = @{ nombre = "__TEST_A_$stamp"; turno = 'Matutino'; es_jefe = $false }
    },
    @{
      nombre = 'Payload vacio { }'
      body   = @{}
    }
  )
  $headers = $authHeaders.Clone()
  $headers['Content-Type'] = 'application/json'
  foreach ($i in $intentos) {
    Write-Host ""
    Write-Host ("  Intento: {0}" -f $i.nombre) -ForegroundColor White
    Write-Host ("    payload: {0}" -f ($i.body | ConvertTo-Json -Compress))
    # v2.3: usar Invoke-WebRequest para capturar el body incluso en errores 4xx.
    # Truco: -SkipHttpErrorCheck (PS7+) o try/catch leyendo _.ErrorDetails.Message
    # que es donde PS <7 deja el body cuando Invoke-WebRequest tira excepcion.
    $ok = $false; $status = $null; $bodyResp = $null
    try {
      $resp = Invoke-WebRequest `
        -Uri "$PB_URL/api/collections/vigilante/records" `
        -Method Post `
        -Body ($i.body | ConvertTo-Json) `
        -Headers $headers `
        -TimeoutSec 5 `
        -UseBasicParsing `
        -ErrorAction Stop
      $status = $resp.StatusCode
      $bodyResp = $resp.Content
      $ok = ($status -ge 200 -and $status -lt 300)
    } catch {
      # PowerShell 5.1: el body del 4xx queda en $_.ErrorDetails.Message
      try { $status = $_.Exception.Response.StatusCode.Value__ } catch {}
      if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        $bodyResp = $_.ErrorDetails.Message
      } else {
        try {
          $stream = $_.Exception.Response.GetResponseStream()
          if ($stream) {
            $stream.Position = 0
            $sr = New-Object System.IO.StreamReader($stream)
            $bodyResp = $sr.ReadToEnd()
          }
        } catch {}
      }
    }
    if ($ok) {
      try {
        $j = $bodyResp | ConvertFrom-Json
        $creadoId = $j.id
        Write-Host ("    [OK] Creado id={0}" -f $creadoId) -ForegroundColor Green
        $vigOk = $true
        break
      } catch {
        Write-Host "    [OK] pero no pude parsear el JSON de respuesta." -ForegroundColor Yellow
        $vigOk = $true
        break
      }
    } else {
      Write-Host ("    [FAIL] HTTP {0}" -f $status) -ForegroundColor Red
      if ($bodyResp) {
        # Cortar a 500 chars para que no ocupe toda la pantalla
        $short = $bodyResp
        if ($short.Length -gt 500) { $short = $short.Substring(0, 500) + '...' }
        Write-Host "    ---- respuesta del server ----" -ForegroundColor DarkRed
        Write-Host ("    {0}" -f $short) -ForegroundColor Red
        Write-Host "    ------------------------------" -ForegroundColor DarkRed
      } else {
        Write-Host "    (server no envio cuerpo de error - raro)" -ForegroundColor DarkYellow
      }
    }
  }
  # Rollback
  if ($creadoId) {
    try {
      Invoke-RestMethod -Uri "$PB_URL/api/collections/vigilante/records/$creadoId" -Method Delete -Headers $authHeaders -TimeoutSec 5 | Out-Null
      Write-Host ""
      Write-Host "  [OK] Rollback: registro de prueba borrado." -ForegroundColor Gray
    } catch {
      Write-Host ("  [WARN] No pude borrar el registro id=$creadoId : {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
  }
  if (-not $vigOk) {
    Write-Host ""
    Write-Host "  [DIAGNOSTICO] Los 3 intentos fallaron. Comparar el schema" -ForegroundColor Yellow
    Write-Host "  del paso [6.5] con lo que envia el frontend." -ForegroundColor Yellow
    Write-Host "  Payload frontend: { nombre, turno, es_jefe }" -ForegroundColor Yellow
    Write-Host "  Si el schema tiene campos REQ que el frontend no envia, ese" -ForegroundColor Yellow
    Write-Host "  es el problema. Ver PocketBase Admin: http://127.0.0.1:8090/_" -ForegroundColor Yellow
  }
} else {
  Write-Host "  [SKIP] No hay token o no existe la coleccion vigilante." -ForegroundColor Yellow
}

# ---- 8. Ubicacion REAL de pb_data (deducida del CMD del proceso) ----
Sub "[8] Directorio pb_data REAL del proceso corriendo"
# Extraer --dir="..." del CommandLine del proceso pocketbase.exe
$pbDataReal = $null
if ($procesos) {
  foreach ($p in $procesos) {
    $cmd = "$($p.CommandLine)"
    $m = [regex]::Match($cmd, '--dir[=\s]+"?([^"\s]+)"?')
    if ($m.Success) {
      $pbDataReal = $m.Groups[1].Value
      Write-Host ("  Detectado del proceso PID={0}: pb_data = {1}" -f $p.ProcessId, $pbDataReal) -ForegroundColor Cyan
      break
    }
  }
}
if (-not $pbDataReal) {
  # Buscar en las 2 ubicaciones conocidas
  $candidatos = @(
    'C:\ProgramData\FCEA-Sistema-Llaves\pb_data',
    'C:\sistema-llaves-fcea\pocketbase\pb_data'
  )
  foreach ($c in $candidatos) {
    if (Test-Path $c) {
      $pbDataReal = $c
      Write-Host ("  Encontrado por sondeo: {0}" -f $c) -ForegroundColor Cyan
      break
    }
  }
}

if ($pbDataReal -and (Test-Path $pbDataReal)) {
  # 8a. Espacio libre en la unidad
  $drive = (Get-Item $pbDataReal).PSDrive
  if ($drive) {
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    $col = if ($freeGB -lt 0.5) { 'Red' } elseif ($freeGB -lt 2) { 'Yellow' } else { 'Green' }
    Write-Host ("  Espacio libre en {0}: {1} GB" -f $drive.Name, $freeGB) -ForegroundColor $col
  }

  # 8b. Archivos criticos
  $dbFile = Join-Path $pbDataReal 'data.db'
  if (Test-Path $dbFile) {
    $it = Get-Item $dbFile
    $ro = $it.IsReadOnly
    Write-Host ("  data.db      : {0:N1} KB  mod: {1}  readonly={2}" -f ($it.Length/1KB), $it.LastWriteTime, $ro) -ForegroundColor $(if ($ro){'Red'}else{'Green'})
  } else {
    Write-Host "  [ERROR] data.db no existe en pb_data" -ForegroundColor Red
  }
  foreach ($aux in @('data.db-shm','data.db-wal','auxiliary.db','auxiliary.db-shm','auxiliary.db-wal')) {
    $f = Join-Path $pbDataReal $aux
    if (Test-Path $f) {
      $it = Get-Item $f
      Write-Host ("  {0,-20}: {1:N1} KB  mod: {2}" -f $aux, ($it.Length/1KB), $it.LastWriteTime) -ForegroundColor Gray
    }
  }

  # 8c. Permisos: probar escribir un archivo temporal
  Write-Host ""
  Write-Host "  Test de escritura en pb_data:"
  $tmpFile = Join-Path $pbDataReal ('__test_write_' + (Get-Random) + '.tmp')
  try {
    'test' | Set-Content -Path $tmpFile -ErrorAction Stop
    Remove-Item $tmpFile -ErrorAction SilentlyContinue
    Write-Host "    [OK] Se puede escribir en pb_data (permisos NTFS OK)" -ForegroundColor Green
  } catch {
    Write-Host ("    [FAIL] No se puede escribir: {0}" -f $_.Exception.Message) -ForegroundColor Red
  }

  # 8d. Locks abiertos por otros procesos sobre data.db
  Write-Host ""
  Write-Host "  Procesos con handles abiertos sobre data.db:"
  $handleTool = "$env:SystemRoot\System32\openfiles.exe"
  # openfiles requiere haberse habilitado. En su lugar usamos un test simple:
  # abrir data.db en modo exclusivo. Si falla, es porque otro proceso lo tiene.
  try {
    $fs = [System.IO.File]::Open($dbFile, 'Open', 'ReadWrite', 'None')
    $fs.Close()
    Write-Host "    [OK] data.db se puede abrir en modo exclusivo (sin locks externos)" -ForegroundColor Green
  } catch {
    Write-Host ("    [LOCK] {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "    (Normal si PocketBase esta corriendo. Anormal si hay 2 PB o proceso zombie)" -ForegroundColor DarkYellow
  }
} else {
  Write-Host "  [NO EXISTE] No pude localizar pb_data en ningun sitio conocido." -ForegroundColor Red
}

# 8e. Extra: probar en OTRA coleccion para ver si es SOLO vigilante o TODAS
Sub "[8.5] Test CREATE en OTRAS colecciones (para saber si es solo vigilante)"
if ($token) {
  $headers2 = $authHeaders.Clone()
  $headers2['Content-Type'] = 'application/json'
  $stampX = Get-Date -Format 'HHmmss'
  # Probamos crear un registro tonto en 'lugares' (que tiene 177 items -> claramente funcional en el pasado)
  $lugarBody = @{ nombre = "__TEST_LUGAR_$stampX" } | ConvertTo-Json
  try {
    $resp = Invoke-WebRequest -Uri "$PB_URL/api/collections/lugares/records" -Method Post -Body $lugarBody -Headers $headers2 -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    $j = $resp.Content | ConvertFrom-Json
    Write-Host ("  [OK] CREATE en 'lugares' funciono. id={0}" -f $j.id) -ForegroundColor Green
    Write-Host "  --> el problema es SOLO en 'vigilante'" -ForegroundColor Yellow
    try { Invoke-RestMethod -Uri "$PB_URL/api/collections/lugares/records/$($j.id)" -Method Delete -Headers $authHeaders -TimeoutSec 5 | Out-Null } catch {}
  } catch {
    $s = $null; $b = $null
    try { $s = $_.Exception.Response.StatusCode.Value__ } catch {}
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $b = $_.ErrorDetails.Message }
    Write-Host ("  [FAIL] CREATE en 'lugares' HTTP {0}" -f $s) -ForegroundColor Red
    if ($b) { Write-Host ("    resp: {0}" -f $b) -ForegroundColor Red }
    Write-Host "  --> el problema es GENERAL (no puede escribir en ninguna coleccion)" -ForegroundColor Yellow
  }
}

# ---- 9. Diagnostico y accion ----
Sub "[9] DIAGNOSTICO"
$hayProblema = $false
if (@($procesos).Count -gt 1) {
  Write-Host "  * Hay MAS DE UN pocketbase.exe corriendo (posibles zombies)" -ForegroundColor Red
  $hayProblema = $true
}
if (-not $token) {
  Write-Host "  * No se pudo autenticar como admin (credenciales invalidas)" -ForegroundColor Red
  Write-Host "    -> Este PocketBase NO es el de esta instalacion" -ForegroundColor Red
  $hayProblema = $true
}
# admin_config es opcional (solo la usa custodian pass); no cuenta como fallo
$faltantesCriticas = $faltantes | Where-Object { $_ -ne 'admin_config' }
if ($faltantesCriticas.Count -gt 0) {
  Write-Host ("  * Colecciones faltantes CRITICAS: {0}" -f ($faltantesCriticas -join ', ')) -ForegroundColor Red
  $hayProblema = $true
} elseif ($faltantes -contains 'admin_config') {
  Write-Host "  * admin_config NO existe (opcional - solo password de custodio)" -ForegroundColor Yellow
}
if ($token -and -not $vigOk) {
  Write-Host "  * El CREATE en 'vigilante' fallo - la razon del error de la UI" -ForegroundColor Red
  $hayProblema = $true
}

if (-not $hayProblema) {
  Write-Host "  [SANO] Todo OK a nivel PocketBase." -ForegroundColor Green
  Write-Host "  Si la UI aun falla, probable cache del navegador." -ForegroundColor Gray
  Write-Host "  Ctrl+Shift+Delete en Chrome -> borrar cache, o Ctrl+F5." -ForegroundColor Gray
} else {
  Line
  Write-Host "  ACCION RECOMENDADA" -ForegroundColor Yellow
  Line
  Write-Host "  1) Matar TODO pocketbase.exe (opcion abajo)"
  Write-Host "  2) Doble click en ARRANCAR SISTEMA.bat del escritorio"
  Write-Host "  3) Correr este script de nuevo para verificar"
  Write-Host ""
  $r = Read-Host "  Ejecutar ya el paso 1 (matar todo pocketbase.exe)? (S/N)"
  if ($r -match '^[sSyY]') {
    Write-Host "  Matando..." -ForegroundColor Yellow
    Get-Process -Name pocketbase -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $q = Get-Process -Name pocketbase -ErrorAction SilentlyContinue
    if ($q) {
      Write-Host "  [WARN] Aun quedan procesos pocketbase. Intento con taskkill /F..." -ForegroundColor Yellow
      taskkill /F /IM pocketbase.exe 2>&1 | Out-Null
      Start-Sleep -Seconds 2
    }
    $q = Get-Process -Name pocketbase -ErrorAction SilentlyContinue
    if ($q) {
      Write-Host "  [ERROR] No pude matar todos los pocketbase.exe. Reiniciar Windows." -ForegroundColor Red
    } else {
      Write-Host "  [OK] Todos los pocketbase.exe muertos." -ForegroundColor Green
      Write-Host "  Ahora doble click en ARRANCAR SISTEMA.bat del escritorio." -ForegroundColor Cyan
    }
  }
}

Write-Host ""
Line
Write-Host "  FIN - envia foto de esta pantalla" -ForegroundColor Green
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
