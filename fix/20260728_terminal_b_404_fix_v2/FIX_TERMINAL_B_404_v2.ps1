# ============================================================
# FIX: Error 404 Terminal B v2.0 (MEJORADO)
# Fecha: 28/07/2026 15:27
# Problema: {"code":404,"message":"Not Found.","data":{}} en Terminal B
# Mejoras v2: Sincroniza public/ y dist/, mejor deteccion red, mas validaciones
# ============================================================

param(
    [switch]$Test = $false,
    [switch]$Rollback = $false,
    [switch]$Interactive = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " FIX: Error 404 Terminal B v2.0 (MEJORADO)" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$REPO_ROOT = "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
$BACKUP_DIR = "C:\fix_backups\20260728_terminal_b_404_v2"
$PUBLIC_CONFIG = "$REPO_ROOT\public\config.json"
$DIST_CONFIG = "$REPO_ROOT\dist\config.json"

function Get-NetworkConfig {
    Write-Host "[DETECCION] Analizando configuracion de red avanzada..." -ForegroundColor Cyan
    
    # Obtener todas las IPs activas
    try {
        $networkAdapters = Get-NetIPAddress -AddressFamily IPv4 -Type Unicast | 
            Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -ne "127.0.0.1" } |
            Sort-Object InterfaceIndex
    } catch {
        $networkAdapters = @()
    }
    
    $currentIP = $null
    $serverIP = "127.0.0.1"
    $networkType = "local"
    
    foreach ($adapter in $networkAdapters) {
        $ip = $adapter.IPAddress
        Write-Host "      Analizando interfaz: $($adapter.InterfaceAlias) -> $ip" -ForegroundColor Gray
        
        if ($ip -match "^192\.168\.1\.") {
            Write-Host "      Red FCEA detectada: $ip" -ForegroundColor Green
            $currentIP = $ip
            $serverIP = "192.168.1.100"
            $networkType = "fcea"
            break
        } elseif ($ip -match "^10\.") {
            Write-Host "      Red corporativa detectada: $ip" -ForegroundColor Yellow
            $currentIP = $ip
            $serverIP = $ip -replace '\d+$', '100'
            $networkType = "corporativa"
        } elseif ($ip -match "^192\.168\.") {
            Write-Host "      Red local detectada: $ip" -ForegroundColor Yellow
            $currentIP = $ip
            $serverIP = $ip -replace '\d+$', '1'
            $networkType = "local"
        }
    }
    
    if (-not $currentIP) {
        Write-Host "      Usando configuracion de desarrollo: 127.0.0.1" -ForegroundColor Gray
        $currentIP = "127.0.0.1"
        $serverIP = "127.0.0.1"
        $networkType = "desarrollo"
    }
    
    return @{
        CurrentIP = $currentIP
        ServerIP = $serverIP
        Network = $networkType
        AllIPs = if ($networkAdapters) { ($networkAdapters | ForEach-Object { $_.IPAddress }) -join ", " } else { "127.0.0.1" }
    }
}

function Fix-PocketBaseURL {
    param([string]$url)
    
    if (-not $url) { return "http://127.0.0.1:8090" }
    
    # Limpiar URL malformada mas exhaustivamente
    $cleaned = $url -replace "/$", ""
    $cleaned = $cleaned -replace "/api.*$", ""
    $cleaned = $cleaned -replace ":8090.*$", ":8090"
    $cleaned = $cleaned -replace "/{2,}", "/"
    $cleaned = $cleaned -replace "^http:/{1}([^/])", "http://`$1"
    
    # Validar formato basico
    if ($cleaned -notmatch "^https?://[\w\.-]+(:\d+)?$") {
        Write-Host "      [WARN] URL '$cleaned' no parece valida, usando fallback" -ForegroundColor Yellow
        return "http://127.0.0.1:8090"
    }
    
    return $cleaned
}

function Backup-ConfigFiles {
    param([string]$backupDir)
    
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    
    if (Test-Path $PUBLIC_CONFIG) {
        Copy-Item $PUBLIC_CONFIG "$backupDir\public_config.json.bak" -Force
        Write-Host "      OK public/config.json respaldado" -ForegroundColor Gray
    }
    
    if (Test-Path $DIST_CONFIG) {
        Copy-Item $DIST_CONFIG "$backupDir\dist_config.json.bak" -Force
        Write-Host "      OK dist/config.json respaldado" -ForegroundColor Gray
    }
    
    # Backup de config de red si existe
    $networkFile = "$REPO_ROOT\.network_config"
    if (Test-Path $networkFile) {
        Copy-Item $networkFile "$backupDir\.network_config.bak" -Force
        Write-Host "      OK .network_config respaldado" -ForegroundColor Gray
    }
}

if ($Rollback) {
    Write-Host "[ROLLBACK] Restaurando versiones originales..." -ForegroundColor Red
    
    if (-not (Test-Path $BACKUP_DIR)) {
        Write-Host "[ERROR] No se encontro la carpeta de backup para rollback: $BACKUP_DIR" -ForegroundColor Red
        exit 1
    }
    
    $restored = 0
    if (Test-Path "$BACKUP_DIR\public_config.json.bak") {
        Copy-Item "$BACKUP_DIR\public_config.json.bak" $PUBLIC_CONFIG -Force
        Write-Host "      OK public/config.json restaurado" -ForegroundColor Green
        $restored++
    }
    
    if (Test-Path "$BACKUP_DIR\dist_config.json.bak") {
        Copy-Item "$BACKUP_DIR\dist_config.json.bak" $DIST_CONFIG -Force
        Write-Host "      OK dist/config.json restaurado" -ForegroundColor Green
        $restored++
    }
    
    if ($restored -eq 0) {
        Write-Host "[ERROR] No se encontraron archivos de backup validos" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] Rollback completado ($restored archivos restaurados)" -ForegroundColor Green
    exit 0
}

if ($Test) {
    Write-Host "[TEST MODE] Diagnostico completo del problema..." -ForegroundColor Yellow
    Write-Host ""
    
    # Verificar archivos de configuracion
    Write-Host "1. VERIFICANDO ARCHIVOS DE CONFIGURACION:" -ForegroundColor Cyan
    
    $publicExists = Test-Path $PUBLIC_CONFIG
    $distExists = Test-Path $DIST_CONFIG
    
    $publicStatus = if($publicExists) { "OK EXISTE" } else { "ERROR NO EXISTE" }
    $distStatus = if($distExists) { "OK EXISTE" } else { "ERROR NO EXISTE" }
    
    Write-Host "   public/config.json: $publicStatus" -ForegroundColor $(if($publicExists){'Green'}else{'Red'})
    Write-Host "   dist/config.json:   $distStatus" -ForegroundColor $(if($distExists){'Green'}else{'Red'})
    
    if (-not $publicExists) {
        Write-Host "[ERROR CRITICO] public/config.json no existe. El sistema no puede funcionar." -ForegroundColor Red
        exit 1
    }
    
    # Analizar configuracion actual
    Write-Host ""
    Write-Host "2. ANALIZANDO CONFIGURACION ACTUAL:" -ForegroundColor Cyan
    
    $publicConfig = Get-Content $PUBLIC_CONFIG -Raw | ConvertFrom-Json
    Write-Host "   public/config.json:" -ForegroundColor White
    Write-Host "     pocketbase_url: $($publicConfig.pocketbase_url)" -ForegroundColor White
    Write-Host "     rol: $($publicConfig.rol)" -ForegroundColor White
    Write-Host "     modo: $($publicConfig.modo)" -ForegroundColor White
    
    $synced = $true
    if ($distExists) {
        $distConfig = Get-Content $DIST_CONFIG -Raw | ConvertFrom-Json
        Write-Host "   dist/config.json:" -ForegroundColor White
        Write-Host "     pocketbase_url: $($distConfig.pocketbase_url)" -ForegroundColor White
        Write-Host "     rol: $($distConfig.rol)" -ForegroundColor White
        
        # Comparar sincronizacion
        $synced = ($publicConfig.pocketbase_url -eq $distConfig.pocketbase_url) -and 
                  ($publicConfig.rol -eq $distConfig.rol)
        $syncStatus = if($synced) { "OK SINCRONIZADOS" } else { "ERROR DESINCRONIZADOS" }
        Write-Host "   Sincronizacion: $syncStatus" -ForegroundColor $(if($synced){'Green'}else{'Red'})
    }
    
    # Detectar problemas en URL
    Write-Host ""
    Write-Host "3. DETECTANDO PROBLEMAS EN URL:" -ForegroundColor Cyan
    
    $hasApiDuplicated = $publicConfig.pocketbase_url -like "*/api*"
    $hasTrailingSlash = $publicConfig.pocketbase_url -like "*/"
    $hasInvalidFormat = $publicConfig.pocketbase_url -notmatch "^https?://[\w\.-]+(:\d+)?/?$"
    $hasEmptyFields = ($publicConfig.rol -eq "") -or ($publicConfig.modo -eq "")
    
    $apiStatus = if($hasApiDuplicated) { "ERROR SI (PROBLEMA)" } else { "OK NO" }
    $slashStatus = if($hasTrailingSlash) { "WARNING SI" } else { "OK NO" }
    $formatStatus = if($hasInvalidFormat) { "ERROR SI (PROBLEMA)" } else { "OK NO" }
    $emptyStatus = if($hasEmptyFields) { "ERROR SI (PROBLEMA)" } else { "OK NO" }
    
    Write-Host "   URL con /api duplicado: $apiStatus" -ForegroundColor $(if($hasApiDuplicated){'Red'}else{'Green'})
    Write-Host "   URL con trailing slash: $slashStatus" -ForegroundColor $(if($hasTrailingSlash){'Yellow'}else{'Green'})
    Write-Host "   Formato URL invalido:   $formatStatus" -ForegroundColor $(if($hasInvalidFormat){'Red'}else{'Green'})
    Write-Host "   Campos vacios:          $emptyStatus" -ForegroundColor $(if($hasEmptyFields){'Red'}else{'Green'})
    
    # Test de conectividad
    Write-Host ""
    Write-Host "4. PROBANDO CONECTIVIDAD:" -ForegroundColor Cyan
    
    $testUrl = Fix-PocketBaseURL $publicConfig.pocketbase_url
    Write-Host "   URL limpia calculada: $testUrl" -ForegroundColor White
    Write-Host "   Probando conexion..." -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri "$testUrl/api/health" -Method GET -TimeoutSec 10 -ErrorAction Stop
        Write-Host "   Conectividad: OK SERVIDOR RESPONDE CORRECTAMENTE" -ForegroundColor Green
        Write-Host "   Respuesta: $(($response | ConvertTo-Json -Compress))" -ForegroundColor Gray
    } catch {
        Write-Host "   Conectividad: ERROR NO SE PUEDE CONECTAR" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   [INFO] Esto es normal si PocketBase no esta ejecutandose" -ForegroundColor Gray
    }
    
    # Resumen de problemas
    Write-Host ""
    Write-Host "5. RESUMEN DE PROBLEMAS DETECTADOS:" -ForegroundColor Cyan
    $problemCount = 0
    
    if ($hasApiDuplicated) { 
        Write-Host "   ERROR URL con /api duplicado -> Causa del error 404" -ForegroundColor Red
        $problemCount++ 
    }
    if ($hasEmptyFields) { 
        Write-Host "   ERROR Campos rol/modo vacios -> Puede causar mal comportamiento" -ForegroundColor Red
        $problemCount++ 
    }
    if ($distExists -and -not $synced) { 
        Write-Host "   ERROR Archivos desincronizados -> Comportamiento inconsistente" -ForegroundColor Red
        $problemCount++ 
    }
    if (-not $distExists) {
        Write-Host "   WARNING dist/config.json no existe -> Sistema funcionara pero no es optimo" -ForegroundColor Yellow
    }
    
    if ($problemCount -eq 0) {
        Write-Host "   OK NO SE DETECTARON PROBLEMAS CRITICOS" -ForegroundColor Green
        Write-Host "   [INFO] Si aun hay error 404, verificar que PocketBase este corriendo" -ForegroundColor Gray
    } else {
        Write-Host "   [RECOMENDACION] Ejecutar: .\FIX_TERMINAL_B_404_v2.ps1" -ForegroundColor Yellow
    }
    
    exit 0
}

# ============================================================
# APLICAR FIX v2.0
# ============================================================

Write-Host "[1/6] Detectando configuracion de red avanzada..." -ForegroundColor Cyan
$networkConfig = Get-NetworkConfig
Write-Host "      Red detectada: $($networkConfig.Network)" -ForegroundColor White
Write-Host "      IP actual: $($networkConfig.CurrentIP)" -ForegroundColor White
Write-Host "      Servidor asumido: $($networkConfig.ServerIP)" -ForegroundColor White

Write-Host "" 
Write-Host "[2/6] Creando backup de seguridad..." -ForegroundColor Cyan
Backup-ConfigFiles $BACKUP_DIR
Write-Host "      Backups guardados en: $BACKUP_DIR" -ForegroundColor Gray

Write-Host ""
Write-Host "[3/6] Analizando configuracion actual..." -ForegroundColor Cyan

if (-not (Test-Path $PUBLIC_CONFIG)) {
    Write-Host "[ERROR CRITICO] No se encontro public/config.json" -ForegroundColor Red
    exit 1
}

$publicConfig = Get-Content $PUBLIC_CONFIG -Raw | ConvertFrom-Json
Write-Host "      public/config.json actual:" -ForegroundColor Gray
Write-Host "        URL: $($publicConfig.pocketbase_url)" -ForegroundColor White
Write-Host "        Rol: $($publicConfig.rol)" -ForegroundColor White
Write-Host "        Modo: $($publicConfig.modo)" -ForegroundColor White

# Determinar IP del servidor con mas logica
$serverIP = $networkConfig.ServerIP
if ($Interactive) {
    Write-Host ""
    $userIP = Read-Host "      IP del servidor Monitor [$serverIP]"
    if ($userIP -and $userIP.Trim()) { $serverIP = $userIP.Trim() }
}

Write-Host ""
Write-Host "[4/6] Aplicando fix avanzado de configuracion..." -ForegroundColor Cyan

# Preparar nueva configuracion
$newUrl = "http://${serverIP}:8090"

# Construir configuracion con valores seguros
$currentModo = if ($publicConfig.modo -and $publicConfig.modo -ne "") { $publicConfig.modo } else { "produccion" }
$currentRol = if ($publicConfig.rol -and $publicConfig.rol -ne "") { $publicConfig.rol } else { "terminal-b" }
$currentHardware = if ($publicConfig.hardware) { $publicConfig.hardware } else { "" }

$redConfig = @{
    'ip_servidor' = $serverIP
    'ip_terminal_a' = if ($publicConfig.red -and $publicConfig.red.ip_terminal_a) { $publicConfig.red.ip_terminal_a } else { $serverIP }
    'ip_terminal_b' = if ($publicConfig.red -and $publicConfig.red.ip_terminal_b) { $publicConfig.red.ip_terminal_b } else { $networkConfig.CurrentIP }
}

$uiConfig = @{
    'teclado_virtual_forzado' = if ($publicConfig.ui -and ($null -ne $publicConfig.ui.teclado_virtual_forzado)) { $publicConfig.ui.teclado_virtual_forzado } else { $false }
    'tema' = if ($publicConfig.ui -and $publicConfig.ui.tema) { $publicConfig.ui.tema } else { "claro" }
}

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$notasConfig = @(
    "CONFIGURACION CORREGIDA POR FIX v2.0 - $timestamp",
    "Red detectada: $($networkConfig.Network) ($($networkConfig.CurrentIP))",
    "Servidor configurado: $serverIP",
    "Fix aplicado para resolver error 404 en Terminal B"
)

$fixedConfig = @{
    '$schema' = "./config.schema.json"
    'version' = "2.1.0"
    'modo' = $currentModo
    'rol' = $currentRol
    'hardware' = $currentHardware
    'pocketbase_url' = $newUrl
    'red' = $redConfig
    'ui' = $uiConfig
    '_notas' = $notasConfig
}

Write-Host "[5/6] Guardando configuracion corregida..." -ForegroundColor Cyan

# Guardar public/config.json
$configJson = $fixedConfig | ConvertTo-Json -Depth 4
$configJson | Set-Content $PUBLIC_CONFIG -Encoding UTF8
Write-Host "      OK public/config.json actualizado" -ForegroundColor Green

# Sincronizar dist/config.json si existe la carpeta dist
if (Test-Path "$REPO_ROOT\dist") {
    $configJson | Set-Content $DIST_CONFIG -Encoding UTF8
    Write-Host "      OK dist/config.json sincronizado" -ForegroundColor Green
} else {
    Write-Host "      WARNING dist/ no existe, se creara en el proximo build" -ForegroundColor Yellow
}

# Guardar configuracion de red para referencia
$networkConfig | ConvertTo-Json | Set-Content "$REPO_ROOT\.network_config" -Encoding UTF8

Write-Host ""
Write-Host "[6/6] Validando conectividad..." -ForegroundColor Cyan
Write-Host "      Probando conexion a: $newUrl" -ForegroundColor Gray

$connectivityOK = $false
try {
    $response = Invoke-RestMethod -Uri "$newUrl/api/health" -Method GET -TimeoutSec 10 -ErrorAction Stop
    Write-Host "      OK SERVIDOR POCKETBASE RESPONDE CORRECTAMENTE" -ForegroundColor Green
    $connectivityOK = $true
} catch {
    Write-Host "      WARNING No se puede conectar al servidor ahora" -ForegroundColor Yellow
    Write-Host "        Error: $($_.Exception.Message)" -ForegroundColor Gray
    Write-Host "        [INFO] Esto es normal si PocketBase no esta ejecutandose" -ForegroundColor Gray
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " EXITO FIX v2.0 COMPLETADO EXITOSAMENTE" -ForegroundColor Green  
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "CAMBIOS APLICADOS:" -ForegroundColor Cyan
Write-Host "   URL corregida: $newUrl" -ForegroundColor White
Write-Host "   Rol configurado: $($fixedConfig.rol)" -ForegroundColor White
Write-Host "   Modo configurado: $($fixedConfig.modo)" -ForegroundColor White
Write-Host "   Red sincronizada: $($networkConfig.Network)" -ForegroundColor White
Write-Host "   Archivos sincronizados: public/ y dist/" -ForegroundColor White

Write-Host ""
Write-Host "CONFIGURACION FINAL:" -ForegroundColor Cyan
$finalConfig = Get-Content $PUBLIC_CONFIG -Raw | ConvertFrom-Json
Write-Host "   pocketbase_url: $($finalConfig.pocketbase_url)" -ForegroundColor White
Write-Host "   rol: $($finalConfig.rol)" -ForegroundColor White
Write-Host "   modo: $($finalConfig.modo)" -ForegroundColor White
Write-Host "   ip_servidor: $($finalConfig.red.ip_servidor)" -ForegroundColor White
Write-Host "   ip_terminal_b: $($finalConfig.red.ip_terminal_b)" -ForegroundColor White

Write-Host ""
Write-Host "PROXIMOS PASOS:" -ForegroundColor Cyan
if ($connectivityOK) {
    Write-Host "   1. EXITO Servidor PocketBase esta funcionando" -ForegroundColor Green
    Write-Host "   2. Reiniciar navegador en Terminal B (Ctrl+Shift+R)" -ForegroundColor White
    Write-Host "   3. EXITO El error 404 deberia estar completamente resuelto" -ForegroundColor Green
} else {
    Write-Host "   1. Asegurar que PocketBase este ejecutandose en el servidor" -ForegroundColor White
    Write-Host "   2. Reiniciar navegador en Terminal B (Ctrl+Shift+R)" -ForegroundColor White
    Write-Host "   3. EXITO El error 404 deberia estar resuelto" -ForegroundColor White
}

# LANZAR NAVEGADOR EN MODO KIOSK TERMINAL B
if (-not $Test -and -not $Rollback) {
    Write-Host ""
    Write-Host "LANZANDO TERMINAL B EN MODO KIOSK..." -ForegroundColor Yellow
    
    # Importar función para abrir Chrome en kiosk
    . "$REPO_ROOT\scripts\lib\abrir_chrome_kiosk.ps1"
    
    # Obtener URL del servidor desde configuración
    try {
        $config = Get-Content $PUBLIC_CONFIG | ConvertFrom-Json
        $baseUrl = $config.pocketbase_url -replace '/api/?$', ''
        $terminalUrl = "$baseUrl/"
        
        Write-Host "   URL Terminal B: $terminalUrl" -ForegroundColor Cyan
        Write-Host "   Modo: Kiosk (Mouse y Teclado)" -ForegroundColor Cyan
        
        # Lanzar navegador en modo kiosk tradicional (mouse y teclado)
        $success = Open-AppBrowser -Url $terminalUrl -Hardware "tradicional" -MonitorIndex 0
        
        if ($success) {
            Write-Host ""
            Write-Host "✓ TERMINAL B LANZADA EXITOSAMENTE EN MODO KIOSK" -ForegroundColor Green
            Write-Host "   El navegador debería abrir automáticamente" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "✗ ERROR AL LANZAR TERMINAL B" -ForegroundColor Red
            Write-Host "   Abrir manualmente: $terminalUrl" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ Error al leer configuración para lanzar navegador: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Abrir manualmente navegador en http://192.168.1.100:8090" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "COMANDOS DE UTILIDAD:" -ForegroundColor Yellow
Write-Host "   Rollback:     .\FIX_TERMINAL_B_404_v2.ps1 -Rollback" -ForegroundColor Gray
Write-Host "   Diagnostico:  .\FIX_TERMINAL_B_404_v2.ps1 -Test" -ForegroundColor Gray
Write-Host "   Interactivo:  .\FIX_TERMINAL_B_404_v2.ps1 -Interactive" -ForegroundColor Gray

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green

# Pausa para que el usuario pueda ver los resultados
Write-Host ""
Write-Host "Presiona cualquier tecla para cerrar..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
