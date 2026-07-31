# =============================================================
# ARRANCAR_FRONTEND.ps1   (HERRAMIENTAS_RED - permanente)
#
# Arranca el servidor de FRONTEND en http://127.0.0.1:5173 que
# sirve la carpeta dist\ de la instalacion oficial del sistema
# FCEA (C:\sistema-llaves-fcea\dist).
#
# CONTEXTO / POR QUE EXISTE:
#   En las Terminales (A y B) el frontend se sirve LOCALMENTE en
#   el puerto 5173 (vite preview / serve_dist.cjs), mientras que
#   los DATOS van al PocketBase del Monitor (192.168.100.10:8090
#   via pocketbase_url del config.json).
#
#   Si el servidor local 5173 NO esta corriendo, el navegador da
#   ERR_CONNECTION_REFUSED en 127.0.0.1:5173, y el lanzador
#   (lanzar_navegador.ps1, "defensa v2.8") redirige el kiosko al
#   8090 del Monitor -> que es solo-API -> devuelve 404.
#   Sintoma tipico: "Terminal no levanta / error 404".
#
# QUE HACE ESTE SCRIPT:
#   1) Diagnostica que piezas hay: dist\index.html, node (portable
#      o en PATH), node_modules\vite, serve_dist.cjs, run_frontend.bat.
#   2) Arranca el frontend con el mejor metodo disponible:
#        a) run_frontend.bat (watchdog interno) DESACOPLADO via WMI
#        b) serve_dist.cjs con node
#        c) vite preview con node
#        d) FALLBACK sin node: mini servidor embebido en PowerShell
#           (HttpListener) con fallback SPA -> index.html.
#   3) Espera a que 5173 responda y reporta.
#   4) Imprime un resumen claro de que FALTA (para decidir si
#      alcanza con arrancar o hay que reinstalar/actualizar).
#
# NO INSTALA NADA. NO TOCA PocketBase. NO borra datos.
# =============================================================
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'ARRANCAR FRONTEND - Sistema FCEA'

$INSTALL   = 'C:\sistema-llaves-fcea'
$DIST      = Join-Path $INSTALL 'dist'
$INDEX     = Join-Path $DIST 'index.html'
$NODE_PORT = Join-Path $INSTALL 'node-portable\node\node.exe'
$VITE      = Join-Path $INSTALL 'node_modules\vite\bin\vite.js'
$SERVE     = Join-Path $INSTALL 'scripts\lib\serve_dist.cjs'
$RUNFRONT  = Join-Path $INSTALL 'scripts\lib\run_frontend.bat'
$DETACH    = Join-Path $INSTALL 'scripts\lib\start_detached.ps1'
$PORT      = 5173

function Line($c='='){ Write-Host ($c * 62) -ForegroundColor Yellow }
function Header($t) { Line; Write-Host "  $t" -ForegroundColor Yellow; Line }
function Sub($t) { Write-Host ""; Write-Host "--- $t ---" -ForegroundColor Cyan }

function Test-Puerto5173 {
    try {
        $tcp = New-Object Net.Sockets.TcpClient
        $ar  = $tcp.BeginConnect('127.0.0.1', $PORT, $null, $null)
        $ok  = $ar.AsyncWaitHandle.WaitOne(600)
        if ($ok) { $tcp.EndConnect($ar); $tcp.Close(); return $true }
        $tcp.Close(); return $false
    } catch { return $false }
}

Header "ARRANCAR FRONTEND (5173) - $env:COMPUTERNAME"

# ---------------------------------------------------------------
# 1) DIAGNOSTICO de piezas
# ---------------------------------------------------------------
Sub "[1] Diagnostico de piezas de la instalacion"

$distOk    = Test-Path $INDEX
$nodePortOk= Test-Path $NODE_PORT
$nodePathOk = $false
try { if (Get-Command node -ErrorAction SilentlyContinue) { $nodePathOk = $true } } catch {}
$viteOk    = Test-Path $VITE
$serveOk   = Test-Path $SERVE
$runFrontOk= Test-Path $RUNFRONT
$detachOk  = Test-Path $DETACH

function Estado($ok){ if($ok){'[OK]  '}else{'[FALTA]'} }
function Col($ok){ if($ok){'Green'}else{'Red'} }

Write-Host ("  {0} dist\index.html          {1}" -f (Estado $distOk), $INDEX)     -ForegroundColor (Col $distOk)
Write-Host ("  {0} node-portable            {1}" -f (Estado $nodePortOk), $NODE_PORT) -ForegroundColor (Col $nodePortOk)
Write-Host ("  {0} node en PATH             {1}" -f (Estado $nodePathOk), 'node.exe') -ForegroundColor (Col $nodePathOk)
Write-Host ("  {0} node_modules\vite        {1}" -f (Estado $viteOk), $VITE)       -ForegroundColor (Col $viteOk)
Write-Host ("  {0} serve_dist.cjs           {1}" -f (Estado $serveOk), $SERVE)     -ForegroundColor (Col $serveOk)
Write-Host ("  {0} run_frontend.bat         {1}" -f (Estado $runFrontOk), $RUNFRONT) -ForegroundColor (Col $runFrontOk)
Write-Host ("  {0} start_detached.ps1       {1}" -f (Estado $detachOk), $DETACH)   -ForegroundColor (Col $detachOk)

$hayNode = $nodePortOk -or $nodePathOk

if (-not $distOk) {
    Write-Host ""
    Write-Host "  [ERROR CRITICO] No existe dist\index.html." -ForegroundColor Red
    Write-Host "  Sin el frontend compilado no hay nada que servir." -ForegroundColor Red
    Write-Host "  => Hay que REINSTALAR / ACTUALIZAR esta Terminal con el pendrive." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine()
    exit 1
}

# ---------------------------------------------------------------
# 2) Ya esta corriendo?
# ---------------------------------------------------------------
Sub "[2] Verificando si el puerto 5173 ya esta escuchando"
if (Test-Puerto5173) {
    Write-Host "  [OK] Ya hay algo escuchando en 127.0.0.1:5173." -ForegroundColor Green
    Write-Host "  El frontend ya estaba arriba. Abri el kiosko y probá." -ForegroundColor Green
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
    [void][System.Console]::ReadLine()
    exit 0
}
Write-Host "  [NADA] Nadie escucha en 5173. Voy a arrancarlo." -ForegroundColor Yellow

# Preparar PATH con node-portable si existe (para run_frontend/serve/vite)
if ($nodePortOk) {
    $env:PATH = (Split-Path $NODE_PORT -Parent) + ';' + $env:PATH
}

# ---------------------------------------------------------------
# 3) Arrancar con el mejor metodo disponible
# ---------------------------------------------------------------
Sub "[3] Arrancando servidor de frontend"

$metodo = $null

if ($hayNode -and $runFrontOk -and $detachOk) {
    Write-Host "  Metodo A: run_frontend.bat (watchdog) DESACOPLADO via WMI..." -ForegroundColor Cyan
    try {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $DETACH -CommandLine "cmd /c `"$RUNFRONT`"" -WorkingDirectory $INSTALL
        $metodo = 'run_frontend.bat (detached)'
    } catch {
        Write-Host ("    [WARN] Fallo metodo A: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

if (-not $metodo -and $hayNode -and $serveOk) {
    Write-Host "  Metodo B: node serve_dist.cjs 5173 dist (ventana propia)..." -ForegroundColor Cyan
    try {
        Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', "node `"$SERVE`" 5173 `"$DIST`"" -WorkingDirectory $INSTALL -WindowStyle Minimized
        $metodo = 'serve_dist.cjs'
    } catch {
        Write-Host ("    [WARN] Fallo metodo B: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

if (-not $metodo -and $hayNode -and $viteOk) {
    Write-Host "  Metodo C: node vite.js preview --port 5173 (ventana propia)..." -ForegroundColor Cyan
    try {
        Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', "node `"$VITE`" preview --port 5173 --host --strictPort" -WorkingDirectory $INSTALL -WindowStyle Minimized
        $metodo = 'vite preview'
    } catch {
        Write-Host ("    [WARN] Fallo metodo C: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

# Si arrancamos por node, esperamos que 5173 responda
if ($metodo) {
    Write-Host ("  Lanzado con: {0}. Esperando a que 5173 responda..." -f $metodo) -ForegroundColor Gray
    $ok = $false
    for ($i=1; $i -le 20; $i++) {
        Start-Sleep -Seconds 1
        if (Test-Puerto5173) { $ok = $true; break }
        Write-Host ("  . intento {0}/20..." -f $i) -ForegroundColor DarkGray
    }
    if ($ok) {
        Write-Host ""
        Line
        Write-Host "  EXITO - Frontend arriba en http://127.0.0.1:5173" -ForegroundColor Green
        Write-Host "  Ahora abri el kiosko (icono del escritorio) o Edge en:" -ForegroundColor Green
        Write-Host "     http://127.0.0.1:5173/terminal?id=B" -ForegroundColor Green
        Line
        Write-Host ""
        Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
        [void][System.Console]::ReadLine()
        exit 0
    } else {
        Write-Host "  [WARN] Se lanzo el servidor pero 5173 no respondio en 20s." -ForegroundColor Yellow
        Write-Host "  Reviso el fallback embebido abajo." -ForegroundColor Yellow
        $metodo = $null
    }
}

# ---------------------------------------------------------------
# 4) FALLBACK sin node: mini servidor embebido en PowerShell
# ---------------------------------------------------------------
if (-not $metodo) {
    Sub "[4] Fallback: servidor embebido en PowerShell (sin node)"
    Write-Host "  No se pudo arrancar con node (o node no esta)." -ForegroundColor Yellow
    Write-Host "  Voy a servir dist\ con un mini servidor de PowerShell." -ForegroundColor Yellow
    Write-Host "  IMPORTANTE: este servidor vive mientras esta ventana este ABIERTA." -ForegroundColor Yellow
    Write-Host "  Es para PROBAR que el frontend funciona. Para el arreglo definitivo" -ForegroundColor Yellow
    Write-Host "  hay que restaurar node-portable / reinstalar (ver resumen final)." -ForegroundColor Yellow
    Write-Host ""

    $mime = @{
        '.html'='text/html; charset=utf-8'; '.htm'='text/html; charset=utf-8';
        '.js'='application/javascript; charset=utf-8'; '.mjs'='application/javascript; charset=utf-8';
        '.css'='text/css; charset=utf-8'; '.json'='application/json; charset=utf-8';
        '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.gif'='image/gif';
        '.svg'='image/svg+xml'; '.ico'='image/x-icon'; '.webp'='image/webp';
        '.woff'='font/woff'; '.woff2'='font/woff2'; '.ttf'='font/ttf'; '.otf'='font/otf';
        '.map'='application/json; charset=utf-8'; '.txt'='text/plain; charset=utf-8';
        '.webmanifest'='application/manifest+json'
    }

    try {
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://127.0.0.1:$PORT/")
        $listener.Start()
        Write-Host "  [OK] Servidor embebido escuchando en http://127.0.0.1:$PORT/" -ForegroundColor Green
        Write-Host "  Abri el kiosko o Edge en: http://127.0.0.1:$PORT/terminal?id=B" -ForegroundColor Green
        Write-Host "  (Cerra esta ventana o Ctrl+C para detenerlo.)" -ForegroundColor Gray
        Write-Host ""

        $distFull = (Resolve-Path $DIST).Path
        while ($listener.IsListening) {
            $ctx = $listener.GetContext()
            $req = $ctx.Request
            $res = $ctx.Response
            try {
                $rel = [Uri]::UnescapeDataString($req.Url.AbsolutePath)
                if ($rel -eq '/' -or [string]::IsNullOrWhiteSpace($rel)) { $rel = '/index.html' }
                $fp = Join-Path $distFull ($rel.TrimStart('/') -replace '/','\')
                $full = $null
                try { $full = [System.IO.Path]::GetFullPath($fp) } catch {}
                # Seguridad: no salir de dist. SPA fallback -> index.html
                if ((-not $full) -or (-not $full.StartsWith($distFull)) -or (-not (Test-Path $full -PathType Leaf))) {
                    $full = $INDEX
                }
                $ext = [System.IO.Path]::GetExtension($full).ToLower()
                $ct  = $mime[$ext]; if (-not $ct) { $ct = 'application/octet-stream' }
                $bytes = [System.IO.File]::ReadAllBytes($full)
                $res.ContentType = $ct
                $res.Headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
                $res.ContentLength64 = $bytes.Length
                $res.OutputStream.Write($bytes, 0, $bytes.Length)
            } catch {
                try { $res.StatusCode = 500 } catch {}
            } finally {
                try { $res.OutputStream.Close() } catch {}
            }
        }
    } catch {
        Write-Host ("  [ERROR] No se pudo levantar el servidor embebido: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

# ---------------------------------------------------------------
# 5) RESUMEN / que falta
# ---------------------------------------------------------------
Sub "[5] RESUMEN"
if (-not $hayNode) {
    Write-Host "  * FALTA node (ni node-portable ni node en PATH)." -ForegroundColor Red
    Write-Host "    -> El arranque automatico (run_frontend.bat) NO puede funcionar." -ForegroundColor Red
    Write-Host "    -> Fix definitivo: copiar node-portable\ del pendrive a" -ForegroundColor Yellow
    Write-Host "       C:\sistema-llaves-fcea\node-portable\  (o reinstalar/actualizar)." -ForegroundColor Yellow
}
if (-not $viteOk -and -not $serveOk) {
    Write-Host "  * FALTAN vite y serve_dist.cjs (instalacion incompleta/vieja)." -ForegroundColor Red
    Write-Host "    -> Fix definitivo: reinstalar/actualizar esta Terminal con el pendrive." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Gray
[void][System.Console]::ReadLine()
