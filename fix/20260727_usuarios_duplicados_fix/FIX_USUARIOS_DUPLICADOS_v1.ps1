# ============================================================
# FIX: Usuarios Duplicados en Terminal A
# Fecha: 27/07/2026 12:45
# Problema: Al buscar "095", aparece "Juan Peiras" repetido 3 veces
# Causa: buscarPorTexto() retorna todos los registros sin deduplicacion
# ============================================================

param(
    [switch]$Test = $false,
    [switch]$Rollback = $false
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " FIX: Usuarios Duplicados en Terminal A v1.0" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$REPO_ROOT = "C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea"
$BACKUP_DIR = "C:\fix_backups\20260727_usuarios_duplicados"
$TARGET_FILE = "$REPO_ROOT\src\hooks\useUsuariosRegistrados.ts"

if ($Rollback) {
    Write-Host "[ROLLBACK] Restaurando version original..." -ForegroundColor Red
    if (-not (Test-Path "$BACKUP_DIR\useUsuariosRegistrados.ts.bak")) {
        Write-Host "[ERROR] No se encontro el backup para rollback" -ForegroundColor Red
        exit 1
    }
    Copy-Item "$BACKUP_DIR\useUsuariosRegistrados.ts.bak" $TARGET_FILE -Force
    Write-Host "[OK] Rollback completado" -ForegroundColor Green
    exit 0
}

if ($Test) {
    Write-Host "[TEST MODE] Verificando condiciones previas..." -ForegroundColor Yellow
    
    # Verificar que el archivo objetivo existe
    if (-not (Test-Path $TARGET_FILE)) {
        Write-Host "[ERROR] No se encontro: $TARGET_FILE" -ForegroundColor Red
        exit 1
    }
    
    # Verificar que el problema existe (busqueda sin deduplicacion)
    $content = Get-Content $TARGET_FILE -Raw
    if ($content -match "return currentUsuarios\.filter\(u => u\.celular && u\.celular\.replace") {
        Write-Host "[OK] Problema confirmado - busqueda sin deduplicacion detectada" -ForegroundColor Green
    } else {
        Write-Host "[WARN] El problema podria haberse solucionado ya" -ForegroundColor Yellow
    }
    
    Write-Host "[TEST] Condiciones verificadas correctamente" -ForegroundColor Green
    exit 0
}

# ============================================================
# APLICAR FIX
# ============================================================

Write-Host "[1/3] Creando backup de seguridad..." -ForegroundColor Cyan
New-Item -Path $BACKUP_DIR -ItemType Directory -Force | Out-Null
Copy-Item $TARGET_FILE "$BACKUP_DIR\useUsuariosRegistrados.ts.bak" -Force
Write-Host "      Backup guardado en: $BACKUP_DIR" -ForegroundColor Gray

Write-Host "[2/3] Aplicando fix de deduplicacion..." -ForegroundColor Cyan

# Leer contenido original
$content = Get-Content $TARGET_FILE -Raw

# Aplicar fix: agregar deduplicacion por celular + email
$newBuscarPorTexto = @"
  const buscarPorTexto = useCallback((texto: string): UsuarioRegistrado[] => {
    if (!texto.trim()) return [];

    const norm = (t: string) => t.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
    const textoNorm = norm(texto.trim());
    const celularBusqueda = texto.replace(/\D/g, '');
    const currentUsuarios = usuariosRef.current;

    // SEGURIDAD: Solo se permite buscar por celular o por email.
    // La busqueda por nombre esta deshabilitada para evitar suplantacion de identidad.

    let resultados: UsuarioRegistrado[] = [];

    // Busqueda por celular: si el texto contiene solo digitos (y posibles espacios/guiones)
    if (/^[\d\s\-\+\(\)]+$/.test(texto.trim()) && celularBusqueda.length >= 2) {
      resultados = currentUsuarios.filter(u => u.celular && u.celular.replace(/\D/g, '').includes(celularBusqueda));
    }
    // Busqueda por email: si el texto contiene @
    else if (texto.includes('@')) {
      resultados = currentUsuarios.filter(u => u.email && norm(u.email).includes(textoNorm));
    }
    // Si el texto no es celular ni email, no devolver resultados
    // (evita busqueda por nombre que permitiria suplantacion de identidad)
    else {
      return [];
    }

    // FIX: DEDUPLICACION POR CELULAR + EMAIL
    // Remover duplicados priorizando el registro mas reciente
    const deduplicados = new Map<string, UsuarioRegistrado>();
    
    resultados.forEach(usuario => {
      const key = `${usuario.celular.replace(/\D/g, '')}_${usuario.email || ''}`;
      const existing = deduplicados.get(key);
      
      if (!existing || new Date(usuario.fechaRegistro) > new Date(existing.fechaRegistro)) {
        deduplicados.set(key, usuario);
      }
    });

    return Array.from(deduplicados.values());
  }, []);
"@

# Reemplazar la funcion buscarPorTexto completa
$pattern = "const buscarPorTexto = useCallback\(\(texto: string\): UsuarioRegistrado\[\] => \{[^}]+\}\);[\s\S]*?return \[\];\s*\}, \[\]\);"
$content = $content -replace $pattern, $newBuscarPorTexto.Trim()

# Escribir archivo modificado
Set-Content $TARGET_FILE -Value $content -Encoding UTF8

Write-Host "[3/3] Verificando fix aplicado..." -ForegroundColor Cyan
$newContent = Get-Content $TARGET_FILE -Raw
if ($newContent -match "DEDUPLICACION POR CELULAR \+ EMAIL") {
    Write-Host "[OK] Fix aplicado correctamente" -ForegroundColor Green
} else {
    Write-Host "[ERROR] El fix no se aplico correctamente" -ForegroundColor Red
    
    # Rollback automatico
    Write-Host "[ROLLBACK] Restaurando backup..." -ForegroundColor Yellow
    Copy-Item "$BACKUP_DIR\useUsuariosRegistrados.ts.bak" $TARGET_FILE -Force
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " FIX COMPLETADO EXITOSAMENTE" -ForegroundColor Green  
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Cambios aplicados:"
Write-Host "- Agregada deduplicacion en buscarPorTexto()" -ForegroundColor White
Write-Host "- Los usuarios duplicados se filtran por celular + email" -ForegroundColor White  
Write-Host "- Se prioriza el registro mas reciente" -ForegroundColor White
Write-Host ""
Write-Host "Proximo paso:" -ForegroundColor Cyan
Write-Host "1. Reinicie el servidor de desarrollo (npm run dev)" -ForegroundColor White
Write-Host "2. Teste la busqueda '095' en Terminal A" -ForegroundColor White
Write-Host "3. Debe aparecer solo 1 vez 'Juan Peiras'" -ForegroundColor White
Write-Host ""
Write-Host "Para rollback: .\FIX_USUARIOS_DUPLICADOS_v1.ps1 -Rollback" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green