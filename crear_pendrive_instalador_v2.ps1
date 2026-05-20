# =====================================================================
#  CREAR / ACTUALIZAR PENDRIVE INSTALADOR v2  (mayo 2026)
# ---------------------------------------------------------------------
#  Toma una letra de unidad (por defecto D:\) y arma alli el pendrive
#  instalador. La idea: el instalador es esencialmente el mismo flujo
#  que el RECUPERADOR v2 (que ya funciona) PERO incluyendo el repo
#  fuente completo con .git, los docs y el MSI de Node.js para instalar
#  offline.
#
#  Estructura final del pendrive:
#
#    D:\
#     +- INSTALAR-SISTEMA-COMPLETO.bat   (= REINSTALAR-COMPLETO.bat)
#     +- DESINSTALAR-SISTEMA.bat
#     +- REPARAR-Y-INICIAR-SISTEMA.bat
#     +- LEEME-PRIMERO.txt
#     +- lib\
#     |   +- REINSTALAR-COMPLETO.ps1
#     |   +- DESINSTALAR-SISTEMA.ps1
#     |   +- REPARAR-Y-INICIAR-SISTEMA.ps1
#     |   +- detectar_hardware.ps1
#     |   +- install_config_io.ps1
#     |   +- abrir_chrome_kiosk.ps1
#     +- sistema\                  (repo completo, sin node_modules)
#     |   +- .git\                 SI - el repo entero con historia
#     |   +- src\
#     |   +- public\
#     |   +- pocketbase\
#     |   +- scripts\
#     |   +- dist\                 (build de produccion)
#     |   +- package.json, etc.
#     +- instaladores\
#     |   +- node-setup.msi
#     +- docs\
#     +- respaldos_db\
#         +- pb_data_ultimo\       (snapshot inicial vacio o seed)
#
#  USO:
#    powershell -ExecutionPolicy Bypass -File .\crear_pendrive_instalador_v2.ps1
#    powershell -ExecutionPolicy Bypass -File .\crear_pendrive_instalador_v2.ps1 -DriveLetter E
# =====================================================================
[CmdletBinding()]
param(
    [string]$DriveLetter = 'D',
    [switch]$SkipBuild,                 # No correr npm run build (usar dist/ ya existente)
    [switch]$SkipNode,                  # No intentar descargar el MSI de Node
    [switch]$IncluirNodeModules         # Si se quiere INCLUIR node_modules (NO recomendado: 400+ MB)
)

$ErrorActionPreference = "Continue"
$Host.UI.RawUI.WindowTitle = "Crear/Actualizar Pendrive INSTALADOR v2"

# ---------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------
function Write-Titulo($texto) {
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Magenta
    Write-Host " $texto" -ForegroundColor Magenta
    Write-Host "=====================================================" -ForegroundColor Magenta
    Write-Host ""
}
function Write-Paso($n,$t)  { Write-Host ""; Write-Host "[$n] $t" -ForegroundColor Yellow }
function Write-OK   ($t)    { Write-Host "    [OK]    $t" -ForegroundColor Green }
function Write-Aviso($t)    { Write-Host "    [!]     $t" -ForegroundColor Yellow }
function Write-Err  ($t)    { Write-Host "    [ERROR] $t" -ForegroundColor Red }

# Copia un archivo binario aunque la ruta destino tenga atributos
# Hidden+System (FAT32 a veces los pone). Usa .NET porque Copy-Item de
# PowerShell falla con "Access denied" en esos casos.
function Copy-FileForzado {
    param([string]$Src, [string]$Dst)
    if (-not (Test-Path $Src)) { throw "No existe origen: $Src" }
    $dstDir = Split-Path -Parent $Dst
    if ($dstDir -and -not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }
    if (Test-Path $Dst) {
        try { attrib -r -h -s "$Dst" 2>$null | Out-Null } catch {}
        try { Remove-Item $Dst -Force -ErrorAction Stop } catch {}
    }
    $bytes = [System.IO.File]::ReadAllBytes($Src)
    [System.IO.File]::WriteAllBytes($Dst, $bytes)
}

function Get-DirSizeMB {
    param([string]$Dir)
    if (-not (Test-Path $Dir)) { return 0 }
    try {
        $b = (Get-ChildItem $Dir -Recurse -File -Force -ErrorAction SilentlyContinue |
              Measure-Object -Property Length -Sum).Sum
        return [math]::Round($b / 1MB, 1)
    } catch { return 0 }
}

# ---------------------------------------------------------------------
# Rutas
# ---------------------------------------------------------------------
$REPO_DIR  = Split-Path -Parent $MyInvocation.MyCommand.Path
$DRIVE     = $DriveLetter.TrimEnd(':').TrimEnd('\').ToUpper() + ':'
$PENDRIVE  = "$DRIVE\"

if (-not (Test-Path $PENDRIVE)) {
    Write-Err "No se detecta la unidad $PENDRIVE."
    Write-Err "Conecte el pendrive y vuelva a ejecutar."
    Read-Host "Presione Enter para salir"
    exit 1
}

$vol = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
if ($vol) {
    $libreGB = [math]::Round($vol.SizeRemaining / 1GB, 1)
    $totalGB = [math]::Round($vol.Size / 1GB, 1)
} else { $libreGB = 0; $totalGB = 0 }

Write-Titulo "PREPARACION PENDRIVE INSTALADOR  v2.0"
Write-Host " Repo origen  : $REPO_DIR"             -ForegroundColor White
Write-Host " Pendrive     : $PENDRIVE"              -ForegroundColor White
Write-Host " Espacio      : $libreGB / $totalGB GB" -ForegroundColor White
Write-Host ""
Write-Host " IMPORTANTE: este proceso BORRA el contenido del pendrive" -ForegroundColor Yellow
Write-Host " (excepto System Volume Information) y lo recrea desde cero." -ForegroundColor Yellow
Write-Host ""
$ok = Read-Host " Escriba SI y Enter para continuar"
if ($ok -ne 'SI') {
    Write-Aviso "Cancelado por el usuario."
    exit 0
}

# ---------------------------------------------------------------------
# PASO 0: Build de produccion (opcional)
# ---------------------------------------------------------------------
Write-Paso "0/8" "Build de produccion (npm run build) ..."
if ($SkipBuild) {
    Write-Aviso "Salteado por -SkipBuild"
    if (-not (Test-Path "$REPO_DIR\dist\index.html")) {
        Write-Aviso "ATENCION: no existe dist/. El instalador caera a npm run dev (mas lento)."
    } else {
        Write-OK "Reutilizando dist/ existente"
    }
} else {
    Push-Location $REPO_DIR
    try {
        Write-Host "    Corriendo npm run build (puede tardar 1-2 min)..." -ForegroundColor Gray
        $tIni = Get-Date
        & npm run build 2>&1 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
        $segs = [int]((Get-Date)-$tIni).TotalSeconds
        if ($LASTEXITCODE -eq 0 -and (Test-Path "$REPO_DIR\dist\index.html")) {
            Write-OK "Build OK en $segs segundos"
        } else {
            Write-Aviso "Build con codigo $LASTEXITCODE - revise. Sigo igual."
        }
    } finally { Pop-Location }
}

# ---------------------------------------------------------------------
# PASO 1: Limpiar pendrive
# ---------------------------------------------------------------------
Write-Paso "1/8" "Limpiando pendrive..."
$conservar = @('System Volume Information','$RECYCLE.BIN','autorun.inf')
Get-ChildItem $PENDRIVE -Force -ErrorAction SilentlyContinue | ForEach-Object {
    if ($conservar -notcontains $_.Name) {
        try {
            attrib -r -h -s "$($_.FullName)" /S /D 2>$null | Out-Null
            Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "    Borrado: $($_.Name)" -ForegroundColor DarkGray
        } catch {
            Write-Aviso "No pude borrar: $($_.Name) - $($_.Exception.Message)"
        }
    }
}
Write-OK "Pendrive limpio"

# ---------------------------------------------------------------------
# PASO 2: Copiar los 3 .bat y el LEEME
# ---------------------------------------------------------------------
Write-Paso "2/8" "Copiando archivos de control (.bat + LEEME)..."

# El INSTALAR es el mismo REINSTALAR-COMPLETO (el flujo es el mismo).
Copy-FileForzado "$REPO_DIR\scripts\respaldo_recuperacion\REINSTALAR-COMPLETO.bat" `
                 "$PENDRIVE\INSTALAR-SISTEMA-COMPLETO.bat"
Write-OK "INSTALAR-SISTEMA-COMPLETO.bat"

Copy-FileForzado "$REPO_DIR\scripts\respaldo_recuperacion\DESINSTALAR-SISTEMA.bat" `
                 "$PENDRIVE\DESINSTALAR-SISTEMA.bat"
Write-OK "DESINSTALAR-SISTEMA.bat"

Copy-FileForzado "$REPO_DIR\scripts\respaldo_recuperacion\REPARAR-Y-INICIAR-SISTEMA.bat" `
                 "$PENDRIVE\REPARAR-Y-INICIAR-SISTEMA.bat"
Write-OK "REPARAR-Y-INICIAR-SISTEMA.bat"

# Generamos un LEEME nuevo, adaptado a INSTALADOR (no recuperador)
$leeme = @'
==============================================================
  PENDRIVE INSTALADOR  -  SISTEMA DE GESTION DE LLAVES FCEA
  Version 2.0  (mayo 2026)
==============================================================

QUE ES ESTE PENDRIVE
--------------------
Sirve para INSTALAR DESDE CERO el sistema en una PC nueva,
y tambien incluye una copia INTEGRA del codigo fuente del
proyecto (incluido el repositorio git con su historia
completa) para entregar al cliente / archivo institucional.

==============================================================
  COMO INSTALAR EN UNA PC NUEVA
==============================================================

  1) Conecte el pendrive en la PC.

  2) Doble clic en:    INSTALAR-SISTEMA-COMPLETO.bat

  3) Windows pedira permiso de Administrador. Diga SI.

  4) El instalador le preguntara:
       - Modo:     [1] Produccion   [2] Desarrollo
       - Hardware: [A] Tactil completo (3 monitores tactiles)
                   [B] Tradicional (3 monitores+teclados+mouses)
                   [C] Desarrollo (1 monitor)

  5) Va a copiar todo, instalar dependencias (2-5 min),
     arrancar PocketBase + frontend, y abrir Chrome.

  6) Al terminar, el sistema queda corriendo. NO cierre la
     ventana cmd.exe del frontend (el sistema vive ahi).

  Al prender la PC la proxima vez, el sistema arrancara solo.

==============================================================
  SI ALGO FALLA Y EL SISTEMA NO LEVANTA AL PRENDER
==============================================================

  Doble clic en:    REPARAR-Y-INICIAR-SISTEMA.bat

  Esto NO reinstala. Solo verifica que PocketBase y el
  frontend esten corriendo, los levanta si estan caidos, y
  abre Chrome en kiosk segun la configuracion guardada.

==============================================================
  COMO DESINSTALAR (devolver la PC al estado previo)
==============================================================

  Doble clic en:    DESINSTALAR-SISTEMA.bat

  Cuando lo pida, escriba CONFIRMAR (en mayusculas) y Enter.
  Borra C:\sistema-de-gesti-n-de-llaves-vigilancia-fcea,
  elimina tareas programadas, limpia entradas de Registro y
  cache. Node.js NO se desinstala (quedaria utilizable).

==============================================================
  URLs DEL SISTEMA (despues de instalar)
==============================================================

   Monitor   : http://localhost:8080/monitor
   Terminal  : http://localhost:8080/terminal
   Dashboard : http://localhost:8080/dashboard

==============================================================
  CONTENIDO DEL PENDRIVE
==============================================================

   INSTALAR-SISTEMA-COMPLETO.bat   <- Doble clic para INSTALAR
   REPARAR-Y-INICIAR-SISTEMA.bat   <- Si algo deja de andar
   DESINSTALAR-SISTEMA.bat         <- Devolver PC como estaba
   LEEME-PRIMERO.txt               Este archivo
   sistema\                        Codigo fuente del sistema
                                   (INCLUYE .git con historia)
   lib\                            Scripts auxiliares PowerShell
   instaladores\                   Node.js MSI (instalacion offline)
   docs\                           Documentacion del sistema
   respaldos_db\                   (Plantilla inicial de DB)

==============================================================
  NOTA TECNICA - REPOSITORIO GIT INCLUIDO
==============================================================

  El directorio  sistema\  es un clon COMPLETO del repositorio
  con su historia git. Para clonarlo en una PC con acceso a
  Internet y subir cambios al remoto original:

      git clone D:\sistema  C:\mi-proyecto
      cd C:\mi-proyecto
      git remote -v   (mostrara el remoto origin de GitHub)

==============================================================
'@
$leeme | Out-File -FilePath "$PENDRIVE\LEEME-PRIMERO.txt" -Encoding UTF8 -Force
Write-OK "LEEME-PRIMERO.txt"

# ---------------------------------------------------------------------
# PASO 3: Copiar las libs PowerShell
# ---------------------------------------------------------------------
Write-Paso "3/8" "Copiando librerias PowerShell a D:\lib\..."
$libDst = "$PENDRIVE\lib"
New-Item -ItemType Directory -Path $libDst -Force | Out-Null

# Las 3 libs reutilizables (detect_hardware, install_config_io, abrir_chrome_kiosk)
foreach ($lib in @('detectar_hardware.ps1','install_config_io.ps1','abrir_chrome_kiosk.ps1')) {
    Copy-FileForzado "$REPO_DIR\scripts\lib\$lib" "$libDst\$lib"
    Write-OK $lib
}

# Los 3 scripts orquestadores del recuperador (REINSTALAR, DESINSTALAR, REPARAR)
foreach ($orq in @('REINSTALAR-COMPLETO.ps1','DESINSTALAR-SISTEMA.ps1','REPARAR-Y-INICIAR-SISTEMA.ps1')) {
    Copy-FileForzado "$REPO_DIR\scripts\respaldo_recuperacion\lib\$orq" "$libDst\$orq"
    Write-OK $orq
}

# ---------------------------------------------------------------------
# PASO 4: Copiar Node.js MSI a instaladores\
# ---------------------------------------------------------------------
Write-Paso "4/8" "Preparando carpeta instaladores\..."
$instDst = "$PENDRIVE\instaladores"
New-Item -ItemType Directory -Path $instDst -Force | Out-Null

# Buscar MSI ya descargado en el repo o en la version vieja del pendrive
$msiCandidatos = @(
    "$REPO_DIR\scripts\instaladores\node-setup.msi",
    "$REPO_DIR\instaladores\node-setup.msi"
)
$msiSrc = $null
foreach ($c in $msiCandidatos) { if (Test-Path $c) { $msiSrc = $c; break } }

if ($msiSrc) {
    Copy-FileForzado $msiSrc "$instDst\node-setup.msi"
    $mb = [math]::Round((Get-Item "$instDst\node-setup.msi").Length / 1MB, 1)
    Write-OK "node-setup.msi copiado ($mb MB)"
} elseif (-not $SkipNode) {
    Write-Aviso "No hay node-setup.msi en el repo. Use scripts\descargar_nodejs_pendrive.ps1"
    Write-Aviso "para bajarlo y vuelva a correr este script."
} else {
    Write-Aviso "Salteado por -SkipNode"
}

# ---------------------------------------------------------------------
# PASO 5: Copiar codigo fuente del sistema a D:\sistema\
# ---------------------------------------------------------------------
Write-Paso "5/8" "Copiando codigo fuente a D:\sistema\ (incluye .git)..."

$sistemaDst = "$PENDRIVE\sistema"
New-Item -ItemType Directory -Path $sistemaDst -Force | Out-Null

# robocopy excluye carpetas pesadas que se regeneran en el destino
$rcExcluir = @(
    '/XD',
    "$REPO_DIR\node_modules",        # Se regenera con npm install
    "$REPO_DIR\respaldo_pre_restauracion",  # Backups grandes locales
    "$REPO_DIR\.vscode",             # Configuracion del editor
    "$REPO_DIR\.idea",
    "$REPO_DIR\pocketbase\pb_data"   # Datos vivos locales del dev (se manejan aparte)
)
if (-not $IncluirNodeModules) {
    # Ya lo agregamos a la lista. OK.
} else {
    # Si el usuario pidio incluir node_modules, sacamos esa exclusion
    $rcExcluir = $rcExcluir | Where-Object { $_ -ne "$REPO_DIR\node_modules" }
}
$rcExcluirFiles = @(
    '/XF', '*.log', '*.tmp', 'ultimo_log_*.txt',
    'REPORTE_VALIDACION_PENDRIVE.txt'
)

# Calcular tamano aproximado a copiar para mostrar
Write-Host "    Calculando archivos a copiar..." -ForegroundColor Gray
$mbAprox = 0
try {
    $mbAprox = (Get-ChildItem $REPO_DIR -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\node_modules\\' -and
                       $_.FullName -notmatch '\\respaldo_pre_restauracion\\' -and
                       $_.FullName -notmatch '\\\.vscode\\' -and
                       $_.FullName -notmatch '\\pocketbase\\pb_data\\' } |
        Measure-Object -Property Length -Sum).Sum
    $mbAprox = [math]::Round($mbAprox / 1MB, 1)
} catch {}
Write-Host "    A copiar aproximadamente: $mbAprox MB (incluye .git)" -ForegroundColor Gray
Write-Host "    Esto puede tardar 1-3 minutos en pendrives USB 2.0..." -ForegroundColor Gray

$rcArgs = @("`"$REPO_DIR`"", "`"$sistemaDst`"", "/E", "/NFL", "/NDL", "/NJH", "/NJS",
            "/nc", "/ns", "/np", "/R:1", "/W:1") + $rcExcluir + $rcExcluirFiles

$rc = Start-Process robocopy.exe -ArgumentList $rcArgs -WindowStyle Hidden -PassThru
$tIni = Get-Date
while (-not $rc.HasExited) {
    Start-Sleep -Seconds 5
    $segs = [int]((Get-Date)-$tIni).TotalSeconds
    $cop = Get-DirSizeMB $sistemaDst
    if ($mbAprox -gt 0) {
        $pct = [math]::Min(100, [int](($cop / $mbAprox) * 100))
        Write-Host ("    ... {0}%  ({1} / {2} MB,  {3}s)" -f $pct, $cop, $mbAprox, $segs) -ForegroundColor DarkCyan
    } else {
        Write-Host ("    ... copiados {0} MB ({1}s)" -f $cop, $segs) -ForegroundColor DarkCyan
    }
}
Write-OK ("Sistema copiado. Codigo de robocopy: {0} (1-7 son OK)" -f $rc.ExitCode)

# Validacion: verificar que .git este
if (Test-Path "$sistemaDst\.git") {
    $gitMB = Get-DirSizeMB "$sistemaDst\.git"
    Write-OK ".git presente ($gitMB MB de historia git)"
} else {
    Write-Aviso "ATENCION: NO se copio .git. El pendrive NO tiene la historia git."
}

# Validacion: dist/
if (Test-Path "$sistemaDst\dist\index.html") {
    Write-OK "dist/ presente (build de produccion incluida)"
} else {
    Write-Aviso "ATENCION: NO se copio dist/. El instalador caera a npm run dev (mas lento)."
}

# ---------------------------------------------------------------------
# PASO 6: Copiar docs
# ---------------------------------------------------------------------
Write-Paso "6/8" "Copiando docs/ a D:\docs\..."
$docsDst = "$PENDRIVE\docs"
New-Item -ItemType Directory -Path $docsDst -Force | Out-Null
if (Test-Path "$REPO_DIR\docs") {
    Copy-Item "$REPO_DIR\docs\*" $docsDst -Recurse -Force -ErrorAction SilentlyContinue
    $n = (Get-ChildItem $docsDst -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-OK "$n archivos de docs copiados"
}

# ---------------------------------------------------------------------
# PASO 7: Crear estructura respaldos_db (vacia - es un instalador)
# ---------------------------------------------------------------------
Write-Paso "7/8" "Preparando respaldos_db\pb_data_ultimo (semilla)..."
$pbSeedDst = "$PENDRIVE\respaldos_db\pb_data_ultimo"
New-Item -ItemType Directory -Path $pbSeedDst -Force | Out-Null
# Opcional: si hay pb_data en el repo (instalacion dev local), usarlo de seed
$pbSeedSrc = "$REPO_DIR\pocketbase\pb_data"
if (Test-Path "$pbSeedSrc\data.db") {
    Copy-Item "$pbSeedSrc\*" $pbSeedDst -Recurse -Force -ErrorAction SilentlyContinue
    $mb = Get-DirSizeMB $pbSeedDst
    Write-OK "pb_data_ultimo poblado desde repo local ($mb MB) - los usuarios verán esta DB inicial"
} else {
    "Pendrive INSTALADOR - sin DB inicial. Sistema arrancara vacio en primera instalacion." |
        Out-File -FilePath "$pbSeedDst\_VACIO.txt" -Encoding UTF8 -Force
    Write-OK "respaldos_db vacio (el sistema arrancara con DB nueva al instalar)"
}

# ---------------------------------------------------------------------
# PASO 8: Validacion final + reporte
# ---------------------------------------------------------------------
Write-Paso "8/8" "Validacion final..."

$checks = @(
    @{ Path = "$PENDRIVE\INSTALAR-SISTEMA-COMPLETO.bat";   Tipo='archivo'; Critico=$true  },
    @{ Path = "$PENDRIVE\DESINSTALAR-SISTEMA.bat";         Tipo='archivo'; Critico=$true  },
    @{ Path = "$PENDRIVE\REPARAR-Y-INICIAR-SISTEMA.bat";   Tipo='archivo'; Critico=$false },
    @{ Path = "$PENDRIVE\LEEME-PRIMERO.txt";               Tipo='archivo'; Critico=$true  },
    @{ Path = "$PENDRIVE\lib\REINSTALAR-COMPLETO.ps1";     Tipo='archivo'; Critico=$true  },
    @{ Path = "$PENDRIVE\lib\DESINSTALAR-SISTEMA.ps1";     Tipo='archivo'; Critico=$true  },
    @{ Path = "$PENDRIVE\lib\detectar_hardware.ps1";       Tipo='archivo'; Critico=$true  },
    @{ Path = "$PENDRIVE\lib\install_config_io.ps1";       Tipo='archivo'; Critico=$true  },
    @{ Path = "$PENDRIVE\lib\abrir_chrome_kiosk.ps1";      Tipo='archivo'; Critico=$true  },
    @{ Path = "$PENDRIVE\sistema\package.json";            Tipo='archivo'; Critico=$true  },
    @{ Path = "$PENDRIVE\sistema\src";                     Tipo='dir';     Critico=$true  },
    @{ Path = "$PENDRIVE\sistema\pocketbase\pocketbase.exe"; Tipo='archivo'; Critico=$true },
    @{ Path = "$PENDRIVE\sistema\.git";                    Tipo='dir';     Critico=$false },
    @{ Path = "$PENDRIVE\sistema\dist\index.html";         Tipo='archivo'; Critico=$false },
    @{ Path = "$PENDRIVE\instaladores\node-setup.msi";     Tipo='archivo'; Critico=$true  },
    @{ Path = "$PENDRIVE\docs";                            Tipo='dir';     Critico=$false },
    @{ Path = "$PENDRIVE\respaldos_db\pb_data_ultimo";     Tipo='dir';     Critico=$false }
)

$fallosCriticos = 0
foreach ($c in $checks) {
    $ok = Test-Path $c.Path
    if ($ok) {
        if ($c.Tipo -eq 'archivo') {
            $kb = [math]::Round((Get-Item $c.Path).Length / 1KB, 1)
            Write-Host ("    [OK]   {0,-50} ({1} KB)" -f ($c.Path -replace [regex]::Escape($PENDRIVE),''), $kb) -ForegroundColor Green
        } else {
            $mb = Get-DirSizeMB $c.Path
            Write-Host ("    [OK]   {0,-50} ({1} MB)" -f ($c.Path -replace [regex]::Escape($PENDRIVE),''), $mb) -ForegroundColor Green
        }
    } else {
        if ($c.Critico) {
            Write-Host ("    [ERR]  {0}" -f $c.Path) -ForegroundColor Red
            $fallosCriticos++
        } else {
            Write-Host ("    [WARN] {0} (no critico)" -f $c.Path) -ForegroundColor Yellow
        }
    }
}

Write-Host ""
$totalMB = Get-DirSizeMB $PENDRIVE
Write-Host (" Tamano total ocupado: $totalMB MB") -ForegroundColor White

if ($fallosCriticos -eq 0) {
    Write-Titulo "PENDRIVE INSTALADOR LISTO"
    Write-Host " Para usarlo en la otra PC:" -ForegroundColor White
    Write-Host "   1) Quite con seguridad el pendrive (Win+B, expulsar)" -ForegroundColor Cyan
    Write-Host "   2) Conecte en la PC destino" -ForegroundColor Cyan
    Write-Host "   3) Doble clic en INSTALAR-SISTEMA-COMPLETO.bat" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Titulo "PENDRIVE GENERADO CON $fallosCriticos ERRORES CRITICOS"
    Write-Host " Revise los [ERR] arriba." -ForegroundColor Red
}

Read-Host "Presione Enter para cerrar"
