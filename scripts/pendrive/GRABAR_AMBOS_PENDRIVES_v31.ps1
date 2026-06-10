# ============================================================
#  Grabador unificado de los DOS pendrives FCEA v3.1
# ============================================================
#  Detecta los pendrives por VOLUMENLABEL, no por letra:
#    - INSTALADOR_LLAVES_FCEA  -> pendrive instalador
#    - RECUPERACION_FCEA       -> pendrive recuperador
#
#  Por eso es robusto a que Windows asigne D:/E: en orden distinto.
#
#  Que graba:
#    Pendrive instalador (INSTALADOR_LLAVES_FCEA):
#      - codigo fuente (sin node_modules, sin .git, sin dist viejo)
#      - dist\ recien compilado
#      - pocketbase.exe + pb_migrations + pb_data productivo (snapshot)
#      - node-portable\ si existe en el repo
#      - launchers: INSTALAR SISTEMA.bat, DESINSTALAR SISTEMA.bat,
#                   RECUPERAR SISTEMA.bat
#      - Documentacion\*.md
#      - LEEME_PRIMERO.txt
#
#    Pendrive recuperador (RECUPERACION_FCEA):
#      Lo mismo que el instalador (es un clon - asi una sola persona
#      puede recuperar O reinstalar con cualquiera de los dos).
#
#  IMPORTANTE - flujo seguro:
#    1) Detiene PocketBase y procesos relacionados.
#    2) Espera 3 segundos a que se liberen los handles.
#    3) Copia pb_data persistente a una carpeta TEMPORAL.
#    4) Reanuda PocketBase (sistema vuelve a estar online).
#    5) Graba ambos pendrives desde la carpeta temporal.
#    6) Borra la carpeta temporal.
#
#  Asi el sistema solo queda offline ~10 segundos.
#
#  Uso:
#    powershell -ExecutionPolicy Bypass -File GRABAR_AMBOS_PENDRIVES_v31.ps1
#
# ============================================================

[CmdletBinding()]
param(
    [switch]$SoloInstalador,    # Solo graba el instalador
    [switch]$SoloRecuperador,   # Solo graba el recuperador
    [switch]$SinDetenerPB,      # No detiene PocketBase (datos pueden ser inconsistentes)
    [switch]$SinPbData          # No copia pb_data (sin snapshot de la BD)
)

$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "FCEA - Grabador de Pendrives v3.1"

# ============================================================
# UTILIDADES
# ============================================================
function W-Title($t)  { Write-Host ""; Write-Host ("  === " + $t + " ===") -ForegroundColor Cyan }
function W-Info($t)   { Write-Host ("      " + $t) -ForegroundColor Gray }
function W-Ok($t)     { Write-Host ("      [OK] " + $t) -ForegroundColor Green }
function W-Warn($t)   { Write-Host ("      [!]  " + $t) -ForegroundColor Yellow }
function W-Err($t)    { Write-Host ("      [X]  " + $t) -ForegroundColor Red }

function Pausa-Final {
    Write-Host ""
    Write-Host "  Presione cualquier tecla para cerrar..." -ForegroundColor Yellow
    try { $null = [System.Console]::ReadKey($true) } catch { Read-Host "ENTER" | Out-Null }
}

function Test-Admin {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $pp = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $pp.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Find-PendriveByLabel {
    param([string]$Label)
    $vol = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue |
        Where-Object { $_.DriveType -eq 2 -and $_.VolumeName -eq $Label }
    if ($vol) { return $vol.DeviceID }   # ej. "E:"
    return $null
}

function Find-AllPendrivesByLabels {
    # Busca TODOS los pendrives cuya etiqueta este en la lista pasada.
    # Devuelve un array de letras de unidad (ej. @("D:","E:")).
    param([string[]]$Labels)
    $vols = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue |
        Where-Object { $_.DriveType -eq 2 -and ($Labels -contains $_.VolumeName) }
    if ($vols) { return @($vols | ForEach-Object { $_.DeviceID }) }
    return @()
}

function Set-VolumeLabelSafe {
    # Renombra el volumen del pendrive a la etiqueta unificada.
    # Si ya tiene esa etiqueta, no hace nada.
    param([string]$Drive, [string]$Label)
    try {
        $vol = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$Drive'" -ErrorAction Stop
        if ($vol.VolumeName -ne $Label) {
            W-Info "Renombrando volumen $Drive ($($vol.VolumeName)) -> $Label"
            & cmd.exe /c "label $Drive $Label" 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                W-Ok "Volumen $Drive ahora se llama $Label"
            } else {
                W-Warn "No se pudo renombrar $Drive (codigo $LASTEXITCODE). Continuando."
            }
        }
    } catch {
        W-Warn "No se pudo renombrar $Drive : $($_.Exception.Message)"
    }
}

# ============================================================
# BLOQUE PRINCIPAL
# ============================================================
try {
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor White
    Write-Host "   Sistema de Gestion de Llaves FCEA - Grabador v3.1"          -ForegroundColor White
    Write-Host "  ============================================================" -ForegroundColor White
    Write-Host ""

    if (-not (Test-Admin)) {
        W-Err "Debe ejecutarse como ADMINISTRADOR."
        throw "No es admin."
    }
    W-Ok "Privilegios de administrador OK."

    # --------------------------------------------------------
    # 1) Detectar repo
    # --------------------------------------------------------
    $RepoDir = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
    W-Info "Repo: $RepoDir"
    if (-not (Test-Path (Join-Path $RepoDir "package.json"))) {
        throw "No parece ser la raiz del repo (falta package.json)."
    }
    if (-not (Test-Path (Join-Path $RepoDir "dist\index.html"))) {
        W-Warn "No existe dist\index.html. Ejecutando npm run build..."
        Push-Location $RepoDir
        try {
            & cmd.exe /c "npm run build"
            if ($LASTEXITCODE -ne 0) { throw "npm run build fallo." }
        } finally { Pop-Location }
        W-Ok "Frontend reconstruido."
    } else {
        W-Ok "dist\ ya existe (se usa el actual)."
    }

    # --------------------------------------------------------
    # 2) Detectar pendrives por etiqueta
    # --------------------------------------------------------
    # FILOSOFIA v3.2 (unificacion):
    #   Todos los pendrives FCEA tienen la MISMA etiqueta: "SISTEMA_FCEA".
    #   Son clones identicos: cada uno trae el instalador, el desinstalador,
    #   el recuperador, la documentacion completa y el codigo actualizado.
    #   Asi se pueden duplicar facilmente (basta con copiar contenido a otro
    #   pendrive y renombrar el volumen).
    #
    #   Para compatibilidad con pendrives viejos del v3.0/v3.1 que aun tengan
    #   las etiquetas "INSTALADOR_LLAVES_FCEA" o "RECUPERACION_FCEA", tambien
    #   los detectamos y los renombramos automaticamente.
    W-Title "DETECCION DE PENDRIVES (etiqueta unificada SISTEMA_FCEA)"

    $etiquetasValidas = @("SISTEMA_FCEA", "INSTALADOR_LLAVES_FCEA", "RECUPERACION_FCEA")
    $drvList = Find-AllPendrivesByLabels -Labels $etiquetasValidas

    if ($drvList.Count -eq 0) {
        W-Warn "No se detecto ningun pendrive con etiqueta valida."
        W-Info "Etiquetas reconocidas: $($etiquetasValidas -join ', ')"
        throw "Conecte al menos un pendrive con etiqueta SISTEMA_FCEA y vuelva a ejecutar."
    }

    W-Ok ("Pendrives detectados: " + ($drvList -join ", "))

    # Compatibilidad con los flags viejos -SoloInstalador / -SoloRecuperador:
    # ahora solo limitamos cuantos pendrives grabamos.
    if ($SoloInstalador -or $SoloRecuperador) {
        $drvList = @($drvList[0])
        W-Info "Modo: SOLO un pendrive ($($drvList[0]))"
    }

    # --------------------------------------------------------
    # 3) Snapshot de pb_data persistente
    # --------------------------------------------------------
    W-Title "SNAPSHOT DE pb_data PRODUCTIVO"
    $PersistData = "C:\ProgramData\FCEA-Sistema-Llaves\pb_data"
    $stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $tmpSnap = Join-Path $env:TEMP "fcea_pb_data_snapshot_$stamp"

    $copiarPbData = -not $SinPbData
    if ($copiarPbData -and -not (Test-Path $PersistData)) {
        W-Warn "No existe pb_data persistente en $PersistData."
        W-Warn "Se grabaran los pendrives sin snapshot de la BD."
        $copiarPbData = $false
    }

    if ($copiarPbData) {
        if (-not $SinDetenerPB) {
            W-Info "Deteniendo PocketBase para hacer snapshot consistente..."
            try {
                Get-Process pocketbase -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            } catch { }
            Start-Sleep -Seconds 3
            W-Ok "PocketBase detenido."
        } else {
            W-Warn "NO se detiene PocketBase (puede haber inconsistencia en el snapshot)."
        }

        W-Info "Copiando pb_data a $tmpSnap..."
        New-Item -ItemType Directory -Force -Path $tmpSnap | Out-Null
        & robocopy $PersistData $tmpSnap /MIR /R:2 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
        if ($LASTEXITCODE -ge 8) {
            throw "robocopy fallo al copiar pb_data (codigo $LASTEXITCODE)."
        }
        W-Ok "Snapshot listo en $tmpSnap"

        # Reanudar PocketBase YA, antes de grabar los pendrives
        # (asi el sistema solo queda offline ~10 segundos).
        if (-not $SinDetenerPB) {
            W-Info "Reanudando PocketBase..."
            $pbExe = "C:\sistema-llaves-fcea\pocketbase\pocketbase.exe"
            if (Test-Path $pbExe) {
                # Lanzar via start-server.bat para que use --dir correcto
                $startBat = "C:\sistema-llaves-fcea\pocketbase\start-server.bat"
                if (Test-Path $startBat) {
                    Start-Process -FilePath "cmd.exe" `
                                  -ArgumentList "/c", "`"$startBat`"" `
                                  -WindowStyle Minimized `
                                  -WorkingDirectory "C:\sistema-llaves-fcea\pocketbase"
                    Start-Sleep -Seconds 3
                    W-Ok "PocketBase reanudado."
                } else {
                    W-Warn "No se encontro start-server.bat - hay que arrancar PocketBase manualmente."
                }
            } else {
                W-Warn "No hay pocketbase.exe instalado en C:\sistema-llaves-fcea\pocketbase\"
            }
        }
    } else {
        W-Info "Omitido snapshot de pb_data."
    }

    # --------------------------------------------------------
    # 4) Funcion: grabar UN pendrive
    # --------------------------------------------------------
    function Grabar-Pendrive {
        param(
            [string]$Drive,           # ej "E:"
            [string]$TipoNombre,      # "instalador" / "recuperador"
            [string]$RepoDir,
            [string]$SnapDir,
            [bool]$CopiarPbData
        )

        W-Title "GRABANDO PENDRIVE $TipoNombre EN $Drive"

        $DriveRoot = $Drive + "\"
        $DestRepo  = $DriveRoot + "sistema-llaves-fcea"
        $DestDocs  = $DriveRoot + "Documentacion"

        # Verificar espacio
        try {
            $driveInfo = Get-PSDrive ($Drive.TrimEnd(":")) -ErrorAction Stop
            $freeGB = [math]::Round($driveInfo.Free / 1GB, 2)
            W-Info "Espacio libre en $Drive : $freeGB GB"
            if ($freeGB -lt 0.5) {
                W-Warn "Poco espacio libre. Continuando igual."
            }
        } catch { }

        # ----- 4a) Estructura base
        W-Info "Creando estructura de carpetas..."
        if (-not (Test-Path $DestRepo)) {
            New-Item -ItemType Directory -Force -Path $DestRepo | Out-Null
        }
        if (-not (Test-Path $DestDocs)) {
            New-Item -ItemType Directory -Force -Path $DestDocs | Out-Null
        }

        # ----- 4b) Copiar codigo fuente del repo (excluye node_modules, .git, dist viejo, pb_data)
        W-Info "Copiando codigo del repo (sin node_modules, sin .git)..."
        $excluir = @(
            "node_modules", ".git", ".github", ".vscode",
            "pocketbase\pb_data",                   # pb_data va aparte (snapshot)
            "pocketbase\pb_backups",                # backups locales no van al pendrive
            "pocketbase\pb_data.MIGRADO_*"          # backups de migracion no van
        )
        $robocopyXD = @()
        foreach ($e in $excluir) {
            $robocopyXD += "/XD"
            $robocopyXD += (Join-Path $RepoDir $e)
        }
        & robocopy $RepoDir $DestRepo /MIR /R:2 /W:1 /NFL /NDL /NJH /NJS /NP `
            /XD "$RepoDir\node_modules" `
            /XD "$RepoDir\.git" `
            /XD "$RepoDir\.github" `
            /XD "$RepoDir\.vscode" `
            /XD "$RepoDir\pocketbase\pb_data" `
            /XD "$RepoDir\pocketbase\pb_backups" `
            /XF "$RepoDir\bun.lockb" | Out-Null
        # Codigo robocopy: <8 = OK, >=8 = error
        if ($LASTEXITCODE -ge 8) {
            W-Warn "robocopy (codigo $LASTEXITCODE). Continuando."
        } else {
            W-Ok "Codigo fuente copiado."
        }

        # Limpiar carpetas de migraciones legacy en el destino (por si quedaron de
        # grabaciones anteriores)
        Get-ChildItem -Path "$DestRepo\pocketbase" -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "pb_data.MIGRADO_*" } |
            ForEach-Object {
                W-Info "Borrando legacy: $($_.FullName)"
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }

        # ----- 4c) Copiar pb_data productivo (snapshot)
        if ($CopiarPbData -and (Test-Path $SnapDir)) {
            W-Info "Copiando snapshot de pb_data al pendrive..."
            $destPbData = "$DestRepo\pocketbase\pb_data"
            if (-not (Test-Path $destPbData)) {
                New-Item -ItemType Directory -Force -Path $destPbData | Out-Null
            }
            & robocopy $SnapDir $destPbData /MIR /R:2 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
            if ($LASTEXITCODE -ge 8) {
                W-Warn "robocopy pb_data codigo $LASTEXITCODE"
            } else {
                $dbFile = Join-Path $destPbData "data.db"
                if (Test-Path $dbFile) {
                    $sizeKB = [math]::Round(((Get-Item $dbFile).Length / 1KB), 1)
                    W-Ok "pb_data copiado (data.db = $sizeKB KB)."
                } else {
                    W-Warn "Copia hecha pero no veo data.db en el destino."
                }
            }
        }

        # ----- 4d) Documentacion en la raiz
        W-Info "Copiando Documentacion\..."
        $docsRepo = Join-Path $RepoDir "docs"
        if (Test-Path $docsRepo) {
            & robocopy $docsRepo $DestDocs *.md /R:2 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
            W-Ok "Documentacion copiada."
        }

        # ----- 4e) Launchers a la vista (en la raiz)
        W-Info "Copiando launchers al root del pendrive..."

        $launchers = @(
            @{ Origen = "scripts\pendrive\INSTALAR_SISTEMA_launcher.bat";   Destino = "INSTALAR SISTEMA.bat" },
            @{ Origen = "scripts\pendrive\DESINSTALAR_SISTEMA_launcher.bat"; Destino = "DESINSTALAR SISTEMA.bat" },
            @{ Origen = "scripts\pendrive\RECUPERAR_SISTEMA_launcher.bat";   Destino = "RECUPERAR SISTEMA.bat" }
        )
        foreach ($l in $launchers) {
            $src = Join-Path $RepoDir $l.Origen
            if (Test-Path $src) {
                Copy-Item -Path $src -Destination (Join-Path $DriveRoot $l.Destino) -Force
                W-Ok ("Launcher: " + $l.Destino)
            } else {
                W-Warn "No existe $($l.Origen)"
            }
        }

        # ----- 4f) LEEME_PRIMERO.txt
        $leemeContent = @"
============================================================
  Sistema de Gestion de Llaves - FCEA
  Pendrive: $TipoNombre
  Generado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
============================================================

QUE HAY EN ESTE PENDRIVE:

  INSTALAR SISTEMA.bat
     -> Instala (o actualiza) el sistema en C:\sistema-llaves-fcea
        El instalador NUNCA pisa los datos productivos
        (C:\ProgramData\FCEA-Sistema-Llaves\pb_data).

  RECUPERAR SISTEMA.bat
     -> Repara una instalacion existente sin perder los datos
        cargados. Solo restaura desde el pendrive si data.db
        esta irrecuperable.

  DESINSTALAR SISTEMA.bat
     -> Quita el sistema de la PC pero respalda los datos en
        C:\backup_fcea_<fecha>\. La carpeta persistente
        C:\ProgramData\FCEA-Sistema-Llaves\ NO se borra.

  Documentacion\
     -> Manuales del sistema (instalacion, operacion, etc.).

  sistema-llaves-fcea\
     -> Codigo fuente + snapshot de la base de datos.

============================================================
  MODELO DE PERSISTENCIA v3.1
============================================================

A partir de v3.1 los datos productivos viven en:

    C:\ProgramData\FCEA-Sistema-Llaves\pb_data

(FUERA de la carpeta de instalacion C:\sistema-llaves-fcea).

Esto significa que:
  * Reinstalar NO borra los datos.
  * Recuperar NO borra los datos.
  * Desinstalar NO borra los datos (solo los respalda).

El snapshot de pb_data en este pendrive solo se usa cuando:
  * Es una instalacion NUEVA (la PC nunca tuvo el sistema), o
  * data.db productivo esta corrupto e irrecuperable.

============================================================

Para empezar:
  1) Hacer click DERECHO en INSTALAR SISTEMA.bat (o
     RECUPERAR SISTEMA.bat) y elegir "Ejecutar como
     administrador".
  2) Aceptar el UAC.
  3) Seguir las indicaciones en pantalla.

Si necesita ayuda tecnica, consulte los manuales en la
carpeta Documentacion\.

============================================================
"@
        Set-Content -Path (Join-Path $DriveRoot "LEEME_PRIMERO.txt") -Value $leemeContent -Encoding UTF8 -Force
        W-Ok "LEEME_PRIMERO.txt actualizado."

        W-Ok "Pendrive $TipoNombre grabado correctamente en $Drive"
    }

    # --------------------------------------------------------
    # 5) Grabar TODOS los pendrives detectados (contenido identico)
    # --------------------------------------------------------
    $contador = 0
    foreach ($drv in $drvList) {
        $contador++
        $tipo = "CLON_$contador"
        Grabar-Pendrive -Drive $drv `
                        -TipoNombre $tipo `
                        -RepoDir $RepoDir `
                        -SnapDir $tmpSnap `
                        -CopiarPbData $copiarPbData

        # Unificar etiqueta a SISTEMA_FCEA (renombra si esta como viejas)
        Set-VolumeLabelSafe -Drive $drv -Label "SISTEMA_FCEA"
    }

    # --------------------------------------------------------
    # 6) Limpieza
    # --------------------------------------------------------
    if ($copiarPbData -and (Test-Path $tmpSnap)) {
        W-Info "Borrando snapshot temporal..."
        Remove-Item -Path $tmpSnap -Recurse -Force -ErrorAction SilentlyContinue
        W-Ok "Snapshot temporal eliminado."
    }

    W-Title "RESUMEN"
    foreach ($drv in $drvList) {
        Write-Host "      Pendrive $drv  ->  SISTEMA_FCEA  OK" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "  [LISTO] $($drvList.Count) pendrive(s) grabado(s) como clones identicos." -ForegroundColor Green
    Write-Host "  Etiqueta unificada: SISTEMA_FCEA" -ForegroundColor Green
    Write-Host ""
    Pausa-Final
    exit 0

} catch {
    Write-Host ""
    W-Err ("Error: " + $_.Exception.Message)
    if ($_.ScriptStackTrace) {
        Write-Host "      Stack:" -ForegroundColor DarkGray
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    Pausa-Final
    exit 1
}
