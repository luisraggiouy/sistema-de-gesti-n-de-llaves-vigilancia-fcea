# =============================================================
# MATAR_POCKETBASE_ZOMBIE.ps1
# SOLO EJECUTAR EN UNA TERMINAL, NUNCA EN EL MONITOR.
# Mata pocketbase.exe local, deshabilita tareas programadas que
# lo relancen, y opcionalmente borra la carpeta pb_data local.
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'MATAR POCKETBASE ZOMBIE - Sistema FCEA'

function Line($c='='){ Write-Host ($c * 62) -ForegroundColor Yellow }
function H($t)  { Line; Write-Host "  $t" -ForegroundColor Yellow; Line }
function Sub($t){ Write-Host ""; Write-Host "--- $t ---" -ForegroundColor Cyan }

H "MATAR POCKETBASE ZOMBIE - $env:COMPUTERNAME"

# ---- Salvaguarda: no correr en el Monitor ----
Sub "[0] Salvaguarda: no correr en el Monitor"
$ips = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
         Where-Object { $_.IPAddress -notlike '127.*' } |
         Select-Object -ExpandProperty IPAddress)
$soyMonitor = $ips -contains '192.168.100.10'
if ($soyMonitor -or $env:COMPUTERNAME -match '^FCEA-MON') {
  Line
  Write-Host "  [PELIGRO] Esta PC parece ser el MONITOR oficial (IP 192.168.100.10)" -ForegroundColor Red
  Write-Host "  ESTE SCRIPT MATARIA EL POCKETBASE DEL MONITOR - NO LO EJECUTES." -ForegroundColor Red
  Write-Host ""
  $c = Read-Host "  Escribe SI-LO-SE-Y-QUIERO-CONTINUAR para forzar (o ENTER para abortar)"
  if ($c -ne 'SI-LO-SE-Y-QUIERO-CONTINUAR') {
    Write-Host "  Abortado. Cerrando." -ForegroundColor Green
    Write-Host ""; Write-Host "Presiona ENTER..." -ForegroundColor Gray; [void][System.Console]::ReadLine(); exit
  }
} else {
  Write-Host "  OK: esta PC no parece ser el Monitor." -ForegroundColor Green
}

# ---- 1. Matar procesos pocketbase.exe ----
Sub "[1] Matando pocketbase.exe locales"
$procs = Get-Process -Name pocketbase -ErrorAction SilentlyContinue
if (-not $procs) {
  Write-Host "  No hay pocketbase.exe corriendo." -ForegroundColor Green
} else {
  foreach ($p in $procs) {
    $ruta = try { $p.Path } catch { '(sin ruta)' }
    Write-Host ("  Matando PID={0}  exe={1}" -f $p.Id, $ruta)
    try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; Write-Host "    [OK] terminado" -ForegroundColor Green }
    catch { Write-Host "    [ERROR] $($_.Exception.Message)" -ForegroundColor Red }
  }
  Start-Sleep -Seconds 1
}

# ---- 2. Matar ventanas de CMD que lo relancen ----
Sub "[2] Cerrando ventanas CMD con titulo 'PocketBase'"
Get-Process -Name cmd -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -match 'PocketBase|start-server' } | ForEach-Object {
  Write-Host ("  Cerrando cmd PID={0} titulo='{1}'" -f $_.Id, $_.MainWindowTitle)
  Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

# ---- 3. Deshabilitar tareas programadas que relancen pocketbase ----
Sub "[3] Deshabilitando tareas programadas con 'pocketbase' o 'FCEA'"
$tareas = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
  $_.TaskName -match 'pocketbase|FCEA|start-server' -or
  ($_.Actions | ForEach-Object { $_.Execute }) -match 'pocketbase\.exe'
}
if (-not $tareas) {
  Write-Host "  No hay tareas programadas relacionadas." -ForegroundColor Green
} else {
  foreach ($t in $tareas) {
    Write-Host ("  Deshabilitando tarea: {0}\{1}" -f $t.TaskPath, $t.TaskName)
    try { Disable-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath | Out-Null; Write-Host "    [OK]" -ForegroundColor Green }
    catch { Write-Host "    [ERROR] $($_.Exception.Message)" -ForegroundColor Red }
  }
}

# ---- 4. Verificar puerto 8090 ----
Sub "[4] Verificando que puerto 8090 quedo libre"
Start-Sleep -Seconds 1
$conns = Get-NetTCPConnection -LocalPort 8090 -State Listen -ErrorAction SilentlyContinue
if ($conns) {
  Write-Host "  [!] Todavia hay algo escuchando en 8090:" -ForegroundColor Red
  foreach ($c in $conns) {
    $p = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
    Write-Host ("     PID={0}  proc={1}" -f $c.OwningProcess, $p.ProcessName) -ForegroundColor Red
  }
} else {
  Write-Host "  [OK] Puerto 8090 libre en esta PC." -ForegroundColor Green
}

# ---- 5. (Opcional) Borrar carpeta pocketbase local ----
Sub "[5] Carpeta local C:\sistema-llaves-fcea\pocketbase"
$carpeta = 'C:\sistema-llaves-fcea\pocketbase'
if (Test-Path $carpeta) {
  Write-Host "  Existe: $carpeta"
  $tam = try {
    (Get-ChildItem $carpeta -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
  } catch { 0 }
  Write-Host ("  Tamano: {0:N1} MB" -f ($tam/1MB))
  Write-Host ""
  Write-Host "  Se recomienda RENOMBRARLA (no borrarla) para que jamas se relance." -ForegroundColor Cyan
  $r = Read-Host "  Renombrar a pocketbase.zombie? (S/N)"
  if ($r -match '^[sS]') {
    $destino = "$carpeta.zombie.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    try {
      Rename-Item -Path $carpeta -NewName (Split-Path -Leaf $destino) -ErrorAction Stop
      Write-Host "  [OK] Renombrado a: $destino" -ForegroundColor Green
    } catch {
      Write-Host "  [ERROR] No se pudo renombrar: $($_.Exception.Message)" -ForegroundColor Red
      Write-Host "  (Probablemente el pocketbase.exe todavia tiene la carpeta abierta. Reintenta tras 5s.)" -ForegroundColor Yellow
    }
  } else {
    Write-Host "  Dejando la carpeta como esta." -ForegroundColor Gray
  }
} else {
  Write-Host "  No existe. Nada que renombrar." -ForegroundColor Green
}

# ---- 6. Recomendacion ----
Sub "[6] Que hacer ahora"
Write-Host "  1) En esta Terminal: ejecutar DIAGNOSTICAR_RED.bat de nuevo"
Write-Host "     para confirmar que ya NO hay puerto 8090 escuchando."
Write-Host "  2) Verificar que config.json apunte a 192.168.100.10 (Monitor)."
Write-Host "     Si no, correr APUNTAR_TERMINAL_A_MONITOR.bat."
Write-Host "  3) Hacer un pedido de prueba desde esta Terminal y confirmar"
Write-Host "     que aparece en el Monitor en menos de 3 segundos."

Write-Host ""
Line
Write-Host "  LIMPIEZA COMPLETA" -ForegroundColor Green
Line
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
