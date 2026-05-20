# ============================================================
# Sistema de Gestion de Llaves FCEA v2.0
# Generador unificado de pendrive
# ============================================================
# Uso:
#   .\crear_pendrive.ps1 -Drive E: -Tipo instalador
#   .\crear_pendrive.ps1 -Drive F: -Tipo recuperacion -PbDataPath C:\...\pb_data
#
# Tipos:
#   instalador   → Pendrive arrancable con el repo + Node.js installer.
#                  Sirve para una instalacion limpia en una PC nueva.
#   recuperacion → Pendrive con backup de pb_data + scripts de
#                  diagnostico y reparacion. Para emergencias.
# ============================================================

#Requires -Version 5.1

param(
  [Parameter(Mandatory=$true)]
  [string]$Drive,

  [Parameter(Mandatory=$true)]
  [ValidateSet("instalador","recuperacion")]
  [string]$Tipo,

  # Solo para -Tipo recuperacion: ruta a pb_data del servidor.
  [string]$PbDataPath = ""
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

Write-Host ""
Write-Host "============================================================"
Write-Host " Generador de pendrive FCEA v2.0"
Write-Host "============================================================"
Write-Host " Tipo  : $Tipo"
Write-Host " Drive : $Drive"
Write-Host " Repo  : $repoRoot"
Write-Host "============================================================"
Write-Host ""

# ------------------------------------------------------------
# Confirmacion del usuario (este script borra contenido del drive)
# ------------------------------------------------------------
$confirm = Read-Host "ATENCION: se va a sobrescribir el pendrive $Drive. Continuar? [S/N]"
if ($confirm -ne "S" -and $confirm -ne "s") {
  Write-Host "Cancelado."
  exit 0
}

# ------------------------------------------------------------
# Limpieza del pendrive (excepto System Volume Information)
# ------------------------------------------------------------
Write-Host "Limpiando contenido previo del pendrive..."
Get-ChildItem -Path $Drive -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -ne 'System Volume Information' -and $_.Name -ne '$RECYCLE.BIN' } |
  ForEach-Object { Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }

if ($Tipo -eq "instalador") {

  # ----------------------------------------------------------
  # PENDRIVE INSTALADOR
  # ----------------------------------------------------------
  Write-Host "Generando pendrive INSTALADOR..."

  # 1) Copiar el repositorio (sin node_modules, sin dist, sin .git)
  $exclude = @("node_modules", "dist", ".git", "pb_data", "respaldo_pre_restauracion")
  Write-Host "Copiando codigo fuente del repo (excluyendo $($exclude -join ', '))..."
  $robocopyArgs = @(
    "$repoRoot",
    "$Drive\sistema-llaves-fcea",
    "/MIR",
    "/XD"
  ) + $exclude + @("/NFL", "/NDL", "/NJH", "/NJS", "/NP")
  & robocopy @robocopyArgs | Out-Null

  # 2) Crear autorun.inf y un INSTALAR.bat raiz que llame al instalador
  @"
@echo off
REM Lanzador del instalador FCEA
cd /d "%~dp0\sistema-llaves-fcea"
call scripts\install\INSTALAR.bat
"@ | Set-Content -Encoding ASCII -Path (Join-Path $Drive "INSTALAR.bat")

  @"
[autorun]
label=Sistema FCEA - Instalador
icon=sistema-llaves-fcea\public\favicon.ico
open=INSTALAR.bat
"@ | Set-Content -Encoding ASCII -Path (Join-Path $Drive "autorun.inf")

  # 3) LEEME.txt con instrucciones
  @"
=============================================================
 PENDRIVE INSTALADOR - Sistema de Gestion de Llaves FCEA v2.0
=============================================================

CONTENIDO:
  - sistema-llaves-fcea\   : Codigo fuente completo del sistema
  - INSTALAR.bat           : Lanzador del instalador
  - autorun.inf            : Autorun (si esta habilitado en la PC)

INSTRUCCIONES:
  1) Conecte este pendrive a la PC de destino.
  2) Si no inicia automaticamente, abra el pendrive y haga
     doble click en INSTALAR.bat.
  3) Seleccione el modo de instalacion:
       [1] Desarrollo (1 PC con monitor + terminal)
       [2] Produccion economica (3 PCs con teclado/mouse)
       [3] Produccion mixta (cabina tactil + 2 terminales)
       [4] Produccion ideal (3 PCs tactiles)
  4) Si elige modos 2, 3 o 4: indique el rol de esta PC
     (Servidor/Monitor, Terminal-A, Terminal-B o Dashboard).

REQUISITOS PREVIOS:
  - Windows 10/11
  - Conexion a internet (para descargar Node.js si no esta instalado)
  - Privilegios de administrador (para abrir el puerto 8090)

SOPORTE:
  Lea docs\INSTALACION.md dentro de sistema-llaves-fcea\
=============================================================
"@ | Set-Content -Encoding UTF8 -Path (Join-Path $Drive "LEEME.txt")

  Write-Host ""
  Write-Host "[OK] Pendrive INSTALADOR generado correctamente en $Drive" -ForegroundColor Green
  Write-Host "     Tamano aproximado del contenido:"
  $size = (Get-ChildItem $Drive -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
  Write-Host ("       {0:N1} MB" -f $size)

} else {

  # ----------------------------------------------------------
  # PENDRIVE RECUPERACION
  # ----------------------------------------------------------
  Write-Host "Generando pendrive RECUPERACION..."

  # 1) Backup de pb_data si se proporciono ruta
  if ($PbDataPath -and (Test-Path $PbDataPath)) {
    $backupDir = Join-Path $Drive "backup_pb_data"
    Write-Host "Respaldando pb_data desde $PbDataPath..."
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    Copy-Item -Recurse -Force -Path "$PbDataPath\*" -Destination $backupDir
    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    Set-Content -Path (Join-Path $backupDir "BACKUP_TIMESTAMP.txt") -Value $stamp
    Write-Host "[OK] Backup completado ($stamp)"
  } else {
    Write-Host "[AVISO] No se proporciono -PbDataPath o no existe. Sin backup de datos."
  }

  # 2) Copiar scripts de recuperacion
  $recoveryScripts = Join-Path $Drive "scripts"
  New-Item -ItemType Directory -Force -Path $recoveryScripts | Out-Null
  Copy-Item -Force -Path (Join-Path $repoRoot "scripts\recovery\*") -Destination $recoveryScripts -ErrorAction SilentlyContinue

  # 3) Lanzador raiz
  @"
@echo off
REM Lanzador del menu de recuperacion FCEA
cd /d "%~dp0"
call scripts\RECUPERAR.bat
"@ | Set-Content -Encoding ASCII -Path (Join-Path $Drive "RECUPERAR.bat")

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
  - backup_pb_data\        : Respaldo de la base de datos (si aplica)
  - scripts\               : Scripts de diagnostico y reparacion
  - RECUPERAR.bat          : Menu principal de recuperacion

INSTRUCCIONES:
  1) Conecte este pendrive en la PC con problemas.
  2) Ejecute RECUPERAR.bat.
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

Write-Host ""
Write-Host "Pendrive listo. Puede expulsarlo con seguridad."
Write-Host ""
