# =============================================================================
#  kill_pocketbase_zombis.ps1
#  -----------------------------------------------------------------------------
#  Mata TODOS los procesos pocketbase.exe, INCLUIDOS los procesos elevados
#  que fueron lanzados por la tarea programada FCEA-Sistema-Llaves-AutoStart
#  y que una sesion de usuario no-admin no puede tocar con "taskkill /F".
#
#  Contexto historico (piloto FCEA sabado 2026-07-25):
#  ---------------------------------------------------
#  El bug de "modal Agregar vigilante devuelve HTTP 400" resulto ser
#  causa->efecto de este otro bug:
#
#    1. La tarea programada FCEA-Sistema-Llaves-AutoStart arranca
#       INICIAR.bat al iniciar sesion con SYSTEM/elevado.
#    2. Ese INICIAR.bat lanza pocketbase.exe -> queda con handles
#       ELEVADOS sobre data.db.
#    3. El operador (usuario sin admin) despues inicia manualmente
#       start-server.bat -> lanza una SEGUNDA instancia de
#       pocketbase.exe, esta con permisos de usuario.
#    4. La segunda instancia no puede escribir data.db porque la
#       primera tiene el lock exclusivo. SQLite responde con
#       "attempt to write a readonly database (8)".
#    5. TODAS las llamadas POST/PATCH del frontend fallan con 400.
#
#  El "taskkill /F /IM pocketbase.exe" que tienen los scripts
#  RECUPERAR e INSTALAR SI mata la instancia del usuario, pero NO
#  puede matar la instancia elevada. El sintoma es sutil porque
#  taskkill devuelve exit 0 igual, entonces los scripts creen que
#  todo esta bien y siguen adelante.
#
#  Este helper corrige eso:
#    - Deshabilita temporalmente la tarea programada para que no
#      relance PocketBase mientras estamos limpiando.
#    - Enumera TODOS los pocketbase.exe usando WMI (Get-CimInstance
#      Win32_Process) que si ve procesos de otras sesiones.
#    - Los mata con Stop-Process -Force. Al correr elevado (los
#      launchers ya pidieron UAC), tenemos permisos.
#    - Verifica que ya no queden y da error si algo sigue vivo.
#    - Espera 2 segundos para que SQLite suelte el lock de data.db.
#    - Vuelve a HABILITAR la tarea programada (asi los reinicios
#      futuros funcionan).
#
#  Idempotente: si no hay pocketbase corriendo o la tarea no existe,
#  no falla, simplemente informa y sigue.
#
#  Uso desde .bat:
#    powershell -NoProfile -ExecutionPolicy Bypass ^
#      -File "C:\path\to\kill_pocketbase_zombis.ps1"
#
#  Codigos de salida:
#    0 = todo OK, no hay pocketbase corriendo
#    1 = habia procesos pero no se pudieron matar
# =============================================================================

$ErrorActionPreference = 'Continue'

Write-Host ""
Write-Host "  [kill_pocketbase_zombis] Iniciando limpieza..." -ForegroundColor Cyan

# --- 1. Deshabilitar la tarea programada para que no relance PocketBase ---
$tareaNombre = 'FCEA-Sistema-Llaves-AutoStart'
try {
    $tarea = Get-ScheduledTask -TaskName $tareaNombre -ErrorAction Stop
    if ($tarea.State -ne 'Disabled') {
        Disable-ScheduledTask -TaskName $tareaNombre -ErrorAction Stop | Out-Null
        Write-Host "  [OK] Tarea programada '$tareaNombre' deshabilitada temporalmente."
        $tareaFueDeshabilitada = $true
    } else {
        Write-Host "  [i] Tarea '$tareaNombre' ya estaba deshabilitada."
        $tareaFueDeshabilitada = $false
    }
} catch {
    # La tarea no existe (primera instalacion) - es normal, seguimos
    Write-Host "  [i] Tarea '$tareaNombre' no existe (probable primera instalacion)."
    $tareaFueDeshabilitada = $false
}

# --- 2. Enumerar TODOS los pocketbase.exe (incluye elevados de otras sesiones) ---
$procesos = @(Get-CimInstance Win32_Process -Filter "Name='pocketbase.exe'" -ErrorAction SilentlyContinue)

if ($procesos.Count -eq 0) {
    Write-Host "  [OK] No hay procesos pocketbase.exe corriendo. Nada que matar." -ForegroundColor Green
} else {
    Write-Host ("  [!] Encontrados {0} proceso(s) pocketbase.exe:" -f $procesos.Count) -ForegroundColor Yellow
    foreach ($p in $procesos) {
        Write-Host ("      PID={0}  Path={1}" -f $p.ProcessId, $p.ExecutablePath)
    }

    # --- 3. Matarlos uno por uno ---
    foreach ($p in $procesos) {
        try {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop
            Write-Host ("  [OK] PID {0} terminado." -f $p.ProcessId) -ForegroundColor Green
        } catch {
            Write-Host ("  [ERROR] No se pudo matar PID {0}: {1}" -f $p.ProcessId, $_.Exception.Message) -ForegroundColor Red
        }
    }

    # --- 4. Verificar que no quede ninguno ---
    Start-Sleep -Milliseconds 500
    $sobrevivientes = @(Get-CimInstance Win32_Process -Filter "Name='pocketbase.exe'" -ErrorAction SilentlyContinue)
    if ($sobrevivientes.Count -gt 0) {
        Write-Host ""
        Write-Host ("  [ERROR] Todavia hay {0} proceso(s) pocketbase.exe vivo(s). Abortando." -f $sobrevivientes.Count) -ForegroundColor Red
        Write-Host "          Reintente reiniciando la PC y ejecutando de nuevo el launcher."

        # Intentar rehabilitar la tarea antes de salir con error, para no
        # dejar la PC en un estado peor del que estaba.
        if ($tareaFueDeshabilitada) {
            try {
                Enable-ScheduledTask -TaskName $tareaNombre -ErrorAction Stop | Out-Null
                Write-Host "  [i] Tarea '$tareaNombre' rehabilitada antes de salir con error."
            } catch { }
        }
        exit 1
    }
}

# --- 5. Esperar a que SQLite suelte el lock de data.db ---
# Sin esto, el proximo pocketbase.exe que arranque puede seguir viendo
# data.db-shm/wal en estado sucio y volver a abrirlo readonly.
Write-Host "  [i] Esperando 2 segundos para que se liberen locks de SQLite..."
Start-Sleep -Seconds 2

# --- 6. Rehabilitar la tarea programada ---
# La rehabilitamos SIEMPRE al final (excepto si ya venia deshabilitada
# por el usuario, en cuyo caso respetamos esa decision).
if ($tareaFueDeshabilitada) {
    try {
        Enable-ScheduledTask -TaskName $tareaNombre -ErrorAction Stop | Out-Null
        Write-Host "  [OK] Tarea programada '$tareaNombre' rehabilitada." -ForegroundColor Green
    } catch {
        Write-Host ("  [WARN] No se pudo rehabilitar la tarea: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "         El sistema funciona igual, pero no arrancara automaticamente al login."
        Write-Host "         Para rehabilitar manualmente:"
        Write-Host "           Enable-ScheduledTask -TaskName '$tareaNombre'"
    }
}

Write-Host "  [kill_pocketbase_zombis] Limpieza completada." -ForegroundColor Cyan
Write-Host ""
exit 0
