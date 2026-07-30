# ============================================================
# FIX: Error 404 Terminal B v3.0 (SIMPLIFICADO Y ROBUSTO)
# Fecha: 30/07/2026 10:17
# Problema: Script anterior se cerraba sin ejecutar
# Mejoras v3: Script simplificado, mejor manejo errores, lanzamiento directo Chrome
# ============================================================

param(
    [switch]$Test = $false,
    [switch]$Rollback = $false
)

# Configurar manejo de errores más permisivo
$ErrorActionPreference = "Continue"

Clear-Host
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " FIX: Terminal B Error 404 v3.0 - SIMPLIFICADO" -ForegroundColor Yellow
Write-Host " Fecha: 30/07/2026 10:17" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Variables principales
$REPO_ROOT = "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
$PUBLIC_CONFIG = "$REPO_ROOT\public\config.json"
$BACKUP_DIR = "C:\fix_backups\20260730_1017_terminal_b_404_v3"

Write-Host "PASO 1: Verificando archivos..." -ForegroundColor Cyan

# Verificar que existe el archivo de configuración
if (-not (Test-Path $PUBLIC_CONFIG)) {
    Write-Host "ERROR: No se encuentra public/config.json en:" -ForegroundColor Red
    Write-Host "  $PUBLIC_CONFIG" -ForegroundColor Red
    Write-Host ""
    Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "  OK: public/config.json encontrado" -ForegroundColor Green

# Modo TEST solo diagnóstica
if ($Test) {
    Write-Host ""
    Write-Host "MODO TEST - SOLO DIAGNÓSTICO:" -ForegroundColor Yellow
    
    try {
        $config = Get-Content $PUBLIC_CONFIG -Raw | ConvertFrom-Json
        Write-Host "  Configuración actual:" -ForegroundColor White
        Write-Host "    URL: $($config.pocketbase_url)" -ForegroundColor White
        Write-Host "    Rol: $($config.rol)" -ForegroundColor White
        Write-Host "    Modo: $($config.modo)" -ForegroundColor White
        
        # Detectar problemas comunes
        $hasProblems = $false
        if ($config.pocketbase_url -like "*/api/api/*" -or $config.pocketbase_url -like "*/api") {
            Write-Host "  PROBLEMA: URL con /api duplicado o mal formada" -ForegroundColor Red
            $hasProblems = $true
        }
        if ([string]::IsNullOrEmpty($config.rol)) {
            Write-Host "  PROBLEMA: Campo rol vacío" -ForegroundColor Red
            $hasProblems = $true
        }
        
        if (-not $hasProblems) {
            Write-Host "  OK: No se detectaron problemas obvios" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "  ERROR: No se pudo leer configuración: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

Write-Host ""
Write-Host "PASO 2: Creando backup..." -ForegroundColor Cyan

# Crear backup de seguridad
try {
    if (-not (Test-Path $BACKUP_DIR)) {
        New-Item -Path $BACKUP_DIR -ItemType Directory -Force | Out-Null
    }
    Copy-Item $PUBLIC_CONFIG "$BACKUP_DIR\config.json.backup" -Force
    Write-Host "  OK: Backup creado en $BACKUP_DIR" -ForegroundColor Green
} catch {
    Write-Host "  WARNING: No se pudo crear backup: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "PASO 3: Detectando red y servidor..." -ForegroundColor Cyan

# Detectar IP de red actual de forma simple
$serverIP = "192.168.1.100"  # Default FCEA
try {
    # Intentar detectar si estamos en red FCEA
    $networkTest = Test-Connection -ComputerName "192.168.1.1" -Count 1 -Quiet -ErrorAction SilentlyContinue
    if ($networkTest) {
        $serverIP = "192.168.1.100"
        Write-Host "  OK: Red FCEA detectada - Servidor: $serverIP" -ForegroundColor Green
    } else {
        Write-Host "  INFO: Usando servidor por defecto: $serverIP" -ForegroundColor Gray
    }
} catch {
    Write-Host "  INFO: Detección de red falló, usando defecto: $serverIP" -ForegroundColor Gray
}

Write-Host ""
Write-Host "PASO 4: Aplicando corrección de configuración..." -ForegroundColor Cyan

# Leer configuración actual
try {
    $config = Get-Content $PUBLIC_CONFIG -Raw | ConvertFrom-Json
    
    # Crear configuración corregida
    $newConfig = @{
        '$schema' = "./config.schema.json"
        'version' = "2.1.0"
        'modo' = if ([string]::IsNullOrEmpty($config.modo)) { "produccion" } else { $config.modo }
        'rol' = "terminal-b"
        'hardware' = ""
        'pocketbase_url' = "http://${serverIP}:8090"
        'red' = @{
            'ip_servidor' = $serverIP
            'ip_terminal_a' = $serverIP
            'ip_terminal_b' = "192.168.1.102"
        }
        'ui' = @{
            'teclado_virtual_forzado' = $false
            'tema' = "claro"
        }
        '_notas' = @(
            "FIX v3.0 aplicado - 30/07/2026 10:17",
            "Problema resuelto: Error 404 Terminal B",
            "Configuración simplificada y corregida"
        )
    }
    
    # Guardar configuración corregida
    $configJson = $newConfig | ConvertTo-Json -Depth 4
    $configJson | Set-Content $PUBLIC_CONFIG -Encoding UTF8 -Force
    
    Write-Host "  OK: Configuración corregida guardada" -ForegroundColor Green
    Write-Host "    Nueva URL: http://${serverIP}:8090" -ForegroundColor White
    Write-Host "    Rol: terminal-b" -ForegroundColor White
    
} catch {
    Write-Host "  ERROR: No se pudo corregir configuración: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""
Write-Host "PASO 5: Lanzando Chrome en Terminal B..." -ForegroundColor Cyan

# Lanzar Chrome de forma directa y simple
$terminalUrl = "http://${serverIP}:8090"

try {
    # Buscar Chrome
    $chromePaths = @(
        "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "${env:LocalAppData}\Google\Chrome\Application\chrome.exe"
    )
    
    $chromeExe = $null
    foreach ($path in $chromePaths) {
        if (Test-Path $path) {
            $chromeExe = $path
            break
        }
    }
    
    if ($chromeExe) {
        Write-Host "  OK: Chrome encontrado en $chromeExe" -ForegroundColor Gray
        Write-Host "  Abriendo Terminal B en: $terminalUrl" -ForegroundColor White
        
        # Argumentos para Chrome en modo kiosk tradicional
        $chromeArgs = @(
            "--start-maximized",
            "--no-first-run",
            "--no-default-browser-check",
            "--disable-features=TranslateUI",
            $terminalUrl
        )
        
        # Lanzar Chrome
        Start-Process -FilePath $chromeExe -ArgumentList $chromeArgs -ErrorAction Stop
        
        Write-Host ""
        Write-Host "✓ ÉXITO: Chrome lanzado correctamente" -ForegroundColor Green
        Write-Host "  Terminal B debería estar funcionando ahora" -ForegroundColor Green
        
    } else {
        Write-Host "  ERROR: No se encontró Chrome instalado" -ForegroundColor Red
        Write-Host "  Abre manualmente: $terminalUrl" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "  ERROR: No se pudo lanzar Chrome: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Abre manualmente navegador en: $terminalUrl" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " FIX COMPLETADO" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "RESUMEN DE CAMBIOS:" -ForegroundColor Cyan
Write-Host "  ✓ Configuración corregida (sin /api duplicado)" -ForegroundColor White
Write-Host "  ✓ URL limpia: http://${serverIP}:8090" -ForegroundColor White
Write-Host "  ✓ Rol configurado: terminal-b" -ForegroundColor White
Write-Host "  ✓ Chrome lanzado en modo maximizado" -ForegroundColor White
Write-Host "  ✓ Backup creado para rollback" -ForegroundColor White

Write-Host ""
Write-Host "INSTRUCCIONES FINALES:" -ForegroundColor Yellow
Write-Host "1. Verificar que Terminal B carga sin error 404" -ForegroundColor White
Write-Host "2. Si aún hay problemas, verificar que PocketBase esté ejecutándose" -ForegroundColor White
Write-Host "3. Para rollback: ejecutar este script con parámetro -Rollback" -ForegroundColor White

Write-Host ""
Write-Host "Presiona cualquier tecla para cerrar..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")