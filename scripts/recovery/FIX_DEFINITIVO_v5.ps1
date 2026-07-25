# =============================================================================
# FIX_DEFINITIVO_v5.ps1
# -----------------------------------------------------------------------------
# Diagnostico correcto (2026-07-25, tras 4 intentos fallidos):
#
#   El pb_data NO esta read-only en disco. Los archivos tienen atributos
#   normales y los ACL son OK.
#
#   El problema es un pocketbase.exe ZOMBI (PID 13112 en la ultima
#   observacion) lanzado por la tarea programada "FCEA-Sistema-Llaves-AutoStart"
#   probablemente con "Ejecutar con privilegios elevados". Ese proceso tiene
#   handle exclusivo sobre C:\ProgramData\FCEA-Sistema-Llaves\pb_data\data.db.
#
#   Cuando cualquier otro pocketbase.exe se lanza desde la sesion NO elevada
#   del usuario REP, Windows le abre data.db en modo READ-ONLY (porque el
#   zombi ya tiene el lock exclusivo). SQLite reporta "attempt to write a
#   readonly database (8)" en cualquier intento de escribir -> migraciones
#   fallan, admin update falla, crear vigilante desde el frontend falla.
#
#   Ademas el startup del usuario tiene INICIAR_SISTEMA_AHORA.bat que puede
#   estar arrancando OTRO pocketbase.exe en paralelo.
#
# Este script (requiere ELEVACION):
#   1. Detiene la tarea programada FCEA-Sistema-Llaves-AutoStart para que
#      no relance pocketbase.exe mientras trabajamos.
#   2. Mata TODOS los pocketbase.exe (con permisos de admin puede matar el
#      zombi de PID 13112).
#   3. Verifica que el puerto 8090 esta libre.
#   4. Copia la migracion 1779500000_force_open_rules.js a la carpeta de
#      migraciones de la instalacion productiva.
#   5. Arranca UNA sola instancia de pocketbase.exe -> aplica la migracion
#      -> reglas quedan abiertas.
#   6. Verifica GET /api/collections/vigilante/records -> debe devolver 200.
#   7. Rehabilita la tarea programada.
#
# USO:
#   - Click derecho > "Ejecutar con PowerShell"  -> NO sirve, no eleva.
#   - Metodo correcto: doble clic en FIX_DEFINITIVO_v5_LANZAR.bat que esta
#     al lado. Ese .bat pide UAC y luego llama a este .ps1 ya elevado.
# =============================================================================

# -- Sanity check: soy admin? ------------------------------------------------
$soyAdmin = ([Security.Principal.WindowsPrincipal] `
             [Security.Principal.WindowsIdentity]::GetCurrent()
            ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $soyAdmin) {
    Write-Host ""
    Write-Host "ERROR: este script requiere permisos de administrador." -ForegroundColor Red
    Write-Host "       Cerra esta ventana y usa el .bat lanzador que pide UAC." -ForegroundColor Red
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host ""
Write-Host "============================================================================"
Write-Host " FIX DEFINITIVO v5 - Sistema Llaves FCEA" -ForegroundColor Cyan
Write-Host " (ejecutando con privilegios de administrador)"
Write-Host "============================================================================"
Write-Host ""

$installDir     = "C:\sistema-llaves-fcea"
$pbExe          = "$installDir\pocketbase\pocketbase.exe"
$startBat       = "$installDir\pocketbase\start-server.bat"
$migrationsDir  = "$installDir\pocketbase\pb_migrations"
$migrationFile  = "1779500000_force_open_rules.js"
$scriptDir      = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceMigracion = Join-Path $scriptDir $migrationFile
$scheduledTaskName = "FCEA-Sistema-Llaves-AutoStart"

# -- Paso 1: deshabilitar temporalmente la tarea programada ------------------
Write-Host "== Paso 1: deshabilitar tarea programada '$scheduledTaskName' =="
try {
    $task = Get-ScheduledTask -TaskName $scheduledTaskName -ErrorAction Stop
    Disable-ScheduledTask -TaskName $scheduledTaskName -ErrorAction Stop | Out-Null
    Write-Host "   OK - tarea deshabilitada temporalmente." -ForegroundColor Green
} catch {
    Write-Host "   Nota: la tarea no existe o ya estaba deshabilitada. Continuamos." -ForegroundColor Yellow
}

# -- Paso 2: matar TODOS los pocketbase.exe (con privilegios elevados si) ----
Write-Host ""
Write-Host "== Paso 2: matar TODAS las instancias de pocketbase.exe =="
$procesos = Get-Process -Name pocketbase -ErrorAction SilentlyContinue
if ($procesos) {
    foreach ($p in $procesos) {
        Write-Host "   Matando PID $($p.Id)..." -NoNewline
        try {
            Stop-Process -Id $p.Id -Force -ErrorAction Stop
            Write-Host " OK" -ForegroundColor Green
        } catch {
            Write-Host " FALLO: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   No habia procesos pocketbase.exe corriendo."
}

Start-Sleep -Seconds 3

# Verificacion: quedaron procesos?
$restantes = Get-Process -Name pocketbase -ErrorAction SilentlyContinue
if ($restantes) {
    Write-Host "   ERROR CRITICO: quedaron pocketbase.exe corriendo:" -ForegroundColor Red
    $restantes | ForEach-Object { Write-Host "     PID $($_.Id)" }
    Write-Host "   No podemos continuar. Reinicia Windows y volve a correr este script." -ForegroundColor Red
    Read-Host "Presiona Enter"
    exit 1
}
Write-Host "   OK - todos los pocketbase.exe fueron eliminados." -ForegroundColor Green

# -- Paso 3: verificar puerto 8090 libre -------------------------------------
Write-Host ""
Write-Host "== Paso 3: verificar puerto 8090 libre =="
$portTest = Get-NetTCPConnection -LocalPort 8090 -State Listen -ErrorAction SilentlyContinue
if ($portTest) {
    Write-Host "   ERROR: puerto 8090 sigue ocupado por PID $($portTest.OwningProcess)." -ForegroundColor Red
    Write-Host "   Cerra ese proceso manualmente y reintenta." -ForegroundColor Red
    Read-Host "Presiona Enter"
    exit 1
}
Write-Host "   OK - puerto 8090 libre." -ForegroundColor Green

# -- Paso 4: verificar que existe la instalacion productiva ------------------
Write-Host ""
Write-Host "== Paso 4: verificar instalacion productiva =="
if (-not (Test-Path $pbExe)) {
    Write-Host "   ERROR: no existe $pbExe" -ForegroundColor Red
    Read-Host "Presiona Enter"
    exit 1
}
if (-not (Test-Path $migrationsDir)) {
    Write-Host "   ERROR: no existe $migrationsDir" -ForegroundColor Red
    Read-Host "Presiona Enter"
    exit 1
}
Write-Host "   OK - instalacion productiva presente."

# -- Paso 5: copiar migracion (idempotente) ----------------------------------
Write-Host ""
Write-Host "== Paso 5: copiar migracion 1779500000_force_open_rules.js =="
if (-not (Test-Path $sourceMigracion)) {
    Write-Host "   ERROR: no se encontro la migracion en $sourceMigracion" -ForegroundColor Red
    Write-Host "   Debe estar al lado de este .ps1 en el pendrive." -ForegroundColor Red
    Read-Host "Presiona Enter"
    exit 1
}
Copy-Item -Force $sourceMigracion (Join-Path $migrationsDir $migrationFile)
Write-Host "   OK - migracion copiada a $migrationsDir\$migrationFile" -ForegroundColor Green

# -- Paso 6: arrancar PocketBase (aplica la migracion en el startup) ---------
Write-Host ""
Write-Host "== Paso 6: arrancar PocketBase =="
Start-Process -FilePath $startBat -WorkingDirectory (Split-Path -Parent $startBat) -WindowStyle Normal
Write-Host "   OK - PocketBase lanzado en ventana nueva."
Write-Host "   Esperando 8 segundos a que el server escuche..."
Start-Sleep -Seconds 8

# -- Paso 7: verificar que responde ------------------------------------------
Write-Host ""
Write-Host "== Paso 7: verificar API =="
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8090/api/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "   OK - /api/health respondio HTTP $($r.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: /api/health no responde: $($_.Exception.Message)" -ForegroundColor Red
}

# -- Paso 8: verificar que las reglas quedaron abiertas ----------------------
Write-Host ""
Write-Host "== Paso 8: verificar que la migracion aplico (GET /vigilante/records) =="
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8090/api/collections/vigilante/records" `
                           -UseBasicParsing -TimeoutSec 5
    if ($r.StatusCode -eq 200) {
        Write-Host "   EXITO - HTTP 200. Las reglas estan abiertas. BUG ARREGLADO." -ForegroundColor Green
    } else {
        Write-Host "   Respuesta inesperada: HTTP $($r.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    $sc = $_.Exception.Response.StatusCode.value__
    if ($sc) {
        Write-Host "   FALLO - HTTP $sc. La migracion no se aplico correctamente." -ForegroundColor Red
        Write-Host "   Ver la ventana de PocketBase para el mensaje de error del arranque." -ForegroundColor Red
    } else {
        Write-Host "   FALLO - No hubo respuesta: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# -- Paso 9: rehabilitar tarea programada ------------------------------------
Write-Host ""
Write-Host "== Paso 9: rehabilitar tarea programada =="
try {
    Enable-ScheduledTask -TaskName $scheduledTaskName -ErrorAction Stop | Out-Null
    Write-Host "   OK - tarea rehabilitada. En el proximo reinicio arrancara normalmente." -ForegroundColor Green
} catch {
    Write-Host "   Nota: no se pudo rehabilitar. Revisar manualmente en el Programador de tareas." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================================================"
Write-Host " LISTO. Proximos pasos:" -ForegroundColor Cyan
Write-Host "   1) En el navegador del monitor: F5 para recargar."
Write-Host "   2) Abrir 'Gestion de vigilantes' > Agregar vigilante."
Write-Host "   3) Si el Paso 8 dijo 'BUG ARREGLADO', deberia funcionar."
Write-Host "============================================================================"
Write-Host ""
Read-Host "Presiona Enter para cerrar"
