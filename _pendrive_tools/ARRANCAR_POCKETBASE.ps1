# =============================================================
# ARRANCAR_POCKETBASE.ps1
# Arranca el PocketBase de la instalacion oficial con el pb_data
# ubicado en C:\ProgramData\FCEA-Sistema-Llaves\pb_data.
#
# El objetivo puntual de este script es reiniciar PB despues de
# matarlo con CAZAR_POCKETBASE_ZOMBIE, para que SQLite haga el
# checkpoint del WAL y las escrituras vuelvan a funcionar.
#
# NO INSTALA NADA. NO SIEMBRA SEMILLAS. Solo lanza pocketbase.exe.
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'ARRANCAR POCKETBASE - Sistema FCEA'

$PB_EXE       = 'C:\sistema-llaves-fcea\pocketbase\pocketbase.exe'
$PB_DATA      = 'C:\ProgramData\FCEA-Sistema-Llaves\pb_data'
$PB_MIGS      = 'C:\sistema-llaves-fcea\pocketbase\pb_migrations'
$PB_URL       = 'http://127.0.0.1:8090'

function Line($c='='){ Write-Host ($c * 62) -ForegroundColor Yellow }
function Header($t) { Line; Write-Host "  $t" -ForegroundColor Yellow; Line }

Header "ARRANCAR POCKETBASE - $env:COMPUTERNAME"

# 1) Verificar prerequisitos
Write-Host ""
Write-Host "[1] Verificando prerequisitos..." -ForegroundColor Cyan

if (-not (Test-Path $PB_EXE)) {
    Write-Host ("  [ERROR] No existe {0}" -f $PB_EXE) -ForegroundColor Red
    Write-Host "  Reinstalar el sistema con el pendrive de instalacion." -ForegroundColor Yellow
    Read-Host "Presiona ENTER"
    exit 1
}
Write-Host ("  [OK] Ejecutable: {0}" -f $PB_EXE) -ForegroundColor Green

if (-not (Test-Path $PB_DATA)) {
    Write-Host ("  [ERROR] No existe {0}" -f $PB_DATA) -ForegroundColor Red
    Read-Host "Presiona ENTER"
    exit 1
}
Write-Host ("  [OK] pb_data: {0}" -f $PB_DATA) -ForegroundColor Green

# 2) Verificar que NO haya otro PB corriendo
Write-Host ""
Write-Host "[2] Verificando que no haya PocketBase corriendo ya..." -ForegroundColor Cyan
$vivos = Get-Process -Name pocketbase -ErrorAction SilentlyContinue
if ($vivos) {
    Write-Host ("  [WARN] Hay {0} proceso(s) pocketbase.exe corriendo:" -f @($vivos).Count) -ForegroundColor Yellow
    foreach ($v in $vivos) {
        Write-Host ("    PID={0}" -f $v.Id)
    }
    Write-Host ""
    $r = Read-Host "  Matar antes de arrancar? (S/N)"
    if ($r -match '^[sSyY]') {
        Get-Process -Name pocketbase -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $q = Get-Process -Name pocketbase -ErrorAction SilentlyContinue
        if ($q) {
            taskkill /F /IM pocketbase.exe 2>&1 | Out-Null
            Start-Sleep -Seconds 2
        }
        Write-Host "  [OK] PocketBase(s) anterior(es) muerto(s)." -ForegroundColor Green
    } else {
        Write-Host "  [CANCEL] Nada por hacer. Salir sin cambios." -ForegroundColor Yellow
        Read-Host "Presiona ENTER"
        exit 0
    }
}
Write-Host "  [OK] No hay procesos pocketbase.exe corriendo." -ForegroundColor Green

# 3) Backup preventivo de data.db (por las dudas)
Write-Host ""
Write-Host "[3] Backup preventivo del data.db actual..." -ForegroundColor Cyan
$dbFile = Join-Path $PB_DATA 'data.db'
if (Test-Path $dbFile) {
    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    $bak = Join-Path $PB_DATA ("data.db.bak_$ts")
    try {
        Copy-Item $dbFile $bak -ErrorAction Stop
        Write-Host ("  [OK] Backup: {0}" -f $bak) -ForegroundColor Green
    } catch {
        Write-Host ("  [WARN] No pude backupear: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "  Sigo igual." -ForegroundColor Yellow
    }
}

# 4) Arrancar PocketBase
Write-Host ""
Write-Host "[4] Arrancando PocketBase..." -ForegroundColor Cyan
# Igual al CMD que estaba corriendo antes:
#   pocketbase.exe serve --http=0.0.0.0:8090 --dir="..." --migrationsDir=pb_migrations
$args = @(
    'serve',
    '--http=0.0.0.0:8090',
    "--dir=$PB_DATA"
)
if (Test-Path $PB_MIGS) {
    $args += "--migrationsDir=$PB_MIGS"
}

# Lanzar en ventana propia para que quede vivo
$startArgs = @{
    FilePath         = $PB_EXE
    ArgumentList     = $args
    WorkingDirectory = (Split-Path $PB_EXE -Parent)
    WindowStyle      = 'Normal'
}
try {
    $proc = Start-Process @startArgs -PassThru
    Write-Host ("  [OK] Lanzado con PID={0}" -f $proc.Id) -ForegroundColor Green
    Write-Host ("  Args: {0}" -f ($args -join ' ')) -ForegroundColor Gray
} catch {
    Write-Host ("  [ERROR] {0}" -f $_.Exception.Message) -ForegroundColor Red
    Read-Host "Presiona ENTER"
    exit 1
}

# 5) Esperar a que /api/health responda
Write-Host ""
Write-Host "[5] Esperando que responda /api/health..." -ForegroundColor Cyan
$maxTries = 20
$ok = $false
for ($i = 1; $i -le $maxTries; $i++) {
    Start-Sleep -Seconds 1
    try {
        $r = Invoke-WebRequest -Uri "$PB_URL/api/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
        if ($r.StatusCode -eq 200) {
            Write-Host ("  [OK] /api/health = 200 tras {0} seg" -f $i) -ForegroundColor Green
            $ok = $true
            break
        }
    } catch {
        # aun no responde, seguir esperando
        Write-Host ("  . intento {0}/{1}..." -f $i, $maxTries) -ForegroundColor DarkGray
    }
}
if (-not $ok) {
    Write-Host "  [FAIL] PocketBase no respondio despues de 20 seg." -ForegroundColor Red
    Read-Host "Presiona ENTER"
    exit 1
}

# 6) Verificar checkpoint: data.db deberia tener fecha reciente ahora
Write-Host ""
Write-Host "[6] Verificando que data.db se haya actualizado..." -ForegroundColor Cyan
if (Test-Path $dbFile) {
    $it = Get-Item $dbFile
    $ageMin = ((Get-Date) - $it.LastWriteTime).TotalMinutes
    if ($ageMin -lt 5) {
        Write-Host ("  [OK] data.db mod: {0} (hace {1:N1} min)" -f $it.LastWriteTime, $ageMin) -ForegroundColor Green
        Write-Host "  El WAL fue aplicado al data.db - deberia poder escribir ya." -ForegroundColor Green
    } else {
        Write-Host ("  [WARN] data.db mod: {0} (hace {1:N1} min)" -f $it.LastWriteTime, $ageMin) -ForegroundColor Yellow
        Write-Host "  Todavia no se hizo checkpoint. Puede que necesite una escritura." -ForegroundColor Yellow
    }
}

# 7) Test rapido de escritura
Write-Host ""
Write-Host "[7] Test de CREATE en 'lugares'..." -ForegroundColor Cyan
$ADMIN_EMAIL = 'vigilancia@llaves.local'
$ADMIN_PASS  = 'vigilanciamvp2026'
$authBody = @{ identity = $ADMIN_EMAIL; password = $ADMIN_PASS } | ConvertTo-Json
$token = $null
foreach ($ep in @("$PB_URL/api/collections/_superusers/auth-with-password","$PB_URL/api/admins/auth-with-password")) {
    try {
        $r = Invoke-RestMethod -Uri $ep -Method Post -Body $authBody -ContentType 'application/json' -TimeoutSec 5
        if ($r.token) { $token = $r.token; break }
    } catch {}
}
if ($token) {
    $stamp = Get-Date -Format 'HHmmss'
    $hdr = @{ Authorization = $token; 'Content-Type' = 'application/json' }
    $bodyLug = @{ nombre = "__TEST_ARRANQUE_$stamp" } | ConvertTo-Json
    try {
        $resp = Invoke-WebRequest -Uri "$PB_URL/api/collections/lugares/records" -Method Post -Body $bodyLug -Headers $hdr -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        $j = $resp.Content | ConvertFrom-Json
        Write-Host ("  [OK] CREATE en 'lugares' funciono. id={0}" -f $j.id) -ForegroundColor Green
        # Rollback
        try {
            Invoke-RestMethod -Uri "$PB_URL/api/collections/lugares/records/$($j.id)" -Method Delete -Headers @{Authorization=$token} -TimeoutSec 5 | Out-Null
            Write-Host "  [OK] Registro de prueba borrado." -ForegroundColor Gray
        } catch {}
        Write-Host ""
        Line
        Write-Host "  EXITO - PocketBase esta escribiendo bien." -ForegroundColor Green
        Write-Host "  Ir al Monitor y probar 'Agregar Vigilante'." -ForegroundColor Green
        Line
    } catch {
        $s = $null; $b = $null
        try { $s = $_.Exception.Response.StatusCode.Value__ } catch {}
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $b = $_.ErrorDetails.Message }
        Write-Host ("  [FAIL] HTTP {0}" -f $s) -ForegroundColor Red
        if ($b) { Write-Host ("  resp: {0}" -f $b) -ForegroundColor Red }
        Write-Host ""
        Line
        Write-Host "  PocketBase arranco pero SIGUE sin poder escribir." -ForegroundColor Red
        Write-Host "  Plan B: recuperacion SQLite con sqlite3 .recover" -ForegroundColor Yellow
        Line
    }
} else {
    Write-Host "  [ERROR] No pude autenticar admin. Ver si arranco bien PocketBase." -ForegroundColor Red
}

Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
