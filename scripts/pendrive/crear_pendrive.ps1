# ============================================================
# Sistema de Gestion de Llaves FCEA v2.0
# Generador unificado de pendrive (4 tipos)
# ============================================================
# Uso:
#   .\crear_pendrive.ps1 -Drive D: -Tipo instalador
#   .\crear_pendrive.ps1 -Drive D: -Tipo instalador -PbDataPath C:\sistema-llaves-fcea\pocketbase\pb_data
#   .\crear_pendrive.ps1 -Drive E: -Tipo recuperacion -PbDataPath C:\sistema-llaves-fcea\pocketbase\pb_data
#   .\crear_pendrive.ps1 -Drive F: -Tipo codigo-fuente
#   .\crear_pendrive.ps1 -Drive D: -Tipo actualizar-datos
#
# Tipos:
#   instalador        -> Pendrive AUTONOMO de recuperacion ante desastres:
#                        codigo + pb_data + pb_backups + Node.js portable
#                        + DESINSTALAR.bat. Permite reconstruir el sistema
#                        completo desde cero en una PC nueva.
#   actualizar-datos  -> Refresca SOLO pb_data y pb_backups del pendrive
#                        instalador existente. Para uso semanal.
#   recuperacion      -> Pendrive con backup de pb_data + scripts de
#                        diagnostico/reparacion + DESINSTALAR.bat.
#                        Para restaurar una instalacion existente.
#   codigo-fuente     -> Pendrive de archivo/auditoria con todo el
#                        codigo fuente, .git, docs y zip + SHA256.
#                        No se instala desde aqui; es para custodia.
# ============================================================

#Requires -Version 5.1

param(
  [Parameter(Mandatory=$true)]
  [string]$Drive,

  [Parameter(Mandatory=$true)]
  [ValidateSet("instalador","recuperacion","codigo-fuente","actualizar-datos")]
  [string]$Tipo,

  # Ruta del pb_data productivo. Si se omite, se usa el del repo actual.
  [string]$PbDataPath = "",

  # Si se especifica, se omite la descarga de Node.js portable
  # (utilizado para regenerar el pendrive cuando ya existe localmente).
  [switch]$SinNode = $false,

  # Si se especifica, no se pide confirmacion interactiva.
  [switch]$Force = $false
)


$ErrorActionPreference = "Stop"

# Normalizar la letra de unidad (con ":\")
if ($Drive -notmatch ":\\?$") {
  $Drive = $Drive.TrimEnd(":") + ":\"
} elseif ($Drive -notmatch "\\$") {
  $Drive = $Drive + "\"
}

if (-not (Test-Path $Drive)) {
  Write-Host "[ERROR] La unidad $Drive no esta disponible." -ForegroundColor Red
  exit 1
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

# Si no se especifica PbDataPath, usar el del repo (asumiendo que es la PC productiva)
if (-not $PbDataPath) {
  $PbDataPath = Join-Path $repoRoot "pocketbase\pb_data"
}
$PbBackupsPath = Join-Path $repoRoot "pocketbase\pb_backups"

Write-Host ""
Write-Host "============================================================"
Write-Host " Generador de pendrive FCEA v2.0 - Recuperacion ante Desastres"
Write-Host "============================================================"
Write-Host " Tipo  : $Tipo"
Write-Host " Drive : $Drive"
Write-Host " Repo  : $repoRoot"
if ($Tipo -eq "instalador" -or $Tipo -eq "recuperacion" -or $Tipo -eq "actualizar-datos") {
  Write-Host " Datos : $PbDataPath"
}
Write-Host "============================================================"
Write-Host ""

# ============================================================
# Funcion auxiliar: detener PocketBase si esta corriendo
# (para que data.db-wal se consolide en data.db y el backup sea consistente)
# ============================================================
function Detener-PocketBase {
  $procs = Get-Process pocketbase -ErrorAction SilentlyContinue
  if ($procs) {
    Write-Host "Deteniendo PocketBase para garantizar consistencia del backup..." -ForegroundColor Yellow
    $procs | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Host "PocketBase detenido."
  }
}

# ============================================================
# Funcion auxiliar: copiar DESINSTALAR.bat a la raiz del pendrive
# ============================================================
function Copiar-Desinstalador {
  param([string]$Destino)
  $src = Join-Path $repoRoot "scripts\install\DESINSTALAR.bat"
  if (Test-Path $src) {
    Copy-Item -Force -Path $src -Destination (Join-Path $Destino "DESINSTALAR.bat")
    Write-Host "DESINSTALAR.bat copiado a la raiz del pendrive."
  } else {
    Write-Host "[AVISO] No se encontro scripts\install\DESINSTALAR.bat en el repo." -ForegroundColor Yellow
  }
}

# ============================================================
# Funcion auxiliar: copiar pb_data y pb_backups al pendrive
# Genera ULTIMO_BACKUP.txt con metadatos
# ============================================================
function Copiar-DatosProductivos {
  param(
    [string]$Destino,        # raiz donde va sistema-llaves-fcea\pocketbase\
    [bool]$EnRaiz = $false   # si true, guarda en backup_pb_data\ (recuperacion)
  )

  if (-not (Test-Path $PbDataPath)) {
    Write-Host "[AVISO] pb_data no existe en $PbDataPath. Se omite respaldo de datos." -ForegroundColor Yellow
    return $null
  }

  $dbFile = Join-Path $PbDataPath "data.db"
  if (-not (Test-Path $dbFile)) {
    Write-Host "[AVISO] No se encontro data.db en $PbDataPath. Se omite." -ForegroundColor Yellow
    return $null
  }

  Detener-PocketBase

  if ($EnRaiz) {
    $destPbData    = Join-Path $Destino "backup_pb_data"
    $destPbBackups = Join-Path $Destino "backup_pb_backups"
  } else {
    $destPbData    = Join-Path $Destino "sistema-llaves-fcea\pocketbase\pb_data"
    $destPbBackups = Join-Path $Destino "sistema-llaves-fcea\pocketbase\pb_backups"
  }

  Write-Host "Copiando pb_data productivo a $destPbData..." -ForegroundColor Cyan
  New-Item -ItemType Directory -Force -Path $destPbData | Out-Null
  & robocopy $PbDataPath $destPbData /MIR /NFL /NDL /NJH /NJS /NP | Out-Null

  if (Test-Path $PbBackupsPath) {
    Write-Host "Copiando pb_backups historicos a $destPbBackups..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $destPbBackups | Out-Null
    & robocopy $PbBackupsPath $destPbBackups /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
  }

  # Calcular metadatos del backup
  $dbInfo  = Get-Item $dbFile
  $dbSizeMB = [math]::Round($dbInfo.Length / 1MB, 2)
  $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $hostname = $env:COMPUTERNAME
  $storageCount = 0
  $storageDir = Join-Path $PbDataPath "storage"
  if (Test-Path $storageDir) {
    $storageCount = (Get-ChildItem $storageDir -Recurse -File -ErrorAction SilentlyContinue).Count
  }

  # Intentar contar registros invocando PocketBase en modo CLI (opcional, puede fallar)
  $resumenRegistros = "No disponible (data.db binario - abrir en el sistema para inspeccionar)"

  $contenido = @"
=============================================================
 ULTIMO BACKUP - Sistema de Gestion de Llaves FCEA v2.0
=============================================================

Timestamp     : $stamp
Hostname      : $hostname
Origen        : $PbDataPath
Tamano data.db: $dbSizeMB MB
Archivos en storage\: $storageCount

Contenido (resumen):
  - data.db        : Base de datos SQLite (todas las tablas)
                     - lugares (llaves)
                     - vigilante
                     - usuarios_solicitantes
                     - usuarios_registrados
                     - solicitudes (autorizaciones)
                     - historial_llaves
                     - auditoria_llaves
                     - objetos_olvidados
                     - configuracion + sistema_config
                     - _admins (administradores)
  - data.db-shm    : Shared memory de WAL (si aplica)
  - data.db-wal    : Write-Ahead Log (si aplica)
  - logs.db        : Logs internos de PocketBase
  - storage\       : Archivos adjuntos ($storageCount archivos)

POLITICA DE ACTUALIZACION:
  Este pendrive debe regenerarse semanalmente (recomendado lunes)
  con el script ACTUALIZAR_DATOS.bat o con:
    .\scripts\pendrive\crear_pendrive.ps1 -Drive $Drive -Tipo actualizar-datos

  En caso de incendio/robo/falla total, este pendrive permite
  reconstruir el sistema con perdida maxima de 7 dias.

=============================================================
"@
  $contenido | Set-Content -Encoding UTF8 -Path (Join-Path $Destino "ULTIMO_BACKUP.txt")
  Write-Host "ULTIMO_BACKUP.txt generado (data.db = $dbSizeMB MB, $storageCount archivos en storage)." -ForegroundColor Green

  return @{
    Timestamp = $stamp
    DbSizeMB  = $dbSizeMB
    Storage   = $storageCount
  }
}

# ============================================================
# Funcion auxiliar: descargar y embeber Node.js portable
# ============================================================
function Copiar-NodePortable {
  param([string]$Destino)

  if ($SinNode) {
    Write-Host "[AVISO] Flag -SinNode activo: se omite Node.js portable." -ForegroundColor Yellow
    return
  }

  $nodeVersion = "v20.18.0"
  $nodeZip = "node-$nodeVersion-win-x64.zip"
  $cacheDir = Join-Path $env:LOCALAPPDATA "FCEA-pendrive-cache"
  New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
  $cachedZip = Join-Path $cacheDir $nodeZip

  if (-not (Test-Path $cachedZip)) {
    $url = "https://nodejs.org/dist/$nodeVersion/$nodeZip"
    Write-Host "Descargando Node.js portable ($nodeVersion) desde nodejs.org..." -ForegroundColor Cyan
    try {
      Invoke-WebRequest -Uri $url -OutFile $cachedZip -UseBasicParsing
    } catch {
      Write-Host "[AVISO] No se pudo descargar Node.js portable: $_" -ForegroundColor Yellow
      Write-Host "        El pendrive se generara sin Node embebido." -ForegroundColor Yellow
      Write-Host "        Para incluirlo: descargue manualmente $nodeZip a $cacheDir" -ForegroundColor Yellow
      return
    }
  } else {
    Write-Host "Node.js portable ya esta en cache local." -ForegroundColor Green
  }

  $nodeDest = Join-Path $Destino "node-portable"
  if (Test-Path $nodeDest) { Remove-Item -Recurse -Force $nodeDest }
  Write-Host "Extrayendo Node.js portable al pendrive..." -ForegroundColor Cyan
  Expand-Archive -Path $cachedZip -DestinationPath $nodeDest -Force

  # Renombrar carpeta interna a "node" para path predecible
  $extracted = Get-ChildItem $nodeDest -Directory | Select-Object -First 1
  if ($extracted -and $extracted.Name -ne "node") {
    Move-Item -Path $extracted.FullName -Destination (Join-Path $nodeDest "node")
  }
  Write-Host "Node.js portable embebido (~30 MB)." -ForegroundColor Green
}

# ============================================================
# TIPO: ACTUALIZAR-DATOS (refresco semanal rapido)
# ============================================================
if ($Tipo -eq "actualizar-datos") {

  # Verificar que el pendrive ya sea un instalador valido
  $pendriveRepo = Join-Path $Drive "sistema-llaves-fcea"
  if (-not (Test-Path $pendriveRepo)) {
    Write-Host "[ERROR] El pendrive $Drive no parece ser un instalador FCEA." -ForegroundColor Red
    Write-Host "        No se encontro sistema-llaves-fcea\. Use -Tipo instalador para generarlo desde cero." -ForegroundColor Red
    exit 1
  }

  Write-Host "Modo ACTUALIZAR-DATOS: refrescando solo pb_data y pb_backups del pendrive..."
  Write-Host "(El codigo fuente, Node.js portable y demas archivos no se tocan)"
  Write-Host ""

  $meta = Copiar-DatosProductivos -Destino $Drive -EnRaiz $false
  if ($meta) {
    Write-Host ""
    Write-Host "[OK] Datos actualizados en $Drive" -ForegroundColor Green
    Write-Host ("       Timestamp : " + $meta.Timestamp)
    Write-Host ("       data.db   : " + $meta.DbSizeMB + " MB")
    Write-Host ("       Archivos  : " + $meta.Storage + " en storage\")
  } else {
    Write-Host "[ERROR] No se pudieron copiar los datos." -ForegroundColor Red
    exit 1
  }

  Write-Host ""
  Write-Host "Pendrive listo. Puede expulsarlo con seguridad."
  exit 0
}

# ------------------------------------------------------------
# Para los demas tipos: confirmar y limpiar el pendrive
# ------------------------------------------------------------
if (-not $Force) {
  $confirm = Read-Host "ATENCION: se va a sobrescribir el pendrive $Drive. Continuar? [S/N]"
  if ($confirm -ne "S" -and $confirm -ne "s") {
    Write-Host "Cancelado."
    exit 0
  }
} else {
  Write-Host "Flag -Force activo: se omite confirmacion."
}


Write-Host "Limpiando contenido previo del pendrive..."
Get-ChildItem -Path $Drive -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -ne 'System Volume Information' -and $_.Name -ne '$RECYCLE.BIN' } |
  ForEach-Object { Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }

# ============================================================
# TIPO: INSTALADOR (DRP - Disaster Recovery Plan)
# Pendrive autonomo con TODO lo necesario para reconstruir
# el sistema desde una PC nueva sin conexion a internet.
# ============================================================
if ($Tipo -eq "instalador") {

  Write-Host "Generando pendrive INSTALADOR (autonomo - DRP)..."

  # 1) Copiar el repositorio SIN node_modules ni dist, pero CON pb_data y pb_backups.
  #    Excluimos directorios volatiles (logs en uso, respaldo previo, backups
  #    automaticos locales) y archivos abiertos (logs.db, .db-shm, .db-wal)
  #    para que robocopy no falle por archivos bloqueados.
  $exclude = @(
    "node_modules",
    "dist",
    ".git",
    "respaldo_pre_restauracion",
    "backups",
    "logs"
  )
  $excludeFiles = @(
    "logs.db",
    "logs.db-shm",
    "logs.db-wal",
    "data.db-shm",
    "data.db-wal",
    "*.tmp",
    "*.log"
  )
  Write-Host "Copiando codigo fuente del repo (excluyendo dirs: $($exclude -join ', '); files: $($excludeFiles -join ', '))..."
  $robocopyArgs = @(
    "$repoRoot",
    "$Drive\sistema-llaves-fcea",
    "/MIR",
    "/R:2", "/W:1",
    "/XD"
  ) + $exclude + @("/XF") + $excludeFiles + @("/NFL", "/NDL", "/NJH", "/NJS", "/NP")
  & robocopy @robocopyArgs | Out-Null
  # robocopy retorna 0-7 como exito; 8+ es error real. No abortamos por warnings.

  # 1.b) Si pb_data del workspace no se sincronizo via /MIR porque estaba abierto,
  # forzar copia consistente.
  $meta = Copiar-DatosProductivos -Destino $Drive -EnRaiz $false

  # 2) Embeber Node.js portable (~30 MB) para ser autonomo sin internet
  Copiar-NodePortable -Destino $Drive

  # 3) Lanzadores SIMPLES en la raiz: solo 2 .bat visibles
  #    - "INSTALAR SISTEMA.bat"   (instala o actualiza datos, auto-elevacion UAC)
  #    - "DESINSTALAR SISTEMA.bat"(desinstala, auto-elevacion UAC)
  #    Todo lo demas se oculta con atributo HIDDEN al final.

  $instalarLauncher = Join-Path $repoRoot "scripts\pendrive\INSTALAR_SISTEMA_launcher.bat"
  $desinstalarLauncher = Join-Path $repoRoot "scripts\pendrive\DESINSTALAR_SISTEMA_launcher.bat"

  if (Test-Path $instalarLauncher) {
    Copy-Item -Force -Path $instalarLauncher -Destination (Join-Path $Drive "INSTALAR SISTEMA.bat")
    Write-Host "INSTALAR SISTEMA.bat copiado a la raiz."
  } else {
    Write-Host "[AVISO] No se encontro INSTALAR_SISTEMA_launcher.bat en el repo." -ForegroundColor Yellow
  }

  # Carpeta "Documentacion" VISIBLE con todos los .md de docs/
  # Para que cualquiera pueda leer la documentacion sin instalar nada.
  $docsSrc  = Join-Path $repoRoot "docs"
  $docsDest = Join-Path $Drive "Documentacion"
  if (Test-Path $docsSrc) {
    Write-Host "Copiando documentacion (carpeta Documentacion VISIBLE)..." -ForegroundColor Cyan
    if (Test-Path $docsDest) { Remove-Item -Recurse -Force $docsDest }
    New-Item -ItemType Directory -Force -Path $docsDest | Out-Null
    & robocopy $docsSrc $docsDest /E /NFL /NDL /NJH /NJS /NP | Out-Null

    # Generar _LEEME_PRIMERO.txt como indice rapido
    @"
 Sistema de Gestion de Llaves FCEA - DOCUMENTACION

 Esta carpeta contiene TODA la documentacion del sistema en
 formato Markdown (.md). Se puede leer con cualquier editor
 de texto (Bloc de notas, Notepad++, VSCode, etc.).

 Para una mejor lectura con formato, abralos con:
   - Visual Studio Code (recomendado)
   - GitHub Markdown viewer (https://markdownlivepreview.com)
   - Cualquier visor de Markdown

 INDICE - QUE LEER PRIMERO?

 SI ES USUARIO FINAL (vigilancia, custodio):
   1) credenciales_sistema.md          - Usuario y password
   2) OPERACION.md                     - Manual de uso diario
   3) instructivo_acceso_dashboard.md  - Como ver reportes
   4) seguridad_identificacion_usuarios.md - Como se identifican
                                             los solicitantes

 SI ES TECNICO / ADMINISTRADOR:
   1) INSTALACION.md                   - Como instalar el sistema
   2) ARQUITECTURA.md                  - Como esta hecho por dentro
   3) guia_mantenimiento_paso_a_paso.md - Mantenimiento semanal
   4) plan_recuperacion_desastres.md   - Que hacer si falla todo
   5) install_config_format.md         - Formato de configuracion

 SI ES AUDITOR / AUTORIDAD:
   1) presentacion_autoridades.md      - Resumen ejecutivo
   2) SRS_Sistema_Gestion_Llaves_FCEA.md - Especificacion completa
   3) mantenimiento_resumen_ejecutivo.md - Resumen de mantenimiento
   4) estadisticas_avanzadas.md        - Reportes disponibles

 INDICE COMPLETO:
   INDICE_DOCUMENTACION.md             - Lista completa con resumenes

 PARA INSTALAR EL SISTEMA

 NO instale desde esta carpeta. Vaya a la raiz del pendrive
 y ejecute (como Administrador):

   INSTALAR SISTEMA.bat

"@ | Set-Content -Encoding UTF8 -Path (Join-Path $docsDest "_LEEME_PRIMERO.txt")

    Write-Host "Documentacion copiada (visible para cualquier usuario)." -ForegroundColor Green
  } else {
    Write-Host "[AVISO] No se encontro la carpeta docs\ en el repo." -ForegroundColor Yellow
  }

  if (Test-Path $desinstalarLauncher) {
    Copy-Item -Force -Path $desinstalarLauncher -Destination (Join-Path $Drive "DESINSTALAR SISTEMA.bat")
    Write-Host "DESINSTALAR SISTEMA.bat copiado a la raiz."
  } else {
    Write-Host "[AVISO] No se encontro DESINSTALAR_SISTEMA_launcher.bat en el repo." -ForegroundColor Yellow
  }

  @"
[autorun]
label=Sistema FCEA - Instalador
icon=sistema-llaves-fcea\public\favicon.ico
open=INSTALAR SISTEMA.bat
"@ | Set-Content -Encoding ASCII -Path (Join-Path $Drive "autorun.inf")


  # 4) LEEME.txt con instrucciones (mas detallado por ser DRP)
  $metaInfo = if ($meta) { "Backup incluido: " + $meta.Timestamp + " (data.db = " + $meta.DbSizeMB + " MB)" } else { "Sin datos incluidos (instalacion inicial)" }
  @"
=============================================================
 PENDRIVE INSTALADOR DRP - Sistema de Gestion de Llaves FCEA v2.0
=============================================================

PROPOSITO:
  Pendrive AUTONOMO de Recuperacion ante Desastres (DRP).
  Permite reconstruir el sistema completo en una PC nueva
  SIN conexion a internet y SIN dependencias externas.

  $metaInfo

CONTENIDO:
  - sistema-llaves-fcea\              : Repositorio completo del sistema
      |- src\                         Codigo fuente React + TypeScript
      |- pocketbase\                  PocketBase + DATOS PRODUCTIVOS
      |   |- pocketbase.exe
      |   |- pb_data\                 *** TUS DATOS REALES ***
      |   |   |- data.db              (llaves, vigilantes, historial, ...)
      |   |   |- storage\             (archivos adjuntos, fotos)
      |   |- pb_backups\              Backups historicos
      |   |- pb_migrations\           Migraciones de BD
      |- public\, scripts\, docs\     Frontend, scripts y documentacion
  - node-portable\                    Node.js LTS portable (sin instalacion)
  - INSTALAR.bat                      Lanzador del instalador
  - DESINSTALAR.bat                   Desinstalador (respalda datos en C:\backup_fcea_<fecha>\)
  - ACTUALIZAR_DATOS.bat              Refresca pb_data del pendrive semanalmente
  - ULTIMO_BACKUP.txt                 Metadatos del backup incluido
  - autorun.inf                       Autorun (si Windows lo permite)

INSTRUCCIONES DE INSTALACION (incendio / hardware nuevo / DRP):
  1) En la PC nueva (Windows 10/11), conectar este pendrive.
  2) Click DERECHO en INSTALAR.bat -> "Ejecutar como administrador".
  3) Seleccionar modo de instalacion:
       [1] Desarrollo (1 PC con monitor + terminal)
       [2] Produccion economica (3 PCs con teclado/mouse)
       [3] Produccion mixta (cabina tactil + 2 terminales)
       [4] Produccion ideal (3 PCs tactiles)
  4) Si elige modos 2, 3 o 4: indicar el rol de la PC
     (S = Servidor/Monitor, A/B = Terminal, D = Dashboard).
  5) Al final, el instalador preguntara:
        "Se detectaron datos productivos (fecha XXX).
         Restaurar TODOS los datos? [S/N]"
     Responder S para recuperar las 100+ llaves, vigilantes,
     historial completo, autorizaciones, objetos olvidados, etc.

  TIEMPO ESTIMADO TOTAL: 15 a 30 minutos por PC.

POLITICA DE ACTUALIZACION SEMANAL (CRITICA):
  Este pendrive es el seguro de continuidad operativa. DEBE
  actualizarse SEMANALMENTE para que el backup este al dia.

  Procedimiento (cada lunes, despues del backup automatico):
  1) Conectar el pendrive en la PC de la cabina.
  2) Doble click en ACTUALIZAR_DATOS.bat (como Administrador).
  3) El script copia el pb_data actual al pendrive en ~30 seg.
  4) Verificar que ULTIMO_BACKUP.txt muestre la fecha de hoy.

  PERDIDA MAXIMA: 7 dias de movimientos (si la actualizacion
  se cumple). Sin actualizacion semanal, la perdida crece.

INSTRUCCIONES DE DESINSTALACION:
  1) Conectar el pendrive en la PC con el sistema instalado.
  2) Click derecho en DESINSTALAR.bat -> "Ejecutar como administrador".
  3) Confirmar escribiendo SI.
  4) Los datos (pb_data, pb_backups y config.json) quedan
     respaldados automaticamente en C:\backup_fcea_<fecha>\

REQUISITOS PREVIOS:
  - Windows 10/11
  - Privilegios de administrador (para abrir el puerto 8090)
  - Conexion a internet NO requerida (Node.js esta embebido)

SOPORTE:
  Lea docs\plan_recuperacion_desastres.md
  y docs\INSTALACION.md dentro de sistema-llaves-fcea\
=============================================================
"@ | Set-Content -Encoding UTF8 -Path (Join-Path $Drive "LEEME.txt")

  # 5) Ocultar todo lo auxiliar: solo deben verse los 2 .bat principales.
  #    Aplicamos atributo +H (hidden) +S (system) para que ni siquiera
  #    aparezcan con "Mostrar elementos ocultos" hasta que se active
  #    "Mostrar archivos protegidos del sistema operativo".
  Write-Host "Ocultando archivos auxiliares (solo se veran los 2 .bat principales)..."
  $itemsAOcultar = @(
    "sistema-llaves-fcea",
    "node-portable",
    "autorun.inf",
    "LEEME.txt",
    "ULTIMO_BACKUP.txt"
  )
  foreach ($it in $itemsAOcultar) {
    $p = Join-Path $Drive $it
    if (Test-Path $p) {
      try {
        attrib +H +S $p /S /D 2>$null | Out-Null
        # Tambien el item raiz (attrib /D solo aplica a contenidos):
        $item = Get-Item -LiteralPath $p -Force
        $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System
      } catch {
        Write-Host ("[AVISO] No se pudo ocultar " + $it + ": " + $_) -ForegroundColor Yellow
      }
    }
  }
  Write-Host "Listo: solo 'INSTALAR SISTEMA.bat' y 'DESINSTALAR SISTEMA.bat' quedan visibles." -ForegroundColor Green

  Write-Host ""
  Write-Host "[OK] Pendrive INSTALADOR DRP generado correctamente en $Drive" -ForegroundColor Green
  $size = (Get-ChildItem $Drive -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
  Write-Host ("       Tamano aproximado: {0:N1} MB" -f $size)

}
# ============================================================
# TIPO: RECUPERACION

# ============================================================
elseif ($Tipo -eq "recuperacion") {

  Write-Host "Generando pendrive RECUPERACION..."

  # 1) Backup de pb_data y pb_backups
  $meta = Copiar-DatosProductivos -Destino $Drive -EnRaiz $true

  if ($meta) {
    $stampDir = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    Set-Content -Path (Join-Path $Drive "backup_pb_data\BACKUP_TIMESTAMP.txt") -Value $stampDir
  }

  # 2) Copiar scripts de recuperacion
  $recoveryScripts = Join-Path $Drive "scripts"
  New-Item -ItemType Directory -Force -Path $recoveryScripts | Out-Null
  Copy-Item -Force -Path (Join-Path $repoRoot "scripts\recovery\*") -Destination $recoveryScripts -ErrorAction SilentlyContinue

  # 3) Lanzador raiz + desinstalador
  @"
@echo off
REM Lanzador del menu de recuperacion FCEA
cd /d "%~dp0"
call scripts\RECUPERAR.bat
"@ | Set-Content -Encoding ASCII -Path (Join-Path $Drive "RECUPERAR.bat")

  Copiar-Desinstalador -Destino $Drive

  @"
[autorun]
label=Sistema FCEA - Recuperacion
open=RECUPERAR.bat
"@ | Set-Content -Encoding ASCII -Path (Join-Path $Drive "autorun.inf")

  @"
=============================================================
 PENDRIVE RECUPERACION - Sistema de Gestion de Llaves FCEA v2.0
=============================================================

CONTENIDO:
  - backup_pb_data\        : Respaldo de la base de datos
  - backup_pb_backups\     : Backups historicos (si aplica)
  - scripts\               : Scripts de diagnostico y reparacion
  - RECUPERAR.bat          : Menu principal de recuperacion
  - DESINSTALAR.bat        : Desinstalador limpio (preserva datos)
  - ULTIMO_BACKUP.txt      : Metadatos del backup

DIFERENCIA con el pendrive INSTALADOR:
  - El de RECUPERACION solo restaura datos en una instalacion
    existente; no instala el sistema desde cero.
  - El INSTALADOR es autonomo (codigo + datos + Node.js).

INSTRUCCIONES:
  1) Conecte este pendrive en la PC con problemas.
  2) Ejecute RECUPERAR.bat (como Administrador).
  3) Elija una opcion del menu:
       [1] Diagnostico del sistema
       [2] Restaurar base de datos desde backup
       [3] Reparar PocketBase (verificar puerto, firewall, etc.)
       [4] Reinstalar frontend (npm install + build)
       [5] Salir

ADVERTENCIA:
  Antes de restaurar la base de datos, se hace un backup
  automatico de la base actual en respaldo_pre_restauracion\
=============================================================
"@ | Set-Content -Encoding UTF8 -Path (Join-Path $Drive "LEEME.txt")

  Write-Host ""
  Write-Host "[OK] Pendrive RECUPERACION generado correctamente en $Drive" -ForegroundColor Green

}
# ============================================================
# TIPO: CODIGO-FUENTE (archivo / auditoria / continuidad)
# ============================================================
elseif ($Tipo -eq "codigo-fuente") {

  Write-Host "Generando pendrive CODIGO FUENTE..."

  # 1) Copiar repo completo (incluye .git para historial), sin node_modules
  $exclude = @("node_modules", "dist", "pb_data", "pb_backups", "respaldo_pre_restauracion")
  Write-Host "Copiando repositorio completo (con .git, excluyendo $($exclude -join ', '))..."
  $robocopyArgs = @(
    "$repoRoot",
    "$Drive\sistema-llaves-fcea",
    "/MIR",
    "/XD"
  ) + $exclude + @("/NFL", "/NDL", "/NJH", "/NJS", "/NP")
  & robocopy @robocopyArgs | Out-Null

  # 2) Crear ZIP comprimido del repo (para distribucion alternativa)
  Write-Host "Creando archivo .zip del codigo fuente..."
  $zipPath = Join-Path $Drive "sistema-llaves-fcea_codigo-fuente.zip"
  Compress-Archive -Path (Join-Path $Drive "sistema-llaves-fcea\*") `
                   -DestinationPath $zipPath -Force

  # 3) Calcular hash SHA256 del ZIP para verificar integridad
  Write-Host "Calculando hash SHA256 para verificacion de integridad..."
  $hash = Get-FileHash -Path $zipPath -Algorithm SHA256
  $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $commitHash = ""
  try {
    Push-Location $repoRoot
    $commitHash = (git rev-parse HEAD 2>$null)
    Pop-Location
  } catch { }

  @"
Archivo  : sistema-llaves-fcea_codigo-fuente.zip
SHA256   : $($hash.Hash)
Fecha    : $stamp
Commit   : $commitHash

Para verificar la integridad del archivo en otra PC:
  PowerShell> Get-FileHash sistema-llaves-fcea_codigo-fuente.zip -Algorithm SHA256
El hash debe coincidir EXACTAMENTE con el indicado arriba.
"@ | Set-Content -Encoding UTF8 -Path (Join-Path $Drive "SHA256.txt")

  # 4) LEEME.txt
  @"
=============================================================
 PENDRIVE CODIGO FUENTE - Sistema de Gestion de Llaves FCEA v2.0
=============================================================

PROPOSITO:
  Este pendrive contiene el CODIGO FUENTE COMPLETO del sistema,
  incluyendo el historial de versiones (.git) y la documentacion.

  Esta destinado a CUSTODIA / ARCHIVO / CONTINUIDAD del proyecto.
  NO es un pendrive de instalacion: para instalar el sistema
  utilice el pendrive INSTALADOR.

CONTENIDO:
  - sistema-llaves-fcea\                       : Repositorio completo
      |- src\           Codigo fuente React + TypeScript
      |- pocketbase\    Binario PocketBase y migraciones
      |- scripts\       Scripts de instalacion / mantenimiento
      |- docs\          Documentacion (15+ archivos)
      |- .git\          Historial completo de versiones
  - sistema-llaves-fcea_codigo-fuente.zip       : Archivo comprimido
  - SHA256.txt                                  : Hash para verificar
                                                  integridad del ZIP

COMO LEVANTAR EL CODIGO EN OTRA PC:
  1) Instale Node.js LTS desde https://nodejs.org
  2) Copie la carpeta sistema-llaves-fcea\ a su PC.
  3) Abra una terminal en esa carpeta y ejecute:
       npm install
       npm run dev
  4) Inicie PocketBase:
       cd pocketbase
       pocketbase.exe serve
  5) Abra http://localhost:5173 en el navegador.

STACK TECNOLOGICO:
  - Frontend : React 18 + TypeScript + Vite + Tailwind CSS
  - UI       : shadcn/ui + Radix UI + Recharts
  - Backend  : PocketBase (Go) sobre SQLite
  - Sin servicios externos, sin licencias, 100% open source.

VERIFICACION DE INTEGRIDAD:
  En PowerShell:
    Get-FileHash sistema-llaves-fcea_codigo-fuente.zip -Algorithm SHA256
  Compare con el hash indicado en SHA256.txt.

=============================================================
 Este pendrive debe conservarse bajo custodia institucional.
=============================================================
"@ | Set-Content -Encoding UTF8 -Path (Join-Path $Drive "LEEME.txt")

  Write-Host ""
  Write-Host "[OK] Pendrive CODIGO FUENTE generado correctamente en $Drive" -ForegroundColor Green
  $size = (Get-ChildItem $Drive -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
  Write-Host ("       Tamano aproximado: {0:N1} MB" -f $size)
  Write-Host ("       SHA256: " + $hash.Hash)
}

Write-Host ""
Write-Host "Pendrive listo. Puede expulsarlo con seguridad."
Write-Host ""
