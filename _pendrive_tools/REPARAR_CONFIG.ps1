# =============================================================
# REPARAR_CONFIG.ps1  (v2 - clave correcta pocketbase_url)
# Corrige el bug de config.json con pocketbase_url vacio.
#
# El frontend (src/lib/runtimeConfig.ts) y el arrancador
# (scripts/install/INICIAR.bat) usan la clave 'pocketbase_url'
# con GUION BAJO. La v1 de este script escribia 'pocketbaseUrl'
# en camelCase y no arreglaba nada.
#
# Auto-detecta si es Monitor (IP 192.168.100.10) o Terminal,
# reescribe C:\sistema-llaves-fcea\dist\config.json y
# public\config.json con la URL correcta:
#   Monitor  -> http://127.0.0.1:8090
#   Terminal -> http://192.168.100.10:8090
#
# Escribe la clave con GUION BAJO (pocketbase_url), pero si
# encuentra la vieja camelCase (pocketbaseUrl) tambien la
# actualiza por si algo la lee.
#
# Hace backup .bak.<fecha> antes de tocar.
# Al final, ofrece matar Chrome para que recargue con la config nueva.
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'REPARAR CONFIG - Sistema FCEA (v2)'

function Line($c='='){ Write-Host ($c * 62) -ForegroundColor Yellow }
function Header($t) { Line; Write-Host "  $t" -ForegroundColor Yellow; Line }
function Sub($t) { Write-Host ""; Write-Host "--- $t ---" -ForegroundColor Cyan }

Header "REPARAR config.json v2 - $env:COMPUTERNAME"

# ---- 1. Detectar rol por IP ----
Sub "[1] Detectando rol de esta PC"
$ips = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
         Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
         Select-Object -ExpandProperty IPAddress)
Write-Host "  IPs de esta PC: $($ips -join ', ')"

$soyMonitor = $ips -contains '192.168.100.10'
$hostname = $env:COMPUTERNAME
if ($soyMonitor -or $hostname -match '^FCEA-MON') {
  $rol = 'monitor'
  $urlNueva = 'http://127.0.0.1:8090'
  Write-Host "  Esta PC es el MONITOR. pocketbase_url -> $urlNueva" -ForegroundColor Green
} else {
  $rol = 'terminal'
  $urlNueva = 'http://192.168.100.10:8090'
  Write-Host "  Esta PC parece ser TERMINAL. Se apuntara al Monitor." -ForegroundColor Cyan
  Write-Host "  URL sugerida: $urlNueva"
  $r = Read-Host "  IP del Monitor (ENTER = 192.168.100.10)"
  if (-not [string]::IsNullOrWhiteSpace($r)) {
    if ($r -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
      $urlNueva = "http://${r}:8090"
    } else {
      Write-Host "  [ERROR] IP invalida. Uso el default 192.168.100.10." -ForegroundColor Red
    }
  }
  Write-Host "  Nueva pocketbase_url: $urlNueva" -ForegroundColor Green
}

# ---- 2. Localizar config.json ----
Sub "[2] Buscando config.json"
$paths = @(
  'C:\sistema-llaves-fcea\dist\config.json',
  'C:\sistema-llaves-fcea\public\config.json'
)
$existentes = @()
foreach ($p in $paths) {
  if (Test-Path $p) {
    $existentes += $p
    try {
      $j = Get-Content $p -Raw | ConvertFrom-Json
      $urlVieja1 = $j.pocketbase_url
      $urlVieja2 = $j.pocketbaseUrl
      Write-Host ("  [ENCONTRADO] {0}" -f $p) -ForegroundColor Green
      Write-Host ("      rol={0}  hardware={1}" -f $j.rol, $j.hardware)
      Write-Host ("      pocketbase_url='{0}'" -f $urlVieja1)
      if ($urlVieja2) {
        Write-Host ("      pocketbaseUrl='{0}'  (obsoleta)" -f $urlVieja2) -ForegroundColor Yellow
      }
    } catch {
      Write-Host ("  [ENCONTRADO pero JSON invalido] {0}" -f $p) -ForegroundColor Red
    }
  } else {
    Write-Host ("  [NO EXISTE] {0}" -f $p) -ForegroundColor Yellow
  }
}
if ($existentes.Count -eq 0) {
  Write-Host "  [ERROR] No hay ningun config.json que reparar." -ForegroundColor Red
  Write-Host "  Verifica que la aplicacion este instalada en C:\sistema-llaves-fcea\" -ForegroundColor Red
  Write-Host ""; Write-Host "Presiona ENTER..." -ForegroundColor Gray; [void][System.Console]::ReadLine(); exit 1
}

# ---- 3. Test antes de escribir (solo Terminal) ----
if ($rol -eq 'terminal') {
  Sub "[3] Test previo: el Monitor responde?"
  try {
    $r = Invoke-WebRequest -Uri "$urlNueva/api/health" -TimeoutSec 4 -UseBasicParsing
    Write-Host ("  HTTP $($r.StatusCode) - el Monitor responde OK.") -ForegroundColor Green
  } catch {
    Write-Host ("  [ADVERTENCIA] El Monitor no responde en $urlNueva") -ForegroundColor Yellow
    Write-Host ("  Detalle: $($_.Exception.Message)") -ForegroundColor Yellow
    Write-Host "  Guardando de todos modos - se puede reintentar mas tarde." -ForegroundColor Yellow
  }
}

# ---- 4. Reescribir config.json ----
Sub "[4] Reescribiendo config.json"
foreach ($p in $existentes) {
  try {
    $j = Get-Content $p -Raw | ConvertFrom-Json
  } catch {
    $j = [pscustomobject]@{
      version = '2.1.0'
      modo = 'produccion'
      rol = if ($rol -eq 'monitor') { 'monitor' } else { 'terminal-a' }
      hardware = if ($rol -eq 'monitor') { 'tradicional' } else { 'tactil' }
      pocketbase_url = ''
    }
  }

  # Backup
  $bak = "$p.bak.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
  Copy-Item $p $bak -Force -ErrorAction SilentlyContinue
  Write-Host ("  Backup: {0}" -f $bak) -ForegroundColor Gray

  # ------- SETEAR pocketbase_url (clave CORRECTA con guion bajo) -------
  if ($j.PSObject.Properties.Name -contains 'pocketbase_url') {
    $j.pocketbase_url = $urlNueva
  } else {
    $j | Add-Member -NotePropertyName pocketbase_url -NotePropertyValue $urlNueva -Force
  }

  # ------- SI EXISTIA la vieja pocketbaseUrl camelCase, tambien la actualizamos -------
  if ($j.PSObject.Properties.Name -contains 'pocketbaseUrl') {
    $j.pocketbaseUrl = $urlNueva
  }

  # Escribir con UTF8 sin BOM
  $out = $j | ConvertTo-Json -Depth 10
  [System.IO.File]::WriteAllText($p, $out, [System.Text.UTF8Encoding]::new($false))
  Write-Host ("  [OK] {0}" -f $p) -ForegroundColor Green
  Write-Host ("       nuevo pocketbase_url = {0}" -f $urlNueva) -ForegroundColor Green
}

# ---- 5. Verificar releyendo ----
Sub "[5] Verificando"
$todoOk = $true
foreach ($p in $existentes) {
  try {
    $j = Get-Content $p -Raw | ConvertFrom-Json
    if ($j.pocketbase_url -eq $urlNueva) {
      Write-Host ("  [OK] {0}  =>  pocketbase_url={1}" -f $p, $j.pocketbase_url) -ForegroundColor Green
    } else {
      Write-Host ("  [FAIL] {0}  =>  '{1}' (esperaba '{2}')" -f $p, $j.pocketbase_url, $urlNueva) -ForegroundColor Red
      $todoOk = $false
    }
  } catch {
    Write-Host ("  [FAIL parseo] {0}: {1}" -f $p, $_.Exception.Message) -ForegroundColor Red
    $todoOk = $false
  }
}

# ---- 6. Refrescar Chrome ----
Sub "[6] Refrescar Chrome (kiosk) para tomar el cambio"
$chr = Get-Process -Name chrome,msedge -ErrorAction SilentlyContinue
if ($chr) {
  Write-Host ("  Hay {0} procesos de Chrome/Edge corriendo." -f $chr.Count)
  $r = Read-Host "  Matar Chrome ahora para forzar recarga? (S/N, default S)"
  if ($r -notmatch '^[nN]') {
    $chr | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "  [OK] Chrome cerrado." -ForegroundColor Green
    Write-Host "  Ahora doble click en 'ARRANCAR SISTEMA.bat' o el icono del" -ForegroundColor Gray
    Write-Host "  escritorio para relanzar todo con la config corregida." -ForegroundColor Gray
  } else {
    Write-Host "  Ok. Recarga manual con Ctrl+F5 en el navegador." -ForegroundColor Gray
  }
} else {
  Write-Host "  Chrome no esta corriendo. Al arrancarlo tomara la nueva config." -ForegroundColor Gray
}

Write-Host ""
Line
if ($todoOk) {
  Write-Host "  LISTO - config.json reparado en $env:COMPUTERNAME" -ForegroundColor Green
} else {
  Write-Host "  ATENCION - Alguna verificacion fallo. Revisa arriba." -ForegroundColor Yellow
}
if ($rol -eq 'monitor') {
  Write-Host "  Ahora corre REPARAR_CONFIG.bat tambien en la Terminal-A." -ForegroundColor Cyan
} else {
  Write-Host "  Test final: hace un pedido y confirma que aparece en el Monitor en <3s." -ForegroundColor Cyan
}
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
